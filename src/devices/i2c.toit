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

// Updated 31 March 2025
I2C-MAX-READABLE-BYTES := 2000
I2C-MAX-WRITABLE-BYTES := 2000

I2C-WAIT-SLEEP := (Duration --ms=75)

LBI2CDevice --sda/int --scl/int -> i2c.Device:
  bus := i2c.Bus
    --sda=gpio.Pin sda
    --scl=gpio.Pin scl
    --frequency=200_000
    --pull-up=true
  return bus.device I2C-ADDRESS-LIGHTBUG

class Reader extends io.Reader:
  device /i2c.Device
  finishWhenEmpty_ /bool
  logger_ /log.Logger

  constructor .device --finishWhenEmpty=false --logger/log.Logger:
    // XXX: --finishWhenEmpty is not used since factoring out into the lightbug package
    // TODO: Decide if we want to keep it, refactor it, or remove it...
    finishWhenEmpty_ = finishWhenEmpty
    logger_ = logger

  /**
  Reads the next bytes.
  */
  read_ -> ByteArray?:
    b := #[]
    e := catch:
      return read-inner_ b
    if e:
      logger_.error "Error reading from device: $e, got $b.size bytes, sleeping for $I2C-WAIT-SLEEP before retrying"
      sleep I2C-WAIT-SLEEP
    return b

  read-inner_ all/ByteArray -> ByteArray?:
    // logger_.debug "calling read_ in LB Reader for i2c"
    all-expected := 0
    loops := 0
    // Read from the buffer as fast as possible (as our buffer is bigger)
    // At most 5*(tx buffer), so 5*1000 = 5KB
    while loops <= 5:
      loops++
      // logger_.debug "Getting number of bytes available to read, loop $loops"
      len-bytes := device.write-read #[I2C-COMMAND-LIGHTBUG-READABLE-BYTES] 2
      len-int := LITTLE-ENDIAN.uint16 len-bytes 0
      all-expected = all-expected + len-int
      
      // Taking uart as an example, if there are no bytes, it loops until there are some.
      // uart does this with a read state, for now we will just sleep a bit...
      if len-int == 0:
        if finishWhenEmpty_:
          logger_.debug "No bytes to read, finishing"
          return null
        // logger_.debug "No bytes to read, sleeping for $I2C-WAIT-SLEEP" // verbose log
        sleep I2C-WAIT-SLEEP // Sleep as there is no data to read right now, don't overload the bus
        break // Leave the while loop

      // If we are told there are more bytes availbile than the largest Lightbug buffer, ignore it...
      if len-int > I2C-MAX-READABLE-BYTES:
        logger_.info "⚠️ Got some messy readable bytes data, binning, and sleeping for $I2C-WAIT-SLEEP"
        sleep I2C-WAIT-SLEEP
        break

      logger_.debug "Got $len-int bytes to read"

      while len-int > 0:
        chunkSize := min len-int 254
        logger_.debug "Requesting read chunk of $chunkSize bytes"
        device.write #[I2C-COMMAND-LIGHTBUG-READ, chunkSize]
        logger_.debug "Reading chunk of $chunkSize bytes"
        b := device.read chunkSize
        if b.size != chunkSize:
          logger_.error "Failed to read chunk $chunkSize bytes, got $b.size bytes"
          return null
        all += b
        len-int -= chunkSize

      if all.size != all-expected:
        logger_.error "Failed to read $all-expected bytes, got $all.size bytes"
        return null

      logger_.debug "Read $all.size bytes after $loops loops"

    yield // They are in our buffer now, so yield briefly before returning
    return all

class Writer extends io.Writer:
  device /i2c.Device
  can-write-bytes /int := 0
  logger_ /log.Logger

  constructor .device --logger/log.Logger:
    logger_ = logger

  /**
  Writes the given $data to this writer.

  Returns the number of bytes written.
  */
  try-write_ data/io.Data from/int to/int -> int:
    written := 0
    e := catch:
      return try-write-inner_ data from to written
    if e:
      logger_.error "Error writing to device: $e, wrote $written bytes, sleeping for $I2C-WAIT-SLEEP before retrying"
      sleep I2C-WAIT-SLEEP
    return written

  try-write-inner_ data/io.Data from/int to/int written/int -> int:
    bytes/ByteArray := ?
    if data is ByteArray:
      bytes = data as ByteArray
    else:
      bytes = ByteArray.from data
    
    bytes-in-window := to - from
    logger_.debug "Going to write $bytes-in-window bytes"
    logger_.debug "Bytes: $bytes"

    // Check the receiver has enough space for our bytes before sending...
    // TODO could refactor this to send in smaller chunks if needed?!
    while can-write-bytes == 0:
      logger_.debug "Updating or waiting for writeable bytes"
      len-bytes := device.write-read #[I2C-COMMAND-LIGHTBUG-WRITEABLE_BYTES] 2
      can-write-bytes = LITTLE-ENDIAN.uint16 len-bytes 0
      logger_.debug "Write space is $can-write-bytes"
      if can-write-bytes > I2C-MAX-WRITABLE-BYTES:
        // Probably got some messy data, so reset and sleep
        logger_.info "⚠️ Got some messy writable bytes data, binning, and sleeping for $I2C-WAIT-SLEEP"
        can-write-bytes = 0
        sleep I2C-WAIT-SLEEP
      logger_.debug "Can write $can-write-bytes bytes"
      if can-write-bytes == 0:
        logger_.debug "Waiting for some bytes to be writeable, sleeping for $I2C-WAIT-SLEEP"
        sleep I2C-WAIT-SLEEP
      else:
        logger_.debug "Can write $can-write-bytes bytes, continuing"
    
    current-index := from
    read-to-index := 0
    while current-index < to and can-write-bytes > 0:
      // Send in batches of 254 
      writing := min (to - current-index) (min can-write-bytes 255)
      read-to-index = current-index + writing
    
      logger_.debug "Writing bytes $current-index to $read-to-index, $writing bytes"
      logger_.with-level log.DEBUG-LEVEL:
        logger_.debug "Writing bytes $bytes[current-index..read-to-index]"
      send-len := #[0]
      LITTLE-ENDIAN.put-uint8 send-len 0 writing
      device.write-address #[I2C-COMMAND-LIGHTBUG-WRITE] send-len + bytes[current-index..read-to-index]
      written += writing
      can-write-bytes -= writing
      current-index = read-to-index
    
    logger_.debug "Wrote $written bytes"
    return written