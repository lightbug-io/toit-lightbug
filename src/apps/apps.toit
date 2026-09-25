import ..devices
import ..services
import ..messages.messages_gen as messages
import ..firmware as firmware
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

  MENU-OPTIONS := [
    "Survey",
    "LoRa",
    "QC",
    "Device Info",
    "Reboot",
    "Go Back",
    ]
  MENU-OPTION-SURVEY := 0
  MENU-OPTION-LORA := 1
  MENU-OPTION-QC:= 2
  MENU-OPTION-DEVICE-INFO := 3
  MENU-OPTION-REBOOT:= 4
  MENU-OPTION-GO-BACK := 5
  DEVICE-INFO-OPTION-BACK := 5

  PAGE-HOME := 1
  PAGE-MENU := 20
  PAGE-DEVICE-INFO := 21

  constructor device/Device dog/Watchdog:
    device_ = device
    dog_ = dog
    self := this

  show-home:
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
                if menu-selection.current == MENU-OPTION-SURVEY:
                  task:: open-survey-app
                else if menu-selection.current == MENU-OPTION-LORA:
                  task:: open-lora-app
                else if menu-selection.current == MENU-OPTION-QC:
                  task:: open-qc-app
                else if menu-selection.current == MENU-OPTION-DEVICE-INFO:
                  self.show-device-info
                else if menu-selection.current == MENU-OPTION-REBOOT:
                  log.info "Rebooting device"
                  device_.comms.send messages.Reset.set-msg
                else if menu-selection.current == MENU-OPTION-GO-BACK:
                  show-home
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
