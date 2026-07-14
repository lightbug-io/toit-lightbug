import ..protocol as protocol

// Auto generated class for protocol message
class LoRa extends protocol.Data:

  static MT := 1004
  static MT_NAME := "LoRa"

  static V4-MESSAGE-TYPE := 1
  static V4-MESSAGE-TYPE_RESERVED := 0
  static V4-MESSAGE-TYPE_ACK := 1
  static V4-MESSAGE-TYPE_ANNOUNCE := 2
  static V4-MESSAGE-TYPE_POSITION-UPDATE-BASIC := 10
  static V4-MESSAGE-TYPE_CONFIG-UPDATE-BASIC := 11
  static V4-MESSAGE-TYPE_LORA-CONFIG-BASIC := 12
  static V4-MESSAGE-TYPE_TRACKER-STATUS := 13
  static V4-MESSAGE-TYPE_POSITION-UPDATE-ENCRYPTED := 20

  static V4-MESSAGE-TYPE_STRINGS := {
    0: "Reserved",
    1: "ACK",
    2: "Announce",
    10: "Position Update Basic",
    11: "Config Update Basic",
    12: "LORA Config Basic",
    13: "Tracker Status",
    20: "Position Update Encrypted",
  }

  static v4-message-type-from-int value/int -> string:
    return V4-MESSAGE-TYPE_STRINGS.get value --if-absent=(: "unknown")

  static PAYLOAD := 2
  static STATE := 40
  static STATE_SLEEP := 0
  static STATE_RECEIVING := 1
  static STATE_TRANSMITTING := 2
  static STATE_UNKNOWN := 3

  static STATE_STRINGS := {
    0: "Sleep",
    1: "Receiving",
    2: "Transmitting",
    3: "Unknown",
  }

  static state-from-int value/int -> string:
    return STATE_STRINGS.get value --if-absent=(: "unknown")

  static EVENT := 41
  static EVENT_NONE := 0
  static EVENT_RX-DONE := 1
  static EVENT_RX-TIMEOUT := 2
  static EVENT_TX-DONE := 3
  static EVENT_TX-TIMEOUT := 4

  static EVENT_STRINGS := {
    0: "None",
    1: "RX Done",
    2: "RX Timeout",
    3: "TX Done",
    4: "TX Timeout",
  }

  static event-from-int value/int -> string:
    return EVENT_STRINGS.get value --if-absent=(: "unknown")

  static STATUS-FLAGS := 42
  static ACTIVE-CONFIG-SLOT := 43
  static PENDING-RX-WINDOW-COUNT := 44
  static NEXT-RX-WINDOW-ID := 45
  static NEXT-RX-CONFIG-SLOT := 46
  static RX-DURATION := 50
  static RX-START-TIME := 51
  static EVENT-TIME := 52
  static RX-WINDOW-ID := 53
  static CONFIG-SLOT := 54

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
  static data --v4-message-type/int?=null --payload/ByteArray?=null --rx-duration/int?=null --rx-start-time/int?=null --rx-window-id/int?=null --config-slot/int?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if v4-message-type != null: data.add-data-uint V4-MESSAGE-TYPE v4-message-type
    if payload != null: data.add-data PAYLOAD payload
    if rx-duration != null: data.add-data-uint RX-DURATION rx-duration
    if rx-start-time != null: data.add-data-uint RX-START-TIME rx-start-time
    if rx-window-id != null: data.add-data-uint RX-WINDOW-ID rx-window-id
    if config-slot != null: data.add-data-uint CONFIG-SLOT config-slot
    return data

  /**
   * Creates a LoRa message without a specific method.
   *
   * This is used for messages that don't require a specific method type
   * (like GET, SET, SUBSCRIBE) but still need to carry data.
   *
   * Parameters:
   * - data: Optional protocol.Data object containing message payload
   *
   * Returns: A Message ready to be sent
   */
  static msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-data MT data

  /**
   * Creates a GET Request message for LoRa.
   *
   * Returns: A Message ready to be sent
   */
  static get-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-GET base-data

  /**
   * Creates a SET Request message for LoRa.
   *
   * Returns: A Message ready to be sent
   */
  static set-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-SET base-data

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
   * Creates a UNSUBSCRIBE Request message for LoRa.
   *
   * Returns: A Message ready to be sent
   */
  static unsubscribe-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-UNSUBSCRIBE base-data

  /**
   * V4 Message Type
   *
   * Valid values:
   * - V4-MESSAGE-TYPE_RESERVED (0): Reserved
   * - V4-MESSAGE-TYPE_ACK (1): ACK
   * - V4-MESSAGE-TYPE_ANNOUNCE (2): Announce
   * - V4-MESSAGE-TYPE_POSITION-UPDATE-BASIC (10): Position Update Basic
   * - V4-MESSAGE-TYPE_CONFIG-UPDATE-BASIC (11): Config Update Basic
   * - V4-MESSAGE-TYPE_LORA-CONFIG-BASIC (12): LORA Config Basic
   * - V4-MESSAGE-TYPE_TRACKER-STATUS (13): Tracker Status
   * - V4-MESSAGE-TYPE_POSITION-UPDATE-ENCRYPTED (20): Position Update Encrypted
   */
  v4-message-type -> int:
    return get-data-uint V4-MESSAGE-TYPE

  /**
   * Payload
   */
  payload -> ByteArray:
    return get-data PAYLOAD

  /**
   * State
   *
   * Valid values:
   * - STATE_SLEEP (0): Sleep
   * - STATE_RECEIVING (1): Receiving
   * - STATE_TRANSMITTING (2): Transmitting
   * - STATE_UNKNOWN (3): Unknown
   */
  state -> int:
    return get-data-uint STATE

  /**
   * Event
   *
   * Valid values:
   * - EVENT_NONE (0): None
   * - EVENT_RX-DONE (1): RX Done
   * - EVENT_RX-TIMEOUT (2): RX Timeout
   * - EVENT_TX-DONE (3): TX Done
   * - EVENT_TX-TIMEOUT (4): TX Timeout
   */
  event -> int:
    return get-data-uint EVENT

  /**
   * Bitfield (listening, busy, queuedRx, subscriptionActive).
   */
  status-flags -> int:
    return get-data-uint STATUS-FLAGS

  /**
   * Active Config Slot
   */
  active-config-slot -> int:
    return get-data-uint ACTIVE-CONFIG-SLOT

  /**
   * Pending RX Window Count
   */
  pending-rx-window-count -> int:
    return get-data-uint PENDING-RX-WINDOW-COUNT

  /**
   * Window ID for the earliest queued finite RX window.
   * Set to 0 when no finite RX window is queued.
   */
  next-rx-window-id -> int:
    return get-data-uint NEXT-RX-WINDOW-ID

  /**
   * Config slot for the earliest queued finite RX window.
   * Only meaningful when pendingRxWindowCount is greater than 0.
   */
  next-rx-config-slot -> int:
    return get-data-uint NEXT-RX-CONFIG-SLOT

  /**
   * RX window duration.
   * On SUBSCRIBE, explicit value 0 means infinite RX (only valid when explicitly supplied on this field).
   *
   *
   * Unit: ms
   */
  rx-duration -> int:
    return get-data-uint RX-DURATION

  /**
   * Absolute module-local target uptime time for RX start in milliseconds.
   * This is not an absolute timestamp, but rather a module-local uptime time in milliseconds.
   *
   *
   * Unit: ms
   */
  rx-start-time -> int:
    return get-data-uint RX-START-TIME

  /**
   * Absolute module-local target uptime time for TX/RX/timeout event in milliseconds.
   * This is not an absolute timestamp, but rather a module-local uptime time in milliseconds.
   *
   *
   * Unit: ms
   */
  event-time -> int:
    return get-data-uint EVENT-TIME

  /**
   * RX Window ID
   */
  rx-window-id -> int:
    return get-data-uint RX-WINDOW-ID

  /**
   * Config Slot
   */
  config-slot -> int:
    return get-data-uint CONFIG-SLOT

  stringify -> string:
    return {
      "v4MessageType": v4-message-type,
      "payload": payload,
      "state": state,
      "event": event,
      "statusFlags": status-flags,
      "activeConfigSlot": active-config-slot,
      "pendingRxWindowCount": pending-rx-window-count,
      "nextRxWindowId": next-rx-window-id,
      "nextRxConfigSlot": next-rx-config-slot,
      "rxDurationMs": rx-duration,
      "rxStartTimeMs": rx-start-time,
      "eventTimeMs": event-time,
      "rxWindowId": rx-window-id,
      "configSlot": config-slot,
    }.stringify
