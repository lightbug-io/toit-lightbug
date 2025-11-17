import ..protocol as protocol

// Auto generated class for protocol message
class ChargerSettings extends protocol.Data:

  static MT := 54
  static MT_NAME := "ChargerSettings"

  static INPUT-CURRENT-LIMIT := 1
  static CHARGE-CURRENT-LIMIT := 2
  static CHARGE-TERMINATION-VOLTAGE := 3

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
  static data --input-current-limit/int?=null --charge-current-limit/int?=null --charge-termination-voltage/int?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if input-current-limit != null: data.add-data-uint INPUT-CURRENT-LIMIT input-current-limit
    if charge-current-limit != null: data.add-data-uint CHARGE-CURRENT-LIMIT charge-current-limit
    if charge-termination-voltage != null: data.add-data-uint CHARGE-TERMINATION-VOLTAGE charge-termination-voltage
    return data

  /**
   * Creates a GET Request message for Charger Settings.
   *
   * Returns: A Message ready to be sent
   */
  static get-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-GET base-data

  /**
   * Creates a SET Request message for Charger Settings.
   *
   * Returns: A Message ready to be sent
   */
  static set-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-SET base-data

  /**
   * Maximum power draw allowed from Vin. Typically higher than Charge Current Limit (additional current is used to power device operation whilst charging)
   *
   * Unit: mA
   */
  input-current-limit -> int:
    return get-data-uint INPUT-CURRENT-LIMIT

  /**
   * Maximum charge rate for the battery. Recommended value is 0.5C (where C is the battery capacity)
   *
   * Unit: mA
   */
  charge-current-limit -> int:
    return get-data-uint CHARGE-CURRENT-LIMIT

  /**
   * Target charge voltage for the battery. Typically 4.25V for lithium ion batteries.
   *
   * Unit: mV
   */
  charge-termination-voltage -> int:
    return get-data-uint CHARGE-TERMINATION-VOLTAGE

  stringify -> string:
    return {
      "inputCurrentLimit": input-current-limit,
      "chargeCurrentLimit": charge-current-limit,
      "chargeTerminationVoltage": charge-termination-voltage,
    }.stringify
