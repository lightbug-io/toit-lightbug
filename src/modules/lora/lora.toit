import ...messages as messages
import ...protocol as protocol
import ...devices as devices
import log

class LoraRadio:
  static RX-INDEFINITE ::= 0

  logger_/log.Logger
  device_/devices.Device?

  constructor --device/devices.Device?=null --logger/log.Logger=(log.default.with-name "lb-lora"):
    device_ = device
    logger_ = logger

  available -> bool:
    return device_ != null

  data --payload/string?=null --payload-bytes/ByteArray?=null --config-slot/int?=null -> protocol.Data:
    if payload-bytes == null and payload != null:
      payload-bytes = payload.to-byte-array
    return messages.LoRa.data --payload=payload-bytes --config-slot=config-slot

  msg --payload/string?=null --payload-bytes/ByteArray?=null --config-slot/int?=null -> protocol.Message:
    return messages.LoRa.msg --data=(data --payload=payload --payload-bytes=payload-bytes --config-slot=config-slot)

  send-payload payload/string --now/bool=true --config-slot/int?=null:
    device_.comms.send (msg --payload=payload --config-slot=config-slot) --now=now

  send-payload payload/string --await --timeout/Duration=(Duration --s=5) --config-slot/int?=null -> protocol.Message?:
    return device_.comms.send-new (msg --payload=payload --config-slot=config-slot) --timeout=timeout

  subscribe --duration/int?=RX-INDEFINITE --timeout/int?=null:
    device_.comms.send (messages.LoRa.subscribe-msg --duration=duration --timeout=timeout) --now=true

  unsubscribe:
    device_.comms.send messages.LoRa.unsubscribe-msg --now=true

  stringify -> string:
    return "LoRa radio"
