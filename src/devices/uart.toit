import uart
import gpio

// ESP32-C6 https://docs.espressif.com/projects/esp-at/en/latest/esp32c6/Get_Started/Hardware_connection.html#esp32c6-4mb-series
// UART0 GPIO17 (RX) GPIO16 (TX) Defaults
ESP32C6-UART-RX-PIN := 17
ESP32C6-UART-TX-PIN := 16

ESP32C6UartPort -> uart.Port:
  return uart.Port
    --rx=gpio.Pin ESP32C6-UART-RX-PIN
    --tx=gpio.Pin ESP32C6-UART-TX-PIN
    --baud_rate=115200