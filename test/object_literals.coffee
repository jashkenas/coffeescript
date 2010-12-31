# Object Literals
# ---------------

# TODO: refactor object literal tests

trailingComma = {k1: "v1", k2: 4, k3: (-> true),}
ok trailingComma.k3() and (trailingComma.k2 is 4) and (trailingComma.k1 is "v1")

ok {a: (num) -> num is 10 }.a 10

moe = {
  name:  'Moe'
  greet: (salutation) ->
    salutation + " " + @name
  hello: ->
    @['greet'] "Hello"
  10: 'number'
}
ok moe.hello() is "Hello Moe"
ok moe[10] is 'number'
moe.hello = ->
  this['greet'] "Hello"
ok moe.hello() is 'Hello Moe'

obj = {
  is:     -> yes,
  'not':  -> no,
}
ok obj.is()
ok not obj.not()

### Top-level object literal... ###
obj: 1
### ...doesn't break things. ###

# Object literals should be able to include keywords.
obj = {class: 'höt'}
obj.function = 'dog'
ok obj.class + obj.function is 'hötdog'

# Implicit objects as part of chained calls.
pluck = (x) -> x.a
eq 100, pluck pluck pluck a: a: a: 100


test "YAML-style object literals", ->
  obj =
    a: 1
    b: 2
  eq 1, obj.a
  eq 2, obj.b

  config =
    development:
      server: 'localhost'
      timeout: 10

    production:
      server: 'dreamboat'
      timeout: 1000

  ok config.development.server  is 'localhost'
  ok config.production.server   is 'dreamboat'
  ok config.development.timeout is 10
  ok config.production.timeout  is 1000

obj =
  a: 1,
  b: 2,
ok obj.a is 1
ok obj.b is 2

# Implicit objects nesting.
obj =
  options:
    value: yes
  fn: ->
    {}
    null
ok obj.options.value is yes
ok obj.fn() is null

# Implicit objects with wacky indentation:
obj =
  'reverse': (obj) ->
    Array.prototype.reverse.call obj
  abc: ->
    @reverse(
      @reverse @reverse ['a', 'b', 'c'].reverse()
    )
  one: [1, 2,
    a: 'b'
  3, 4]
  red:
    orange:
          yellow:
                  green: 'blue'
    indigo: 'violet'
  misdent: [[],
  [],
                  [],
      []]
ok obj.abc().join(' ') is 'a b c'
ok obj.one.length is 5
ok obj.one[4] is 4
ok obj.one[2].a is 'b'
ok (key for key of obj.red).length is 2
ok obj.red.orange.yellow.green is 'blue'
ok obj.red.indigo is 'violet'
ok obj.misdent.toString() is ',,,'

#542: Objects leading expression statement should be parenthesized.
{f: -> ok yes }.f() + 1

# String-keyed objects shouldn't suppress newlines.
one =
  '>!': 3
six: -> 10
ok not one.six

# Shorthand objects with property references.
obj =
  ### comment one ###
  ### comment two ###
  one: 1
  two: 2
  object: -> {@one, @two}
  list:   -> [@one, @two]
result = obj.object()
eq result.one, 1
eq result.two, 2
eq result.two, obj.list()[1]

third = (a, b, c) -> c
obj =
  one: 'one'
  two: third 'one', 'two', 'three'
ok obj.one is 'one'
ok obj.two is 'three'
