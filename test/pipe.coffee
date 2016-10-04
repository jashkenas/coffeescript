
test "Pipe to function", ->

  fn = (x) -> x * 100

  eq 100, 1 |> fn
  eq 300, 3 |> fn

test "Pipe to partialy filled function", ->

  fn = (x,y) -> "#{x},#{y}"

  eq '1,2', 1 |> fn(2)
  eq '1,2', 1 |> fn 2

test "Pipe chain", ->

  f = (x) -> x * 10
  g = (x) -> x + 5

  eq 15, 1 |> f |> g
  eq 60, 1 |> g |> f

  add = (x,y) -> x + y
  mul = (x,y) -> x * y

  eq 45, 4 |> mul(10) |> add 5
  eq 70, 4 |> add(10) |> mul 5

test "Pipe on the next line", ->

  fn = (x,y) -> "#{x},#{y}"

  eq '1,2', 1
    |> fn(2)

  eq '1,2', 1
    |> fn 2

