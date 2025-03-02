import i2c
import io
import .base
import .i2c
import ..messages

ZCARD-MESSAGES := [
    // TODO fully fill this list
    // TODO provide a base set supported by everything..
    Ack.MT,
    Open.MT,
    Close.MT,
    Heartbeat.MT,
    LastPosition.MT,
    TxNow.MT,
    Status.MT,
    DeviceIds.MT,
    DeviceTime.MT,
    GPSControl.MT,
    BuzzerControl.MT,
    BatteryStatus.MT,
    AlarmControl.MT,
    LinkControl.MT,
    Lora.MT,
    PresetPage.MT,
    TextPage.MT,
    MenuPage.MT,
    DrawBitmap.MT,
    // TODO change button press
]

// The first ZCard devices
// Introduced Feb 2025
class ZCard extends LightbugDevice:
  constructor:
    super "ZCard"
  messages-supported -> List:
    return ZCARD-MESSAGES
  messages-not-supported -> List:
    return [
      Config.MT,
      HapticsControl.MT,
      Temperature.MT, // Needs to be implemented
      Pressure.MT,
    ]