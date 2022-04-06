# Formatting
# ----------

# TODO: maybe this file should be split up into their respective sections:
#   operators -> operators
#   array literals -> array literals
#   string literals -> string literals
#   function invocations -> function invocations

doesNotThrowCompileError "a = then b"

test "multiple semicolon-separated statements in parentheticals", ->
  nonce = {}
  eq nonce, (1; 2; nonce)
  eq nonce, (-> return (1; 2; nonce))()

# * Line Continuation
#   * Property Accesss
#   * Operators
#   * Array Literals
#   * Function Invocations
#   * String Literals

# Property Access

test "chained accesses split on period/newline, backwards and forwards", ->
  str = 'abc'
  result = str.
    split('').
    reverse().
    reverse().
    reverse()
  arrayEq ['c','b','a'], result
  arrayEq ['c','b','a'], str.
    split('').
    reverse().
    reverse().
    reverse()
  result = str
    .split('')
    .reverse()
    .reverse()
    .reverse()
  arrayEq ['c','b','a'], result
  arrayEq ['c','b','a'],
    str
    .split('')
    .reverse()
    .reverse()
    .reverse()
  arrayEq ['c','b','a'],
    str.
    split('')
    .reverse().
    reverse()
    .reverse()

# Operators

test "newline suppression for operators", ->
  six =
    1 +
    2 +
    3
  eq 6, six

test "`?.` and `::` should continue lines", ->
  ok not (
    Date
    ::
    ?.foo
  )

  ok not (
    Date
    ?::
    ?.foo
  )
  #eq Object::toString, Date?.
  #prototype
  #::
  #?.foo

doesNotThrowCompileError """
  oh. yes
  oh?. true
  oh:: return
  """

doesNotThrowCompileError """
  a?[b..]
  a?[...b]
  a?[b..c]
  """

test "#1768: space between `::` and index is ignored", ->
  eq 'function', typeof String:: ['toString']

# Array Literals

test "indented array literals don't trigger whitespace rewriting", ->
  getArgs = -> arguments
  result = getArgs(
    [[[[[],
                  []],
                [[]]]],
      []])
  eq 1, result.length

# Function Invocations

doesNotThrowCompileError """
  obj = then fn 1,
    1: 1
    a:
      b: ->
        fn c,
          d: e
    f: 1
  """

# String Literals

test "indented heredoc", ->
  result = ((_) -> _)(
                """
                abc
                """)
  eq "abc", result

# Chaining - all open calls are closed by property access starting a new line
# * chaining after
#   * indented argument
#   * function block
#   * indented object
#
#   * single line arguments
#   * inline function literal
#   * inline object literal
#
# * chaining inside
#   * implicit object literal

test "chaining after outdent", ->
  id = (x) -> x

  # indented argument
  ff = id parseInt "ff",
    16
  .toString()
  eq '255', ff

  # function block
  str = 'abc'
  zero = parseInt str.replace /\w/, (letter) ->
    0
  .toString()
  eq '0', zero

  # indented object
  a = id id
    a: 1
  .a
  eq 1, a

test "#1495, method call chaining", ->
  str = 'abc'

  result = str.split ''
              .join ', '
  eq 'a, b, c', result

  result = str
  .split ''
  .join ', '
  eq 'a, b, c', result

  eq 'a, b, c', (str
    .split ''
    .join ', '
  )

  eq 'abc',
    'aaabbbccc'.replace /(\w)\1\1/g, '$1$1'
               .replace /([abc])\1/g, '$1'

  # Nested calls
  result = [1..3]
    .slice Math.max 0, 1
    .concat [3]
  arrayEq [2, 3, 3], result

  # Single line function arguments
  result = [1..6]
    .map (x) -> x * x
    .filter (x) -> x % 2 is 0
    .reverse()
  arrayEq [36, 16, 4], result

  # Single line implicit objects
  id = (x) -> x
  result = id a: 1
    .a
  eq 1, result

  # The parens are forced
  result = str.split(''.
    split ''
    .join ''
  ).join ', '
  eq 'a, b, c', result

