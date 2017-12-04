# Assignment
# ----------

# * Assignment
# * Compound Assignment
# * Destructuring Assignment
# * Context Property (@) Assignment
# * Existential Assignment (?=)
# * Assignment to variables similar to generated variables

test "context property assignment (using @)", ->
  nonce = {}
  addMethod = ->
    @method = -> nonce
    this
  eq nonce, addMethod.call({}).method()

test "unassignable values", ->
  nonce = {}
  for nonref in ['', '""', '0', 'f()'].concat CoffeeScript.RESERVED
    eq nonce, (try CoffeeScript.compile "#{nonref} = v" catch e then nonce)

# Compound Assignment

test "boolean operators", ->
  nonce = {}

  a  = 0
  a or= nonce
  eq nonce, a

  b  = 1
  b or= nonce
  eq 1, b

  c = 0
  c and= nonce
  eq 0, c

  d = 1
  d and= nonce
  eq nonce, d

  # ensure that RHS is treated as a group
  e = f = false
  e and= f or true
  eq false, e

test "compound assignment as a sub expression", ->
  [a, b, c] = [1, 2, 3]
  eq 6, (a + b += c)
  eq 1, a
  eq 5, b
  eq 3, c

# *note: this test could still use refactoring*
test "compound assignment should be careful about caching variables", ->
  count = 0
  list = []

  list[++count] or= 1
  eq 1, list[1]
  eq 1, count

  list[++count] ?= 2
  eq 2, list[2]
  eq 2, count

  list[count++] and= 6
  eq 6, list[2]
  eq 3, count

  base = ->
    ++count
    base

  base().four or= 4
  eq 4, base.four
  eq 4, count

  base().five ?= 5
  eq 5, base.five
  eq 5, count

  eq 5, base().five ?= 6
  eq 6, count

test "compound assignment with implicit objects", ->
  obj = undefined
  obj ?=
    one: 1

  eq 1, obj.one

  obj and=
    two: 2

  eq undefined, obj.one
  eq         2, obj.two

test "compound assignment (math operators)", ->
  num = 10
  num -= 5
  eq 5, num

  num *= 10
  eq 50, num

  num /= 10
  eq 5, num

  num %= 3
  eq 2, num

test "more compound assignment", ->
  a = {}
  val = undefined
  val ||= a
  val ||= true
  eq a, val

  b = {}
  val &&= true
  eq val, true
  val &&= b
  eq b, val

  c = {}
  val = null
  val ?= c
  val ?= true
  eq c, val

test "#1192: assignment starting with object literals", ->
  doesNotThrow (-> CoffeeScript.run "{}.p = 0")
  doesNotThrow (-> CoffeeScript.run "{}.p++")
  doesNotThrow (-> CoffeeScript.run "{}[0] = 1")
  doesNotThrow (-> CoffeeScript.run """{a: 1, 'b', "#{1}": 2}.p = 0""")
  doesNotThrow (-> CoffeeScript.run "{a:{0:{}}}.a[0] = 0")


# Destructuring Assignment

test "empty destructuring assignment", ->
  {} = {}
  [] = []

test "chained destructuring assignments", ->
  [a] = {0: b} = {'0': c} = [nonce={}]
  eq nonce, a
  eq nonce, b
  eq nonce, c

test "variable swapping to verify caching of RHS values when appropriate", ->
  a = nonceA = {}
  b = nonceB = {}
  c = nonceC = {}
  [a, b, c] = [b, c, a]
  eq nonceB, a
  eq nonceC, b
  eq nonceA, c
  [a, b, c] = [b, c, a]
  eq nonceC, a
  eq nonceA, b
  eq nonceB, c
  fn = ->
    [a, b, c] = [b, c, a]
  arrayEq [nonceA,nonceB,nonceC], fn()
  eq nonceA, a
  eq nonceB, b
  eq nonceC, c

test "#713: destructuring assignment should return right-hand-side value", ->
  nonces = [nonceA={},nonceB={}]
  eq nonces, [a, b] = [c, d] = nonces
  eq nonceA, a
  eq nonceA, c
  eq nonceB, b
  eq nonceB, d

