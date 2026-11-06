# Relay location upload v1

The Relay menu has **Cloud upload: Off / L1 / L2**. It starts **Off** and
returns to Off when exiting the app. Selection is not persisted. LoRa, Ping
send mode and Continual Off defaults are unchanged.

This is a best-effort bridge to the already-configured P1 cloud link:

- L1 uses the existing `ForwardTo=0` (Chasm) route.
- L2 uses the existing `ForwardTo=2` (Link2) route.
- No endpoint, credentials, encryption configuration or link failover policy
  is changed. P1's existing L2 fallback via L1 still applies.

## Accepted input and identity

Only the existing radio text `uint32-device-id:latitude,longitude` is accepted.
Coordinates must be finite and inside latitude ±90 / longitude ±180. The
existing 64-byte RF maximum is unchanged. LoRa and ESP-NOW supply text directly;
BLE's existing compact-location decoder supplies the same text to this path.

Unknown local identity, local-ID echoes, IDs outside uint32, malformed input,
pings, pongs, acknowledgments, commands, sessions, unknown packets and all binary
V3/encrypted packets are not uploaded. This version does **not** forward even a
decoded binary V3 Position. Local P1 Position subscriptions are for the UI and
outbound radio operation only, not cloud uploads. Cloud responses are not
rebroadcast over radio.

The app reconstructs an ordinary V3 Position (MT15), with latitude and longitude
encoded as signed int32 degrees × 10^7. It does not copy an inbound V3 envelope.
P2 sends `ForwardedFor=<remote device ID>` and the selected `ForwardTo`, without
ClientID. Comms assigns a fresh relay message ID. P1 supplies the relay ClientID
and appends its local ESP32 hop, giving ordered `ForwardedFor=[remote, 1]`.
The cloud companion returns `ForwardTo=[1, remote]` on an ACK. P1 consumes `1`;
P2 can match its own outstanding upload by ResponseTo. No radio ACK is required.

There are no incoming session, method, control, application-publish or storage
headers to inherit. The original numeric source ID is only an assertion in the
existing unauthenticated radio format, not proof of source authenticity.

### Unknown metadata stays unknown

Text locations have **no GPS fix timestamp, fix type, source, accuracy or
altitude**. Those data fields remain absent. Receive time must not be mistaken
for fix time, and a coordinate must not be described as RTK or a high-quality
fix without evidence. Use the ordinary transport receive-time metadata for
observation time where available. Raw/typed JSON consumers must distinguish
absent fields from getters' default values.

This v1 targets the forwarded Position stream in raw NATS/MQTT, not automatic
legacy Lightbug Cloud location persistence or its valid-location UI.

## Delivery policy

There is one app-side upload in flight and **no queue, retry or persistence**.
A 15-second task deadline bounds the P1 write and the matching-response wait.
Further valid locations during that window are dropped with a `busy` warning.
Send exceptions, non-OK responses and an unconfirmed timeout are logged; a
timeout is not proof that the server failed to receive the frame. An OK response
is not a promise of downstream persistence.

Disabling upload or exiting cancels work not yet sent. It cannot recall a frame
already handed to P1. Changing links never rewrites an in-flight frame or starts
an additional worker. There is no `S_RAM` request: a forwarded cloud ACK can
bypass P1's stored-message cleanup. This intentionally avoids unbounded stored
retries, and does not provide offline delivery guarantees.

## Companion and validation

Requires the Gingin companion for uint-sized ForwardedFor/ForwardTo, ordered
repeated routing fields in JSON and reversing the full route on ACKs. Source IDs
above 255 must not be truncated. No wrapper, OriginalClientID or new message type
is introduced.

Host tests cover selection/defaults, conversion, unknown metadata, uint32 source
IDs, P2-to-P1 framing, repeated origin headers, malformed/non-location/binary
input, self echoes, busy drops, cancellation, timeout, NACK and write failure.
The repeated-header fixture simulates the documented P1 mutation; it is **not**
a hardware test.

### RH2 / Kanal live checklist (not yet run)

No RH2 is available to the author. Do not treat a successful host build as live
validation. After normal review and explicit approval to flash/deploy:

- Verify boot and app re-entry default to Off; switch Off → L1 → L2 → Off.
- With upload Off, existing LoRa/ESP-NOW/BLE ping, location, display, distance
  and button/menu behavior must remain unchanged.
- Send a location from a different device ID above 255. Capture P2→P1 bytes:
  MT15, ForwardedFor=remote, chosen ForwardTo, fresh MessageID, no ClientID.
- On the chosen link, confirm relay ClientID and ordered `[remote,1]`; inspect
  raw NATS/MQTT JSON for absent fix metadata and the original full uint32 ID.
- Confirm the companion ACK route `[1,remote]` reaches P2 after P1 removes `1`,
  and the response matches the fresh MessageID. No radio downlink is expected.
- Verify unknown/control/encrypted traffic and local-device echoes never
  upload; local GNSS subscriptions alone must not generate cloud uploads.
- Disconnect the chosen cloud link, keep receiving locations, and confirm
  UI/button/radio responsiveness plus busy/unconfirmed logs, no app retries
  and no growing P1 stored-message backlog. Restore the link and send a new
  sample. Observe existing L2 fallback separately, without changing its policy.
- Disable/exit during an outstanding attempt. Expect no later new attempt,
  while a frame already sent may still complete.
