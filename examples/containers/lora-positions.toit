import lightbug.devices as devices
import lightbug.messages as messages
import lightbug.modules.comms.generic-handler show GenericHandler
import lightbug.protocol as protocol
import log

import watchdog.provider
import watchdog show WatchdogServiceClient

LOG-LEVEL ::= log.WARN-LEVEL
INFO-WATCH-MESSAGE-LEVEL ::= 1
MIN-LORA-TX-MS ::= 5000
POSITION-WATCH-INTERVAL-MS ::= MIN-LORA-TX-MS
WATCHDOG-FEED-MS ::= 10000
PAGE-HOME ::= 1
PAGE-STATS ::= 36
SCREEN-WIDTH ::= 250
SCREEN-HEIGHT ::= 122
TEXT-SPACING ::= 12

logger := log.default.with-name "lora-positions"

class LoraPositionsApp:
  device_/devices.Device
  dog_/any
  position-handler_/GenericHandler? := null
  buttons-subscriber-id_/int? := null
  running_/bool := false
  watchdog-feeding_/bool := false
  showing-stats_/bool := false

  device-id_/int? := null
  position-count_/int := 0
  tx-count_/int := 0
  skipped-count_/int := 0
  last-position-text_/string := "-"
  last-tx-text_/string := "-"
  last-tx-at_/Time := Time.epoch

  constructor device/devices.Device dog:
    device_ = device
    dog_ = dog

  start:
    dog_.start --s=60
    running_ = true
    start-watchdog-feed_
    init-device-id_
    init-button-subscription_
    init-position-handler_
    subscribe-position-watch_
    show-home_
    logger.info "LoRa positions app started"

  feed:
    e := catch: dog_.feed
    if e:
      logger.warn "DOG fail: $e"

  start-watchdog-feed_:
    if watchdog-feeding_:
      return
    watchdog-feeding_ = true
    task::
      while running_ and watchdog-feeding_:
        feed
        sleep --ms=WATCHDOG-FEED-MS

  init-device-id_:
    if device-id_ != null:
      return
    e := catch:
      resp := device_.comms.send-new messages.DeviceIDs.get-msg --timeout=(Duration --s=5)
      if resp != null:
        ids := messages.DeviceIDs.from-data resp.data
        device-id_ = ids.id
        logger.info "Device id: $(device-id_)"
    if e:
      logger.warn "Failed to read device id: $e"

  init-button-subscription_:
    e := catch:
      id := device_.buttons.subscribe --timeout=null --callback=(:: |button-data|
        feed
        if button-data.duration > 0 and showing-stats_:
          if button-data.button-id == messages.ButtonPress.BUTTON-ID_DOWN_RIGHT or button-data.button-id == messages.ButtonPress.BUTTON-ID_ACTION:
            show-home_
        else if button-data.duration > 0 and button-data.button-id == messages.ButtonPress.BUTTON-ID_DOWN_RIGHT:
          show-stats_
      )
      if id:
        buttons-subscriber-id_ = id
    if e:
      logger.warn "Failed to subscribe to buttons: $e"

  init-position-handler_:
    position-handler_ = GenericHandler --callback=(:: |a-msg|
      if running_ and a-msg.type == messages.Position.MT:
        position := messages.Position.from-data a-msg.data
        handle-position_ position
    )
    device_.comms.register-handler position-handler_

  subscribe-position-watch_:
    e := catch:
      device_.gnss.subscribe-position --interval=POSITION-WATCH-INTERVAL-MS --message-level=INFO-WATCH-MESSAGE-LEVEL
      logger.info "Position watch subscription active"
    if e:
      logger.warn "Failed to subscribe to position watch: $e"

  handle-position_ position/messages.Position:
    feed
    position-count_ += 1
    last-position-text_ = position-text_ position
    now := Time.now
    if now < last-tx-at_ + (Duration --ms=MIN-LORA-TX-MS):
      skipped-count_ += 1
      maybe-refresh-stats_
      return

    payload := id-prefixed_ last-position-text_
    if payload == null:
      skipped-count_ += 1
      maybe-refresh-stats_
      return

    e := catch:
      device_.lora.send-payload payload --now=true
      last-tx-at_ = now
      last-tx-text_ = payload
      tx-count_ += 1
      logger.info "LoRa position tx: $payload"
    if e:
      skipped-count_ += 1
      logger.warn "Failed to send LoRa position: $e"
    maybe-refresh-stats_

  position-text_ position/messages.Position -> string:
    return "$(position.latitude.to-string --precision=6),$(position.longitude.to-string --precision=6)"

  id-prefixed_ body/string -> string?:
    init-device-id_
    if device-id_ == null:
      return null
    return "$(device-id_):$body"

  show-home_:
    showing-stats_ = false
    e := catch:
      device_.eink.show-preset --page-id=PAGE-HOME
    if e:
      logger.warn "Failed to show home page: $e"

  show-stats_:
    showing-stats_ = true
    draw-stats_ --full=true

  maybe-refresh-stats_:
    if showing-stats_:
      draw-stats_

  draw-stats_ --full/bool=false:
    redraw-type := messages.BasePage.REDRAW-TYPE_PARTIALREDRAW
    if full:
      redraw-type = messages.BasePage.REDRAW-TYPE_FULLREDRAWWITHOUTCLEAR
    e := catch:
      device_.eink.batch --important:
        draw-line_ 0 "LoRa Positions"
        draw-line_ 1 "ID: $(device-id_ == null ? "-" : device-id_.stringify)"
        draw-line_ 2 "Positions: $position-count_"
        draw-line_ 3 "Sent: $tx-count_  Skip: $skipped-count_"
        draw-line_ 4 "Last: $last-position-text_"
        draw-line_ 5 "Tx: $last-tx-text_"
        draw-back-row_
        device_.eink.draw-page --page-id=PAGE-STATS --status-bar-enable=true --redraw-type=redraw-type
    if e:
      logger.warn "Failed to draw stats: $e"

  draw-line_ index/int text/string:
    y := 4 + TEXT-SPACING * index
    device_.eink.draw-element --page-id=PAGE-STATS --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --x=0 --y=y --text=text --fontsize=0 --textalign=messages.DrawElement.TEXTALIGN_LEFT --width=SCREEN-WIDTH --redraw-type=messages.DrawElement.REDRAW-TYPE-BUFFERONLY

  draw-back-row_:
    y := SCREEN-HEIGHT - 15
    device_.eink.draw-element --page-id=PAGE-STATS --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --textalign=messages.DrawElement.TEXTALIGN_MIDDLE --width=SCREEN-WIDTH --x=0 --y=y --text="Back" --redraw-type=messages.DrawElement.REDRAW-TYPE-BUFFERONLY

main:
  provider.main
  client := WatchdogServiceClient
  client.open
  dog := client.create "lb/lora-positions"

  device := devices.I2C
    --log-level=LOG-LEVEL
    --with-default-handlers=true
    --background=false

  app := LoraPositionsApp device dog
  app.start
