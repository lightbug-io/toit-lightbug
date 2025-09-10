import ...protocol as protocol
import ...messages as messages
import ...devices as devices
import log

// Constant list of MenuPage item fields to avoid recreating the list each call.
MENU_FIELDS := [
  messages.MenuPage.ITEM-1,
  messages.MenuPage.ITEM-2,
  messages.MenuPage.ITEM-3,
  messages.MenuPage.ITEM-4,
  messages.MenuPage.ITEM-5,
  messages.MenuPage.ITEM-6,
  messages.MenuPage.ITEM-7,
  messages.MenuPage.ITEM-8,
  messages.MenuPage.ITEM-9,
  messages.MenuPage.ITEM-10,
  messages.MenuPage.ITEM-11,
  messages.MenuPage.ITEM-12,
  messages.MenuPage.ITEM-13,
  messages.MenuPage.ITEM-14,
  messages.MenuPage.ITEM-15,
  messages.MenuPage.ITEM-16,
  messages.MenuPage.ITEM-17,
  messages.MenuPage.ITEM-18,
  messages.MenuPage.ITEM-19,
  messages.MenuPage.ITEM-20,
]

/**
Eink module that treats the screen as a composable buffer and draw surface.

Provides helpers to buffer text/base pieces and then draw them in a single
operation. Also provides a convenience method to send menu pages.
*/
class Eink:
  logger_/log.Logger
  device_/devices.Device?

  constructor --device/devices.Device?=null --logger/log.Logger=(log.default.with-name "lb-eink"):
    device_ = device
    logger_ = logger

  // Compute redraw-type from friendly flags when an explicit redraw-type is
  // not provided. Returns null if nothing is selected so callers can keep
  // existing behavior.
  compute-redraw-type --redraw-type/int?=null --partial/bool?=false --full/bool?=false --buffer/bool?=false --clear/bool?=false -> int?:
    if redraw-type != null: return redraw-type
    if full:
      return messages.TextPage.REDRAW-TYPE_FULLREDRAW
    else if partial:
      return messages.TextPage.REDRAW-TYPE_PARTIALREDRAW
    else if buffer:
      if clear:
        return messages.TextPage.REDRAW-TYPE_CLEARDONTDRAW
      else:
        return messages.TextPage.REDRAW-TYPE_BUFFERONLY
    return null

  available -> bool:
    // Always available as it simply sends messages via comms.
    return true

  /**
  Buffer a text page into the device buffer.

  Lines is an optional list of up to 4 strings. The default redraw-type is
  BufferOnly so the message only updates the buffer and does not redraw the
  screen until a subsequent draw is requested.
  */
  text-page --page-id/int?=null --page-title/string?=null --lines/List?=null --status-bar-enable/bool?=null --redraw-type/int?=null --partial/bool?=false --full/bool?=false --buffer/bool?=false --clear/bool?=false -> protocol.Message?:
  // Assumes device_.comms is present.

    // Determine redraw-type from flags if not explicitly provided.
    rt := compute-redraw-type --redraw-type=redraw-type --partial=partial --full=full --buffer=buffer --clear=clear

    l1 := null
    l2 := null
    l3 := null
    l4 := null
    if lines != null:
      if lines.size >= 1: l1 = lines[0]
      if lines.size >= 2: l2 = lines[1]
      if lines.size >= 3: l3 = lines[2]
      if lines.size >= 4: l4 = lines[3]
    data := messages.TextPage.data --page-id=page-id --page-title=page-title --status-bar-enable=status-bar-enable --redraw-type=rt --line-1=l1 --line-2=l2 --line-3=l3 --line-4=l4
    msg := messages.TextPage.msg --data=data
    // Use send-new to optionally wait for a response/ack from the device.
    return device_.comms.send-new msg --flush=true

  // Async overload that runs the synchronous call in a background task and
  // calls the provided callbacks with the protocol.Message result or error.
  text-page --async --page-id/int?=null --page-title/string?=null --lines/List?=null --status-bar-enable/bool?=null --redraw-type/int?=null --partial/bool?=false --full/bool?=false --buffer/bool?=false --clear/bool?=false --onComplete/Lambda?=null --onError/Lambda?=null:
    task::
      e := catch:
        res := text-page --page-id=page-id --page-title=page-title --lines=lines --status-bar-enable=status-bar-enable --redraw-type=redraw-type --partial=partial --full=full --buffer=buffer --clear=clear
        if onComplete:
          onComplete.call res
      if e:
        logger_.error "Async text-page failed: $(e)"
        if onError:
          onError.call e.stringify

  /**
  Send a BasePage message. Useful to control redraw behaviour or to trigger
  a draw after buffering several pieces.
  */
  send-base-page --page-id/int?=null --status-bar-enable/bool?=null --redraw-type/int?=null --partial/bool?=false --full/bool?=false --buffer/bool?=false --clear/bool?=false -> protocol.Message?:
  // Assumes device_.comms is present.
    rt := compute-redraw-type --redraw-type=redraw-type --partial=partial --full=full --buffer=buffer --clear=clear

    data := messages.BasePage.data --page-id=page-id --status-bar-enable=status-bar-enable --redraw-type=rt
    msg := messages.BasePage.msg --data=data
    return device_.comms.send-new msg --flush=true

  // Async overload for send-base-page
  send-base-page --async --page-id/int?=null --status-bar-enable/bool?=null --redraw-type/int?=null --partial/bool?=false --full/bool?=false --buffer/bool?=false --clear/bool?=false --onComplete/Lambda?=null --onError/Lambda?=null:
    task::
      e := catch:
        res := send-base-page --page-id=page-id --status-bar-enable=status-bar-enable --redraw-type=redraw-type --partial=partial --full=full --buffer=buffer --clear=clear
        if onComplete:
          onComplete.call res
      if e:
        logger_.error "Async send-base-page failed: $(e)"
        if onError:
          onError.call e.stringify

  /**
  Draw the current buffer to the screen.

  This is a convenience that sends a BasePage with a drawing redraw-type
  (default FullRedraw). Use this after buffering multiple pieces to make
  them appear on-screen at once.
  */
  draw-page --page-id/int?=null --status-bar-enable/bool?=null --redraw-type/int?=null --partial/bool?=false --full/bool?=false --buffer/bool?=false --clear/bool?=false -> protocol.Message?:
    rt := compute-redraw-type --redraw-type=redraw-type --partial=partial --full=full --buffer=buffer --clear=clear
    return send-base-page --page-id=page-id --status-bar-enable=status-bar-enable --redraw-type=rt

  // Async overload for draw-page
  draw-page --async --page-id/int?=null --status-bar-enable/bool?=null --redraw-type/int?=null --partial/bool?=false --full/bool?=false --buffer/bool?=false --clear/bool?=false --onComplete/Lambda?=null --onError/Lambda?=null:
    task::
      e := catch:
        res := draw-page --page-id=page-id --status-bar-enable=status-bar-enable --redraw-type=redraw-type --partial=partial --full=full --buffer=buffer --clear=clear
        if onComplete:
          onComplete.call res
      if e:
        logger_.error "Async draw-page failed: $(e)"
        if onError:
          onError.call e.stringify

  /**
  Send a menu page.

  Menu pages are controlled by the device. This helper fills the menu fields
  and sends the message. Items beyond 20 will be ignored.

  Selected item is zero-based.
  */
  send-menu --page-id/int?=null --page-title/string?=null --items/List --selected-item/int?=null -> protocol.Message?:
  // Assumes device_.comms is present.

    if items == null or items.size == 0:
      logger_.info "No menu items provided."
      return null

    data := protocol.Data
    // Item count (max 20 supported by generated message).
    count := items.size
    if count > MENU_FIELDS.size: count = MENU_FIELDS.size
    data.add-data-uint messages.MenuPage.ITEM-COUNT count

    if page-id != null: data.add-data-uint messages.MenuPage.PAGE-ID page-id
    if page-title != null: data.add-data-ascii messages.MenuPage.PAGE-TITLE page-title
    if selected-item != null: data.add-data-uint messages.MenuPage.SELECTED-ITEM selected-item

    for i := 0; i < count; i++:
      field := MENU_FIELDS[i]
      item := items[i]
      data.add-data-ascii field item

    msg := protocol.Message.with-data messages.MenuPage.MT data
    return device_.comms.send-new msg --flush=true

  // Async overload for send-menu
  send-menu --async --page-id/int?=null --page-title/string?=null --items/List --selected-item/int?=null --onComplete/Lambda?=null --onError/Lambda?=null:
    task::
      e := catch:
        res := send-menu --page-id=page-id --page-title=page-title --items=items --selected-item=selected-item
        if onComplete:
          onComplete.call res
      if e:
        logger_.error "Async send-menu failed: $(e)"
        if onError:
          onError.call e.stringify

  /**
  Draw an element (box, circle, line or bitmap) on the given page.

  Accepts the full set of DrawElement fields from the generated message
  helper. Returns the protocol.Message? from the sync send-new call, or
  null if comms are unavailable.
  */
  draw-element --page-id/int?=null --status-bar-enable/bool?=null --redraw-type/int?=null --x/int?=null --y/int?=null --width/int?=null --height/int?=null --type/int?=null --style/int?=null --fontsize/int?=null --textalign/int?=null --linewidth/int?=null --padding/int?=null --radius/int?=null --linetype/int?=null --x2/int?=null --y2/int?=null --bitmap/ByteArray?=null --text/string?=null -> protocol.Message?:
    if device_ == null or device_.comms == null:
      logger_.info "No device or comms available to draw element."
      return null

    data := messages.DrawElement.data
      --page-id=page-id
      --status-bar-enable=status-bar-enable
      --redraw-type=redraw-type
      --x=x
      --y=y
      --width=width
      --height=height
      --type=type
      --style=style
      --fontsize=fontsize
      --textalign=textalign
      --linewidth=linewidth
      --padding=padding
      --radius=radius
      --linetype=linetype
      --x2=x2
      --y2=y2
      --bitmap=bitmap
      --text=text

    msg := messages.DrawElement.msg --data=data
    return device_.comms.send-new msg --flush=true

  // Async overload for draw-element
  draw-element --async --page-id/int?=null --status-bar-enable/bool?=null --redraw-type/int?=null --x/int?=null --y/int?=null --width/int?=null --height/int?=null --type/int?=null --style/int?=null --fontsize/int?=null --textalign/int?=null --linewidth/int?=null --padding/int?=null --radius/int?=null --linetype/int?=null --x2/int?=null --y2/int?=null --bitmap/ByteArray?=null --text/string?=null --onComplete/Lambda?=null --onError/Lambda?=null:
    task::
      e := catch:
        res := draw-element --page-id=page-id --status-bar-enable=status-bar-enable --redraw-type=redraw-type --x=x --y=y --width=width --height=height --type=type --style=style --fontsize=fontsize --textalign=textalign --linewidth=linewidth --padding=padding --radius=radius --linetype=linetype --x2=x2 --y2=y2 --bitmap=bitmap --text=text
        if onComplete:
          onComplete.call res
      if e:
        logger_.error "Async draw-element failed: $(e)"
        if onError:
          onError.call e.stringify

  show-preset --page-id/int --status-bar-enable/bool?=true -> protocol.Message?:
    if device_ == null or device_.comms == null:
      logger_.info "No device or comms available to show preset."
      return null
    return send-base-page --page-id=page-id --status-bar-enable=status-bar-enable

  // Async overload for show-preset
  show-preset --async --page-id/int --status-bar-enable/bool?=true --onComplete/Lambda?=null --onError/Lambda?=null:
    task::
      e := catch:
        res := show-preset --page-id=page-id --status-bar-enable=status-bar-enable
        if onComplete:
          onComplete.call res
      if e:
        logger_.error "Async show-preset failed: $(e)"
        if onError:
          onError.call e.stringify

  /**
  Convenience wrapper to draw a straight line. This calls `draw-element` with
  the LINE type so callers don't need to provide the type constant.
  */
  draw-line --page-id/int?=null --status-bar-enable/bool?=null --x/int?=null --y/int?=null --x2/int?=null --y2/int?=null --linewidth/int?=null --linetype/int?=null -> protocol.Message?:
    return draw-element --page-id=page-id --status-bar-enable=status-bar-enable --type=messages.DrawElement.TYPE_LINE --x=x --y=y --x2=x2 --y2=y2 --linewidth=linewidth --linetype=linetype

  // Async overload for draw-line
  draw-line --async --page-id/int?=null --status-bar-enable/bool?=null --x/int?=null --y/int?=null --x2/int?=null --y2/int?=null --linewidth/int?=null --linetype/int?=null --onComplete/Lambda?=null --onError/Lambda?=null:
    task::
      e := catch:
        res := draw-line --page-id=page-id --status-bar-enable=status-bar-enable --x=x --y=y --x2=x2 --y2=y2 --linewidth=linewidth --linetype=linetype
        if onComplete:
          onComplete.call res
      if e:
        logger_.error "Async draw-line failed: $(e)"
        if onError:
          onError.call e.stringify

  /**
  Convenience wrapper to draw a circle. Calls `draw-element` with TYPE_CIRCLE.
  */
  draw-circle --page-id/int?=null --status-bar-enable/bool?=null --x/int?=null --y/int?=null --width/int?=null --height/int?=null --linewidth/int?=null -> protocol.Message?:
    return draw-element --page-id=page-id --status-bar-enable=status-bar-enable --type=messages.DrawElement.TYPE_CIRCLE --x=x --y=y --width=width --height=height --linewidth=linewidth

  // Async overload for draw-circle
  draw-circle --async --page-id/int?=null --status-bar-enable/bool?=null --x/int?=null --y/int?=null --width/int?=null --height/int?=null --linewidth/int?=null --onComplete/Lambda?=null --onError/Lambda?=null:
    task::
      e := catch:
        res := draw-circle --page-id=page-id --status-bar-enable=status-bar-enable --x=x --y=y --width=width --height=height --linewidth=linewidth
        if onComplete:
          onComplete.call res
      if e:
        logger_.error "Async draw-circle failed: $(e)"
        if onError:
          onError.call e.stringify

  /**
  Convenience wrapper to draw a bitmap. Calls `draw-element` with TYPE_BITMAP.
  Accepts an optional --redraw-type to control buffer/draw behaviour.
  */
  draw-bitmap --page-id/int?=null --status-bar-enable/bool?=null --redraw-type/int?=null --x/int?=null --y/int?=null --width/int?=null --height/int?=null --bitmap/ByteArray?=null -> protocol.Message?:
  // Assumes device_.comms is present.
    rt := compute-redraw-type --redraw-type=redraw-type
    return draw-element --page-id=page-id --status-bar-enable=status-bar-enable --redraw-type=rt --type=messages.DrawElement.TYPE_BITMAP --x=x --y=y --width=width --height=height --bitmap=bitmap

  // Async overload for draw-bitmap
  draw-bitmap --async --page-id/int?=null --status-bar-enable/bool?=null --redraw-type/int?=null --x/int?=null --y/int?=null --width/int?=null --height/int?=null --bitmap/ByteArray?=null --onComplete/Lambda?=null --onError/Lambda?=null:
    task::
      e := catch:
        res := draw-bitmap --page-id=page-id --status-bar-enable=status-bar-enable --redraw-type=redraw-type --x=x --y=y --width=width --height=height --bitmap=bitmap
        if onComplete:
          onComplete.call res
      if e:
        logger_.error "Async draw-bitmap failed: $(e)"
        if onError:
          onError.call e.stringify

  stringify -> string:
    return "Eink screen controller"
