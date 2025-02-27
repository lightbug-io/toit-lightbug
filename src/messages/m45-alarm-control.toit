import ..protocol as protocol

class AlarmControl extends protocol.Data:
    static MT := 45
    static LEGACY_ALARM_ACTION := 1 // 4 bytes of encoded data relating to legacy alarm formats
    static DURATION := 2 // Duration of alarm in seconds
    static BUZZER_PATTERN := 3
    static BUZZER_INTENSITY := 4
    static HAPTICS_PATTERN := 5
    static HAPTICS_INTENSITY := 6
    static STROBE_PATTERN := 7
    static STROBE_INTENSITY := 8
    static PROMPT_MESSAGE := 9
    static PROMPT_TIMEOUT := 10 // Timeout for the prompt in seconds
    static PROMPT_BUTTON_1_TEXT := 11
    static PROMPT_BUTTON_2_TEXT := 12
    static PROMPT_BUTTON_3_TEXT := 13

    static doMsg --legacyAlarmAction/int?=null --duration/int?=null --buzzerPattern/int?=null --buzzerIntensity/int?=null --hapticsPattern/int?=null --hapticsIntensity/int?=null --strobePattern/int?=null --strobeIntensity/int?=null --promptMessage/string?=null --promptTimeout/int?=null --promptButton1Text/string?=null --promptButton2Text/string?=null --promptButton3Text/string?=null -> protocol.Message:
        msg := protocol.Message MT
        if legacyAlarmAction:
            msg.data.addDataUint32 LEGACY_ALARM_ACTION legacyAlarmAction
        if duration:
            msg.data.addDataUint8 DURATION duration
        if buzzerPattern:
            msg.data.addDataUint8 BUZZER_PATTERN buzzerPattern
        if buzzerIntensity:
            msg.data.addDataUint8 BUZZER_INTENSITY buzzerIntensity
        if hapticsPattern:
            msg.data.addDataUint8 HAPTICS_PATTERN hapticsPattern
        if hapticsIntensity:
            msg.data.addDataUint8 HAPTICS_INTENSITY hapticsIntensity
        if strobePattern:
            msg.data.addDataUint8 STROBE_PATTERN strobePattern
        if strobeIntensity:
            msg.data.addDataUint8 STROBE_INTENSITY strobeIntensity
        if promptMessage:
            msg.data.addDataAscii PROMPT_MESSAGE promptMessage
        if promptTimeout:
            msg.data.addDataUint8 PROMPT_TIMEOUT promptTimeout
        if promptButton1Text:
            msg.data.addDataAscii PROMPT_BUTTON_1_TEXT promptButton1Text
        if promptButton2Text:
            msg.data.addDataAscii PROMPT_BUTTON_2_TEXT promptButton2Text
        if promptButton3Text:
            msg.data.addDataAscii PROMPT_BUTTON_3_TEXT promptButton3Text
        msg.header.data.addDataUint8 protocol.Header.TYPE_MESSAGE_METHOD protocol.Header.METHOD_DO
        return msg

    constructor.fromData data/protocol.Data:
        super.fromData data

    legacyAlarmAction -> int:
        return getDataUint32 LEGACY_ALARM_ACTION

    duration -> int:
        return getDataUint8 DURATION

    buzzerPattern -> int:
        return getDataUint8 BUZZER_PATTERN

    buzzerIntensity -> int:
        return getDataUint8 BUZZER_INTENSITY

    hapticsPattern -> int:
        return getDataUint8 HAPTICS_PATTERN

    hapticsIntensity -> int:
        return getDataUint8 HAPTICS_INTENSITY

    strobePattern -> int:
        return getDataUint8 STROBE_PATTERN

    strobeIntensity -> int:
        return getDataUint8 STROBE_INTENSITY

    promptMessage -> string:
        return getDataAscii PROMPT_MESSAGE

    promptTimeout -> int:
        return getDataUint8 PROMPT_TIMEOUT

    promptButton1Text -> string:
        return getDataAscii PROMPT_BUTTON_1_TEXT

    promptButton2Text -> string:
        return getDataAscii PROMPT_BUTTON_2_TEXT

    promptButton3Text -> string:
        return getDataAscii PROMPT_BUTTON_3_TEXT

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
