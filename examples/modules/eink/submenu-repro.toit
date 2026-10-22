import esp32
import system.storage
import lightbug.devices as devices
import lightbug.messages as messages
import lightbug.protocol as protocol
import lightbug.modules.comms.message-handler show MessageHandler
import lightbug.modules.power show Cpu2Sleep

// Run from examples: jag watch modules/eink/submenu-repro.toit --device <id>
// Startup / RX / DRAW logs appear in this Jaguar terminal, not P1 RTT ESP logs.
// P1 queues navigation while eInk is busy; RX row can precede that navigation.
// Mirror ordered directions locally; redraw only for page changes by default.
// Open Actions, press Right three times quickly, then Action: this opens More.
// Right on P1's home screen restarts Actions / Info.
// The first item reads <Deep sleep> during sleep; wake input is handled before
// restoring the label. Capture RX / STATE / DRAW / ACTION alongside video.
// Set REPLAY-REPORTED-ROW=true to restore the old row-reset feedback loop.
// Set REFRESH-EVERY-MS=1000 separately to stress same-page redraws.
// Short taps test FIFO ordering; long Right selects the last row, long Left
// reopens this example's root. Actions only log; they have no external effects.
// First compare main and the deep-sleep branch with ENABLE-DEEP-SLEEP=false:
// this isolates the branch's RAM button FIFO from sleep/wake behaviour.
// Then enable sleep on the deep-sleep branch and repeat after an idle wake.
// This example owns the display and, when enabled, whole-chip P2 sleep.
ENABLE-DEEP-SLEEP ::= true
REPLAY-REPORTED-ROW ::= false
REFRESH-EVERY-MS ::= 0
IDLE-US ::= 5_000_000
LABEL-RESTORE-QUIET-US ::= 250_000 // Coalesce the wake burst before a same-page redraw.
HOME-PAGE ::= 1 // P1 PRESET_PAGE_HOME (also used by the disabled-home placeholder).
ROOT-PAGE ::= 40
PAGES ::= {
  40: ["Actions", "Info"],
  41: ["Record 0", "Record 1", "Record 2", "More", "Back"],
  42: ["Record A", "Record B", "Record C", "Back"],
  43: ["Reproduction only", "Back"],
}


main:
  print "SUBMENU REPRO starting; deep-sleep=$ENABLE-DEEP-SLEEP replay-reported-row=$REPLAY-REPORTED-ROW refresh-ms=$REFRESH-EVERY-MS"
  error := catch --trace=true: run-example
  if error:
    print "SUBMENU REPRO failed: $error"
    throw error

run-example:
  if ENABLE-DEEP-SLEEP: esp32.ext1-wakeup-status (1 << 7)
  store := state-store --persistent=ENABLE-DEEP-SLEEP
  // Cold starts must not inherit a sequence from a different P1 session.
  if esp32.reset-reason != esp32.RESET-DEEPSLEEP: store["state"] = null
  menu := ReproMenu store --replay-reported-row=REPLAY-REPORTED-ROW
  print "P1: creating I2C device (SDA=6, SCL=7)"
  device := with-timeout (Duration --s=5):
    devices.I2C
        --open=false
        --startComms=false
        --reinit-on-comms-start=(not ENABLE-DEEP-SLEEP)
        --with-default-handlers=false
        --log-level=devices.INFO-LEVEL
  print "P1: starting communications"
  comms := with-timeout (Duration --s=5): device.comms
  // Accept/persist events inline before Comms ACKs; never draw in this handler.
  comms.register-handler menu
  grace-us := esp32.reset-reason == esp32.RESET-DEEPSLEEP ? 0 : 20_000_000
  boot-us := Time.monotonic-us
  // P1 retains its menu. On wake, do not send the saved selection back before
  // the retained button FIFO has been handled (the press may still be held).
  rendered-revision := esp32.reset-reason == esp32.RESET-DEEPSLEEP ? 0 : -1
  next-refresh-us := 0
  power := ReproSleep comms menu --before-prepare=(::
    if menu.page != HOME-PAGE:
      menu.set-sleep-indicator true
      rendered-revision = draw-menu device menu
    // A press during the marker redraw cancels this attempt.
    menu.idle and (menu.page == HOME-PAGE or
        (menu.sleep-indicator and rendered-revision == menu.revision))
  )
  if ENABLE-DEEP-SLEEP:
    print "P1: starting deep-sleep handshake"
    power.start-awake device
  else:
    require-ok comms (messages.Open.msg --data=null) --stage="OPEN"
    comms.heartbeats.start
    sub := messages.ButtonPress.subscribe-msg
    sub.header-add-data-uint8 protocol.Header.TYPE_STORAGE_LEVEL 10 // S_RAM.
    require-ok comms sub --stage="Button SUBSCRIBE"

  while true:
    now-us := Time.monotonic-us
    if menu.can-redraw and (rendered-revision != menu.revision or
        (REFRESH-EVERY-MS > 0 and now-us >= next-refresh-us)):
      rendered-revision = draw-menu device menu
      next-refresh-us = Time.monotonic-us + REFRESH-EVERY-MS * 1000
    if ENABLE-DEEP-SLEEP and now-us - boot-us >= grace-us:
      power.deep-sleep device --duration=(Duration --h=1)
          --can-sleep=(:: (menu.page == HOME-PAGE or rendered-revision == menu.revision) and menu.idle)
    sleep --ms=25

