import io

class SectionStats:
  name_/string
  total-us_/int := 0
  count_/int := 0
  min-us_/int := -1
  max-us_/int := 0

  constructor .name_:

  add-sample duration-us/int -> none:
    total-us_ += duration-us
    count_ += 1
    if min-us_ < 0 or duration-us < min-us_:
      min-us_ = duration-us
    if duration-us > max-us_:
      max-us_ = duration-us

  name -> string:
    return name_

  total-us -> int:
    return total-us_

  count -> int:
    return count_

  avg-us -> int:
    if count_ == 0:
      return 0
    return total-us_ / count_

  min-us -> int:
    if min-us_ < 0:
      return 0
    return min-us_

  max-us -> int:
    return max-us_

  format-line -> string:
    return "$name_: total=$total-us_ us avg=$avg-us us min=$min-us us max=$max-us us samples=$count_"

class Profiler:
  sections_/Map := {:}
  ordered_/List := []

  ensure-section_ name/string -> SectionStats:
    if sections_.contains name:
      return sections_[name]
    section := SectionStats name
    sections_[name] = section
    ordered_.add section
    return section

  measure name/string [block] -> none:
    start := Time.monotonic-us
    block.call
    duration-us := Time.monotonic-us - start
    section := ensure-section_ name
    section.add-sample duration-us

  add-sample name/string duration-us/int -> none:
    section := ensure-section_ name
    section.add-sample duration-us

  report -> string:
    buffer := io.Buffer
    buffer.write "\nProfiling summary:\n"
    ordered_.do: |section/SectionStats|
      buffer.write section.format-line
      buffer.write "\n"
    return buffer.to-string
