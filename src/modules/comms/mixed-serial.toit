import io
import monitor
import uart
import ...protocol as protocol
import .comms show Comms
import .transport show V3Transport
import .serial-framing show SerialFrameReader

/** Single physical UART owner for vending and LB-prefixed V3. A dedicated
    reader is paused/joined before TX changes the UART and pin directions. */
class MixedSerial implements V3Transport:
  port_ := null
  rx-pin_ /int
  tx-pin_ /int
  scanner_ /SerialFrameReader
  frames_ := monitor.Channel 8
  tx-lock_ := monitor.Mutex
  reader_ /Task? := null
  reader-running_ /bool := false
  reader-delivering_ /bool := false
  dispatching_ /bool := false
  pending-writes_ /int := 0
  running_ /bool := false
  last-activity-us /int := 0
  writer_ /SerialWriter? := null
  comms /Comms? := null

  constructor --rx-pin/int --tx-pin/int --require-prefix/bool=true:
    rx-pin_ = rx-pin
    tx-pin_ = tx-pin
    scanner_ = SerialFrameReader --require-prefix=require-prefix
    writer_ = SerialWriter this
    set-rx_
    comms = Comms --transport=this --link-id=protocol.Header.LINK_ID_RS232 --startInbound=false --open=false

  prefix -> bool: return true
  connected -> bool: return port_ != null
  // Comms does not read this stream: run owns framing and calls receive-message.
  in -> io.Reader: return port_.in
  out -> io.Writer: return writer_
  connect:
    if port_ == null: set-rx_
  disconnect:
    running_ = false
    pause-reader_
    if port_ != null: port_.close
    port_ = null

  busy -> bool:
    return scanner_.busy or reader-delivering_ or dispatching_ or pending-writes_ > 0 or frames_.size > 0

  last-receive-us -> int: return scanner_.last-activity-us

  run [on-vending]:
    if running_: throw "Serial reader already running"
    running_ = true
    resume-reader_
    try:
      while true:
        frame := frames_.receive
        if frame is string: throw frame
        dispatching_ = true
        try:
          if frame.v3:
            comms.receive-message (protocol.Message.from-bytes frame.bytes)
          else:
            on-vending.call frame.bytes frame.started-us
        finally:
          dispatching_ = false
    finally:
      disconnect

  transmit bytes/ByteArray:
    pending-writes_++
    try:
      tx-lock_.do:
        // Do not tear down the reader partway through a received frame.
        while scanner_.busy or reader-delivering_: sleep --ms=1
        pause-reader_
        try:
          set-tx_
          port_.out.write bytes --flush=true
        finally:
          set-rx_
          last-activity-us = Time.monotonic-us --since-wakeup
          if running_: resume-reader_
    finally:
      pending-writes_--

  set-rx_:
    if port_ != null: port_.close
    port_ = uart.Port --rx=rx-pin_ --tx=tx-pin_ --baud-rate=9600 --high-priority=true --no-large-buffers

  set-tx_:
    if port_ != null: port_.close
    port_ = uart.Port --rx=tx-pin_ --tx=rx-pin_ --baud-rate=9600 --high-priority=true --no-large-buffers

  pause-reader_:
    if not reader-running_: return
    reader_.cancel
    while reader-running_: yield
    reader_ = null

  resume-reader_:
    if reader-running_: return
    reader-running_ = true
    reader_ = task --background=true::
      try:
        error := catch:
          while running_:
            frame := scanner_.read-next port_.in
            // Never block the physical reader on a full queue: a queued command
            // may itself be waiting to transmit. Bounded overload drops frames.
            if frame != null:
              // Entering a monitor can yield. Keep TX paused until the complete
              // frame has been queued, or cancellation could lose that frame.
              reader-delivering_ = true
              try:
                frames_.try-send frame
              finally:
                reader-delivering_ = false
        if error:
          if frames_.size == frames_.capacity: frames_.receive
          frames_.send "$error"
      finally:
        reader-running_ = false

class SerialWriter extends io.Writer with io.OutMixin:
  serial_ /MixedSerial
  constructor .serial_:
  try-write_ data/io.Data from/int to/int -> int:
    bytes := data is ByteArray ? data : ByteArray.from data
    serial_.transmit bytes[from..to]
    return to - from
