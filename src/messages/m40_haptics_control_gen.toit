import ..protocol as protocol

// Auto generated class for protocol message
class HapticsControl extends protocol.Data:

  static MT := 40
  static MT_NAME := "HapticsControl"

  static PATTERN := 1
  static PATTERN_FADE := 1
  static PATTERN_PULSE := 2
  static PATTERN_DROP := 3

  static PATTERN_STRINGS := {
    1: "Fade",
    2: "Pulse",
    3: "Drop",
  }

  static pattern-from-int value/int -> string:
    return PATTERN_STRINGS.get value --if-absent=(: "unknown")

  static INTENSITY := 2
  static INTENSITY_LOW := 0
  static INTENSITY_MEDIUM := 1
  static INTENSITY_HIGH := 2

  static INTENSITY_STRINGS := {
    0: "Low",
    1: "Medium",
    2: "High",
  }

  static intensity-from-int value/int -> string:
    return INTENSITY_STRINGS.get value --if-absent=(: "unknown")


  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  /**
  Creates a protocol.Data object with all available fields for this message type.
  
  This is a comprehensive helper that accepts all possible fields.
  For method-specific usage, consider using the dedicated request/response methods.
  
  Returns: A protocol.Data object with the specified field values
  */
  static data --pattern/int?=null --intensity/int?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if pattern != null: data.add-data-uint PATTERN pattern
    if intensity != null: data.add-data-uint INTENSITY intensity
    return data

  /**
  Creates a Haptics Control message without a specific method.
  
  This is used for messages that don't require a specific method type
  (like GET, SET, SUBSCRIBE) but still need to carry data.
  
  Parameters:
  - data: Optional protocol.Data object containing message payload
  
  Returns: A Message ready to be sent
  */
  static msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-data MT data

  /**
    Pattern of haptics [1-3]
    
    Valid values:
    - PATTERN_FADE (1): Default
    - PATTERN_PULSE (2): Pulse
    - PATTERN_DROP (3): Drop
  */
  pattern -> int:
    return get-data-uint PATTERN

  /**
    Intensity of haptics [0-2]
    
    Valid values:
    - INTENSITY_LOW (0): Low
    - INTENSITY_MEDIUM (1): Medium
    - INTENSITY_HIGH (2): High
  */
  intensity -> int:
    return get-data-uint INTENSITY

  stringify -> string:
    return {
      "Pattern": pattern,
      "Intensity": intensity,
    }.stringify
