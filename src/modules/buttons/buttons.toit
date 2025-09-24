import ...messages.messages_gen as messages
import ...modules.comms as comms
import monitor
import log

/**
Button module for handling button press events.

Provides a clean interface for subscribing to button press events and handling
them with optional lambda callbacks.
*/
class Buttons:
  comms_/comms.Comms
  logger_/log.Logger
  subscribed_/bool := false
  // Support multiple independent subscribers: id -> Lambda
  subscribers_/Map := {:}
  next-subscriber-id_/int := 0
  inbox_/monitor.Channel? := null
  task_/Task? := null

  constructor comms/comms.Comms --logger/log.Logger=(log.default.with-name "lb-buttons"):
    comms_ = comms
    logger_ = logger

  /**
  Subscribes to button press events synchronously (blocks until response).
  
  The callback will be called with the raw button press message data whenever
  a button press is received. The callback can inspect properties like
  buttonData.duration, buttonData.button-id, etc.
  
  Parameters:
    --callback: Optional lambda to call when button presses are received.
                This can also be set later with set-callback.
    --timeout: Timeout duration for the subscription request
  
  Returns: true if subscription was successful, false otherwise
  */
  // Synchronous subscribe: returns subscriber id on success, null on failure.
  subscribe --callback/Lambda?=null --timeout/Duration=(Duration --s=5) --retries/int=3 -> int?:
    id := next-subscriber-id_ + 1
    next-subscriber-id_ = id
    if callback:
      subscribers_[id] = callback
    else:
      subscribers_[id] = (::)

    // If already subscribed at transport level, we're already receiving messages.
    if subscribed_:
      return id

    // Otherwise attempt underlying subscribe and wait for ack.
    success := false
    latch := monitor.Latch

    subscribe_ --callback=null 
        --onSuccess=(:: 
          success = true
          latch.set true
        )
        --onError=(:: |error|
          success = false
          latch.set false
        )
        --timeout=timeout
        --retries=retries

    // Wait for response
    latch.get

    if not success:
      subscribers_.remove id
      return null

    return id

  /**
  Subscribes to button press events asynchronously (fire-and-forget).
  
  This method sends the subscription request but doesn't wait for confirmation.
  Use this when you want non-blocking behavior and don't need to know if the
  subscription was successful immediately.
  
  Parameters:
    --callback: Optional lambda to call when button presses are received
    --onSuccess: Optional lambda to call when subscription is confirmed
    --onError: Optional lambda to call if subscription fails
  */
  // Async subscribe: returns subscriber id immediately.
  subscribe --async --callback/Lambda?=null --onSuccess/Lambda?=null --onError/Lambda?=null --retries/int=3 -> int:
    id := next-subscriber-id_ + 1
    next-subscriber-id_ = id
    if callback:
      subscribers_[id] = callback
    else:
      subscribers_[id] = (::)

    if not subscribed_:
      subscribe_ --callback=null --onSuccess=onSuccess --onError=onError --retries=retries
    else:
      if onSuccess:
        onSuccess.call

    return id

  /**
  Unsubscribes from button press events synchronously (blocks until response).
  
  Sends an unsubscribe message to the device and stops the listening task.
  
  Parameters:
    --timeout: Timeout duration for the unsubscribe request
  
  Returns: true if unsubscription was successful, false otherwise
  */
  // Synchronous unsubscribe. If subscriber-id provided, remove that subscriber.
  // If no subscriber-id provided, remove all subscribers and perform underlying
  // unsubscribe. Returns true if underlying unsubscription succeeded or was
  // not necessary.
  unsubscribe --subscriber-id/int?=null --timeout/Duration=(Duration --s=5) -> bool:
    if subscriber-id != null:
      subscribers_.remove subscriber-id
    else:
      subscribers_ = {:}

    // If there are remaining subscribers, nothing to do at transport level.
    if subscribers_.size > 0:
      return true

    if not subscribed_:
      return true

    success := false
    latch := monitor.Latch

    unsubscribe_ --onSuccess=(:: 
          success = true
          latch.set true
        )
        --onError=(:: |error|
          success = false
          latch.set false
        )
        --timeout=timeout

    // Wait for response
    latch.get
    return success

  /**
  Unsubscribes from button press events asynchronously (fire-and-forget).
  
  This method sends the unsubscribe request but doesn't wait for confirmation.
  Use this when you want non-blocking behavior and don't need to know if the
  unsubscription was successful immediately.
  
  Parameters:
    --onSuccess: Optional lambda to call when unsubscription is confirmed
    --onError: Optional lambda to call if unsubscription fails
  */
  // Async unsubscribe: remove given subscriber id or all if null.
  unsubscribe --async --subscriber-id/int?=null --onSuccess/Lambda?=null --onError/Lambda?=null:
    if subscriber-id != null:
      subscribers_.remove subscriber-id
    else:
      subscribers_ = {:}

    if subscribers_.size == 0:
      if not subscribed_:
        if onSuccess:
          onSuccess.call
        return
      unsubscribe_ --onSuccess=onSuccess --onError=onError
    else:
      if onSuccess:
        onSuccess.call

  /**
  Internal method to handle subscription logic.
  
  This contains the shared logic between sync and async subscription methods.
  */
  subscribe_ --callback/Lambda?=null --onSuccess/Lambda?=null --onError/Lambda?=null --timeout/Duration?=null --retries/int=3:
    subscribe-with-retries_ 0 retries --callback=callback --onSuccess=onSuccess --onError=onError --timeout=timeout

  /**
  Internal helper method to perform subscription with retry logic.
  */
  subscribe-with-retries_ current-attempt/int max-retries/int --callback/Lambda?=null --onSuccess/Lambda?=null --onError/Lambda?=null --timeout/Duration?=null:
    logger_.debug "Button subscription attempt $(current-attempt + 1) of $(max-retries + 1)"
    
    // Send subscription message.
    comms_.send (messages.ButtonPress.subscribe-msg) --now=true
        --onAck=(:: 
          subscribed_ = true
          // Start listening for button press messages if we have any subscribers.
          if subscribers_.size > 0:
            start-listening_
          if onSuccess:
            onSuccess.call
        )
        --onNack=(:: |msg|
          // Check if we should retry
          if current-attempt < max-retries:
            logger_.debug "Button subscription failed, retrying... (attempt $(current-attempt + 1) of $(max-retries + 1))"
            subscribe-with-retries_ (current-attempt + 1) max-retries --callback=callback --onSuccess=onSuccess --onError=onError --timeout=timeout
          else:
            // Final failure - treat NACK as a failure
            error-msg := ?
            if msg.msg-status != null:
              error-msg = "Button subscription failed after $(max-retries + 1) attempts, state: $(msg.msg-status)"
              logger_.debug error-msg
            else:
              error-msg = "Button subscription failed after $(max-retries + 1) attempts"
              logger_.debug error-msg
            if onError:
              onError.call error-msg
        )
        --onTimeout=(::
          // Check if we should retry on timeout
          if current-attempt < max-retries:
            logger_.debug "Button subscription timed out, retrying... (attempt $(current-attempt + 1) of $(max-retries + 1))"
            subscribe-with-retries_ (current-attempt + 1) max-retries --callback=callback --onSuccess=onSuccess --onError=onError --timeout=timeout
          else:
            // Final timeout
            logger_.debug "Button subscription timed out after $(max-retries + 1) attempts"
            if onError:
              onError.call "Subscription timed out after $(max-retries + 1) attempts"
        )
        --timeout=timeout

  /**
  Internal method to handle unsubscription logic.
  
  This contains the shared logic between sync and async unsubscription methods.
  */
  unsubscribe_ --onSuccess/Lambda?=null --onError/Lambda?=null --timeout/Duration?=null:
    // Stop the listening task first.
    stop-listening_

    // Send unsubscribe message.
    comms_.send (messages.ButtonPress.unsubscribe-msg) --now=true
        --onAck=(:: 
          subscribed_ = false
          subscribers_ = {:}
          if onSuccess:
            onSuccess.call
        )
        --onNack=(:: |msg|
          // Treat NACK as a failure
          error-msg := ?
          if msg.msg-status != null:
            error-msg = "Button unsubscription failed, state: $(msg.msg-status)"
            logger_.debug error-msg
          else:
            error-msg = "Button unsubscription failed"
            logger_.debug error-msg
          if onError:
            onError.call error-msg
        )
        --onTimeout=(::
          // Handle timeout case
          logger_.debug "Button unsubscription timed out"
          if onError:
            onError.call "Unsubscription timed out"
        )
        --timeout=timeout

  /**
  Sets or updates the callback for button press events.
  
  This can be called even after subscription to change the callback function.
  If no callback is provided, button press events will still be received but
  not processed.
  
  Parameters:
    callback: Lambda to call when button presses are received, or null to remove callback
  */
  set-callback callback/Lambda?:
    // Keep backward-compatible single-callback setter by registering a
    // dedicated subscriber and clearing previous ones.
    subscribers_ = {:}
    if callback:
      id := next-subscriber-id_ + 1
      next-subscriber-id_ = id
      subscribers_[id] = callback

    if subscribed_:
      if subscribers_.size > 0:
        if not task_:
          start-listening_
      else:
        stop-listening_

  /**
  Returns whether the module is currently subscribed to button press events.
  */
  is-subscribed -> bool:
    return subscribed_

  /**
  Starts the listening task for button press messages.
  */
  start-listening_:
    if task_:
      return  // Already listening.

    // Create inbox for button messages.
    inbox_ = comms_.inbox "buttons"
    
    // Start task to process button messages and dispatch to all subscribers.
    task_ = task::
      try:
        while subscribers_.size > 0:
          msg := inbox_.receive
          e := catch:
            if msg.type == messages.ButtonPress.MT:
              logger_.debug "Received button press: $msg"
              button-data := messages.ButtonPress.from-data msg.data
              // Dispatch to all subscribers; protect each callback.
              subscribers_.do: |id cb|
                se := catch:
                  cb.call button-data
                if se:
                  logger_.error "Subscriber $(id) callback error: $se"
          if e:
            logger_.error "Error processing button message: $e"
      finally:
        logger_.debug "Button listening task stopped"

  /**
  Stops the listening task and cleans up resources.
  */
  stop-listening_:
    if task_:
      task_.cancel
      task_ = null
    inbox_ = null
