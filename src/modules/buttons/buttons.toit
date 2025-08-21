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
  callback_/Lambda? := null
  inbox_/monitor.Channel? := null
  task_/Task? := null

  constructor comms/comms.Comms --logger/log.Logger?=null:
    comms_ = comms
    logger_ = logger ? log.default.with-name "lb-buttons" : log.default.with-name "lb-buttons"

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
  subscribe --callback/Lambda?=null --timeout/Duration=(Duration --s=5) -> bool:
    if subscribed_:
      // TODO XXX: DO we want to allow 2 subs, or overriding previous ones?
      logger_.warn "Already subscribed to button presses"
      return false

    // Track success for synchronous behavior
    success := false
    latch := monitor.Latch

    subscribe_ --callback=callback 
        --onSuccess=(:: 
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
  Subscribes to button press events asynchronously (fire-and-forget).
  
  This method sends the subscription request but doesn't wait for confirmation.
  Use this when you want non-blocking behavior and don't need to know if the
  subscription was successful immediately.
  
  Parameters:
    --callback: Optional lambda to call when button presses are received
    --onSuccess: Optional lambda to call when subscription is confirmed
    --onError: Optional lambda to call if subscription fails
  */
  subscribe --async --callback/Lambda?=null --onSuccess/Lambda?=null --onError/Lambda?=null:
    if subscribed_:
      logger_.warn "Already subscribed to button presses"
      if onError:
        onError.call "Already subscribed"
      return

    subscribe_ --callback=callback --onSuccess=onSuccess --onError=onError

  /**
  Unsubscribes from button press events synchronously (blocks until response).
  
  Sends an unsubscribe message to the device and stops the listening task.
  
  Parameters:
    --timeout: Timeout duration for the unsubscribe request
  
  Returns: true if unsubscription was successful, false otherwise
  */
  unsubscribe --timeout/Duration=(Duration --s=5) -> bool:
    if not subscribed_:
      logger_.warn "Not currently subscribed to button presses"
      return false

    // Track success for synchronous behavior
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
  unsubscribe --async --onSuccess/Lambda?=null --onError/Lambda?=null:
    if not subscribed_:
      logger_.warn "Not currently subscribed to button presses"
      if onError:
        onError.call "Not currently subscribed"
      return

    unsubscribe_ --onSuccess=onSuccess --onError=onError

  /**
  Internal method to handle subscription logic.
  
  This contains the shared logic between sync and async subscription methods.
  */
  subscribe_ --callback/Lambda?=null --onSuccess/Lambda?=null --onError/Lambda?=null --timeout/Duration?=null:
    // Store the callback for later use.
    callback_ = callback

    // Send subscription message.
    // TODO XXX: Is --ms actually needed for button subscriptions?
    comms_.send (messages.ButtonPress.subscribe-msg --ms=1000) --now=true
        --onAck=(:: 
          subscribed_ = true
          // TODO XXX: Should we always start listening even if no ACK?
          // Maybe we want the callback to work regardless of subscription confirmation?
          // Start listening for button press messages if we have a callback.
          if callback_:
            start-listening_
          if onSuccess:
            onSuccess.call
        )
        --onNack=(:: |msg|
          // Treat NACK as a failure - don't set subscribed_ or start listening
          // TODO XXX: Consider actually continuing to listen even if NACKed?
          error-msg := ?
          if msg.msg-status != null:
            error-msg = "Button subscription failed, state: $(msg.msg-status)"
            logger_.debug error-msg
          else:
            error-msg = "Button subscription failed"
            logger_.debug error-msg
          if onError:
            onError.call error-msg
        )
        --onTimeout=(::
          // Handle timeout case
          logger_.debug "Button subscription timed out"
          if onError:
            onError.call "Subscription timed out"
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
          callback_ = null
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
    callback_ = callback
    
    if subscribed_:
      if callback_:
        // Start listening if we weren't before.
        if not task_:
          start-listening_
      else:
        // Stop listening if callback is removed.
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
    
    // Start task to process button messages.
    task_ = task::
      try:
        while callback_:
          msg := inbox_.receive
          e := catch:
            if msg.type == messages.ButtonPress.MT:
              logger_.debug "Received button press: $msg"
              button-data := messages.ButtonPress.from-data msg.data
              callback_.call button-data
            else:
              logger_.debug "Received other message: $msg"
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
