import ..protocol as protocol
import fixed-point show FixedPoint

// Auto generated class for protocol message
class Alarm extends protocol.Data:

  static MT := 45

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
  static PROMPT-BUTTON-1-TEXT := 11
  static PROMPT-BUTTON-2-TEXT := 12
  static PROMPT-BUTTON-3-TEXT := 13

  constructor:
    super

  // GET
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static get-msg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg

  // SET
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static set-msg -> protocol.Message:
    msg := protocol.Message MT
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
  static unsubscribe-msg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-UNSUBSCRIBE
    return msg

  // DO
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static do-msg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-DO
    return msg

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

  prompt-message -> int:
    return get-data-uint PROMPT-MESSAGE

  prompt-timeout -> int:
    return get-data-uint PROMPT-TIMEOUT

  prompt-button-1-text -> int:
    return get-data-uint PROMPT-BUTTON-1-TEXT

  prompt-button-2-text -> int:
    return get-data-uint PROMPT-BUTTON-2-TEXT

  prompt-button-3-text -> int:
    return get-data-uint PROMPT-BUTTON-3-TEXT

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
      "Prompt button 1 text": prompt-button-1-text,
      "Prompt button 2 text": prompt-button-2-text,
      "Prompt button 3 text": prompt-button-3-text,
    }.stringify
