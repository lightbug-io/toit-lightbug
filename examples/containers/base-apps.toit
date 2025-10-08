import lightbug.devices as devices
import lightbug.messages as messages
import lightbug.modules.comms.message-handler show MessageHandler
import lightbug.modules.strobe.strobe show Strobe
import lightbug.protocol as protocol
import lightbug.apps as apps
import lightbug.apps.survey show SurveyApp
import log

import watchdog.provider
import watchdog show WatchdogServiceClient

LOG-LEVEL ::= log.WARN-LEVEL

main:
  provider.main
  client := WatchdogServiceClient
  client.open
  dog := client.create "lb/apps"

  device := devices.I2C
    --log-level=LOG-LEVEL
    --with-default-handlers=false
    --background=false
  apps := apps.Apps device dog

  // Listen for "Actions" button presses...
  apps.start