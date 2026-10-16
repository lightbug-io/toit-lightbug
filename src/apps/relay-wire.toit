import coordinate show Coordinate
import io.byte-order show LITTLE-ENDIAN
import .lora-distance show LoraDistance

// 22 bytes + manufacturer field overhead (4) + flags (3) fits legacy BLE's 31 bytes.
class RelayWire:
  static SIZE ::= 22

  static encode text/string sequence/int -> ByteArray:
    parts := text.split ":"
    if parts.size > 2: throw "Invalid relay payload"
    id := int.parse parts[0]
    if id < 0: throw "Invalid relay id"
    body := parts.size == 1 ? "" : parts[1]
    kind := 0
    coordinate/Coordinate? := null
    if body == "ping": kind = 1
    else if body == "pong": kind = 2
    else if body != "":
      coordinate = LoraDistance.parse body
      if coordinate == null: throw "Invalid relay location"
      kind = 3
    data := ByteArray SIZE
    data[0] = 0x4c
    data[1] = 0x52
    data[2] = 1
    data[3] = kind
    LITTLE-ENDIAN.put-uint16 data 4 (sequence & 0xffff)
    LITTLE-ENDIAN.put-int64 data 6 id
    if coordinate != null:
      LITTLE-ENDIAN.put-int32 data 14 ((coordinate.lat * 1_000_000).round.to-int)
      LITTLE-ENDIAN.put-int32 data 18 ((coordinate.lon * 1_000_000).round.to-int)
    return data

  static decode data/ByteArray -> string?:
    if data.size != SIZE or data[0] != 0x4c or data[1] != 0x52 or data[2] != 1:
      return null
    id := LITTLE-ENDIAN.int64 data 6
    if id < 0: return null
    if data[3] == 0: return "$id"
    if data[3] == 1: return "$id:ping"
    if data[3] == 2: return "$id:pong"
    if data[3] != 3: return null
    lat := (LITTLE-ENDIAN.int32 data 14) / 1_000_000.0
    lon := (LITTLE-ENDIAN.int32 data 18) / 1_000_000.0
    if lat < -90 or lat > 90 or lon < -180 or lon > 180: return null
    return "$id:$(lat.to-string --precision=6),$(lon.to-string --precision=6)"

  static sequence data/ByteArray -> int:
    return LITTLE-ENDIAN.uint16 data 4
