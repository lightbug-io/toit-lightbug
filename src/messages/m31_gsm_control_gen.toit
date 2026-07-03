import ..protocol as protocol

// Auto generated class for protocol message
class GSMControl extends protocol.Data:

  static MT := 31
  static MT_NAME := "GSMControl"

  static FLIGHT-MODE := 1
  static DURATION := 2
  static GSM-ACTIVE := 3
  static REQUEST-CONTROL := 4
  static START-SEARCH := 5
  static START-SEARCH_FULL := 0
  static START-SEARCH_AUTO := 1

  static START-SEARCH_STRINGS := {
    0: "Full",
    1: "Auto",
  }

  static start-search-from-int value/int -> string:
    return START-SEARCH_STRINGS.get value --if-absent=(: "unknown")


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
  static data --flight-mode/bool?=null --duration/int?=null --request-control/bool?=null --start-search/int?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if flight-mode != null: data.add-data-bool FLIGHT-MODE flight-mode
    if duration != null: data.add-data-uint DURATION duration
    if request-control != null: data.add-data-bool REQUEST-CONTROL request-control
    if start-search != null: data.add-data-uint START-SEARCH start-search
    return data

  /**
   * Creates a GET Request message for GSM Control.
   *
   * Returns: A Message ready to be sent
   */
  static get-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-GET base-data

  /**
   * Creates a SET Request message for GSM Control.
   *
   * Returns: A Message ready to be sent
   */
  static set-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-SET base-data

  /**
   * Flight mode
   */
  flight-mode -> bool:
    return get-data-bool FLIGHT-MODE

  /**
   * Duration
   *
   * Unit: minutes
   */
  duration -> int:
    return get-data-uint DURATION

  /**
   * GSM Active
   */
  gsm-active -> bool:
    return get-data-bool GSM-ACTIVE

  /**
   * Note this will always be true when GETting state in flight mode (as control has been taken).
   */
  request-control -> bool:
    return get-data-bool REQUEST-CONTROL

  /**
   * Trigger a network search. When present, takes priority over flight mode / duration fields.
   *
   *
   * Valid values:
   * - START-SEARCH_FULL (0): Full network scan.
   * - START-SEARCH_AUTO (1): Automatic search using the last known band.
   */
  start-search -> int:
    return get-data-uint START-SEARCH

  stringify -> string:
    return {
      "flightMode": flight-mode,
      "duration": duration,
      "gsmActive": gsm-active,
      "requestControl": request-control,
      "startSearch": start-search,
    }.stringify
