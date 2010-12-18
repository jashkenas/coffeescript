# Splats
# ------

# note: splats in parameter lists of function definitions are tested in `arguments.coffee`


test "passing splats to functions", ->
  fn = () -> arguments
  arrayEqual [2..4], fn [0..4]...

  fn = (a, b, c..., d) -> [a, b, c, d]
  [first, second, others, last] = fn [0..3]..., 4, [5...8]...
  eq 0, first
  eq 1, second
  arrayEqual [2..6], others
  eq 7, last


obj =
  name: 'moe'
  accessor: (args...) ->
    [@name].concat(args).join(' ')
  getNames: ->
    args = ['jane', 'ted']
    @accessor(args...)
  index: 0
  0: {method: -> this is obj[0]}

ok obj.getNames() is 'moe jane ted'
ok obj[obj.index++].method([]...), 'should cache base value'

crowd = [
  contenders...
  "Mighty Mouse"
]

bests = [
  "Mighty Mouse"
  contenders.slice(0, 4)...
]

ok crowd[0] is contenders[0]
ok crowd[10] is "Mighty Mouse"

ok bests[1] is contenders[0]
ok bests[4] is contenders[3]


# Finally, splats with super() within classes.

class Parent
  meth: (args...) ->
    args

class Child extends Parent
  meth: ->
    nums = [3, 2, 1]
    super nums...

ok (new Child).meth().join(' ') is '3 2 1'


# Functions with splats being called with too few arguments.
pen = null
method = (first, variable..., penultimate, ultimate) ->
  pen = penultimate

method 1, 2, 3, 4, 5, 6, 7, 8, 9
ok pen is 8

method 1, 2, 3
ok pen is 2

method 1, 2
ok pen is 2


# Array splat expansions with assigns.
nums = [1, 2, 3]
list = [a = 0, nums..., b = 4]
ok a is 0
ok b is 4
ok list.join(' ') is '0 1 2 3 4'


# Splat on a line by itself is invalid.
failed = true
try
  CoffeeScript.compile "x 'a'\n...\n"
  failed = false
catch err
ok failed


# multiple generated references
(->
  a = {b: []}
  a.b[true] = -> this == a.b
  c = 0
  d = []
  ok a.b[0<++c<2] d...
)()
