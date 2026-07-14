import .firmware_build_info show FIRMWARE_VERSION_INT FIRMWARE_VERSION_STRING FIRMWARE_VARIANT

firmware-version-string -> string:
  return FIRMWARE_VERSION_STRING

firmware-version-int -> int:
  return FIRMWARE_VERSION_INT

firmware-variant -> string:
  return FIRMWARE_VARIANT

startup-line -> string:
  return "lb-fw variant=$FIRMWARE_VARIANT version=$FIRMWARE_VERSION_STRING encoded=$FIRMWARE_VERSION_INT"

print-startup-line:
  print startup-line

semver-to-int version/string -> int:
  normalized := version.starts-with "v" ? version[1..] : version
  parts := normalized.split "."
  if parts.size != 3:
    throw "INVALID_SEMVER: $version"

  major := int.parse parts[0]
  minor := int.parse parts[1]
  patch := int.parse parts[2]

  if major < 0:
    throw "INVALID_SEMVER_MAJOR: $version"
  if minor < 0 or minor > 99:
    throw "INVALID_SEMVER_MINOR: $version"
  if patch < 0 or patch > 99:
    throw "INVALID_SEMVER_PATCH: $version"

  encoded := (major * 10_000) + (minor * 100) + patch
  if encoded > 4_294_967_295:
    throw "INVALID_SEMVER_RANGE: $version"
  return encoded
