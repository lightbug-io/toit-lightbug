import ..devices
import ..services
import ..messages.messages_gen as messages
import .survey
import .qc
import ..modules.eink.menu-selection show MenuSelection
import .survey.eink-batch show eink-do-batch
import .survey.strobe-once show strobe-once
import log
import watchdog show Watchdog

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
    "QC",
    "Reboot",
    "Go Back",
    ]
  MENU-OPTION-SURVEY := 0
  MENU-OPTION-QC:= 1
  MENU-OPTION-REBOOT:= 2
  MENU-OPTION-GO-BACK := 3

  PAGE-HOME := 1
  PAGE-MENU := 20

  constructor device/Device dog/Watchdog:
    device_ = device
    dog_ = dog
    self := this

  show-home:
    eink-do-batch --important:
      // logger_.info "HOME"
      device_.eink.show-preset --page-id=PAGE-HOME
      menu-selection = null

  show_menu:
    eink-do-batch --important:
      // logger_.info "MENU"
      device_.eink.send-menu --page-id=PAGE-MENU --items=MENU-OPTIONS --selected-item=0
      menu-selection = MenuSelection --start=0 --size=MENU-OPTIONS.size

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
                else if menu-selection.current == MENU-OPTION-QC:
                  task:: open-qc-app
                else if menu-selection.current == MENU-OPTION-REBOOT:
                  log.info "Rebooting device"
                  device_.comms.send messages.Reset.msg
                else if menu-selection.current == MENU-OPTION-GO-BACK:
                  show-home
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
    app_.show-survey
  
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