test "#4787 destructuring of objects within arrays", ->
  arr = [1, {a:1, b:2}]
  [...,{a, b}] = arr
  eq a, 1
  eq b, arr[1].b
  deepEqual {a, b}, arr[1]

test "#4798 destructuring of objects with splat within arrays", ->
  arr = [1, {a:1, b:2}]
  [...,{a, r...}] = arr
  eq a, 1
  deepEqual r, {b:2}
  [b, {q...}] = arr
  eq b, 1
  deepEqual q, arr[1]
  eq q.b, r.b
  eq q.a, a

test "destructuring assignment with splats", ->
  a = {}; b = {}; c = {}; d = {}; e = {}
  [x,y...,z] = [a,b,c,d,e]
  eq a, x
  arrayEq [b,c,d], y
  eq e, z

  # Should not trigger implicit call, e.g. rest ... => rest(...)
  [x,y ...,z] = [a,b,c,d,e]
  eq a, x
  arrayEq [b,c,d], y
  eq e, z

test "deep destructuring assignment with splats", ->
  a={}; b={}; c={}; d={}; e={}; f={}; g={}; h={}; i={}
  [u, [v, w..., x], y..., z] = [a, [b, c, d, e], f, g, h, i]
  eq a, u
  eq b, v
  arrayEq [c,d], w
  eq e, x
  arrayEq [f,g,h], y
  eq i, z

test "destructuring assignment with objects", ->
  a={}; b={}; c={}
  obj = {a,b,c}
  {a:x, b:y, c:z} = obj
  eq a, x
  eq b, y
  eq c, z

test "deep destructuring assignment with objects", ->
  a={}; b={}; c={}; d={}
  obj = {
    a
    b: {
      'c': {
        d: [
          b
          {e: c, f: d}
        ]
      }
    }
  }
  {a: w, 'b': {c: d: [x, {'f': z, e: y}]}} = obj
  eq a, w
  eq b, x
  eq c, y
  eq d, z

test "destructuring assignment with objects and splats", ->
  a={}; b={}; c={}; d={}
  obj = a: b: [a, b, c, d]
  {a: b: [y, z...]} = obj
  eq a, y
  arrayEq [b,c,d], z

  # Should not trigger implicit call, e.g. rest ... => rest(...)
  {a: b: [y, z ...]} = obj
  eq a, y
  arrayEq [b,c,d], z

test "destructuring assignment against an expression", ->
  a={}; b={}
  [y, z] = if true then [a, b] else [b, a]
  eq a, y
  eq b, z

test "destructuring assignment with objects and splats: ES2015", ->
  obj = {a: 1, b: 2, c: 3, d: 4, e: 5}
  throws (-> CoffeeScript.compile "{a, r..., s...} = x"), null, "multiple rest elements are disallowed"
  throws (-> CoffeeScript.compile "{a, r..., s..., b} = x"), null, "multiple rest elements are disallowed"
  prop = "b"
  {a, b, r...} = obj
  eq a, 1
  eq b, 2
  eq r.e, obj.e
  eq r.a, undefined
  {d, c: x, r...} = obj
  eq x, 3
  eq d, 4
  eq r.c, undefined
  eq r.b, 2
  {a, 'b': z, g = 9, r...} = obj
  eq g, 9
  eq z, 2
  eq r.b, undefined

test "destructuring assignment with splats and default values", ->
  obj = {}
  c = {b: 1}
  { a: {b} = c, d...} = obj

  eq b, 1
  deepEqual d, {}

  # Should not trigger implicit call, e.g. rest ... => rest(...)
  {
    a: {b} = c
    d ...
  } = obj

  eq b, 1
  deepEqual d, {}

test "destructuring assignment with splat with default value", ->
  obj = {}
  c = {val: 1}
  { a: {b...} = c } = obj

  deepEqual b, val: 1