// Keep the example's display hook outside the shared sleep implementation.
// It runs before PREPARE while the inbound reader and ordinary commands work.
class ReproSleep extends Cpu2Sleep:
  menu_ /ReproMenu
  before-prepare_ /Lambda
  preparing_ /bool := false

  constructor comms .menu_ --before-prepare/Lambda:
    before-prepare_ = before-prepare
    super comms

  prepare -> bool:
    preparing_ = true
    if not before-prepare_.call: return false
    return super

  deep-sleep device --duration/Duration=(Duration --h=1)
      --can-sleep/Lambda=(:: true) -> bool:
    preparing_ = false
    try:
      return super device --duration=duration --can-sleep=can-sleep
    finally:
      // A real sleep never returns. NACKs, races and failures must not leave
      // an awake device displaying the sleep marker.
      // An idle check alone must not erase a retained marker before the wake RX.
      if preparing_: menu_.set-sleep-indicator false

draw-menu device menu/ReproMenu -> int:
  revision := menu.revision
  page := menu.page
  row := menu.selected
  items := menu.items
  print "DRAW revision=$revision page=$page row=$row first=$(items[0])"
  reply := with-timeout (Duration --s=5):
    device.eink.send-menu --page-id=page --items=items --selected-item=row
  if reply == null or reply.msg-status != 0: throw "Menu draw rejected: $reply"
  return revision

state-store --persistent/bool -> any:
  // The awake comparison needs no storage service/container on plain Jaguar.
  if not persistent: return {:}
  print "P2: opening persistent RAM storage (deep-sleep only)"
  return with-timeout (Duration --s=5):
    storage.Bucket.open --ram "lightbug/submenu-repro"

require-ok comms msg/protocol.Message --stage/string:
  print "P1: $stage"
  reply := with-timeout (Duration --s=5):
    (comms.send msg --now=true --withLatch=true --timeout=(Duration --s=5)).get
  if reply == null or reply.msg-status != 0: throw "$stage rejected: $reply"
  print "P1: $stage OK"

