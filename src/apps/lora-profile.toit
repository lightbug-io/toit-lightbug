/** LoRa presets for RH2 devices. */
class LoraProfile:
  static SHORT ::= 0
  static MEDIUM ::= 1
  static LONG ::= 2
  static FAST ::= 3
  static COUNT ::= 4
  static SLOT ::= 0
  static MAX-PAYLOAD ::= 64

  name/string
  code/string
  frequency-hz/int
  sf/int
  coding-rate/int
  tx-power-dbm/int
  duty-percent/int
  id-interval-ms/int
  ping-interval-ms/int
  location-interval-ms/int

  constructor name/string code/string frequency-hz/int sf/int coding-rate/int tx-power-dbm/int duty-percent/int id-interval-ms/int ping-interval-ms/int location-interval-ms/int:
    this.name = name
    this.code = code
    this.frequency-hz = frequency-hz
    this.sf = sf
    this.coding-rate = coding-rate
    this.tx-power-dbm = tx-power-dbm
    this.duty-percent = duty-percent
    this.id-interval-ms = id-interval-ms
    this.ping-interval-ms = ping-interval-ms
    this.location-interval-ms = location-interval-ms

  static at index/int -> LoraProfile:
    if index == SHORT:
      return LoraProfile "Short" "S" 868_100_000 7 1 5 1 5_000 6_000 9_000
    if index == MEDIUM:
      return LoraProfile "Medium" "M" 868_300_000 9 1 5 1 16_000 21_000 29_000
    if index == LONG:
      return LoraProfile "Long" "L" 869_525_000 11 4 14 10 8_000 10_000 16_000
    if index == FAST:
      return LoraProfile "Fast" "F" 869_525_000 7 1 5 10 1_000 1_000 1_000
    throw "Invalid LoRa profile $index"

  interval-ms mode/string -> int:
    if mode == "id": return id-interval-ms
    if mode == "ping" or mode == "pong": return ping-interval-ms
    if mode == "location": return location-interval-ms
    throw "Unknown LoRa mode $mode"

  /** Airtime estimate for these LoRa settings: 125 kHz bandwidth, explicit header, CRC off. */
  airtime-ms bytes/int -> int:
    if bytes < 1 or bytes > MAX-PAYLOAD: throw "LoRa payload must be 1..$MAX-PAYLOAD bytes"
    numerator := 8 * bytes - 4 * sf + 20 + 8
    denominator := 4 * (sf >= 11 ? sf - 2 : sf)
    payload-symbols := (numerator + denominator - 1) / denominator
    symbols := payload-symbols * (coding-rate + 4) + 8 + 12
    airtime-numerator := 1000 * (4 * symbols + 1) * (1 << (sf - 2))
    return (airtime-numerator + 125_000 - 1) / 125_000

  /** 80% of the nominal duty limit, so the app retains RF airtime margin. */
  min-gap-ms bytes/int -> int:
    airtime := airtime-ms bytes
    return (airtime * 100 * 100 + duty-percent * 80 - 1) / (duty-percent * 80)

  stringify -> string:
    return "$name $(frequency-hz / 1_000_000.0)MHz SF$sf CR4/$(coding-rate + 4) $(tx-power-dbm)dBm"
