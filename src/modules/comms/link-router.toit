import ...protocol as protocol
import ...messages as messages
import .comms show Comms
import .message-handler show MessageHandler

/** One router owns all V3 links in a container. Only the consumed destination
    hop is removed; replies can also use bounded, translated request IDs. */
class LinkRouter:
  p1_ /Comms
  links_ /Map := {:}
  routes_ /Map := {:}
  route-timeout_ /Duration

  constructor --p1/Comms --route-timeout/Duration=(Duration --s=60):
    p1_ = p1
    route-timeout_ = route-timeout
    if p1_.link-id == null: p1_.link-id = protocol.Header.LINK_ID_P1
    add-link p1_

  add-link comms/Comms:
    id := comms.link-id
    if id == null or id == protocol.Header.LINK_ID_ESP32 or id == protocol.Header.LINK_ID_CHASM or id == protocol.Header.LINK_ID_LINK2:
      throw "Invalid router link ID"
    if links_.contains id: throw "Duplicate router link ID: $id"
    links_[id] = comms
    comms.register-router (LinkIngress this comms)

  receive source/Comms msg/protocol.Message -> bool:
    expire_
    routing-fields := (msg.header-get-all-data protocol.Header.TYPE_FORWARDED_FOR) +
        (msg.header-get-all-data protocol.Header.TYPE_FORWARD_TO)
    malformed := routing-fields.any: it.size == 0 or it.size > 8
    if malformed:
      reject_ source msg protocol.Header.STATUS_INVALID_PARAMETER
      return true
    route := null
    if msg.response-to != null:
      route = routes_.get "$(source.link-id):$(msg.response-to)"
    target := null
    consume := false
    if msg.header-has-data protocol.Header.TYPE_FORWARD_TO:
      destination := msg.header-get-data-uint protocol.Header.TYPE_FORWARD_TO
      if destination == protocol.Header.LINK_ID_ESP32:
        msg.header-remove-data protocol.Header.TYPE_FORWARD_TO
        if not msg.header-has-data protocol.Header.TYPE_FORWARD_TO: return false
        destination = msg.header-get-data-uint protocol.Header.TYPE_FORWARD_TO
      if links_.contains destination:
        target = links_[destination]
        consume = true
      else if source != p1_ and (destination == protocol.Header.LINK_ID_CHASM or destination == protocol.Header.LINK_ID_LINK2):
        // P1 must consume the cloud destination itself.
        target = p1_
      else:
        reject_ source msg protocol.Header.STATUS_NOT_SUPPORTED
        return true
    else if route != null:
      target = route[0]
    else:
      return false
    if target == source or (route != null and route[0] != target):
      reject_ source msg protocol.Header.STATUS_INVALID_PARAMETER
      return true

    forwarded := protocol.Message.from-bytes msg.bytes
    if consume: forwarded.header-remove-data protocol.Header.TYPE_FORWARD_TO
    if route != null:
      // A request may receive PROCESSING followed by a result, or repeated
      // subscription responses. Keep its correlation until the idle timeout.
      route[3] = Time.monotonic-us + route-timeout_.in-us
      forwarded.header-remove-data protocol.Header.TYPE_RESPONSE_TO_MESSAGE_ID
      forwarded.header-add-data-uint32 protocol.Header.TYPE_RESPONSE_TO_MESSAGE_ID route[1]
      if not forwarded.header-has-data protocol.Header.TYPE_FORWARD_TO:
        route[2].do: | hop/ByteArray |
          forwarded.header-add-data protocol.Header.TYPE_FORWARD_TO hop
    if msg.msgId != null and msg.response-to == null and msg.type != messages.ACK.MT:
      if routes_.size >= 128:
        reject_ source msg protocol.Header.STATUS_ABANDONED
        return true
      original-id := msg.msgId
      translated-id := target.refresh-message-id forwarded
      if translated-id == 0: translated-id = target.refresh-message-id forwarded
      return-route := msg.header-get-all-data protocol.Header.TYPE_FORWARDED_FOR
      reversed := []
      return-route.size.repeat: reversed.add return-route[return-route.size - 1 - it]
      routes_["$(target.link-id):$translated-id"] = [source, original-id, reversed, Time.monotonic-us + route-timeout_.in-us]
    forwarded.header-add-data-uint8 protocol.Header.TYPE_FORWARDED_FOR source.link-id
    target.send-forwarded forwarded
    return true

  expire_:
    expired := []
    routes_.do: | key value |
      if Time.monotonic-us >= value[3]: expired.add key
    expired.do: routes_.remove it

  reject_ source/Comms msg/protocol.Message status/int:
    if msg.msgId == null or msg.type == messages.ACK.MT: return
    response := messages.ACK.msg --data=null
    response.header-add-data-uint32 protocol.Header.TYPE_RESPONSE_TO_MESSAGE_ID msg.msgId
    response.header-add-data-uint8 protocol.Header.TYPE_MESSAGE_STATUS status
    source.send-forwarded response

class LinkIngress implements MessageHandler:
  router_ /LinkRouter
  source_ /Comms
  constructor .router_ .source_:
  handle-message msg/protocol.Message -> bool:
    return router_.receive source_ msg
