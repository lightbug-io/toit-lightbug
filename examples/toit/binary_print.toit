// An example of using Toit's string formatting to print a byte in hex and binary.
main:
  byte := 94
  print "$(%02x byte)" // 5e
  print "$(%08b byte)" // 01011110