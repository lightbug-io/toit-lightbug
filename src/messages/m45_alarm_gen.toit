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

  // Helper to create a data object for this message type.
  static data --legacy-alarm-action/int?=null --duration/int?=null --buzzer-pattern/int?=null --buzzer-intensity/int?=null --haptics-pattern/int?=null --haptics-intensity/int?=null --strobe-pattern/int?=null --strobe-intensity/int?=null --prompt-message/string?=null --prompt-timeout/int?=null --prompt-button-1/string?=null --prompt-button-2/string?=null -> protocol.Data:
    data := protocol.Data
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

  // GET
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static get-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg

  // SET
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static set-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SET
    return msg

  // SUBSCRIBE to a message with an optional interval in milliseconds
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static subscribe-msg --ms/int -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SUBSCRIBE
    if ms != null:
      msg.header.data.add-data-uint32 protocol.Header.TYPE-SUBSCRIPTION-INTERVAL ms
    return msg

  // UNSUBSCRIBE
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static unsubscribe-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-UNSUBSCRIBE
    return msg

  // DO
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static do-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-DO
    return msg

  // Creates a message with no method set
  static msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-data MT data

  legacy-alarm-action -> int:
    return get-data-uint LEGACY-ALARM-ACTION

  duration -> int:
    return get-data-uint DURATION

  buzzer-pattern -> int:
    return get-data-uint BUZZER-PATTERN

  buzzer-intensity -> int:
    return get-data-uint BUZZER-INTENSITY

  haptics-pattern -> int:
    return get-data-uint HAPTICS-PATTERN

  haptics-intensity -> int:
    return get-data-uint HAPTICS-INTENSITY

  strobe-pattern -> int:
    return get-data-uint STROBE-PATTERN

  strobe-intensity -> int:
    return get-data-uint STROBE-INTENSITY

  prompt-message -> string:
    return get-data-ascii PROMPT-MESSAGE

  prompt-timeout -> int:
    return get-data-uint PROMPT-TIMEOUT

  prompt-button-1 -> string:
    return get-data-ascii PROMPT-BUTTON-1

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
