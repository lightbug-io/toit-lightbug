interface IdGenerator:
  next -> int

class SequentialIdGenerator implements IdGenerator:
  nextId_ := 0
  maxId_ := 0

  constructor --start/int --maxId/int:
    nextId_ = start - 1
    maxId_ = maxId

  next -> int:
    nextId_ = (nextId_ + 1) % maxId_
    return nextId_

class RandomIdGenerator implements IdGenerator:
  lowerBound_ := 0
  upperBound_ := 0

  constructor --lowerBound/int --upperBound/int:
    lowerBound_ = lowerBound
    upperBound_ = upperBound
  
  next -> int:
    return random lowerBound_ upperBound_