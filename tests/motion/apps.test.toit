// Tests RH2 menu navigation and app selection.
// Run as part of the RH2 motion host test suite.

import ...examples.motion.rh2 show MotionApps MOTION-APPS PAGE-HOME PAGE-MOTION-APPS
import ...examples.motion.display show ButtonEvent
import lightbug.messages show ButtonPress

class Reply:
  msg-ok/bool := true

class Ink:
  page/int := -1
  items/List := []
  show-preset --page-id:
    page = page-id
    return Reply
  send-menu --page-id --items --selected-item:
    page = page-id
    this.items = items
    if selected-item != 0: throw "Menu did not reset selection"
    return Reply

class Device:
  eink := Ink

class Screen:
  stops/int := 0
  suspend: stops++

class Controls:
  clears/int := 0
  clear: clears++

class Session:
  modes/List := []
  run selected/int: modes.add selected

main:
  dev := Device
  screen := Screen
  controls := Controls
  session := Session
  apps := MotionApps dev screen controls session
  apps.show-home
  if not session.modes.is-empty: throw "Boot launched motion setup"
  apps.handle (ButtonEvent 2 99 100 null)
  if dev.eink.page != PAGE-HOME: throw "Stale button opened menu"
  apps.handle (ButtonEvent 2 PAGE-HOME 100 null)
  if not session.modes.is-empty: throw "Opening Actions launched motion setup"
  if dev.eink.page != PAGE-MOTION-APPS or MOTION-APPS != ["Time domain", "Frequency Domain", "Compass", "Back"]:
    throw "Home Actions did not show the motion apps"
  apps.handle (ButtonEvent 0 PAGE-MOTION-APPS 100 0)
  if session.modes != [0] or dev.eink.page != PAGE-MOTION-APPS: throw "Time app lifecycle"
  apps.handle (ButtonEvent 2 PAGE-MOTION-APPS 100 0)
  // P1 may repeat its pre-press selection when events are queued.
  apps.handle (ButtonEvent 0 PAGE-MOTION-APPS 100 0)
  if session.modes != [0, 1]: throw "Queued selection did not open Frequency Domain"
  apps.handle (ButtonEvent 2 PAGE-MOTION-APPS 100 0)
  apps.handle (ButtonEvent 2 PAGE-MOTION-APPS 100 0)
  apps.handle (ButtonEvent 0 PAGE-MOTION-APPS 100 0)
  if session.modes != [0, 1, 2]: throw "Compass app lifecycle"
  apps.handle (ButtonEvent 1 PAGE-MOTION-APPS 100 0)
  apps.handle (ButtonEvent 0 PAGE-MOTION-APPS 100 3)
  if dev.eink.page != PAGE-HOME: throw "Back did not restore RH2 Home"
  apps.handle (ButtonEvent 2 PAGE-HOME 100 null)
  apps.handle (ButtonEvent 2 PAGE-MOTION-APPS 1200 0)
  if dev.eink.page != PAGE-HOME: throw "Long Right did not restore Home"
  if screen.stops < 4: throw "Menus did not take ink ownership"
  print "Motion apps Home, selection, profile and return navigation tests passed"
