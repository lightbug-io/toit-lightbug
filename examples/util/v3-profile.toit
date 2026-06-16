import lightbug.messages.messages_gen as messages
import lightbug.protocol as protocol
import system

main:
  count := 2_000_000

  // Make bytes
  b := null
  start := Time.monotonic-us
  count.repeat: | i |
    b = (messages.Command.set-msg --base-data=(messages.Command.data --arm-mode=1)).bytes-for-protocol
  end := Time.monotonic-us
  print "Time to create $(count) messages: $((end - start) / 1000) ms"
  print "Last message bytes: $b"


  // Make a message
  m := null
  start = Time.monotonic-us
  count.repeat: | i |
    m = protocol.Message.from-bytes b
  end = Time.monotonic-us
  print "Time to parse $(count) messages: $((end - start) / 1000) ms"
  print "Last message: $m"