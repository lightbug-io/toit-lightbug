// Jaguar bench entrypoint. Production builds use base-apps.toit directly.
import .base-apps as base
import lightbug.modules.dev-input.http-buttons show DevButtonServer
import lightbug.util.docs show jag-define

main:
  external-provider := jag-define "lb-watchdog-provider"
  base.run --setup=(:: |device| (DevButtonServer device).start) --start-watchdog-provider=(external-provider == null or external-provider.stringify != "external")
