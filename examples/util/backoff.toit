import lightbug.util.backoff as backoff

main:
  print "=== Backoff Example 1: Exponential backoff with max retries ==="
  attempt-count := 0
  
  e := catch:
    backoff.do-with-backoff
      --onSuccess=(:: print "Operation succeeded!")
      --onError=(:: |error|
        attempt-count++
        print "Error on attempt $attempt-count: $error"
      )
      --initial-delay=(Duration --ms=100)
      --max-retries=5
      --backoff-factor=2.0
      --max-delay=(Duration --ms=2000):
      print "Attempting operation..."
      throw "Simulated exception to demonstrate retry"
  if e:
    print "Backoff failed after max retries: $e"
  
  print "\n=== Backoff Example 2: Operation that eventually succeeds ==="
  success-attempt := 0
  
  e = catch:
    backoff.do-with-backoff
      --onSuccess=(:: print "Finally succeeded after $success-attempt attempts!")
      --onError=(:: |error|
        success-attempt++
        print "Error on attempt $success-attempt: $error"
      )
      --initial-delay=(Duration --ms=200)
      --max-retries=10
      --backoff-factor=1.5:
      print "Attempting operation..."
      if success-attempt < 3:
        throw "Not ready yet, attempt $success-attempt"
      print "Operation completed successfully!"
  if e:
    print "Backoff failed: $e"
  
  print "\n=== Backoff Example 3: Constant delay with no max retries ==="
  constant-attempt := 0
  should-stop := false
  
  e = catch:
    // This would run forever, but we'll limit it with a counter for demo
    backoff.do-with-backoff
      --onSuccess=(:: print "Constant delay operation succeeded!")
      --onError=(:: |error|
        constant-attempt++
        print "Error on attempt $constant-attempt: $error"
        if constant-attempt >= 3:
          print "Stopping demo after 3 attempts"
          should-stop = true
      )
      --initial-delay=(Duration --ms=500)
      --backoff-factor=1.0:  // No increase in delay
      print "Attempting operation..."
      if should-stop:
        print "Operation completed (demo stopped)"
      else:
        throw "Constant delay example"
  if e:
    print "Backoff failed: $e"