// Kept in the example so the exact P2 state transitions can also run on host.
// No sorting or buffering here: a decreasing RX sequence exposes transport order.
class ReproMenu implements MessageHandler:
  store_ /any
  replay-reported-row_ /bool
  page /int := ROOT-PAGE
  selected /int := 0
  revision /int := 0
  actions /int := 0
  sleep-indicator /bool := false
  restoring-label_ /bool := false
  last-sequence /int? := null
  last-activity-us /int := Time.monotonic-us

  constructor .store_ --replay-reported-row/bool=false:
    replay-reported-row_ = replay-reported-row
    state := store_.get "state" --if-absent=(: null)
    if state:
      page = state[0]
      selected = state[1]
      last-sequence = state[2]
      actions = state[3]
      sleep-indicator = state.size > 4 ? state[4] : false

  items -> List:
    if page == HOME-PAGE: return []
    if not sleep-indicator: return PAGES[page]
    result := []
    PAGES[page].do: | item | result.add item
    result[0] = "<Deep sleep>"
    return result

  idle -> bool:
    return Time.monotonic-us - last-activity-us >= IDLE-US

  can-redraw -> bool:
    return page != HOME-PAGE and not sleep-indicator and
        (not restoring-label_ or Time.monotonic-us - last-activity-us >= LABEL-RESTORE-QUIET-US)

  set-sleep-indicator sleeping/bool:
    if sleeping == sleep-indicator: return
    sleep-indicator = sleeping
    restoring-label_ = false
    revision++
    save_

  save_:
    store_["state"] = [page, selected, last-sequence, actions, sleep-indicator]

  handle-message msg/protocol.Message -> bool:
    if msg.type != messages.ButtonPress.MT: return false
    button := messages.ButtonPress.from-data msg.data
    sequence := msg.data.has-data 5 ? (msg.data.get-data-uint 5) : msg.msgId
    row := button.has-data messages.ButtonPress.MENU-ITEM ? button.menu-item : null
    print "RX id=$(msg.msgId) seq=$sequence page=$(button.page-id) row=$row button=$(button.button-id) ms=$(button.duration)"
    last-activity-us = Time.monotonic-us
    if sequence != null and sequence == last-sequence:
      print "RETRY seq=$sequence (ACK again, no action)"
      return false
    if sequence != null and last-sequence != null and sequence < last-sequence:
      print "OUT-OF-ORDER previous=$last-sequence received=$sequence"
    last-sequence = sequence
    before := revision
    previous-page := page
    if button.page-id == HOME-PAGE:
      if button.button-id == messages.ButtonPress.BUTTON-ID_DOWN_RIGHT and button.duration >= 20:
        page = ROOT-PAGE
        selected = 0
        actions = 0
        revision++
        print "RESTART: Actions / Info"
      else:
        page = HOME-PAGE
        selected = 0
    else if button.page-id == page and button.has-data messages.ButtonPress.MENU-ITEM and
        button.menu-item >= 0 and button.menu-item < items.size:
      if replay-reported-row_:
        // Deliberate reproduction of the original example's stale-row reset.
        selected = button.menu-item
      if button.button-id == messages.ButtonPress.BUTTON-ID_ACTION:
        activate_
      else if not replay-reported-row_ and button.duration >= 20:
        if button.button-id == messages.ButtonPress.BUTTON-ID_DOWN_RIGHT:
          selected = button.duration >= 1000 ? items.size - 1 : (selected + 1) % items.size
        else if button.button-id == messages.ButtonPress.BUTTON-ID_UP_LEFT:
          if button.duration >= 1000:
            page = ROOT-PAGE
            selected = 0
            revision++
          else:
            selected = (selected + items.size - 1) % items.size
      if replay-reported-row_ and revision == before: revision++
    else:
      print "STALE/INVALID event page=$(button.page-id); active=$page"
    // Apply the wake press using the real actions, then remove the visual marker.
    // A page change already requires a redraw; navigation within a page needs
    // one coalesced label restoration, not a selection reset per queued press.
    if sleep-indicator:
      sleep-indicator = false
      restoring-label_ = page == previous-page
      if page != HOME-PAGE and revision == before: revision++
    if page != previous-page: restoring-label_ = false
    print "STATE page=$page row=$selected revision=$revision"
    // RTC RAM survives deep sleep. Acceptance precedes the generic positive ACK.
    save_
    return false

  activate_:
    target := page
    if page == ROOT-PAGE:
      target = selected == 0 ? 41 : 43
    else if page == 41 and selected == 3:
      target = 42
    else if selected == items.size - 1:
      target = page == 42 ? 41 : ROOT-PAGE
    else:
      actions++
      print "ACTION page=$page row=$selected count=$actions (record only)"
    if target != page:
      page = target
      selected = 0
      revision++
