import ..protocol as protocol

class BuzzerControl extends protocol.Data:
  static MT := 42
  static DURATION := 1 // Duration of buzzer in milliseconds
  static SOUND-TYPE := 2
  static INTENSITY := 3
  static RUN-COUNT := 4
  static FREQUENCY := 5 // Frequency of buzzer of KHz.

  static SOUND-SOLID := 0
  static SOUND-SIREN := 1
  static SOUND-BEEP-BEEP := 2
  static SOUND-AMBULANCE := 3
  static SOUND-FIRE-TRUCK := 4
  static SOUND-POSITIVE1 := 5
  static SOUND-SLOW-BEEP := 6
  static SOUND-ALARM := 7

  static do-msg --duration/int?=null --soundType/int?=null --intensity/int?=null --runCount/int?=null --frequency/float?=null -> protocol.Message:
      msg := protocol.Message MT
      if duration:
          msg.data.add-data-uint16 DURATION duration
      if soundType:
          msg.data.add-data-uint8 SOUND-TYPE soundType
      if intensity:
          msg.data.add-data-uint8 INTENSITY intensity
      if runCount:
          msg.data.add-data-uint8 RUN-COUNT runCount
      if frequency:
          msg.data.add-data-float32 FREQUENCY frequency
      msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-DO
      return msg

  constructor.from-data data/protocol.Data:
      super.from-data data

  duration -> int:
      return get-data-uint16 DURATION

  soundType -> int:
      return get-data-uint8 SOUND-TYPE

  intensity -> int:
      return get-data-uint8 INTENSITY

  runCount -> int:
      return get-data-uint8 RUN-COUNT

  frequency -> float:
      return get-data-float32 FREQUENCY

  stringify -> string:
      return {
              "Duration": duration,
              "Sound Type": soundType,
              "Intensity": intensity,
              "Run Count": runCount,
              "Frequency": frequency,
      }.stringify
