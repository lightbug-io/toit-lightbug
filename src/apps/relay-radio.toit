import ble
import esp32.espnow
import monitor
import ..modules.ble as device-ble
import .relay-wire show RelayWire

// LoRa remains on P1; these two radios run locally on P2.
class RelayRadio:
  static LORA ::= 0
  static ESPNOW ::= 1
  static BLE ::= 2
  static DEFAULT-CHANNEL ::= 6
  static MAX-CHANNEL ::= 11

  mode/int
  channel/int
  advertising_/bool := false
  advertisement-generation_/int := 0
  receive_/Lambda
  failed_/Lambda
  service_/espnow.Service? := null
  adapter_/ble.Adapter? := null
  ble-module_/device-ble.BLE?
  receiver_/Task? := null
  receiver-done_/monitor.Latch := monitor.Latch
  running_/bool := false
  sequence_/int := random 0x10000
  seen_/List := []
  tx-lock_/monitor.Mutex := monitor.Mutex

  constructor .mode --receive/Lambda --failed/Lambda --ble-module/device-ble.BLE?=null --.channel/int=DEFAULT-CHANNEL:
    ble-module_ = ble-module
    receive_ = receive
    failed_ = failed

  static name mode/int -> string:
    if mode == ESPNOW: return "ESP-NOW"
    if mode == BLE: return "BLE"
    return "LoRa"

  start:
    try:
      if mode == ESPNOW:
        // Creating the service fails with ALREADY_IN_USE if Wi-Fi owns the radio.
        // Never disconnect another container's Wi-Fi connection here.
        service_ = espnow.Service --channel=channel
        service_.add-peer espnow.BROADCAST-ADDRESS
      else:
        adapter_ = ble-module_.acquire-relay-radio
        // Initialize both roles before launching the receive task.
        adapter_.central
        adapter_.peripheral
      running_ = true
      receiver_ = task::
        try:
          receive-loop_
        finally:
          critical-do: receiver-done_.set true
    finally:
      if not running_: stop

  stop:
    running_ = false
    advertisement-generation_++
    if receiver_:
      // BLE scans finish naturally so native scan cleanup may yield safely.
      if mode == ESPNOW: receiver_.cancel
      receiver-done_.get
      receiver_ = null
    tx-lock_.do:
      if service_:
        service_.close
        service_ = null
      if adapter_:
        if advertising_:
          adapter_.peripheral.stop-advertise
          advertising_ = false
        ble-module_.release-relay-radio
        adapter_ = null
    seen_ = []

  send text/string:
    tx-lock_.do:
      if not running_: throw "Relay radio stopped"
      if mode == ESPNOW:
        service_.send text --address=espnow.BROADCAST-ADDRESS
      else:
        data := RelayWire.encode text sequence_++
        peripheral := adapter_.peripheral
        advertisement := ble.Advertisement [
          ble.DataBlock.flags --general-discovery,
          ble.DataBlock.manufacturer-specific data,
        ]
        // A new press replaces the current burst immediately, without a send queue.
        advertisement-generation_++
        generation := advertisement-generation_
        if advertising_:
          peripheral.stop-advertise
          advertising_ = false
        peripheral.start-advertise advertisement --interval=(Duration --ms=100)
        advertising_ = true
        task::
          sleep --ms=500
          tx-lock_.do:
            if running_ and generation == advertisement-generation_ and advertising_:
              peripheral.stop-advertise
              advertising_ = false

  receive-loop_:
    e := catch:
      if mode == ESPNOW:
        while running_:
          message := service_.receive
          if running_: receive_.call message.data
      else:
        while running_:
          adapter_.central.scan --duration=(Duration --s=1): |device/ble.RemoteScannedDevice|
            device.data.manufacturer-specific: |company/ByteArray data/ByteArray|
              if running_ and company.size == 2 and company[0] == 0xff and company[1] == 0xff:
                bytes := data
                text := RelayWire.decode bytes
                if text != null and not duplicate_ text (RelayWire.sequence bytes):
                  receive_.call text.to-byte-array
    if e and running_:
      running_ = false
      failed_.call e

  duplicate_ text/string sequence/int -> bool:
    now := Time.monotonic-us
    key := "$((text.split ":")[0]):$sequence"
    seen_.do: |entry|
      if entry[0] == key and now - entry[1] < 10_000_000: return true
    if seen_.size >= 64: seen_.remove --at=0
    seen_.add [key, now]
    return false
