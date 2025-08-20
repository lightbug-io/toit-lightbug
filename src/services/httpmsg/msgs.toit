import ...messages as messages
import ...protocol as protocol
import ...util.bitmaps show lightbug-40-40

// TODO these should be defined elsewhere
SCREEN-WIDTH := 250
SCREEN-HEIGHT := 122

// Helper function to create LORA data with payload and receive time
create-lora-data payload/string -> protocol.Data:
  data := protocol.Data
  data.add-data-ascii messages.LORA.PAYLOAD payload
  data.add-data-uint32 messages.LORA.RECEIVE-MS 10000
  return data

// Helper function to create CPU2Sleep data
create-cpu2sleep-data interval/int wake-on-event/bool -> protocol.Data:
  data := protocol.Data
  data.add-data-uint32 messages.CPU2Sleep.INTERVAL interval
  data.add-data-uint8 messages.CPU2Sleep.WAKE-ON-EVENT (wake-on-event ? 1 : 0)
  return data

// Helper function to create TransmitNow data
create-transmit-now-data payload/ByteArray -> protocol.Data:
  data := protocol.Data
  data.add-data messages.TransmitNow.PAYLOAD payload
  return data

// Helper function to create GPSControl data
create-gps-control-data rtk-enable-correction/int -> protocol.Data:
  data := protocol.Data
  data.add-data-uint8 messages.GPSControl.CORRECTIONS-ENABLED rtk-enable-correction
  return data

// Helper function to create MenuPage data
create-menu-page-data page-id/int items/List -> protocol.Data:
  data := protocol.Data
  data.add-data-uint8 messages.MenuPage.PAGE-ID page-id
  data.add-data-uint 30 items.size
  data.add-data-uint 6 0 //redraw type
  items.size.repeat: | i |
    // MenuPage has LINE-1, LINE-2, LINE-3, etc. starting from constant 100
    line-constant := 100 + i
    data.add-data-string line-constant items[i]
  return data

// Helper function to create TextPage data
create-text-page-data page-id/int page-title/string line1/string line2/string -> protocol.Data:
  data := protocol.Data
  data.add-data-uint messages.TextPage.PAGE-ID page-id
  data.add-data-string messages.TextPage.PAGE-TITLE page-title
  data.add-data-string messages.TextPage.LINE-1 line1
  data.add-data-string messages.TextPage.LINE-2 line2
  return data

// Helper function to create DrawBitmap data
create-draw-bitmap-data page-id/int bitmap-data/ByteArray bitmap-height/int bitmap-width/int x/int=0 y/int=0 redraw-type/int=0 -> protocol.Data:
  data := protocol.Data
  data.add-data-uint messages.DrawBitmap.PAGE-ID page-id
  data.add-data-uint messages.DrawBitmap.REDRAW-TYPE redraw-type
  data.add-data-uint messages.DrawBitmap.X x
  data.add-data-uint messages.DrawBitmap.Y y
  data.add-data-uint messages.DrawBitmap.WIDTH bitmap-width
  data.add-data-uint messages.DrawBitmap.HEIGHT bitmap-height
  data.add-data messages.DrawBitmap.BITMAP bitmap-data
  return data

// Helper function to create HapticsControl data
create-haptics-control-data pattern/int intensity/int -> protocol.Data:
  data := protocol.Data
  data.add-data-uint8 messages.HapticsControl.PATTERN pattern
  data.add-data-uint8 messages.HapticsControl.INTENSITY intensity
  return data

// Helper function to create BuzzerControl data
create-buzzer-control-data duration/int frequency/float?=null sound-type/int?=null intensity/int?=null -> protocol.Data:
  data := protocol.Data
  data.add-data-uint16 messages.BuzzerControl.DURATION duration
  if frequency != null:
    data.add-data-float32 messages.BuzzerControl.FREQUENCY frequency
  if sound-type != null:
    data.add-data-uint8 messages.BuzzerControl.SOUND-TYPE sound-type
  if intensity != null:
    data.add-data-uint8 messages.BuzzerControl.INTENSITY intensity
  return data

// Helper function to create BuzzerSequence data
create-buzzer-sequence-data frequencies/List durations/List -> protocol.Data:
  data := protocol.Data
  data.add-data-list-float32 messages.BuzzerSequence.FREQUENCIES frequencies
  data.add-data-list-uint16 messages.BuzzerSequence.TIMINGS durations
  return data

// Helper function to create Alarm data
create-alarm-data duration/int buzzer-pattern/int?=null buzzer-intensity/int?=null -> protocol.Data:
  data := protocol.Data
  data.add-data-uint32 messages.Alarm.DURATION duration
  if buzzer-pattern != null:
    data.add-data-uint8 messages.Alarm.BUZZER-PATTERN buzzer-pattern
  if buzzer-intensity != null:
    data.add-data-uint8 messages.Alarm.BUZZER-INTENSITY buzzer-intensity
  return data

