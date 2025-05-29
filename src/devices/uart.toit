import uart
import gpio
import io
import .base
import .strobe

// ESP32-C6 https://docs.espressif.com/projects/esp-at/en/latest/esp32c6/Get_Started/Hardware_connection.html#esp32c6-4mb-series
// UART0 GPIO17 (RX) GPIO16 (TX) Defaults
ESP32C6-UART-RX-PIN := 17
ESP32C6-UART-TX-PIN := 16

ESP32C6UartPort -> uart.Port:
  return uart.Port
    --rx=gpio.Pin ESP32C6-UART-RX-PIN
    --tx=gpio.Pin ESP32C6-UART-TX-PIN
    --baud_rate=115200

// TODO GenericUart devices may want to have the LB prefix set for messages...

class GenericUart implements Device:
  _port/ uart.Port

  constructor --port/uart.Port:
    _port = port

  name -> string:
    return "Uart"
  strobe -> Strobe:
    return NoStrobe
  messages-supported -> List:
    return []
  messages-not-supported -> List:
    return []
  // XXX: Does reinit really make sense for a generic UART device? Possibly not?
  reinit -> bool:
    return true
  prefix -> bool:
    return true
  in -> io.Reader:
    return _port.in
  out -> io.Writer:
    return _port.out
