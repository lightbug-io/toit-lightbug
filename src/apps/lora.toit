import ..devices
import ..messages.messages_gen as messages
import ..modules.comms.generic-handler show GenericHandler
import ..modules.eink.menu-selection show MenuSelection
import ..protocol as protocol
import ..util.bytes show stringify-all-bytes
import log
import watchdog show Watchdog
import .apps show Apps
import .survey.strobe-once show strobe-once

TOP-PAD := 26
TEXT-SPACING := 12
MAX-MESSAGES := 6
LORA-LISTEN-MS := 10000
LORA-LISTEN-REFRESH-MS := 10000
STROBE-FLASH-MS := 25

class LoraApp:
  static screen-width ::= 250
  static screen-height ::= 122

  static PAGE-LORA ::= 34
  static PAGE-MENU ::= 35

  static SEND-ID ::= "id"
  static SEND-PING ::= "ping"
  static SEND-LOCATION ::= "location"

  static MENU-TEXT-SENDING-ID ::= "SendingID"
  static MENU-TEXT-SENDING-PING ::= "SendingPing"
  static MENU-TEXT-SENDING-LOCATION ::= "SendingLocation"
  static MENU-TEXT-BACK ::= "Go Back"
  static MENU-TEXT-EXIT ::= "Exit"

  device_/Device
  parent_/Apps? := null
  dog_/Watchdog? := null

  is-running_/bool := false
  showing-page_/int := 0
  buttons-subscriber-id_/int? := null
  lora-handler_/GenericHandler? := null
  lora-listening_/bool := false
  position-handler_/GenericHandler? := null
  position-subscribed_/bool := false

  menu-selection/MenuSelection? := null
  send-mode_/string := SEND-ID
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
    update-menu-options_
    show-lora
    init-device-id_
    init-button-subscription_
    init-lora-handler_
    subscribe-lora_
    start-lora-listening_
    logger_.info "LoRa app started"

  stop:
    dog_.stop
    is-running_ = false
    stop-lora-listening_
    unsubscribe-lora_
    unsubscribe-position_
    deinit-button-subscriber_
    deinit-lora-handler_
    deinit-position-handler_

    parent_.start
    parent_.show-home
    showing-page_ = 0

  feed:
    e := catch: dog_.feed
    if e:
      logger_.warn "DOG fail: $e"

  is-running -> bool:
    return is-running_

  init-button-subscription_:
    catch --trace:
      id := device_.buttons.subscribe --timeout=null --callback=(:: |button-data|
        feed
        if button-data.duration > 0:
          task:: handle-button-press button-data
      )

      if id:
        buttons-subscriber-id_ = id

  deinit-button-subscriber_:
    if buttons-subscriber-id_:
      e := catch: device_.buttons.unsubscribe --subscriber-id=buttons-subscriber-id_ --timeout=null
      if e:
        logger_.warn "Failed to unsubscribe from buttons: $e"
      buttons-subscriber-id_ = null

  init-lora-handler_:
    lora-handler_ = GenericHandler --callback=(:: |a-msg|
      if is-running_ and a-msg.type == messages.LORA.MT:
        lora := messages.LORA.from-data a-msg.data
        if lora.has-data messages.LORA.PAYLOAD:
          text := payload-to-text_ lora.payload
          logger_.info "LoRa rx: $text"
          flash-green_
          feed
          add-received-message_ text
          handle-received-payload_ text
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
    lora-listening_ = true
    task::
      logger_.info "LoRa listen loop started"
      while is-running_ and lora-listening_:
        e := catch:
          feed
          data := messages.LORA.data --payload=listen-payload_.to-byte-array --receive-ms=LORA-LISTEN-MS
          response := device_.comms.send-new (messages.LORA.msg --data=data) --timeout=(Duration --ms=(LORA-LISTEN-MS + 2000))
          if response and not response.msg-ok:
            logger_.warn "LoRa listen response not OK: $(response)"
          feed
        if e:
          logger_.warn "Failed to keep LORA listening: $e"
        sleep --ms=LORA-LISTEN-REFRESH-MS
      logger_.info "LoRa listen loop stopped"

  stop-lora-listening_:
    lora-listening_ = false
    e := catch:
      data := messages.LORA.data --sleep=true
      device_.comms.send (messages.LORA.set-msg --base-data=data) --now=true
    if e:
      logger_.warn "Failed to stop LORA listening: $e"

  subscribe-lora_:
    e := catch:
      device_.comms.send messages.LORA.subscribe-msg --now=true
      logger_.info "LoRa subscribed"
    if e:
      logger_.warn "Failed to subscribe to LORA: $e"

  unsubscribe-lora_:
    e := catch:
      device_.comms.send messages.LORA.unsubscribe-msg --now=true
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
      show-lora

  unsubscribe-position_:
    if not position-subscribed_:
      return
    e := catch:
      device_.gnss.unsubscribe-position
    if e:
      logger_.warn "Failed to unsubscribe from position: $e"
    position-subscribed_ = false

  show-lora:
    logger_.info "Showing LoRa page"
    showing-page_ = PAGE-LORA
    start-lora-listening_
    device_.eink.batch --important:
      draw-button-row_

      i := 0
      while i < MAX-MESSAGES:
        text := ""
        if i < received-messages_.size:
          text = received-messages_[i]
        draw-line_ i text
        i += 1

      draw-title_
      device_.eink.draw-page --page-id=PAGE-LORA --status-bar-enable=true --redraw-type=messages.BasePage.REDRAW-TYPE_FULLREDRAWWITHOUTCLEAR

  draw-title_:
    device_.eink.draw-element --page-id=PAGE-LORA --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --x=0 --y=0 --text="LoRa App" --fontsize=1 --redraw-type=messages.DrawElement.REDRAW-TYPE-BUFFERONLY

  draw-button-row_:
    third := screen-width / 3
    y := screen-height - 15
    device_.eink.draw-element --page-id=PAGE-LORA --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --textalign=messages.DrawElement.TEXTALIGN_MIDDLE --width=third --x=0 --y=y --text="Menu" --redraw-type=messages.DrawElement.REDRAW-TYPE-BUFFERONLY
    device_.eink.draw-element --page-id=PAGE-LORA --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --textalign=messages.DrawElement.TEXTALIGN_MIDDLE --width=third --x=third --y=y --text=device-id-text_ --redraw-type=messages.DrawElement.REDRAW-TYPE-BUFFERONLY
    device_.eink.draw-element --page-id=PAGE-LORA --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --textalign=messages.DrawElement.TEXTALIGN_MIDDLE --width=third --x=(third * 2) --y=y --text=send-button-text_ --redraw-type=messages.DrawElement.REDRAW-TYPE-BUFFERONLY

  draw-line_ index/int text/string:
    device_.eink.draw-element --page-id=PAGE-LORA --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --x=0 --y=(TOP-PAD + TEXT-SPACING * index) --text=text --fontsize=0 --textalign=messages.DrawElement.TEXTALIGN_LEFT --width=screen-width --redraw-type=messages.DrawElement.REDRAW-TYPE-BUFFERONLY

  send-button-text_ -> string:
    if send-mode_ == SEND-PING:
      return "Send Ping"
    if send-mode_ == SEND-LOCATION:
      return "Send Loc"
    return "Send ID"

  show-menu:
    logger_.info "Showing LoRa menu"
    stop-lora-listening_
    update-menu-options_
    menu-selection = MenuSelection --start=0 --size=menu-options_.size
    showing-page_ = PAGE-MENU
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
    sending := MENU-TEXT-SENDING-ID
    if send-mode_ == SEND-PING:
      sending = MENU-TEXT-SENDING-PING
    else if send-mode_ == SEND-LOCATION:
      sending = MENU-TEXT-SENDING-LOCATION
    menu-options_ = [
      sending,
      MENU-TEXT-BACK,
      MENU-TEXT-EXIT,
    ]

  add-received-message_ text/string:
    received-messages_.insert text --at=0
    while received-messages_.size > MAX-MESSAGES:
      received-messages_.remove --at=(received-messages_.size - 1)
    if showing-page_ == PAGE-LORA:
      show-lora

  payload-to-text_ payload/ByteArray -> string:
    if payload.size == 0:
      return "<empty>"
    e := catch:
      return payload.to-string
    logger_.warn "LoRa payload was not valid UTF-8: $e"
    return "bytes:$(stringify-all-bytes payload)"

  send-current:
    payload := payload-for-current-mode_
    if payload == null:
      show-lora
      return

    send-lora-payload_ payload

  send-lora-payload_ payload/string:
    e := catch:
      feed
      logger_.info "LoRa tx: $payload"
      data := messages.LORA.data --payload=payload.to-byte-array --receive-ms=LORA-LISTEN-MS
      msg := messages.LORA.msg --data=data
      response := device_.comms.send-new msg --timeout=(Duration --ms=(LORA-LISTEN-MS + 2000))
      if response and not response.msg-ok:
        logger_.warn "LoRa tx response not OK: $(response)"
      feed
      flash-white_
    if e:
      logger_.warn "Failed to send LORA: $e"
      show-lora

  handle-received-payload_ text/string:
    parts := split-payload_ text
    sender := parts[0]
    body := parts[1]
    if body == "ping":
      if sender != "" and device-id_ != null and sender == "$(device-id_)":
        return
      response := prefixed-payload_ "pong"
      if response:
        logger_.info "LoRa auto-pong: $response"
        add-received-message_ "tx $response"
        task:: send-lora-payload_ response

  flash-white_:
    task::
      strobe-once:
        device_.strobe.white
        sleep --ms=STROBE-FLASH-MS
        device_.strobe.off

  flash-green_:
    task::
      strobe-once:
        device_.strobe.green
        sleep --ms=STROBE-FLASH-MS
        device_.strobe.off

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
          show-lora
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
    sender := ""
    body := ""
    seen-colon := false
    text.do: |ch|
      if not seen-colon and ch == ':':
        seen-colon = true
      else if seen-colon:
        body += "$ch"
      else:
        sender += "$ch"
    if not seen-colon:
      return ["", text]
    return [sender, body]

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
      show-lora

  handle-button-press button-data/messages.ButtonPress:
    if not is-running_:
      return
    if button-data.duration <= 0:
      return
    else if button-data.duration >= 3000:
      stop
      return

    if showing-page_ == PAGE-LORA:
      if button-data.button-id == messages.ButtonPress.BUTTON-ID_UP_LEFT:
        show-menu
      else if button-data.button-id == messages.ButtonPress.BUTTON-ID_DOWN_RIGHT:
        send-current

    else if showing-page_ == PAGE-MENU:
      if menu-selection == null:
        menu-selection = MenuSelection --start=0 --size=menu-options_.size
      if button-data.button-id == messages.ButtonPress.BUTTON-ID_ACTION:
        selected := menu-options_[menu-selection.current]
        if selected == MENU-TEXT-BACK:
          show-lora
        else if selected == MENU-TEXT-EXIT:
          stop
        else:
          cycle-send-mode_
      else if button-data.button-id == messages.ButtonPress.BUTTON-ID_DOWN_RIGHT:
        menu-selection.up
      else if button-data.button-id == messages.ButtonPress.BUTTON-ID_UP_LEFT:
        menu-selection.down
