// Tests e-ink command serialization and acknowledgement behavior.
// Run as part of the RH2 motion host test suite.

import io
import math
import monitor
import lightbug.devices.i2c-device show I2C
import lightbug.modules.comms show Comms
import lightbug.modules.comms.transport show V3Transport
import lightbug.messages show TextPage BasePage ACK DrawElement
import lightbug.protocol as protocol
import ...examples.motion.display show Screen
import ...examples.motion.analysis as analysis
import ...examples.motion.compass as compass
import motion-fusion show Vector3 Quaternion GRAVITY

class Reader extends io.Reader with io.InMixin:
  frames := monitor.Channel 8
  read_ -> ByteArray?: return frames.receive

// Model the STM custom-page contract: BasePage acknowledges the same page ID
// without drawing. Only TextPage's redraw action transfers a custom canvas.
class Peer extends io.Writer with io.OutMixin:
  reader/Reader
  commands/List := []
  dials/List := [ByteArray 392, ByteArray 392, ByteArray 392]
  bitmap-bytes/int := 0
  hold-pair/bool := false
  held-replies/List := []
  paired/bool := false
  reject-next/bool := false
  refreshes/List := []
  page/int := -1
  title/string := ""
  lines/List := ["", "", "", ""]
  constructor .reader:

  try-write_ data/io.Data from/int to/int -> int:
    request := protocol.Message.from-bytes (ByteArray.from data)[from..to]
    commands.add request
    status := reject-next ? 1 : (apply_ request)
    reject-next = false
    reply := protocol.Message ACK.MT
    reply.header-add-data-uint32 protocol.Header.TYPE-RESPONSE-TO-MESSAGE-ID request.msgId
    reply.header-add-data-uint8 protocol.Header.TYPE-MESSAGE-STATUS status
    clearing := request.type == DrawElement.MT and
        (request.data.get-data-uint DrawElement.REDRAW-TYPE) == DrawElement.REDRAW-TYPE_CLEARDONTDRAW
    if hold-pair and not clearing:
      held-replies.add reply.bytes
      if held-replies.size == 2:
        paired = true
        hold-pair = false
        held-replies.do: reader.frames.send it
        held-replies.clear
    else:
      reader.frames.send reply.bytes
    return to - from

  apply_ request/protocol.Message -> int:
    id := request.data.has-data TextPage.PAGE-ID ? (request.data.get-data-uint TextPage.PAGE-ID) : 11
    if request.type == DrawElement.MT:
      kind := request.data.get-data-uint DrawElement.TYPE
      mode := request.data.get-data-uint DrawElement.REDRAW-TYPE
      if kind == DrawElement.TYPE_BOX:
        canvas := request.data.has-data DrawElement.WIDTH and (request.data.get-data-uint DrawElement.WIDTH) == 249
        if mode == DrawElement.REDRAW-TYPE_CLEARDONTDRAW or canvas:
          title = ""
          lines = ["", "", "", ""]
        else if mode != DrawElement.REDRAW-TYPE_BUFFERONLY: return 1
        page = id
        x := request.data.get-data-uint DrawElement.X
        y := request.data.get-data-uint DrawElement.Y
        if x == 0 and y >= 13: lines[(y - 13) / 26] = request.data.get-data-ascii DrawElement.TEXT
        return 0
      if kind == DrawElement.TYPE_BITMAP and mode == DrawElement.REDRAW-TYPE_BUFFERONLY:
        bits := request.data.get-data DrawElement.BITMAP
        width := request.data.get-data-uint DrawElement.WIDTH
        height := request.data.get-data-uint DrawElement.HEIGHT
        x := (request.data.get-data-uint DrawElement.X) - 13
        y := (request.data.get-data-uint DrawElement.Y) - 22
        if bits.size > 255 or width % 8 != 0 or bits.size != width / 8 * height: return 1
        index := x / 83
        column := (x % 83) / 8
        if not 0 <= index < 3 or not 0 <= y < 56: return 1
        stride := width / 8
        height.repeat: | row |
          dials[index].replace ((y + row) * 7 + column) bits (row * stride) ((row + 1) * stride)
        bitmap-bytes += bits.size
        return 0
      if (kind == DrawElement.TYPE_CIRCLE or kind == DrawElement.TYPE_LINE) and mode == DrawElement.REDRAW-TYPE_BUFFERONLY: return 0
      return 1
    if request.type == BasePage.MT:
      if id == page: return 0
      return id > 10 ? 1 : 0
    if request.type != TextPage.MT: return 1
    mode := request.data.has-data TextPage.REDRAW-TYPE ? (request.data.get-data-uint TextPage.REDRAW-TYPE) : 0
    if mode == TextPage.REDRAW-TYPE_FULLREDRAW or mode == TextPage.REDRAW-TYPE_CLEARDONTDRAW:
      title = ""
      lines = ["", "", "", ""]
    page = id
    if request.data.has-data TextPage.PAGE-TITLE:
      title = request.data.get-data-ascii TextPage.PAGE-TITLE
    [TextPage.LINE-1, TextPage.LINE-2, TextPage.LINE-3, TextPage.LINE-4].size.repeat: | i |
      field := TextPage.LINE-1 + i
      if request.data.has-data field: lines[i] = request.data.get-data-ascii field
    if mode != TextPage.REDRAW-TYPE_BUFFERONLY and mode != TextPage.REDRAW-TYPE_CLEARDONTDRAW:
      refreshes.add [page, title, (lines.map: it), mode]
    return 0

