import lightbug.modules.comms as comms_mod
import lightbug.devices as devices
import lightbug.protocol as protocol
import io

// Minimal test reader implementing the operations used by Comms
class TestReader extends io.Reader with io.InMixin:
  buffer_/ByteArray := #[]

  constructor --bytes/ByteArray:
    buffer_ = bytes

  read_ -> ByteArray?:
    if buffer_.size == 0: return null
    b := buffer_
    buffer_ = #[]
    return b

main:
  testProcessInboundMessage
  testProcessInboundMessageWithPrefix

testProcessInboundMessage:
  // Build a simple protocol message using the library
  msg := protocol.Message.with-data 0x0B (protocol.Data) // type doesn't matter for parsing

  // Prepend nothing - the reader expects protocol version as first byte within msg.bytes
  reader := TestReader --bytes=msg.bytes

  // Create a fake device with injected reader
  dev := devices.Fake --open=true --in=reader
  c := comms_mod.Comms --device=dev --startInbound=false --open=false

  // Call single pass
  m := c.processInboundOnce_
  if not m:
    print "❌ Comms failed to parse message in single pass"
    return

  // Basic checks on the returned message
  if m.type != msg.type:
    print "❌ Parsed message type mismatch: wanted $(msg.type) got $(m.type)"
    return

  if m.size != msg.size:
    print "❌ Parsed message size mismatch: wanted $(msg.size) got $(m.size)"
    return

  // Compare the raw bytes for full fidelity
  if m.bytes == msg.bytes:
    print "✅ Comms parsed message with matching bytes, type=$(m.type) size=$(m.size)"
  else:
    print "❌ Parsed message bytes differ"
    print "expected: $(msg.bytes)"
    print "actual:   $(m.bytes)"


testProcessInboundMessageWithPrefix:
  // Build a simple protocol message using the library
  msg := protocol.Message.with-data 0x0B (protocol.Data)

  // LB prefix bytes (as used by Comms when device_.prefix is true)
  prefix := #[0x4c, 0x42]

  // Reader with prefix then message
  reader := TestReader --bytes=(prefix + msg.bytes)

  dev := devices.Fake --open=true --in=reader
  c := comms_mod.Comms --device=dev --startInbound=false --open=false

  // First call should consume 'L' and return null
  a := c.processInboundOnce_
  if a:
    print "❌ Expected first pass to return null (consumed first prefix byte)"
    return

  // Second call should consume 'B' and return null
  b := c.processInboundOnce_
  if b:
    print "❌ Expected second pass to return null (consumed second prefix byte)"
    return

  // Third call should parse the message
  m2 := c.processInboundOnce_
  if not m2:
    print "❌ Expected third pass to return parsed message"
    return

  if m2.bytes == msg.bytes:
    print "✅ Comms parsed message after LB prefix (3rd pass)"
  else:
    print "❌ Parsed message after prefix differs"
    print "expected: $(msg.bytes)"
    print "actual:   $(m2.bytes)"
