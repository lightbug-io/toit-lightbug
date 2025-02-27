import ..protocol as protocol
import coordinate show Coordinate
import fixed-point show FixedPoint

class LastPosition extends protocol.Data:
  static MT := 15
  static TIMESTAMP := 1
  static LATITUDE := 2
  static LONGITUDE := 3
  static ALTITUDE := 4
  static ACCURACY := 5
  static COURSE_OVER_GROUND := 6
  static SPEED := 7
  static NUMBER_OF_SATELLITES := 8
  static AVERAGE_CN0 := 9
  static POSITION_TYPE := 10
  static POSITION_SOURCE := 11

  static LAT_LON_RAW_ADJUSTMENT := 1e7

  static getMsg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.addDataUint8 protocol.Header.TYPE_MESSAGE_METHOD protocol.Header.METHOD-GET
    return msg

  constructor.fromData data/protocol.Data:
    super.fromData data
  
  msg -> protocol.Message:
    return protocol.Message.withData MT this
  
  static subscribeMsg --intervalms/int -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.addDataUint8 protocol.Header.TYPE_MESSAGE_METHOD protocol.Header.METHOD-SUBSCRIBE
    msg.header.data.addDataUint32 protocol.Header.TYPE_SUBSCRIPTION_INTERVAL intervalms // must be uint32
    return msg

  timestamp -> int:
    // TODO return a typed value
    return getDataUintn TIMESTAMP
  coordinate -> Coordinate:
    return Coordinate latitude longitude
  latitude -> float:
    return latitude-float
  longitude -> float:
    return longitude-float
  latitudeFixed -> FixedPoint:
    return ( FixedPoint --decimals=7 latitude-float )
  longitudeFixed -> FixedPoint:
    return ( FixedPoint --decimals=7 longitude-float )
  latitude-float -> float:
    return ( getDataIntn LATITUDE) / LAT_LON_RAW_ADJUSTMENT
  longitude-float -> float:
    return ( getDataIntn LONGITUDE) / LAT_LON_RAW_ADJUSTMENT
  latitude-raw -> int:
    return getDataIntn LATITUDE
  longitude-raw -> int:
    return getDataIntn LONGITUDE
  altitude -> int:
    return getDataUintn ALTITUDE
  accuracy -> int:
    return getDataUintn ACCURACY
  course-over-ground -> int:
    return getDataUintn COURSE_OVER_GROUND
  speed -> int:
    return getDataUintn SPEED
  number-of-satellites -> int:
    return getDataUintn NUMBER_OF_SATELLITES
  average-cn0 -> int:
    return getDataUintn AVERAGE_CN0
  position-type -> int:
    return getDataUintn POSITION_TYPE
  position-source -> int:
    return getDataUintn POSITION_SOURCE

  stringify -> string:
    return {
        "Timestamp": timestamp,
        "Latitude": latitude,
        "Longitude": longitude,
        "Altitude": altitude,
        "Accuracy": accuracy,
        "Course Over Ground": course-over-ground,
        "Speed": speed,
        "Number of Satellites": number-of-satellites,
        "Average CN0": average-cn0,
        "Position Type": position-type,
        "Position Source": position-source,
    }.stringify
