import ..modules.comms.message-handler show MessageHandler
import ..protocol as protocol
import ..messages show ButtonPress

/** The example records button deliveries before Comms sends its ACK.
    Store may be an RTC RAM bucket on hardware or a Map in host tests. */
class VendingButtons implements MessageHandler:
  store_ /any
  count /int := 0
  last-button-id /int? := null
  last-duration-ms /int? := null

  constructor store:
    store_ = store

  handle-message msg/protocol.Message -> bool:
    if msg.type != ButtonPress.MT: return false
    sequence := (msg.data.has-data 5) ? (msg.data.get-data-uint 5) : msg.msgId
    previous := store_.get "last-button-sequence" --if-absent=(: null)
    if sequence != null and sequence == previous: return false
    count++
    last-button-id = msg.data.get-data-uint ButtonPress.BUTTON-ID
    last-duration-ms = msg.data.get-data-uint ButtonPress.DURATION
    if sequence != null: store_["last-button-sequence"] = sequence
    // Synchronous dispatch: returning false permits the generic ACK only
    // after the example has accepted/persisted its deduplication state.
    return false
