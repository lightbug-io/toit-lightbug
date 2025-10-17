import ..protocol as protocol

// Auto generated class for protocol message
class Alarm extends protocol.Data:

  static MT := 45
  static MT_NAME := "Alarm"

  static LEGACY-ALARM-ACTION := 1
  static DURATION := 2
  static BUZZER-PATTERN := 3
  static BUZZER-INTENSITY := 4
  static HAPTICS-PATTERN := 5
  static HAPTICS-INTENSITY := 6
  static STROBE-PATTERN := 7
  static STROBE-INTENSITY := 8
  static PROMPT-MESSAGE := 9
  static PROMPT-TIMEOUT := 10
  static PROMPT-BUTTON-1 := 11
  static PROMPT-BUTTON-2 := 12

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
  static data --legacy-alarm-action/int?=null --duration/int?=null --buzzer-pattern/int?=null --buzzer-intensity/int?=null --haptics-pattern/int?=null --haptics-intensity/int?=null --strobe-pattern/int?=null --strobe-intensity/int?=null --prompt-message/string?=null --prompt-timeout/int?=null --prompt-button-1/string?=null --prompt-button-2/string?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if legacy-alarm-action != null: data.add-data-uint LEGACY-ALARM-ACTION legacy-alarm-action
    if duration != null: data.add-data-uint DURATION duration
    if buzzer-pattern != null: data.add-data-uint BUZZER-PATTERN buzzer-pattern
    if buzzer-intensity != null: data.add-data-uint BUZZER-INTENSITY buzzer-intensity
    if haptics-pattern != null: data.add-data-uint HAPTICS-PATTERN haptics-pattern
    if haptics-intensity != null: data.add-data-uint HAPTICS-INTENSITY haptics-intensity
    if strobe-pattern != null: data.add-data-uint STROBE-PATTERN strobe-pattern
    if strobe-intensity != null: data.add-data-uint STROBE-INTENSITY strobe-intensity
    if prompt-message != null: data.add-data-ascii PROMPT-MESSAGE prompt-message
    if prompt-timeout != null: data.add-data-uint PROMPT-TIMEOUT prompt-timeout
    if prompt-button-1 != null: data.add-data-ascii PROMPT-BUTTON-1 prompt-button-1
    if prompt-button-2 != null: data.add-data-ascii PROMPT-BUTTON-2 prompt-button-2
    return data

  /**
   * Creates a Alarm message without a specific method.
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
   * 4 bytes of encoded data relating to legacy alarm formats. Can not be used with other options. Note using this field will override Duration header field setting
   */
  legacy-alarm-action -> int:
    return get-data-uint LEGACY-ALARM-ACTION

  /**
   * Duration of alarm in seconds. Max 127s
   */
  duration -> int:
    return get-data-uint DURATION

  /**
   * Buzzer Pattern
   */
  buzzer-pattern -> int:
    return get-data-uint BUZZER-PATTERN

  /**
   * Buzzer Intensity
   */
  buzzer-intensity -> int:
    return get-data-uint BUZZER-INTENSITY

  /**
   * Haptics Pattern
   */
  haptics-pattern -> int:
    return get-data-uint HAPTICS-PATTERN

  /**
   * Haptics Intensity
   */
  haptics-intensity -> int:
    return get-data-uint HAPTICS-INTENSITY

  /**
   * Strobe Pattern
   */
  strobe-pattern -> int:
    return get-data-uint STROBE-PATTERN

  /**
   * Strobe Intensity
   */
  strobe-intensity -> int:
    return get-data-uint STROBE-INTENSITY

  /**
   * Message to show on the device prompt If not set, no prompt will be shown
   * Prompts can be dismissed by button presses, or automatically after the prompt timeout has expired
   */
  prompt-message -> string:
    return get-data-ascii PROMPT-MESSAGE

  /**
   * Timeout for the prompt in seconds
   * If not set, prompt will stay until dismissed with a button press
   */
  prompt-timeout -> int:
    return get-data-uint PROMPT-TIMEOUT

  /**
   * Prompt button 1
   */
  prompt-button-1 -> string:
    return get-data-ascii PROMPT-BUTTON-1

  /**
   * Prompt button 2
   */
  prompt-button-2 -> string:
    return get-data-ascii PROMPT-BUTTON-2

  stringify -> string:
    return {
      "Legacy alarm action": legacy-alarm-action,
      "Duration": duration,
      "Buzzer Pattern": buzzer-pattern,
      "Buzzer Intensity": buzzer-intensity,
      "Haptics Pattern": haptics-pattern,
      "Haptics Intensity": haptics-intensity,
      "Strobe Pattern": strobe-pattern,
      "Strobe Intensity": strobe-intensity,
      "Prompt message": prompt-message,
      "Prompt timeout": prompt-timeout,
      "Prompt button 1": prompt-button-1,
      "Prompt button 2": prompt-button-2,
    }.stringify