test "destructuring assignment with multiple splats in different objects", ->
  obj = { a: {val: 1}, b: {val: 2} }
  { a: {a...}, b: {b...} } = obj
  deepEqual a, val: 1
  deepEqual b, val: 2

  o = {
    props: {
      p: {
        n: 1
        m: 5
      }
      s: 6
    }
  }
  {p: {m, q..., t = {obj...}}, r...} = o.props
  eq m, o.props.p.m
  deepEqual r, s: 6
  deepEqual q, n: 1
  deepEqual t, obj

  @props = o.props
  {p: {m}, r...} = @props
  eq m, @props.p.m
  deepEqual r, s: 6

  {p: {m}, r...} = {o.props..., p:{m:9}}
  eq m, 9

  # Should not trigger implicit call, e.g. rest ... => rest(...)
  {
    a: {
      a ...
    }
    b: {
      b ...
    }
  } = obj
  deepEqual a, val: 1
  deepEqual b, val: 2

test "destructuring assignment with dynamic keys and splats", ->
  i = 0
  foo = -> ++i

  obj = {1: 'a', 2: 'b'}
  { "#{foo()}": a, b... } = obj

  eq a, 'a'
  eq i, 1
  deepEqual b, 2: 'b'

# Tests from https://babeljs.io/docs/plugins/transform-object-rest-spread/.
test "destructuring assignment with objects and splats: Babel tests", ->
  # What Babel calls “rest properties:”
  { x, y, z... } = { x: 1, y: 2, a: 3, b: 4 }
  eq x, 1
  eq y, 2
  deepEqual z, { a: 3, b: 4 }

  # What Babel calls “spread properties:”
  n = { x, y, z... }
  deepEqual n, { x: 1, y: 2, a: 3, b: 4 }

  # Should not trigger implicit call, e.g. rest ... => rest(...)
  { x, y, z ... } = { x: 1, y: 2, a: 3, b: 4 }
  eq x, 1
  eq y, 2
  deepEqual z, { a: 3, b: 4 }

  n = { x, y, z ... }
  deepEqual n, { x: 1, y: 2, a: 3, b: 4 }

test "deep destructuring assignment with objects: ES2015", ->
  a1={}; b1={}; c1={}; d1={}
  obj = {
    a: a1
    b: {
      'c': {
        d: {
          b1
          e: c1
          f: d1
        }
      }
    }
    b2: {b1, c1}
  }
  {a: w, b: {c: {d: {b1: bb, r1...}}}, r2...} = obj
  eq r1.e, c1
  eq r2.b, undefined
  eq bb, b1
  eq r2.b2, obj.b2

  # Should not trigger implicit call, e.g. rest ... => rest(...)
  {a: w, b: {c: {d: {b1: bb, r1 ...}}}, r2 ...} = obj
  eq r1.e, c1
  eq r2.b, undefined
  eq bb, b1
  eq r2.b2, obj.b2

test "deep destructuring assignment with defaults: ES2015", ->
  obj =
    b: { c: 1, baz: 'qux' }
    foo: 'bar'
  j =
    f: 'world'
  i =
    some: 'prop'
  {
    a...
    b: { c, d... }
    e: {
      f: hello
      g: { h... } = i
    } = j
  } = obj

  deepEqual a, foo: 'bar'
  eq c, 1
  deepEqual d, baz: 'qux'
  eq hello, 'world'
  deepEqual h, some: 'prop'

  # Should not trigger implicit call, e.g. rest ... => rest(...)
  {
    a ...
    b: {
      c,
      d ...
    }
    e: {
      f: hello
      g: {
        h ...
      } = i
    } = j
  } = obj

  deepEqual a, foo: 'bar'
  eq c, 1
  deepEqual d, baz: 'qux'
  eq hello, 'world'
  deepEqual h, some: 'prop'

