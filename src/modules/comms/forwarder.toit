import log
import ...protocol as protocol
import .comms show Comms
import .message-handler show MessageHandler

/**
Routes V3 messages between the USB host link and P1.
*/
class P1UsbForwarder:
  static P1-LINK-ID ::= protocol.Header.LINK_ID_P1
  static USB-HOST-LINK-ID ::= protocol.Header.LINK_ID_USB_HOST

  usb_ /Comms
  p1_ /Comms
  p1-link-id_ /int
  usb-link-id_ /int
  routes_ /Map := {:}
  logger_ /log.Logger

  constructor
      --usb/Comms
      --p1/Comms
      --p1-link-id/int=P1-LINK-ID
      --usb-link-id/int=USB-HOST-LINK-ID
      --logger/log.Logger=(log.default.with-name "p1-usb-forwarder"):
    usb_ = usb
    p1_ = p1
    p1-link-id_ = p1-link-id
    usb-link-id_ = usb-link-id
    logger_ = logger
    usb_.register-handler (UsbIngressHandler this)
    p1_.register-handler (P1IngressHandler this)

  forward-from-usb_ msg/protocol.Message -> bool:
    if not msg.header-has-data protocol.Header.TYPE_FORWARD_TO:
      return false
    destination := msg.header-get-data-uint protocol.Header.TYPE_FORWARD_TO
    if destination == p1-link-id_:
      forward-directly-to-p1_ msg
      return true
    if destination == protocol.Header.LINK_ID_CHASM:
      forward-to-chasm-via-p1_ msg
      return true
    return false

  forward-directly-to-p1_ msg/protocol.Message -> none:
    forwarded := protocol.Message.from-message msg
    mark-forwarded_ forwarded usb-link-id_
    remember-usb-route_ forwarded
    logger_.info "Forwarding V3 message $(forwarded.type) USB -> P1 id=$(forwarded.msgId) bytes=$(forwarded.bytes)"
    p1_.send forwarded --now=true

  forward-to-chasm-via-p1_ msg/protocol.Message -> none:
    // P1 consumes Forward To = Chasm and sends the frame on its cloud link.
    forwarded := protocol.Message.from-message msg
    forwarded.header-remove-data protocol.Header.TYPE_FORWARDED_FOR
    forwarded.header-add-data-uint8 protocol.Header.TYPE_FORWARDED_FOR usb-link-id_
    remember-usb-route_ forwarded
    logger_.info "Forwarding V3 message $(forwarded.type) USB -> P1 -> Chasm id=$(forwarded.msgId) bytes=$(forwarded.bytes)"
    p1_.send forwarded --now=true

  remember-usb-route_ msg/protocol.Message -> none:
    if msg.msgId == null:
      return
    routes_[msg.msgId] = usb-link-id_

  forward-from-p1_ msg/protocol.Message -> bool:
    if msg.response-to != null:
      logger_.info "P1 reply type=$(msg.type) response-to=$(msg.response-to) bytes=$(msg.bytes)"
    destination := null
    if msg.header-has-data protocol.Header.TYPE_FORWARD_TO:
      destination = msg.header-get-data-uint protocol.Header.TYPE_FORWARD_TO
      // Leave P2-targeted messages for P2's local handlers.
      if destination == protocol.Header.LINK_ID_ESP32:
        return false
    else if msg.response-to != null and routes_.contains msg.response-to:
      destination = routes_[msg.response-to]
      routes_.remove msg.response-to

    if destination != usb-link-id_:
      return false

    forwarded := protocol.Message.from-message msg
    mark-forwarded_ forwarded p1-link-id_
    // Preserve P1's response-to ID when returning the frame to USB.
    wire := forwarded.bytes
    wire-length := wire[1] + (wire[2] << 8)
    wire-checksum := wire[wire.size - 2] + (wire[wire.size - 1] << 8)
    logger_.info "Forwarding V3 message $(forwarded.type) P1 -> USB size=$(wire.size) encoded-length=$wire-length checksum=$(forwarded.checksum-calc)/$wire-checksum"
    usb_.send-raw-bytes wire
    return true

  mark-forwarded_ msg/protocol.Message source-link-id/int:
    msg.header-remove-data protocol.Header.TYPE_FORWARD_TO
    msg.header-remove-data protocol.Header.TYPE_FORWARDED_FOR
    msg.header-add-data-uint8 protocol.Header.TYPE_FORWARDED_FOR source-link-id

class UsbIngressHandler implements MessageHandler:
  forwarder_ /P1UsbForwarder

  constructor forwarder/P1UsbForwarder:
    forwarder_ = forwarder

  handle-message msg/protocol.Message -> bool:
    return forwarder_.forward-from-usb_ msg

class P1IngressHandler implements MessageHandler:
  forwarder_ /P1UsbForwarder

  constructor forwarder/P1UsbForwarder:
    forwarder_ = forwarder

  handle-message msg/protocol.Message -> bool:
    return forwarder_.forward-from-p1_ msg
