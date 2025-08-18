import ..protocol as protocol

// Auto generated class for protocol message
class SatelliteData extends protocol.Data:

  static MT := 16
  static MT_NAME := "SatelliteData"

  static SNR-AVERAGE := 1
  static SNR-MINIMUM := 2
  static SNR-MAXIMUM := 3
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

  // Helper to create a data object for this message type.
  static data --snr-average/int?=null --snr-minimum/int?=null --snr-maximum/int?=null --total-satellites/int?=null --good-satellites/int?=null --gps-l1/ByteArray?=null --gps-lx/ByteArray?=null --glonass-l1/ByteArray?=null --glonass-lx/ByteArray?=null --beidou-l1/ByteArray?=null --beidou-lx/ByteArray?=null --galileo-l1/ByteArray?=null --galileo-lx/ByteArray?=null -> protocol.Data:
    data := protocol.Data
    if snr-average != null: data.add-data-uint SNR-AVERAGE snr-average
    if snr-minimum != null: data.add-data-uint SNR-MINIMUM snr-minimum
    if snr-maximum != null: data.add-data-uint SNR-MAXIMUM snr-maximum
    if total-satellites != null: data.add-data-uint TOTAL-SATELLITES total-satellites
    if good-satellites != null: data.add-data-uint GOOD-SATELLITES good-satellites
    if gps-l1 != null: data.add-data GPS-L1 gps-l1
    if gps-lx != null: data.add-data GPS-LX gps-lx
    if glonass-l1 != null: data.add-data GLONASS-L1 glonass-l1
    if glonass-lx != null: data.add-data GLONASS-LX glonass-lx
    if beidou-l1 != null: data.add-data BEIDOU-L1 beidou-l1
    if beidou-lx != null: data.add-data BEIDOU-LX beidou-lx
    if galileo-l1 != null: data.add-data GALILEO-L1 galileo-l1
    if galileo-lx != null: data.add-data GALILEO-LX galileo-lx
    return data

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

  snr-average -> int:
    return get-data-uint SNR-AVERAGE

  snr-minimum -> int:
    return get-data-uint SNR-MINIMUM

  snr-maximum -> int:
    return get-data-uint SNR-MAXIMUM

  total-satellites -> int:
    return get-data-uint TOTAL-SATELLITES

  good-satellites -> int:
    return get-data-uint GOOD-SATELLITES

  gps-l1 -> ByteArray:
    return get-data GPS-L1

  gps-lx -> ByteArray:
    return get-data GPS-LX

  glonass-l1 -> ByteArray:
    return get-data GLONASS-L1

  glonass-lx -> ByteArray:
    return get-data GLONASS-LX

  beidou-l1 -> ByteArray:
    return get-data BEIDOU-L1

  beidou-lx -> ByteArray:
    return get-data BEIDOU-LX

  galileo-l1 -> ByteArray:
    return get-data GALILEO-L1

  galileo-lx -> ByteArray:
    return get-data GALILEO-LX

  stringify -> string:
    return {
      "SNR Average": snr-average,
      "SNR Minimum": snr-minimum,
      "SNR Maximum": snr-maximum,
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
