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
  static COURSE-OVER-GROUND := 6
  static SPEED := 7
  static NUMBER-OF-SATELLITES := 8
  static AVERAGE-CN0 := 9
  static POSITION-TYPE := 10
  static POSITION-SOURCE := 11

  static LAT-LON-RAW-ADJUSTMENT := 1e7

  static getMsg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.addDataUint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg

  constructor.fromData data/protocol.Data:
    super.fromData data
  
  msg -> protocol.Message:
    return protocol.Message.withData MT this
  
  static subscribeMsg --intervalms/int -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.addDataUint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SUBSCRIBE
    msg.header.data.addDataUint32 protocol.Header.TYPE-SUBSCRIPTION-INTERVAL intervalms // must be uint32
    return msg

  timestamp -> int:
    // TODO return a typed value
    return getDataUint TIMESTAMP
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
    return ( getDataIntn LATITUDE) / LAT-LON-RAW-ADJUSTMENT
  longitude-float -> float:
    return ( getDataIntn LONGITUDE) / LAT-LON-RAW-ADJUSTMENT
  latitude-raw -> int:
    return getDataIntn LATITUDE
  longitude-raw -> int:
    return getDataIntn LONGITUDE
  altitude -> int:
    return getDataUint ALTITUDE
  accuracy -> int:
    return getDataUint ACCURACY
  course-over-ground -> int:
    return getDataUint COURSE-OVER-GROUND
  speed -> int:
    return getDataUint SPEED
  number-of-satellites -> int:
    return getDataUint NUMBER-OF-SATELLITES
  average-cn0 -> int:
    return getDataUint AVERAGE-CN0
  position-type -> int:
    return getDataUint POSITION-TYPE
  position-source -> int:
    return getDataUint POSITION-SOURCE

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
