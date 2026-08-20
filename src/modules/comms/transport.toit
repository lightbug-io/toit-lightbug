import io

/**
A byte-stream transport carrying V3 protocol messages.

This is deliberately smaller than `devices.Device`: the peer need not be a
Lightbug hardware device. For example, a USB console link has a host computer
at the other end, but it can still use Comms for V3 parsing and acknowledgements.
*/
interface V3Transport:
  in -> io.Reader
  out -> io.Writer

  // Whether outbound V3 messages need the "LB" byte prefix.
  prefix -> bool

  // Physical link lifecycle. Stream transports that are always available can
  // implement these as no-ops and return true from connected.
  connected -> bool
  connect -> none
  disconnect -> none
