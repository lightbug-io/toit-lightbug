// Manages RH2 button input, e-ink pages and incremental motion graphs.
// Used by rh2.toit, session.toit and the motion apps.

import lightbug.messages show ButtonPress TextPage DrawElement
import monitor
import .analysis as analysis
import .settings as settings
import .compass as compass
import motion-fusion show Quaternion

PAGE-SETUP ::= 80
PAGE-ROTATE ::= 81
PAGE-CONFIRM ::= 83
PAGE-GYRO ::= 84
PAGE-RESULTS ::= 85
PAGE-ERROR ::= 89

/** Snapshot owned by the display worker; pending updates replace this whole value. */
class Frame:
  page/int
  title/string
  lines/List
  revision/int
  graphs/List?
  boxed/bool
  timing/string?
  sample-us/int?
  compass-view/compass.View? := null
  generation/int? := null
  constructor .page .title .lines .revision .graphs .boxed .timing .sample-us:

/** A result snapshot remains valid while acquisition prepares the next window. */
class Result:
  features/analysis.Features
  attitude/Quaternion
  generation/int
  corrections/int
  field/float?
  dropped/int
  overruns/int
  magnetic-count/int
  analysis-ms/int?
  sample-us/int?
  constructor .features .attitude .generation .corrections .field .dropped .overruns .magnetic-count .analysis-ms .sample-us:

