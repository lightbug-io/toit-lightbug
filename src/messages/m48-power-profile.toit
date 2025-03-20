import ..protocol as protocol

class PowerProfile extends protocol.Data:
  static MT := 48
  static TOTAL-POWER := 3
  static CURRENT-NOW := 4

  static subscribe-msg --interval/int=300 -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-SUBSCRIBE
    msg.header.data.add-data-uint32 protocol.Header.TYPE_SUBSCRIPTION_INTERVAL interval
    return msg

  static unsubscribe-msg -> protocol.Message:
    msg := protocol.Message MT
    msg.header.data.add-data-uint8 protocol.Header.TYPE-MESSAGE-METHOD protocol.Header.METHOD-UNSUBSCRIBE
    return msg

  constructor.from-data data/protocol.Data:
    super.from-data data

  total-power -> float:
    return get-data-float32 TOTAL-POWER

  current-now -> float:
    return get-data-float32 CURRENT-NOW

  stringify -> string:
    return {
      "Total Power": total-power,
      "Current Now": current-now,
    }.stringify
