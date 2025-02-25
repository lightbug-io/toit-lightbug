import uart
import gpio

// ESP32-C6 https://docs.espressif.com/projects/esp-at/en/latest/esp32c6/Get_Started/Hardware_connection.html#esp32c6-4mb-series
// UART0 GPIO17 (RX) GPIO16 (TX) Defaults
// Toit typically doesn't "force" users to the defaults. The esp gpio
// matrix is pretty good. Usually you don't care for the default pins.
ESP32C6-UART-RX-PIN := 17
ESP32C6-UART-TX-PIN := 16

// As for the i2c device, the pins are never closed.
esp32c6-uart-port -> uart.Port:
  return uart.Port
    --rx=gpio.Pin ESP32C6-UART-RX-PIN
    --tx=gpio.Pin ESP32C6-UART-TX-PIN
    --baud-rate=115200
