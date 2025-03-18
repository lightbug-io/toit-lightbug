import ..protocol as protocol

class AlarmControl extends protocol.Data:
  static MT := 45
  static LEGACY-ALARM-ACTION := 1 // 4 bytes of encoded data relating to legacy alarm formats
  static DURATION := 2 // Duration of alarm in seconds
  static BUZZER-PATTERN := 3
  static BUZZER-INTENSITY := 4
  static HAPTICS-PATTERN := 5
  static HAPTICS-INTENSITY := 6
  static STROBE-PATTERN := 7
  static STROBE-INTENSITY := 8
  static PROMPT-MESSAGE := 9
  static PROMPT-TIMEOUT := 10 // Timeout for the prompt in seconds
  static PROMPT-BUTTON-1-TEXT := 11
  static PROMPT-BUTTON-2-TEXT := 12
  static PROMPT-BUTTON-3-TEXT := 13

  static do-msg --legacy-alarm-action/int?=null --duration/int?=null --buzzer-pattern/int?=null --buzzer-intensity/int?=null --haptics-pattern/int?=null --haptics-intensity/int?=null --strobe-pattern/int?=null --strobe-intensity/int?=null --prompt-message/string?=null --prompt-timeout/int?=null --prompt-button-1-text/string?=null --prompt-button-2-text/string?=null --prompt-button-3-text/string?=null -> protocol.Message:
      msg := protocol.Message MT
      if legacy-alarm-action:
          msg.data.add-data-uint32 LEGACY-ALARM-ACTION legacy-alarm-action
      if duration:
          msg.data.add-data-uint8 DURATION duration
      if buzzer-pattern:
          msg.data.add-data-uint8 BUZZER-PATTERN buzzer-pattern
      if buzzer-intensity:
          msg.data.add-data-uint8 BUZZER-INTENSITY buzzer-intensity
      if haptics-pattern:
          msg.data.add-data-uint8 HAPTICS-PATTERN haptics-pattern
      if haptics-intensity:
          msg.data.add-data-uint8 HAPTICS-INTENSITY haptics-intensity
      if strobe-pattern:
          msg.data.add-data-uint8 STROBE-PATTERN strobe-pattern
      if strobe-intensity:
          msg.data.add-data-uint8 STROBE-INTENSITY strobe-intensity
      if prompt-message:
          msg.data.add-data-ascii PROMPT-MESSAGE prompt-message
      if prompt-timeout:
          msg.data.add-data-uint8 PROMPT-TIMEOUT prompt-timeout
      if prompt-button-1-text:
          msg.data.add-data-ascii PROMPT-BUTTON-1-TEXT prompt-button-1-text
      if prompt-button-2-text:
          msg.data.add-data-ascii PROMPT-BUTTON-2-TEXT prompt-button-2-text
      if prompt-button-3-text:
          msg.data.add-data-ascii PROMPT-BUTTON-3-TEXT prompt-button-3-text
      msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-DO
      return msg

  constructor.from-data data/protocol.Data:
      super.from-data data

  legacy-alarm-action -> int:
      return get-data-uint32 LEGACY-ALARM-ACTION

  duration -> int:
      return get-data-uint8 DURATION

  buzzer-pattern -> int:
      return get-data-uint8 BUZZER-PATTERN

  buzzer-intensity -> int:
      return get-data-uint8 BUZZER-INTENSITY

  haptics-pattern -> int:
      return get-data-uint8 HAPTICS-PATTERN

  haptics-intensity -> int:
      return get-data-uint8 HAPTICS-INTENSITY

  strobe-pattern -> int:
      return get-data-uint8 STROBE-PATTERN

  strobe-intensity -> int:
      return get-data-uint8 STROBE-INTENSITY

  prompt-message -> string:
      return get-data-ascii PROMPT-MESSAGE

  prompt-timeout -> int:
      return get-data-uint8 PROMPT-TIMEOUT

  prompt-button-1-text -> string:
      return get-data-ascii PROMPT-BUTTON-1-TEXT

  prompt-button-2-text -> string:
      return get-data-ascii PROMPT-BUTTON-2-TEXT

  prompt-button-3-text -> string:
      return get-data-ascii PROMPT-BUTTON-3-TEXT

  stringify -> string:
      return {
              "Legacy Alarm Action": legacy-alarm-action,
              "Duration": duration,
              "Buzzer Pattern": buzzer-pattern,
              "Buzzer Intensity": buzzer-intensity,
              "Haptics Pattern": haptics-pattern,
              "Haptics Intensity": haptics-intensity,
              "Strobe Pattern": strobe-pattern,
              "Strobe Intensity": strobe-intensity,
              "Prompt Message": prompt-message,
              "Prompt Timeout": prompt-timeout,
              "Prompt Button 1 Text": prompt-button-1-text,
              "Prompt Button 2 Text": prompt-button-2-text,
              "Prompt Button 3 Text": prompt-button-3-text,
      }.stringify
