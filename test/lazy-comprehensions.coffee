# Lazy Comprehensions
# --------------

# * Array Lazy Comprehensions
# * Range Lazy Comprehensions
# * Object Lazy Comprehensions
# * Implicit Lazy Destructuring Assignment
# * Lazy Comprehensions with Nonstandard Step

test "Basic lazy array comprehensions.", ->

  nums    = (n * n for each n in [1, 2, 3] when n & 1)
  results = (n * 2 for each n from nums)

  eq results.next().value, 2
  eq results.next().value, 18
  eq results.next().done,  yes


test "Disallow uncaptured lazy comprehensions.", ->

  throwsCompileError "for n in [1, 2, 3]"


test "Basic lazy object comprehensions.", ->

  obj   = {one: 1, two: 2, three: 3}
  names = (prop + '!' for each prop of obj)
  odds  = (prop + '!' for each prop, value of obj when value & 1)

  eq names.next().value, "one!"
  eq names.next().value, "two!"
  eq names.next().value, "three!"
  eq names.next().done,  yes
  eq odds.next().value,  "one!"
  eq odds.next().value,  "three!"
  eq odds.next().done,   yes


test "Basic lazy range comprehensions.", ->

  nums = (i * 3 for i in [1..3])

  negs = (x for each x in [-20..-5*2])

  nums.push negs.next().value
  nums.push negs.next().value
  nums.push negs.next().value

  arrayEq nums, [3, 6, 9, -20, -19, -18]


test "Lazy range comprehensions with steps.", ->

  results = (x for each x in [0...15] by 5)
  eq results.next().value, 0
  eq results.next().value, 5
  eq results.next().value, 10
  eq results.next().done,  yes

  results = (x for each x in [0..100] by 10)
  eq results.next().value, i*10 for i in [0..10]
  eq results.next().done,  yes


test "Downward lazy range comprehensions.", ->

  a = (x for each x in [5..1])
  b = (x for each x in [(10-5)..(-2+3)])

  for x in [5..1]
    eq a.next().value, x
    eq b.next().value, x

  results = (x for each x in [10..1])
  eq results.next().value, x for x in [10..1]

  results = (x for each x in [10...0] by -2)
  eq results.next().value, x for x in [10, 8, 6, 4, 2]


test "Lazy range comprehension gymnastics.", ->
  a = 6
  b = 0
  c = -2

  results = (i for each i in [a..b])
  eq results.next().value, x for x in [6, 5, 4, 3, 2, 1, 0]

  results = (i for each i in [a..b] by c)
  eq results.next().value, x for x in [6, 4, 2, 0]


test "Multiline array comprehension with filter.", ->

  evens = for each num in [1, 2, 3, 4, 5, 6] when not (num & 1)
    num *= -1
    num -= 2
    num * -1
  eq evens.next().value, x for x in [4, 6, 8]


test "Ensure that the lazy closure wrapper preserves local variables.", ->

  obj = {}

  worker =
    for each method in ['one', 'two', 'three'] then do (method) ->
      obj[method] = -> "I'm " + method
  
  null until worker.next().done

  eq obj.one(),   "I'm one"
  eq obj.two(),   "I'm two"
  eq obj.three(), "I'm three"


test "Ensure that local variables are closed over for lazy range comprehensions.", ->

  funcs = for each i in [1..3]
    do (i) ->
      -> -i

  eq (func() for func from funcs).join(' '), '-1 -2 -3'
  eq i, 4


test "Nested lazy comprehensions.", ->

  results = ("#{x},#{y}" for each x in [0,1,2] for each y in ["a","b","c"])

  for a in ["a","b","c"]
    it = results.next().value
    for b in [0,1,2]
      eq it.next().value, "#{b},#{a}"
  return


test "Scoped loop pattern matching.", ->

  a = [[0], [1]]
  funcs = []

  worker = for each [v] in a
    do (v) ->
      funcs.push -> v
  
  null until worker.next().done

  eq funcs[0](), 0
  eq funcs[1](), 1


test "Lazy comprehensions over properties.", ->

  class Cat
    constructor: -> @name = 'Whiskers'
    breed: 'tabby'
    hair:  'cream'

  whiskers = new Cat
  own = (value for each own key, value of whiskers)
  all = (value for each key, value of whiskers)

  eq own.next().value, 'Whiskers'
  eq (a for a from all).sort().join(' '), 'Whiskers cream tabby'
