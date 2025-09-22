import ..protocol as protocol

// Auto generated class for protocol message
class PowerProfile extends protocol.Data:

  static MT := 48
  static MT_NAME := "PowerProfile"

  static TOTAL-POWER := 3
  static CURRENT := 4

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
  static data --total-power/float?=null --current/float?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if total-power != null: data.add-data-float TOTAL-POWER total-power
    if current != null: data.add-data-float CURRENT current
    return data

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
   * Creates a UNSUBSCRIBE Request message for Power Profile.
   */
  
  /**
   * Returns: A Message ready to be sent
   */
  static unsubscribe-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-UNSUBSCRIBE base-data

  /**
   * Total power used in mAH since the subscription was started (or the device was turned on, if only using GET)
   *
   * Unit: mAh
   */
  total-power -> float:
    return get-data-float TOTAL-POWER

  /**
   * Instantaneous Current power usage
   *
   * Unit: mA
   */
  current -> float:
    return get-data-float CURRENT

  stringify -> string:
    return {
      "Total power": total-power,
      "Current": current,
    }.stringify