// A set of predefined messages that can be shown as buttons on the web page
sample-messages := {
    "Basic": {
        "$(messages.Open.MT) Open": messages.Open.msg.bytes-for-protocol,
        "$(messages.Close.MT) Close": messages.Close.msg.bytes-for-protocol,
        "$(messages.Heartbeat.MT) Heartbeat": messages.Heartbeat.msg.bytes-for-protocol,
        "$(messages.CPU1Reset.MT) CPU1 Reset": (messages.CPU1Reset.do-msg).bytes-for-protocol,
        "$(messages.CPU2Sleep.MT) CPU2 Sleep": (messages.CPU2Sleep.do-msg --base-data=(create-cpu2sleep-data 1 false)).bytes-for-protocol,
    },
    "Getters": {
        "$(messages.DeviceStatus.MT) Status": messages.DeviceStatus.get-msg.bytes-for-protocol,
        "$(messages.DeviceIDs.MT) Device IDs": messages.DeviceIDs.get-msg.bytes-for-protocol,
        "$(messages.DeviceTime.MT) Time": messages.DeviceTime.get-msg.bytes-for-protocol,
        "$(messages.Temperature.MT) Temperature": messages.Temperature.get-msg.bytes-for-protocol,
        "$(messages.Pressure.MT) Pressure": messages.Pressure.get-msg.bytes-for-protocol,
        "$(messages.BatteryStatus.MT) Battery": messages.BatteryStatus.get-msg.bytes-for-protocol,
    },
    "Actions": {
        "$(messages.TransmitNow.MT) Cellular 'Transmit Now'": (messages.TransmitNow.do-msg --base-data=(create-transmit-now-data "hello".to-byte-array)).bytes-for-protocol,
    },
    "Position": {
      "$(messages.GPSControl.MT) RTK Enable (if supported)": (messages.GPSControl.set-msg --corrections-enabled=messages.GPSControl.CORRECTIONS-ENABLED_FULL-RTCM-STREAM).bytes-for-protocol,
      "$(messages.GPSControl.MT) RTK Disable (if supported)": (messages.GPSControl.set-msg --corrections-enabled=messages.GPSControl.CORRECTIONS-ENABLED_DISABLED).bytes-for-protocol,
      "$(messages.Position.MT) Last Position": (messages.Position.get-msg).bytes-for-protocol,
    },
    "Screen": {
        "$(messages.PresetPage.MT) Home page": messages.PresetPage.msg.bytes-for-protocol,
        "$(messages.MenuPage.MT) Menu 3 items": (messages.MenuPage.msg --data=(create-menu-page-data 101 ["Option 1", "Option 2", "Option 3"])).bytes-for-protocol,
        "$(messages.TextPage.MT) Text page": (messages.TextPage.msg --data=(create-text-page-data 102 "Page 101" "First Line" "Second Line")).bytes-for-protocol,
        "$(messages.DrawBitmap.MT) Lightbug Logo": (messages.DrawBitmap.msg --data=(create-draw-bitmap-data 103 lightbug-40-40 40 40 0 0 0)).bytes-for-protocol,
    },
    "$(messages.HapticsControl.MT) Haptics": {
        "Pattern 1 low intensity": (messages.HapticsControl.msg --data=(create-haptics-control-data 1 1)).bytes-for-protocol,
        "Pattern 2 low intensity": (messages.HapticsControl.msg --data=(create-haptics-control-data 2 1)).bytes-for-protocol,
        "Pattern 3 low intensity": (messages.HapticsControl.msg --data=(create-haptics-control-data 3 1)).bytes-for-protocol,
    },
    "$(messages.BuzzerControl.MT) Buzzer": {
        "20ms 0.5khz": (messages.BuzzerControl.msg --data=(create-buzzer-control-data 20 0.5)).bytes-for-protocol,
        "200ms 1khz": (messages.BuzzerControl.msg --data=(create-buzzer-control-data 200 1.0)).bytes-for-protocol,
        "2s Ambulance": (messages.BuzzerControl.msg --data=(create-buzzer-control-data 2000 null 1 1)).bytes-for-protocol,
    },
    "$(messages.BuzzerSequence.MT) Buzzer Sequence": {
        "Starwars": (messages.BuzzerSequence.msg --data=(create-buzzer-sequence-data [0.440, 0.0, 0.440, 0.0, 0.440, 0.0, 0.349, 0.0, 0.523, 0.0, 0.440, 0.0,  0.349, 0.0, 0.523, 0.0, 0.440, 0.0, 0.659, 0.0, 0.659, 0.0, 0.659, 0.0,  0.698, 0.0, 0.523, 0.0, 0.415, 0.0, 0.349, 0.0, 0.523, 0.0, 0.440] [400, 50, 400, 50, 400, 50, 300, 50, 100, 50, 400, 50,  300, 50, 100, 50, 800, 50, 400, 50, 400, 50, 400, 50,  300, 50, 100, 50, 400, 50, 300, 50, 100, 50, 800])).bytes-for-protocol,
        // "Nokia_Tune": (messages.BuzzerSequence.do-msg [ 1.318, 0.0, 1.174, 0.0, 1.480, 0.0, 1.662, 0.0, 1.108, 0.0, 0.988, 0.0, 1.174, 0.0, 1.318, 0.0, 0.988, 0.0, 0.880, 0.0, 1.108, 0.0, 1.318, 0.0, 0.880 ] [75, 50, 75, 50, 150, 50, 150, 50, 75, 50, 75, 50, 150, 50, 150, 50, 75, 50, 75, 50, 150, 50, 150, 50, 500]).bytes-for-protocol,
    },
    "$(messages.Alarm.MT) Alarm": {
        "Duration 0": (messages.Alarm.msg --data=(create-alarm-data 0)).bytes-for-protocol,
        "3s pattern 4 intensity 1": (messages.Alarm.msg --data=(create-alarm-data 3000 4 1)).bytes-for-protocol,
    },
    "$(messages.LORA.MT) LORA, Transmit & Receive for 10s": {
      "Lightbug": (messages.LORA.do-msg --base-data=(create-lora-data "Lightbug")).bytes-for-protocol,
      "Demo": (messages.LORA.do-msg --base-data=(create-lora-data "Demo")).bytes-for-protocol,
      "2025": (messages.LORA.do-msg --base-data=(create-lora-data "2025")).bytes-for-protocol,
      // "Subscribe": (messages.LORA.subscribe-msg).bytes-for-protocol, // Don't have a subscribe button, just ask for subscription on startup
      // "Unsubscribe": (messages.LORA.unsubscribe-msg).bytes-for-protocol,
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