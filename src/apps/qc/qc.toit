import ...devices
import ...messages.messages_gen as messages
import ...protocol as protocol
import ...modules.eink.menu-selection show MenuSelection
import ...modules.comms.message-handler show MessageHandler
import ...modules.comms.generic-handler show GenericHandler
import log
import monitor
import system.firmware
import watchdog show Watchdog
import ..apps show Apps

// TODO put this somewhere reusable
import ..survey.eink-batch show eink-do-batch

class QCApp:

  // TODO put these somewhere reusable..
  static screen-width ::= 250
  static screen-height ::= 122

  static BUTTON-NO ::= "No"
  static BUTTON-YES ::= "Yes"
  static BUTTON-SKIP ::= "Skip"

  device_/Device
  parent_/Apps? := null
  dog_/Watchdog? := null

  is-running_/bool := false
  showing-page_/int := 0
  buttons-subscriber-id_/int? := null

  logger_/log.Logger := log.default.with-name "qc"

  constructor device/Device parent/Apps dog/Watchdog:
    device_ = device
    parent_ = parent
    dog_ = dog
  
  // Basic app control, likely should be in a base and common interface?
  start:
    dog_.start --s=120 // 2 minute watchdog for QC app
    is-running_ = true
    init-button-subscription_
    // Send an OPEN message to the link
    // with the app name "qc", so that the server knows to start the cloud based QC app...
    opmsg := messages.Open.msg
    opmsg = add-forwarding-headers opmsg 0
    device_.comms.send opmsg
  
  show-text-page line/string:
    device_.eink.text-page --page-id=30 --status-bar-enable=false --lines=["",line,"","   No    Skip    Yes"]

  stop:
    dog_.stop
    is-running_ = false
    deinit-button-subscriber_

    parent_.start
    parent_.show-home
    showing-page_ = 0 // we no longer know or care

  feed:
    e := catch: dog_.feed
    if e:
      logger_.warn "DOG fail: $e"

  is-running -> bool:
    return is-running_

  init-button-subscription_:
    catch --trace:
      id := device_.buttons.subscribe --timeout=null --callback=(:: |button-data|
        feed
        logger_.info "$button-data"
        if button-data.duration <= 0:
          // Not actually a press... TODO make this nicer
        else:
          if not is-running_:
            // If we are not running, ignore button presses
            // The handler should not be subscribed if we are not running, but just in case
          if button-data.duration <= 0:
            // Not actually a press... ignore
          else if button-data.duration >= 3000: // Stop and go home
            stop
        //   else:
        //     // This counts as a real button press for the QC app.
        //     // So forward it to the server without "qc" tag...
        //     // So that the cloud app requires no state for the action that has been taken.
        //     msg := protocol.Message.with-data messages.ButtonPress.MT button-data.base-data
        //     msg = add-forwarding-headers msg
        //     device_.comms.send msg
      )

      if id:
        buttons-subscriber-id_ = id

  deinit-button-subscriber_:
    // Unsubscribe from buttons if we have a subscriber id
    if buttons-subscriber-id_:
      e := catch: device_.buttons.unsubscribe --subscriber-id=buttons-subscriber-id_ --timeout=null
      if e:
        logger_.warn "Failed to unsubscribe from buttons: $e"
      // Ignore errors from unsubscribe but clear our id.
      buttons-subscriber-id_ = null
    
  add-forwarding-headers msg/protocol.Message to-link/int-> protocol.Message:
    // 0 is the default lightbug link
    msg.header.data.add-data-uint8 protocol.Header.TYPE-FORWARD-TO to-link
    msg.header.data.add-data-ascii 50 "qc" 
    // msg.header.data.add-data-ascii 51 qc-name // Application meta field 1... (up to 20 bytes?)
    return msg