test "chaining should not wrap spilling ternary", ->
  throwsCompileError """
    if 0 then 1 else g
      a: 42
    .h()
  """

test "chaining should wrap calls containing spilling ternary", ->
  f = (x) -> h: x
  id = (x) -> x
  result = f if true then 42 else id
      a: 2
  .h
  eq 42, result

test "chaining should work within spilling ternary", ->
  f = (x) -> h: x
  id = (x) -> x
  result = f if false then 1 else id
      a: 3
      .a
  eq 3, result.h

test "method call chaining inside objects", ->
  f = (x) -> c: 42
  result =
    a: f 1
    b: f a: 1
      .c
  eq 42, result.b

test "#4568: refine sameLine implicit object tagging", ->
  condition = yes
  fn = -> yes

  x =
    fn bar: {
      foo: 123
    } if not condition
  eq x, undefined

# Nested blocks caused by paren unwrapping
test "#1492: Nested blocks don't cause double semicolons", ->
  js = CoffeeScript.compile '(0;0)'
  eq -1, js.indexOf ';;'

test "#1195 Ignore trailing semicolons (before newlines or as the last char in a program)", ->
  preNewline = (numSemicolons) ->
    """
    nonce = {}; nonce2 = {}
    f = -> nonce#{Array(numSemicolons+1).join(';')}
    nonce2
    unless f() is nonce then throw new Error('; before linebreak should = newline')
    """
  CoffeeScript.run(preNewline(n), bare: true) for n in [1,2,3]

  lastChar = '-> lastChar;'
  doesNotThrowCompileError lastChar, bare: true

test "#1299: Disallow token misnesting", ->
  try
    CoffeeScript.compile '''
      [{
         ]}
    '''
    ok no
  catch e
    eq 'unmatched ]', e.message

test "#2981: Enforce initial indentation", ->
  try
    CoffeeScript.compile '  a\nb-'
    ok no
  catch e
    eq 'missing indentation', e.message

test "'single-line' expression containing multiple lines", ->
  doesNotThrowCompileError """
    (a, b) -> if a
      -a
    else if b
    then -b
    else null
  """

test "#1275: allow indentation before closing brackets", ->
  array = [
      1
      2
      3
    ]
  eq array, array
  do ->
  (
    a = 1
   )
  eq 1, a

test "don’t allow mixing of spaces and tabs for indentation", ->
  try
    CoffeeScript.compile '''
      new Layer
       x: 0
      	y: 1
    '''
    ok no
  catch e
    eq 'indentation mismatch', e.message

test "each code block that starts at indentation 0 can use a different style", ->
  doesNotThrowCompileError '''
      new Layer
       x: 0
       y: 1
      new Layer
      	x: 0
      	y: 1
    '''

test "tabs and spaces cannot be mixed for indentation", ->
  try
    CoffeeScript.compile '''
      new Layer
      	 x: 0
      	 y: 1
    '''
    ok no
  catch e
    eq 'mixed indentation', e.message

test "#4487: Handle unusual outdentation", ->
  a =
    switch 1
      when 2
          no
         when 3 then no
      when 1 then yes
  eq yes, a

  b = do ->
    if no
      if no
            1
       2
      3
  eq b, undefined

test "#3906: handle further indentation inside indented chain", ->
  eq 1, CoffeeScript.eval '''
    z = b: -> d: 2
    e = ->
    f = 3

    z
        .b ->
            c
        .d

    e(
        f
    )

    1
  '''

  eq 1, CoffeeScript.eval '''
    z = -> b: -> e: ->

    z()
        .b
            c: 'd'
        .e()

    f = [
        'g'
    ]

    1
  '''

  eq 1, CoffeeScript.eval '''
    z = -> c: -> c: ->

    z('b')
      .c 'a',
        {b: 'a'}
      .c()
    z(
      'b'
    )
    1
  '''