test "object spread properties: ES2015", ->
  obj = {a: 1, b: 2, c: 3, d: 4, e: 5}
  obj2 = {obj..., c:9}
  eq obj2.c, 9
  eq obj.a, obj2.a

  # Should not trigger implicit call, e.g. rest ... => rest(...)
  obj2 = {
    obj ...
    c:9
  }
  eq obj2.c, 9
  eq obj.a, obj2.a

  obj2 = {obj..., a: 8, c: 9, obj...}
  eq obj2.c, 3
  eq obj.a, obj2.a

  # Should not trigger implicit call, e.g. rest ... => rest(...)
  obj2 = {
    obj ...
    a: 8
    c: 9
    obj ...
  }
  eq obj2.c, 3
  eq obj.a, obj2.a

  obj3 = {obj..., b: 7, g: {obj2..., c: 1}}
  eq obj3.g.c, 1
  eq obj3.b, 7
  deepEqual obj3.g, {obj..., c: 1}

  (({a, b, r...}) ->
    eq 1, a
    deepEqual r, {c: 3, d: 44, e: 55}
  ) {obj2..., d: 44, e: 55}

  obj = {a: 1, b: 2, c: {d: 3, e: 4, f: {g: 5}}}
  obj4 = {a: 10, obj.c...}
  eq obj4.a, 10
  eq obj4.d, 3
  eq obj4.f.g, 5
  deepEqual obj4.f, obj.c.f

  # Should not trigger implicit call, e.g. rest ... => rest(...)
  (({
    a
    b
    r ...
    }) ->
    eq 1, a
    deepEqual r, {c: 3, d: 44, e: 55}
  ) {
    obj2 ...
    d: 44
    e: 55
  }

  # Should not trigger implicit call, e.g. rest ... => rest(...)
  obj4 = {
    a: 10
    obj.c ...
  }
  eq obj4.a, 10
  eq obj4.d, 3
  eq obj4.f.g, 5
  deepEqual obj4.f, obj.c.f

  obj5 = {obj..., ((k) -> {b: k})(99)...}
  eq obj5.b, 99
  deepEqual obj5.c, obj.c

  # Should not trigger implicit call, e.g. rest ... => rest(...)
  obj5 = {
    obj ...
    ((k) -> {b: k})(99) ...
  }
  eq obj5.b, 99
  deepEqual obj5.c, obj.c

  fn = -> {c: {d: 33, e: 44, f: {g: 55}}}
  obj6 = {obj..., fn()...}
  eq obj6.c.d, 33
  deepEqual obj6.c, {d: 33, e: 44, f: {g: 55}}

  obj7 = {obj..., fn()..., {c: {d: 55, e: 66, f: {77}}}...}
  eq obj7.c.d, 55
  deepEqual obj6.c, {d: 33, e: 44, f: {g: 55}}

  # Should not trigger implicit call, e.g. rest ... => rest(...)
  obj7 = {
    obj ...
    fn() ...
    {c: {d: 55, e: 66, f: {77}}} ...
  }
  eq obj7.c.d, 55
  deepEqual obj6.c, {d: 33, e: 44, f: {g: 55}}

  obj =
    a:
      b:
        c:
          d:
            e: {}
  obj9 = {a:1, obj.a.b.c..., g:3}
  deepEqual obj9.d, {e: {}}

  a = "a"
  c = "c"
  obj9 = {a:1, obj[a].b[c]..., g:3}
  deepEqual obj9.d, {e: {}}

  obj9 = {a:1, obj.a["b"].c["d"]..., g:3}
  deepEqual obj9["e"], {}

test "bracket insertion when necessary", ->
  [a] = [0] ? [1]
  eq a, 0

# for implicit destructuring assignment in comprehensions, see the comprehension tests

test "destructuring assignment with context (@) properties", ->
  a={}; b={}; c={}; d={}; e={}
  obj =
    fn: () ->
      local = [a, {b, c}, d, e]
      [@a, {b: @b, c: @c}, @d, @e] = local
  eq undefined, obj[key] for key in ['a','b','c','d','e']
  obj.fn()
  eq a, obj.a
  eq b, obj.b
  eq c, obj.c
  eq d, obj.d
  eq e, obj.e

test "#1024: destructure empty assignments to produce javascript-like results", ->
  eq 2 * [] = 3 + 5, 16

test "#1005: invalid identifiers allowed on LHS of destructuring assignment", ->
  disallowed = ['eval', 'arguments'].concat CoffeeScript.RESERVED
  throws (-> CoffeeScript.compile "[#{disallowed.join ', '}] = x"), null, 'all disallowed'
  throws (-> CoffeeScript.compile "[#{disallowed.join '..., '}...] = x"), null, 'all disallowed as splats'
  t = tSplat = null
  for v in disallowed when v isnt 'class' # `class` by itself is an expression
    throws (-> CoffeeScript.compile t), null, t = "[#{v}] = x"
    throws (-> CoffeeScript.compile tSplat), null, tSplat = "[#{v}...] = x"
  doesNotThrow ->
    for v in disallowed
      CoffeeScript.compile "[a.#{v}] = x"
      CoffeeScript.compile "[a.#{v}...] = x"
      CoffeeScript.compile "[@#{v}] = x"
      CoffeeScript.compile "[@#{v}...] = x"

