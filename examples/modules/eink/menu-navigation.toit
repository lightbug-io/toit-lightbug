import lightbug.devices as devices
import lightbug.messages as messages

// Demonstrates navigation between two complete e-ink pages.
//
// The menu is rendered by the device. Its normal selection controls are used
// to choose an item; press the Action button to open the text page. Press the
// Left / Up button from the text page to return to the menu.
//
// PAGE-MENU and PAGE-TEXT are intentionally different. Changing page ID, and
// the explicit full redraw below, clears the display buffer before the text
// page is drawn. This makes it easy to confirm that no menu pixels remain.
PAGE-MENU ::= 40
PAGE-TEXT ::= 41

MENU-ITEMS ::= ["Open text page", "Another menu item"]

main:
  device := devices.I2C --background=false
  showing-text-page := false

  show-menu := ::
    print "Showing menu"
    // Returning to a different page ID causes the device to clear and fully
    // redraw the screen before displaying the menu.
    device.eink.send-menu --page-id=PAGE-MENU --items=MENU-ITEMS --selected-item=0
    showing-text-page = false

  show-text-page := ::
    print "Opening text page; the menu is cleared first"
    device.eink.text-page
        --page-id=PAGE-TEXT
        --page-title="Text page"
        --lines=["The menu is completely gone.", "This is a fresh full redraw.", "", "Left / Up: return to menu"]
        --status-bar-enable=false
        --full
    showing-text-page = true

  show-menu.call

  device.buttons.subscribe --timeout=null --callback=(:: |button-data/messages.ButtonPress|
    // Ignore release/empty events; only act on a completed press.
    if button-data.duration > 0:
      if showing-text-page:
        if button-data.button-id == messages.ButtonPress.BUTTON-ID_UP_LEFT:
          show-menu.call
      else if button-data.button-id == messages.ButtonPress.BUTTON-ID_ACTION:
        // The device has already handled the menu selection. For this small
        // example every menu item opens the same text page.
        show-text-page.call
  )

  while true:
    sleep --ms=60000
