import ..protocol as protocol

// Auto generated class for protocol message
class BuzzerControl extends protocol.Data:

  static MT := 42
  static MT_NAME := "BuzzerControl"

  static DURATION := 1
  static SOUND-TYPE := 2
  static SOUND-TYPE_SOLID := 0
  static SOUND-TYPE_SIREN := 1
  static SOUND-TYPE_BEEP-BEEP := 2
  static SOUND-TYPE_AMBULANCE := 3
  static SOUND-TYPE_FIRETRUCK := 4
  static SOUND-TYPE_POSITIVE1 := 5
  static SOUND-TYPE_SLOWBEEP := 6
  static SOUND-TYPE_ALARM := 7

  static SOUND-TYPE_STRINGS := {
    0: "Solid",
    1: "Siren",
    2: "Beep Beep",
    3: "Ambulance",
    4: "FireTruck",
    5: "Positive1",
    6: "SlowBeep",
    7: "Alarm",
  }

  static sound-type-from-int value/int -> string:
    return SOUND-TYPE_STRINGS.get value --if-absent=(: "unknown")

  static INTENSITY := 3
  static RUN-COUNT := 4
  static FREQUENCY := 5

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
  static data --duration/int?=null --sound-type/int?=null --intensity/int?=null --run-count/int?=null --frequency/float?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if duration != null: data.add-data-uint DURATION duration
    if sound-type != null: data.add-data-uint SOUND-TYPE sound-type
    if intensity != null: data.add-data-uint INTENSITY intensity
    if run-count != null: data.add-data-uint RUN-COUNT run-count
    if frequency != null: data.add-data-float FREQUENCY frequency
    return data

  /**
   * Creates a Buzzer Control message without a specific method.
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
   * Duration of buzzer in milliseconds
   */
  duration -> int:
    return get-data-uint DURATION

  /**
   * A predefined sound type
   *
   * Valid values:
   * - SOUND-TYPE_SOLID (0): Solid
   * - SOUND-TYPE_SIREN (1): Siren
   * - SOUND-TYPE_BEEP-BEEP (2): Beep Beep
   * - SOUND-TYPE_AMBULANCE (3): Ambulance
   * - SOUND-TYPE_FIRETRUCK (4): FireTruck
   * - SOUND-TYPE_POSITIVE1 (5): Positive1
   * - SOUND-TYPE_SLOWBEEP (6): SlowBeep
   * - SOUND-TYPE_ALARM (7): Alarm
   */
  sound-type -> int:
    return get-data-uint SOUND-TYPE

  /**
   * Intensity of buzzer. [0-2]. Work as frequency control for buzzer types (moving towards and away from resonance).
   */
  intensity -> int:
    return get-data-uint INTENSITY

  /**
   * Number of times to run the buzzer
   */
  run-count -> int:
    return get-data-uint RUN-COUNT

  /**
   * Frequency of buzzer of KHz.(if frequency is sent, only duration and frequency parameters will be inside the message)
   */
  frequency -> float:
    return get-data-float FREQUENCY

  stringify -> string:
    return {
      "duration": duration,
      "soundType": sound-type,
      "intensity": intensity,
      "runCount": run-count,
      "frequency": frequency,
    }.stringify
