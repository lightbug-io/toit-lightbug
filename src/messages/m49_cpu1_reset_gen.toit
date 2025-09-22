import ..protocol as protocol

// Auto generated class for protocol message
class CPU1Reset extends protocol.Data:

  static MT := 49
  static MT_NAME := "CPU1Reset"

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
  static data --base-data/protocol.Data?=protocol.Data -> protocol.Data: return base-data

  /**
   * Creates a DO Request message for CPU1 Reset.
   *
   * Returns: A Message ready to be sent
   */
  static do-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-DO base-data

  stringify -> string:
    return {
    }.stringify