/** One replaceable pending frame and one worker; acquisition never waits for ink. */
class Screen:
  eink_/any
  pending_/Frame? := null
  revision_/int := 0
  applied_/int := 0
  last-page_/int := -1
  next-draw-us_/int := 0
  latest_/Result? := null
  page_/int := 0
  heading_/bool := false
  exit-requested/bool := false
  plotted_/int := 0
  previous-y_/List := [null, null, null, null]
  drawn-lines_/List? := null
  drawn-timing_/string? := null
  drawn-generation_/int? := null
  gap_/bool := false
  suspended_/bool := false
  drawing_/bool := false
  app_/int := settings.TIME-DOMAIN

  drawn-compass_/compass.View? := null
  next-compass-log-us_/int := 0

  constructor .eink_:

  current-page -> int: return last-page_
  has-results -> bool: return latest_ != null

  start:
    task --background=true::
      while true:
        error := catch:
          if not suspended_:
            drawing_ = true
            try: draw-pending_
            finally: drawing_ = false
        if error:
          print "# e-ink update failed: $error"
          last-page_ = -1
          next-draw-us_ = Time.monotonic-us + 3_000_000
        sleep --ms=(last-page_ == compass.PAGE ? 20 : 100)

  suspend:
    // Finish an in-flight V3 batch before Home/menu takes ownership of ink.
    suspended_ = true
    pending_ = null
    with-timeout --ms=10000:
      while drawing_: sleep --ms=20
    latest_ = null
    last-page_ = -1

  resume:
    exit-requested = false
    pending_ = null
    suspended_ = false

  configure-app selected/int:
    settings.name selected
    app_ = selected
    page_ = selected == settings.FREQUENCY-DOMAIN ? 1 : 0

  show id/int title/string lines/List --graphs/List?=null --boxed/bool=false --timing/string?=null --sample-us/int?=null --generation/int?=null -> int:
    padded := List 4: it < lines.size ? lines[it] : ""
    revision_++
    pending_ = Frame id title padded revision_ graphs boxed timing sample-us
    pending_.generation = generation
    return revision_

  present id/int title/string lines/List:
    revision := show id title lines
    with-timeout --ms=15000:
      while applied_ < revision: sleep --ms=20
    print "# e-ink page $id acknowledged: $title"

  draw-pending_:
    if pending_ == null or Time.monotonic-us < next-draw-us_: return
    frame := pending_
    if frame.compass-view != null:
      draw-compass_ frame
      return
    if frame.sample-us != null and Time.monotonic-us - frame.sample-us > 3_000_000:
      // Keep the page stable; a stale frame must not cause another setup draw.
      frame = Frame frame.page frame.title frame.lines frame.revision null frame.boxed "STALE" null
      frame.generation = pending_.generation
    new-page := frame.page != last-page_
    reset-plot := not new-page and frame.generation != null and frame.generation != drawn-generation_
    full := new-page or not frame.boxed
    if new-page: plotted_ = 0
    previous := (new-page or reset-plot or frame.graphs == null) ? [null, null, null, null] : previous-y_.copy
    stage := "text buffer"
    ok := with-timeout --ms=8000:
      eink_.batch --important=true:
        if frame.boxed:
          4.repeat: | i |
            if new-page or drawn-lines_ == null or frame.lines[i] != drawn-lines_[i]:
              stage = "text box $i"
              redraw := new-page and i == 0 ? DrawElement.REDRAW-TYPE_CLEARDONTDRAW : DrawElement.REDRAW-TYPE_BUFFERONLY
              require-ok_ (eink_.draw-element
                  --page-id=frame.page
                  --status-bar-enable=false
                  --redraw-type=redraw
                  --type=DrawElement.TYPE_BOX
                  --x=0
                  --y=(13 + 26 * i)
                  --width=145
                  --height=20
                  --fontsize=DrawElement.FONTSIZE_MEDIUM
                  --textalign=DrawElement.TEXTALIGN_LEFT
                  --text=frame.lines[i])
          if frame.timing != null and (new-page or frame.timing != drawn-timing_):
            stage = "timing text"
            require-ok_ (eink_.draw-element
                --page-id=frame.page
                --status-bar-enable=false
                --redraw-type=DrawElement.REDRAW-TYPE_BUFFERONLY
                --type=DrawElement.TYPE_BOX
                --x=105
                --y=0
                --width=50
                --height=13
                --fontsize=DrawElement.FONTSIZE_SMALL
                --textalign=DrawElement.TEXTALIGN_RIGHT
                --text=frame.timing)
          if new-page:
            stage = "row separators"
            separators_ frame.page 0
        else:
          // Explicit white fill marks the whole canvas dirty, including areas
          // outside TextPage glyph bounds, before transferring a setup page.
          clear-canvas_ frame.page
          require-ok_ (eink_.text-page
              --page-id=frame.page
              --page-title=frame.title
              --lines=frame.lines
              --status-bar-enable=false
              --buffer=true
              --clear=false)
        if reset-plot:
          clear-plot_ frame.page
          separators_ frame.page 150
          plotted_ = 0
        if frame.graphs != null:
          if plotted_ >= PLOT-POINTS:
            stage = "clear plot"
            clear-plot_ frame.page
            separators_ frame.page 150
            plotted_ = 0
            previous = [null, null, null, null]
          4.repeat: | i |
            value := frame.graphs[i]
            if value != null:
              stage = "trace $i"
              scale := (frame.page - PAGE-RESULTS) * 4 + i
              y := plot-y scale value
              x := 151 + plotted_
              actual-y := 14 + 26 * i + y
              if previous[i] == null:
                require-ok_ (eink_.draw-element
                    --page-id=frame.page
                    --status-bar-enable=false
                    --redraw-type=DrawElement.REDRAW-TYPE_BUFFERONLY
                    --type=DrawElement.TYPE_CIRCLE
                    --x=(x - 1)
                    --y=(actual-y - 1)
                    --width=1)
              else:
                require-ok_ (eink_.draw-element
                    --page-id=frame.page
                    --status-bar-enable=false
                    --redraw-type=DrawElement.REDRAW-TYPE_BUFFERONLY
                    --type=DrawElement.TYPE_LINE
                    --x=(x - 1)
                    --y=previous[i]
                    --x2=x
                    --y2=actual-y)
              previous[i] = actual-y
            else:
              previous[i] = null
        // draw-page flushes custom pages via TextPage. Preserve the composed
        // canvas when requesting a full panel refresh.
        // FullRedraw would clear the freshly composed buffer a second time.
        redraw := full ? TextPage.REDRAW-TYPE_FULLREDRAWWITHOUTCLEAR : TextPage.REDRAW-TYPE_PARTIALREDRAW
        stage = "screen refresh"
        require-ok_ (eink_.draw-page --page-id=frame.page --status-bar-enable=false --redraw-type=redraw)
    if not ok: throw "Display batch failed during $stage"
    last-page_ = frame.page
    applied_ = frame.revision
    drawn-lines_ = frame.lines
    drawn-timing_ = frame.timing
    drawn-generation_ = frame.generation
    previous-y_ = previous
    if frame.graphs != null: plotted_++
    if frame.sample-us != null and settings.LOG-DIAGNOSTICS:
      print "# display lag estimate $((Time.monotonic-us - frame.sample-us) / 1000) ms (sample to display acknowledgement)"
    if pending_ != null and pending_.revision == frame.revision: pending_ = null
    next-draw-us_ = Time.monotonic-us + 250_000

  compass-results q/Quaternion magnetic/bool sample-us/int:
    show compass.PAGE "" [] --sample-us=sample-us
    pending_.compass-view = compass.View (compass.Pose q magnetic) sample-us

  draw-compass_ frame/Frame:
    started := Time.monotonic-us
    view := frame.compass-view
    if Time.monotonic-us - view.sample-us > 2_000_000:
      view = compass.View (compass.Pose (Quaternion 1 0 0 0) false) view.sample-us
      view.pose.mark-stale
    full := last-page_ != compass.PAGE
    unchanged := not full and drawn-compass_ != null and
        view.pose.labels == drawn-compass_.pose.labels and
        (view.pose.angles.map: compass.degrees it) == (drawn-compass_.pose.angles.map: compass.degrees it) and
        view.pose.status == drawn-compass_.pose.status
    building := started
    built := started
    prepared := started
    failure/any := null
    ok := unchanged or (with-timeout --ms=(full ? 15000 : 8000):
      eink_.batch --important=true:
        failure = catch:
          building = Time.monotonic-us
          view.draw eink_ full drawn-compass_ --on-built=(:: built = Time.monotonic-us) --on-prepared=(:: prepared = Time.monotonic-us): | reply | require-ok_ reply
    )
    if failure != null: throw "Compass display failed: $failure"
    if not ok: throw "Compass display batch timed out or was rejected"
    if not unchanged and settings.LOG-DIAGNOSTICS and Time.monotonic-us >= next-compass-log-us_:
      now := Time.monotonic-us
      next-compass-log-us_ = now + 5_000_000
      print "# compass display: sample_to_ack_ms=$((now - view.sample-us) / 1000) draw_ms=$((now - started) / 1000) compose_ms=$((prepared - started) / 1000) batch_wait_ms=$((building - started) / 1000) build_ms=$((built - building) / 1000) buffer_ack_ms=$((prepared - built) / 1000) flush_ms=$((now - prepared) / 1000)"
    if not unchanged: drawn-compass_ = view
    last-page_ = compass.PAGE
    applied_ = frame.revision
    if pending_ != null and pending_.revision == frame.revision: pending_ = null
    // The producer already limits Compass poses to 10 Hz. Do not add another
    // fixed quarter-second pause after the panel/transport has finished.
    next-draw-us_ = 0

  status title/string lines/List:
    latest_ = null
    show PAGE-GYRO title lines

  note-gap:
    gap_ = true
    if latest_ != null: render-results_

  results features/analysis.Features q/Quaternion generation/int corrections/int
      mag-strength/float? dropped/int overruns/int heading/bool --magnetic-count/int=0 --analysis-ms/int?=null --sample-us/int?=null:
    latest_ = Result features q generation corrections mag-strength dropped overruns magnetic-count analysis-ms sample-us
    gap_ = false
    heading_ = heading
    render-results_

  button button/int:
    if latest_ == null: return
    if button == ButtonPress.BUTTON-ID_ACTION:
      exit-requested = true
    else:
      pages := [app_ == settings.FREQUENCY-DOMAIN ? 1 : 0, 2, 3]
      index := pages.index-of page_
      index = (index + (button == ButtonPress.BUTTON-ID_DOWN_RIGHT ? 1 : 2)) % pages.size
      page_ = pages[index]
      render-results_

  render-results_:
    if latest_ == null: return
    f/analysis.Features := latest_.features
    q/Quaternion := latest_.attitude
    lines := []
    title := ""
    if page_ == 0:
      lines = ["RMS $(number f.vector-rms) m/s2", "Vertical $(number f.vertical-rms)",
          "ACF $(number f.autocorrelation-hz) Hz", "Regularity $(number f.regularity)"]
    else if page_ == 1:
      lines = ["FFT $(number f.fft-hz) Hz", "Vertical $(number f.vertical-rms)",
          "0.5-3Hz $(number f.low-power)", "3-10Hz $(number f.high-power)"]
    else if page_ == 2:
      lines = ["q w $(number q.w) x $(number q.x)", "q y $(number q.y) z $(number q.z)",
          "Field $(number latest_.field) uT", heading_ ? "Mag cal: active" : "Heading: off"]
    else:
      lines = ["Generation $(latest_.generation)", "G $(latest_.corrections)/$(analysis.WINDOW-SIZE) M $(latest_.magnetic-count)",
          "Drops $(latest_.dropped) MagOV $(latest_.overruns)", "Middle: motion apps"]
    graphs/List? := null
    if page_ == 0: graphs = [f.vector-rms, f.vertical-rms, f.autocorrelation-hz, f.regularity]
    if page_ == 1: graphs = [f.fft-hz, f.vertical-rms, f.low-power, f.high-power]
    timing/string? := null
    if latest_.analysis-ms != null:
      timing = latest_.analysis-ms > 9999 ? "9999+ms" : "$(latest_.analysis-ms)ms"
    if gap_:
      timing = "GAP"
      graphs = null
    show (PAGE-RESULTS + page_) title lines --graphs=graphs --boxed --timing=timing --sample-us=(gap_ ? null : latest_.sample-us) --generation=latest_.generation

  clear-canvas_ page/int:
    require-ok_ (eink_.draw-element
        --page-id=page
        --status-bar-enable=false
        --redraw-type=DrawElement.REDRAW-TYPE_BUFFERONLY
        --type=DrawElement.TYPE_BOX
        --x=0
        --y=0
        --width=249
        --height=121
        --text="")

  separators_ page/int from/int:
    3.repeat: | i |
      y := 37 + 26 * i
      require-ok_ (eink_.draw-element
          --page-id=page
          --status-bar-enable=false
          --redraw-type=DrawElement.REDRAW-TYPE_BUFFERONLY
          --type=DrawElement.TYPE_LINE
          --x=from
          --y=y
          --x2=248
          --y2=y
          --linetype=DrawElement.LINETYPE_DASHED)

  clear-plot_ page/int:
    require-ok_ (eink_.draw-element
        --page-id=page
        --status-bar-enable=false
        --redraw-type=DrawElement.REDRAW-TYPE_BUFFERONLY
        --type=DrawElement.TYPE_BOX
        --x=150
        --y=13
        --width=98
        --height=108
        --text="")

