import io
import lightbug.modules.comms show Comms
import lightbug.modules.comms.transport show V3Transport

class Reader extends io.Reader with io.InMixin:
  calls /int := 0
  read_ -> ByteArray?:
    calls++
    sleep --ms=10
    return #[]

class Writer extends io.Writer with io.OutMixin:
  try-write_ data/io.Data from/int to/int -> int: return to - from

class Transport implements V3Transport:
  reader := Reader
  in -> io.Reader: return reader
  out -> io.Writer: return Writer
  prefix -> bool: return false
  connected -> bool: return true
  connect:
  disconnect:

main:
  transport := Transport
  comms := Comms --transport=transport --open=false
  sleep --ms=30
  comms.pause-inbound
  before := transport.reader.calls
  if before == 0: throw "reader did not start"
  sleep --ms=30
  if transport.reader.calls != before: throw "reader still running after pause"
  comms.resume-inbound
  comms.resume-inbound // Must not spawn another reader.
  sleep --ms=30
  if transport.reader.calls <= before: throw "reader did not resume"
  comms.pause-inbound
  print "Comms reader stop/join/resume tests passed"
