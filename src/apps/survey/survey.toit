import ...devices
import ...messages.messages_gen as messages
import ...protocol as protocol
import ...modules.eink.menu-selection show MenuSelection
import ...modules.comms.message-handler show MessageHandler
import ...modules.comms.generic-handler show GenericHandler
import log
import net
import net.wifi
import http
import monitor
import coordinate show Coordinate
import crypto.sha1 show sha1
import system.firmware
import system.api.network show NetworkService NetworkServiceClient
import watchdog show Watchdog

import .eink-batch show eink-do-batch
import .strobe-once show strobe-once
import ..apps show Apps

HTTP-POLL := 1500
AP-NAME := "LB-RH2"
AP-PASS := "12345678"

TOP-PAD := 12
POINT-STORE-MAX := 100

// TODO provide these as part of the higher level page stuff?
SMALL-TEXT-SPACING := 11
NORMAL-TEXT-SPACING := 18

class SurveyApp:

  // TODO put these somewhere reusable..
  static screen-width ::= 250
  static screen-height ::= 122

  static PAGE-SURVEY ::= 31
  static PAGE-MENU-ACTIONS ::= 32
  static PAGE-INFO ::= 33
  // TODO make a page to view ALL? of the stored locations?!

  static MENU-TEXT-RTK-OFF ::= "RTKOff"
  static MENU-TEXT-RTK-ON ::= "RTKOn"
  static MENU-TEXT-MODE-ON-Button ::= "ModeButton"
  static MENU-TEXT-MODE-Continuous ::= "ModeCont."
  static MENU-TEXT-DIST-1M ::= "Auto1m"
  static MENU-TEXT-DIST-5M ::= "Auto5m"
  static MENU-TEXT-DIST-10M ::= "Auto10m"
  static MENU-TEXT-START ::= "Start Survey"
  static MENU-TEXT-BACK ::= "Go Back"
  static MENU-TEXT-CLEAR-POINTS ::= "Clear Points"
  static MENU-TEXT-SEND ::= "Send to cloud"
  static MENU-TEXT-STOP ::= "Stop"
  static MENU-TEXT-EXIT ::= "Exit"

  static TEXT-CURR ::= "Curr:"
  static TEXT-PREV ::= "Prev:"
  static TEXT-LAST ::= "Last:"
  static TEXT-STORE ::= "Store"

  static WIFI-CLIENT ::= "WiFi"
  static WIFI-AP ::= "WiFi AP"

  device_/Device
  parent_/Apps? := null
  dog_/Watchdog? := null

  is-running_/bool := false
  is-surveying_/bool := false
  showing-page_/int := 0
  last-selected-rtk_/string? := null
  last-selected-mode_/string? := null
  last-selected-dist_/string? := null
  last-selected-wifi_/string? := null
  // Mode can be Button (store on press) or Continuous (store automatically when moved >=5m)
  last-received-position_/messages.Position? := null
  last-share-code_/string? := null

  buttons-subscriber-id_/int? := null
  position-handler_/GenericHandler? := null

  menu-selection/MenuSelection? := null
  action-menu-options_/List := []
  
  BUTTON-LEFT-INFO := "Info"
  device-button-left := ""

  BUTTON-MIDDLE-START := "Start"
  BUTTON-MIDDLE-STORE := TEXT-STORE
  BUTTON-MIDDLE-CONTINIOUS := "Cont."
  device-button-middle := ""

  BUTTON-RIGHT-ACTIONS := "Actions"
  device-button-right := ""

  // HTTP server fields
  network_/net.Interface? := null
  tcp_socket_ := null
  http_server_/http.Server? := null
  http_task_/Task? := null

  // List of messages.Position
  // For now just in memory, later this could be persisted in flash, or instantly sent out to a server...
  point-store_/List := []
  point-store-dist_/float := 0.0
  // Distance threshold used in continuous mode when storing points
  store-last-point-dist_/float := 5.0

  logger_/log.Logger := log.default.with-name "survey"

  constructor device/Device parent/Apps dog/Watchdog:
    device_ = device
    parent_ = parent
    dog_ = dog
  
  // Basic app control, likely should be in a base and common interface?
  start:
    dog_.start --s=30
    is-running_ = true
    init-button-subscription_
    init-position-handler_

    rhash_ba := sha1 "$(Time.now.stringify)$(random 999999999)"
    rhash_hex := ""
    rhash_ba.do: |b|
      rhash_hex += "$(%02x b)" // TODO just limit to 10 here
    last-share-code_ = "$(rhash_hex)"[0..10] // share code is 10 chars of this hash for now

    task::
      request-chasm-link // todo probably just FAF this one... (Or do we want to close it on close too?)

    if not has-wifi-configured:
      logger_.info "No WiFi, start AP"
      // NO configured wifi, so we assume we are in production, and will want an AP, so set it up now...
      // TODO consider using the device ID..?!
      network_ = wifi.establish
        --ssid=AP-NAME
        --password=AP-PASS
      last-selected-wifi_ = WIFI-AP
    else:
      logger_.info "WiFi, start CL"
      last-selected-wifi_ = WIFI-CLIENT
      network_ = net.open

    init-webserver_

    menu-selection = null
    last-selected-rtk_ = MENU-TEXT-RTK-ON
    last-selected-mode_ = MENU-TEXT-MODE-ON-Button
    last-selected-dist_ = MENU-TEXT-DIST-5M

    device-button-left = BUTTON-LEFT-INFO
    device-button-middle = BUTTON-MIDDLE-START
    device-button-right = BUTTON-RIGHT-ACTIONS

    action-menu-options_ = [
      MENU-TEXT-BACK,
      MENU-TEXT-CLEAR-POINTS,
      MENU-TEXT-SEND,
      last-selected-rtk_,
      last-selected-mode_,
      last-selected-dist_,
      MENU-TEXT-STOP,
      MENU-TEXT-EXIT,
    ]

  stop:
    dog_.stop
    is-running_ = false
    survey-stop
    deinit-webserver_
    deinit-button-subscriber_
    deinit-position-handler_

    if network_:
      e := catch:
        network_.close
      if e:
        logger_.warn "Failed to close network: $e"
      network_ = null

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
          // TODO there should be a flash abstraction for strobe..
          // TODO ideally this should use the corner LEDs to be consistent with the device FW button presses in menus
          task::
            strobe-once:
              device_.strobe.blue
              sleep --ms=50
              device_.strobe.off
          // Delegate to shared handler
          task:: handle-button-press button-data
      )

      if id:
        buttons-subscriber-id_ = id

  init-position-handler_:
    // Register a handler for locations too
    // TODO factor out GenericHandler to somewhere as CallbackHandler?
    position-handler_ = GenericHandler --callback=(:: |a-msg|
      feed
      // TODO we only continue to listen on 2 pages right now, but likely we just always want to listen
      // unless the handler itself is unregistered (we exit this app?) which is not currently done..
      if showing-page_ == PAGE-SURVEY or showing-page_ == PAGE-MENU-ACTIONS or showing-page_ == PAGE-INFO:
        if a-msg.type == messages.Position.MT:
          pos := messages.Position.from-data a-msg.data
          last-received-position_ = pos
          screen-on-new-pos pos
          // If in continuous mode and surveying, store points when moved >=5m
          if is-surveying_ and last-selected-mode_ == MENU-TEXT-MODE-Continuous:
            store-last-point-on-dist-change store-last-point-dist_
    )
    device_.comms.register-handler position-handler_

  init-webserver_:
    if http_server_:
      deinit-webserver_ // deinit first..
    http_e := catch:
      tcp_socket := network_.tcp_listen 80
      tcp_socket_ = tcp_socket
      server := http.Server --logger=((log.default.with-name "survey-http").with-level log.WARN-LEVEL) --max-tasks=5
      http_server_ = server
      http_task_ = task::
        e2 := catch:
            server.listen tcp_socket:: | request/http.RequestIncoming writer/http.ResponseWriter |
              resource := request.query.resource
              params := request.query.parameters

              if resource == "/":
                content_fragment := generate-content-fragment
                version_ba := sha1 content_fragment
                version_hex := ""
                version_ba.do: |b|
                  version_hex += "$(%02x b)"

                js := "<script>\n(function(){let busy=false; let version=\"" + version_hex + "\"; function poll(){ if(busy) return; busy=true; fetch('/poll?since='+version).then(r=>{ if(r.status==200){ let newVersion = r.headers.get('X-Content-Version') || '0'; r.text().then(t=>{ document.getElementById('content').innerHTML = t; version = newVersion; }).catch(()=>{}); } }).catch(()=>{}).finally(()=>{ busy=false; setTimeout(poll,$(HTTP-POLL)); }); } setTimeout(poll,$(HTTP-POLL));})();\n</script>"

                html := "<html><head><meta charset=\"utf-8\"></head><body><div id=\"content\">" + content_fragment + "</div>" + js + "</body></html>"
                writer.headers.set "Content-Type" "text/html; charset=utf-8"
                writer.write_headers 200
                writer.out.write html
                writer.close

              else if resource == "/poll":
                content_fragment := generate-content-fragment
                version_ba := sha1 content_fragment
                version_hex := ""
                version_ba.do: |b|
                  version_hex += "$(%02x b)"

                since_param := params["since"]
                // log.debug "Poll request since=$since_param current=$version_hex"
                if since_param != null and since_param == version_hex:
                  writer.write_headers 204
                  writer.close
                else:
                  writer.headers.set "Content-Type" "text/html; charset=utf-8"
                  writer.headers.set "X-Content-Version" "$version_hex"
                  writer.write_headers 200
                  writer.out.write content_fragment
                  writer.close

              else if resource == "/button":
                // Emulate a button press via HTTP. Accept numeric ids only
                // for physical button emulation.
                idparam := params["id"]
                if idparam == null:
                  writer.write_headers 404
                  writer.close
                else:
                  // Parse id as integer; on parse failure return 404.
                  parse_e := catch:
                    parsed := int.parse idparam
                    parsed
                  if parse_e == null:
                    btnid := int.parse idparam
                    data := messages.ButtonPress.data --button-id=btnid --duration=500
                    bp := messages.ButtonPress.from-data data
                    // Call shared handler
                    task:: handle-button-press bp
                    writer.write_headers 200
                    writer.out.write "OK"
                    writer.close
                  else:
                    writer.write_headers 404
                    writer.close

              else if resource == "/action":
                // Trigger action shortcuts (done / clear) from the web UI.
                idparam := params["id"]
                if idparam == null:
                  writer.write_headers 404
                  writer.close
                else:
                  writer.write_headers 200
                  writer.out.write "ACTING"
                  writer.close
                  label := idparam
                  if label == MENU-TEXT-EXIT:
                    stop
                  else if label == MENU-TEXT-STOP:
                    survey-stop
                    show-survey
                  else if label == MENU-TEXT-CLEAR-POINTS:
                    clear-points
                    show-survey
                  else if label == MENU-TEXT-BACK:
                    show-survey
                  else if label == MENU-TEXT-SEND:
                    // Trigger sending stored points to the link
                    task:: send-points-to-link
                  else if label == MENU-TEXT-RTK-ON:
                    last-selected-rtk_ = MENU-TEXT-RTK-OFF
                    action-menu-options_[3] = last-selected-rtk_ // RTK index
                    rtk-off
                    update-actions-menu
                  else if label == MENU-TEXT-RTK-OFF:
                    last-selected-rtk_ = MENU-TEXT-RTK-ON
                    action-menu-options_[3] = last-selected-rtk_ // RTK index
                    rtk-on
                    update-actions-menu
                  else if label == MENU-TEXT-MODE-ON-Button:
                    // switch to Continuous
                    last-selected-mode_ = MENU-TEXT-MODE-Continuous
                    action-menu-options_[4] = last-selected-mode_ // MODE index
                    if is-surveying_:
                      // Update middle button label to continuous
                      device-button-middle = BUTTON-MIDDLE-CONTINIOUS
                    else:
                      device-button-middle = BUTTON-MIDDLE-START
                    update-actions-menu
                    screen-on-button-change
                  else if label == MENU-TEXT-MODE-Continuous:
                    // switch to Button
                    last-selected-mode_ = MENU-TEXT-MODE-ON-Button
                    action-menu-options_[4] = last-selected-mode_ // MODE index
                    if is-surveying_:
                      // Update middle button label to store
                      device-button-middle = BUTTON-MIDDLE-STORE
                    else:
                      device-button-middle = BUTTON-MIDDLE-START
                    update-actions-menu
                    screen-on-button-change
                  else if label == MENU-TEXT-DIST-5M:
                    // Cycle to 1m
                    last-selected-dist_ = MENU-TEXT-DIST-1M
                    action-menu-options_[5] = last-selected-dist_ // DIST index
                    store-last-point-dist_ = 1.0
                    update-actions-menu
                    screen-on-button-change
                  else if label == MENU-TEXT-DIST-1M:
                    // Cycle to 10m
                    last-selected-dist_ = MENU-TEXT-DIST-10M
                    action-menu-options_[5] = last-selected-dist_
                    store-last-point-dist_ = 10.0
                    update-actions-menu
                    screen-on-button-change
                  else if label == MENU-TEXT-DIST-10M:
                    // Cycle back to 5m (default)
                    last-selected-dist_ = MENU-TEXT-DIST-5M
                    action-menu-options_[5] = last-selected-dist_
                    store-last-point-dist_ = 5.0
                    update-actions-menu
                    screen-on-button-change

              else:
                writer.write_headers 404
                writer.close
        if e2:
          logger_.warn "Survey HTTP server task error: $e2"
    if http_e:
      logger_.warn "Failed to start survey HTTP server: $http_e"

  deinit-button-subscriber_:
    // Unsubscribe from buttons if we have a subscriber id
    if buttons-subscriber-id_:
      e := catch: device_.buttons.unsubscribe --subscriber-id=buttons-subscriber-id_ --timeout=null
      if e:
        logger_.warn "Failed to unsubscribe from buttons: $e"
      // Ignore errors from unsubscribe but clear our id.
      buttons-subscriber-id_ = null

  deinit-position-handler_:
    if position-handler_:
      e := catch: device_.comms.unregister-handler position-handler_
      if e:
        logger_.warn "Failed to unregister position handler: $e"
      // Ignore errors but clear our handler
      position-handler_ = null

  deinit-webserver_:
    // Stop HTTP server if running
    if http_server_:
      // There's no direct close on Server; closing the TCP socket stops listen.
      http_server_ = null
    if tcp_socket_:
      e := catch:
        tcp_socket_.close
      if e:
        logger_.warn "Failed to close tcp socket: $e"
      tcp_socket_ = null
    if http_task_:
      e := catch:
        http_task_.cancel
      if e:
        logger_.warn "Failed to cancel http task: $e"
      http_task_ = null

  show-actions-menu:
    eink-do-batch --important:
      showing-page_ = PAGE-MENU-ACTIONS
      device_.eink.send-menu --page-id=PAGE-MENU-ACTIONS  --items=action-menu-options_ --selected-item=0
      menu-selection = MenuSelection --start=0 --size=action-menu-options_.size
  
  update-actions-menu:
    eink-do-batch --important:
      if showing-page_ == PAGE-MENU-ACTIONS:
        device_.eink.send-menu --page-id=PAGE-MENU-ACTIONS --items=action-menu-options_ --selected-item=menu-selection.current

  show-info-page:
    eink-do-batch --important:
      device-ip := "Unknown"
      wifi-ssid := "Unknown"
      conn-type := "Unknown"
      if last-selected-wifi_ != null:
        conn-type = last-selected-wifi_

      // Get info from the current connection
      e := catch --trace:
        if conn-type != "Unknown":
          // Try and get the device IP address
          catch --trace:
            device-ip = "$(network_.address)"
      if e:
        logger_.warn "WiFi info: $e"
      
      // Try to get current Wifi details
      e = catch --trace:
        effective := firmware.config["wifi"]
        if effective != null:
          wifi-ssid = effective.get wifi.CONFIG-SSID
      if e:
        logger_.warn "WiFi config: $e"

      info-items := [
        MENU-TEXT-BACK,
        "Share$(last-share-code_)",
        "Conn$conn-type",
        ]
      if conn-type != "None":
        info-items.add "IP$device-ip"
      if conn-type == WIFI-CLIENT:
        info-items.add "WiFi Net$wifi-ssid"
      if conn-type == WIFI-AP:
        info-items.add "AP Name$(AP-NAME)"
        info-items.add "AP Pass$(AP-PASS)"

      showing-page_ = PAGE-INFO
      device_.eink.send-menu --page-id=PAGE-INFO --items=info-items --selected-item=0
      menu-selection = MenuSelection --start=0 --size=info-items.size

  // Check if we have WiFi configured..
  // We assume that production devices WILL NOT have this configured
  has-wifi-configured -> bool:
    // Check if we have wifi configured (for web server)
    effective := firmware.config["wifi"]
    if effective == null:
      return false
    ssid := effective.get wifi.CONFIG-SSID
    if ssid != null and ssid != "":
      return true
    return false
  
  survey-start:
    if is-surveying_:
      return

    is-surveying_ = true

    // audible beep to indicate start
    device_.piezo.med --ms=100

    // If continuous mode, middle button is just a label and does nothing
    if last-selected-mode_ == MENU-TEXT-MODE-Continuous:
      device-button-middle = BUTTON-MIDDLE-CONTINIOUS
    else:
      device-button-middle = BUTTON-MIDDLE-STORE
    
    show-survey // Initial full redraw of survey page / with it started

    if last-selected-rtk_ == MENU-TEXT-RTK-ON:
      rtk-on
    else:
      rtk-off
    
    // Subscribe to position every second
    // TODO refactor GNSS subscription to allow multiple subscribers? (Like is done for buttons)
    device_.gnss.subscribe-position --interval=1000
  
  survey-stop:
    if not is-surveying_:
      return
    is-surveying_ = false

    // audible beep to indicate start
    device_.piezo.low --ms=500

    device-button-middle = BUTTON-MIDDLE-START
    rtk-off
    device_.gnss.unsubscribe-position
  
  rtk-on:
    device_.gnss.set-gps-control --corrections-enabled=messages.GPSControl.CORRECTIONS-ENABLED_FULL-RTCM-STREAM
  
  rtk-off:
    device_.gnss.set-gps-control --corrections-enabled=messages.GPSControl.CORRECTIONS-ENABLED_DISABLED

  show-survey:
    eink-do-batch --important:
      // Buttons
      device_.eink.draw-element --page-id=PAGE-SURVEY --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --textalign=messages.DrawElement.TEXTALIGN_MIDDLE --width=(screen-width / 3) --x=0 --y=(screen-height - 15) --text=device-button-left --redraw-type=messages.DrawElement.REDRAW-TYPE-BUFFERONLY
      device_.eink.draw-element --page-id=PAGE-SURVEY --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --textalign=messages.DrawElement.TEXTALIGN_MIDDLE --width=(screen-width / 3) --x=(screen-width / 3) --y=(screen-height - 15) --text=device-button-middle --redraw-type=messages.DrawElement.REDRAW-TYPE-BUFFERONLY
      device_.eink.draw-element --page-id=PAGE-SURVEY --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --textalign=messages.DrawElement.TEXTALIGN_MIDDLE --width=(screen-width / 3) --x=((screen-width * 2 ) / 3) --y=(screen-height - 15) --text=device-button-right --redraw-type=messages.DrawElement.REDRAW-TYPE-BUFFERONLY

      // Survey info...
      device_.eink.draw-element --page-id=PAGE-SURVEY --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --x=0 --y=(TOP-PAD + NORMAL-TEXT-SPACING) --text=text-for-curr-line --fontsize=0 --textalign=messages.DrawElement.TEXTALIGN_LEFT --width=screen-width --redraw-type=messages.DrawElement.REDRAW-TYPE-BUFFERONLY
      device_.eink.draw-element --page-id=PAGE-SURVEY --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --x=0 --y=(TOP-PAD + NORMAL-TEXT-SPACING + SMALL-TEXT-SPACING*1) --text=text-for-last-line --fontsize=0 --textalign=messages.DrawElement.TEXTALIGN_LEFT --width=screen-width --redraw-type=messages.DrawElement.REDRAW-TYPE-BUFFERONLY
      device_.eink.draw-element --page-id=PAGE-SURVEY --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --x=0 --y=(TOP-PAD + NORMAL-TEXT-SPACING + SMALL-TEXT-SPACING*2) --text=text-for-prev-line --fontsize=0 --textalign=messages.DrawElement.TEXTALIGN_LEFT --width=screen-width --redraw-type=messages.DrawElement.REDRAW-TYPE-BUFFERONLY
      device_.eink.draw-element --page-id=PAGE-SURVEY --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --x=0 --y=(TOP-PAD + NORMAL-TEXT-SPACING + SMALL-TEXT-SPACING*3) --text=text-for-fix-line --fontsize=0 --textalign=messages.DrawElement.TEXTALIGN_LEFT --width=screen-width --redraw-type=messages.DrawElement.REDRAW-TYPE-BUFFERONLY
      device_.eink.draw-element --page-id=PAGE-SURVEY --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --x=0 --y=(TOP-PAD + NORMAL-TEXT-SPACING + SMALL-TEXT-SPACING*4) --text=text-for-stored-line --fontsize=0 --textalign=messages.DrawElement.TEXTALIGN_LEFT --width=screen-width --redraw-type=messages.DrawElement.REDRAW-TYPE-BUFFERONLY
      device_.eink.draw-element --page-id=PAGE-SURVEY --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --x=0 --y=(TOP-PAD + NORMAL-TEXT-SPACING + SMALL-TEXT-SPACING*5) --text=text-for-dist-line --fontsize=0 --textalign=messages.DrawElement.TEXTALIGN_LEFT --width=screen-width --redraw-type=messages.DrawElement.REDRAW-TYPE-BUFFERONLY

      // Title
      device_.eink.draw-element --page-id=PAGE-SURVEY --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --x=0 --y=0 --text=text-for-title --fontsize=1 --redraw-type=messages.DrawElement.REDRAW-TYPE_FULLREDRAWWITHOUTCLEAR

      // Update state after draws...
      showing-page_ = PAGE-SURVEY

  screen-on-button-change:
    eink-do-batch --important:
      if showing-page_ == PAGE-SURVEY:
        device_.eink.draw-element --page-id=PAGE-SURVEY --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --textalign=messages.DrawElement.TEXTALIGN_MIDDLE --width=(screen-width / 3) --x=0 --y=(screen-height - 15) --text=device-button-left --redraw-type=messages.DrawElement.REDRAW-TYPE-BUFFERONLY
        device_.eink.draw-element --page-id=PAGE-SURVEY --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --textalign=messages.DrawElement.TEXTALIGN_MIDDLE --width=(screen-width / 3) --x=(screen-width / 3) --y=(screen-height - 15) --text=device-button-middle --redraw-type=messages.DrawElement.REDRAW-TYPE-BUFFERONLY
        device_.eink.draw-element --page-id=PAGE-SURVEY --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --textalign=messages.DrawElement.TEXTALIGN_MIDDLE --width=(screen-width / 3) --x=((screen-width * 2 ) / 3) --y=(screen-height - 15) --text=device-button-right --redraw-type=messages.DrawElement.REDRAW-TYPE-PARTIALREDRAW

  screen-on-new-pos pos/messages.Position:
    eink-do-batch: // not a --important eink update..
      if showing-page_ == PAGE-SURVEY:
        device_.eink.draw-element --page-id=PAGE-SURVEY --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --x=0 --y=(TOP-PAD + NORMAL-TEXT-SPACING + SMALL-TEXT-SPACING*3) --text=text-for-fix-line --fontsize=0 --textalign=messages.DrawElement.TEXTALIGN_LEFT --width=screen-width --redraw-type=messages.DrawElement.REDRAW-TYPE-BUFFERONLY
        device_.eink.draw-element --page-id=PAGE-SURVEY --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --x=0 --y=(TOP-PAD + NORMAL-TEXT-SPACING) --text=text-for-curr-line --fontsize=0 --textalign=messages.DrawElement.TEXTALIGN_LEFT --width=screen-width --redraw-type=messages.DrawElement.REDRAW-TYPE-PARTIALREDRAW

  // Updates the Last, prev and metric lines on the page, when a new value is stored
  screen-on-new-store:
    eink-do-batch --important: // Important, as this is after a user action (on button press). We could afford to skip some in cont mode?
      if showing-page_ == PAGE-SURVEY and is-surveying_:
        device_.eink.draw-element --page-id=PAGE-SURVEY --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --x=0 --y=(TOP-PAD + NORMAL-TEXT-SPACING + SMALL-TEXT-SPACING*1) --text=text-for-last-line --fontsize=0 --textalign=messages.DrawElement.TEXTALIGN_LEFT --width=screen-width --redraw-type=messages.DrawElement.REDRAW-TYPE-BUFFERONLY
        device_.eink.draw-element --page-id=PAGE-SURVEY --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --x=0 --y=(TOP-PAD + NORMAL-TEXT-SPACING + SMALL-TEXT-SPACING*2) --text=text-for-prev-line --fontsize=0 --textalign=messages.DrawElement.TEXTALIGN_LEFT --width=screen-width --redraw-type=messages.DrawElement.REDRAW-TYPE-BUFFERONLY
        device_.eink.draw-element --page-id=PAGE-SURVEY --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --x=0 --y=(TOP-PAD + NORMAL-TEXT-SPACING + SMALL-TEXT-SPACING*3) --text=text-for-fix-line --fontsize=0 --textalign=messages.DrawElement.TEXTALIGN_LEFT --width=screen-width --redraw-type=messages.DrawElement.REDRAW-TYPE-BUFFERONLY
        device_.eink.draw-element --page-id=PAGE-SURVEY --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --x=0 --y=(TOP-PAD + NORMAL-TEXT-SPACING + SMALL-TEXT-SPACING*4) --text=text-for-stored-line --fontsize=0 --textalign=messages.DrawElement.TEXTALIGN_LEFT --width=screen-width --redraw-type=messages.DrawElement.REDRAW-TYPE-BUFFERONLY
        device_.eink.draw-element --page-id=PAGE-SURVEY --status-bar-enable=true --type=messages.DrawElement.TYPE_BOX --x=0 --y=(TOP-PAD + NORMAL-TEXT-SPACING + SMALL-TEXT-SPACING*5) --text=text-for-dist-line --fontsize=0 --textalign=messages.DrawElement.TEXTALIGN_LEFT --width=screen-width --redraw-type=messages.DrawElement.REDRAW-TYPE-PARTIALREDRAW

  text-for-title:
    if is-surveying_:
      return "Surveying..."
    return "Survey App"
  
  // Toit will round down as part of a stringify, so we clamp to 0.01 minimum
  // as 0.00 for dispaly is missleading
  text-for-accuracy pos/messages.Position -> string:
    if pos.latitude == 0.0 or pos.longitude == 0.0:
      return "N/A"
    if pos.accuracy >= 0.005:
      return "$(pos.accuracy.stringify 2)m"
    return "0.01m"
  
  fixed-accuracy-from-message pos/messages.Position -> float:
    if pos == null:
      return 0.0
    // Sometimes device will continue sending old accuracy, even if we don't have a position
    // TODO fix in STM
    accuracy := pos.accuracy
    if pos.latitude == 0.0 or pos.longitude == 0.0:
      accuracy = 0.0
    return accuracy

  text-for-curr-line:
    if not is-surveying_ or last-received-position_ == null:
      return "Cur: No position"
    
    accuracy := fixed-accuracy-from-message last-received-position_
    // Sometimes we get 0.00 accuracy, at rtk-fix...
    // if not IGNORE-NO-FIX and ( accuracy == 0.0 or accuracy >= 1000 ):
    if accuracy >= 1000 or last-received-position_.latitude == 0.0:
      return "$(TEXT-CURR) ..."
    return "$(TEXT-CURR) $(text-for-pos last-received-position_)"

  text-for-last-line:
    if point-store_.size == 0:
      return "$(TEXT-LAST)"
    return "$(TEXT-LAST) $(text-for-pos point-store_[point-store_.size - 1])"
  
  text-for-prev-line:
    if point-store_.size <= 1:
      return "$(TEXT-PREV)"
    return "$(TEXT-PREV) $(text-for-pos point-store_[point-store_.size - 2])"
  
  text-for-fix-line:
    if not is-surveying_ or last-received-position_ == null:
      return "Waiting..." // Evil padding to make it clear previous values
    return "Sats: $(last-received-position_.satellites) | Acc: $(text-for-accuracy last-received-position_) | Fix: $(messages.Position.type-from-int last-received-position_.type)"

  text-for-stored-line:
    full-text := ""
    if point-store_.size >= POINT-STORE-MAX:
      full-text = " FULL! "
    return "Stored: $(point-store_.size) points / $(POINT-STORE-MAX) $(full-text)"
  
  text-for-dist-line:
    return "Distance: $(point-store-dist_.stringify 2)m"

  generate-content-fragment -> string:
    body := ""
    if showing-page_ == PAGE-MENU-ACTIONS or showing-page_ == PAGE-INFO:
      body = "In a menu\n"
    else:
      body = "$(text-for-title)\n"
      body = "$body$(text-for-curr-line)\n"
      body = "$body$text-for-last-line\n"
      body = "$body$text-for-prev-line\n"
      body = "$body$text-for-fix-line\n"
      body = "$body$text-for-stored-line\n"
      body = "$body$text-for-dist-line\n\n"

      count := point-store_.size
      showcount := if count > 10: 10 else: count
      if showcount > 0:
        body = body + "Last $(showcount) stored locations:\n"
        start_idx := count - 1
        i := start_idx
        while i >= (count - showcount):
          p := point-store_[i]
          s := text-for-pos p
          body = body + "- $s\n"
          i -= 1

    left_id := messages.ButtonPress.BUTTON-ID_LEFT-UP.stringify
    select_id := messages.ButtonPress.BUTTON-ID_ACTION.stringify
    right_id := messages.ButtonPress.BUTTON-ID_RIGHT-DOWN.stringify

    left_label := if showing-page_ == PAGE-SURVEY: device-button-left else: "Up"
    middle_label := if showing-page_ == PAGE-SURVEY: device-button-middle else: "Select"
    right_label := if showing-page_ == PAGE-SURVEY: device-button-right else: "Down"

    btn_prefix := "<div>"
    btn_suffix := "</button> "
    btn_close := "</div>"
    btn_left := "<button onclick=\"fetch('/button?id=" + left_id + "')\">"
    // If middle label indicates continuous mode, render it non-clickable on the web UI
    btn_mid := if middle_label == BUTTON-MIDDLE-CONTINIOUS: "<button>" else: "<button onclick=\"fetch('/button?id=" + select_id + "')\">"
    btn_right := "<button onclick=\"fetch('/button?id=" + right_id + "')\">"
    buttons := btn_prefix + btn_left + left_label + btn_suffix + btn_mid + middle_label + btn_suffix + btn_right + right_label + btn_suffix + btn_close

    action_buttons := "<div style=\"margin-top:6px\">"
    i := 0
    while i < action-menu-options_.size:
      lbl := action-menu-options_[i]
      action_buttons = action_buttons + "<button onclick=\"fetch('/action?id='+encodeURIComponent(this.innerText))\">" + lbl + "</button> "
      i += 1
    action_buttons = action_buttons + "</div>"

    return buttons + action_buttons + "<pre>" + body + "</pre>"

  // Convert a position to a string suitable for display on screen
  // Example: 0.00000 0.000000 0.00
  text-for-pos pos/messages.Position-> string:
    if pos == null:
      return "none"
    return "$(pos.latitude.stringify 6) $(pos.longitude.stringify 6) $(text-for-accuracy pos)"

  store-last-point:
    if showing-page_ != PAGE-SURVEY:
      return
    if last-received-position_ == null:
      return
    // Sometimes we get 0.00 accuracy, at rtk-fix...
    // if not IGNORE-NO-FIX and ( last-received-position_.accuracy == 0.0 or last-received-position_.accuracy >= 1000 ):
    if last-received-position_.accuracy >= 1000 or last-received-position_.latitude == 0.0:
      return

    if point-store_.size >= POINT-STORE-MAX:
      log.warn "POINTS@$(point-store_.size)"
      device_.haptics.pulse --intensity=messages.HapticsControl.INTENSITY_LOW
      return
    else:
      device_.haptics.drop --intensity=messages.HapticsControl.INTENSITY_LOW

    point-store_.add last-received-position_
    // Increase distance calc...
    if point-store_.size >= 2:
      last := point-store_[point-store_.size - 1]  
      prev := point-store_[point-store_.size - 2]
      last-coord := Coordinate last.latitude last.longitude
      prev-coord := Coordinate prev.latitude prev.longitude
      dist := last-coord.distance-to-coord prev-coord
      point-store-dist_ += dist
    screen-on-new-store

  store-last-point-on-dist-change distance/float:
    // Must be surveying and have a last received position
    if not is-surveying_:
      return
    if last-received-position_ == null:
      return
    // Validate accuracy using helper
    acc := fixed-accuracy-from-message last-received-position_
    if acc == 0.0:
      // invalid fix; do nothing
      return

    if point-store_.size == 0:
      store-last-point
      return

    // Compare to last stored point
    last := point-store_[point-store_.size - 1]
    last-coord := Coordinate last.latitude last.longitude
    curr-coord := Coordinate last-received-position_.latitude last-received-position_.longitude
    dist := curr-coord.distance-to-coord last-coord
    if dist >= distance:
      store-last-point

  clear-points:
    point-store_ = []
    point-store-dist_ = 0.0
    last-received-position_ = null
  
  request-chasm-link:
    // TODO higher level LINK API...

    // Request link connection
    msg := messages.LinkControl.set-msg --base-data=(messages.LinkControl.data --enable=true)
    r := device_.comms.send-new msg
  
  sending-points-to-device_ := false

  send-points-to-link:
    if point-store_.size == 0:
      return
    if sending-points-to-device_:
      return
    sending-points-to-device_ = true
    request-chasm-link

    i := 0
    while i < point-store_.size:
      send-point-to-link point-store_[i]
      i += 1
    sending-points-to-device_ = false

  link-send-sem := monitor.Semaphore --count=5 --limit=5

  send-point-to-link pos/messages.Position --retries_/int=3:
    link-send-sem.down // acquire semaphore slot
    // TODO Position should have a normal ".msg" method too
    ptmsg := protocol.Message.with-data messages.Position.MT pos
    ptmsg = add-forwarding-headers ptmsg
    callback := (::
      link-send-sem.up // release semaphore slot
      if (it == null or not it.msg-ok) and retries_ > 1:
        retries_ -= 1
        logger_.warn "CLOUD point retry..."
        sleep --ms=1000
        send-point-to-link pos --retries_=retries_
      else if it != null and it.msg-ok:
        strobe-once:
          device_.strobe.green
          sleep --ms=50
          device_.strobe.off
      else:
        logger_.warn "CLOUD point FAIL"
        strobe-once:
          device_.strobe.red
          sleep --ms=50
          device_.strobe.off
    )
    // XXX: Evil? As it makes a new message id each resend
    // This should be pushed down some levels...
    device_.comms.send-new ptmsg --async --timeout=(Duration --ms=5000) --callback=callback
    
  add-forwarding-headers msg/protocol.Message -> protocol.Message:
    // 0 is the default lightbug link
    msg.header.data.add-data-uint8 protocol.Header.TYPE-FORWARD-TO 0
    msg.header.data.add-data-ascii 50 "pub" // Application that the message is targeting?
    msg.header.data.add-data-ascii 51 "%d-$(last-share-code_)" // Application meta field 1... (up to 20 bytes)
    return msg

  // Shared button handling so physical and HTTP-triggered presses call same logic
  handle-button-press button-data/messages.ButtonPress:
    if not is-running_:
      // If we are not running, ignore button presses
      // The handler should not be subscribed if we are not running, but just in case
      return
    if button-data.duration <= 0:
      // Not actually a press... ignore
      return
    else if button-data.duration >= 3000: // Stop and go home
      stop
      return
    
    // Survey page...
    if showing-page_ == PAGE-SURVEY:
      if button-data.button-id == messages.ButtonPress.BUTTON-ID_ACTION:
        if device-button-middle == BUTTON-MIDDLE-START:
          survey-start
        else if device-button-middle == BUTTON-MIDDLE-STORE:
          store-last-point
      else if button-data.button-id == messages.ButtonPress.BUTTON-ID_RIGHT-DOWN:
        show-actions-menu
      else if button-data.button-id == messages.ButtonPress.BUTTON-ID_LEFT-UP:
        show-info-page

    // Info page
    else if showing-page_ == PAGE-INFO:
      if button-data.button-id == messages.ButtonPress.BUTTON-ID_ACTION:
        if menu-selection.current == 0:
          show-survey
      else if button-data.button-id == messages.ButtonPress.BUTTON-ID_RIGHT-DOWN:
        menu-selection.up
      else if button-data.button-id == messages.ButtonPress.BUTTON-ID_LEFT-UP:
        menu-selection.down
    
    // Actions menu
    else if showing-page_ == PAGE-MENU-ACTIONS:
      if button-data.button-id == messages.ButtonPress.BUTTON-ID_ACTION:
        selected := action-menu-options_[menu-selection.current]
        if selected == MENU-TEXT-STOP:
          survey-stop
          show-survey
        if selected == MENU-TEXT-EXIT:
          stop
        else if selected == MENU-TEXT-CLEAR-POINTS:
          // TODO might be nice to show the number of points on the right, and have clear set that to 0, rather than go back to survey
          clear-points
          show-survey
        else if selected == MENU-TEXT-SEND:
          // Trigger sending stored points to the link
          task:: send-points-to-link
          show-survey
        else if selected == MENU-TEXT-BACK:
          show-survey
        else if selected == MENU-TEXT-RTK-ON:
          last-selected-rtk_ = MENU-TEXT-RTK-OFF
          action-menu-options_[menu-selection.current] = last-selected-rtk_
          rtk-off
          update-actions-menu
        else if selected == MENU-TEXT-RTK-OFF:
          last-selected-rtk_ = MENU-TEXT-RTK-ON
          action-menu-options_[menu-selection.current] = last-selected-rtk_
          rtk-on
          update-actions-menu
        else if selected == MENU-TEXT-MODE-ON-Button:
          last-selected-mode_ = MENU-TEXT-MODE-Continuous
          action-menu-options_[menu-selection.current] = last-selected-mode_
          // When switching to Continuous, middle button becomes a label and does nothing
          if is-surveying_:
            device-button-middle = BUTTON-MIDDLE-CONTINIOUS
          else:
            device-button-middle = BUTTON-MIDDLE-STORE
          update-actions-menu
          screen-on-button-change // As this could be triggered from http, when the menu isnt shown..
        else if selected == MENU-TEXT-MODE-Continuous:
          last-selected-mode_ = MENU-TEXT-MODE-ON-Button
          action-menu-options_[menu-selection.current] = last-selected-mode_
          if is-surveying_:
            device-button-middle = BUTTON-MIDDLE-STORE
          else:
            device-button-middle = BUTTON-MIDDLE-START
          update-actions-menu
          screen-on-button-change // As this could be triggered from http, when the menu isnt shown..
        else if selected == MENU-TEXT-DIST-5M:
          // Cycle to 1m
          last-selected-dist_ = MENU-TEXT-DIST-1M
          action-menu-options_[menu-selection.current] = last-selected-dist_
          store-last-point-dist_ = 1.0
          update-actions-menu
          screen-on-button-change
        else if selected == MENU-TEXT-DIST-1M:
          // Cycle to 10m
          last-selected-dist_ = MENU-TEXT-DIST-10M
          action-menu-options_[menu-selection.current] = last-selected-dist_
          store-last-point-dist_ = 10.0
          update-actions-menu
          screen-on-button-change
        else if selected == MENU-TEXT-DIST-10M:
          // Back to 5m
          last-selected-dist_ = MENU-TEXT-DIST-5M
          action-menu-options_[menu-selection.current] = last-selected-dist_
          store-last-point-dist_ = 5.0
          update-actions-menu
          screen-on-button-change
      else if button-data.button-id == messages.ButtonPress.BUTTON-ID_RIGHT-DOWN:
        menu-selection.up
      else if button-data.button-id == messages.ButtonPress.BUTTON-ID_LEFT-UP:
        menu-selection.down
    else:
      // logger_.info "Unhandled button press on unknown page"
