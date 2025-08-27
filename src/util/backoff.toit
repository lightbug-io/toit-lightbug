/**
Executes a block with exponential backoff retry logic.

This function will repeatedly execute the provided block until it succeeds
or the maximum number of retries is exceeded. Between retries, it sleeps
for an increasing duration based on the backoff factor.

Parameters:
  --onSuccess: Optional callback function called when the block executes
               successfully without throwing an exception.
  --onError: Optional callback function called when the block throws an
             exception. The exception is passed as a parameter to the callback.
  --initial-delay: Initial delay between retries. Defaults to 100ms.
  --max-retries: Maximum number of retry attempts. If null, retries indefinitely.
                 Note: This is the number of retries, not total attempts.
                 (e.g., max-retries=3 means 4 total attempts: 1 initial + 3 retries)
  --backoff-factor: Factor by which the delay is multiplied after each retry.
                    Use 1.0 for constant delay, >1.0 for exponential backoff.
                    Defaults to 1.0.
  --max-delay: Maximum delay cap to prevent excessively long waits.
               If null, delay can grow indefinitely. Defaults to null.

Examples:
  // Simple retry with exponential backoff
  do-with-backoff:
    risky-operation

  // With callbacks and custom settings
  do-with-backoff
    --onSuccess=(:: print "Success!")
    --onError=(:: |error| print "Error: $error")
    --initial-delay=(Duration --ms=500)
    --max-retries=5
    --backoff-factor=2.0
    --max-delay=(Duration --s=30):
    network-request

Throws: The last exception thrown by the block if max-retries is exceeded.
*/
do-with-backoff [block] --onSuccess/Lambda?=null --onError/Lambda?=null --initial-delay/Duration=(Duration --ms=100) --max-retries/int?=null --backoff-factor/float=1.0 --max-delay/Duration?=null:
  done := false
  retry-count := 0
  current-delay := initial-delay
  
  while not done:
    e := catch:
      block.call
      done = true
      if onSuccess:
        onSuccess.call
    if e:
      if onError:
        onError.call e
      
      // Check if we've exceeded max retries
      if max-retries and retry-count >= max-retries:
        // Re-throw the last exception since we've exhausted retries
        throw e
      
      // Sleep for the current delay
      sleep current-delay
      
      // Update delay for next iteration
      current-delay = current-delay * backoff-factor
      if max-delay and current-delay > max-delay:
        current-delay = max-delay
      
      retry-count++