class Transport implements V3Transport:
  reader := Reader
  peer/Peer
  constructor: peer = Peer reader
  in -> io.Reader: return reader
  out -> io.Writer: return peer
  prefix -> bool: return false
  connected -> bool: return true
  connect:
  disconnect:

class Device extends I2C:
  test-comms/Comms? := null
  constructor wire/Transport:
    super --connect-now=false --startComms=false
    test-comms = Comms --transport=wire --open=false
  comms -> Comms: return test-comms

main:
  wire := Transport
  device := Device wire
  try:
    ink := device.eink
    // Cancellation during a batch must release its semaphore for later frames.
    timed-out := catch:
      with-timeout --ms=20:
        ink.batch --important=true: sleep --ms=100
    if timed-out == null: throw "Expected batch timeout"
    with-timeout --ms=100:
      if not (ink.batch --important=true: null): throw "Batch did not recover after timeout"
    with-timeout --ms=1000:
      ink.text-page --page-id=80 --page-title="Mag setup" --lines=["Middle: calibrate"] --buffer=true --clear=true
      if not wire.peer.refreshes.is-empty: throw "Buffer command refreshed early"
      ink.draw-page --page-id=80
    if wire.peer.refreshes.size != 1: throw "ACKed buffer flush never drew the custom page"
    if wire.peer.commands.last.type != TextPage.MT: throw "Custom flush used preset-only BasePage"
    if (wire.peer.commands.last.data.get-data-uint TextPage.REDRAW-TYPE) != TextPage.REDRAW-TYPE_FULLREDRAWWITHOUTCLEAR:
      throw "Default buffer flush did not preserve the canvas"
    if wire.peer.refreshes.last[1] != "Mag setup": throw "Flush erased composed title"

    // Reproduce the target's silent ACK path explicitly, so the test cannot
    // accidentally treat BasePage as a custom-page drawing command.
    ink.send-base-page --page-id=80 --redraw-type=BasePage.REDRAW-TYPE_FULLREDRAWWITHOUTCLEAR
    if wire.peer.refreshes.size != 1: throw "Peer model drew a preset-only same-page command"
    ink.draw-page --page-id=1
    if wire.peer.commands.last.type != BasePage.MT: throw "Preset drawing changed transport command"

    // Exercise the actual background worker and its startup present/wait path.
    screen := Screen ink
    screen.start
    with-timeout --ms=1000:
      screen.present 80 "Mag setup" ["Middle: calibrate", "Left: skip"]
    if wire.peer.refreshes.size != 2: throw "First setup screen was ACKed without a draw"
    screen.next-draw-us_ = 0
    with-timeout --ms=1000:
      screen.present 80 "Calibration" ["Turn slowly"]
    frame := wire.peer.refreshes.last
    if frame[1] != "Calibration" or frame[2] != ["Turn slowly", "", "", ""]:
      throw "Same-page redraw retained previous frame content"
    if frame[3] != TextPage.REDRAW-TYPE_FULLREDRAWWITHOUTCLEAR: throw "Setup refresh did not clear old content"
    window := analysis.Window 0 0
    analysis.WINDOW-SIZE.repeat: window.add (Vector3 0 0 0) GRAVITY true
    features := analysis.Features window
    screen.next-draw-us_ = 0
    start := wire.peer.commands.size
    screen.results features (Quaternion 1 0 0 0) 1 256 null 0 0 false --analysis-ms=123
    with-timeout --ms=2000:
      while screen.pending_ != null: sleep --ms=10
    commands := wire.peer.commands[start..]
    last := commands.size - 1
    if commands[0].type != DrawElement.MT or commands[last].type != TextPage.MT: throw "Box frame not followed by flush"
    4.repeat: | i |
      box := commands[i]
      if (box.data.get-data-uint DrawElement.TYPE) != DrawElement.TYPE_BOX: throw "Missing text box"
      if (box.data.get-data-uint DrawElement.Y) != 13 + 26 * i: throw "Wrong text box placement"
    if (commands[4].data.get-data-uint DrawElement.TYPE) != DrawElement.TYPE_BOX: throw "Missing timing text"
    3.repeat: | i |
      line := commands[5 + i]
      if (line.data.get-data-uint DrawElement.TYPE) != DrawElement.TYPE_LINE or
          (line.data.get-data-uint DrawElement.LINETYPE) != DrawElement.LINETYPE_DASHED: throw "Missing dashed separator"
    2.repeat: | i |
      if (commands[8 + i].data.get-data-uint DrawElement.TYPE) != DrawElement.TYPE_CIRCLE: throw "Missing point"
    start = wire.peer.commands.size
    screen.next-draw-us_ = 0
    screen.results features (Quaternion 1 0 0 0) 1 256 null 0 0 false --analysis-ms=123
    with-timeout --ms=2000:
      while screen.pending_ != null: sleep --ms=10
    update := wire.peer.commands[start..]
    if update.size != 3: throw "Expected two line segments and a partial flush"
    2.repeat: | i |
      if (update[i].data.get-data-uint DrawElement.TYPE) != DrawElement.TYPE_LINE: throw "Live update did not draw segments"
    if (update.last.data.get-data-uint TextPage.REDRAW-TYPE) != TextPage.REDRAW-TYPE_PARTIALREDRAW: throw "Live update was not partial"
    // Exercise Compass through the production field encoder, transport and
    // ACK path; an in-memory drawing mock cannot enforce V3 field lengths.
    start = wire.peer.commands.size
    screen.next-draw-us_ = 0
    wire.peer.hold-pair = true
    screen.compass-results (Quaternion 1 0 0 0) true Time.monotonic-us
    with-timeout --ms=2000:
      while screen.pending_ != null: sleep --ms=10
    strips := wire.peer.commands[start..].filter:
      it.type == DrawElement.MT and (it.data.get-data-uint DrawElement.TYPE) == DrawElement.TYPE_BITMAP
    if not wire.peer.paired: throw "Compass waited for the first ACK before sending the second element"
    if strips.size != 6: throw "Compass did not serialize both halves of all dials"
    expected := (compass.Dial math.PI true).bits
    [0, 1].do: | half |
      strip/protocol.Message := strips[half]
      if (strip.data.get-data-uint DrawElement.Y) != 22 + 28 * half: throw "Compass strips not adjacent"
      if (strip.data.get-data DrawElement.BITMAP) != expected[half * 196..(half + 1) * 196]: throw "Compass pixels corrupted on wire"
    if wire.peer.refreshes.last[0] != compass.PAGE: throw "Compass flush never reached peer"
    if wire.peer.refreshes.last[3] != TextPage.REDRAW-TYPE_FULLREDRAWWITHOUTCLEAR: throw "Compass initial flush erased pixels"
    sent-bytes := wire.peer.bitmap-bytes
    screen.next-draw-us_ = 0
    screen.compass-results (Quaternion 1 0 0 1) true Time.monotonic-us
    with-timeout --ms=2000:
      while screen.pending_ != null: sleep --ms=10
    if wire.peer.refreshes.last[3] != TextPage.REDRAW-TYPE_PARTIALREDRAW: throw "Compass live flush not partial"
    if wire.peer.dials[0] != (compass.Dial (-math.PI / 2) true).bits: throw "Compass incremental pixels corrupted on wire"
    if wire.peer.bitmap-bytes - sent-bytes >= 392: throw "Compass resent full dial for a needle change"
    // A NACK drains the other in-flight ACK and prevents a successful commit.
    wire.peer.hold-pair = true
    wire.peer.reject-next = true
    data := DrawElement.data
        --page-id=compass.PAGE
        --redraw-type=DrawElement.REDRAW-TYPE_BUFFERONLY
        --type=DrawElement.TYPE_BOX
        --x=1
        --y=1
        --width=10
        --height=20
        --text=""
    nack := catch: ink.draw-elements [data, data]
    if nack == null or not nack.to-string.contains "element 0 type=0 page=88: status=1":
      throw "Buffered pipeline hid NACK details"
    if not wire.peer.held-replies.is-empty: throw "Pipeline left an ACK undrained"
    before := wire.peer.commands.size
    unsafe := DrawElement.data --redraw-type=DrawElement.REDRAW-TYPE_PARTIALREDRAW
    if (catch: ink.draw-elements [data, unsafe]) == null: throw "Pipeline accepted an early panel refresh"
    if wire.peer.commands.size != before: throw "Invalid pipeline partially reached the peer"
    screen.suspend
    start = wire.peer.commands.size
    screen.show 88 "Old app" ["Obsolete"]
    sleep --ms=150
    if wire.peer.commands.size != start: throw "Suspended worker overwrote menu"
    screen.resume
    sleep --ms=150
    if wire.peer.commands.size != start: throw "Resume replayed a previous app's frame"
    print "Real e-ink/V3 custom flush, presets, and first-screen worker tests passed"
  finally:
    device.comms.pause-inbound
