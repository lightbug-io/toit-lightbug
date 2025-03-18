import ...messages as messages
import ...util.bitmaps show lightbug4040

// TODO these should be defined elsewhere
SCREEN_WIDTH := 250
SCREEN_HEIGHT := 122

// A set of predefined messages that can be shown as buttons on the web page
sample-messages := {
    "Getters": {
        "$(messages.LastPosition.MT) Location": (messages.LastPosition.getMsg).bytes-for-protocol,
        "$(messages.Status.MT) Status": (messages.Status.getMsg).bytes-for-protocol,
        "$(messages.DeviceIds.MT) Device IDs": (messages.DeviceIds.getMsg).bytes-for-protocol,
        "$(messages.DeviceTime.MT) Time": (messages.DeviceTime.getMsg).bytes-for-protocol,
        "$(messages.Temperature.MT) Temperature": (messages.Temperature.getMsg).bytes-for-protocol,
        "$(messages.Pressure.MT) Pressure": (messages.Pressure.getMsg).bytes-for-protocol,
        "$(messages.BatteryStatus.MT) Battery": (messages.BatteryStatus.getMsg).bytes-for-protocol,
    },
    "Actions": {
        "$(messages.TxNow.MT) Cellular 'Transmit Now'": (messages.TxNow.doMsg --data="hello".to-byte-array).bytes-for-protocol,
    },
    "Screen": {
        "$(messages.PresetPage.MT) Home page": messages.PresetPage.toMsg.bytes-for-protocol,
        "$(messages.MenuPage.MT) Menu 3 items": (messages.MenuPage.toMsg --pageId=101 --items=["Option 1", "Option 2", "Option 3"]).bytes-for-protocol,
        "$(messages.TextPage.MT) Text page": (messages.TextPage.toMsg --pageId=102 --pageTitle="Page 101" --line1="First Line" --line2="Second Line").bytes-for-protocol,
        "$(messages.DrawBitmap.MT) Lightbug Logo": (messages.DrawBitmap.toMsg --pageId=103 --bitmapData=lightbug4040 --bitmapHeight=40 --bitmapWidth=40).bytes-for-protocol,
        // TODO this should be able to overlay a logo on a page (whatever page is being displayed) if not pageid is set
        // "$(messages.DrawBitmap.MT) Overlay Logo": (messages.DrawBitmap.toMsg --bitmapData=lightbug4040 --bitmapHeight=40 --bitmapWidth=40 --bitmapOverlay=true --bitmapX=(SCREEN_WIDTH - 40) --bitmapY=(SCREEN_HEIGHT - 40)).bytes-for-protocol,
    },
    "$(messages.HapticsControl.MT) Haptics": {
        "Pattern 1 low intensity": (messages.HapticsControl.doMsg messages.HapticsControl.PATTERN_1 messages.HapticsControl.INTENSITY-LOW).bytes-for-protocol,
        "Pattern 2 low intensity": (messages.HapticsControl.doMsg messages.HapticsControl.PATTERN_2 messages.HapticsControl.INTENSITY-LOW).bytes-for-protocol,
        "Pattern 3 low intensity": (messages.HapticsControl.doMsg messages.HapticsControl.PATTERN_3 messages.HapticsControl.INTENSITY-LOW).bytes-for-protocol,
    },
    "$(messages.BuzzerControl.MT) Buzzer": {
        "20ms 0.5khz": (messages.BuzzerControl.doMsg --duration=20 --frequency=0.5 ).bytes-for-protocol,
        "200ms 1khz": (messages.BuzzerControl.doMsg --duration=200 --frequency=1.0 ).bytes-for-protocol,
        "2s Ambulance": (messages.BuzzerControl.doMsg --duration=2000 --soundType=messages.BuzzerControl.SOUND_AMBULANCE --intensity=1 ).bytes-for-protocol,
    },
    "$(messages.BuzzerSequence.MT) Buzzer Sequence": {
        "Starwars": (messages.BuzzerSequence.doMsg [0.440, 0.0, 0.440, 0.0, 0.440, 0.0, 0.349, 0.0, 0.523, 0.0, 0.440, 0.0,  0.349, 0.0, 0.523, 0.0, 0.440, 0.0, 0.659, 0.0, 0.659, 0.0, 0.659, 0.0,  0.698, 0.0, 0.523, 0.0, 0.415, 0.0, 0.349, 0.0, 0.523, 0.0, 0.440] [400, 50, 400, 50, 400, 50, 300, 50, 100, 50, 400, 50,  300, 50, 100, 50, 800, 50, 400, 50, 400, 50, 400, 50,  300, 50, 100, 50, 400, 50, 300, 50, 100, 50, 800]).bytes-for-protocol,
        // "Nokia_Tune": (messages.BuzzerSequence.doMsg [ 1.318, 0.0, 1.174, 0.0, 1.480, 0.0, 1.662, 0.0, 1.108, 0.0, 0.988, 0.0, 1.174, 0.0, 1.318, 0.0, 0.988, 0.0, 0.880, 0.0, 1.108, 0.0, 1.318, 0.0, 0.880 ] [75, 50, 75, 50, 150, 50, 150, 50, 75, 50, 75, 50, 150, 50, 150, 50, 75, 50, 75, 50, 150, 50, 150, 50, 500]).bytes-for-protocol,
    },
    "$(messages.AlarmControl.MT) Alarm": {
        "Duration 0": (messages.AlarmControl.doMsg --duration=0).bytes-for-protocol,
        "3s pattern 4 intensity 1": (messages.AlarmControl.doMsg --duration=3 --buzzerPattern=4 --buzzerIntensity=1).bytes-for-protocol,
    },
    "$(messages.Lora.MT) LORA, Transmit & Receive for 10s": {
      "Lightbug": (messages.Lora.doMsg --payload="Lightbug".to-byte-array --receiveMs=10000).bytes-for-protocol,
      "MWC": (messages.Lora.doMsg --payload="MWC".to-byte-array --receiveMs=10000).bytes-for-protocol,
      "2025": (messages.Lora.doMsg --payload="2025".to-byte-array --receiveMs=10000).bytes-for-protocol,
      // "Subscribe": (messages.Lora.subscribeMsg).bytes-for-protocol, // Don't have a subscribe button, just ask for subscription on startup
      // "Unsubscribe": (messages.Lora.unsubscribeMsg).bytes-for-protocol,
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