test "#2055: destructuring assignment with `new`", ->
  {length} = new Array
  eq 0, length

test "#156: destructuring with expansion", ->
  array = [1..5]
  [first, ..., last] = array
  eq 1, first
  eq 5, last
  [..., lastButOne, last] = array
  eq 4, lastButOne
  eq 5, last
  [first, second, ..., last] = array
  eq 2, second
  [..., last] = 'strings as well -> x'
  eq 'x', last
  throws (-> CoffeeScript.compile "[1, ..., 3]"),        null, "prohibit expansion outside of assignment"
  throws (-> CoffeeScript.compile "[..., a, b...] = c"), null, "prohibit expansion and a splat"
  throws (-> CoffeeScript.compile "[...] = c"),          null, "prohibit lone expansion"

test "destructuring with dynamic keys", ->
  {"#{'a'}": a, """#{'b'}""": b, c} = {a: 1, b: 2, c: 3}
  eq 1, a
  eq 2, b
  eq 3, c
  throws -> CoffeeScript.compile '{"#{a}"} = b'

test "simple array destructuring defaults", ->
  [a = 1] = []
  eq 1, a
  [a = 2] = [undefined]
  eq 2, a
  [a = 3] = [null]
  eq null, a # Breaking change in CS2: per ES2015, default values are applied for `undefined` but not for `null`.
  [a = 4] = [0]
  eq 0, a
  arr = [a = 5]
  eq 5, a
  arrayEq [5], arr

test "simple object destructuring defaults", ->
  {b = 1} = {}
  eq b, 1
  {b = 2} = {b: undefined}
  eq b, 2
  {b = 3} = {b: null}
  eq b, null # Breaking change in CS2: per ES2015, default values are applied for `undefined` but not for `null`.
  {b = 4} = {b: 0}
  eq b, 0

  {b: c = 1} = {}
  eq c, 1
  {b: c = 2} = {b: undefined}
  eq c, 2
  {b: c = 3} = {b: null}
  eq c, null # Breaking change in CS2: per ES2015, default values are applied for `undefined` but not for `null`.
  {b: c = 4} = {b: 0}
  eq c, 0

test "multiple array destructuring defaults", ->
  [a = 1, b = 2, c] = [undefined, 12, 13]
  eq a, 1
  eq b, 12
  eq c, 13
  [a, b = 2, c = 3] = [undefined, 12, 13]
  eq a, undefined
  eq b, 12
  eq c, 13
  [a = 1, b, c = 3] = [11, 12]
  eq a, 11
  eq b, 12
  eq c, 3

test "multiple object destructuring defaults", ->
  {a = 1, b: bb = 2, 'c': c = 3, "#{0}": d = 4} = {"#{'b'}": 12}
  eq a, 1
  eq bb, 12
  eq c, 3
  eq d, 4

test "array destructuring defaults with splats", ->
  [..., a = 9] = []
  eq a, 9
  [..., b = 9] = [19]
  eq b, 19

test "deep destructuring assignment with defaults", ->
  [a, [{b = 1, c = 3}] = [c: 2]] = [0]
  eq a, 0
  eq b, 1
  eq c, 2

test "destructuring assignment with context (@) properties and defaults", ->
  a={}; b={}; c={}; d={}; e={}
  obj =
    fn: () ->
      local = [a, {b, c: undefined}, d]
      [@a, {b: @b = b, @c = c}, @d, @e = e] = local
  eq undefined, obj[key] for key in ['a','b','c','d','e']
  obj.fn()
  eq a, obj.a
  eq b, obj.b
  eq c, obj.c
  eq d, obj.d
  eq e, obj.e

test "destructuring assignment with defaults single evaluation", ->
  callCount = 0
  fn = -> callCount++
  [a = fn()] = []
  eq 0, a
  eq 1, callCount
  [a = fn()] = [10]
  eq 10, a
  eq 1, callCount
  {a = fn(), b: c = fn()} = {a: 20, b: undefined}
  eq 20, a
  eq c, 1
  eq callCount, 2


