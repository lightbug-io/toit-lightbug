import ..protocol as protocol

// Auto generated class for protocol message
class LinkControl extends protocol.Data:

  static MT := 50
  static MT_NAME := "LinkControl"

  static IP-ADDRESS := 1
  static PORT := 2
  static ENABLE := 3

  constructor:
    super

  constructor.from-data data/protocol.Data:
    super.from-data data

  // Helper to create a data object for this message type.
  static data --ip-address/string?=null --port/int?=null --enable/bool?=null -> protocol.Data:
    data := protocol.Data
    if ip-address != null: data.add-data-ascii IP-ADDRESS ip-address
    if port != null: data.add-data-uint PORT port
    if enable != null: data.add-data-bool ENABLE enable
    return data

  // GET
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static get-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-GET
    return msg

  // SET
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static set-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SET
    return msg

  // SUBSCRIBE to a message with an optional interval in milliseconds
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static subscribe-msg --ms/int -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SUBSCRIBE
    if ms != null:
      msg.header.data.add-data-uint32 protocol.Header.TYPE-SUBSCRIPTION-INTERVAL ms
    return msg

  // UNSUBSCRIBE
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static unsubscribe-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-UNSUBSCRIBE
    return msg

  // DO
  // Warning: Available methods are not yet specified in the spec, so this message method might not actually work.
  static do-msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    msg := protocol.Message.with-data MT data
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-DO
    return msg

  // Creates a message with no method set
  static msg --data/protocol.Data?=protocol.Data -> protocol.Message:
    return protocol.Message.with-data MT data

  ip-address -> string:
    return get-data-ascii IP-ADDRESS

  port -> int:
    return get-data-uint PORT

  enable -> bool:
    return get-data-bool ENABLE

  stringify -> string:
    return {
      "IP Address": ip-address,
      "Port": port,
      "Enable": enable,
    }.stringify