number value/float? -> string:
  return value == null ? "--" : (value.to-string --precision=2)

require-ok_ reply:
  if reply == null or not reply.msg-ok: throw "Display did not acknowledge"

/** Button callbacks enqueue only; no display work occurs in the V3 callback. */
class ButtonEvent:
  id/int
  page/int
  duration/int
  menu-item/int?
  constructor .id .page .duration .menu-item:

class Controls:
  events_ := monitor.Channel 8
  buttons_/any
  constructor .buttons_:
  start:
    id := buttons_.subscribe --timeout=(Duration --s=3) --retries=1 --callback=(:: | data/ButtonPress |
      if data.duration > 0:
        page := data.has-data ButtonPress.PAGE-ID ? data.page-id : -1
        item := data.has-data ButtonPress.MENU-ITEM ? data.menu-item : null
        events_.try-send (ButtonEvent data.button-id page data.duration item)
    )
    if id == null: throw "Button subscription failed"
  clear:
    while (events_.receive --blocking=false) != null:
      yield
  poll --page/int=-1 -> int?:
    event := read-event
    if event == null: return null
    if page >= 0 and event.page != page: return null
    return event.id
  read-event -> ButtonEvent?: return events_.receive --blocking=false
  wait page/int -> int:
    while true:
      event := poll --page=page
      if event != null: return event
      sleep --ms=20

// A chronological sweep across the RH2's right-hand plot area. On wrap the
// old sweep is cleared; no bitmap history is sent over the shared bus.
PLOT-POINTS ::= 96
PLOT-HEIGHT ::= 19
// Fixed linear full-scale values: acceleration (m/s²), frequency (Hz),
// regularity (unitless), and band power (m²/s⁴). Out-of-range values clip.
PLOT-RANGES := [40.0, 40.0, 5.0, 1.0, 5.0, 40.0, 1000.0, 1000.0]

/** Fixed, bounded mapping so earlier plotted points never need rescaling. */
plot-y row/int value/float -> int:
  if not value.is-finite: throw "INVALID_SPARKLINE_VALUE"
  v := max 0.0 value
  fraction := min 1.0 (v / PLOT-RANGES[row])
  return ((1.0 - fraction) * PLOT-HEIGHT).round.to-int
