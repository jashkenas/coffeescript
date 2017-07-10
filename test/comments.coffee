# Comments
# --------

# * Single-Line Comments
# * Block Comments

# Note: awkward spacing seen in some tests is likely intentional.

test "comments in objects", ->
  obj1 = {
  # comment
    # comment
      # comment
    one: 1
  # comment
    two: 2
      # comment
  }

  ok Object::hasOwnProperty.call(obj1,'one')
  eq obj1.one, 1
  ok Object::hasOwnProperty.call(obj1,'two')
  eq obj1.two, 2

test "comments in YAML-style objects", ->
  obj2 =
  # comment
    # comment
      # comment
    three: 3
  # comment
    four: 4
      # comment

  ok Object::hasOwnProperty.call(obj2,'three')
  eq obj2.three, 3
  ok Object::hasOwnProperty.call(obj2,'four')
  eq obj2.four, 4

test "comments following operators that continue lines", ->
  sum =
    1 +
    1 + # comment
    1
  eq 3, sum

test "comments in functions", ->
  fn = ->
  # comment
    false
    false   # comment
    false
    # comment

  # comment before return
    true

  ok fn()

  fn2 = -> #comment
    fn()
    # comment after return

  ok fn2()

test "trailing comment before an outdent", ->
  nonce = {}
  fn3 = ->
    if true
      undefined # comment
    nonce

  eq nonce, fn3()

test "comments in a switch", ->
  nonce = {}
  result = switch nonce #comment
    # comment
    when false then undefined
    # comment
    when null #comment
      undefined
    else nonce # comment

  eq nonce, result

test "comment with conditional statements", ->
  nonce = {}
  result = if false # comment
    undefined
  #comment
  else # comment
    nonce
    # comment
  eq nonce, result

test "spaced comments with conditional statements", ->
  nonce = {}
  result = if false
    undefined

  # comment
  else if false
    undefined

  # comment
  else
    nonce

  eq nonce, result


# Block Comments

###
  This is a here-comment.
  Kind of like a heredoc.
###

test "block comments in objects", ->
  a = {}
  b = {}
  obj = {
    a: a
    ###
    block comment in object
    ###
    b: b
  }

  eq a, obj.a
  eq b, obj.b

test "block comments in YAML-style", ->
  a = {}
  b = {}
  obj =
    a: a
    ###
    block comment in YAML-style
    ###
    b: b

  eq a, obj.a
  eq b, obj.b


test "block comments in functions", ->
  nonce = {}

  fn1 = ->
    true
    ###
    false
    ###

  ok fn1()

  fn2 = ->
    ###
    block comment in function 1
    ###
    nonce

  eq nonce, fn2()

  fn3 = ->
    nonce
  ###
  block comment in function 2
  ###

  eq nonce, fn3()

  fn4 = ->
    one = ->
      ###
        block comment in function 3
      ###
      two = ->
        three = ->
          nonce

  eq nonce, fn4()()()()

test "block comments inside class bodies", ->
  class A
    a: ->

    ###
    Comment in class body 1
    ###
    b: ->

  ok A.prototype.b instanceof Function

  class B
    ###
    Comment in class body 2
    ###
    a: ->
    b: ->

  ok B.prototype.a instanceof Function

