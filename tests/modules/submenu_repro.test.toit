import monitor
import ...examples.modules.eink.submenu-repro show ReproMenu ReproSleep state-store
import lightbug.messages as messages
import lightbug.protocol as protocol

event id/int page/int row/int? --button/int=2 --duration/int=80 -> protocol.Message:
  data := messages.ButtonPress.data --button-id=button --duration=duration --page-id=page --menu-item=row
  data.add-data-uint 5 id
  msg := protocol.Message.with-data messages.ButtonPress.MT data
  msg.header-add-data-uint32 protocol.Header.TYPE_MESSAGE_ID id
  return msg

check condition/bool message/string:
  if not condition: throw message

main:
  store := state-store --persistent=false
  check (store is Map and store.size == 0) "awake startup requires no storage service"
  menu := ReproMenu store
  check (not (menu.handle-message (event 1 40 0 --button=0))) "handler must permit the generic ACK"
  check (menu.page == 41) "root Actions did not open submenu"
  revision := menu.revision
  for row := 1; row <= 3; row++:
    // P1 can report the same row throughout a burst queued during a display update.
    menu.handle-message (event (row + 1) 41 0)
    check (menu.selected == row and menu.revision == revision) "burst lost a press or requested a reset redraw"
  more := event 5 41 0 --button=0
  menu.handle-message more
  check (menu.page == 42 and menu.selected == 0) "three rapid presses plus Select did not open More"
  revision = menu.revision
  menu.handle-message more
  check (menu.revision == revision and menu.page == 42) "retry repeated a transition"
  menu.handle-message (event 6 41 4)
  check (menu.page == 42 and menu.selected == 0) "old-page event affected the new submenu"
  menu.handle-message (event 7 42 0)
  menu.handle-message (event 8 42 0)
  record := event 9 42 0 --button=0
  menu.handle-message record
  check (menu.actions == 1 and menu.selected == 2 and menu.revision == revision) "action ignored ordered navigation or caused a redraw"
  resumed := ReproMenu store
  resumed.handle-message record
  check (resumed.actions == 1 and resumed.page == 42 and resumed.selected == 2) "sleep restart lost state/deduplication"
  resumed.handle-message (event 10 42 0)
  resumed.handle-message (event 11 42 0 --button=0)
  check (resumed.page == 41) "Back did not restore the parent menu"
  resumed.handle-message (event 12 41 0 --button=1)
  check (resumed.selected == 4) "Left did not wrap to the last row"
  resumed.handle-message (event 13 41 4)
  check (resumed.selected == 0) "Right did not wrap to the first row"
  // Deliberately preserve reception order. A reordered backlog must stay visible.
  resumed.handle-message (event 16 41 0)
  resumed.handle-message (event 15 41 0 --button=1)
  check (resumed.selected == 0 and resumed.last-sequence == 15) "example hid transport reordering"
  resumed.handle-message (event 17 41 0 --duration=1500)
  check (resumed.selected == 4) "long Right did not select the last row"
  resumed.handle-message (event 18 41 4 --button=1 --duration=1500)
  check (resumed.page == 40 and resumed.selected == 0) "long Left did not reopen the example root"
  stress := ReproMenu {:} --replay-reported-row=true
  stress.handle-message (event 1 40 0 --button=0)
  revision = stress.revision
  stress.handle-message (event 2 41 0)
  stress.handle-message (event 3 41 0)
  check (stress.selected == 0 and stress.revision == revision + 2) "stale-row feedback reproduction was lost"
  test-home-restart
  test-sleep-label
  test-sleep-indicator-lifecycle
  print "PASS: home restart, sleep indicator lifecycle, queued directions, Select, no navigation redraws, retries, stale pages, sleep restoration and stale-row reproduction"

test-home-restart:
  menu := ReproMenu {:}
  menu.handle-message (event 1 40 0 --button=0)
  menu.handle-message (event 2 41 0 --button=0)
  check (menu.actions == 1) "test setup did not record an action"
  menu.set-sleep-indicator true
  restart := event 3 1 null
  menu.handle-message restart
  check (menu.page == 40 and menu.selected == 0 and menu.actions == 0) "Right on P1 home did not reset the test"
  check (menu.items[0] == "Actions" and not menu.sleep-indicator) "restart retained the sleep label"
  revision := menu.revision
  menu.handle-message restart
  check (menu.revision == revision) "home restart retry repeated the reset"
  menu.handle-message (event 4 1 null --button=1)
  check (menu.page == 1 and not menu.can-redraw) "Left on home unexpectedly reopened the example"
  menu.handle-message (event 5 1 null)
  check (menu.page == 40 and menu.can-redraw) "Right did not reopen the example after another home event"

