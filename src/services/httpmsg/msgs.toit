import ...messages as messages
import ...util.bitmaps show lightbug-40-40

// TODO these should be defined elsewhere
SCREEN-WIDTH := 250
SCREEN-HEIGHT := 122

// A set of predefined messages that can be shown as buttons on the web page
sample-messages := {
    "Basic": {
        "$(messages.Open.MT) Open": messages.Open.msg.bytes-for-protocol,
        "$(messages.Close.MT) Close": messages.Close.msg.bytes-for-protocol,
        "$(messages.Heartbeat.MT) Heartbeat": messages.Heartbeat.msg.bytes-for-protocol,
    },
    "Getters": {
        "$(messages.LastPosition.MT) Location": (messages.LastPosition.get-msg).bytes-for-protocol,
        "$(messages.Status.MT) Status": (messages.Status.get-msg).bytes-for-protocol,
        "$(messages.DeviceIds.MT) Device IDs": (messages.DeviceIds.get-msg).bytes-for-protocol,
        "$(messages.DeviceTime.MT) Time": (messages.DeviceTime.get-msg).bytes-for-protocol,
        "$(messages.Temperature.MT) Temperature": (messages.Temperature.get-msg).bytes-for-protocol,
        "$(messages.Pressure.MT) Pressure": (messages.Pressure.get-msg).bytes-for-protocol,
        "$(messages.BatteryStatus.MT) Battery": (messages.BatteryStatus.get-msg).bytes-for-protocol,
    },
    "Actions": {
        "$(messages.TxNow.MT) Cellular 'Transmit Now'": (messages.TxNow.do-msg --data="hello".to-byte-array).bytes-for-protocol,
    },
    "Screen": {
        "$(messages.PresetPage.MT) Home page": messages.PresetPage.to-msg.bytes-for-protocol,
        "$(messages.MenuPage.MT) Menu 3 items": (messages.MenuPage.to-msg --page-id=101 --items=["Option 1", "Option 2", "Option 3"]).bytes-for-protocol,
        "$(messages.TextPage.MT) Text page": (messages.TextPage.to-msg --page-id=102 --page-title="Page 101" --line1="First Line" --line2="Second Line").bytes-for-protocol,
        "$(messages.DrawBitmap.MT) Lightbug Logo": (messages.DrawBitmap.to-msg --page-id=103 --bitmap-data=lightbug-40-40 --bitmap-height=40 --bitmap-width=40).bytes-for-protocol,
        "$(messages.DrawBitmap.MT) Overlay Logo": (messages.DrawBitmap.to-msg --bitmap-data=lightbug-40-40 --bitmap-height=40 --bitmap-width=40 --redraw-type=1 --bitmap-x=(SCREEN-WIDTH - 40) --bitmap-y=(SCREEN-HEIGHT - 40)).bytes-for-protocol,
    },
    "$(messages.HapticsControl.MT) Haptics": {
        "Pattern 1 low intensity": (messages.HapticsControl.do-msg messages.HapticsControl.PATTERN_1 messages.HapticsControl.INTENSITY-LOW).bytes-for-protocol,
        "Pattern 2 low intensity": (messages.HapticsControl.do-msg messages.HapticsControl.PATTERN_2 messages.HapticsControl.INTENSITY-LOW).bytes-for-protocol,
        "Pattern 3 low intensity": (messages.HapticsControl.do-msg messages.HapticsControl.PATTERN_3 messages.HapticsControl.INTENSITY-LOW).bytes-for-protocol,
    },
    "$(messages.BuzzerControl.MT) Buzzer": {
        "20ms 0.5khz": (messages.BuzzerControl.do-msg --duration=20 --frequency=0.5 ).bytes-for-protocol,
        "200ms 1khz": (messages.BuzzerControl.do-msg --duration=200 --frequency=1.0 ).bytes-for-protocol,
        "2s Ambulance": (messages.BuzzerControl.do-msg --duration=2000 --soundType=messages.BuzzerControl.SOUND_AMBULANCE --intensity=1 ).bytes-for-protocol,
    },
    "$(messages.BuzzerSequence.MT) Buzzer Sequence": {
        "Starwars": (messages.BuzzerSequence.do-msg [0.440, 0.0, 0.440, 0.0, 0.440, 0.0, 0.349, 0.0, 0.523, 0.0, 0.440, 0.0,  0.349, 0.0, 0.523, 0.0, 0.440, 0.0, 0.659, 0.0, 0.659, 0.0, 0.659, 0.0,  0.698, 0.0, 0.523, 0.0, 0.415, 0.0, 0.349, 0.0, 0.523, 0.0, 0.440] [400, 50, 400, 50, 400, 50, 300, 50, 100, 50, 400, 50,  300, 50, 100, 50, 800, 50, 400, 50, 400, 50, 400, 50,  300, 50, 100, 50, 400, 50, 300, 50, 100, 50, 800]).bytes-for-protocol,
        // "Nokia_Tune": (messages.BuzzerSequence.do-msg [ 1.318, 0.0, 1.174, 0.0, 1.480, 0.0, 1.662, 0.0, 1.108, 0.0, 0.988, 0.0, 1.174, 0.0, 1.318, 0.0, 0.988, 0.0, 0.880, 0.0, 1.108, 0.0, 1.318, 0.0, 0.880 ] [75, 50, 75, 50, 150, 50, 150, 50, 75, 50, 75, 50, 150, 50, 150, 50, 75, 50, 75, 50, 150, 50, 150, 50, 500]).bytes-for-protocol,
    },
    "$(messages.AlarmControl.MT) Alarm": {
        "Duration 0": (messages.AlarmControl.do-msg --duration=0).bytes-for-protocol,
        "3s pattern 4 intensity 1": (messages.AlarmControl.do-msg --duration=3 --buzzer-pattern=4 --buzzer-intensity=1).bytes-for-protocol,
    },
    "$(messages.Lora.MT) LORA, Transmit & Receive for 10s": {
      "Lightbug": (messages.Lora.do-msg --payload="Lightbug".to-byte-array --receive-ms=10000).bytes-for-protocol,
      "MWC": (messages.Lora.do-msg --payload="MWC".to-byte-array --receive-ms=10000).bytes-for-protocol,
      "2025": (messages.Lora.do-msg --payload="2025".to-byte-array --receive-ms=10000).bytes-for-protocol,
      // "Subscribe": (messages.Lora.subscribe-msg).bytes-for-protocol, // Don't have a subscribe button, just ask for subscription on startup
      // "Unsubscribe": (messages.Lora.unsubscribe-msg).bytes-for-protocol,
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