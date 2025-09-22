import ..protocol as protocol

// Auto generated class for protocol message
class Position extends protocol.Data:

  static MT := 15
  static MT_NAME := "Position"

  static TIMESTAMP := 1
  static LATITUDE := 2
  static LONGITUDE := 3
  static ALTITUDE := 4
  static ACCURACY := 5
  static COURSE := 6
  static SPEED := 7
  static SATELLITES := 8
  static CN0 := 9
  static TYPE := 10
  static TYPE_INVALID := 0
  static TYPE_FIXED := 1
  static TYPE_RESERVED := 2
  static TYPE_STANDALONE-3D-FIX := 3
  static TYPE_RTK-FLOAT := 4
  static TYPE_RTK-FIX := 5

  static TYPE_STRINGS := {
    0: "invalid",
    1: "fixed",
    2: "reserved",
    3: "standalone 3d fix",
    4: "rtk-float",
    5: "rtk-fix",
  }

  static type-from-int value/int -> string:
    return TYPE_STRINGS.get value --if-absent=(: "unknown")

  static SOURCE := 11
  static SOURCE_GPS := 0
  static SOURCE_RTK := 1

  static SOURCE_STRINGS := {
    0: "gps",
    1: "rtk",
  }

  static source-from-int value/int -> string:
    return SOURCE_STRINGS.get value --if-absent=(: "unknown")

  static CORRECTION-AGE := 12

  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  /**
   * Creates a protocol.Data object with all available fields for this message type.
   *
   * This is a comprehensive helper that accepts all possible fields.
   * For method-specific usage, consider using the dedicated request/response methods.
   *
   * Returns: A protocol.Data object with the specified field values
   */
  static data --base-data/protocol.Data?=protocol.Data -> protocol.Data: return base-data

  /**
   * Creates a GET Request message for Position.
   *
   * Returns: A Message ready to be sent
   */
  static get-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-GET base-data

  // Subscribe to a message with an optional interval in milliseconds
  static subscribe-msg --interval/int?=null --duration/int?=null --timeout/int?=null -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SUBSCRIBE
    // Subscription header options - only add when provided
    if interval != null:
      msg.header.data.add-data-uint32 protocol.Header.TYPE-SUBSCRIPTION-INTERVAL interval
    if duration != null:
      msg.header.data.add-data-uint32 protocol.Header.TYPE-SUBSCRIPTION-DURATION duration
    if timeout != null:
      msg.header.data.add-data-uint32 protocol.Header.TYPE-SUBSCRIPTION-TIMEOUT timeout
    return msg

  /**
   * Creates a UNSUBSCRIBE Request message for Position.
   *
   * Returns: A Message ready to be sent
   */
  static unsubscribe-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-UNSUBSCRIBE base-data

  // [parser: timestamp]
  timestamp -> Time:
    return Time.epoch --ms=(get-data-uint TIMESTAMP)

  // Raw value for Timestamp before conversion
  timestamp-raw -> int:
    return get-data-uint TIMESTAMP

  // [unit: degree]
  latitude -> float:
    return (get-data-int LATITUDE) / 1e7

  // Fixed point representation of Latitude.
  latitude-raw -> int:
    return get-data-int LATITUDE

  // [unit: degree]
  longitude -> float:
    return (get-data-int LONGITUDE) / 1e7

  // Fixed point representation of Longitude.
  longitude-raw -> int:
    return get-data-int LONGITUDE

  // [unit: meter]
  altitude -> float:
    return (get-data-int ALTITUDE) / 1e3

  // Altitude in mm.
  altitude-raw -> int:
    return get-data-int ALTITUDE

  // [unit: meter]
  accuracy -> float:
    return (get-data-uint ACCURACY) / 1e2

  // [unit: cm] Raw value for Accuracy before conversion (division by 1e2)
  accuracy-raw -> int:
    return get-data-uint ACCURACY

  // [unit: degree]
  course -> float:
    return (get-data-uint COURSE) / 1e2

  // Course over ground centi-degrees (cd).
  course-raw -> int:
    return get-data-uint COURSE

  // [unit: km/h]
  speed -> float:
    return (get-data-uint SPEED) / 1e2

  // Speed in meters per second (m/s).
  speed-raw -> int:
    return get-data-uint SPEED

  /**
   * Satellites
   *
   * Unit: count
   */
  satellites -> int:
    return get-data-uint SATELLITES

  /**
   * Average CN0. Carrier to noise density. Higher is better.
   *
   * Unit: dB-Hz
   */
  cn0 -> int:
    return get-data-uint CN0

  /**
   * Position type
   *
   * Valid values:
   * - TYPE_INVALID (0): invalid
   * - TYPE_FIXED (1): fixed
   * - TYPE_RESERVED (2): Can indicate a 2D fix, low accuracy, should be treated as invalid
   * - TYPE_STANDALONE-3D-FIX (3): standalone 3d fix
   * - TYPE_RTK-FLOAT (4): rtk-float
   * - TYPE_RTK-FIX (5): rtk-fix
   */
  type -> int:
    return get-data-uint TYPE

  /**
   * Position source
   *
   * Valid values:
   * - SOURCE_GPS (0): Position has come from a GPS module.
   * - SOURCE_RTK (1): Position has come from an RTK module. This does not mean the position is RTK corrected.
   */
  source -> int:
    return get-data-uint SOURCE

  // [unit: seconds]
  correction-age -> float:
    return (get-data-uint CORRECTION-AGE) / 10.0

  // Raw value for Correction Age before conversion (division by 10)
  correction-age-raw -> int:
    return get-data-uint CORRECTION-AGE

  stringify -> string:
    return {
      "Timestamp": timestamp,
      "Latitude": latitude,
      "Longitude": longitude,
      "Altitude": altitude,
      "Accuracy": accuracy,
      "Course": course,
      "Speed": speed,
      "Satellites": satellites,
      "CN0": cn0,
      "Type": type,
      "Source": source,
      "Correction Age": correction-age,
    }.stringify
