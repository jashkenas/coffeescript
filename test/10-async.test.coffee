# Test async/await operations

test "async function", ->
  delay = (ms) -> new Promise (resolve) -> setTimeout(resolve, ms)

  fetchData = ->
    await delay(1)
    return 42

  result = await fetchData()
  eq result, 42

test "async arrow function", ->
  getData = ->
    await Promise.resolve("data")

  result = await getData()
  eq result, "data"

test "await in loops", ->
  values = []

  processItems = ->
    for i in [1, 2, 3]
      val = await Promise.resolve(i * 2)
      values.push val

  await processItems()
  eq values[0], 2
  eq values[1], 4
  eq values[2], 6

test "async class methods", ->
  class DataService
    fetchUser: ->
      await Promise.resolve({name: "Alice"})

  service = new DataService()
  user = await service.fetchUser()
  eq user.name, "Alice"

test "promise chaining", ->
  result = await Promise.resolve(5)
    .then (x) -> x * 2
    .then (x) -> x + 3
  eq result, 13

test "async try-catch", ->
  riskyOperation = ->
    await Promise.resolve("success")

  try
    result = await riskyOperation()
    eq result, "success"
  catch e
    throw e

test "parallel await", ->
  p1 = Promise.resolve(1)
  p2 = Promise.resolve(2)
  p3 = Promise.resolve(3)

  [r1, r2, r3] = await Promise.all([p1, p2, p3])
  eq r1, 1
  eq r2, 2
  eq r3, 3

test "async generator", ->
  asyncGen = ->
    yield await Promise.resolve(1)
    yield await Promise.resolve(2)
    yield await Promise.resolve(3)

  values = []
  for await val from asyncGen()
    values.push val

  eq values[0], 1
  eq values[1], 2
  eq values[2], 3
