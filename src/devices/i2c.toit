import gpio
import i2c
import io
import log
import io.byte-order show LITTLE-ENDIAN

I2C-ADDRESS-LIGHTBUG := 0x1b

I2C-COMMAND-LIGHTBUG-READABLE-BYTES := 0x01 // Get the number of bytes available to read.
I2C-COMMAND-LIGHTBUG-READ := 0x02 // Read data.
I2C-COMMAND-LIGHTBUG-WRITE := 0x03 // Write data.

// this is not really good style.
// The function was upper-case which made it look like a type.
// Furthermore, the pins to the i2c bus are allocated but never closed.
// Typically this isn't an issue, as most users keep the i2c device forever, but
// in theory you should close the pins when you are done with the i2c device.
lb-i2c-device --sda/int --scl/int -> i2c.Device:
  bus := i2c.Bus
    --sda=gpio.Pin sda
    --scl=gpio.Pin scl
    --frequency=400_000
  return bus.device I2C-ADDRESS-LIGHTBUG

// No need to add the in-mixin. A reader doesn't need any `.in` method.
class Reader extends io.Reader:
  device /i2c.Device
  finishWhenEmpty_ /bool

  constructor .device --finishWhenEmpty=false:
    // XXX: --finishWhenEmpty is not used since factoring out into the lightbug package
    // TODO: Decide if we want to keep it, refactor it, or remove it...
    finishWhenEmpty_ = finishWhenEmpty

  /**
  Reads the next bytes.
  There are no yields in this function, so it will block until there are bytes to read,
    as we want to empty the buffer as soon as possible into our own memory.
  */
  read_ -> ByteArray?:
    // log.debug "calling read_ in LB Reader for i2c"
    all := #[]
    all-expected := 0
    loops := 0
    // Read from the buffer as fast as possible (as our buffer is bigger).
    // At most 5*(tx buffer), so 5*1000 = 5KB.
    while loops <= 5:
      loops++
      // log.debug "Getting number of bytes available to read, loop $loops"
      len-bytes := device.read-address #[I2C-COMMAND-LIGHTBUG-READABLE-BYTES] 2
      len-int := LITTLE-ENDIAN.uint16 len-bytes 0
      all-expected = all-expected + len-int

      // --- This comment looks stale.
      // Taking uart as an example, if there are no bytes, it loops until there are some.
      // uart does this with a read state, for now we will just sleep a bit...
      if len-int == 0:
        if finishWhenEmpty_:
          log.debug "No bytes to read, finishing"
          return null
        // log.debug "No bytes to read, yielding"
        break // Leave the while loop

      log.debug "Got $len-int bytes to read"

      while len-int > 0:
        chunk-size := min len-int 254
        log.debug "Reading chunk of $chunk-size bytes stage 1"
        device.write #[I2C-COMMAND-LIGHTBUG-READ, chunk-size]
        log.debug "Reading chunk of $chunk-size bytes stage 2"
        b := device.read chunk-size
        if b.size != chunk-size:
          log.error "Failed to read chunk $chunk-size bytes, got $b.size bytes"
          return null
        all += b
        len-int -= chunk-size

      if all.size != all-expected:
        log.error "Failed to read $all-expected bytes, got $all.size bytes"
        return null

      log.debug "Read $all.size bytes after $loops loops"

    yield // They are in our buffer now, so yield briefly before returning.
    return all

class Writer extends io.Writer:
  device /i2c.Device

  constructor .device:

  /**
  Writes the given $data to this writer.

  Returns the number of bytes written.
  */
  try-write_ data/io.Data from/int to/int -> int:
    bytes/ByteArray := ?
    if data is ByteArray:
      bytes = data as ByteArray
    else:
      bytes = ByteArray.from data
    log.debug "Writing $bytes.size bytes"
    log.debug "Bytes: $bytes"

    List.chunk-up 0 bytes.size 255: | from/int to/int |
      log.debug "Writing bytes $from to $to"
      log.debug "Bytes: $bytes[from..to]"
      sendLen := #[0]
      LITTLE-ENDIAN.put-uint8 sendLen 0 (to - from)
      device.write-address #[I2C-COMMAND-LIGHTBUG-WRITE] sendLen + bytes[from..to]

      from = to

    return bytes.size
