import lightbug.firmware as firmware

main:
  semver-to-int
  startup-line

assert-eq label/string got want -> none:
  if got != want:
    throw "$label failed. Got=$got Want=$want"

semver-to-int:
  assert-eq "0.18.0 encoding" (firmware.semver-to-int "0.18.0") 1800
  assert-eq "v0.18.0 encoding" (firmware.semver-to-int "v0.18.0") 1800
  assert-eq "1.1.1 encoding" (firmware.semver-to-int "1.1.1") 10101
  assert-eq "12.34.56 encoding" (firmware.semver-to-int "12.34.56") 123456

startup-line:
  line := firmware.startup-line
  if not line.contains "version=":
    throw "startup-line missing version"
  if not line.contains "encoded=":
    throw "startup-line missing encoded version"
