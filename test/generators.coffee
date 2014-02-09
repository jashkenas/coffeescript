# Generators
# -----------------
#
# * Generator Definition

test "generator as argument", ->
  ok --> 1

test "generator definition", ->
  gen = --> yield i for i in [0..2]
  list = gen()
  {value, done} = list.next()
  eq value, 0
  eq done, no
  {value, done} = list.next()
  eq value, 1
  eq done, no
  {value, done} = list.next()
  eq value, 2
  eq done, no
  {done} = list.next()
  eq done, yes

test "yield from", ->
  first = -->
    i = 0
    yield i++ while true
  second = -->
    yield from first()
  list = second()
  for i in [0..3]
    {value} = list.next()
    eq value, i

test "bound generator", ->
  obj =
    bound: ->
      do ==> yield this
    unbound: ->
      do --> yield this
    nested: ->
      do ==>
        yield do ==>
          yield do ==>
            yield this

  eq obj, obj.bound().next().value
  ok obj isnt obj.unbound().next().value
  eq obj, obj.nested().next().value.next().value.next().value
