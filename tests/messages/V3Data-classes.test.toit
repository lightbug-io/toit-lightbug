import lightbug.protocol as protocol
import lightbug.messages show *

main:
  testConstructor

testConstructor:
  // Just make a location
  // http://docs-next.lightbug.io/devices/api/parse?bytes=03%2C%200x4f%2C%200x00%2C%200x0f%2C%200x00%2C%200x02%2C%200x00%2C%200x01%2C%200x02%2C%200x04%2C%200x1b%2C%200x01%2C%200x00%2C%200x00%2C%200x08%2C%200x56%2C%200x99%2C%200x93%2C%200x00%2C%200x00%2C%200x00%2C%200x00%2C%200x00%2C%200x0b%2C%200x00%2C%200x01%2C%200x02%2C%200x03%2C%200x04%2C%200x05%2C%200x06%2C%200x07%2C%200x08%2C%200x09%2C%200x0a%2C%200x0b%2C%200x08%2C%200x78%2C%200x87%2C%200xad%2C%200x0c%2C%200x00%2C%200x00%2C%200x00%2C%200x00%2C%200x04%2C%200xd8%2C%200xa7%2C%200xad%2C%200x1e%2C%200x04%2C%200x5f%2C%200x33%2C%200x7c%2C%200xfe%2C%200x04%2C%200xf2%2C%200xe8%2C%200x01%2C%200x00%2C%200x02%2C%200x69%2C%200x03%2C%200x02%2C%200x17%2C%200x70%2C%200x02%2C%200x02%2C%200x00%2C%200x01%2C%200x1b%2C%200x01%2C%200x00%2C%200x01%2C%200x03%2C%200x01%2C%200x01%2C%200xf6%2C%200x75
  b := #[0X0B, 0X00, 0X01, 0X02, 0X03, 0X04, 0X05, 0X06, 0X07, 0X08, 0X09, 0X0A, 0X0B, 0X08, 0X78, 0X87, 0XAD, 0X0C, 0X00, 0X00, 0X00, 0X00, 0X04, 0XD8, 0XA7, 0XAD, 0X1E, 0X04, 0X5F, 0X33, 0X7C, 0XFE, 0X04, 0XF2, 0XE8, 0X01, 0X00, 0X02, 0X69, 0X03, 0X02, 0X17, 0X70, 0X02, 0X02, 0X00, 0X01, 0X1B, 0X01, 0X00, 0X01, 0X03, 0X01, 0X01]
  LastPosition.from-data (protocol.Data.from-bytes b)
  print "✅ Passed creating LastPositionData from Data"