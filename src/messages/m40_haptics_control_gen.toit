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

  static DRIVER-PATTERN := 3
  static DRIVER-PATTERN_STRONG-CLICK-100 := 1
  static DRIVER-PATTERN_STRONG-CLICK-60 := 2
  static DRIVER-PATTERN_STRONG-CLICK-30 := 3
  static DRIVER-PATTERN_SHARP-CLICK-100 := 4
  static DRIVER-PATTERN_SHARP-CLICK-60 := 5
  static DRIVER-PATTERN_SHARP-CLICK-30 := 6
  static DRIVER-PATTERN_SOFT-BUMP-100 := 7
  static DRIVER-PATTERN_SOFT-BUMP-60 := 8
  static DRIVER-PATTERN_SOFT-BUMP-30 := 9
  static DRIVER-PATTERN_DOUBLE-CLICK-100 := 10
  static DRIVER-PATTERN_DOUBLE-CLICK-60 := 11
  static DRIVER-PATTERN_TRIPLE-CLICK-100 := 12
  static DRIVER-PATTERN_SOFT-FUZZ-60 := 13
  static DRIVER-PATTERN_STRONG-BUZZ-100 := 14
  static DRIVER-PATTERN_750MS-ALERT-100 := 15
  static DRIVER-PATTERN_1000MS-ALERT-100 := 16
  static DRIVER-PATTERN_STRONG-CLICK-1-100 := 17
  static DRIVER-PATTERN_STRONG-CLICK-2-80 := 18
  static DRIVER-PATTERN_STRONG-CLICK-3-60 := 19
  static DRIVER-PATTERN_STRONG-CLICK-4-30 := 20
  static DRIVER-PATTERN_MEDIUM-CLICK-1-100 := 21
  static DRIVER-PATTERN_MEDIUM-CLICK-2-80 := 22
  static DRIVER-PATTERN_MEDIUM-CLICK-3-60 := 23
  static DRIVER-PATTERN_SHARP-TICK-1-100 := 24
  static DRIVER-PATTERN_SHARP-TICK-2-80 := 25
  static DRIVER-PATTERN_SHARP-TICK-3-60 := 26
  static DRIVER-PATTERN_SHORT-DOUBLE-CLICK-STRONG-1-100 := 27
  static DRIVER-PATTERN_SHORT-DOUBLE-CLICK-STRONG-2-80 := 28
  static DRIVER-PATTERN_SHORT-DOUBLE-CLICK-STRONG-3-60 := 29
  static DRIVER-PATTERN_SHORT-DOUBLE-CLICK-STRONG-4-30 := 30
  static DRIVER-PATTERN_SHORT-DOUBLE-CLICK-MEDIUM-1-100 := 31
  static DRIVER-PATTERN_SHORT-DOUBLE-CLICK-MEDIUM-2-80 := 32
  static DRIVER-PATTERN_SHORT-DOUBLE-CLICK-MEDIUM-3-60 := 33
  static DRIVER-PATTERN_SHORT-DOUBLE-SHARP-TICK-1-100 := 34
  static DRIVER-PATTERN_SHORT-DOUBLE-SHARP-TICK-2-80 := 35
  static DRIVER-PATTERN_SHORT-DOUBLE-SHARP-TICK-3-60 := 36
  static DRIVER-PATTERN_LONG-DOUBLE-SHARP-CLICK-STRONG-1-100 := 37
  static DRIVER-PATTERN_LONG-DOUBLE-SHARP-CLICK-STRONG-2-80 := 38
  static DRIVER-PATTERN_LONG-DOUBLE-SHARP-CLICK-STRONG-3-60 := 39
  static DRIVER-PATTERN_LONG-DOUBLE-SHARP-CLICK-STRONG-4-30 := 40
  static DRIVER-PATTERN_LONG-DOUBLE-SHARP-CLICK-MEDIUM-1-100 := 41
  static DRIVER-PATTERN_LONG-DOUBLE-SHARP-CLICK-MEDIUM-2-80 := 42
  static DRIVER-PATTERN_LONG-DOUBLE-SHARP-CLICK-MEDIUM-3-60 := 43
  static DRIVER-PATTERN_LONG-DOUBLE-SHARP-TICK-1-100 := 44
  static DRIVER-PATTERN_LONG-DOUBLE-SHARP-TICK-2-80 := 45
  static DRIVER-PATTERN_LONG-DOUBLE-SHARP-TICK-3-60 := 46
  static DRIVER-PATTERN_BUZZ-1-100 := 47
  static DRIVER-PATTERN_BUZZ-2-80 := 48
  static DRIVER-PATTERN_BUZZ-3-60 := 49
  static DRIVER-PATTERN_BUZZ-4-40 := 50
  static DRIVER-PATTERN_BUZZ-5-20 := 51
  static DRIVER-PATTERN_PULSING-STRONG-1-100 := 52
  static DRIVER-PATTERN_PULSING-STRONG-2-60 := 53
  static DRIVER-PATTERN_PULSING-MEDIUM-1-100 := 54
  static DRIVER-PATTERN_PULSING-MEDIUM-2-60 := 55
  static DRIVER-PATTERN_PULSING-SHARP-1-100 := 56
  static DRIVER-PATTERN_PULSING-SHARP-2-60 := 57
  static DRIVER-PATTERN_TRANSITION-CLICK-1-100 := 58
  static DRIVER-PATTERN_TRANSITION-CLICK-2-80 := 59
  static DRIVER-PATTERN_TRANSITION-CLICK-3-60 := 60
  static DRIVER-PATTERN_TRANSITION-CLICK-4-40 := 61
  static DRIVER-PATTERN_TRANSITION-CLICK-5-20 := 62
  static DRIVER-PATTERN_TRANSITION-CLICK-6-10 := 63
  static DRIVER-PATTERN_TRANSITION-HUM-1-100 := 64
  static DRIVER-PATTERN_TRANSITION-HUM-2-80 := 65
  static DRIVER-PATTERN_TRANSITION-HUM-3-60 := 66
  static DRIVER-PATTERN_TRANSITION-HUM-4-40 := 67
  static DRIVER-PATTERN_TRANSITION-HUM-5-20 := 68
  static DRIVER-PATTERN_TRANSITION-HUM-6-10 := 69
  static DRIVER-PATTERN_TRANSITION-RAMP-DOWN-LONG-SMOOTH-1-100-TO-0 := 70
  static DRIVER-PATTERN_TRANSITION-RAMP-DOWN-LONG-SMOOTH-2-100-TO-0 := 71
  static DRIVER-PATTERN_TRANSITION-RAMP-DOWN-MEDIUM-SMOOTH-1-100-TO-0 := 72
  static DRIVER-PATTERN_TRANSITION-RAMP-DOWN-MEDIUM-SMOOTH-2-100-TO-0 := 73
  static DRIVER-PATTERN_TRANSITION-RAMP-DOWN-SHORT-SMOOTH-1-100-TO-0 := 74
  static DRIVER-PATTERN_TRANSITION-RAMP-DOWN-SHORT-SMOOTH-2-100-TO-0 := 75
  static DRIVER-PATTERN_TRANSITION-RAMP-DOWN-LONG-SHARP-1-100-TO-0 := 76
  static DRIVER-PATTERN_TRANSITION-RAMP-DOWN-LONG-SHARP-2-100-TO-0 := 77
  static DRIVER-PATTERN_TRANSITION-RAMP-DOWN-MEDIUM-SHARP-1-100-TO-0 := 78
  static DRIVER-PATTERN_TRANSITION-RAMP-DOWN-MEDIUM-SHARP-2-100-TO-0 := 79
  static DRIVER-PATTERN_TRANSITION-RAMP-DOWN-SHORT-SHARP-1-100-TO-0 := 80
  static DRIVER-PATTERN_TRANSITION-RAMP-DOWN-SHORT-SHARP-2-100-TO-0 := 81
  static DRIVER-PATTERN_TRANSITION-RAMP-UP-LONG-SMOOTH-1-0-TO-100 := 82
  static DRIVER-PATTERN_TRANSITION-RAMP-UP-LONG-SMOOTH-2-0-TO-100 := 83
  static DRIVER-PATTERN_TRANSITION-RAMP-UP-MEDIUM-SMOOTH-1-0-TO-100 := 84
  static DRIVER-PATTERN_TRANSITION-RAMP-UP-MEDIUM-SMOOTH-2-0-TO-100 := 85
  static DRIVER-PATTERN_TRANSITION-RAMP-UP-SHORT-SMOOTH-1-0-TO-100 := 86
  static DRIVER-PATTERN_TRANSITION-RAMP-UP-SHORT-SMOOTH-2-0-TO-100 := 87
  static DRIVER-PATTERN_TRANSITION-RAMP-UP-LONG-SHARP-1-0-TO-100 := 88
  static DRIVER-PATTERN_TRANSITION-RAMP-UP-LONG-SHARP-2-0-TO-100 := 89
  static DRIVER-PATTERN_TRANSITION-RAMP-UP-MEDIUM-SHARP-1-0-TO-100 := 90
  static DRIVER-PATTERN_TRANSITION-RAMP-UP-MEDIUM-SHARP-2-0-TO-100 := 91
  static DRIVER-PATTERN_TRANSITION-RAMP-UP-SHORT-SHARP-1-0-TO-100 := 92
  static DRIVER-PATTERN_TRANSITION-RAMP-UP-SHORT-SHARP-2-0-TO-100 := 93
  static DRIVER-PATTERN_TRANSITION-RAMP-DOWN-LONG-SMOOTH-1-50-TO-0 := 94
  static DRIVER-PATTERN_TRANSITION-RAMP-DOWN-LONG-SMOOTH-2-50-TO-0 := 95
  static DRIVER-PATTERN_TRANSITION-RAMP-DOWN-MEDIUM-SMOOTH-1-50-TO-0 := 96
  static DRIVER-PATTERN_TRANSITION-RAMP-DOWN-MEDIUM-SMOOTH-2-50-TO-0 := 97
  static DRIVER-PATTERN_TRANSITION-RAMP-DOWN-SHORT-SMOOTH-1-50-TO-0 := 98
  static DRIVER-PATTERN_TRANSITION-RAMP-DOWN-SHORT-SMOOTH-2-50-TO-0 := 99
  static DRIVER-PATTERN_TRANSITION-RAMP-DOWN-LONG-SHARP-1-50-TO-0 := 100
  static DRIVER-PATTERN_TRANSITION-RAMP-DOWN-LONG-SHARP-2-50-TO-0 := 101
  static DRIVER-PATTERN_TRANSITION-RAMP-DOWN-MEDIUM-SHARP-1-50-TO-0 := 102
  static DRIVER-PATTERN_TRANSITION-RAMP-DOWN-MEDIUM-SHARP-2-50-TO-0 := 103
  static DRIVER-PATTERN_TRANSITION-RAMP-DOWN-SHORT-SHARP-1-50-TO-0 := 104
  static DRIVER-PATTERN_TRANSITION-RAMP-DOWN-SHORT-SHARP-2-50-TO-0 := 105
  static DRIVER-PATTERN_TRANSITION-RAMP-UP-LONG-SMOOTH-1-0-TO-50 := 106
  static DRIVER-PATTERN_TRANSITION-RAMP-UP-LONG-SMOOTH-2-0-TO-50 := 107
  static DRIVER-PATTERN_TRANSITION-RAMP-UP-MEDIUM-SMOOTH-1-0-TO-50 := 108
  static DRIVER-PATTERN_TRANSITION-RAMP-UP-MEDIUM-SMOOTH-2-0-TO-50 := 109
  static DRIVER-PATTERN_TRANSITION-RAMP-UP-SHORT-SMOOTH-1-0-TO-50 := 110
  static DRIVER-PATTERN_TRANSITION-RAMP-UP-SHORT-SMOOTH-2-0-TO-50 := 111
  static DRIVER-PATTERN_TRANSITION-RAMP-UP-LONG-SHARP-1-0-TO-50 := 112
  static DRIVER-PATTERN_TRANSITION-RAMP-UP-LONG-SHARP-2-0-TO-50 := 113
  static DRIVER-PATTERN_TRANSITION-RAMP-UP-MEDIUM-SHARP-1-0-TO-50 := 114
  static DRIVER-PATTERN_TRANSITION-RAMP-UP-MEDIUM-SHARP-2-0-TO-50 := 115
  static DRIVER-PATTERN_TRANSITION-RAMP-UP-SHORT-SHARP-1-0-TO-50 := 116
  static DRIVER-PATTERN_TRANSITION-RAMP-UP-SHORT-SHARP-2-0-TO-50 := 117
  static DRIVER-PATTERN_LONG-BUZZ-FOR-PROGRAMMATIC-STOPPING-100 := 118
  static DRIVER-PATTERN_SMOOTH-HUM-1-50 := 119
  static DRIVER-PATTERN_SMOOTH-HUM-2-40 := 120
  static DRIVER-PATTERN_SMOOTH-HUM-3-30 := 121
  static DRIVER-PATTERN_SMOOTH-HUM-4-20 := 122
  static DRIVER-PATTERN_SMOOTH-HUM-5-10 := 123

  static DRIVER-PATTERN_STRINGS := {
    1: "Strong Click - 100%",
    2: "Strong Click - 60%",
    3: "Strong Click - 30%",
    4: "Sharp Click - 100%",
    5: "Sharp Click - 60%",
    6: "Sharp Click - 30%",
    7: "Soft Bump - 100%",
    8: "Soft Bump - 60%",
    9: "Soft Bump - 30%",
    10: "Double Click - 100%",
    11: "Double Click - 60%",
    12: "Triple Click - 100%",
    13: "Soft Fuzz - 60%",
    14: "Strong Buzz - 100%",
    15: "750ms Alert - 100%",
    16: "1000ms Alert - 100%",
    17: "Strong Click 1 - 100%",
    18: "Strong Click 2 - 80%",
    19: "Strong Click 3 - 60%",
    20: "Strong Click 4 - 30%",
    21: "Medium Click 1 - 100%",
    22: "Medium Click 2 - 80%",
    23: "Medium Click 3 - 60%",
    24: "Sharp Tick 1 - 100%",
    25: "Sharp Tick 2 - 80%",
    26: "Sharp Tick 3 - 60%",
    27: "Short Double Click Strong 1 - 100%",
    28: "Short Double Click Strong 2 - 80%",
    29: "Short Double Click Strong 3 - 60%",
    30: "Short Double Click Strong 4 - 30%",
    31: "Short Double Click Medium 1 - 100%",
    32: "Short Double Click Medium 2 - 80%",
    33: "Short Double Click Medium 3 - 60%",
    34: "Short Double Sharp Tick 1 - 100%",
    35: "Short Double Sharp Tick 2 - 80%",
    36: "Short Double Sharp Tick 3 - 60%",
    37: "Long Double Sharp Click Strong 1 - 100%",
    38: "Long Double Sharp Click Strong 2 - 80%",
    39: "Long Double Sharp Click Strong 3 - 60%",
    40: "Long Double Sharp Click Strong 4 - 30%",
    41: "Long Double Sharp Click Medium 1 - 100%",
    42: "Long Double Sharp Click Medium 2 - 80%",
    43: "Long Double Sharp Click Medium 3 - 60%",
    44: "Long Double Sharp Tick 1 - 100%",
    45: "Long Double Sharp Tick 2 - 80%",
    46: "Long Double Sharp Tick 3 - 60%",
    47: "Buzz 1 - 100%",
    48: "Buzz 2 - 80%",
    49: "Buzz 3 - 60%",
    50: "Buzz 4 - 40%",
    51: "Buzz 5 - 20%",
    52: "Pulsing Strong 1 - 100%",
    53: "Pulsing Strong 2 - 60%",
    54: "Pulsing Medium 1 - 100%",
    55: "Pulsing Medium 2 - 60%",
    56: "Pulsing Sharp 1 - 100%",
    57: "Pulsing Sharp 2 - 60%",
    58: "Transition Click 1 - 100%",
    59: "Transition Click 2 - 80%",
    60: "Transition Click 3 - 60%",
    61: "Transition Click 4 - 40%",
    62: "Transition Click 5 - 20%",
    63: "Transition Click 6 - 10%",
    64: "Transition Hum 1 - 100%",
    65: "Transition Hum 2 - 80%",
    66: "Transition Hum 3 - 60%",
    67: "Transition Hum 4 - 40%",
    68: "Transition Hum 5 - 20%",
    69: "Transition Hum 6 - 10%",
    70: "Transition Ramp Down Long Smooth 1 - 100 to 0%",
    71: "Transition Ramp Down Long Smooth 2 - 100 to 0%",
    72: "Transition Ramp Down Medium Smooth 1 - 100 to 0%",
    73: "Transition Ramp Down Medium Smooth 2 - 100 to 0%",
    74: "Transition Ramp Down Short Smooth 1 - 100 to 0%",
    75: "Transition Ramp Down Short Smooth 2 - 100 to 0%",
    76: "Transition Ramp Down Long Sharp 1 - 100 to 0%",
    77: "Transition Ramp Down Long Sharp 2 - 100 to 0%",
    78: "Transition Ramp Down Medium Sharp 1 - 100 to 0%",
    79: "Transition Ramp Down Medium Sharp 2 - 100 to 0%",
    80: "Transition Ramp Down Short Sharp 1 - 100 to 0%",
    81: "Transition Ramp Down Short Sharp 2 - 100 to 0%",
    82: "Transition Ramp Up Long Smooth 1 - 0 to 100%",
    83: "Transition Ramp Up Long Smooth 2 - 0 to 100%",
    84: "Transition Ramp Up Medium Smooth 1 - 0 to 100%",
    85: "Transition Ramp Up Medium Smooth 2 - 0 to 100%",
    86: "Transition Ramp Up Short Smooth 1 - 0 to 100%",
    87: "Transition Ramp Up Short Smooth 2 - 0 to 100%",
    88: "Transition Ramp Up Long Sharp 1 - 0 to 100%",
    89: "Transition Ramp Up Long Sharp 2 - 0 to 100%",
    90: "Transition Ramp Up Medium Sharp 1 - 0 to 100%",
    91: "Transition Ramp Up Medium Sharp 2 - 0 to 100%",
    92: "Transition Ramp Up Short Sharp 1 - 0 to 100%",
    93: "Transition Ramp Up Short Sharp 2 - 0 to 100%",
    94: "Transition Ramp Down Long Smooth 1 - 50 to 0%",
    95: "Transition Ramp Down Long Smooth 2 - 50 to 0%",
    96: "Transition Ramp Down Medium Smooth 1 - 50 to 0%",
    97: "Transition Ramp Down Medium Smooth 2 - 50 to 0%",
    98: "Transition Ramp Down Short Smooth 1 - 50 to 0%",
    99: "Transition Ramp Down Short Smooth 2 - 50 to 0%",
    100: "Transition Ramp Down Long Sharp 1 - 50 to 0%",
    101: "Transition Ramp Down Long Sharp 2 - 50 to 0%",
    102: "Transition Ramp Down Medium Sharp 1 - 50 to 0%",
    103: "Transition Ramp Down Medium Sharp 2 - 50 to 0%",
    104: "Transition Ramp Down Short Sharp 1 - 50 to 0%",
    105: "Transition Ramp Down Short Sharp 2 - 50 to 0%",
    106: "Transition Ramp Up Long Smooth 1 - 0 to 50%",
    107: "Transition Ramp Up Long Smooth 2 - 0 to 50%",
    108: "Transition Ramp Up Medium Smooth 1 - 0 to 50%",
    109: "Transition Ramp Up Medium Smooth 2 - 0 to 50%",
    110: "Transition Ramp Up Short Smooth 1 - 0 to 50%",
    111: "Transition Ramp Up Short Smooth 2 - 0 to 50%",
    112: "Transition Ramp Up Long Sharp 1 - 0 to 50%",
    113: "Transition Ramp Up Long Sharp 2 - 0 to 50%",
    114: "Transition Ramp Up Medium Sharp 1 - 0 to 50%",
    115: "Transition Ramp Up Medium Sharp 2 - 0 to 50%",
    116: "Transition Ramp Up Short Sharp 1 - 0 to 50%",
    117: "Transition Ramp Up Short Sharp 2 - 0 to 50%",
    118: "Long buzz for programmatic stopping - 100%",
    119: "Smooth Hum 1 (No kick or brake pulse) - 50%",
    120: "Smooth Hum 2 (No kick or brake pulse) - 40%",
    121: "Smooth Hum 3 (No kick or brake pulse) - 30%",
    122: "Smooth Hum 4 (No kick or brake pulse) - 20%",
    123: "Smooth Hum 5 (No kick or brake pulse) - 10%",
  }

  static driver-pattern-from-int value/int -> string:
    return DRIVER-PATTERN_STRINGS.get value --if-absent=(: "unknown")


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
  static data --pattern/int?=null --intensity/int?=null --driver-pattern/int?=null --base-data/protocol.Data?=protocol.Data -> protocol.Data:
    data := base-data
    if pattern != null: data.add-data-uint PATTERN pattern
    if intensity != null: data.add-data-uint INTENSITY intensity
    if driver-pattern != null: data.add-data-uint DRIVER-PATTERN driver-pattern
    return data

  /**
   * Creates a SET Request message for Haptics Control.
   *
   * Returns: A Message ready to be sent
   */
  static set-msg --base-data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-method MT protocol.Header.METHOD-SET base-data

  /**
   * Pattern of haptics [1-3]
   *
   * Valid values:
   * - PATTERN_FADE (1): Default
   * - PATTERN_PULSE (2): Pulse
   * - PATTERN_DROP (3): Drop
   */
  pattern -> int:
    return get-data-uint PATTERN

  /**
   * Intensity of haptics [0-2]
   *
   * Valid values:
   * - INTENSITY_LOW (0): Low
   * - INTENSITY_MEDIUM (1): Medium
   * - INTENSITY_HIGH (2): High
   */
  intensity -> int:
    return get-data-uint INTENSITY

  /**
   * Direct DRV2605 ROM effect index [1-123].
   * Must be sent on its own (without Pattern, Intensity, or Header Duration).
   *
   *
   * Valid values:
   * - DRIVER-PATTERN_STRONG-CLICK-100 (1): Strong Click - 100%
   * - DRIVER-PATTERN_STRONG-CLICK-60 (2): Strong Click - 60%
   * - DRIVER-PATTERN_STRONG-CLICK-30 (3): Strong Click - 30%
   * - DRIVER-PATTERN_SHARP-CLICK-100 (4): Sharp Click - 100%
   * - DRIVER-PATTERN_SHARP-CLICK-60 (5): Sharp Click - 60%
   * - DRIVER-PATTERN_SHARP-CLICK-30 (6): Sharp Click - 30%
   * - DRIVER-PATTERN_SOFT-BUMP-100 (7): Soft Bump - 100%
   * - DRIVER-PATTERN_SOFT-BUMP-60 (8): Soft Bump - 60%
   * - DRIVER-PATTERN_SOFT-BUMP-30 (9): Soft Bump - 30%
   * - DRIVER-PATTERN_DOUBLE-CLICK-100 (10): Double Click - 100%
   * - DRIVER-PATTERN_DOUBLE-CLICK-60 (11): Double Click - 60%
   * - DRIVER-PATTERN_TRIPLE-CLICK-100 (12): Triple Click - 100%
   * - DRIVER-PATTERN_SOFT-FUZZ-60 (13): Soft Fuzz - 60%
   * - DRIVER-PATTERN_STRONG-BUZZ-100 (14): Strong Buzz - 100%
   * - DRIVER-PATTERN_750MS-ALERT-100 (15): 750ms Alert - 100%
   * - DRIVER-PATTERN_1000MS-ALERT-100 (16): 1000ms Alert - 100%
   * - DRIVER-PATTERN_STRONG-CLICK-1-100 (17): Strong Click 1 - 100%
   * - DRIVER-PATTERN_STRONG-CLICK-2-80 (18): Strong Click 2 - 80%
   * - DRIVER-PATTERN_STRONG-CLICK-3-60 (19): Strong Click 3 - 60%
   * - DRIVER-PATTERN_STRONG-CLICK-4-30 (20): Strong Click 4 - 30%
   * - DRIVER-PATTERN_MEDIUM-CLICK-1-100 (21): Medium Click 1 - 100%
   * - DRIVER-PATTERN_MEDIUM-CLICK-2-80 (22): Medium Click 2 - 80%
   * - DRIVER-PATTERN_MEDIUM-CLICK-3-60 (23): Medium Click 3 - 60%
   * - DRIVER-PATTERN_SHARP-TICK-1-100 (24): Sharp Tick 1 - 100%
   * - DRIVER-PATTERN_SHARP-TICK-2-80 (25): Sharp Tick 2 - 80%
   * - DRIVER-PATTERN_SHARP-TICK-3-60 (26): Sharp Tick 3 - 60%
   * - DRIVER-PATTERN_SHORT-DOUBLE-CLICK-STRONG-1-100 (27): Short Double Click Strong 1 - 100%
   * - DRIVER-PATTERN_SHORT-DOUBLE-CLICK-STRONG-2-80 (28): Short Double Click Strong 2 - 80%
   * - DRIVER-PATTERN_SHORT-DOUBLE-CLICK-STRONG-3-60 (29): Short Double Click Strong 3 - 60%
   * - DRIVER-PATTERN_SHORT-DOUBLE-CLICK-STRONG-4-30 (30): Short Double Click Strong 4 - 30%
   * - DRIVER-PATTERN_SHORT-DOUBLE-CLICK-MEDIUM-1-100 (31): Short Double Click Medium 1 - 100%
   * - DRIVER-PATTERN_SHORT-DOUBLE-CLICK-MEDIUM-2-80 (32): Short Double Click Medium 2 - 80%
   * - DRIVER-PATTERN_SHORT-DOUBLE-CLICK-MEDIUM-3-60 (33): Short Double Click Medium 3 - 60%
   * - DRIVER-PATTERN_SHORT-DOUBLE-SHARP-TICK-1-100 (34): Short Double Sharp Tick 1 - 100%
   * - DRIVER-PATTERN_SHORT-DOUBLE-SHARP-TICK-2-80 (35): Short Double Sharp Tick 2 - 80%
   * - DRIVER-PATTERN_SHORT-DOUBLE-SHARP-TICK-3-60 (36): Short Double Sharp Tick 3 - 60%
   * - DRIVER-PATTERN_LONG-DOUBLE-SHARP-CLICK-STRONG-1-100 (37): Long Double Sharp Click Strong 1 - 100%
   * - DRIVER-PATTERN_LONG-DOUBLE-SHARP-CLICK-STRONG-2-80 (38): Long Double Sharp Click Strong 2 - 80%
   * - DRIVER-PATTERN_LONG-DOUBLE-SHARP-CLICK-STRONG-3-60 (39): Long Double Sharp Click Strong 3 - 60%
   * - DRIVER-PATTERN_LONG-DOUBLE-SHARP-CLICK-STRONG-4-30 (40): Long Double Sharp Click Strong 4 - 30%
   * - DRIVER-PATTERN_LONG-DOUBLE-SHARP-CLICK-MEDIUM-1-100 (41): Long Double Sharp Click Medium 1 - 100%
   * - DRIVER-PATTERN_LONG-DOUBLE-SHARP-CLICK-MEDIUM-2-80 (42): Long Double Sharp Click Medium 2 - 80%
   * - DRIVER-PATTERN_LONG-DOUBLE-SHARP-CLICK-MEDIUM-3-60 (43): Long Double Sharp Click Medium 3 - 60%
   * - DRIVER-PATTERN_LONG-DOUBLE-SHARP-TICK-1-100 (44): Long Double Sharp Tick 1 - 100%
   * - DRIVER-PATTERN_LONG-DOUBLE-SHARP-TICK-2-80 (45): Long Double Sharp Tick 2 - 80%
   * - DRIVER-PATTERN_LONG-DOUBLE-SHARP-TICK-3-60 (46): Long Double Sharp Tick 3 - 60%
   * - DRIVER-PATTERN_BUZZ-1-100 (47): Buzz 1 - 100%
   * - DRIVER-PATTERN_BUZZ-2-80 (48): Buzz 2 - 80%
   * - DRIVER-PATTERN_BUZZ-3-60 (49): Buzz 3 - 60%
   * - DRIVER-PATTERN_BUZZ-4-40 (50): Buzz 4 - 40%
   * - DRIVER-PATTERN_BUZZ-5-20 (51): Buzz 5 - 20%
   * - DRIVER-PATTERN_PULSING-STRONG-1-100 (52): Pulsing Strong 1 - 100%
   * - DRIVER-PATTERN_PULSING-STRONG-2-60 (53): Pulsing Strong 2 - 60%
   * - DRIVER-PATTERN_PULSING-MEDIUM-1-100 (54): Pulsing Medium 1 - 100%
   * - DRIVER-PATTERN_PULSING-MEDIUM-2-60 (55): Pulsing Medium 2 - 60%
   * - DRIVER-PATTERN_PULSING-SHARP-1-100 (56): Pulsing Sharp 1 - 100%
   * - DRIVER-PATTERN_PULSING-SHARP-2-60 (57): Pulsing Sharp 2 - 60%
   * - DRIVER-PATTERN_TRANSITION-CLICK-1-100 (58): Transition Click 1 - 100%
   * - DRIVER-PATTERN_TRANSITION-CLICK-2-80 (59): Transition Click 2 - 80%
   * - DRIVER-PATTERN_TRANSITION-CLICK-3-60 (60): Transition Click 3 - 60%
   * - DRIVER-PATTERN_TRANSITION-CLICK-4-40 (61): Transition Click 4 - 40%
   * - DRIVER-PATTERN_TRANSITION-CLICK-5-20 (62): Transition Click 5 - 20%
   * - DRIVER-PATTERN_TRANSITION-CLICK-6-10 (63): Transition Click 6 - 10%
   * - DRIVER-PATTERN_TRANSITION-HUM-1-100 (64): Transition Hum 1 - 100%
   * - DRIVER-PATTERN_TRANSITION-HUM-2-80 (65): Transition Hum 2 - 80%
   * - DRIVER-PATTERN_TRANSITION-HUM-3-60 (66): Transition Hum 3 - 60%
   * - DRIVER-PATTERN_TRANSITION-HUM-4-40 (67): Transition Hum 4 - 40%
   * - DRIVER-PATTERN_TRANSITION-HUM-5-20 (68): Transition Hum 5 - 20%
   * - DRIVER-PATTERN_TRANSITION-HUM-6-10 (69): Transition Hum 6 - 10%
   * - DRIVER-PATTERN_TRANSITION-RAMP-DOWN-LONG-SMOOTH-1-100-TO-0 (70): Transition Ramp Down Long Smooth 1 - 100 to 0%
   * - DRIVER-PATTERN_TRANSITION-RAMP-DOWN-LONG-SMOOTH-2-100-TO-0 (71): Transition Ramp Down Long Smooth 2 - 100 to 0%
   * - DRIVER-PATTERN_TRANSITION-RAMP-DOWN-MEDIUM-SMOOTH-1-100-TO-0 (72): Transition Ramp Down Medium Smooth 1 - 100 to 0%
   * - DRIVER-PATTERN_TRANSITION-RAMP-DOWN-MEDIUM-SMOOTH-2-100-TO-0 (73): Transition Ramp Down Medium Smooth 2 - 100 to 0%
   * - DRIVER-PATTERN_TRANSITION-RAMP-DOWN-SHORT-SMOOTH-1-100-TO-0 (74): Transition Ramp Down Short Smooth 1 - 100 to 0%
   * - DRIVER-PATTERN_TRANSITION-RAMP-DOWN-SHORT-SMOOTH-2-100-TO-0 (75): Transition Ramp Down Short Smooth 2 - 100 to 0%
   * - DRIVER-PATTERN_TRANSITION-RAMP-DOWN-LONG-SHARP-1-100-TO-0 (76): Transition Ramp Down Long Sharp 1 - 100 to 0%
   * - DRIVER-PATTERN_TRANSITION-RAMP-DOWN-LONG-SHARP-2-100-TO-0 (77): Transition Ramp Down Long Sharp 2 - 100 to 0%
   * - DRIVER-PATTERN_TRANSITION-RAMP-DOWN-MEDIUM-SHARP-1-100-TO-0 (78): Transition Ramp Down Medium Sharp 1 - 100 to 0%
   * - DRIVER-PATTERN_TRANSITION-RAMP-DOWN-MEDIUM-SHARP-2-100-TO-0 (79): Transition Ramp Down Medium Sharp 2 - 100 to 0%
   * - DRIVER-PATTERN_TRANSITION-RAMP-DOWN-SHORT-SHARP-1-100-TO-0 (80): Transition Ramp Down Short Sharp 1 - 100 to 0%
   * - DRIVER-PATTERN_TRANSITION-RAMP-DOWN-SHORT-SHARP-2-100-TO-0 (81): Transition Ramp Down Short Sharp 2 - 100 to 0%
   * - DRIVER-PATTERN_TRANSITION-RAMP-UP-LONG-SMOOTH-1-0-TO-100 (82): Transition Ramp Up Long Smooth 1 - 0 to 100%
   * - DRIVER-PATTERN_TRANSITION-RAMP-UP-LONG-SMOOTH-2-0-TO-100 (83): Transition Ramp Up Long Smooth 2 - 0 to 100%
   * - DRIVER-PATTERN_TRANSITION-RAMP-UP-MEDIUM-SMOOTH-1-0-TO-100 (84): Transition Ramp Up Medium Smooth 1 - 0 to 100%
   * - DRIVER-PATTERN_TRANSITION-RAMP-UP-MEDIUM-SMOOTH-2-0-TO-100 (85): Transition Ramp Up Medium Smooth 2 - 0 to 100%
   * - DRIVER-PATTERN_TRANSITION-RAMP-UP-SHORT-SMOOTH-1-0-TO-100 (86): Transition Ramp Up Short Smooth 1 - 0 to 100%
   * - DRIVER-PATTERN_TRANSITION-RAMP-UP-SHORT-SMOOTH-2-0-TO-100 (87): Transition Ramp Up Short Smooth 2 - 0 to 100%
   * - DRIVER-PATTERN_TRANSITION-RAMP-UP-LONG-SHARP-1-0-TO-100 (88): Transition Ramp Up Long Sharp 1 - 0 to 100%
   * - DRIVER-PATTERN_TRANSITION-RAMP-UP-LONG-SHARP-2-0-TO-100 (89): Transition Ramp Up Long Sharp 2 - 0 to 100%
   * - DRIVER-PATTERN_TRANSITION-RAMP-UP-MEDIUM-SHARP-1-0-TO-100 (90): Transition Ramp Up Medium Sharp 1 - 0 to 100%
   * - DRIVER-PATTERN_TRANSITION-RAMP-UP-MEDIUM-SHARP-2-0-TO-100 (91): Transition Ramp Up Medium Sharp 2 - 0 to 100%
   * - DRIVER-PATTERN_TRANSITION-RAMP-UP-SHORT-SHARP-1-0-TO-100 (92): Transition Ramp Up Short Sharp 1 - 0 to 100%
   * - DRIVER-PATTERN_TRANSITION-RAMP-UP-SHORT-SHARP-2-0-TO-100 (93): Transition Ramp Up Short Sharp 2 - 0 to 100%
   * - DRIVER-PATTERN_TRANSITION-RAMP-DOWN-LONG-SMOOTH-1-50-TO-0 (94): Transition Ramp Down Long Smooth 1 - 50 to 0%
   * - DRIVER-PATTERN_TRANSITION-RAMP-DOWN-LONG-SMOOTH-2-50-TO-0 (95): Transition Ramp Down Long Smooth 2 - 50 to 0%
   * - DRIVER-PATTERN_TRANSITION-RAMP-DOWN-MEDIUM-SMOOTH-1-50-TO-0 (96): Transition Ramp Down Medium Smooth 1 - 50 to 0%
   * - DRIVER-PATTERN_TRANSITION-RAMP-DOWN-MEDIUM-SMOOTH-2-50-TO-0 (97): Transition Ramp Down Medium Smooth 2 - 50 to 0%
   * - DRIVER-PATTERN_TRANSITION-RAMP-DOWN-SHORT-SMOOTH-1-50-TO-0 (98): Transition Ramp Down Short Smooth 1 - 50 to 0%
   * - DRIVER-PATTERN_TRANSITION-RAMP-DOWN-SHORT-SMOOTH-2-50-TO-0 (99): Transition Ramp Down Short Smooth 2 - 50 to 0%
   * - DRIVER-PATTERN_TRANSITION-RAMP-DOWN-LONG-SHARP-1-50-TO-0 (100): Transition Ramp Down Long Sharp 1 - 50 to 0%
   * - DRIVER-PATTERN_TRANSITION-RAMP-DOWN-LONG-SHARP-2-50-TO-0 (101): Transition Ramp Down Long Sharp 2 - 50 to 0%
   * - DRIVER-PATTERN_TRANSITION-RAMP-DOWN-MEDIUM-SHARP-1-50-TO-0 (102): Transition Ramp Down Medium Sharp 1 - 50 to 0%
   * - DRIVER-PATTERN_TRANSITION-RAMP-DOWN-MEDIUM-SHARP-2-50-TO-0 (103): Transition Ramp Down Medium Sharp 2 - 50 to 0%
   * - DRIVER-PATTERN_TRANSITION-RAMP-DOWN-SHORT-SHARP-1-50-TO-0 (104): Transition Ramp Down Short Sharp 1 - 50 to 0%
   * - DRIVER-PATTERN_TRANSITION-RAMP-DOWN-SHORT-SHARP-2-50-TO-0 (105): Transition Ramp Down Short Sharp 2 - 50 to 0%
   * - DRIVER-PATTERN_TRANSITION-RAMP-UP-LONG-SMOOTH-1-0-TO-50 (106): Transition Ramp Up Long Smooth 1 - 0 to 50%
   * - DRIVER-PATTERN_TRANSITION-RAMP-UP-LONG-SMOOTH-2-0-TO-50 (107): Transition Ramp Up Long Smooth 2 - 0 to 50%
   * - DRIVER-PATTERN_TRANSITION-RAMP-UP-MEDIUM-SMOOTH-1-0-TO-50 (108): Transition Ramp Up Medium Smooth 1 - 0 to 50%
   * - DRIVER-PATTERN_TRANSITION-RAMP-UP-MEDIUM-SMOOTH-2-0-TO-50 (109): Transition Ramp Up Medium Smooth 2 - 0 to 50%
   * - DRIVER-PATTERN_TRANSITION-RAMP-UP-SHORT-SMOOTH-1-0-TO-50 (110): Transition Ramp Up Short Smooth 1 - 0 to 50%
   * - DRIVER-PATTERN_TRANSITION-RAMP-UP-SHORT-SMOOTH-2-0-TO-50 (111): Transition Ramp Up Short Smooth 2 - 0 to 50%
   * - DRIVER-PATTERN_TRANSITION-RAMP-UP-LONG-SHARP-1-0-TO-50 (112): Transition Ramp Up Long Sharp 1 - 0 to 50%
   * - DRIVER-PATTERN_TRANSITION-RAMP-UP-LONG-SHARP-2-0-TO-50 (113): Transition Ramp Up Long Sharp 2 - 0 to 50%
   * - DRIVER-PATTERN_TRANSITION-RAMP-UP-MEDIUM-SHARP-1-0-TO-50 (114): Transition Ramp Up Medium Sharp 1 - 0 to 50%
   * - DRIVER-PATTERN_TRANSITION-RAMP-UP-MEDIUM-SHARP-2-0-TO-50 (115): Transition Ramp Up Medium Sharp 2 - 0 to 50%
   * - DRIVER-PATTERN_TRANSITION-RAMP-UP-SHORT-SHARP-1-0-TO-50 (116): Transition Ramp Up Short Sharp 1 - 0 to 50%
   * - DRIVER-PATTERN_TRANSITION-RAMP-UP-SHORT-SHARP-2-0-TO-50 (117): Transition Ramp Up Short Sharp 2 - 0 to 50%
   * - DRIVER-PATTERN_LONG-BUZZ-FOR-PROGRAMMATIC-STOPPING-100 (118): Long buzz for programmatic stopping - 100%
   * - DRIVER-PATTERN_SMOOTH-HUM-1-50 (119): Smooth Hum 1 (No kick or brake pulse) - 50%
   * - DRIVER-PATTERN_SMOOTH-HUM-2-40 (120): Smooth Hum 2 (No kick or brake pulse) - 40%
   * - DRIVER-PATTERN_SMOOTH-HUM-3-30 (121): Smooth Hum 3 (No kick or brake pulse) - 30%
   * - DRIVER-PATTERN_SMOOTH-HUM-4-20 (122): Smooth Hum 4 (No kick or brake pulse) - 20%
   * - DRIVER-PATTERN_SMOOTH-HUM-5-10 (123): Smooth Hum 5 (No kick or brake pulse) - 10%
   */
  driver-pattern -> int:
    return get-data-uint DRIVER-PATTERN

  stringify -> string:
    return {
      "pattern": pattern,
      "intensity": intensity,
      "driverPattern": driver-pattern,
    }.stringify
