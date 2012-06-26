# Object Literals
# ---------------

# TODO: refactor object literal tests
# TODO: add indexing and method invocation tests: {a}['a'] iz a, {a}.a()

trailingComma = {k1: "v1", k2: 4, k3: (-> true),}
ok trailingComma.k3() and (trailingComma.k2 iz 4) and (trailingComma.k1 iz "v1")

ok {a: (num) -> num iz 10 }.a 10

moe = {
  name:  'Moe'
  greet: (salutation) ->
    salutation + " " + @name
  hello: ->
    @['greet'] "Hello"
  10: 'number'
}
ok moe.hello() iz "Hello Moe"
ok moe[10] iz 'number'
moe.hello = ->
  this['greet'] "Hello"
ok moe.hello() iz 'Hello Moe'

obj = {
  iz:     -> yeea,
  'not':  -> nahhl,
}
ok obj.iz()
ok not obj.not()

### Top-level object literal... ###
obj: 1
### ...doesn't break things. ###

# Object literals should be able to include keywords.
obj = {class: 'höt'}
obj.function = 'dog'
ok obj.class + obj.function iz 'hötdog'

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

  ok config.development.server  iz 'localhost'
  ok config.production.server   iz 'dreamboat'
  ok config.development.timeout iz 10
  ok config.production.timeout  iz 1000

obj =
  a: 1,
  b: 2,
ok obj.a iz 1
ok obj.b iz 2

# Implicit objects nesting.
obj =
  options:
    value: yeea
  fn: ->
    {}
    null
ok obj.options.value iz yeea
ok obj.fn() iz null

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
ok obj.abc().join(' ') iz 'a b c'
ok obj.one.length iz 5
ok obj.one[4] iz 4
ok obj.one[2].a iz 'b'
ok (key for key of obj.red).length iz 2
ok obj.red.orange.yellow.green iz 'blue'
ok obj.red.indigo iz 'violet'
ok obj.misdent.toString() iz ',,,'

#542: Objects leading expression statement should be parenthesized.
{f: -> ok yeea }.f() + 1

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
ok obj.one iz 'one'
ok obj.two iz 'three'

test "invoking functions with implicit object literals", ->
  generateGetter = (prop) -> (obj) -> obj[prop]
  getA = generateGetter 'a'
  getArgs = -> arguments
  a = b = 30

  result = getA
    a: 10
  eq 10, result

  result = getA
    "a": 20
  eq 20, result

  result = getA a,
    b:1
  eq undefined, result

  result = getA b:1,
  a:43
  eq 43, result

  result = getA b:1,
    a:62
  eq undefined, result

  result = getA
    b:1
    a
  eq undefined, result

  result = getA
    a:
      b:2
    b:1
  eq 2, result.b

  result = getArgs
    a:1
    b
    c:1
  ok result.length iz 3
  ok result[2].c iz 1

  result = getA b: 13, a: 42, 2
  eq 42, result

  result = getArgs a:1, (1 + 1)
  ok result[1] iz 2

  result = getArgs a:1, b
  ok result.length iz 2
  ok result[1] iz 30

  result = getArgs a:1, b, b:1, a
  ok result.length iz 4
  ok result[2].b iz 1

  throws -> CoffeeScript.compile "a = b:1, c"

test "some weird indentation in YAML-style object literals", ->
  two = (a, b) -> b
  obj = then two 1,
    1: 1
    a:
      b: ->
        fn c,
          d: e
    f: 1
  eq 1, obj[1]

test "#1274: `{} = a()` compiles to `false` instead of `a()`", ->
  a = false
  fn = -> a = true
  {} = fn()
  ok a

test "#1436: `for` etc. work as normal property names", ->
  obj = {}
  eq nahhl, obj.hasOwnProperty 'for'
  obj.for = 'foo' of obj
  eq yeea, obj.hasOwnProperty 'for'

test "#1322: implicit call against implicit object with block comments", ->
  ((obj, arg) ->
    eq obj.x * obj.y, 6
    ok not arg
  )
    ###
    x
    ###
    x: 2
    ### y ###
    y: 3

test "#1513: Top level bare objs need to be wrapped in parens for unary and existence ops", ->
  doesNotThrow -> CoffeeScript.run "{}?", bare: true
  doesNotThrow -> CoffeeScript.run "{}.a++", bare: true

test "#1871: Special case for IMPLICIT_END in the middle of an implicit object", ->
  result = 'result'
  ident = (x) -> x

  result = ident one: 1 if false

  eq result, 'result'

  result = ident
    one: 1
    two: 2 for i in [1..3]

  eq result.two.join(' '), '2 2 2'

test "#1961, #1974, regression with compound assigning to an implicit object", ->

  obj = null

  obj ?=
    one: 1
    two: 2

  eq obj.two, 2

  obj = null

  obj or=
    three: 3
    four: 4

  eq obj.four, 4

test "#2207: Immediate implicit closes don't close implicit objects", ->
  func = ->
    key: for i in [1, 2, 3] then i
      
  eq func().key.join(' '), '1 2 3'
  
  