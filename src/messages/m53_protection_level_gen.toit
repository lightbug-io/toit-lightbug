import ..protocol as protocol

// Auto generated class for protocol message
class ProtectionLevel extends protocol.Data:

  static MT := 53
  static MT_NAME := "ProtectionLevel"

  static VALID := 1
  static LATITUDE := 2
  static LONGITUDE := 3
  static ALTITUDE := 4

  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  /**
  Creates a protocol.Data object with all available fields for this message type.
  
  This is a comprehensive helper that accepts all possible fields.
  For method-specific usage, consider using the dedicated request/response methods.
  
  Returns: A protocol.Data object with the specified field values
  */
  static data --valid/int?=null --latitude/int?=null --longitude/int?=null --altitude/int?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if valid != null: data.add-data-uint VALID valid
    if latitude != null: data.add-data-uint LATITUDE latitude
    if longitude != null: data.add-data-uint LONGITUDE longitude
    if altitude != null: data.add-data-uint ALTITUDE altitude
    return data

  // GET
  static get-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg

  /**
    Indicates if the protection level data is valid
  */
  valid -> int:
    return get-data-uint VALID

  /**
    Protection level in the Lat direction (North South)
    
    Unit: mm
  */
  latitude -> int:
    return get-data-uint LATITUDE

  /**
    Protection level in the Lon direction (East West)
    
    Unit: mm
  */
  longitude -> int:
    return get-data-uint LONGITUDE

  /**
    Protection level in the Z direction
    
    Unit: mm
  */
  altitude -> int:
    return get-data-uint ALTITUDE

  stringify -> string:
    return {
      "Valid": valid,
      "latitude": latitude,
      "longitude": longitude,
      "Altitude": altitude,
    }.stringify
