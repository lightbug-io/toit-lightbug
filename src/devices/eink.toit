import monitor
import log
import ..services as services
import ..messages.messages_gen as messages
import ..protocol as protocol

/**
Eink screen abstraction for Lightbug devices.

This interface provides a simplified way to work with eink screens,
handling the complexity of message construction and change tracking internally.
*/
interface Eink:
  /**
  Text content methods (setting these makes the screen show a text page)
  */
  set-title title/string --flush/bool=false
  set-line1 text/string --flush/bool=false
  set-line2 text/string --flush/bool=false
  set-line3 text/string --flush/bool=false
  set-line4 text/string --flush/bool=false
  set-line5 text/string --flush/bool=false
  set-lines --line1/string?=null --line2/string?=null --line3/string?=null --line4/string?=null --line5/string?=null --flush/bool=false

  /**
  Menu content methods (setting these makes the screen show a menu page)
  */
  set-items items/List --flush/bool=false
  add-item item/string --flush/bool=false
  set-initial-selection selection/int --flush/bool=false

  /**
  Bitmap overlay methods (these can be added to any page type)
  */
  add-bitmap --x/int --y/int --width/int --height/int --bitmap/ByteArray --flush/bool=false

  /**
  Rendering methods
  */
  render -> none       // Smart render (clear + build + redraw on first time, partial redraw otherwise)
  flush -> none        // Send BufferOnly to device
  partial-draw -> none // Send with PartialRedraw
  full-draw -> none    // Send with FullRedraw

  /**
  Special screen operations
  */
  draw-home -> none    // Show device home page

/**
Helper function to create an eink instance with comms.
Use this after creating comms to set up screen functionality.
*/
setup-eink comms/services.Comms --logger/log.Logger=(log.default.with-name "lb-eink") -> Eink:
  return BaseEink comms --logger=logger

class NoEink implements Eink:
  // Text content methods - all no-ops
  set-title title/string --flush/bool=false:
  set-line1 text/string --flush/bool=false:
  set-line2 text/string --flush/bool=false:
  set-line3 text/string --flush/bool=false:
  set-line4 text/string --flush/bool=false:
  set-line5 text/string --flush/bool=false:
  set-lines --line1/string?=null --line2/string?=null --line3/string?=null --line4/string?=null --line5/string?=null --flush/bool=false:
  
  // Menu content methods - all no-ops
  set-items items/List --flush/bool=false:
  add-item item/string --flush/bool=false:
  set-initial-selection selection/int --flush/bool=false:
  
  // Bitmap overlay methods - all no-ops
  add-bitmap --x/int --y/int --width/int --height/int --bitmap/ByteArray --flush/bool=false:
  
  // Rendering methods - all no-ops
  render -> none:
  flush -> none:
  partial-draw -> none:
  full-draw -> none:
  
  // Special screen operations - all no-ops
  draw-home -> none:

