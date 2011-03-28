# Assignment
# ----------

# * Assignment
# * Compound Assignment
# * Destructuring Assignment
# * Context Property (@) Assignment
# * Existential Assignment (?=)

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

test "compound assignments should not declare", ->
  # TODO: make description more clear
  # TODO: remove reference to Math
  eq Math, (-> Math or= 0)()


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


# Destructuring Assignment

test "empty destructuring assignment", ->
  {} = [] = undefined

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

test "#713", ->
  nonces = [nonceA={},nonceB={}]
  eq nonces, [a, b] = [c, d] = nonces
  eq nonceA, a
  eq nonceA, c
  eq nonceB, b
  eq nonceB, d

test "destructuring assignment with splats", ->
  a = {}; b = {}; c = {}; d = {}; e = {}
  [x,y...,z] = [a,b,c,d,e]
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

test "destructuring assignment against an expression", ->
  a={}; b={}
  [y, z] = if true then [a, b] else [b, a]
  eq a, y
  eq b, z

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

test "#1024", ->
  eq 2 * [] = 3 + 5, 16


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
  d ?= nonce
  eq nonce, d
