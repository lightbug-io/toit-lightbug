import lightbug.devices as devices
import lightbug.protocol as protocol
import lightbug.messages.messages_gen as messages
import monitor

SCREEN-WIDTH ::= 250
SCREEN-HEIGHT ::= 122
BYTES-PER-ROW ::= (SCREEN-WIDTH + 7) / 8  // 32 bytes
MAX-ROWS-PER-MESSAGE ::= 255 / BYTES-PER-ROW  // 7 rows

// Creates a bitmap row filled with the specified pattern.
create-row fill-byte/int width/int -> ByteArray:
  return ByteArray width: fill-byte

// Creates a bitmap chunk for a section of rows.
create-bitmap-chunk fill-byte/int rows/int -> ByteArray:
  size := rows * BYTES-PER-ROW
  return ByteArray size: fill-byte

fill-screen device fill-black/bool:
  fill-byte := fill-black ? 0xFF : 0x00
  color-name := fill-black ? "black" : "clear"
  
  print "💬 Filling screen with $color-name pixels..."
  
  y := 0
  message-count := 0
  first-message := true
  
  while y < SCREEN-HEIGHT:
    rows-remaining := SCREEN-HEIGHT - y
    rows-this-chunk := rows-remaining < MAX-ROWS-PER-MESSAGE
        ? rows-remaining
        : MAX-ROWS-PER-MESSAGE
    
    is-last-message := (y + rows-this-chunk) >= SCREEN-HEIGHT
    
    redraw-type/int := ?
    if first-message:
      redraw-type = messages.DrawElement.REDRAW-TYPE_CLEARDONTDRAW
      first-message = false
    else if is-last-message:
      redraw-type = messages.DrawElement.REDRAW-TYPE_FULLREDRAWWITHOUTCLEAR
    else:
      redraw-type = messages.DrawElement.REDRAW-TYPE_BUFFERONLY
    
    device.eink.draw-bitmap
        --async
        --status-bar-enable=false
        --redraw-type=redraw-type
        --x=0
        --y=y
        --width=SCREEN-WIDTH
        --height=rows-this-chunk
        --bitmap=(create-bitmap-chunk fill-byte rows-this-chunk)
        --onComplete=(:: | response |
          print "onComplete $(response.response-to)"
        )
        --onError=(:: | error |
          print "onError $(error)"
        )
        --onTimeout=(:: | id |
          print "onTimeout $(id)"
        )
    
    message-count++
    y += rows-this-chunk

main:
  device := devices.I2C --background=false// --log-level=devices.DEBUG-LEVEL
  
  sleep --ms=2000

  task:: while true:
    fill-screen device true
    sleep --ms=4000

    fill-screen device false
    sleep --ms=4000 // left at 1:10