test "#3199: throw multiline implicit object", ->
  x = do ->
    if no then throw
      type: 'a'
      msg: 'b'
  eq undefined, x

  y = do ->
    if no then return
      type: 'a'
      msg: 'b'
  eq undefined, y

  y = do ->
    yield
      type: 'a'
      msg: 'b'

    if no then yield
      type: 'c'
      msg: 'd'

    1
  {value, done} = y.next()
  ok value.type is 'a' and done is no

  {value, done} = y.next()
  ok value is 1 and done is yes

test "#4576: multiple row function chaining", ->
  ->
    eq @a, 3
  .call a: 3

test "#4576: function chaining on separate rows", ->
  do ->
    Promise
    .resolve()
    .then ->
      yes
    .then ok

test "#3736: chaining after do IIFE", ->
  eq 3,
    do ->
      a: 3
    .a

  eq 3,
    do (b = (c) -> c) -> a: 3
    ?.a

  b = 3
  eq 3,
    do (
      b
      {d} = {}
    ) ->
      a: b
    .a

  # preserve existing chaining behavior for non-IIFE `do`
  b = c: -> 4
  eq 4,
    do b
    .c

test "#5168: allow indented property index", ->
  a = b: 3

  eq 3, a[
    if yes
      'b'
    else
      'c'
  ]

  d = [1, 2, 3]
  arrayEq [1, 2], d[
    ...2
  ]

  class A
    b: -> 3

  class B extends A
    c: ->
      super[
        'b'
      ]()

  eq 3, new B().c()

test "logical and/or should continue lines", ->
  ok not (
    yes
    and no
  )

  ok not (
    1
      and 0
  )

  ok 'abc'
    && 123

  ok 'abc'
  && 123

  ok 'abc'
  or 123

  ok 'abc'
    or 123

  ok 'abc'
  || 123

  ok 'abc'
    || 123

  a =
    and   : 'b'
    or    : 'a'
  ok 'a' is a.or

  b =
    or    : 'b'
    and   : 'a'
  ok 'a' is b.and

  yup = -> yes
  nope = -> no

  eq 3,
    yes
    and yup
      c: 2
    and 3

  eq 3,
    yes
      and yup
        c: 2
      and 3

  eq 3,
    no
    or nope
      c: 2
    or 3

  eq 3,
    no
      or nope
        c: 2
      or 3

  eq 5,
    yes
    and yup
      c: 2
      if yes
        3
      else
        4
    and 5

  eq 5,
    yes
      and yup
        c: 2
        if yes
          3
        else
          4
      and 5

  eq yes,
    yes
      and yup
        c: 2
        if yes
          3
        else
          4
          and 5

  eq yes,
    yes
      and yup
        c: 2
        if yes
          3
        else
          4
            and 5

  eq 2,
    no
    or nope -> 1
    or 2

  eq 2,
    no
      or nope -> 1
      or 2

  eq 2,
    no
    or nope ->
      1
    or 2

  eq 2,
    no
      or nope ->
        1
      or 2

  eq no,
    no
    or nope ->
      1
      or 2

  eq no,
    no
      or nope ->
        1
        or 2

  eq no,
    no
      or nope ->
        1
          or 2

  f = ({c}) -> c
  eq 3,
    yes
    and f
      c:
        no
        or 3

  eq 3,
    yes
    and f
      c:
        no
          or 3

  eq 1,
    yes
    and f
      c:
        1
    or 3

  eq 3,
    if yes
    and yes
      3

  eq 3,
    if yes
     and yes
      3

  eq 3,
    if yes
      and yes
      3

  eq 3,
    if yes
       and yes
      3

test "leading and/or should continue object property", ->
  obj =
    a: yes
      and yes
  eq yes, obj.a

  obj =
    b: 1
    a: yes
    and yes
  eq yes, obj.a

  obj =
    a: yes
        and yes
    b: 1
  eq yes, obj.a

  # when object doesn't start line, don't treat as continuation of object property
  f = -> no
  eq yes,
    f a: 1
      or yes