/**
Base eink implementation that handles communication with Lightbug devices.
*/
class BaseEink implements Eink:
  static PAGE-TYPE-NONE ::= 0
  static PAGE-TYPE-TEXT ::= 1
  static PAGE-TYPE-MENU ::= 2
  
  comms_/ services.Comms
  logger_/ log.Logger
  page-id_/ int := 1000
  
  // Page type tracking (last content type wins)
  page-type_/ int := PAGE-TYPE-NONE
  previous-page-type_/ int := PAGE-TYPE-NONE
  
  // Text content
  title_/ string := ""
  line1_/ string := ""
  line2_/ string := ""
  line3_/ string := ""
  line4_/ string := ""
  line5_/ string := ""
  
  // Menu content
  items_/ List := []
  initial-selection_/ int := 1
  
  // Bitmap overlays (these are additive)
  bitmaps_/ List := []
  
  // Change tracking
  title-changed_/ bool := false
  line1-changed_/ bool := false
  line2-changed_/ bool := false
  line3-changed_/ bool := false
  line4-changed_/ bool := false
  line5-changed_/ bool := false
  items-changed_/ bool := false
  selection-changed_/ bool := false
  bitmaps-changed_/ bool := false
  is-first-update_/ bool := true

  constructor comms/services.Comms --logger/log.Logger=(log.default.with-name "lb-eink"):
    comms_ = comms
    logger_ = logger

  // Text content methods (setting these makes the screen show a text page)
  set-line1 text/string --flush/bool=false:
    if line1_ != text:
      line1_ = text
      line1-changed_ = true
      if page-type_ != PAGE-TYPE-TEXT:
        page-type_ = PAGE-TYPE-TEXT
        clear-menu-content_
      if flush: this.flush
  
  set-line2 text/string --flush/bool=false:
    if line2_ != text:
      line2_ = text
      line2-changed_ = true
      if page-type_ != PAGE-TYPE-TEXT:
        page-type_ = PAGE-TYPE-TEXT
        clear-menu-content_
      if flush: this.flush
  
  set-line3 text/string --flush/bool=false:
    if line3_ != text:
      line3_ = text
      line3-changed_ = true
      if page-type_ != PAGE-TYPE-TEXT:
        page-type_ = PAGE-TYPE-TEXT
        clear-menu-content_
      if flush: this.flush
  
  set-line4 text/string --flush/bool=false:
    if line4_ != text:
      line4_ = text
      line4-changed_ = true
      if page-type_ != PAGE-TYPE-TEXT:
        page-type_ = PAGE-TYPE-TEXT
        clear-menu-content_
      if flush: this.flush
  
  set-line5 text/string --flush/bool=false:
    if line5_ != text:
      line5_ = text
      line5-changed_ = true
      if page-type_ != PAGE-TYPE-TEXT:
        page-type_ = PAGE-TYPE-TEXT
        clear-menu-content_
      if flush: this.flush

  set-lines --line1/string?=null --line2/string?=null --line3/string?=null --line4/string?=null --line5/string?=null --flush/bool=false:
    if line1 != null: set-line1 line1
    if line2 != null: set-line2 line2
    if line3 != null: set-line3 line3
    if line4 != null: set-line4 line4
    if line5 != null: set-line5 line5
    if flush: this.flush

  set-title title/string --flush/bool=false:
    if title_ != title:
      title_ = title
      title-changed_ = true
      // Switch to text mode if we're not already there
      if page-type_ != PAGE-TYPE-TEXT:
        page-type_ = PAGE-TYPE-TEXT
        // Clear menu content when switching to text mode
        clear-menu-content_
      if flush: this.flush

  // Menu content methods (setting these makes the screen show a menu page)
  set-items items/List --flush/bool=false:
    if items_ != items:
      items_ = items
      items-changed_ = true
      // Switch to menu mode if we're not already there
      if page-type_ != PAGE-TYPE-MENU:
        page-type_ = PAGE-TYPE-MENU
        // Clear text content when switching to menu mode
        clear-text-content_
      if flush: this.flush

  add-item item/string --flush/bool=false:
    new-items := items_.copy
    new-items.add item
    set-items new-items --flush=flush

  set-initial-selection selection/int --flush/bool=false:
    if initial-selection_ != selection:
      initial-selection_ = selection
      selection-changed_ = true
      if flush: this.flush

  // Bitmap overlay methods (these can be added to any page type)
  add-bitmap --x/int --y/int --width/int --height/int --bitmap/ByteArray --flush/bool=false:
    bitmaps_.add {
      "x": x,
      "y": y,
      "width": width,
      "height": height,
      "bitmap": bitmap
    }
    bitmaps-changed_ = true
    if flush: this.flush

  draw-home -> none:
    // Send preset page message
    comms_.send (messages.PresetPage.msg) --now=true

  // Rendering methods
  flush -> none:
    // Send with BufferOnly redraw type
    ensure-buffer-cleared-on-first-use_
    send-current-content_ messages.TextPage.REDRAW-TYPE_BUFFERONLY
    
  partial-draw -> none:
    // Send with PartialRedraw redraw type
    ensure-buffer-cleared-on-first-use_
    send-current-content_ messages.TextPage.REDRAW-TYPE_PARTIALREDRAW
    
  full-draw -> none:
    // Send with FullRedraw redraw type
    ensure-buffer-cleared-on-first-use_
    send-current-content_ messages.TextPage.REDRAW-TYPE_FULLREDRAW
    
  render -> none:
    // Smart render: clear buffer + build content + redraw on first time, partial redraw otherwise
    if is-first-update_:
      // Replicate the behavior of the --flush=true sequence
      send-clear-buffer_
      // Send text content with BufferOnly
      if page-type_ == PAGE-TYPE-TEXT:
        send-text-page_ messages.TextPage.REDRAW-TYPE_BUFFERONLY
      else if page-type_ == PAGE-TYPE-MENU:
        send-menu-page_ messages.TextPage.REDRAW-TYPE_BUFFERONLY  // Use TextPage constants
      // Send bitmaps with BufferOnly
      if bitmaps-changed_ or is-first-update_:
        send-bitmaps-buffer-only_
      // Trigger redraw
      send-redraw-trigger_
      // Set baseline for page type tracking
      previous-page-type_ = page-type_
      reset-change-flags_
    else:
      send-current-content_ messages.TextPage.REDRAW-TYPE_PARTIALREDRAW

  ensure-buffer-cleared-on-first-use_:
    // Clear buffer before first operation that sends content
    if is-first-update_:
      send-clear-buffer_

  send-clear-buffer_:
    // Send a minimal message with ClearDontDraw to clear the buffer
    data := protocol.Data
    data.add-data-uint messages.TextPage.PAGE-ID page-id_
    data.add-data-uint messages.TextPage.REDRAW-TYPE messages.TextPage.REDRAW-TYPE_CLEARDONTDRAW
    
    msg := messages.TextPage.msg --data=data
    latch := comms_.send msg --now=true --withLatch=true
    
    result := latch.get
    if not result:
      logger_.error "Failed to clear screen buffer for page $page-id_"

  send-current-content_ redraw-type/int:
    success := true
    
    // Check if page type has changed - if so, we need to send all content with full redraw
    page-type-changed := previous-page-type_ != page-type_
    final-redraw-type := page-type-changed ? messages.TextPage.REDRAW-TYPE_FULLREDRAW : redraw-type
    
    // Send the main page content based on page type
    if page-type_ == PAGE-TYPE-TEXT:
      success = send-text-page_ final-redraw-type --force-all=page-type-changed
    else if page-type_ == PAGE-TYPE-MENU:
      success = send-menu-page_ final-redraw-type --force-all=page-type-changed
    
    // Send bitmap overlays if any
    if success and (bitmaps-changed_ or is-first-update_):
      success = send-bitmaps_
    
    if success:
      previous-page-type_ = page-type_
      reset-change-flags_

  send-text-page_ redraw-type/int --force-all/bool=false -> bool:
    // Start with base data containing only page ID
    data := protocol.Data
    data.add-data-uint messages.TextPage.PAGE-ID page-id_
    
    // Add fields that have changed, on first update, or when forcing all
    if title-changed_ or is-first-update_ or force-all:
      data.add-data-ascii messages.TextPage.PAGE-TITLE title_
    
    if line1-changed_ or is-first-update_ or force-all:
      data.add-data-ascii messages.TextPage.LINE-1 line1_
    
    if line2-changed_ or is-first-update_ or force-all:
      data.add-data-ascii messages.TextPage.LINE-2 line2_
    
    if line3-changed_ or is-first-update_ or force-all:
      data.add-data-ascii messages.TextPage.LINE-3 line3_
    
    if line4-changed_ or is-first-update_ or force-all:
      data.add-data-ascii messages.TextPage.LINE-4 line4_
    
    if line5-changed_ or is-first-update_ or force-all:
      data.add-data-ascii messages.TextPage.LINE-5 line5_
    
    data.add-data-uint messages.TextPage.REDRAW-TYPE redraw-type
    
    msg := messages.TextPage.msg --data=data
    latch := comms_.send msg --now=true --withLatch=true
    
    result := latch.get
    if not result:
      logger_.error "Failed to send text page $page-id_"
    
    return result != false

  send-menu-page_ redraw-type/int --force-all/bool=false -> bool:
    // Start with base data containing only page ID
    data := protocol.Data
    data.add-data-uint messages.MenuPage.PAGE-ID page-id_

    // Add fields that have changed, on first update, or when forcing all
    if items-changed_ or is-first-update_ or force-all:
      data.add-data-uint messages.MenuPage.ITEM-COUNT items_.size
      // Add items to the data - fix the indexing issue
      items_.size.repeat: |i|
        if i < 20: // MenuPage supports up to 20 items
          item-field := 100 + i // ITEM-1 is 100, ITEM-2 is 101, etc.
          data.add-data-ascii item-field items_[i]
    
    if selection-changed_ or is-first-update_ or force-all:
      data.add-data-uint messages.MenuPage.INITIAL-ITEM-SELECTION initial-selection_
    
    msg := messages.MenuPage.msg --data=data
    latch := comms_.send msg --now=true --withLatch=true
    
    result := latch.get
    if not result:
      logger_.error "Failed to send menu page $page-id_"
    
    return result != false

  send-bitmaps_ -> bool:
    if bitmaps_.is-empty:
      return true

    success := true
    
    bitmaps_.do: |bitmap-info|
      // Use PartialRedraw for bitmaps to preserve existing content
      redraw-type := messages.DrawBitmap.REDRAW-TYPE_PARTIALREDRAW
      
      data := messages.DrawBitmap.data
        --page-id=page-id_
        --redraw-type=redraw-type
        --x=bitmap-info["x"]
        --y=bitmap-info["y"]
        --width=bitmap-info["width"]
        --height=bitmap-info["height"]
        --bitmap=bitmap-info["bitmap"]
      
      msg := messages.DrawBitmap.msg --data=data
      latch := comms_.send msg --now=true --withLatch=true
      
      result := latch.get
      if not result:
        logger_.error "Failed to draw bitmap on page $page-id_ at ($(bitmap-info["x"]),$(bitmap-info["y"]))"
        success = false

    return success

  send-bitmaps-buffer-only_ -> bool:
    if bitmaps_.is-empty:
      return true

    success := true
    
    bitmaps_.do: |bitmap-info|
      // Use BufferOnly for building up content
      data := messages.DrawBitmap.data
        --page-id=page-id_
        --redraw-type=messages.DrawBitmap.REDRAW-TYPE_BUFFERONLY
        --x=bitmap-info["x"]
        --y=bitmap-info["y"]
        --width=bitmap-info["width"]
        --height=bitmap-info["height"]
        --bitmap=bitmap-info["bitmap"]
      
      msg := messages.DrawBitmap.msg --data=data
      latch := comms_.send msg --now=true --withLatch=true
      
      result := latch.get
      if not result:
        logger_.error "Failed to send bitmap to buffer on page $page-id_ at ($(bitmap-info["x"]),$(bitmap-info["y"]))"
        success = false

    return success

  send-redraw-trigger_:
    // Send a minimal message to trigger the redraw - use FullRedrawWithoutClear to preserve buffer content
    data := protocol.Data
    data.add-data-uint messages.TextPage.PAGE-ID page-id_
    data.add-data-uint messages.TextPage.REDRAW-TYPE messages.TextPage.REDRAW-TYPE_FULLREDRAWWITHOUTCLEAR
    
    msg := messages.TextPage.msg --data=data
    latch := comms_.send msg --now=true --withLatch=true
    
    result := latch.get
    if not result:
      logger_.error "Failed to trigger redraw for page $page-id_"

  reset-change-flags_:
    title-changed_ = false
    line1-changed_ = false
    line2-changed_ = false
    line3-changed_ = false
    line4-changed_ = false
    line5-changed_ = false
    items-changed_ = false
    selection-changed_ = false
    bitmaps-changed_ = false
    is-first-update_ = false

  clear-text-content_:
    // Clear all text content when switching to menu mode
    title_ = ""
    line1_ = ""
    line2_ = ""
    line3_ = ""
    line4_ = ""
    line5_ = ""
    // Mark all as changed so they get sent as empty
    title-changed_ = true
    line1-changed_ = true
    line2-changed_ = true
    line3-changed_ = true
    line4-changed_ = true
    line5-changed_ = true

  clear-menu-content_:
    // Clear all menu content when switching to text mode
    items_ = []
    initial-selection_ = 1
    // Mark as changed so they get sent as empty
    items-changed_ = true
    selection-changed_ = true
