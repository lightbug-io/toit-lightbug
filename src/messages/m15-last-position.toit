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

  static get-msg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg

  constructor.from-data data/protocol.Data:
    super.from-data data
  
  msg -> protocol.Message:
    return protocol.Message.with-data MT this
  
  static subscribe-msg --intervalms/int -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SUBSCRIBE
    msg.header.data.add-data-uint32 protocol.Header.TYPE-SUBSCRIPTION-INTERVAL intervalms // must be uint32
    return msg

  timestamp -> int:
    // TODO return a typed value
    return get-data-uint TIMESTAMP
  coordinate -> Coordinate:
    return Coordinate latitude longitude
  latitude -> float:
    return latitude-float
  longitude -> float:
    return longitude-float
  latitude-fixed -> FixedPoint:
    return ( FixedPoint --decimals=7 latitude-float )
  longitude-fixed -> FixedPoint:
    return ( FixedPoint --decimals=7 longitude-float )
  latitude-float -> float:
    return ( get-data-intn LATITUDE) / LAT-LON-RAW-ADJUSTMENT
  longitude-float -> float:
    return ( get-data-intn LONGITUDE) / LAT-LON-RAW-ADJUSTMENT
  latitude-raw -> int:
    return get-data-intn LATITUDE
  longitude-raw -> int:
    return get-data-intn LONGITUDE
  altitude -> int:
    return get-data-uint ALTITUDE
  accuracy -> int:
    return get-data-uint ACCURACY
  course-over-ground -> int:
    return get-data-uint COURSE-OVER-GROUND
  speed -> int:
    return get-data-uint SPEED
  number-of-satellites -> int:
    return get-data-uint NUMBER-OF-SATELLITES
  average-cn0 -> int:
    return get-data-uint AVERAGE-CN0
  position-type -> int:
    return get-data-uint POSITION-TYPE
  position-source -> int:
    return get-data-uint POSITION-SOURCE

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
