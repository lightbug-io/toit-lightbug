import ..devices
import ..messages.messages_gen as messages
import ..modules.comms.generic-handler show GenericHandler
import ..modules.eink.menu-selection show MenuSelection
import ..protocol as protocol
import ..util.bytes show stringify-all-bytes-compact-hex
import io.byte-order show LITTLE-ENDIAN
import log
import watchdog show Watchdog
import .apps show Apps
import .lora-profile show LoraProfile
import .lora-flow show LoraFlow LoraWire

TOP-PAD := 41
TEXT-SPACING := 12
MAX-MESSAGES := 5
MAX-DISPLAY-CHARS := 38
LORA-RX-INDEFINITE := 0
STROBE-FLASH-MS := 15
WATCHDOG-FEED-MS := 10000
RX-DISPLAY-MIN-INTERVAL-US := 1_000_000
RX-LED-MIN-INTERVAL-US := 200_000

class LoraApp:
  static screen-width ::= 250
  static screen-height ::= 122

  static PAGE-LORA ::= 34
  static PAGE-MENU ::= 35

  static SEND-ID ::= "id"
  static SEND-PING ::= "ping"
  static SEND-LOCATION ::= "location"

  static MENU-TEXT-EXIT ::= "Exit to Home"
  static MENU-TEXT-BACK ::= "Back"
  static MENU-MODE ::= 0
  static MENU-PROFILE ::= 1
  static MENU-REPEAT ::= 2
  static MENU-EXIT ::= 3
  static MENU-BACK ::= 4

  device_/Device
  parent_/Apps? := null
  dog_/Watchdog? := null

  is-running_/bool := false
  showing-page_/int := 0
  buttons-subscriber-id_/int? := null
  lora-handler_/GenericHandler? := null
  lora-listening_/bool := false
  watchdog-feeding_/bool := false
  position-handler_/GenericHandler? := null
  position-subscribed_/bool := false
  lora-page-drawn_/bool := false
  received-render-task_/Task? := null
  received-render-generation_/int := 0
  pending-manual-task_/Task? := null
  flow_/LoraFlow := LoraFlow
  button-events_/List := []
  button-worker_/Task? := null

  menu-selection/MenuSelection? := null
  send-mode_/string := SEND-PING
  profile-index_/int := LoraProfile.DEFAULT
  profile_/LoraProfile := LoraProfile.at LoraProfile.DEFAULT
  profile-ready_/bool := false
  continual_/bool := false
  continual-task_/Task? := null
  continual-generation_/int := 0
  menu-options_/List := []
  received-messages_/List := []
  last-position_/messages.Position? := null
  last-position-received-us_/int := 0
  device-id_/int? := null
  show-unknown-messages_/bool := false

  logger_/log.Logger := log.default.with-name "lora"

  constructor device/Device parent/Apps dog/Watchdog --show-unknown-messages/bool=false:
    device_ = device
    parent_ = parent
    dog_ = dog
    show-unknown-messages_ = show-unknown-messages

  start:
    dog_.start --s=60
    is-running_ = true
    start-watchdog-feed_
    update-menu-options_
    init-button-subscription_
    init-lora-handler_
    apply-profile_ LoraProfile.DEFAULT
    show-lora --reason="app start"
    init-device-id_
    logger_.info "LoRa app started"

  stop:
    is-running_ = false
    button-events_ = []
    cancel-received-message-render_
    cancel-pending-manual_
    watchdog-feeding_ = false
    stop-continual_
    dog_.stop
    stop-lora-listening_
    unsubscribe-position_
    deinit-button-subscriber_
    deinit-lora-handler_
    deinit-position-handler_

    parent_.start
    parent_.show-home
    showing-page_ = 0
    lora-page-drawn_ = false

  feed:
    e := catch: dog_.feed
    if e:
      logger_.warn "DOG fail: $e"

  start-watchdog-feed_:
    if watchdog-feeding_:
      return
    watchdog-feeding_ = true
    task::
      while is-running_ and watchdog-feeding_:
        feed
        sleep --ms=WATCHDOG-FEED-MS

  is-running -> bool:
    return is-running_

  init-button-subscription_:
    catch --trace:
      id := device_.buttons.subscribe --timeout=null --callback=(:: |button-data|
        feed
        if button-data.duration > 0:
          // Keep feedback immediate, but keep page transitions ordered.
          task::
            if is-running_: device_.strobe.flash-blue --ms=50
          logger_.info "LoRa button received: $(button-context_ button-data) P2-page=$(showing-page_) queued=$(button-events_.size)"
          schedule-button-handling_ button-data
      )

      if id:
        buttons-subscriber-id_ = id

  deinit-button-subscriber_:
    if buttons-subscriber-id_:
      e := catch: device_.buttons.unsubscribe --subscriber-id=buttons-subscriber-id_ --timeout=null
      if e:
        logger_.warn "Failed to unsubscribe from buttons: $e"
      buttons-subscriber-id_ = null

  schedule-button-handling_ button-data/messages.ButtonPress:
    // The Comms callback must not wait on e-ink/I2C.  A separate task for
    // every press is also unsafe: page transitions can complete out of order.
    // Queue presses and run exactly one state-changing worker instead.
    if not is-running_:
      return
    // Keep the local page too.  P1 page ids are reused when returning from a
    // menu, so checking only the P1 tag when the worker eventually runs is
    // insufficient: a menu-era event can otherwise look valid after Back.
    button-events_.add [button-data, showing-page_]
    if button-worker_:
      return
    button-worker_ = task:: process-button-events_

  process-button-events_:
    while is-running_ and button-events_.size > 0:
      event := button-events_.remove --at=0
      logger_.info "LoRa button handling: $(button-context_ event[0]) received-P2-page=$(event[1]) current-P2-page=$(showing-page_) queued=$(button-events_.size)"
      handle-button-press event[0] --received-page=event[1]
    button-worker_ = null

  button-context_ button-data/messages.ButtonPress -> string:
    menu-item := button-data.has-data messages.ButtonPress.MENU-ITEM ? "$(button-data.menu-item)" : "-"
    return "id=$(button-data.button-id) duration=$(button-data.duration) P1-page=$(button-data.page-id) P1-menu=$(menu-item)"

  init-lora-handler_:
    lora-handler_ = GenericHandler --callback=(:: |a-msg|
      if is-running_ and a-msg.type == messages.LoRa.MT:
        lora := messages.LoRa.from-data a-msg.data
        if lora.has-data messages.LoRa.PAYLOAD:
          payload := lora.payload
          v3-msg := payload-to-v3-message_ payload
          text := payload-to-display-text_ payload v3-msg
          logger_.info "LoRa rx: $text"
          feed
          // Keep binary traffic in the logs without filling the e-ink screen.
          if show-unknown-messages_ or v3-msg != null or payload-is-text_ payload:
            if v3-msg == null:
              handle-received-payload_ text
            add-received-message_ (short-display-text_ text)
            maybe-rx-feedback_
        else:
          logger_.info "LoRa update without payload"
    )
    device_.comms.register-handler lora-handler_

  deinit-lora-handler_:
    if lora-handler_:
      e := catch: device_.comms.unregister-handler lora-handler_
      if e:
        logger_.warn "Failed to unregister LORA handler: $e"
      lora-handler_ = null

  init-position-handler_:
    if position-handler_:
      return
    position-handler_ = GenericHandler --callback=(:: |a-msg|
      if is-running_ and a-msg.type == messages.Position.MT:
        first-fix := last-position_ == null or last-position_.type == messages.Position.TYPE_INVALID
        last-position_ = messages.Position.from-data a-msg.data
        last-position-received-us_ = Time.monotonic-us
        if last-position_.type != messages.Position.TYPE_INVALID:
          logger_.info "P1 position update type=$(last-position_.type) lat=$(last-position_.latitude) lon=$(last-position_.longitude)"
          if first-fix and send-mode_ == SEND-LOCATION and showing-page_ == PAGE-LORA:
            task::
              if is-running_ and showing-page_ == PAGE-LORA: screen-on-button-row-change_
    )
    device_.comms.register-handler position-handler_

  deinit-position-handler_:
    if position-handler_:
      e := catch: device_.comms.unregister-handler position-handler_
      if e:
        logger_.warn "Failed to unregister position handler: $e"
      position-handler_ = null

  apply-profile_ index/int -> bool:
    stop-continual_
    cancel-pending-manual_
    if lora-listening_:
      stop-lora-listening_
    profile-index_ = index
    profile_ = LoraProfile.at index
    profile-ready_ = false
    e := catch:
      data := messages.LoRaConfig.data
        --config-slot=LoraProfile.SLOT
        --spread-factor=profile_.sf
        --coding-rate=profile_.coding-rate
        --bandwidth=0
        --center-frequency=profile_.frequency-hz
        --tx-power=profile_.tx-power-dbm
        --preamble-length=8
        --crc-on=false
        --iq-inverted=false
        --fixed-length=false
        --payload-length=0
        --max-payload-length=LoraProfile.MAX-PAYLOAD
        --public-network=false
      response := device_.comms.send-new (messages.LoRaConfig.set-msg --base-data=data) --timeout=(Duration --s=5)
      if response == null or not response.msg-ok:
        throw "P1 LoRaConfig SET failed: $response"
      query := messages.LoRaConfig.get-msg --base-data=(messages.LoRaConfig.data --config-slot=LoraProfile.SLOT)
      readback := device_.comms.send-new query --timeout=(Duration --s=5)
      if readback == null or not readback.msg-ok:
        throw "P1 LoRaConfig GET failed: $readback"
      cfg := messages.LoRaConfig.from-data readback.data
      if cfg.config-slot != LoraProfile.SLOT or
          cfg.center-frequency != profile_.frequency-hz or
          cfg.spread-factor != profile_.sf or
          cfg.coding-rate != profile_.coding-rate or
          cfg.bandwidth != 0 or
          cfg.tx-power != profile_.tx-power-dbm or
          cfg.preamble-length != 8 or
          cfg.crc-on or cfg.fixed-length or
          cfg.max-payload-length != LoraProfile.MAX-PAYLOAD:
        throw "P1 LoRaConfig mismatch: $cfg"
      profile-ready_ = true
      logger_.info "LoRa profile ready: $profile_ slot=$(LoraProfile.SLOT) duty=$(profile_.duty-percent)%"
    if e:
      logger_.warn "LoRa profile unavailable: $e"
      return false
    return true

  cycle-profile_:
    index := (profile-index_ + 1) % LoraProfile.COUNT
    apply-profile_ index
    if showing-page_ == PAGE-MENU:
      update-menu
    else:
      show-lora --full=true --reason="profile changed"

  start-lora-listening_:
    if lora-listening_ or not profile-ready_:
      return
    lora-listening_ = subscribe-lora_

  stop-lora-listening_:
    lora-listening_ = false
    unsubscribe-lora_

  subscribe-lora_ -> bool:
    e := catch:
      msg := messages.LoRa.subscribe-msg --duration=LORA-RX-INDEFINITE
      msg.data.add-data-uint messages.LoRa.CONFIG-SLOT LoraProfile.SLOT
      device_.comms.send msg --now=true
      logger_.info "LoRa subscribed profile=$(profile_.name) slot=$(LoraProfile.SLOT)"
    if e:
      logger_.warn "Failed to subscribe to LORA: $e"
      return false
    return true

  unsubscribe-lora_:
    e := catch:
      device_.comms.send messages.LoRa.unsubscribe-msg --now=true
      logger_.info "LoRa unsubscribed"
    if e:
      logger_.warn "Failed to unsubscribe from LORA: $e"

  subscribe-position_:
    if position-subscribed_:
      return
    init-position-handler_
    e := catch:
      device_.gnss.subscribe-position --interval=1000 --message-level=2
      position-subscribed_ = true
      logger_.info "Position subscribed at 1s, level 2 (start GNSS)"
    if e:
      logger_.warn "Failed to subscribe to position: $e"
      show-lora --reason="position subscription failed"

  unsubscribe-position_:
    if not position-subscribed_:
      return
    e := catch:
      device_.gnss.unsubscribe-position
    if e:
      logger_.warn "Failed to unsubscribe from position: $e"
    position-subscribed_ = false
    last-position_ = null
    last-position-received-us_ = 0

  show-lora --full/bool=false --reason/string="unspecified":
    logger_.info "LoRa page transition: $(showing-page_) -> $(PAGE-LORA), full=$(full), reason=$(reason)"
    redraw-type := messages.DrawElement.REDRAW-TYPE_PARTIALREDRAW
    if full or showing-page_ != PAGE-LORA or not lora-page-drawn_:
      redraw-type = messages.DrawElement.REDRAW-TYPE_FULLREDRAWWITHOUTCLEAR
    showing-page_ = PAGE-LORA
    trim-received-messages_
    start-lora-listening_
    flow_.mark-rendered Time.monotonic-us
    flow_.reset-flash
    device_.eink.batch --important:
      draw-button-row_
      draw-message-lines_
      draw-timing_
      draw-status_
      // BasePage only supports P1 preset pages. PAGE-LORA is custom, so the
      // final DrawElement must perform the redraw (as Survey does).
      draw-title_ --redraw-type=redraw-type
      lora-page-drawn_ = true

  draw-title_ --redraw-type/int=messages.DrawElement.REDRAW-TYPE-BUFFERONLY:
    title := profile-ready_ ? "LoRa $(profile_.name)$(continual_ ? " Auto" : "")" : "LoRa profile error"
    device_.eink.draw-element --page-id=PAGE-LORA --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --x=4 --y=0 --text=title --fontsize=1 --redraw-type=redraw-type

  draw-status_ --redraw-type/int=messages.DrawElement.REDRAW-TYPE-BUFFERONLY:
    mode := send-mode_ == SEND-LOCATION ? "Location" : (send-mode_ == SEND-PING ? "Ping" : "ID")
    status := "$mode | $(device-id-text_)$(flow_.pending-manual-mode != null ? " | Queued" : "")"
    device_.eink.draw-element --page-id=PAGE-LORA --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --x=4 --y=17 --text=status --fontsize=0 --width=(screen-width - 8) --redraw-type=redraw-type

  draw-timing_:
    // Continual cadence and the shared airtime guard are different.
    // Position length varies; before a fix, show a 32-byte estimate.
    bytes := device-id_ == null ? 8 : "$(device-id_)".size
    estimated := false
    if send-mode_ == SEND-PING:
      bytes += 5  // ":ping"
    else if send-mode_ == SEND-LOCATION:
      position := last-position_
      if position != null and position-subscribed_ and
          Time.monotonic-us - last-position-received-us_ <= 15_000_000 and
          position.type != messages.Position.TYPE_INVALID and
          position.type != messages.Position.TYPE_RESERVED and
          (position.latitude != 0 or position.longitude != 0):
        bytes += ":$(position.latitude.to-string --precision=6),$(position.longitude.to-string --precision=6)".size
      else:
        bytes = 32
        estimated = true
    gap-ms := profile_.send-gap-ms bytes send-mode_
    gap-tenths := (gap-ms + 99) / 100
    interval-tenths := (profile_.interval-ms send-mode_) / 100
    text := "Min TX gap $(estimated ? "~" : "")$(gap-tenths / 10).$(gap-tenths % 10)s | Auto $(interval-tenths / 10).$(interval-tenths % 10)s"
    device_.eink.draw-element --page-id=PAGE-LORA --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --x=4 --y=29 --text=text --fontsize=0 --width=(screen-width - 8)

  draw-button-row_ --final-redraw-type/int?=null:
    third := screen-width / 3
    y := screen-height - 15
    device_.eink.draw-element --page-id=PAGE-LORA --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --textalign=messages.DrawElement.TEXTALIGN_MIDDLE --width=third --x=0 --y=y --text="Home" --redraw-type=messages.DrawElement.REDRAW-TYPE-BUFFERONLY
    device_.eink.draw-element --page-id=PAGE-LORA --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --textalign=messages.DrawElement.TEXTALIGN_MIDDLE --width=third --x=third --y=y --text=send-button-text_ --redraw-type=messages.DrawElement.REDRAW-TYPE-BUFFERONLY
    redraw-type := final-redraw-type == null ? messages.DrawElement.REDRAW-TYPE-BUFFERONLY : final-redraw-type
    device_.eink.draw-element --page-id=PAGE-LORA --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --textalign=messages.DrawElement.TEXTALIGN_MIDDLE --width=third --x=(third * 2) --y=y --text="Menu" --redraw-type=redraw-type

  draw-line_ index/int text/string --redraw-type/int=messages.DrawElement.REDRAW-TYPE-BUFFERONLY:
    device_.eink.draw-element --page-id=PAGE-LORA --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --x=4 --y=(TOP-PAD + TEXT-SPACING * index) --text=text --fontsize=0 --textalign=messages.DrawElement.TEXTALIGN_LEFT --width=(screen-width - 8) --redraw-type=redraw-type

  draw-message-lines_ --final-redraw-type/int?=null:
    i := 0
    while i < MAX-MESSAGES:
      text := ""
      if i < received-messages_.size:
        text = received-messages_[i]
      else if i == 0 and received-messages_.size == 0:
        text = "Listening..."
      redraw-type := (i == MAX-MESSAGES - 1 and final-redraw-type != null) ? final-redraw-type : messages.DrawElement.REDRAW-TYPE-BUFFERONLY
      draw-line_ i text --redraw-type=redraw-type
      i += 1

  send-button-text_ -> string:
    return "Send"

  show-menu --reason/string="unspecified":
    logger_.info "LoRa page transition: $(showing-page_) -> $(PAGE-MENU), reason=$(reason)"
    update-menu-options_
    menu-selection = MenuSelection --start=0 --size=menu-options_.size
    showing-page_ = PAGE-MENU
    cancel-received-message-render_
    device_.eink.batch --important:
      device_.eink.send-menu --page-id=PAGE-MENU --items=menu-options_ --selected-item=0

  update-menu:
    device_.eink.batch --important:
      update-menu-options_
      if showing-page_ == PAGE-MENU:
        if menu-selection == null:
          menu-selection = MenuSelection --start=0 --size=menu-options_.size
        device_.eink.send-menu --page-id=PAGE-MENU --items=menu-options_ --selected-item=menu-selection.current

  update-menu-options_:
    menu-options_ = [
      "Mode$send-mode_",
      "Radio$(profile_.name) $(profile_.frequency-hz / 1_000_000.0)",
      "Continual$(continual_ ? "On" : "Off")",
      MENU-TEXT-EXIT,
      MENU-TEXT-BACK,
    ]

  add-received-message_ text/string:
    received-messages_.insert text --at=0
    trim-received-messages_

  maybe-rx-feedback_:
    if showing-page_ != PAGE-LORA:
      return
    schedule-received-message-render_
    now := Time.monotonic-us
    if flow_.should-flash now RX-LED-MIN-INTERVAL-US:
      task::
        if is-running_ and showing-page_ == PAGE-LORA: flash-green_

  trim-received-messages_:
    while received-messages_.size > MAX-MESSAGES:
      received-messages_.remove --at=(received-messages_.size - 1)

  schedule-received-message-render_:
    flow_.note-receive
    if received-render-task_: return
    generation := received-render-generation_
    received-render-task_ = task:: render-received-messages_ generation

  cancel-received-message-render_:
    // Do not let a delayed LoRa redraw land on a menu or Home.
    received-render-generation_++
    flow_.cancel-render
    if received-render-task_:
      received-render-task_.cancel
      received-render-task_ = null

  render-received-messages_ generation/int:
    while is-running_ and generation == received-render-generation_ and flow_.render-pending:
      wait-us := flow_.render-wait-us Time.monotonic-us RX-DISPLAY-MIN-INTERVAL-US
      sleep --ms=(wait-us > 0 ? (wait-us + 999) / 1000 : 50)
      if not is-running_ or generation != received-render-generation_ or showing-page_ != PAGE-LORA:
        break
      if (flow_.render-wait-us Time.monotonic-us RX-DISPLAY-MIN-INTERVAL-US) > 0:
        continue
      device_.eink.batch:
        if showing-page_ == PAGE-LORA:
          flow_.mark-rendered Time.monotonic-us
          draw-message-lines_ --final-redraw-type=messages.DrawElement.REDRAW-TYPE_PARTIALREDRAW
    received-render-task_ = null

  screen-on-received-message_:
    device_.eink.batch:
      if showing-page_ == PAGE-LORA:
        draw-message-lines_ --final-redraw-type=messages.DrawElement.REDRAW-TYPE_PARTIALREDRAW

  screen-on-button-row-change_:
    device_.eink.batch --important:
      if showing-page_ == PAGE-LORA:
        draw-button-row_
        draw-timing_
        draw-status_ --redraw-type=messages.DrawElement.REDRAW-TYPE_PARTIALREDRAW

  payload-is-text_ payload/ByteArray -> bool:
    e := catch: payload.to-string
    return e == null

  short-display-text_ text/string -> string:
    if text.size <= MAX-DISPLAY-CHARS:
      return text
    return "$(text[0..MAX-DISPLAY-CHARS - 3])..."

  payload-to-text_ payload/ByteArray -> string:
    if payload.size == 0:
      return "<empty>"
    e := catch:
      return payload.to-string
    logger_.warn "LoRa payload was not valid UTF-8: $e"
    return stringify-all-bytes-compact-hex payload

  payload-to-display-text_ payload/ByteArray v3-msg/protocol.Message? -> string:
    if v3-msg:
      return v3-message-to-text_ v3-msg
    return payload-to-text_ payload

  payload-to-v3-message_ payload/ByteArray -> protocol.Message?:
    if payload.size < 7 or payload[0] != 3:
      return null
    message-length := LITTLE-ENDIAN.uint16 payload 1
    if message-length != payload.size:
      return null
    e := catch:
      msg := protocol.Message.from-bytes payload
      checksum := LITTLE-ENDIAN.uint16 payload (payload.size - 2)
      if msg.checksum-calc != checksum:
        return null
      return msg
    if e:
      logger_.debug "LoRa payload was not a valid V3 message: $e"
    return null

  v3-message-to-text_ msg/protocol.Message -> string:
    client := v3-message-client-text_ msg
    if msg.type == messages.Position.MT:
      position := messages.Position.from-data msg.data
      return "$client $(msg.type) $(position.latitude.to-string --precision=6) $(position.longitude.to-string --precision=6) $(position.accuracy.to-string --precision=2)"
    // TODO: render other V3 message types using a generated priority list of compact fields.
    return "$client $(msg.type) $(msg.size)"

  v3-message-client-text_ msg/protocol.Message -> string:
    if msg.header-has-data protocol.Header.TYPE_CLIENT_ID:
      return "$(msg.header-get-data-uint protocol.Header.TYPE_CLIENT_ID)"
    if msg.header-has-data protocol.Header.TYPE_FORWARDED_FOR:
      return "$(msg.header-get-data-uint protocol.Header.TYPE_FORWARDED_FOR)"
    return "-"

  send-current --continual/bool=false:
    payload := payload-for-current-mode_
    if payload == null:
      if not continual:
        logger_.warn "No valid payload for $send-mode_"
        flash-rejected_
      return
    send-lora-payload_ payload send-mode_ --continual=continual

  send-id:
    payload := id-payload_
    if payload == null:
      logger_.warn "Device ID unavailable"
      flash-rejected_
      return
    send-lora-payload_ payload SEND-ID

  toggle-continual_:
    if continual_:
      stop-continual_
    else:
      start-continual_
    update-menu

  start-continual_:
    if not profile-ready_:
      logger_.warn "Cannot enable continual: LoRa profile is unavailable"
      return
    continual_ = true
    continual-generation_++
    generation := continual-generation_
    logger_.info "LoRa continual on profile=$(profile_.name) mode=$send-mode_ interval_ms=$(profile_.interval-ms send-mode_)"
    continual-task_ = task:: continual-loop_ generation

  stop-continual_:
    if continual_:
      logger_.info "LoRa continual off"
    continual_ = false
    continual-generation_++
    if continual-task_:
      continual-task_.cancel
      continual-task_ = null

  continual-loop_ generation/int:
    // Use a fixed deadline so P1/I2C work does not get added to every interval.
    next-at-us := Time.monotonic-us + (profile_.interval-ms send-mode_) * 1000
    while is-running_ and continual_ and generation == continual-generation_:
      remaining-us := next-at-us - Time.monotonic-us
      if remaining-us > 0:
        sleep --ms=((remaining-us + 999) / 1000)
      if not is-running_ or not continual_ or generation != continual-generation_:
        break
      send-current --continual=true
      next-at-us += (profile_.interval-ms send-mode_) * 1000
      if next-at-us <= Time.monotonic-us:
        next-at-us = Time.monotonic-us + (profile_.interval-ms send-mode_) * 1000
    if generation == continual-generation_:
      continual-task_ = null

  cancel-pending-manual_:
    flow_.cancel-manual
    if pending-manual-task_:
      pending-manual-task_.cancel
      pending-manual-task_ = null

  queue-manual_ mode/string wait-us/int:
    first := flow_.queue-manual mode
    logger_.info "LoRa manual send queued: profile=$(profile_.name) mode=$mode wait_ms=$((wait-us + 999) / 1000) coalesced=$(not first)"
    if first:
      device_.strobe.flash device_.strobe.YELLOW --ms=100
      if showing-page_ == PAGE-LORA: screen-on-button-row-change_
    if pending-manual-task_: return
    generation := flow_.pending-generation
    pending-manual-task_ = task:: process-pending-manual_ generation

  process-pending-manual_ generation/int:
    while is-running_ and generation == flow_.pending-generation and flow_.pending-manual-mode != null:
      wait-us := flow_.tx-wait-us Time.monotonic-us
      if wait-us > 0:
        sleep --ms=((wait-us + 999) / 1000)
      if not is-running_ or generation != flow_.pending-generation:
        break
      if (flow_.tx-wait-us Time.monotonic-us) > 0:
        continue
      mode := flow_.take-manual
      if mode != send-mode_:
        logger_.info "LoRa queued manual send cancelled: mode changed"
      else:
        payload := payload-for-current-mode_
        if payload == null:
          logger_.warn "LoRa queued manual send cancelled: no valid $mode payload"
          flash-rejected_
        else:
          send-lora-payload_ payload mode
      if showing-page_ == PAGE-LORA and is-running_: screen-on-button-row-change_
    if generation == flow_.pending-generation:
      pending-manual-task_ = null

  reserve-transmission_ payload/string mode/string --continual/bool=false --manual/bool=false -> string:
    if not profile-ready_:
      logger_.warn "LoRa send blocked: profile unavailable"
      return "blocked"
    bytes := payload.to-byte-array.size
    if bytes < 1 or bytes > LoraProfile.MAX-PAYLOAD:
      logger_.warn "LoRa send blocked: payload=$bytes bytes exceeds 1..$(LoraProfile.MAX-PAYLOAD)"
      return "blocked"
    now := Time.monotonic-us
    wait-us := flow_.tx-wait-us now
    if manual and flow_.pending-manual-mode != null:
      queue-manual_ mode wait-us
      return "queued"
    if continual and wait-us > 0:
      // Continual mode waits for its airtime deadline.
      sleep --ms=((wait-us + 999) / 1000)
      now = Time.monotonic-us
      wait-us = flow_.tx-wait-us now
    if wait-us > 0:
      if manual:
        queue-manual_ mode wait-us
        return "queued"
      logger_.info "LoRa send deferred: profile=$(profile_.name) mode=$mode wait_ms=$((wait-us + 999) / 1000)"
      return "blocked"
    gap-ms := profile_.send-gap-ms bytes mode
    if not (flow_.reserve-tx now gap-ms):
      logger_.warn "LoRa send deferred: budget changed before reservation"
      return "blocked"
    logger_.info "LoRa airtime budget: profile=$(profile_.name) mode=$mode bytes=$bytes airtime_ms=$(profile_.airtime-ms bytes) next_gap_ms=$gap-ms"
    return "reserved"

  send-lora-payload_ payload/string mode/string --continual/bool=false:
    reservation := reserve-transmission_ payload mode --continual=continual --manual=(not continual)
    if reservation != "reserved":
      if reservation == "blocked" and not continual: flash-rejected_
      return
    e := catch:
      feed
      data := messages.LoRa.data --payload=payload.to-byte-array --config-slot=LoraProfile.SLOT
      msg := messages.LoRa.msg --data=data
      if continual:
        device_.comms.send msg --now=true
        logger_.info "LoRa tx: $payload profile=$(profile_.name) continual=true outcome=queued-to-P1 at_us=$(Time.monotonic-us)"
      else:
        response := device_.comms.send-new msg --timeout=(Duration --s=5)
        if response == null:
          logger_.warn "LoRa manual tx unconfirmed: no P1 response for $payload; peer RX may still occur"
          device_.strobe.flash device_.strobe.YELLOW --ms=100
        else if not response.msg-ok:
          logger_.warn "LoRa manual tx rejected by P1: $payload response=$response"
          flash-rejected_
        else:
          logger_.info "LoRa tx: $payload profile=$(profile_.name) continual=false outcome=P1-accepted at_us=$(Time.monotonic-us)"
          flash-white_
      feed
    if e:
      logger_.warn "Failed to send LORA: $e"
      if not continual: flash-rejected_

  send-lora-payload-now_ payload/string mode/string:
    if (reserve-transmission_ payload mode) != "reserved":
      logger_.info "LoRa automatic response suppressed by airtime guard"
      return
    // Reserve synchronously, then perform P1 I/O outside inbound dispatch.
    task::
      e := catch:
        data := messages.LoRa.data --payload=payload.to-byte-array --config-slot=LoraProfile.SLOT
        device_.comms.send (messages.LoRa.msg --data=data) --now=true
        logger_.info "LoRa automatic tx: $payload profile=$(profile_.name)"
        feed
      if e:
        logger_.warn "Failed to send LORA automatically: $e"

  handle-received-payload_ text/string:
    parts := split-payload_ text
    sender := parts[0]
    body := parts[1]
    if LoraWire.is-ping body:
      if sender != "" and device-id_ != null and sender == "$(device-id_)":
        logger_.info "LoRa ping from self ignored"
        return
      if body.starts-with "ping:" and body[5..body.size] != profile_.code:
        logger_.warn "LoRa peer profile mismatch: received=$(body[5..body.size]) local=$(profile_.code)"
      response := prefixed-payload_ "pong:$(profile_.code)"
      if response:
        send-lora-payload-now_ response "pong"
        logger_.info "LoRa auto-pong considered: $response"
      else:
        logger_.warn "LoRa auto-pong skipped: no device id"
    else if LoraWire.is-legacy-pong body:
      logger_.info "LoRa legacy pong received from $sender"
    else if LoraWire.pong-profile body:
      peer-profile := LoraWire.pong-profile body
      if peer-profile == profile_.code:
        logger_.info "LoRa peer profile matched: $(profile_.name)"
      else:
        logger_.warn "LoRa peer profile mismatch: peer=$peer-profile local=$(profile_.code)"
    logger_.info "LoRa rx parsed sender='$sender' body='$body'"

  flash-rejected_:
    device_.strobe.flash-red --ms=STROBE-FLASH-MS

  flash-white_:
    device_.strobe.flash-white --ms=STROBE-FLASH-MS

  flash-green_:
    device_.strobe.flash-green --ms=STROBE-FLASH-MS

  payload-for-current-mode_ -> string?:
    if send-mode_ == SEND-PING:
      return prefixed-payload_ LoraWire.ping-body
    if send-mode_ == SEND-LOCATION:
      return location-payload_
    return id-payload_

  id-payload_ -> string?:
    init-device-id_
    if device-id_ == null:
      return null
    return "$(device-id_)"

  init-device-id_:
    if device-id_ != null:
      return
    e := catch:
      resp := device_.comms.send-new messages.DeviceIDs.get-msg --timeout=(Duration --s=5)
      if resp != null:
        ids := messages.DeviceIDs.from-data resp.data
        device-id_ = ids.id
        logger_.info "Device id: $(device-id_)"
        if showing-page_ == PAGE-LORA:
          screen-on-button-row-change_
    if e:
      logger_.warn "Failed to read device id: $e"

  device-id-text_ -> string:
    if device-id_ == null:
      return "ID ..."
    return "ID $(device-id_)"

  listen-payload_ -> string:
    init-device-id_
    if device-id_ == null:
      return "unknown:listening"
    return "$(device-id_):listening"

  location-payload_ -> string?:
    // Position subscriptions publish live P1 fixes. Keep a receive-time bound
    // so LoRa cannot repeat a cached coordinate after GNSS updates stop.
    position := last-position_
    if not position-subscribed_ or position == null or
        Time.monotonic-us - last-position-received-us_ > 15_000_000 or
        position.type == messages.Position.TYPE_INVALID or
        position.type == messages.Position.TYPE_RESERVED or
        (position.latitude == 0 and position.longitude == 0):
      logger_.warn "Location send skipped: awaiting fresh P1 GNSS fix"
      return null
    return prefixed-payload_ "$(position.latitude.to-string --precision=6),$(position.longitude.to-string --precision=6)"

  prefixed-payload_ body/string -> string?:
    init-device-id_
    if device-id_ == null:
      return null
    return "$(device-id_):$body"

  split-payload_ text/string -> List:
    idx := text.index-of ":"
    if idx == -1:
      return ["", text]
    return [text[0..idx], text[idx + 1..text.size]]

  cycle-send-mode_:
    cancel-pending-manual_
    was-continual := continual_
    if was-continual: stop-continual_
    if send-mode_ == SEND-ID:
      send-mode_ = SEND-PING
      unsubscribe-position_
    else if send-mode_ == SEND-PING:
      send-mode_ = SEND-LOCATION
      subscribe-position_
    else:
      send-mode_ = SEND-ID
      unsubscribe-position_
    if was-continual:
      start-continual_
      logger_.info "LoRa continual mode changed to $send-mode_ interval_ms=$(profile_.interval-ms send-mode_)"
    if showing-page_ == PAGE-MENU:
      update-menu
    else:
      screen-on-button-row-change_

  handle-button-press button-data/messages.ButtonPress --received-page/int?=null:
    if not is-running_:
      return
    if button-data.duration <= 0:
      return
    if received-page != null and received-page != showing-page_:
      logger_.warn "Ignoring stale queued LoRa button: received-P2-page=$(received-page), current-P2-page=$(showing-page_)"
      return
    else if button-data.duration >= 3000:
      stop
      return

    // The event is tagged by P1 with the page that was visible at press time.
    // Once P2 has transitioned to another page, an event from the former page
    // is stale.  It must never be reinterpreted using that former page: an
    // Action tagged PAGE-LORA while the menu is open would otherwise transmit
    // a ping (and flash white) from inside the menu.
    if button-data.page-id != showing-page_:
      logger_.warn "Ignoring P1/P2 page mismatch: P1=$(button-data.page-id), P2=$(showing-page_)"
      return

    if showing-page_ == PAGE-LORA:
      if button-data.button-id == messages.ButtonPress.BUTTON-ID_UP_LEFT:
        stop
      else if button-data.button-id == messages.ButtonPress.BUTTON-ID_ACTION:
        send-current
      else if button-data.button-id == messages.ButtonPress.BUTTON-ID_DOWN_RIGHT:
        show-menu --reason="accepted P1 Down/Right on LoRa page"

    else if showing-page_ == PAGE-MENU:
      if menu-selection == null:
        menu-selection = MenuSelection --start=0 --size=menu-options_.size
      if button-data.button-id == messages.ButtonPress.BUTTON-ID_ACTION:
        // P1 owns the visible external-menu selection. Its ButtonPress
        // context carries that selection, so use it for the action rather
        // than relying solely on our locally replayed Up/Down presses.
        if button-data.has-data messages.ButtonPress.MENU-ITEM:
          if not menu-selection.synchronize button-data.menu-item:
            logger_.warn "Ignoring out-of-range P1 LoRa menu item $(button-data.menu-item)"
            return
        logger_.info "LoRa menu action: item $(menu-selection.current)"
        selected := menu-selection.current
        if selected == MENU-MODE:
          cycle-send-mode_
        else if selected == MENU-PROFILE:
          cycle-profile_
        else if selected == MENU-REPEAT:
          toggle-continual_
        else if selected == MENU-EXIT:
          stop
        else if selected == MENU-BACK:
          show-lora --full=true --reason="accepted menu Back"
      else if button-data.button-id == messages.ButtonPress.BUTTON-ID_DOWN_RIGHT:
        menu-selection.up
      else if button-data.button-id == messages.ButtonPress.BUTTON-ID_UP_LEFT:
        menu-selection.down