# Existential Assignment

test "existential assignment", ->
  nonce = {}
  a = false
  a ?= nonce
  eq false, a
  b = undefined
  b ?= nonce
  eq nonce, b
  c = null
  c ?= nonce
  eq nonce, c

test "#1627: prohibit conditional assignment of undefined variables", ->
  throws (-> CoffeeScript.compile "x ?= 10"),        null, "prohibit (x ?= 10)"
  throws (-> CoffeeScript.compile "x ||= 10"),       null, "prohibit (x ||= 10)"
  throws (-> CoffeeScript.compile "x or= 10"),       null, "prohibit (x or= 10)"
  throws (-> CoffeeScript.compile "do -> x ?= 10"),  null, "prohibit (do -> x ?= 10)"
  throws (-> CoffeeScript.compile "do -> x ||= 10"), null, "prohibit (do -> x ||= 10)"
  throws (-> CoffeeScript.compile "do -> x or= 10"), null, "prohibit (do -> x or= 10)"
  doesNotThrow (-> CoffeeScript.compile "x = null; x ?= 10"),        "allow (x = null; x ?= 10)"
  doesNotThrow (-> CoffeeScript.compile "x = null; x ||= 10"),       "allow (x = null; x ||= 10)"
  doesNotThrow (-> CoffeeScript.compile "x = null; x or= 10"),       "allow (x = null; x or= 10)"
  doesNotThrow (-> CoffeeScript.compile "x = null; do -> x ?= 10"),  "allow (x = null; do -> x ?= 10)"
  doesNotThrow (-> CoffeeScript.compile "x = null; do -> x ||= 10"), "allow (x = null; do -> x ||= 10)"
  doesNotThrow (-> CoffeeScript.compile "x = null; do -> x or= 10"), "allow (x = null; do -> x or= 10)"

  throws (-> CoffeeScript.compile "-> -> -> x ?= 10"), null, "prohibit (-> -> -> x ?= 10)"
  doesNotThrow (-> CoffeeScript.compile "x = null; -> -> -> x ?= 10"), "allow (x = null; -> -> -> x ?= 10)"

test "more existential assignment", ->
  global.temp ?= 0
  eq global.temp, 0
  global.temp or= 100
  eq global.temp, 100
  delete global.temp

test "#1348, #1216: existential assignment compilation", ->
  nonce = {}
  a = nonce
  b = (a ?= 0)
  eq nonce, b
  #the first ?= compiles into a statement; the second ?= compiles to a ternary expression
  eq a ?= b ?= 1, nonce

  if a then a ?= 2 else a = 3
  eq a, nonce

test "#1591, #1101: splatted expressions in destructuring assignment must be assignable", ->
  nonce = {}
  for nonref in ['', '""', '0', 'f()', '(->)'].concat CoffeeScript.RESERVED
    eq nonce, (try CoffeeScript.compile "[#{nonref}...] = v" catch e then nonce)

test "#1643: splatted accesses in destructuring assignments should not be declared as variables", ->
  nonce = {}
  accesses = ['o.a', 'o["a"]', '(o.a)', '(o.a).a', '@o.a', 'C::a', 'f().a', 'o?.a', 'o?.a.b', 'f?().a']
  for access in accesses
    for i,j in [1,2,3] #position can matter
      code =
        """
        nonce = {}; nonce2 = {}; nonce3 = {};
        @o = o = new (class C then a:{}); f = -> o
        [#{new Array(i).join('x,')}#{access}...] = [#{new Array(i).join('0,')}nonce, nonce2, nonce3]
        unless #{access}[0] is nonce and #{access}[1] is nonce2 and #{access}[2] is nonce3 then throw new Error('[...]')
        """
      eq nonce, unless (try CoffeeScript.run code, bare: true catch e then true) then nonce
  # subpatterns like `[[a]...]` and `[{a}...]`
  subpatterns = ['[sub, sub2, sub3]', '{0: sub, 1: sub2, 2: sub3}']
  for subpattern in subpatterns
    for i,j in [1,2,3]
      code =
        """
        nonce = {}; nonce2 = {}; nonce3 = {};
        [#{new Array(i).join('x,')}#{subpattern}...] = [#{new Array(i).join('0,')}nonce, nonce2, nonce3]
        unless sub is nonce and sub2 is nonce2 and sub3 is nonce3 then throw new Error('[sub...]')
        """
      eq nonce, unless (try CoffeeScript.run code, bare: true catch e then true) then nonce

