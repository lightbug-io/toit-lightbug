class MenuSelection:
  selection_ /int := 0
  size_ /int

  constructor --start/int --size/int:
    selection_ = start
    size_ = size
  
  up -> int:
    selection_ += 1
    if selection_ >= size_:
      selection_ = 0
    return selection_

  down -> int:
    selection_ -= 1
    if selection_ < 0:
      selection_ = size_ - 1
    return selection_

  // Set the selection from the device's authoritative menu state. Returns
  // false for an out-of-range value so callers can retain their local state.
  synchronize selection/int -> bool:
    if selection < 0 or selection >= size_: return false
    selection_ = selection
    return true

  select-last -> int:
    selection_ = size_ - 1
    return selection_
  
  current -> int:
    return selection_
