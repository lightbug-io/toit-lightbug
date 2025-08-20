
import core.async show task monitor
import core.os show sleep

/**
An asynchronous Promise class that mimics Javascript's Promise behavior.

It uses a background task to perform work, allowing the main program
  to continue. The .await method blocks until the promise is settled.
*/
class Promise:
  static PENDING ::= 0
  static FULFILLED ::= 1
  static REJECTED ::= 2

  state_/int := PENDING
  value_ := null
  error_ := null

  thens_ := []
  on_error_/Lambda? := null
  finally_/Lambda? := null

  monitor_ := monitor.Monitor

  /**
  Constructs a new promise.

  The 'executor' lambda is run in a background task. It receives two
    lambdas, 'resolve' and 'reject', to settle the promise.
  */
  constructor executor/Lambda:
    task::
      // The user's code can now be asynchronous.
      // We protect it with a 'catch' to automatically reject on throw.
      err := catch:
        executor.call (:: resolve_), (:: reject_)
      if err != null: reject_ err

  resolve_ value:
    monitor_.lock:
      try:
        if state_ != PENDING: return
        state_ = FULFILLED
        value_ = value
        monitor_.notify_all
      finally:
        monitor_.unlock

  reject_ err:
    monitor_.lock:
      try:
        if state_ != PENDING: return
        state_ = REJECTED
        error_ = err
        monitor_.notify_all
      finally:
        monitor_.unlock

  then callback/Lambda -> Promise:
    thens_.add callback
    return this

  on-error callback/Lambda -> Promise:
    on_error_ = callback
    return this

  finally callback/Lambda -> Promise:
    finally_ = callback
    return this

  /**
  Waits for the promise to be settled, then executes the chain.
  */
  await:
    // Wait for the promise to move out of the PENDING state.
    monitor_.lock:
      try:
        while state_ == PENDING:
          monitor_.wait
      finally:
        monitor_.unlock

    // Now that the promise is settled, execute the chain.
    try:
      if state_ == REJECTED:
        if on_error_: on_error_.call error_
        return

      // Start with the fulfilled value of the promise.
      current_value := value_
      thens_.do: |then_action|
        successful_result := null
        err := catch:
          successful_result = then_action.call current_value

        if err != null:
          if on_error_: on_error_.call err
          return
        current_value = successful_result
    finally:
      if finally_: finally_.call

main:
  print "Asynchronous promise example"

  // Example of a failing promise chain.
  p1 := Promise (:: | resolve reject |
    print "Promise 1 task started (will reject in 500ms)"
    sleep --ms=500
    reject.call "Something went wrong")

  p1.then (:: |val|
    print "Step 1: This will be skipped")
  p1.on-error (:: |err|
    print "Caught error: $err")
  p1.finally (::
    print "Promise 1 finished (finally)")

  print "Main program continues while promise 1 runs..."
  p1.await

  print ""
  print "---"
  print ""

  // Example of a successful promise chain.
  print "A successful promise chain:"
  p2 := Promise (:: | resolve reject |
    print "Promise 2 task started (will resolve in 1s)"
    sleep --s=1
    resolve.call "start")

  p2.then (:: |val|
    print "Step 1: $val"
    "all good")
  p2.then (:: |val|
    print "Step 2: $val")
  p2.on-error (:: |err|
    print "This should not be called: $err")
  p2.finally (::
    print "Promise 2 finished (finally)")

  print "Main program continues while promise 2 runs..."
  p2.await
