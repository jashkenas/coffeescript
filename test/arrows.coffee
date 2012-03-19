test "left arrow", ->
  id = (n, f) ->
    f(n)
  a <- id(1)
  c = a
  b <- id(c)
  d = 2
  e = b
  eq e, 1

test "left arrow with arrays", ->
  async_sum = (a, b, f) ->
    f(a + b)
  r <- async_sum(2, 2)
  eq r, 4