import ...messages as messages
import ...util.bitmaps show lightbug4040

// TODO these should be defined elsewhere
SCREEN_WIDTH := 250
SCREEN_HEIGHT := 122

// A set of predefined messages that can be shown as buttons on the web page
sample-messages := {
    "Getters": {
        "$(messages.LastPosition.MT) Location": (messages.LastPosition.getMsg).bytesForProtocol,
        "$(messages.Status.MT) Status": (messages.Status.getMsg).bytesForProtocol,
        "$(messages.DeviceIds.MT) Device IDs": (messages.DeviceIds.getMsg).bytesForProtocol,
        "$(messages.DeviceTime.MT) Time": (messages.DeviceTime.getMsg).bytesForProtocol,
        "$(messages.Temperature.MT) Temperature": (messages.Temperature.getMsg).bytesForProtocol,
        "$(messages.Pressure.MT) Pressure": (messages.Pressure.getMsg).bytesForProtocol,
        "$(messages.BatteryStatus.MT) Battery": (messages.BatteryStatus.getMsg).bytesForProtocol,
    },
    "Actions": {
        "$(messages.TxNow.MT) Cellular 'Transmit Now'": (messages.TxNow.doMsg --data="hello".to-byte-array).bytesForProtocol,
    },
    "Screen": {
        "$(messages.PresetPage.MT) Home page": messages.PresetPage.toMsg.bytesForProtocol,
        "$(messages.MenuPage.MT) Menu 3 items": (messages.MenuPage.toMsg --pageId=101 --items=["Option 1", "Option 2", "Option 3"]).bytesForProtocol,
        "$(messages.TextPage.MT) Text page": (messages.TextPage.toMsg --pageId=102 --pageTitle="Page 101" --line1="First Line" --line2="Second Line").bytesForProtocol,
        "$(messages.DrawBitmap.MT) Lightbug Logo": (messages.DrawBitmap.toMsg --pageId=103 --bitmapData=lightbug4040 --bitmapHeight=40 --bitmapWidth=40).bytesForProtocol,
        // TODO this should be able to overlay a logo on a page (whatever page is being displayed) if not pageid is set
        // "$(messages.DrawBitmap.MT) Overlay Logo": (messages.DrawBitmap.toMsg --bitmapData=lightbug4040 --bitmapHeight=40 --bitmapWidth=40 --bitmapOverlay=true --bitmapX=(SCREEN_WIDTH - 40) --bitmapY=(SCREEN_HEIGHT - 40)).bytesForProtocol,
    },
    "$(messages.HapticsControl.MT) Haptics": {
        "Pattern 1 low intensity": (messages.HapticsControl.doMsg messages.HapticsControl.PATTERN_1 messages.HapticsControl.INTENSITY-LOW).bytesForProtocol,
        "Pattern 2 low intensity": (messages.HapticsControl.doMsg messages.HapticsControl.PATTERN_2 messages.HapticsControl.INTENSITY-LOW).bytesForProtocol,
        "Pattern 3 low intensity": (messages.HapticsControl.doMsg messages.HapticsControl.PATTERN_3 messages.HapticsControl.INTENSITY-LOW).bytesForProtocol,
    },
    "$(messages.BuzzerControl.MT) Buzzer": {
        "20ms 0.5khz": (messages.BuzzerControl.doMsg --duration=20 --frequency=0.5 ).bytesForProtocol,
        "200ms 1khz": (messages.BuzzerControl.doMsg --duration=200 --frequency=1.0 ).bytesForProtocol,
        "2s Ambulance": (messages.BuzzerControl.doMsg --duration=2000 --soundType=messages.BuzzerControl.SOUND_AMBULANCE --intensity=1 ).bytesForProtocol,
    },
    "$(messages.AlarmControl.MT) Alarm": {
        "Duration 0": (messages.AlarmControl.doMsg --duration=0).bytesForProtocol,
        "3s pattern 4 intensity 1": (messages.AlarmControl.doMsg --duration=3 --buzzerPattern=4 --buzzerIntensity=1).bytesForProtocol,
    },
    "1004 LORA": {
      "Transmit": #[0X03, 0X18, 0X00, 0XEC, 0X03, 0X01, 0X00, 0X05, 0X01, 0X04, 0X02, 0X00, 0X02, 0X0A, 0X04, 0X6C, 0X62, 0X6C, 0X62, 0X02, 0X10, 0X27, 0X80, 0X55],
      "Subscribe": #[0X03, 0X0E, 0X00, 0XEC, 0X03, 0X01, 0X00, 0X05, 0X01, 0X03, 0X00, 0X00, 0XC5, 0XD8],
      "Unsubscribe": #[0X03, 0X0E, 0X00, 0XEC, 0X03, 0X01, 0X00, 0X05, 0X01, 0X05, 0X00, 0X00, 0X65, 0X6A],
    },
    // "GSM": {
    //     "SET Normal mode": #[0x03, 0x17, 0x00, 0x31, 0x00, 0x01, 0x00, 0x05, 0x01, 0x01, 0x01, 0x00, 0x01, 0x01, 0x01, 0x75, 0x30],
    //     "SET Airplane mode 10s": #[0x03, 0x23, 0x00, 0x31, 0x00, 0x01, 0x00, 0x05, 0x01, 0x01, 0x02, 0x00, 0x01, 0x02, 0x01, 0x00, 0x04, 0x0A, 0x00, 0x00, 0x00, 0x38, 0x8B],
    //     "GET CFUN": #[0x03, 0x14, 0x00, 0x31, 0x00, 0x01, 0x00, 0x05, 0x01, 0x02, 0x00, 0x00, 0xAD, 0x1E],
    // },
    // "Location": {
    //     "RTK ON": #[0x03, 0x17, 0x00, 0x39, 0x00, 0x01, 0x00, 0x05, 0x01, 0x01, 0x01, 0x00, 0x01, 0x01, 0x01, 0x13, 0x5C],
    //     "RTK OFF": #[0x03, 0x17, 0x00, 0x39, 0x00, 0x01, 0x00, 0x05, 0x01, 0x01, 0x01, 0x00, 0x01, 0x01, 0x02, 0x70, 0x6C],
    // },
}