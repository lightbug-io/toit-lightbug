import ..protocol as protocol
import fixed-point show FixedPoint

// Auto generated class for protocol message
class Position extends protocol.Data:

  static MT := 15

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
  static SOURCE := 11
  static CORRECTION-AGE := 12

  constructor:
    super

  // GET
  static get-msg -> protocol.Message:
    msg := protocol.Message MT
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
  static unsubscribe-msg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-UNSUBSCRIBE
    return msg

  // [parser: timestamp]
  timestamp -> Time:
    return Time.epoch --ms=(get-data-uint TIMESTAMP)

  // Raw value for Timestamp before conversion
  timestamp-raw -> int:
    return get-data-uint TIMESTAMP

  // [unit: degree]
  latitude -> float:
    return (get-data-int LATITUDE) / 1e7

  // Raw value for Latitude before conversion
  latitude-raw -> int:
    return get-data-int LATITUDE

  // [unit: degree]
  longitude -> float:
    return (get-data-int LONGITUDE) / 1e7

  // Raw value for Longitude before conversion
  longitude-raw -> int:
    return get-data-int LONGITUDE

  // [unit: meter]
  altitude -> float:
    return (get-data-int ALTITUDE) / 1e3

  // Raw value for Altitude before conversion
  altitude-raw -> int:
    return get-data-int ALTITUDE

  // [unit: meter]
  accuracy -> float:
    return (get-data-uint ACCURACY) / 1e2

  // Raw value for Accuracy before conversion
  accuracy-raw -> int:
    return get-data-uint ACCURACY

  // [unit: degree]
  course -> float:
    return (get-data-uint COURSE) / 1e2

  // Raw value for Course before conversion
  course-raw -> int:
    return get-data-uint COURSE

  // [unit: km/h]
  speed -> float:
    return (get-data-uint SPEED) / 1e2

  // Raw value for Speed before conversion
  speed-raw -> int:
    return get-data-uint SPEED

  satellites -> int:
    return get-data-uint SATELLITES

  cn0 -> int:
    return get-data-uint CN0

  type -> int:
    return get-data-uint TYPE

  source -> int:
    return get-data-uint SOURCE

  // [unit: seconds]
  correction-age -> float:
    return (get-data-uint CORRECTION-AGE) / 10.0

  // Raw value for Correction Age before conversion
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
