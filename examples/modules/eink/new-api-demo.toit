import lightbug.devices as devices
import lightbug.services as services
import lightbug.util.bitmaps show lightbug-20-20 lightbug-30-30 lightbug-40-40

main:
  // Setup the device and comms service
  device := devices.RtkHandheld2
  comms := services.Comms --device=device
  screen := devices.setup-eink comms
  
  print "📝 Draw a page with some text and bitmap"
  screen.set-title "Unified API Demo"
  screen.set-lines 
    --line1="Welcome to the screen module"
    --line2="which is much simpler"
    --line3="than sending messages."
  screen.add-bitmap --x=209 --y=0 --width=40 --height=40 --bitmap=lightbug-40-40
  screen.render
  
  print "📝 Updating line 4, 3 times with time"
  screen.set-line4 "$(Time.now)"
  screen.render
  sleep (Duration --s=1)
  screen.set-line4 "$(Time.now)"
  screen.render
  sleep (Duration --s=1)
  screen.set-line4 "$(Time.now)"
  screen.render
  
  print "📋 Switch to a menu (last content wins)"
  screen.set-items ["Option A", "Option B", "Option C"]
  screen.render
  
  sleep (Duration --s=2)
  
  print "📋 Adding a 4th menu item"
  screen.add-item "Option D"
  screen.render
  
  sleep (Duration --s=2)

  print "📋 Time to go home..."
  screen.set-title "Heading home..."
  screen.render
  
  sleep (Duration --s=2)
  
  print "🏠 Showing device home page"
  screen.draw-home