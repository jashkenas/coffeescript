x: 1
y: {}
y.x: -> 3

puts x is 1
puts typeof(y.x) is 'function'
puts y.x instanceof Function
puts y.x() is 3
puts y.x.name is 'x'


# The empty function should not cause a syntax error.
->


obj: {
  name: "Fred"

  bound: ->
    (=> puts(this.name is "Fred"))()

  unbound: ->
    (-> puts(!this.name?))()
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

puts Math.Add(5, 5) is 10
puts Math.AnonymousAdd(10, 10) is 20
puts Math.FastAdd(20, 20) is 40


# Parens are optional on simple function calls.
puts 100 > 1 if 1 > 0
puts true unless false
puts true for i in [1..3]

puts_func: (f) -> puts(f())
puts_func -> true

# Optional parens can be used in a nested fashion.
call: (func) -> func()

result: call ->
  inner: call ->
    Math.Add(5, 5)

puts result is 10


# And even with strange things like this:

funcs:  [(x) -> x, (x) -> x * x]
result: funcs[1] 5

puts result is 25

result: ("hello".slice) 3

puts result is 'lo'