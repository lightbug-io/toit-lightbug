import ...messages as messages
import ...protocol as protocol

// TODO these should be defined elsewhere
SCREEN-WIDTH := 250
SCREEN-HEIGHT := 122

// Helper function to create LORA data with payload and receive time
create-lora-data payload/string -> protocol.Data:
  data := protocol.Data
  data.add-data-ascii messages.LORA.PAYLOAD payload
  data.add-data-uint32 messages.LORA.RECEIVE-MS 10000
  return data

// Helper function to create CPU2Sleep data
create-cpu2sleep-data interval/int wake-on-event/bool -> protocol.Data:
  data := protocol.Data
  data.add-data-uint32 messages.CPU2Sleep.INTERVAL interval
  data.add-data-uint8 messages.CPU2Sleep.WAKE-ON-EVENT (wake-on-event ? 1 : 0)
  return data

// Helper function to create TransmitNow data
create-transmit-now-data payload/ByteArray -> protocol.Data:
  data := protocol.Data
  data.add-data messages.TransmitNow.PAYLOAD payload
  return data

// Helper function to create GPSControl data
create-gps-control-data rtk-enable-correction/int -> protocol.Data:
  data := protocol.Data
  data.add-data-uint8 messages.GPSControl.CORRECTIONS-ENABLED rtk-enable-correction
  return data

// Helper function to create MenuPage data
create-menu-page-data page-id/int items/List -> protocol.Data:
  data := protocol.Data
  data.add-data-uint8 messages.MenuPage.PAGE-ID page-id
  data.add-data-uint 30 items.size
  data.add-data-uint 6 0 //redraw type
  items.size.repeat: | i |
    // MenuPage has LINE-1, LINE-2, LINE-3, etc. starting from constant 100
    line-constant := 100 + i
    data.add-data-string line-constant items[i]
  return data

// Helper function to create TextPage data
create-text-page-data page-id/int page-title/string line1/string line2/string -> protocol.Data:
  data := protocol.Data
  data.add-data-uint messages.TextPage.PAGE-ID page-id
  data.add-data-string messages.TextPage.PAGE-TITLE page-title
  data.add-data-string messages.TextPage.LINE-1 line1
  data.add-data-string messages.TextPage.LINE-2 line2
  return data

// Helper function to create DrawElement bitmap data
create-draw-bitmap-data page-id/int bitmap-data/ByteArray bitmap-height/int bitmap-width/int x/int=0 y/int=0 redraw-type/int=0 -> protocol.Data:
  data := protocol.Data
  data.add-data-uint messages.DrawElement.PAGE-ID page-id
  data.add-data-uint messages.DrawElement.REDRAW-TYPE redraw-type
  data.add-data-uint messages.DrawElement.X x
  data.add-data-uint messages.DrawElement.Y y
  data.add-data-uint messages.DrawElement.WIDTH bitmap-width
  data.add-data-uint messages.DrawElement.HEIGHT bitmap-height
  data.add-data-uint messages.DrawElement.TYPE messages.DrawElement.TYPE_BITMAP
  data.add-data messages.DrawElement.BITMAP bitmap-data
  return data

// Helper function to create HapticsControl data
create-haptics-control-data pattern/int intensity/int -> protocol.Data:
  data := protocol.Data
  data.add-data-uint8 messages.HapticsControl.PATTERN pattern
  data.add-data-uint8 messages.HapticsControl.INTENSITY intensity
  return data

// Helper function to create BuzzerControl data
create-buzzer-control-data duration/int frequency/float?=null sound-type/int?=null intensity/int?=null -> protocol.Data:
  data := protocol.Data
  data.add-data-uint16 messages.BuzzerControl.DURATION duration
  if frequency != null:
    data.add-data-float32 messages.BuzzerControl.FREQUENCY frequency
  if sound-type != null:
    data.add-data-uint8 messages.BuzzerControl.SOUND-TYPE sound-type
  if intensity != null:
    data.add-data-uint8 messages.BuzzerControl.INTENSITY intensity
  return data

// Helper function to create BuzzerSequence data
create-buzzer-sequence-data frequencies/List durations/List -> protocol.Data:
  data := protocol.Data
  data.add-data-list-float32 messages.BuzzerSequence.FREQUENCIES frequencies
  data.add-data-list-uint16 messages.BuzzerSequence.TIMINGS durations
  return data

// Helper function to create Alarm data
create-alarm-data duration/int buzzer-pattern/int?=null buzzer-intensity/int?=null -> protocol.Data:
  data := protocol.Data
  data.add-data-uint32 messages.Alarm.DURATION duration
  if buzzer-pattern != null:
    data.add-data-uint8 messages.Alarm.BUZZER-PATTERN buzzer-pattern
  if buzzer-intensity != null:
    data.add-data-uint8 messages.Alarm.BUZZER-INTENSITY buzzer-intensity
  return data
