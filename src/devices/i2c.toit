import gpio
import i2c
import io
import log
import io.byte-order show LITTLE-ENDIAN

I2C-ADDRESS-LIGHTBUG := 0x1b

I2C-COMMAND-LIGHTBUG-READABLE-BYTES := 0x01 // Get the number of bytes available to read
I2C-COMMAND-LIGHTBUG-READ := 0x02 // Read data
I2C-COMMAND-LIGHTBUG-WRITE := 0x03 // Write data
I2C-COMMAND-LIGHTBUG-WRITEABLE_BYTES := 0x04 // Get the number of bytes available to write

LBI2CDevice --sda/int --scl/int -> i2c.Device:
  bus := i2c.Bus
    --sda=gpio.Pin sda
    --scl=gpio.Pin scl
    --frequency=400_000
  return bus.device I2C-ADDRESS-LIGHTBUG

class Reader extends io.Reader with io.InMixin:
  device /i2c.Device
  finishWhenEmpty_ /bool

  constructor d/i2c.Device --finishWhenEmpty=false:
    device = d
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
    allExpected := 0
    loops := 0
    // Read from the buffer as fast as possible (as our buffer is bigger)
    // At most 5*(tx buffer), so 5*1000 = 5KB
    while loops <= 5:
      loops++
      // log.debug "Getting number of bytes available to read, loop $loops"
      lenBytes := device.read-address #[I2C-COMMAND-LIGHTBUG-READABLE-BYTES] 2
      lenInt := LITTLE-ENDIAN.uint16 lenBytes 0
      allExpected = allExpected + lenInt
      
      // Taking uart as an example, if there are no bytes, it loops until there are some.
      // uart does this with a read state, for now we will just sleep a bit...
      if lenInt == 0:
        if finishWhenEmpty_:
          log.debug "No bytes to read, finishing"
          return null
        // log.debug "No bytes to read, yielding"
        break // Leave the while loop

      log.debug "Got $lenInt bytes to read"

      while lenInt > 0:
        chunkSize := min lenInt 254
        log.debug "Reading chunk of $chunkSize bytes stage 1"
        device.write #[I2C-COMMAND-LIGHTBUG-READ, chunkSize]
        log.debug "Reading chunk of $chunkSize bytes stage 2"
        b := device.read chunkSize
        if b.size != chunkSize:
          log.error "Failed to read chunk $chunkSize bytes, got $b.size bytes"
          return null
        all += b
        lenInt -= chunkSize

      if all.size != allExpected:
        log.error "Failed to read $allExpected bytes, got $all.size bytes"
        return null

      log.debug "Read $all.size bytes after $loops loops"

    yield // They are in our buffer now, so yield briefly before returning
    return all

class Writer extends io.Writer with io.OutMixin:
  device /i2c.Device
  canWriteBytes /int := 0

  constructor d/i2c.Device:
    device = d

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
    
    bytesInWindow := to - from
    log.debug "Going to write $bytesInWindow bytes"
    log.debug "Bytes: $bytes"

    // Check the receiver has enough space for our bytes before sending...
    // TODO could refactor this to send in smaller chunks if needed?!
    while canWriteBytes == 0:
      log.debug "Updating or waiting for writeable bytes"
      lenBytes := device.read-address #[I2C-COMMAND-LIGHTBUG-WRITEABLE_BYTES] 2
      canWriteBytes = LITTLE-ENDIAN.uint16 lenBytes 0
      log.debug "Can write $canWriteBytes bytes"
      if canWriteBytes == 0:
        log.debug "Waiting for some bytes to be writeable"
        sleep (Duration --ms=50)
      else:
        log.debug "Can write $canWriteBytes bytes, continuing"
    
    currentIndex := from
    readToIndex := 0
    written := 0
    while currentIndex < to and canWriteBytes > 0:
      // Send in batches of 254 
      writing := min (to - currentIndex) (min canWriteBytes 255)
      readToIndex = currentIndex + writing
    
      log.debug "Writing bytes $currentIndex to $readToIndex, $writing bytes"
      log.debug "Bytes: $bytes[currentIndex..readToIndex]"
      sendLen := #[0]
      LITTLE-ENDIAN.put-uint8 sendLen 0 writing
      device.write-address #[I2C-COMMAND-LIGHTBUG-WRITE] sendLen + bytes[currentIndex..readToIndex]
      written += writing
      canWriteBytes -= writing
      currentIndex = readToIndex
    
    log.debug "Wrote $written bytes"
    return written