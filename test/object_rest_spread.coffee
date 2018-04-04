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

  arr2 = [arr[1]]
  [{a2...}] = arr2
  eq a2.a, arr2[0].a

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

test "#4673: complex destructured object spread variables", ->
  b = c: 1
  {{a...}...} = b
  eq a.c, 1

  d = {}
  {d.e...} = f: 1
  eq d.e.f, 1

  {{g}...} = g: 1
  eq g, 1

test "rest element destructuring in function definition", ->
  obj = {a: 1, b: 2, c: 3, d: 4, e: 5}

  (({a, b, r...}) ->
    eq 1, a
    eq 2, b,
    deepEqual r, {c: 3, d: 4, e: 5}
  ) obj

  (({a: p, b, r...}, q) ->
    eq p, 1
    eq q, 9
    deepEqual r, {c: 3, d: 4, e: 5}
  ) {a:1, b:2, c:3, d:4, e:5}, 9

  # Should not trigger implicit call, e.g. rest ... => rest(...)
  (({
      a: p
      b
      r ...
    }, q) ->
    eq p, 1
    eq q, 9
    deepEqual r, {c: 3, d: 4, e: 5}
  ) {a:1, b:2, c:3, d:4, e:5}, 9

  a1={}; b1={}; c1={}; d1={}
  obj1 = {
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

  (({a: w, b: {c: {d: {b1: bb, r1...}}}, r2...}) ->
    eq a1, w
    eq bb, b1
    eq r2.b, undefined
    deepEqual r1, {e: c1, f: d1}
    deepEqual r2.b2, {b1, c1}
  ) obj1

  b = 3
  f = ({a, b...}) ->
  f {}
  eq 3, b

  (({a, r...} = {}) ->
    eq a, undefined
    deepEqual r, {}
  )()

  (({a, r...} = {}) ->
    eq a, 1
    deepEqual r, {b: 2, c: 3}
  ) {a: 1, b: 2, c: 3}

  f = ({a, r...} = {}) -> [a, r]
  deepEqual [undefined, {}], f()
  deepEqual [1, {b: 2}], f {a: 1, b: 2}
  deepEqual [1, {}], f {a: 1}

  f = ({a, r...} = {a: 1, b: 2}) -> [a, r]
  deepEqual [1, {b:2}], f()
  deepEqual [2, {}], f {a:2}
  deepEqual [3, {c:5}], f {a:3, c:5}

  f = ({ a: aa = 0, b: bb = 0 }) -> [aa, bb]
  deepEqual [0, 0], f {}
  deepEqual [0, 42], f {b:42}
  deepEqual [42, 0], f {a:42}
  deepEqual [42, 43], f {a:42, b:43}

test "#4673: complex destructured object spread variables", ->
  f = ({{a...}...}) ->
    a
  eq f(c: 1).c, 1

  g = ({@y...}) ->
    eq @y.b, 1
  g b: 1
