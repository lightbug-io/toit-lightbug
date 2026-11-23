// Launches the RH2 motion apps and coordinates the home and app menus.

import lightbug.devices as devices
import lightbug.firmware as firmware
import .display show Screen Controls ButtonEvent PAGE-ERROR require-ok_
import lightbug.messages show ButtonPress
import lightbug.modules.eink.menu-selection show MenuSelection
import .settings as settings
import .session show Session

main:
  firmware.print-startup-line
  dev := devices.I2C --background=false
  screen := Screen dev.eink
  screen.start
  controls := Controls dev.buttons
  controls.start
  apps := MotionApps dev screen controls (Session dev screen controls)
  apps.show-home
  while true:
    event := controls.read-event
    if event != null: apps.handle event
    sleep --ms=20

PAGE-HOME ::= 1
PAGE-MOTION-APPS ::= 70
// Add future apps here and dispatch them in open-app_. Keep Back last.
MOTION-APPS := settings.NAMES + ["Back"]

/** Base-apps Home/Actions behavior, with one event consumer and ink owner. */
class MotionApps:
  dev_/any
  screen_/any
  controls_/any
  session_/any
  page_/int := PAGE-HOME
  selection_ := MenuSelection --start=0 --size=MOTION-APPS.size
  last-p1-selection_/int := 0

  constructor .dev_ .screen_ .controls_ .session_:

  show-home:
    screen_.suspend
    controls_.clear
    require-ok_ (dev_.eink.show-preset --page-id=PAGE-HOME)
    page_ = PAGE-HOME

  show-menu:
    screen_.suspend
    controls_.clear
    require-ok_ (dev_.eink.send-menu --page-id=PAGE-MOTION-APPS --items=MOTION-APPS --selected-item=0)
    selection_ = MenuSelection --start=0 --size=MOTION-APPS.size
    last-p1-selection_ = 0
    page_ = PAGE-MOTION-APPS
    print "# Motion apps: Time domain / Frequency Domain / Compass"

  handle event/ButtonEvent:
    // A queued press belongs to the page visible when it was generated.
    if event.page != page_: return
    if page_ == PAGE-HOME:
      if event.id == ButtonPress.BUTTON-ID_DOWN_RIGHT: show-menu
      return
    if event.duration >= 1000 and event.id == ButtonPress.BUTTON-ID_DOWN_RIGHT:
      show-home
      return
    if event.duration >= 1000 and event.id == ButtonPress.BUTTON-ID_UP_LEFT:
      selection_.select-last
      return
    // P1 reports selection before applying the press and may repeat it for
    // queued events. Match the base-apps synchronization/replay convention.
    if event.menu-item != null:
      if event.menu-item != selection_.current and event.menu-item != last-p1-selection_:
        selection_.synchronize event.menu-item
      last-p1-selection_ = event.menu-item
    if event.id == ButtonPress.BUTTON-ID_UP_LEFT:
      selection_.down
    else if event.id == ButtonPress.BUTTON-ID_DOWN_RIGHT:
      selection_.up
    else if event.id == ButtonPress.BUTTON-ID_ACTION:
      if selection_.current == MOTION-APPS.size - 1: show-home
      else: open-app_ selection_.current

  open-app_ index/int:
    controls_.clear
    error := catch:
      session_.run index
    if error:
      print "# motion app stopped: $error"
      screen_.resume
      screen_.present PAGE-ERROR "Motion stopped" ["See console for details", "Middle: motion apps", "", ""]
      while (controls_.wait PAGE-ERROR) != ButtonPress.BUTTON-ID_ACTION: yield
    show-menu
