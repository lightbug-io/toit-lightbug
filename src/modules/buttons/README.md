# Buttons Module

The buttons module provides a clean interface for handling button press events from Lightbug devices.

## Overview

The buttons module abstracts away the complexity of subscribing to button press messages, managing message inboxes, and handling callbacks. It provides a simple subscribe/unsubscribe interface with optional lambda callbacks.

## Usage

### Synchronous Subscription (Blocking)

The default `subscribe` method blocks until the subscription is confirmed:

```toit
import lightbug.devices as devices

main:
  device := devices.RtkHandheld2
  
  // Blocks until subscription is confirmed or fails
  success := device.buttons.subscribe --callback=:: |button-data|
    print "Button $(button-data.button-id) pressed for $(button-data.duration)ms"
    
  if not success:
    throw "Failed to subscribe to button presses"
```

### Asynchronous Subscription (Fire-and-Forget)

Use `--async` for non-blocking subscription:

```toit
// Fire-and-forget - doesn't wait for confirmation
device.buttons.subscribe --async --callback=:: |button-data|
  print "Button $(button-data.button-id) pressed for $(button-data.duration)ms"

print "Subscription request sent, continuing..."
```

### Asynchronous with Success/Error Callbacks

```toit
device.buttons.subscribe --async 
    --callback=:: |button-data|
      print "Button $(button-data.button-id) pressed for $(button-data.duration)ms"
    --onSuccess=:: 
      print "✅ Successfully subscribed!"
    --onError=:: |error|
      print "🚨 Subscription failed: $error"
```

### Error Handling Patterns

```toit
// Pattern 1: Synchronous with catch
e := catch:
  device.buttons.subscribe --callback=:: |button-data|
    print "Button event: $button-data"
  
if e:
  print "🚨 Button setup failed: $e"
  throw e

// Pattern 2: Asynchronous with error callback
device.buttons.subscribe --async 
    --callback=:: |button-data| print "Button: $button-data"
    --onError=:: |error| print "🚨 Setup failed: $error"
```

### Changing Callbacks

```toit
// You can change the callback after subscription
device.buttons.set-callback:: |button-data|
  print "New callback: Button $(button-data.button-id)"

// Or remove the callback entirely
device.buttons.set-callback null
```

### Unsubscribing

```toit
// Synchronous unsubscribe (blocks until confirmed)
success := device.buttons.unsubscribe
if not success:
  print "Failed to unsubscribe"

// Asynchronous unsubscribe (fire-and-forget)
device.buttons.unsubscribe --async

// Asynchronous with callbacks
device.buttons.unsubscribe --async 
    --onSuccess=:: print "✅ Unsubscribed"
    --onError=:: |error| print "🚨 Failed: $error"
```

## API Reference

### Methods

#### `subscribe --callback/Lambda?=null --timeout/Duration=(Duration --s=5) -> bool`
Subscribes to button press events synchronously (blocks until confirmed).

**Parameters:**
- `--callback`: Optional lambda to call when button presses are received
- `--timeout`: Timeout duration for the subscription request (default: 5 seconds)

**Returns:** `true` if subscription was successful, `false` otherwise

#### `subscribe --async --callback/Lambda?=null --onSuccess/Lambda?=null --onError/Lambda?=null`
Subscribes to button press events asynchronously (fire-and-forget).

**Parameters:**
- `--async`: Flag to enable asynchronous mode
- `--callback`: Optional lambda to call when button presses are received
- `--onSuccess`: Optional lambda to call when subscription is confirmed
- `--onError`: Optional lambda to call if subscription fails (receives error message)

#### `unsubscribe --timeout/Duration=(Duration --s=5) -> bool`
Unsubscribes from button press events synchronously (blocks until confirmed).

**Parameters:**
- `--timeout`: Timeout duration for the unsubscribe request (default: 5 seconds)

**Returns:** `true` if unsubscription was successful, `false` otherwise

#### `unsubscribe --async --onSuccess/Lambda?=null --onError/Lambda?=null`
Unsubscribes from button press events asynchronously (fire-and-forget).

**Parameters:**
- `--async`: Flag to enable asynchronous mode
- `--onSuccess`: Optional lambda to call when unsubscription is confirmed
- `--onError`: Optional lambda to call if unsubscription fails (receives error message)

#### `set-callback callback/Lambda?`
Sets or updates the callback for button press events.

**Parameters:**
- `callback`: Lambda to call when button presses are received, or `null` to remove callback

#### `is-subscribed -> bool`
Returns whether the module is currently subscribed to button press events.

### Callback Function

The callback function receives a `ButtonPress` object with the following properties:

- `button-id -> int`: ID of the button (0-indexed)
- `duration -> int`: Duration of the button press in milliseconds

## Examples

See `examples/modules/strobe/button-clean.toit` for a complete example that demonstrates:
- Subscribing to button presses
- Handling different button IDs
- Distinguishing between short and long presses
- Controlling device strobe based on button presses

## Migration from Raw Message Handling

If you're migrating from the raw message handling approach (like in the original `button.toit` example), the new module simplifies your code significantly:

**Before:**
```toit
// Complex subscription and inbox management
if not ( device.comms.send (messages.ButtonPress.subscribe-msg --ms=1000) --now=true
  --preSend=(:: print "💬 Subscribing to button presses")
  --onAck=(:: print "✅ Button subscription ACKed")
  --onNack=(:: if it.msg-status != null: log.warn "Button not yet subscribed, state: $(it.msg-status)" else: log.warn "Button not yet subscribed" )
  --timeout=(Duration --s=5)
).get:
  throw "📟❌ Failed to subscribe to button press events"

inbox := device.comms.inbox "button-example"
while true:
  msg := inbox.receive
  // ... complex message handling
```

**After:**
```toit
// Simple subscription with callback
device.buttons.subscribe --ms=1000 --callback=:: |button-data|
  // Direct access to button data
  if button-data.duration >= 1000:
    // Handle long press
  else:
    // Handle short press based on button-data.button-id
```