test-sleep-label:
  store := {:}
  menu := ReproMenu store
  menu.handle-message (event 1 40 0 --button=0)
  3.repeat: | i | menu.handle-message (event (i + 2) 41 0)
  menu.set-sleep-indicator true
  check (menu.items[0] == "<Deep sleep>" and menu.selected == 3) "sleep label changed the selection"
  separate := ReproMenu {:}
  separate.handle-message (event 1 40 0 --button=0)
  check (separate.items[0] == "Record 0") "sleep label mutated the shared page definition"
  resumed := ReproMenu store
  check (resumed.sleep-indicator and not resumed.can-redraw) "wake startup would redraw before handling the button"
  resumed.handle-message (event 5 41 0 --button=0)
  check (resumed.page == 42 and resumed.items[0] == "Record A" and resumed.can-redraw) "wake Select did not open More before restoring the label"
  resumed.set-sleep-indicator true
  resumed = ReproMenu store
  resumed.handle-message (event 6 42 0)
  check (resumed.selected == 1 and not resumed.sleep-indicator and not resumed.can-redraw) "wake Right was lost or restored the label before the burst settled"
  revision := resumed.revision
  resumed.handle-message (event 7 42 0)
  check (resumed.selected == 2 and resumed.revision == revision) "wake burst caused repeated selection resets"
  resumed.last-activity-us = Time.monotonic-us - 250_000
  check resumed.can-redraw "normal label did not become drawable after the quiet period"
  resumed.set-sleep-indicator true
  resumed.handle-message (event 8 42 0 --button=0)
  check (resumed.actions == 1 and resumed.selected == 2 and resumed.items[0] == "Record A") "sleep label changed the row's action"
  old-format := ReproMenu {"state": [41, 2, 20, 4]}
  check (old-format.page == 41 and not old-format.sleep-indicator) "old saved state could not be restored"

class TestHeartbeats:
  is-running /bool := true
  stop: is-running = false
  start: is-running = true

class TestComms:
  heartbeats := TestHeartbeats
  menu /ReproMenu
  reject /bool := false
  inject-press /bool := false
  prepares /int := 0
  paused /bool := false
  label-at-prepare /string? := null

  constructor .menu:

  send msg/protocol.Message --now/bool --withLatch/bool --timeout/Duration:
    status := 0
    if msg.type == messages.CPU2Sleep.MT and
        (msg.data.get-data-uint messages.CPU2Sleep.SLEEP-TRANSITION) == messages.CPU2Sleep.PREPARE-DEEP-SLEEP:
      prepares++
      label-at-prepare = menu.items[0]
      if reject: status = 5
      if inject-press: menu.handle-message (event 100 40 0)
    reply := protocol.Message 5
    reply.header-add-data-uint8 4 status
    latch := monitor.Latch
    latch.set reply
    return latch

  pause-inbound: paused = true
  resume-inbound: paused = false

class TestDevice:
  i2c-scl /int := 7
  connected /bool := true
  fail-close /bool := false
  disconnect:
    connected = false
    if fail-close: throw "close failed"
  connect: connected = true

class TestSleep extends ReproSleep:
  test-menu_ /ReproMenu
  entered /bool := false
  label-at-entry /string? := null

  constructor comms/TestComms menu/ReproMenu --cancel-before/bool=false:
    test-menu_ = menu
    super comms menu --before-prepare=(:: menu.set-sleep-indicator true; not cancel-before)

  configure-wakeup_ pin-mask/int: null
  enter-sleep_ duration/Duration:
    entered = true
    label-at-entry = test-menu_.items[0]

test-sleep-indicator-lifecycle:
  menu := ReproMenu {:}
  comms := TestComms menu
  device := TestDevice
  coordinator := TestSleep comms menu
  // A fresh wake with no release event must retain the marker, even when the
  // main loop asks about sleep again while waiting for that release.
  menu.set-sleep-indicator true
  check (not (coordinator.deep-sleep device --can-sleep=(:: false))) "idle guard allowed sleep"
  check (menu.sleep-indicator and comms.prepares == 0) "idle guard erased the retained marker before wake RX"
  menu.set-sleep-indicator false
  check (coordinator.deep-sleep device) "accepted attempt did not enter sleep"
  check (coordinator.entered and coordinator.label-at-entry == "<Deep sleep>" and
      comms.label-at-prepare == "<Deep sleep>") "sleep label was not drawn before PREPARE/entry"
  // The simulated native sleep returns; its cleanup represents a cancelled entry.
  check (not menu.sleep-indicator) "returned entry retained the marker"
  menu = ReproMenu {:}
  comms = TestComms menu
  comms.reject = true
  coordinator = TestSleep comms menu
  device = TestDevice
  check (not (coordinator.deep-sleep device)) "rejected sleep entered"
  revision := menu.revision
  check (not menu.sleep-indicator and not coordinator.entered) "rejection retained a false sleep label"
  check (not (coordinator.deep-sleep device)) "rejection cooldown entered sleep"
  check (comms.prepares == 1 and menu.revision == revision) "cooldown flashed the sleep label again"
  menu = ReproMenu {:}
  comms = TestComms menu
  comms.inject-press = true
  coordinator = TestSleep comms menu
  menu.last-activity-us = Time.monotonic-us - 5_000_000
  check (not (coordinator.deep-sleep (TestDevice) --can-sleep=(:: menu.idle))) "press during PREPARE did not cancel sleep"
  check (menu.selected == 1 and not menu.sleep-indicator and not comms.paused) "cancelled entry lost the press or reader"
  menu = ReproMenu {:}
  comms = TestComms menu
  coordinator = TestSleep comms menu --cancel-before=true
  check (not (coordinator.deep-sleep (TestDevice))) "press during marker draw did not cancel sleep"
  check (comms.prepares == 0 and not menu.sleep-indicator) "cancelled redraw still sent PREPARE or retained the label"
  menu = ReproMenu {:}
  comms = TestComms menu
  coordinator = TestSleep comms menu
  device = TestDevice
  device.fail-close = true
  error := catch: coordinator.deep-sleep device
  check (error != null and not menu.sleep-indicator and device.connected and not comms.paused) "failed disconnect left a false sleep label or stopped reader"