test "#1838: Regression with variable assignment", ->
  name =
  'dave'

  eq name, 'dave'

test '#2211: splats in destructured parameters', ->
  doesNotThrow -> CoffeeScript.compile '([a...]) ->'
  doesNotThrow -> CoffeeScript.compile '([a...],b) ->'
  doesNotThrow -> CoffeeScript.compile '([a...],[b...]) ->'
  throws -> CoffeeScript.compile '([a...,[a...]]) ->'
  doesNotThrow -> CoffeeScript.compile '([a...,[b...]]) ->'

test '#2213: invocations within destructured parameters', ->
  throws -> CoffeeScript.compile '([a()])->'
  throws -> CoffeeScript.compile '([a:b()])->'
  throws -> CoffeeScript.compile '([a:b.c()])->'
  throws -> CoffeeScript.compile '({a()})->'
  throws -> CoffeeScript.compile '({a:b()})->'
  throws -> CoffeeScript.compile '({a:b.c()})->'

test '#2532: compound assignment with terminator', ->
  doesNotThrow -> CoffeeScript.compile """
  a = "hello"
  a +=
  "
  world
  !
  "
  """

test "#2613: parens on LHS of destructuring", ->
  a = {}
  [(a).b] = [1, 2, 3]
  eq a.b, 1

test "#2181: conditional assignment as a subexpression", ->
  a = false
  false && a or= true
  eq false, a
  eq false, not a or= true

test "#1500: Assignment to variables similar to generated variables", ->
  len = 0
  x = ((results = null; n) for n in [1, 2, 3])
  arrayEq [1, 2, 3], x
  eq 0, len

  for x in [1, 2, 3]
    f = ->
      i = 0
    f()
    eq 'undefined', typeof i

  ref = 2
  x = ref * 2 ? 1
  eq x, 4
  eq 'undefined', typeof ref1

  x = {}
  base = -> x
  name = -1
  base()[-name] ?= 2
  eq x[1], 2
  eq base(), x
  eq name, -1

  f = (@a, a) -> [@a, a]
  arrayEq [1, 2], f.call scope = {}, 1, 2
  eq 1, scope.a

  try throw 'foo'
  catch error
    eq error, 'foo'

  eq error, 'foo'

  doesNotThrow -> CoffeeScript.compile '(@slice...) ->'

test "Assignment to variables similar to helper functions", ->
  f = (slice...) -> slice
  arrayEq [1, 2, 3], f 1, 2, 3
  eq 'undefined', typeof slice1

  class A
  class B extends A
    extend = 3
    hasProp = 4
    value: 5
    method: (bind, bind1) => [bind, bind1, extend, hasProp, @value]
  {method} = new B
  arrayEq [1, 2, 3, 4, 5], method 1, 2

  modulo = -1 %% 3
  eq 2, modulo

  indexOf = [1, 2, 3]
  ok 2 in indexOf

test "#4566: destructuring with nested default values", ->
  {a: {b = 1}} = a: {}
  eq 1, b

  {c: {d} = {}} = c: d: 3
  eq 3, d

  {e: {f = 5} = {}} = {}
  eq 5, f

test "#4674: _extends utility for object spreads 1", ->
  eqJS(
    "{a, b..., c..., d}"
    """
      var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

      _extends({a}, b, c, {d});
    """
  )

test "#4674: _extends utility for object spreads 2", ->
  _extends = -> 3
  a = b: 1
  c = d: 2
  e = {a..., c...}
  eq e.b, 1
  eq e.d, 2

test "#4673: complex destructured object spread variables", ->
  b = c: 1
  {{a...}...} = b
  eq a.c, 1

  d = {}
  {d.e...} = f: 1
  eq d.e.f, 1

  {{g}...} = g: 1
  eq g, 1
