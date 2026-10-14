import coordinate show Coordinate

/** Helpers for the compact latitude,longitude text used by LoRa locations. */
class LoraDistance:
  static parse text/string -> Coordinate?:
    values := text.split ","
    if values.size != 2: return null
    latitude := float.parse values[0] --if-error=: return null
    longitude := float.parse values[1] --if-error=: return null
    if not (latitude >= -90.0 and latitude <= 90.0 and
        longitude >= -180.0 and longitude <= 180.0):
      return null
    return Coordinate latitude longitude

  static meters from/Coordinate to/Coordinate -> int:
    return ((from.distance-to-coord to) + 0.5).to-int
