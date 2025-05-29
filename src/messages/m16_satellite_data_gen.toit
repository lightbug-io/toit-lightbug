import ..protocol as protocol

// Auto generated class for protocol message
class SatelliteData extends protocol.Data:

  static MT := 16
  static NAME := "SatelliteData"

  static AVERAGE-SNR := 1
  static MINIMUM-SNR := 2
  static MAXIMUM-SNR := 3
  static TOTAL-SATELLITES := 4
  static GOOD-SATELLITES := 5
  static GPS-L1 := 10
  static GPS-LX := 11
  static GLONASS-L1 := 12
  static GLONASS-LX := 13
  static BEIDOU-L1 := 14
  static BEIDOU-LX := 15
  static GALILEO-L1 := 16
  static GALILEO-LX := 17

  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  // GET
  static get-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg

  // SUBSCRIBE to a message with an optional interval in milliseconds
  static subscribe-msg --ms/int -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SUBSCRIBE
    if ms != null:
      msg.header.data.add-data-uint32 protocol.Header.TYPE-SUBSCRIPTION-INTERVAL ms
    return msg

  // UNSUBSCRIBE
  static unsubscribe-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-UNSUBSCRIBE
    return msg

  average-snr -> int:
    return get-data-uint AVERAGE-SNR

  minimum-snr -> int:
    return get-data-uint MINIMUM-SNR

  maximum-snr -> int:
    return get-data-uint MAXIMUM-SNR

  total-satellites -> int:
    return get-data-uint TOTAL-SATELLITES

  good-satellites -> int:
    return get-data-uint GOOD-SATELLITES

  gps-l1 -> int:
    return get-data-uint GPS-L1

  gps-lx -> int:
    return get-data-uint GPS-LX

  glonass-l1 -> int:
    return get-data-uint GLONASS-L1

  glonass-lx -> int:
    return get-data-uint GLONASS-LX

  beidou-l1 -> int:
    return get-data-uint BEIDOU-L1

  beidou-lx -> int:
    return get-data-uint BEIDOU-LX

  galileo-l1 -> int:
    return get-data-uint GALILEO-L1

  galileo-lx -> int:
    return get-data-uint GALILEO-LX

  stringify -> string:
    return {
      "Average SNR": average-snr,
      "Minimum SNR": minimum-snr,
      "Maximum SNR": maximum-snr,
      "Total Satellites": total-satellites,
      "Good Satellites": good-satellites,
      "GPS L1": gps-l1,
      "GPS Lx": gps-lx,
      "GLONASS L1": glonass-l1,
      "GLONASS Lx": glonass-lx,
      "Beidou L1": beidou-l1,
      "Beidou Lx": beidou-lx,
      "Galileo L1": galileo-l1,
      "Galileo Lx": galileo-lx,
    }.stringify
