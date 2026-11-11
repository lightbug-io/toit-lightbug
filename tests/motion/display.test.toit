// Tests motion display pages, controls and graph updates.
// Run as part of the RH2 motion host test suite.

import ...examples.motion.settings as mode
import lightbug.messages show ButtonPress BasePage DrawElement
import motion-fusion show Quaternion Vector3 GRAVITY
import ...examples.motion.display as display
import ...examples.motion.display show Controls
import ...examples.motion.analysis as analysis

class Reply:
  msg-ok/bool := true

class Ink:
  frames := []
  buffered/List? := null
  reply/Reply? := Reply
  inside-batch/bool := false
  elements/List := []
  batch --important [action] -> bool:
    if not important or inside-batch: throw "Display batch was not exclusive"
    inside-batch = true
    error := catch: action.call
    inside-batch = false
    return error == null
  text-page --page-id --page-title --lines --status-bar-enable --buffer --clear:
    if not inside-batch or not buffer or (not clear and buffered == null): throw "Frame buffer not cleared before composition"
    buffered = [page-id, page-title, lines]
    return reply
  draw-page --page-id --status-bar-enable --redraw-type:
    if not inside-batch or buffered == null: throw "Draw occurred before composition"
    // The real FullRedraw command clears RAM before transfer; it would erase
    // the composed frame. FullRedrawWithoutClear must preserve that frame.
    if redraw-type == BasePage.REDRAW-TYPE_FULLREDRAW: buffered = [page-id, "", ["", "", "", ""]]
    frames.add [buffered[0], buffered[1], buffered[2], redraw-type == BasePage.REDRAW-TYPE_FULLREDRAWWITHOUTCLEAR, redraw-type == BasePage.REDRAW-TYPE_PARTIALREDRAW]
    return reply
  draw-element --page-id --status-bar-enable --redraw-type --type --x --y
      --width=null --height=null --fontsize=null --textalign=null --text=null --x2=null --y2=null --linetype=null:
    if not inside-batch: throw "Element outside frame"
    elements.add [type, x, y, x2, y2, linetype, text, redraw-type]
    if redraw-type == DrawElement.REDRAW-TYPE_CLEARDONTDRAW or (width == 249 and height == 121):
      buffered = [page-id, "", ["", "", "", ""]]
    if buffered == null: throw "Box before canvas clear"
    if type == DrawElement.TYPE_BOX and x == 0 and y >= 13:
      index := (y - 13) / 26
      buffered[2][index] = text
    return reply

class Buttons:
  callback_/Lambda? := null
  subscribe --timeout --retries --callback:
    callback_ = callback
    return 1
  press id/int page/int --duration/int=100:
    callback_.call (ButtonPress.from-data (ButtonPress.data --button-id=id --page-id=page --duration=duration))

