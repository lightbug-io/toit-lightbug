import net
import net.tcp
import io
import log
import .base
import ..modules.strobe
import ..modules.comms
import ..modules.buttons
import ..modules.ble
import ..modules.wifi
import ..modules.piezo show Piezo
import ..modules.haptics show Haptics
import ..modules.gnss show GNSS
import ..modules.eink show Eink
import ..modules.lora show LoraRadio

/**
Development-only transport that talks to a device through a local
`squish chasm proxy --device <ID>` process instead of a physical link.

The proxy forwards raw V3 protocol bytes to/from a single device over the
authenticated Chasm cloud API, so this is useful when the device isn't
reachable over local WiFi/BLE but still has its own internet connection.

Start the proxy once per device before running Toit code against it:
  squish chasm proxy --device <ID>
*/
class Proxy implements Device:
  static DEFAULT-PORT ::= 48000

  socket_/tcp.Socket
  comms_/Comms? := null
  buttons_/Buttons? := null
  ble_/BLE? := null
  wifi_/WiFi? := null
  piezo_/Piezo? := null
  haptics_/Haptics? := null
  gnss_/GNSS? := null
  lora_/LoraRadio? := null
  eink_/Eink? := null
  open_/bool

  constructor --host/string="127.0.0.1" --port/int=DEFAULT-PORT --open/bool=true:
    open_ = open
    network := net.open
    socket_ = network.tcp-connect host port

  name -> string:
    return "Proxy"
  strobe -> Strobe:
    return NoStrobe
  comms -> Comms:
    if not comms_:
      comms_ = Comms --device=this --open=open_
    return comms_
  buttons -> Buttons:
    if not buttons_:
      buttons_ = Buttons comms
    return buttons_
  ble -> BLE:
    if not ble_:
      ble_ = BLE --logger=(log.default.with-name "lb.ble")
    return ble_
  wifi -> WiFi:
    if not wifi_:
      wifi_ = WiFi --logger=(log.default.with-name "lb.wifi")
    return wifi_
  piezo -> Piezo:
    if not piezo_:
      piezo_ = Piezo --device=this --logger=(log.default.with-name "lb.piezo")
    return piezo_
  haptics -> Haptics:
    if not haptics_:
      haptics_ = Haptics --device=this --logger=(log.default.with-name "lb.haptics")
    return haptics_
  gnss -> GNSS:
    if not gnss_:
      gnss_ = GNSS --device=this --logger=(log.default.with-name "lb.gnss")
    return gnss_
  lora -> LoraRadio:
    if not lora_:
      lora_ = LoraRadio --device=this --logger=(log.default.with-name "lb.lora")
    return lora_
  eink -> Eink:
    if not eink_:
      eink_ = Eink --device=this --logger=(log.default.with-name "eink")
    return eink_
  // Each write is one complete V3 message over a discrete link (like I2C),
  // not a noisy continuous stream, so no "LB" sync marker is needed.
  prefix -> bool:
    return false
  // The proxy's TCP link is opened eagerly in the constructor.
  connected -> bool:
    return true
  connect -> none:
  disconnect -> none:
    socket_.close
  in -> io.Reader:
    return socket_.in
  out -> io.Writer:
    return socket_.out
