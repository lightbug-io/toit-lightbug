import uart
import gpio

// ESP32-C6 https://docs.espressif.com/projects/esp-at/en/latest/esp32c6/Get_Started/Hardware_connection.html#esp32c6-4mb-series
// UART0 GPIO17 (RX) GPIO16 (TX) Defaults
ESP32C6_UART_RX_PIN := 17
ESP32C6_UART_TX_PIN := 16

ESP32C6UartPort -> uart.Port:
  return uart.Port
    --rx=gpio.Pin ESP32C6_UART_RX_PIN
    --tx=gpio.Pin ESP32C6_UART_TX_PIN
    --baud_rate=115200