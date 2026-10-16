// Compatibility for callers using the original LoRa app name.
import .relay show RelayApp

class LoraApp extends RelayApp:
  constructor device parent dog --show-unknown-messages/bool=false:
    super device parent dog --show-unknown-messages=show-unknown-messages
