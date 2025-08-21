import log
import ...messages as messages
import ...util.resilience show catch-and-restart
import .comms show Comms

/**
Interface for controlling heartbeat messages to keep the device connection alive.
*/
interface Heartbeats:
  // Start sending heartbeats
  start
  // Stop sending heartbeats
  stop
  // Set the heartbeat period
  set-period period/Duration
  // Check if heartbeats are currently running
  is-running -> bool

/**
Implementation of heartbeat control for Comms.
*/
class CommsHeartbeats implements Heartbeats:
  comms_ /Comms
  logger_ /log.Logger
  period_ /Duration := Duration --s=15
  running_ /bool := false
  task_ := null

  constructor comms logger/log.Logger:
    comms_ = comms
    logger_ = logger

  start:
    if running_:
      logger_.debug "Heartbeats already running"
      return
    running_ = true
    logger_.info "Starting heartbeats with period $(period_)"
    task_ = task --background=true:: catch-and-restart "sendHeartbeats_" (:: send-heartbeats_) --logger=logger_

  stop:
    if not running_:
      logger_.debug "Heartbeats already stopped"
      return
    running_ = false
    logger_.info "Stopping heartbeats"
    if task_:
      task_.cancel
      task_ = null

  set-period period/Duration:
    period_ = period
    logger_.info "Heartbeat period set to $(period_)"
    // If running, restart with new period
    if running_:
      stop
      start

  is-running -> bool:
    return running_

  send-heartbeats_:
    while running_:
      // Send a heartbeat message
      if not (comms_.send (messages.Heartbeat.msg --data=null) --withLatch=true).get:
        logger_.error "Failed to send heartbeat"
      else:
        logger_.debug "Sent heartbeat"
      sleep period_
