import lightbug.devices as devices
import lightbug.firmware as firmware
import lightbug.messages as messages
import lightbug.modules.comms.message-handler show MessageHandler
import lightbug.modules.comms.forwarder show P1UsbForwarder
import lightbug.modules.comms.usb-console show UsbConsole
import lightbug.modules.strobe.strobe show Strobe
import lightbug.protocol as protocol
import lightbug.apps as apps
import lightbug.apps.survey show SurveyApp
import lightbug.util.docs show jag-define
import log

import watchdog.provider
import watchdog show WatchdogServiceClient

LOG-LEVEL ::= log.WARN-LEVEL
logger := log.default.with-name "base-apps"

main:
  run

// The production entrypoint has no dependency on development input services.
// A separate bench entrypoint passes setup after the device is constructed.
run --setup/Lambda?=null --start-watchdog-provider/bool=true:
  firmware.print-startup-line
  if start-watchdog-provider:
    provider.main
  client := WatchdogServiceClient
  client.open
  dog := client.create "lb/apps"

  device := devices.I2C
    --log-level=LOG-LEVEL
    --with-default-handlers=true
    --background=false
  if setup:
    setup.call device
  show-unknown-lora := jag-define "lb-lora-show-unknown"
  apps := apps.Apps device dog --show-unknown-lora-messages=(show-unknown-lora != null and show-unknown-lora.stringify == "true")

  // Keep the application container usable as a USB dock target.  The USB V3
  // bridge sends Forward To=P1 requests to P1 and routes correlated replies
  // (and Forward To=USB host messages) back to the host.
  usb := UsbConsole --background=false
  P1UsbForwarder --usb=usb.comms --p1=device.comms

  // Listen for "Actions" button presses...
  apps.start

  // Optionally go right into an app
  start-app := jag-define "lb-app"
  start-app-name := start-app == null ? "" : start-app.stringify
  if start-app-name != "":
    logger.info "lb-app=$start-app-name"
    print "lb-app=$start-app-name"
  if start-app-name == "survey":
    apps.open-survey-app
  else if start-app-name == "lora":
    apps.open-lora-app
  else if start-app-name == "qc":
    apps.open-qc-app
  else if start-app-name != "":
    logger.warn "Unknown lb-app define: $start-app-name"
