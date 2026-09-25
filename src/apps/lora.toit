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

TOP-PAD := 26
TEXT-SPACING := 12
MAX-MESSAGES := 6
LORA-RX-INDEFINITE := 0
STROBE-FLASH-MS := 15
WATCHDOG-FEED-MS := 10000

class LoraApp:
  static screen-width ::= 250
  static screen-height ::= 122

  static PAGE-LORA ::= 34
  static PAGE-MENU ::= 35

  static SEND-ID ::= "id"
  static SEND-PING ::= "ping"
  static SEND-LOCATION ::= "location"

  static MENU-TEXT-SEND-ID ::= "SendID"
  static MENU-TEXT-SEND-PING ::= "SendPing"
  static MENU-TEXT-SEND-LOCATION ::= "SendLocation"
  static MENU-TEXT-BACK ::= "Back"
  static MENU-TEXT-EXIT ::= "Exit"

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
  received-render-pending_/bool := false
  received-render-generation_/int := 0
  button-events_/List := []
  button-worker_/Task? := null

  menu-selection/MenuSelection? := null
  send-mode_/string := SEND-PING
  menu-options_/List := []
  received-messages_/List := []
  last-position_/messages.Position? := null
  device-id_/int? := null

  logger_/log.Logger := log.default.with-name "lora"

  constructor device/Device parent/Apps dog/Watchdog:
    device_ = device
    parent_ = parent
    dog_ = dog

  start:
    dog_.start --s=60
    is-running_ = true
    start-watchdog-feed_
    update-menu-options_
    init-button-subscription_
    init-lora-handler_
    start-lora-listening_
    show-lora --reason="app start"
    init-device-id_
    logger_.info "LoRa app started"

  stop:
    is-running_ = false
    button-events_ = []
    received-render-generation_++
    if received-render-task_:
      received-render-task_.cancel
      received-render-task_ = null
    watchdog-feeding_ = false
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
          device_.strobe.flash-blue --ms=50
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
          flash-green_
          if v3-msg == null:
            handle-received-payload_ text
          logger_.info "LoRa rx: $text"
          feed
          add-received-message_ text
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
        last-position_ = messages.Position.from-data a-msg.data
    )
    device_.comms.register-handler position-handler_

  deinit-position-handler_:
    if position-handler_:
      e := catch: device_.comms.unregister-handler position-handler_
      if e:
        logger_.warn "Failed to unregister position handler: $e"
      position-handler_ = null

  start-lora-listening_:
    if lora-listening_:
      return
    lora-listening_ = subscribe-lora_

  stop-lora-listening_:
    lora-listening_ = false
    unsubscribe-lora_

  subscribe-lora_ -> bool:
    e := catch:
      device_.comms.send (messages.LoRa.subscribe-msg --duration=LORA-RX-INDEFINITE) --now=true
      logger_.info "LoRa subscribed"
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
      device_.gnss.subscribe-position --interval=1000
      position-subscribed_ = true
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

  show-lora --full/bool=false --reason/string="unspecified":
    logger_.info "LoRa page transition: $(showing-page_) -> $(PAGE-LORA), full=$(full), reason=$(reason)"
    redraw-type := messages.DrawElement.REDRAW-TYPE_PARTIALREDRAW
    if full or showing-page_ != PAGE-LORA or not lora-page-drawn_:
      redraw-type = messages.DrawElement.REDRAW-TYPE_FULLREDRAWWITHOUTCLEAR
    showing-page_ = PAGE-LORA
    trim-received-messages_
    start-lora-listening_
    device_.eink.batch --important:
      draw-button-row_
      draw-message-lines_
      // BasePage only supports P1 preset pages. PAGE-LORA is custom, so the
      // final DrawElement must perform the redraw (as Survey does).
      draw-title_ --redraw-type=redraw-type
      lora-page-drawn_ = true

  draw-title_ --redraw-type/int=messages.DrawElement.REDRAW-TYPE-BUFFERONLY:
    device_.eink.draw-element --page-id=PAGE-LORA --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --x=0 --y=0 --text="LoRa App" --fontsize=1 --redraw-type=redraw-type

  draw-button-row_ --final-redraw-type/int?=null:
    third := screen-width / 3
    y := screen-height - 15
    device_.eink.draw-element --page-id=PAGE-LORA --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --textalign=messages.DrawElement.TEXTALIGN_MIDDLE --width=third --x=0 --y=y --text="Menu" --redraw-type=messages.DrawElement.REDRAW-TYPE-BUFFERONLY
    device_.eink.draw-element --page-id=PAGE-LORA --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --textalign=messages.DrawElement.TEXTALIGN_MIDDLE --width=third --x=third --y=y --text=send-button-text_ --redraw-type=messages.DrawElement.REDRAW-TYPE-BUFFERONLY
    redraw-type := final-redraw-type == null ? messages.DrawElement.REDRAW-TYPE-BUFFERONLY : final-redraw-type
    device_.eink.draw-element --page-id=PAGE-LORA --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --textalign=messages.DrawElement.TEXTALIGN_MIDDLE --width=third --x=(third * 2) --y=y --text=device-id-text_ --redraw-type=redraw-type

  draw-line_ index/int text/string --redraw-type/int=messages.DrawElement.REDRAW-TYPE-BUFFERONLY:
    device_.eink.draw-element --page-id=PAGE-LORA --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --x=0 --y=(TOP-PAD + TEXT-SPACING * index) --text=text --fontsize=0 --textalign=messages.DrawElement.TEXTALIGN_LEFT --width=screen-width --redraw-type=redraw-type

  draw-message-lines_ --final-redraw-type/int?=null:
    i := 0
    while i < MAX-MESSAGES:
      text := ""
      if i < received-messages_.size:
        text = received-messages_[i]
      redraw-type := (i == MAX-MESSAGES - 1 and final-redraw-type != null) ? final-redraw-type : messages.DrawElement.REDRAW-TYPE-BUFFERONLY
      draw-line_ i text --redraw-type=redraw-type
      i += 1

  send-button-text_ -> string:
    if send-mode_ == SEND-PING:
      return "Send Ping"
    if send-mode_ == SEND-LOCATION:
      return "Send Loc"
    return "Send ID"

  show-menu --reason/string="unspecified":
    logger_.info "LoRa page transition: $(showing-page_) -> $(PAGE-MENU), reason=$(reason)"
    stop-lora-listening_
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
    sending := MENU-TEXT-SEND-ID
    if send-mode_ == SEND-PING:
      sending = MENU-TEXT-SEND-PING
    else if send-mode_ == SEND-LOCATION:
      sending = MENU-TEXT-SEND-LOCATION
    menu-options_ = [
      sending,
      MENU-TEXT-EXIT,
      MENU-TEXT-BACK,
    ]

  add-received-message_ text/string:
    received-messages_.insert text --at=0
    trim-received-messages_
    if showing-page_ == PAGE-LORA:
      schedule-received-message-render_

  trim-received-messages_:
    while received-messages_.size > MAX-MESSAGES:
      received-messages_.remove --at=(received-messages_.size - 1)

  schedule-received-message-render_:
    received-render-pending_ = true
    if received-render-task_: return
    generation := received-render-generation_
    received-render-task_ = task:: render-received-messages_ generation

  cancel-received-message-render_:
    // A queued partial update for the custom LoRa page must not race a
    // MenuPage transition and draw received payload bytes over the menu.
    received-render-generation_++
    received-render-pending_ = false
    if received-render-task_:
      received-render-task_.cancel
      received-render-task_ = null

  render-received-messages_ generation/int:
    // Keep the Comms handler data-only. Coalesce bursts before emitting the
    // partial redraw, so ButtonPress delivery is never held behind e-ink I2C.
    while is-running_ and generation == received-render-generation_ and received-render-pending_:
      received-render-pending_ = false
      sleep --ms=50
      device_.eink.batch:
        if showing-page_ == PAGE-LORA:
          draw-message-lines_ --final-redraw-type=messages.DrawElement.REDRAW-TYPE_PARTIALREDRAW
    received-render-task_ = null

  screen-on-received-message_:
    device_.eink.batch:
      if showing-page_ == PAGE-LORA:
        draw-message-lines_ --final-redraw-type=messages.DrawElement.REDRAW-TYPE_PARTIALREDRAW

  screen-on-button-row-change_:
    device_.eink.batch --important:
      if showing-page_ == PAGE-LORA:
        draw-button-row_ --final-redraw-type=messages.DrawElement.REDRAW-TYPE_PARTIALREDRAW

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

  send-current:
    payload := payload-for-current-mode_
    if payload == null:
      show-lora --reason="no payload for current send mode"
      return

    send-lora-payload_ payload

  send-id:
    payload := id-payload_
    if payload == null:
      show-lora --reason="device id unavailable"
      return

    send-lora-payload_ payload

  send-lora-payload_ payload/string:
    e := catch:
      feed
      logger_.info "LoRa tx: $payload"
      flash-white_
      data := messages.LoRa.data --payload=payload.to-byte-array
      msg := messages.LoRa.msg --data=data
      response := device_.comms.send-new msg --timeout=(Duration --s=5)
      if response and not response.msg-ok:
        logger_.warn "LoRa tx response not OK: $(response)"
      feed
    if e:
      logger_.warn "Failed to send LORA: $e"
      show-lora --reason="LoRa send failed"

  send-lora-payload-now_ payload/string:
    e := catch:
      data := messages.LoRa.data --payload=payload.to-byte-array
      device_.comms.send (messages.LoRa.msg --data=data) --now=true
      feed
    if e:
      logger_.warn "Failed to send LORA immediately: $e"

  handle-received-payload_ text/string:
    parts := split-payload_ text
    sender := parts[0]
    body := parts[1]
    if body == "ping":
      if sender != "" and device-id_ != null and sender == "$(device-id_)":
        logger_.info "LoRa ping from self ignored"
        return
      response := prefixed-payload_ "pong"
      if response:
        send-lora-payload-now_ response
        flash-white_
        logger_.info "LoRa auto-pong: $response"
      else:
        logger_.warn "LoRa auto-pong skipped: no device id"
    logger_.info "LoRa rx parsed sender='$sender' body='$body'"

  flash-white_:
    device_.strobe.flash-white --ms=STROBE-FLASH-MS

  flash-green_:
    device_.strobe.flash-green --ms=STROBE-FLASH-MS

  payload-for-current-mode_ -> string?:
    if send-mode_ == SEND-PING:
      return prefixed-payload_ "ping"
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
    if last-position_ == null:
      resp := device_.comms.send-new messages.Position.get-msg --timeout=(Duration --s=5)
      if resp != null:
        last-position_ = messages.Position.from-data resp.data
    if last-position_ == null:
      return null
    return prefixed-payload_ "$(last-position_.latitude.to-string --precision=6),$(last-position_.longitude.to-string --precision=6)"

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
    if send-mode_ == SEND-ID:
      send-mode_ = SEND-PING
      unsubscribe-position_
    else if send-mode_ == SEND-PING:
      send-mode_ = SEND-LOCATION
      subscribe-position_
    else:
      send-mode_ = SEND-ID
      unsubscribe-position_
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
        show-menu --reason="accepted P1 Up/Left on LoRa page"
      else if button-data.button-id == messages.ButtonPress.BUTTON-ID_ACTION:
        send-current
      else if button-data.button-id == messages.ButtonPress.BUTTON-ID_DOWN_RIGHT:
        send-id

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
        selected := menu-options_[menu-selection.current]
        if selected == MENU-TEXT-BACK:
          show-lora --full=true --reason="accepted menu Back"
        else if selected == MENU-TEXT-EXIT:
          stop
        else:
          cycle-send-mode_
      else if button-data.button-id == messages.ButtonPress.BUTTON-ID_DOWN_RIGHT:
        menu-selection.up
      else if button-data.button-id == messages.ButtonPress.BUTTON-ID_UP_LEFT:
        menu-selection.down
