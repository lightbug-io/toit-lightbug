import ..devices
import ..services
import ..messages.messages_gen as messages
import ..protocol as protocol
import ..firmware as firmware
import ..modules.comms.message-handler show MessageHandler
import .survey
import .lora
import .qc
import ..modules.eink.menu-selection show MenuSelection
import .survey.strobe-once show strobe-once
import log
import watchdog show Watchdog
import esp32
import system

class Apps:

  device_/Device
  dog_/Watchdog
  is-running_/bool := false
  menu-selection/MenuSelection? := null
  app_/any? := null // TODO make an app interface?
  logger_/log.Logger := log.default.with-name "apps"
  buttons-subscriber-id_/int? := null
  position-handler_/PositionUpdateHandler? := null
  position-subscription-active_/bool := false
  details-generation_/int := 0
  details-back-index_/int := 0

  MENU-OPTIONS := [
    "Apps",
    "Messaging",
    "Device Info",
    "Back",
    ]
  MENU-OPTION-APPS := 0
  MENU-OPTION-MESSAGING := 1
  MENU-OPTION-DEVICE-INFO := 2
  MENU-OPTION-BACK := 3

  APPS-MENU-OPTIONS := [
    "Survey",
    "LoRa",
    "QC",
    "Back",
    ]
  APPS-MENU-OPTION-SURVEY := 0
  APPS-MENU-OPTION-LORA := 1
  APPS-MENU-OPTION-QC := 2
  APPS-MENU-OPTION-BACK := 3

  // These actions deliberately send ordinary V3 messages to CPU1. They make
  // useful, observable P1 functions available without adding a bespoke P2
  // control protocol.
  MESSAGING-MENU-OPTIONS := [
    "Base Page: Home",
    "Base Page: Diagnostics",
    "Buzzer: Positive 1s",
    "Haptics: Pulse 2s",
    "Haptics: QC Fade",
    "Haptics: Strong Click",
    "LED: Blue 3s",
    "Reset: CPU1",
    "Get: Device IDs",
    "Subscribe: Position 1s",
    "Back",
    ]
  MESSAGING-MENU-OPTION-HOME := 0
  MESSAGING-MENU-OPTION-DIAGNOSTICS := 1
  MESSAGING-MENU-OPTION-BUZZER := 2
  MESSAGING-MENU-OPTION-HAPTICS := 3
  MESSAGING-MENU-OPTION-HAPTICS-QC := 4
  MESSAGING-MENU-OPTION-HAPTICS-CLICK := 5
  MESSAGING-MENU-OPTION-LED := 6
  MESSAGING-MENU-OPTION-RESET-P1 := 7
  MESSAGING-MENU-OPTION-DEVICE-IDS := 8
  MESSAGING-MENU-OPTION-POSITION := 9
  MESSAGING-MENU-OPTION-BACK := 10

  P1-PRESET-PAGE-HOME := 1
  P1-PRESET-PAGE-DIAGNOSTICS := 5
  P1-BUZZER-DURATION-MS := 1_000
  P1-HAPTICS-DURATION-MS := 2_000
  P1-LED-DURATION-MS := 3_000
  DEVICE-INFO-OPTION-BACK := 5

  PAGE-HOME := 1
  PAGE-MENU := 20
  PAGE-DEVICE-INFO := 21
  PAGE-APPS-MENU := 22
  PAGE-MESSAGING-MENU := 23
  PAGE-DEVICE-IDS := 24
  PAGE-POSITION := 25

  constructor device/Device dog/Watchdog:
    device_ = device
    dog_ = dog
    self := this

  show-home:
    stop-position-subscription_
    device_.eink.batch --important:
      // logger_.info "HOME"
      device_.eink.show-preset --page-id=PAGE-HOME
      menu-selection = null

  show_menu:
    device_.eink.batch --important:
      // logger_.info "MENU"
      device_.eink.send-menu --page-id=PAGE-MENU --items=MENU-OPTIONS --selected-item=0
      menu-selection = MenuSelection --start=0 --size=MENU-OPTIONS.size

  show-device-info:
    items := [
      menu-row "Variant" firmware.firmware-variant,
      menu-row "Firmware" firmware.firmware-version-string,
      menu-row "Toit SDK" system.app-sdk-version,
      menu-row "Uptime" (format-uptime (Time.monotonic-us --since-wakeup) / 1_000_000),
      menu-row "Reset" (reset-reason-name esp32.reset-reason),
      "Back",
      ]
    device_.eink.batch --important:
      device_.eink.send-menu --page-id=PAGE-DEVICE-INFO --items=items --selected-item=0
      menu-selection = MenuSelection --start=0 --size=items.size

  show-apps-menu:
    device_.eink.batch --important:
      device_.eink.send-menu --page-id=PAGE-APPS-MENU --items=APPS-MENU-OPTIONS --selected-item=0
      menu-selection = MenuSelection --start=0 --size=APPS-MENU-OPTIONS.size

  show-messaging-menu:
    device_.eink.batch --important:
      device_.eink.send-menu --page-id=PAGE-MESSAGING-MENU --items=MESSAGING-MENU-OPTIONS --selected-item=0
      menu-selection = MenuSelection --start=0 --size=MESSAGING-MENU-OPTIONS.size

  send-messaging-action:
    selection := menu-selection.current
    if selection == MESSAGING-MENU-OPTION-HOME:
      logger_.info "Sending V3 BasePage: P1 Home"
      device_.eink.show-preset --page-id=P1-PRESET-PAGE-HOME
    else if selection == MESSAGING-MENU-OPTION-DIAGNOSTICS:
      logger_.info "Sending V3 BasePage: P1 Diagnostics"
      device_.eink.show-preset --page-id=P1-PRESET-PAGE-DIAGNOSTICS
    else if selection == MESSAGING-MENU-OPTION-BUZZER:
      logger_.info "Sending V3 BuzzerControl: Positive for $(P1-BUZZER-DURATION-MS)ms"
      device_.piezo.positive1 --ms=P1-BUZZER-DURATION-MS
    else if selection == MESSAGING-MENU-OPTION-HAPTICS:
      // A duration causes P1 to use continuous RTP haptics, rather than the
      // brief built-in Pulse pattern used by the wrapper previously.
      logger_.info "Sending V3 HapticsControl: Pulse for $(P1-HAPTICS-DURATION-MS)ms"
      msg := messages.HapticsControl.set-msg --base-data=(messages.HapticsControl.data --pattern=messages.HapticsControl.PATTERN_PULSE --intensity=messages.HapticsControl.INTENSITY_MEDIUM)
      msg.header.data.add-data-uint32 protocol.Header.TYPE-SUBSCRIPTION-DURATION P1-HAPTICS-DURATION-MS
      device_.comms.send msg --now=true
    else if selection == MESSAGING-MENU-OPTION-HAPTICS-QC:
      // Exact payload used by gingin's RH2 QC manual-haptics check:
      // HapticsControl(pattern=Fade/1, intensity=Medium/1), no duration.
      logger_.info "Sending V3 HapticsControl: QC Fade"
      msg := messages.HapticsControl.set-msg --base-data=(messages.HapticsControl.data --pattern=messages.HapticsControl.PATTERN_FADE --intensity=messages.HapticsControl.INTENSITY_MEDIUM)
      device_.comms.send msg --now=true
    else if selection == MESSAGING-MENU-OPTION-HAPTICS-CLICK:
      // This is a different P1 haptics path: a direct DRV2605 ROM effect.
      // It intentionally has no duration, as P1 rejects a duration together
      // with a driver pattern.
      logger_.info "Sending V3 HapticsControl: Strong Click"
      msg := messages.HapticsControl.set-msg --base-data=(messages.HapticsControl.data --driver-pattern=messages.HapticsControl.DRIVER-PATTERN_STRONG-CLICK-100)
      device_.comms.send msg --now=true
    else if selection == MESSAGING-MENU-OPTION-LED:
      logger_.info "Sending V3 LEDControl: blue for $(P1-LED-DURATION-MS)ms"
      msg := messages.LEDControl.set-msg --base-data=(messages.LEDControl.data --red=0 --green=0 --blue=255)
      msg.header.data.add-data-uint32 protocol.Header.TYPE-SUBSCRIPTION-DURATION P1-LED-DURATION-MS
      device_.comms.send msg --now=true
    else if selection == MESSAGING-MENU-OPTION-RESET-P1:
      logger_.warn "Sending V3 Reset: CPU1"
      // MT 49 is named CPU1Reset by P1; the generated Toit alias is Reset.
      device_.comms.send messages.Reset.set-msg --now=true
    else if selection == MESSAGING-MENU-OPTION-DEVICE-IDS:
      show-device-ids
    else if selection == MESSAGING-MENU-OPTION-POSITION:
      start-position-subscription
    else if selection == MESSAGING-MENU-OPTION-BACK:
      show_menu

  show-device-ids:
    details-generation_++
    generation := details-generation_
    show-details-menu_ PAGE-DEVICE-IDS [menu-row "Status" "Loading…", "Back"]
    task:: load-device-ids_ generation

  load-device-ids_ generation/int:
    e := catch:
      response := device_.comms.send-new messages.DeviceIDs.get-msg --timeout=(Duration --s=5)
      if generation != details-generation_: return
      if response == null:
        show-details-menu_ PAGE-DEVICE-IDS [menu-row "Status" "No response", "Back"]
        return
      ids := messages.DeviceIDs.from-data response.data
      show-details-menu_ PAGE-DEVICE-IDS [
        menu-row "Device ID" "$(ids.id)",
        menu-row "IMEI" ids.imei,
        menu-row "ICCID" ids.iccid,
        menu-row "SIM2 ICCID" ids.cached-sim2-iccid,
        "Back",
        ]
    if e:
      logger_.warn "Device IDs GET failed: $e"
      if generation == details-generation_:
        show-details-menu_ PAGE-DEVICE-IDS [menu-row "Status" "GET failed", "Back"]

  start-position-subscription:
    stop-position-subscription_
    position-subscription-active_ = true
    position-handler_ = PositionUpdateHandler this
    device_.comms.register-handler position-handler_
    show-details-menu_ PAGE-POSITION [menu-row "Status" "Awaiting position", "Back"]
    logger_.info "Sending V3 Position SUBSCRIBE: interval=1000ms"
    device_.comms.send (messages.Position.subscribe-msg --interval=1_000) --now=true

  stop-position-subscription_:
    if not position-subscription-active_: return
    position-subscription-active_ = false
    details-generation_++
    if position-handler_:
      device_.comms.unregister-handler position-handler_
      position-handler_ = null
    logger_.info "Sending V3 Position UNSUBSCRIBE"
    device_.comms.send messages.Position.unsubscribe-msg --now=true

  handle-position-update position/messages.Position:
    if not position-subscription-active_: return
    show-details-menu_ PAGE-POSITION [
      menu-row "Latitude" (position.latitude.to-string --precision=6),
      menu-row "Longitude" (position.longitude.to-string --precision=6),
      menu-row "Fix" (messages.Position.type-from-int position.type),
      menu-row "Accuracy" "$(position.accuracy.to-string --precision=2)m",
      menu-row "Satellites" "$(position.satellites)",
      "Back",
      ]

  show-details-menu_ page-id/int items/List:
    device_.eink.batch --important:
      device_.eink.send-menu --page-id=page-id --items=items --selected-item=0
      menu-selection = MenuSelection --start=0 --size=items.size
      details-back-index_ = items.size - 1

  // P1's menu renderer treats ASCII Unit Separator (0x1F) as a left/right
  // column break. Keep this in one helper so all Device Info rows align.
  menu-row label/string value/string -> string:
    return "$label$value"

  format-uptime seconds/int -> string:
    days := seconds / 86_400
    hours := (seconds / 3_600) % 24
    minutes := (seconds / 60) % 60
    secs := seconds % 60
    if days > 0: return "$(days)d $(hours)h $(minutes)m"
    if hours > 0: return "$(hours)h $(minutes)m $(secs)s"
    return "$(minutes)m $(secs)s"

  reset-reason-name reason/int -> string:
    if reason == esp32.RESET-POWER-ON: return "Power on"
    if reason == esp32.RESET-SOFTWARE: return "Software"
    if reason == esp32.RESET-PANIC: return "Panic"
    if reason == esp32.RESET-INTERRUPT-WATCHDOG: return "Interrupt watchdog"
    if reason == esp32.RESET-TASK-WATCHDOG: return "Task watchdog"
    if reason == esp32.RESET-OTHER-WATCHDOG: return "Other watchdog"
    if reason == esp32.RESET-DEEPSLEEP: return "Deep sleep"
    if reason == esp32.RESET-BROWNOUT: return "Brownout"
    if reason == esp32.RESET-USB: return "USB"
    if reason == esp32.RESET-JTAG: return "JTAG"
    if reason == esp32.RESET-EFUSE: return "eFuse error"
    if reason == esp32.RESET-POWER-GLITCH: return "Power glitch"
    if reason == esp32.RESET-CPU-LOCKUP: return "CPU lockup"
    if reason == esp32.RESET-EXTERNAL: return "External"
    return "Unknown ($(reason))"

  // Basic app control, similar to SurveyApp.
  start:
    // logger_.info "START"
    is-running_ = true
    self := this

    // Subscribe to buttons if we're not already subscribed.
    if not buttons-subscriber-id_:
      e := catch:
        id := device_.buttons.subscribe --timeout=null --callback=(:: |button-data|
          // We only listen to button presses on page 0...
          if button-data.duration <= 0:
            // Not actually a press... TODO make this nicer
          else:
            task::
              strobe-once:
                device_.strobe.blue
                sleep --ms=50
                device_.strobe.off
            if button-data.duration >= 3000: // 3s any button = home (for now)
              show-home
            else if self.app_ and self.app_.is-running:
              // If an app is running, let it handle button presses
            else if button-data.page-id == PAGE-HOME: // TODO use a preset page const ID
              if button-data.button-id == messages.ButtonPress.BUTTON-ID-DOWN-RIGHT:
                self.show_menu
            else if button-data.page-id == PAGE-MENU:
              if button-data.button-id == messages.ButtonPress.BUTTON-ID-ACTION:
                if menu-selection.current == MENU-OPTION-APPS:
                  self.show-apps-menu
                else if menu-selection.current == MENU-OPTION-MESSAGING:
                  self.show-messaging-menu
                else if menu-selection.current == MENU-OPTION-DEVICE-INFO:
                  self.show-device-info
                else if menu-selection.current == MENU-OPTION-BACK:
                  show-home
              else if button-data.button-id == messages.ButtonPress.BUTTON-ID-DOWN-RIGHT:
                menu-selection.up
              else if button-data.button-id == messages.ButtonPress.BUTTON-ID-UP-LEFT:
                menu-selection.down
            else if button-data.page-id == PAGE-APPS-MENU:
              if button-data.button-id == messages.ButtonPress.BUTTON-ID-ACTION:
                if menu-selection.current == APPS-MENU-OPTION-SURVEY:
                  task:: open-survey-app
                else if menu-selection.current == APPS-MENU-OPTION-LORA:
                  task:: open-lora-app
                else if menu-selection.current == APPS-MENU-OPTION-QC:
                  task:: open-qc-app
                else if menu-selection.current == APPS-MENU-OPTION-BACK:
                  self.show_menu
              else if button-data.button-id == messages.ButtonPress.BUTTON-ID-DOWN-RIGHT:
                menu-selection.up
              else if button-data.button-id == messages.ButtonPress.BUTTON-ID-UP-LEFT:
                menu-selection.down
            else if button-data.page-id == PAGE-MESSAGING-MENU:
              if button-data.button-id == messages.ButtonPress.BUTTON-ID-ACTION:
                self.send-messaging-action
              else if button-data.button-id == messages.ButtonPress.BUTTON-ID-DOWN-RIGHT:
                menu-selection.up
              else if button-data.button-id == messages.ButtonPress.BUTTON-ID-UP-LEFT:
                menu-selection.down
            else if button-data.page-id == PAGE-DEVICE-IDS:
              if button-data.button-id == messages.ButtonPress.BUTTON-ID-ACTION:
                if menu-selection.current == details-back-index_:
                  details-generation_++
                  self.show-messaging-menu
              else if button-data.button-id == messages.ButtonPress.BUTTON-ID-DOWN-RIGHT:
                menu-selection.up
              else if button-data.button-id == messages.ButtonPress.BUTTON-ID-UP-LEFT:
                menu-selection.down
            else if button-data.page-id == PAGE-POSITION:
              if button-data.button-id == messages.ButtonPress.BUTTON-ID-ACTION:
                if menu-selection.current == details-back-index_:
                  self.stop-position-subscription_
                  self.show-messaging-menu
              else if button-data.button-id == messages.ButtonPress.BUTTON-ID-DOWN-RIGHT:
                menu-selection.up
              else if button-data.button-id == messages.ButtonPress.BUTTON-ID-UP-LEFT:
                menu-selection.down
            else if button-data.page-id == PAGE-DEVICE-INFO:
              if button-data.button-id == messages.ButtonPress.BUTTON-ID-ACTION:
                if menu-selection.current == DEVICE-INFO-OPTION-BACK:
                  self.show_menu
              else if button-data.button-id == messages.ButtonPress.BUTTON-ID-DOWN-RIGHT:
                menu-selection.up
              else if button-data.button-id == messages.ButtonPress.BUTTON-ID-UP-LEFT:
                menu-selection.down
            else:
              // logger_.info "BTN miss $button-data"
        )

        if not id:
          logger_.warn "BTN sub fail"
        else:
          buttons-subscriber-id_ = id
          logger_.info "BTN sub $(id)"
      if e:
        logger_.error "BTN sub fail $e"

  open-survey-app:
    // logger_.info "OPEN SURVEY"
    stop
    app_ = SurveyApp device_ this dog_
    app_.start

  open-lora-app:
    stop
    app_ = LoraApp device_ this dog_
    app_.start
  
  open-qc-app:
    stop
    app_ = QCApp device_ this dog_
    app_.start

  stop:
    // logger_.info "STOP"
    is-running_ = false
    // Unsubscribe from buttons if we have a subscriber id
    if buttons-subscriber-id_:
      e := catch: device_.buttons.unsubscribe --subscriber-id=buttons-subscriber-id_ --timeout=null
      // Ignore errors from unsubscribe but clear our id.
      buttons-subscriber-id_ = null

  is-running -> bool:
    return is-running_

class PositionUpdateHandler implements MessageHandler:
  apps_/Apps

  constructor apps/Apps:
    apps_ = apps

  handle-message msg/protocol.Message -> bool:
    if msg.type == messages.Position.MT:
      apps_.handle-position-update (messages.Position.from-data msg.data)
    // The normal Comms policy still ACKs P1's unsolicited Position reports.
    return false
