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
  
  current -> int:
    return selection_