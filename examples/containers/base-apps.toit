import lightbug.devices as devices
import lightbug.messages as messages
import lightbug.modules.comms.message-handler show MessageHandler
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
  provider.main
  client := WatchdogServiceClient
  client.open
  dog := client.create "lb/apps"

  device := devices.I2C
    --log-level=LOG-LEVEL
    --with-default-handlers=true
    --background=false
  apps := apps.Apps device dog

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
