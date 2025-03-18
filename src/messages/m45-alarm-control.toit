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

    static doMsg --legacyAlarmAction/int?=null --duration/int?=null --buzzerPattern/int?=null --buzzerIntensity/int?=null --hapticsPattern/int?=null --hapticsIntensity/int?=null --strobePattern/int?=null --strobeIntensity/int?=null --promptMessage/string?=null --promptTimeout/int?=null --promptButton1Text/string?=null --promptButton2Text/string?=null --promptButton3Text/string?=null -> protocol.Message:
        msg := protocol.Message MT
        if legacyAlarmAction:
            msg.data.addDataUint32 LEGACY-ALARM-ACTION legacyAlarmAction
        if duration:
            msg.data.addDataUint8 DURATION duration
        if buzzerPattern:
            msg.data.addDataUint8 BUZZER-PATTERN buzzerPattern
        if buzzerIntensity:
            msg.data.addDataUint8 BUZZER-INTENSITY buzzerIntensity
        if hapticsPattern:
            msg.data.addDataUint8 HAPTICS-PATTERN hapticsPattern
        if hapticsIntensity:
            msg.data.addDataUint8 HAPTICS-INTENSITY hapticsIntensity
        if strobePattern:
            msg.data.addDataUint8 STROBE-PATTERN strobePattern
        if strobeIntensity:
            msg.data.addDataUint8 STROBE-INTENSITY strobeIntensity
        if promptMessage:
            msg.data.addDataAscii PROMPT-MESSAGE promptMessage
        if promptTimeout:
            msg.data.addDataUint8 PROMPT-TIMEOUT promptTimeout
        if promptButton1Text:
            msg.data.addDataAscii PROMPT-BUTTON-1-TEXT promptButton1Text
        if promptButton2Text:
            msg.data.addDataAscii PROMPT-BUTTON-2-TEXT promptButton2Text
        if promptButton3Text:
            msg.data.addDataAscii PROMPT-BUTTON-3-TEXT promptButton3Text
        msg.header.data.addDataUint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-DO
        return msg

    constructor.fromData data/protocol.Data:
        super.fromData data

    legacyAlarmAction -> int:
        return getDataUint32 LEGACY-ALARM-ACTION

    duration -> int:
        return getDataUint8 DURATION

    buzzerPattern -> int:
        return getDataUint8 BUZZER-PATTERN

    buzzerIntensity -> int:
        return getDataUint8 BUZZER-INTENSITY

    hapticsPattern -> int:
        return getDataUint8 HAPTICS-PATTERN

    hapticsIntensity -> int:
        return getDataUint8 HAPTICS-INTENSITY

    strobePattern -> int:
        return getDataUint8 STROBE-PATTERN

    strobeIntensity -> int:
        return getDataUint8 STROBE-INTENSITY

    promptMessage -> string:
        return getDataAscii PROMPT-MESSAGE

    promptTimeout -> int:
        return getDataUint8 PROMPT-TIMEOUT

    promptButton1Text -> string:
        return getDataAscii PROMPT-BUTTON-1-TEXT

    promptButton2Text -> string:
        return getDataAscii PROMPT-BUTTON-2-TEXT

    promptButton3Text -> string:
        return getDataAscii PROMPT-BUTTON-3-TEXT

    stringify -> string:
        return {
                "Legacy Alarm Action": legacyAlarmAction,
                "Duration": duration,
                "Buzzer Pattern": buzzerPattern,
                "Buzzer Intensity": buzzerIntensity,
                "Haptics Pattern": hapticsPattern,
                "Haptics Intensity": hapticsIntensity,
                "Strobe Pattern": strobePattern,
                "Strobe Intensity": strobeIntensity,
                "Prompt Message": promptMessage,
                "Prompt Timeout": promptTimeout,
                "Prompt Button 1 Text": promptButton1Text,
                "Prompt Button 2 Text": promptButton2Text,
                "Prompt Button 3 Text": promptButton3Text,
        }.stringify