test "#2037: herecomments shouldn't imply line terminators", ->
  do (-> ### ###yes; fail)

test "#2916: block comment before implicit call with implicit object", ->
  fn = (obj) -> ok obj.a
  ### ###
  fn
    a: yes

test "#3132: Format single-line block comment nicely", ->
  eqJS """
  ### Single-line block comment without additional space here => ###""",
  """
  /* Single-line block comment without additional space here => */
  """

test "#3132: Format multi-line block comment nicely", ->
  eqJS """
  ###
  # Multi-line
  # block
  # comment
  ###""",
  """
  /*
   * Multi-line
   * block
   * comment
   */
  """

test "#3132: Format simple block comment nicely", ->
  eqJS """
  ###
  No
  Preceding hash
  ###""",
  """
  /*
  No
  Preceding hash
  */
  """


test "#3132: Format indented block-comment nicely", ->
  eqJS """
  fn = ->
    ###
    # Indented
    Multiline
    ###
    1""",
  """
  var fn;

  fn = function() {
    /*
     * Indented
    Multiline
     */
    return 1;
  };
  """

# Although adequately working, block comment-placement is not yet perfect.
# (Considering a case where multiple variables have been declared …)
test "#3132: Format jsdoc-style block-comment nicely", ->
  eqJS """
  ###*
  # Multiline for jsdoc-"@doctags"
  #
  # @type {Function}
  ###
  fn = () -> 1
  """,
  """
  var fn;

  /**
   * Multiline for jsdoc-"@doctags"
   *
   * @type {Function}
   */
  fn = function() {
    return 1;
  };"""

# Although adequately working, block comment-placement is not yet perfect.
# (Considering a case where multiple variables have been declared …)
test "#3132: Format hand-made (raw) jsdoc-style block-comment nicely", ->
  eqJS """
  ###*
   * Multiline for jsdoc-"@doctags"
   *
   * @type {Function}
  ###
  fn = () -> 1
  """,
  """
  var fn;

  /**
   * Multiline for jsdoc-"@doctags"
   *
   * @type {Function}
   */
  fn = function() {
    return 1;
  };"""

# Although adequately working, block comment-placement is not yet perfect.
# (Considering a case where multiple variables have been declared …)
test "#3132: Place block-comments nicely", ->
  eqJS """
  ###*
  # A dummy class definition
  #
  # @class
  ###
  class DummyClass

    ###*
    # @constructor
    ###
    constructor: ->

    ###*
    # Singleton reference
    #
    # @type {DummyClass}
    ###
    @instance = new DummyClass()

  """,
  """
  var DummyClass;

  /**
   * A dummy class definition
   *
   * @class
   */
  DummyClass = (function() {
    class DummyClass {
      /**
       * @constructor
       */
      constructor() {}

    };

    /**
     * Singleton reference
     *
     * @type {DummyClass}
     */
    DummyClass.instance = new DummyClass();

    return DummyClass;

  })();"""

test "#3638: Demand a whitespace after # symbol", ->
  eqJS """
  ###
  #No
  #whitespace
  ###""",
  """
  /*
  #No
  #whitespace
   */"""


test "#3761: Multiline comment at end of an object", ->
  anObject =
    x: 3
    ###
    #Comment
    ###

  ok anObject.x is 3

test "#4375: UTF-8 characters in comments", ->
  # 智に働けば角が立つ、情に掉させば流される。
  ok yes

test "#4290: Block comments in array literals", ->
  arr = [
    ###  ###
    3
    ###
      What is the meaning of life, the universe, and everything?
    ###
    42
  ]
  arrayEq arr, [3, 42]

test "Block comments in array literals are properly indented 1", ->
  eqJS '''
  arr = [
    ### ! ###
    3
    42
  ]''', '''
  var arr;

  arr = [/* ! */ 3, 42];'''

test "Block comments in array literals are properly indented 2", ->
  eqJS '''
  arr = [
    ###  ###
    3
    ###
      What is the meaning of life, the universe, and everything?
    ###
    42
  ]''', '''
  var arr;

  arr = [
    /*  */
    3,
    /*
      What is the meaning of life, the universe, and everything?
    */
    42
  ];'''

test "Block comments in array literals are properly indented 3", ->
  eqJS '''
  arr = [
    ###
      How many stooges are there?
    ###
    3
    ### Who’s on first? ###
    'Who'
  ]''', '''
  var arr;

  arr = [
    /*
      How many stooges are there?
    */
    3,
    /* Who’s on first? */
    'Who'
  ];'''

test "Block comments in array literals are properly indented 4", ->
  eqJS '''
  if yes
    arr = [
      1
      ###
        How many stooges are there?
      ###
      3
      ### Who’s on first? ###
      'Who'
    ]''', '''
  var arr;

  if (true) {
    arr = [
      1,
      /*
        How many stooges are there?
      */
      3,
      /* Who’s on first? */
      'Who'
    ];
  }'''

test "Line comments in array literals are properly indented 1", ->
  eqJS '''
  arr = [
    # How many stooges are there?
    3
    # Who’s on first?
    'Who'
  ]''', '''
  var arr;

  arr = [
    // How many stooges are there?
    3,
    // Who’s on first?
    'Who'
  ];'''

test "Line comments in array literals are properly indented 2", ->
  eqJS '''
  arr = [
    # How many stooges are there?
    3
    # Who’s on first?
    'Who'
    # Who?
    {
      firstBase: 'Who'
      secondBase: 'What'
      leftField: 'Why'
    }
  ]''', '''
  var arr;

  arr = [
    // How many stooges are there?
    3,
    // Who’s on first?
    'Who',
    {
      // Who?
      firstBase: 'Who',
      secondBase: 'What',
      leftField: 'Why'
    }
  ];'''

test "Line comments are properly indented", ->
  eqJS '''
  # Unindented comment
  if yes
    # Comment indented one tab
    1
    if yes
      # Comment indented two tabs
      2
    else
      # Another comment indented two tabs
      # Yet another comment indented two tabs
      3
  else
    # Another comment indented one tab
    # Yet another comment indented one tab
    4

  # Another unindented comment''', '''
  // Unindented comment
  if (true) {
    // Comment indented one tab
    1;
    if (true) {
      // Comment indented two tabs
      2;
    } else {
      // Another comment indented two tabs
      // Yet another comment indented two tabs
      3;
    }
  } else {
    // Another comment indented one tab
    // Yet another comment indented one tab
    4;
  }

  // Another unindented comment'''

test "Line comments that trail code, followed by line comments that start a new line", ->
  eqJS '''
  a = ->
    b 1 # Trailing comment

  # Comment that starts a new line
  2
  ''', '''
  var a;

  a = function() {
    return b(1); // Trailing comment
  };

  // Comment that starts a new line
  2;
  '''

test "Line comment in an interpolated string", ->
  eqJS '''
  "a#{# comment
  1}b"
  ''', '''
  `a${// comment
  1}b`;'''