main:
  ink := Ink
  screen := display.Screen ink
  screen.show 80 "First" ["old"]
  screen.show 81 "Second" ["new"]
  if ink.frames.size != 0: throw "Posting to screen blocked for ink"
  screen.draw-pending_
  if ink.frames.size != 1 or ink.frames[0][1] != "Second": throw "Stale frame queue"
  if ink.frames[0][2] != ["new", "", "", ""] or ink.frames[0][3] != true:
    throw "Page transition did not clear/full redraw"
  screen.show 81 "Progress" ["newer"]
  screen.draw-pending_
  if ink.frames.size != 1: throw "Refresh rate not bounded"
  screen.next-draw-us_ = 0
  screen.draw-pending_
  if ink.frames[1][3] != true or ink.frames[1][1] != "Progress": throw "Setup page was not fully refreshed"
  screen.next-draw-us_ = 0
  screen.show 81 "Clean" ["ghosting refresh"]
  screen.draw-pending_
  if ink.frames[2][3] != true: throw "Setup page was not fully refreshed"
  screen.next-draw-us_ = 0
  ink.reply = null
  before := screen.applied_
  screen.show 81 "No ACK" []
  if (catch: screen.draw-pending_) == null or screen.applied_ != before:
    throw "Unacknowledged display appeared successful"
  if ink.frames.size != 3: throw "Drew a frame whose buffer was not acknowledged"
  ink.reply = Reply
  screen.draw-pending_
  if screen.applied_ == before: throw "Failed frame was not retried"

  window := analysis.Window 0 0
  analysis.WINDOW-SIZE.repeat: window.add (Vector3 0 0 0) GRAVITY true
  features := analysis.Features window
  screen.results features (Quaternion 1 0 0 0) 3 analysis.WINDOW-SIZE 45.0 2 4 false --analysis-ms=123
  if not screen.has-results: throw "Missing result page"
  if not screen.pending_.lines[2].contains "--": throw "Missing frequency shown as a number"
  if not screen.pending_.lines[3].contains "--": throw "Missing regularity shown as a number"
  screen.next-draw-us_ = 0
  screen.draw-pending_
  circles := []
  lines := []
  ink.elements.do:
    if it[0] == DrawElement.TYPE_CIRCLE: circles.add it
    if it[0] == DrawElement.TYPE_LINE: lines.add it
  if circles.size != 2 or lines.size != 3: throw "Expected points and dashed row separators"
  if not (lines.every (: it[5] == DrawElement.LINETYPE_DASHED)): throw "Row separators not dashed"
  if circles[0][1] != 150: throw "Incorrect trace position"
  if ink.frames.last[1] != "" or ink.frames.last[2][0] != "RMS 0.00 m/s2": throw "Result rows not drawn without heading"
  before-elements := ink.elements.size
  screen.results features (Quaternion 1 0 0 0) 3 analysis.WINDOW-SIZE 45.0 2 4 false --analysis-ms=123
  screen.next-draw-us_ = 0
  screen.draw-pending_
  update := ink.elements[before-elements..]
  if update.size != 2 or not (update.every (: it[0] == DrawElement.TYPE_LINE)):
    throw "Unchanged values should send only new line segments"
  if update[0][1] != circles[0][1] + 1 or update[0][3] != update[0][1] + 1: throw "Line endpoints do not join the previous point"
  if circles[0][2] != 13 + 19: throw "Zero baseline margin is incorrect"
  if not ink.frames.last[4]: throw "Live frame did not use partial redraw"
  94.repeat:
    screen.results features (Quaternion 1 0 0 0) 3 analysis.WINDOW-SIZE 45.0 2 4 false --analysis-ms=123
    screen.next-draw-us_ = 0
    screen.draw-pending_
  before-elements = ink.elements.size
  screen.results features (Quaternion 1 0 0 0) 3 analysis.WINDOW-SIZE 45.0 2 4 false --analysis-ms=123
  screen.next-draw-us_ = 0
  screen.draw-pending_
  wrapped := ink.elements[before-elements..]
  if wrapped.size != 6 or wrapped[0][0] != DrawElement.TYPE_BOX or wrapped[0][1] != 150:
    throw "Plot wrap did not clear only the graph area"
  3.repeat: | i |
    if wrapped[1 + i][0] != DrawElement.TYPE_LINE or wrapped[1 + i][5] != DrawElement.LINETYPE_DASHED:
      throw "Plot wrap did not restore separators"
  // A changing value should draw between actual pixel centers. An unavailable
  // value must break the line rather than bridge an unknown interval.
  trace-ink := Ink
  trace := display.Screen trace-ink
  trace.show 85 "" ["", "", "", ""] --boxed --graphs=[0.0, null, null, null]
  trace.draw-pending_
  trace.next-draw-us_ = 0
  trace.show 85 "" ["", "", "", ""] --boxed --graphs=[40.0, null, null, null]
  trace.draw-pending_
  segment := trace-ink.elements.last
  if segment[0] != DrawElement.TYPE_LINE or segment[2] != 33 or segment[4] != 14: throw "Incorrect rising trace"
  trace.next-draw-us_ = 0
  trace.show 85 "" ["", "", "", ""] --boxed --graphs=[null, null, null, null]
  trace.draw-pending_
  trace.next-draw-us_ = 0
  trace.show 85 "" ["", "", "", ""] --boxed --graphs=[10.0, null, null, null]
  trace.draw-pending_
  if trace-ink.elements.last[0] != DrawElement.TYPE_CIRCLE: throw "Trace bridged a missing reading"
  screen.button ButtonPress.BUTTON-ID_DOWN_RIGHT
  if not screen.pending_.lines[0].contains "q w": throw "Next page"
  screen.button ButtonPress.BUTTON-ID_UP_LEFT
  if not screen.pending_.lines[0].contains "RMS": throw "Previous page"
  screen.button ButtonPress.BUTTON-ID_ACTION
  if not screen.exit-requested: throw "Return-to-menu action ignored"
  screen.note-gap
  if not screen.has-results or screen.pending_.page < display.PAGE-RESULTS or screen.pending_.timing != "GAP":
    throw "Gap switched the result page back to collecting"
  screen.status "Keep still" ["Restarting"]
  if screen.has-results: throw "Stale results survived an acquisition gap"
  screen.results features (Quaternion 1 0 0 0) 3 analysis.WINDOW-SIZE 45.0 2 4 false --sample-us=(Time.monotonic-us - 4_000_000)
  before = ink.frames.size
  screen.next-draw-us_ = 0
  screen.draw-pending_
  if ink.frames.size != before + 1 or screen.drawn-timing_ != "STALE": throw "Stale data was not marked inline"
  screen.configure-app mode.FREQUENCY-DOMAIN
  screen.results features (Quaternion 1 0 0 0) 3 analysis.WINDOW-SIZE 45.0 2 4 false
  if not screen.pending_.lines[0].contains "FFT" or not screen.pending_.lines[1].contains "Vertical": throw "Frequency app page"
  screen.button ButtonPress.BUTTON-ID_DOWN_RIGHT
  screen.button ButtonPress.BUTTON-ID_DOWN_RIGHT
  screen.button ButtonPress.BUTTON-ID_DOWN_RIGHT
  if not screen.pending_.lines[0].contains "FFT": throw "Frequency app cycled into time-domain pages"
  screen.configure-app mode.TIME-DOMAIN
  screen.results features (Quaternion 1 0 0 0) 3 analysis.WINDOW-SIZE 45.0 2 4 false
  if not screen.pending_.lines[0].contains "RMS": throw "Time app page"

  buttons := Buttons
  controls := Controls buttons
  controls.start
  buttons.press 0 80 --duration=0
  if controls.poll != null: throw "Accepted release event"
  buttons.press 0 80
  if (controls.poll --page=81) != null: throw "Accepted stale page event"
  buttons.press 2 81
  if (controls.poll --page=81) != 2: throw "Lost active page button"
  20.repeat: buttons.press 0 81
  if controls.events_.size != 8: throw "Unbounded button inbox"
  controls.clear
  if controls.poll != null: throw "Button inbox not drained"
  print "E-ink coalescing, ACK, refresh, results, and button routing tests passed"
