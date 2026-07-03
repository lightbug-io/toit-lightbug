import ..protocol as protocol

// Auto generated class for protocol message
class LEDControl extends protocol.Data:

  static MT := 52
  static MT_NAME := "LEDControl"

  static RED := 2
  static GREEN := 3
  static BLUE := 4

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
  static data --red/int?=null --green/int?=null --blue/int?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if red != null: data.add-data-uint RED red
    if green != null: data.add-data-uint GREEN green
    if blue != null: data.add-data-uint BLUE blue
    return data

  /**
   * Creates a GET Request message for LED Control.
   *
   * Returns: A Message ready to be sent
   */
  static get-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-GET base-data

  /**
   * Creates a SET Request message for LED Control.
   *
   * Returns: A Message ready to be sent
   */
  static set-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-SET base-data

  /**
   * Red LED intensity (0-255) PWM value
   */
  red -> int:
    return get-data-uint RED

  /**
   * Green LED intensity (0-255) PWM value
   */
  green -> int:
    return get-data-uint GREEN

  /**
   * Blue LED intensity (0-255) PWM value
   */
  blue -> int:
    return get-data-uint BLUE

  stringify -> string:
    return {
      "red": red,
      "green": green,
      "blue": blue,
    }.stringify
