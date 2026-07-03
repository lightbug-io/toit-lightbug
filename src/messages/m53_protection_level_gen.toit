import ..protocol as protocol

// Auto generated class for protocol message
class ProtectionLevel extends protocol.Data:

  static MT := 53
  static MT_NAME := "ProtectionLevel"

  static VALID := 1
  static LATITUDE := 2
  static LONGITUDE := 3
  static ALTITUDE := 4
  static PROBABILITY := 6

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
  static data --valid/int?=null --latitude/int?=null --longitude/int?=null --altitude/int?=null --probability/float?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if valid != null: data.add-data-uint VALID valid
    if latitude != null: data.add-data-uint LATITUDE latitude
    if longitude != null: data.add-data-uint LONGITUDE longitude
    if altitude != null: data.add-data-uint ALTITUDE altitude
    if probability != null: data.add-data-float PROBABILITY probability
    return data

  /**
   * Creates a GET Request message for Protection Level.
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
   * Creates a UNSUBSCRIBE Request message for Protection Level.
   *
   * Returns: A Message ready to be sent
   */
  static unsubscribe-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-UNSUBSCRIBE base-data

  /**
   * Indicates if the protection level data is valid
   */
  valid -> int:
    return get-data-uint VALID

  /**
   * Protection level in the Lat direction (North South)
   *
   * Unit: mm
   */
  latitude -> int:
    return get-data-uint LATITUDE

  /**
   * Protection level in the Lon direction (East West)
   *
   * Unit: mm
   */
  longitude -> int:
    return get-data-uint LONGITUDE

  /**
   * Protection level in the Z direction
   *
   * Unit: mm
   */
  altitude -> int:
    return get-data-uint ALTITUDE

  /**
   * Protection level probability as a float32.
   * For UBX NAV-PL this is computed from TMIR coefficient/exponent as coeff * 10^exp.
   */
  probability -> float:
    return get-data-float PROBABILITY

  stringify -> string:
    return {
      "valid": valid,
      "lat": latitude,
      "lon": longitude,
      "alt": altitude,
      "probability": probability,
    }.stringify
