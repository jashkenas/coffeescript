func = (first, second, rest...) ->
  rest.join ' '

result = func 1, 2, 3, 4, 5

ok result is "3 4 5"


gold = silver = bronze = theField = last = null

medalists = (first, second, third, rest..., unlucky) ->
  gold     = first
  silver   = second
  bronze   = third
  theField = rest.concat([last])
  last     = unlucky

contenders = [
  "Michael Phelps"
  "Liu Xiang"
  "Yao Ming"
  "Allyson Felix"
  "Shawn Johnson"
  "Roman Sebrle"
  "Guo Jingjing"
  "Tyson Gay"
  "Asafa Powell"
  "Usain Bolt"
]

medalists "Mighty Mouse", contenders...

ok gold is "Mighty Mouse"
ok silver is "Michael Phelps"
ok bronze is "Liu Xiang"
ok last is "Usain Bolt"
ok theField.length is 8

contenders.reverse()
medalists contenders[0...2]..., "Mighty Mouse", contenders[2...contenders.length]...

ok gold is "Usain Bolt"
ok silver is "Asafa Powell"
ok bronze is "Mighty Mouse"
ok last is "Michael Phelps"
ok theField.length is 8

medalists contenders..., 'Tim', 'Moe', 'Jim'
ok last is 'Jim'


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
  contenders[0..3]...
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
