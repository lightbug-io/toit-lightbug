import ..protocol as protocol

// Auto generated class for protocol message
class PowerInfo extends protocol.Data:

  static MT := 48
  static MT_NAME := "PowerInfo"

  static WIFI-ON-INTERVAL := 1
  static WIFI-WAKE-ON-EVENT := 2
  static TOTAL-POWER-SINCE-PROFILE := 3
  static CURRENT := 4
  static CHARGING := 5
  static EXTERNAL-VOLTAGE := 6
  static TOTAL-POWER-SINCE-LAST-TX := 7
  static CHARGE-CURRENT := 8
  static INPUT-CURRENT := 9

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
  static data --wifi-on-interval/int?=null --wifi-wake-on-event/bool?=null --total-power-since-profile/float?=null --current/float?=null --charging/bool?=null --external-voltage/float?=null --total-power-since-last-tx/float?=null --charge-current/float?=null --input-current/float?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if wifi-on-interval != null: data.add-data-uint WIFI-ON-INTERVAL wifi-on-interval
    if wifi-wake-on-event != null: data.add-data-bool WIFI-WAKE-ON-EVENT wifi-wake-on-event
    if total-power-since-profile != null: data.add-data-float TOTAL-POWER-SINCE-PROFILE total-power-since-profile
    if current != null: data.add-data-float CURRENT current
    if charging != null: data.add-data-bool CHARGING charging
    if external-voltage != null: data.add-data-float EXTERNAL-VOLTAGE external-voltage
    if total-power-since-last-tx != null: data.add-data-float TOTAL-POWER-SINCE-LAST-TX total-power-since-last-tx
    if charge-current != null: data.add-data-float CHARGE-CURRENT charge-current
    if input-current != null: data.add-data-float INPUT-CURRENT input-current
    return data

  /**
   * Creates a GET Request message for Power Info.
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
   * Creates a UNSUBSCRIBE Request message for Power Info.
   *
   * Returns: A Message ready to be sent
   */
  static unsubscribe-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-UNSUBSCRIBE base-data

  /**
   * WiFi on Interval
   */
  wifi-on-interval -> int:
    return get-data-uint WIFI-ON-INTERVAL

  /**
   * WiFi Wake on Event
   */
  wifi-wake-on-event -> bool:
    return get-data-bool WIFI-WAKE-ON-EVENT

  /**
   * Total power used, since a point in time decided by the method used.
   * For messages from a SUBSCRIBE, this is the mAH used since the subscription was started
   * For a GET response, this is the mAH used since the device was turned on
   *
   *
   * Unit: mAh
   */
  total-power-since-profile -> float:
    return get-data-float TOTAL-POWER-SINCE-PROFILE

  /**
   * Instantaneous Current power usage
   *
   * Unit: mA
   */
  current -> float:
    return get-data-float CURRENT

  /**
   * Is the device currently charging
   */
  charging -> bool:
    return get-data-bool CHARGING

  /**
   * Measured external voltage
   *
   * Unit: V
   */
  external-voltage -> float:
    return get-data-float EXTERNAL-VOLTAGE

  /**
   * Total power used since the last transmission
   */
  total-power-since-last-tx -> float:
    return get-data-float TOTAL-POWER-SINCE-LAST-TX

  /**
   * Current used to charge the device
   */
  charge-current -> float:
    return get-data-float CHARGE-CURRENT

  /**
   * Current coming in from external input
   */
  input-current -> float:
    return get-data-float INPUT-CURRENT

  stringify -> string:
    return {
      "_wifiOnInterval": wifi-on-interval,
      "_wifiWakeOnEvent": wifi-wake-on-event,
      "totalPower": total-power-since-profile,
      "current": current,
      "charging": charging,
      "externalVoltage": external-voltage,
      "totalPowerSinceLastTx": total-power-since-last-tx,
      "chargeCurrent": charge-current,
      "inputCurrent": input-current,
    }.stringify
