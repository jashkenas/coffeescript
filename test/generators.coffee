# Generators
# -----------------
#
# * Generator Definition

test "generator as argument", ->
  ok -> yield 0

test "generator definition", ->
  x = ->
    yield 0
    yield 1
    yield 2
  y = x()
  z = y.next()
  eq z.value, 0
  eq z.done, false
  z = y.next()
  eq z.value, 1
  eq z.done, false
  z = y.next()
  eq z.value, 2
  eq z.done, false
  z = y.next()
  eq z.value, undefined
  eq z.done, true

test "bound generator", ->
  obj =
    bound: ->
      do =>
        yield this
    unbound: ->
      do ->
        yield this
    nested: ->
      do =>
        yield do =>
          yield do =>
            yield this

  eq obj, obj.bound().next().value
  ok obj isnt obj.unbound().next().value
  eq obj, obj.nested().next().value.next().value.next().value
