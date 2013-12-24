# Generators
# -----------------
#
# * Generator Definition

test "generator as argument", ->
  ok ->* 1

test "generator definition", ->
  x = ->*
    yield 0
    yield 1
    yield 2
  y = do ->*
    yield* x()
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
      do =>*
        this
    unbound: ->
      do ->*
        this
    nested: ->
      do =>*
        do =>*
          do =>*
            this

  eq obj, obj.bound().next().value
  ok obj isnt obj.unbound().next().value
  eq obj, obj.nested().next().value.next().value.next().value
