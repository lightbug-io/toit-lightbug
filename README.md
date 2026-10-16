# Toit Lightbug

`toit-lightbug` is the official Toit package that lets you target Lightbug ESP32 hardware with a full set of bindings, helper services, examples, and production-ready applications.

## What you get

- **Hardware bindings:** Data-driven modules for every Lightbug subsystem (E-ink, strobe, buttons, comms, messaging, etc.) that you can import from the installed pkg.
- **Sample applications:** A rich `examples/` tree covering low-level `messages/`, `modules/`, `services/`, and `containers/` plus stand-alone demos such as the `geofence` project.
- **Tooling:** Helpers such as `bitmaps.json` and `tools/generate_bitmaps.py` create the bitmap tables that many examples expect, while `tests/` shows how we run unit-style Jaguar tests on host or hardware.

## Relay app

Open **Apps → Relay**, then choose **Radio: LoRa / ESP-NOW / BLE** independently of **Send: Ping / ID / Location**. LoRa is the default and retains its profiles and airtime limits. Switching radios stops continual sending and cancels queued sends. This app exchanges messages directly; it does not forward packets.

ESP-NOW broadcasts on a selectable channel (1–11, default 6); both devices must use the same channel. It requires Wi-Fi to be disabled before entering that mode. For Jaguar bench sessions, use `-Djag.wifi=false` with an appropriate `-Djag.timeout` when starting the program over USB; Wi-Fi and HTTP button controls are unavailable during that session. Relay reports a busy/unavailable radio rather than disconnecting Wi-Fi itself.

BLE uses compact, non-connectable advertisements carrying an ID, ping/pong, or coordinates. Each send advertises for up to 500 ms; a new send replaces the current advertisement immediately. Repeated receptions are filtered. BLE and ESP-NOW manual sends have no app-imposed cooldown or queued follow-up; Rate controls continual sends only. Rapid BLE sends can shorten a burst and reduce delivery chances. The device's BLE scanner and advertiser must be idle when selecting BLE; ordinary BLE requests cannot use the adapter until Relay releases it. BLE and ESP-NOW broadcasts are unencrypted and delivery is best effort.

The base-apps entrypoints accept `-Dlb-app=relay` to start Relay on boot.

## Documentation & resources

- **Toit home:** https://toitlang.org/
- **Toit language reference:** https://docs.toit.io/language/
- **Toit package docs:** https://docs.toit.io/language/package
- **Lightbug Toit SDK docs:** https://docs.lightbug.io/devices/api/sdks/toit/
- **Lightbug Toit getting started:** https://docs.lightbug.io/devices/api/sdks/toit/getting-started
- **Lightbug Toit examples:** https://docs.lightbug.io/devices/api/sdks/toit/examples/
- **Lightbug device API general entry:** https://docs.lightbug.io/devices/api/
- **Package listing:** https://pkg.toit.io/package/github.com%2Flightbug-io%2Ftoit-lightbug
- **Examples directory on GitHub:** https://github.com/lightbug-io/toit-lightbug/tree/main/examples
- **Lightbug toit envelopes:** https://github.com/lightbug-io/toit-envelopes
- **Releases & firmware assets:** https://github.com/lightbug-io/toit-lightbug/releases
