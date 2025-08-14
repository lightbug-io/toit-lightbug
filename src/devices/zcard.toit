import i2c
import io
import .base
import .i2c
import .strobe
import ..messages

ZCARD-MESSAGES := [
    // TODO fully fill this list
    // TODO provide a base set supported by everything..
    ACK.MT,
    Open.MT,
    Close.MT,
    Heartbeat.MT,
    Position.MT,
    TransmitNow.MT,
    DeviceStatus.MT,
    DeviceIDs.MT,
    DeviceTime.MT,
    GPSControl.MT,
    BuzzerControl.MT,
    BatteryStatus.MT,
    Alarm.MT,
    LinkControl.MT,
    LORA.MT,
    PresetPage.MT,
    TextPage.MT,
    MenuPage.MT,
    DrawBitmap.MT,
    // TODO change button press
]

// The latest revision of the ZCard device
class ZCard extends ZCardRev2:

// The second of the ZCard devices
// Introduced Mid 2025
class ZCardRev2 extends LightbugDevice:
  constructor:
    super "ZCard" --strobe=(StandardStrobe --initial-value=1)
  messages-supported -> List:
    return ZCARD-MESSAGES
  messages-not-supported -> List:
    return [
      Config.MT,
      HapticsControl.MT,
      Temperature.MT, // Needs to be implemented
      Pressure.MT,
    ]

// The first ZCard devices
// Introduced Feb 2025
class ZCardRev1 extends LightbugDevice:
  constructor:
    super "ZCard" --strobe=(StandardStrobe --initial-value=1)
  messages-supported -> List:
    return ZCARD-MESSAGES
  messages-not-supported -> List:
    return [
      Config.MT,
      HapticsControl.MT,
      Temperature.MT, // Needs to be implemented
      Pressure.MT,
    ]