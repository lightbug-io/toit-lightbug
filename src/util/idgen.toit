interface IdGenerator:
  next -> int

class SequentialIdGenerator implements IdGenerator:
  lastId := 0
  maxId := 0

  constructor --start/int --maxId/int:
    lastId = start
    maxId = maxId

  next -> int:
    lastId = (lastId + 1) % maxId
    return lastId

class RandomIdGenerator implements IdGenerator:
  lowerBound := 0
  upperBound := 0

  constructor --lowerBound/int --upperBound/int:
      lowerBound = lowerBound
      upperBound = upperBound
  
  next -> int:
    return random lowerBound upperBound