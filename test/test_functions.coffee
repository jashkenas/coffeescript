x: 1
y: {}
y.x: -> 3

ok x is 1
ok typeof(y.x) is 'function'
ok y.x instanceof Function
ok y.x() is 3
ok y.x.name is 'x'


# The empty function should not cause a syntax error.
->
() ->


obj: {
  name: "Fred"

  bound: ->
    (=> ok(this.name is "Fred"))()

  unbound: ->
    (-> ok(!this.name?))()
}

obj.unbound()
obj.bound()


# The named function should be cleared out before a call occurs:

# Python decorator style wrapper that memoizes any function
memoize: (fn) ->
  cache: {}
  self: this
  (args...) ->
    key: args.toString()
    return cache[key] if cache[key]
    cache[key] = fn.apply(self, args)

Math: {
  Add: (a, b) -> a + b
  AnonymousAdd: ((a, b) -> a + b)
  FastAdd: memoize (a, b) -> a + b
}

ok Math.Add(5, 5) is 10
ok Math.AnonymousAdd(10, 10) is 20
ok Math.FastAdd(20, 20) is 40


# Parens are optional on simple function calls.
ok 100 > 1 if 1 > 0
ok true unless false
ok true for i in [1..3]

ok_func: (f) -> ok(f())
ok_func -> true

# Optional parens can be used in a nested fashion.
call: (func) -> func()

result: call ->
  inner: call ->
    Math.Add(5, 5)

ok result is 10


# And even with strange things like this:

funcs:  [(x) -> x, (x) -> x * x]
result: funcs[1] 5

ok result is 25

result: ("hello".slice) 3

ok result is 'lo'


# And with multiple single-line functions on the same line.

func: (x) -> (x) -> (x) -> x
ok func(1)(2)(3) is 3
