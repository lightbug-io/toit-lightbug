import ..protocol as protocol

class BuzzerControl extends protocol.Data:
    static MT := 42
    static DURATION := 1 // Duration of buzzer in milliseconds
    static SOUND_TYPE := 2
    static INTENSITY := 3
    static RUN_COUNT := 4
    static FREQUENCY := 5 // Frequency of buzzer of KHz.

    static SOUND_SOLID := 0
    static SOUND_SIREN := 1
    static SOUND_BEEP_BEEP := 2
    static SOUND_AMBULANCE := 3
    static SOUND_FIRE_TRUCK := 4
    static SOUND_POSITIVE1 := 5
    static SOUND_SLOW_BEEP := 6
    static SOUND_ALARM := 7

    static doMsg --duration/int?=null --soundType/int?=null --intensity/int?=null --runCount/int?=null --frequency/float?=null -> protocol.Message:
        msg := protocol.Message MT
        if duration:
            msg.data.addDataUint16 DURATION duration
        if soundType:
            msg.data.addDataUint8 SOUND_TYPE soundType
        if intensity:
            msg.data.addDataUint8 INTENSITY intensity
        if runCount:
            msg.data.addDataUint8 RUN_COUNT runCount
        if frequency:
            msg.data.addDataFloat32 FREQUENCY frequency
        msg.header.data.addDataUint8 protocol.Header.TYPE_MESSAGE_METHOD protocol.Header.METHOD_DO
        return msg

    constructor.fromData data/protocol.Data:
        super.fromData data

    duration -> int:
        return getDataUint16 DURATION

    soundType -> int:
        return getDataUint8 SOUND_TYPE

    intensity -> int:
        return getDataUint8 INTENSITY

    runCount -> int:
        return getDataUint8 RUN_COUNT

    frequency -> float:
        return getDataFloat32 FREQUENCY

    stringify -> string:
        return {
                "Duration": duration,
                "Sound Type": soundType,
                "Intensity": intensity,
                "Run Count": runCount,
                "Frequency": frequency,
        }.stringify
