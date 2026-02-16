sleep-blocking --ms/int -> none:
  sleep-blocking (Duration --ms=ms)

sleep-blocking duration/Duration -> none:
  deadline-us := (Time.monotonic-us --since-wakeup) + duration.in-us
  while true:
    remaining-us := deadline-us - (Time.monotonic-us --since-wakeup)
    if remaining-us <= 0: return
    // Don't sleep when too close to the deadline.
    sleep-us := remaining-us - 100_000 
    // Don't sleep for too little time.
    if sleep-us >= 20_000: sleep --ms=(sleep-us / 1_000)