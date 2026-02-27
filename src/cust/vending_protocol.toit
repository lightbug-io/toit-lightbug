import io

class VendingProtocol:

  static HEADER := 0x3E
  static BACKSLASH_R := 0x0D
  static BACKSLASH_N := 0x0A

  static BUFFER_SIZE := 100

  // Commands (FROM VENDING).
  static Cmd_SetId := 0xA1
  static Cmd_GetStat := 0xA2
  static Cmd_Auth := 0xA3

  // Responses (FROM DEVICE).
  static Res_SetId := 0xB1
  static Res_GetStat := 0xB2
  static Res_Auth := 0xB3

  // Status codes (FROM DEVICE).
  static Stat_Success := 0xF1
  static Stat_Fail := 0xF2
  static Stat_NoSupport := 0xF3

  static ID_PREFIX_CURRENT := 0x1B
  static ID_PREFIX_SERIAL := 0x2B

  static vending-id-from-current-id current-id/int -> int:
    id32 := current-id & 0xFFFF_FFFF
    return (ID_PREFIX_CURRENT << 32) | id32

  static vending-id-from-serial serial-num/int -> int:
    // Matches C++: deviceIdentifier = serialNum - (serialRange * 1e6).
    device-identifier := serial-num % 1_000_000
    id32 := device-identifier & 0xFFFF_FFFF
    return (ID_PREFIX_SERIAL << 32) | id32

  static clamp-int value/int min/int max/int -> int:
    if value < min: return min
    if value > max: return max
    return value

  static signed-int8-as-byte value/int -> int:
    // Match C++ cast to int8_t, then store as uint8_t.
    signed := clamp-int value -128 127
    if signed < 0: return 256 + signed
    return signed

  static is-valid-command-payload payload/ByteArray -> bool:
    if payload.size < 2: return false
    // C++ protocol uses expectedLen including trailing CR/LF bytes.
    expected-length := payload.size + 2
    checksum := HEADER ^ expected-length
    payload.do: | byte/int |
      checksum ^= byte
    return checksum == 0

  static command-payload-from-frame frame/ByteArray -> ByteArray?:
    // Frame layout is [HEADER, LENGTH, PAYLOAD..., CR, LF].
    if frame.size < 6: return null
    if frame[0] != HEADER: return null

    length := frame[1]
    if length < 4 or length > BUFFER_SIZE: return null
    // LENGTH includes payload+xor+CR+LF, so full frame is LENGTH + 2.
    if frame.size != length + 2: return null

    if frame[frame.size - 2] != BACKSLASH_R: return null
    if frame[frame.size - 1] != BACKSLASH_N: return null

    // Extract [command, data..., xor], excluding trailing CR/LF.
    payload := frame[2..frame.size - 2]
    if not is-valid-command-payload payload: return null

    return payload

  static build-command-frame command/int data/ByteArray=#[] -> ByteArray:
    payload := ByteArray data.size + 1
    payload[0] = command
    data.size.repeat: | i |
      payload[i + 1] = data[i]
    return build-frame payload

  static build-response-frame code/int status/int data/ByteArray=#[] -> ByteArray:
    payload := ByteArray data.size + 2
    payload[0] = code
    payload[1] = status
    data.size.repeat: | i |
      payload[i + 2] = data[i]
    return build-frame payload

  static build-frame payload-without-checksum/ByteArray -> ByteArray:
    // LENGTH must include payload, checksum, CR and LF.
    length := payload-without-checksum.size + 3
    frame := ByteArray length + 2

    frame[0] = HEADER
    frame[1] = length

    checksum := HEADER ^ length
    payload-without-checksum.size.repeat: | i |
      byte := payload-without-checksum[i]
      frame[i + 2] = byte
      checksum ^= byte

    frame[payload-without-checksum.size + 2] = checksum
    frame[payload-without-checksum.size + 3] = BACKSLASH_R
    frame[payload-without-checksum.size + 4] = BACKSLASH_N
    return frame

  static response-for-command-frame frame/ByteArray vending-id/int temperature/int voltage/float -> ByteArray?:
    payload := command-payload-from-frame frame
    if not payload: return null
    return response-for-command-payload payload vending-id temperature voltage

  static response-for-command-payload payload/ByteArray vending-id/int temperature/int voltage/float -> ByteArray?:
    if not is-valid-command-payload payload: return null

    command := payload[0]
    data := payload[1..(payload.size - 1)] // Excludes command and checksum.

    if command == Cmd_GetStat:
      if data.size != 0:
        return build-response-frame Res_GetStat Stat_Fail
      status-data := get-stat-data vending-id temperature voltage
      return build-response-frame Res_GetStat Stat_Success status-data

    // Cmd_SetId and Cmd_Auth are intentionally ignored for now.
    return null

  static get-stat-data vending-id/int temperature/int voltage/float -> ByteArray:
    // Keep payload compatibility with the existing implementation.
    data := ByteArray 9
    io.LITTLE-ENDIAN.put-uint data 5 0 vending-id
    data[6] = signed-int8-as-byte temperature

    voltage-centi := (voltage * 100.0).to-int
    voltage-centi = clamp-int voltage-centi 320 420
    adc-voltage := ((voltage-centi * 1024) / (3 * 151)).to-int
    io.LITTLE-ENDIAN.put-uint16 data 7 adc-voltage

    return data