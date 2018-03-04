# Comments
# --------

# Block Comments

#*
  This is a here-comment.
  Kind of like a heredoc.
*#

test "block comments in objects", ->
  a = {}
  b = {}
  obj = {
    a: a
      #*
      block comment in object
      *#
    b: b
  }

  eq a, obj.a
  eq b, obj.b

test "block comments in YAML-style", ->
  a = {}
  b = {}
  obj =
    a: a
    #*
    block comment in YAML-style
    *#
    b: b

  eq a, obj.a
  eq b, obj.b


test "block comments in functions", ->
  nonce = {}

  fn1 = ->
    true
    #*
    false
    *#

  ok fn1()

  fn2 = ->
    #*
    block comment in function 1
    *#
    nonce

  eq nonce, fn2()

  fn3 = ->
    nonce
  #*
  block comment in function 2
  *#

  eq nonce, fn3()

  fn4 = ->
    one = ->
      #*
        block comment in function 3
      *#
      two = ->
        three = ->
          nonce

  eq nonce, fn4()()()()

test "block comments inside class bodies", ->
  class A
    a: ->

    #*
    Comment in class body 1
    *#
    b: ->

  ok A.prototype.b instanceof Function

  class B
    #*
    Comment in class body 2
    *#
    a: ->
    b: ->

  ok B.prototype.a instanceof Function

test "#2037: herecomments shouldn't imply line terminators", ->
  do (-> #* *#yes; fail)

test "#2916: block comment before implicit call with implicit object", ->
  fn = (obj) -> ok obj.a
  #* *#
  fn
    a: yes

test "#3132: Format single-line block comment nicely", ->
  eqJS """
  #* Single-line block comment without additional space here => *#""",
  """
  /* Single-line block comment without additional space here => */
  """

test "#3132: Format multiline block comment nicely", ->
  eqJS """
  #*
  # Multiline
  # block
  # comment
  *#""",
  """
  /*
   * Multiline
   * block
   * comment
   */
  """

test "#3132: Format simple block comment nicely", ->
  eqJS """
  #*
  No
  Preceding hash
  *#""",
  """
  /*
  No
  Preceding hash
  */
  """


test "#3132: Format indented block-comment nicely", ->
  eqJS """
  fn = ->
    #*
    # Indented
    Multiline
    *#
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
  #**
  # Multiline for jsdoc-"@doctags"
  #
  # @type {Function}
  *#
  fn = () -> 1
  """,
  """
  /**
   * Multiline for jsdoc-"@doctags"
   *
   * @type {Function}
   */
  var fn;

  fn = function() {
    return 1;
  };"""

# Although adequately working, block comment-placement is not yet perfect.
# (Considering a case where multiple variables have been declared …)
test "#3132: Format hand-made (raw) jsdoc-style block-comment nicely", ->
  eqJS """
  #**
   * Multiline for jsdoc-"@doctags"
   *
   * @type {Function}
  *#
  fn = () -> 1
  """,
  """
  /**
   * Multiline for jsdoc-"@doctags"
   *
   * @type {Function}
   */
  var fn;

  fn = function() {
    return 1;
  };"""

# Although adequately working, block comment-placement is not yet perfect.
# (Considering a case where multiple variables have been declared …)
test "#3132: Place block-comments nicely", ->
  eqJS """
  #**
  # A dummy class definition
  #
  # @class
  *#
  class DummyClass

    #**
    # @constructor
    *#
    constructor: ->

    #**
    # Singleton reference
    #
    # @type {DummyClass}
    *#
    @instance = new DummyClass()

  """,
  """
  /**
   * A dummy class definition
   *
   * @class
   */
  var DummyClass;

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

  }).call(this);"""

test "#3638: Demand a whitespace after # symbol", ->
  eqJS """
  #*
  #No
  #whitespace
  *#""",
  """
  /*
  #No
  #whitespace
   */"""


test "#3761: Multiline comment at end of an object", ->
  anObject =
    x: 3
    #*
    #Comment
    *#

  ok anObject.x is 3

test "#4375: UTF-8 characters in comments", ->
  # 智に働けば角が立つ、情に掉させば流される。
  ok yes

test "#4290: Block comments in array literals", ->
  arr = [
    #*  *#
    3
    #*
      What is the meaning of life, the universe, and everything?
    *#
    42
  ]
  arrayEq arr, [3, 42]

test "Block comments in array literals are properly indented 1", ->
  eqJS '''
  arr = [
    #* ! *#
    3
    42
  ]''', '''
  var arr;

  arr = [/* ! */ 3, 42];'''

test "Block comments in array literals are properly indented 2", ->
  eqJS '''
  arr = [
    #*  *#
    3
    #*
      What is the meaning of life, the universe, and everything?
    *#
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
    #*
      How many stooges are there?
    *#
    3
    #* Who’s on first? *#
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
      #*
        How many stooges are there?
      *#
      3
      #* Who’s on first? *#
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

test "Block comments trailing their attached token are properly indented", ->
  eqJS '''
  if indented
    if indentedAgain
      a
      #*
        Multiline
        comment
      *#
    a
  ''', '''
  if (indented) {
    if (indentedAgain) {
      a;
    }
    /*
      Multiline
      comment
    */
    a;
  }
  '''

test "Comments in proper order 1", ->
  eqJS '''
  # 1
  #* 2 *#
  # 3
  ''', '''
  // 1
  /* 2 */
  // 3
  '''

test "Comments in proper order 2", ->
  eqJS '''
  if indented
    # 1
    #* 2 *#
    # 3
    a
  ''', '''
  if (indented) {
    // 1
    /* 2 */
    // 3
    a;
  }
  '''

test "Line comments in classes are properly indented", ->
  eqJS '''
  class A extends B
    # This is a fine class.
    # I could tell you all about it, but what else do you need to know?
    constructor: ->
      # Something before `super`
      super()

    # This next method is a doozy!
    # A doozy, I tell ya!
    method: ->
      # Whoa.
      # Can you believe it?
      no

    #* Look out, incoming! *#
    anotherMethod: ->
      #* Ha! *#
      off
  ''', '''
  var A;

  A = class A extends B {
    // This is a fine class.
    // I could tell you all about it, but what else do you need to know?
    constructor() {
      // Something before `super`
      super();
    }

    // This next method is a doozy!
    // A doozy, I tell ya!
    method() {
      // Whoa.
      // Can you believe it?
      return false;
    }

    /* Look out, incoming! */
    anotherMethod() {
      /* Ha! */
      return false;
    }

  };'''

test "Block comment in an interpolated string", ->
  eqJS '"a#{#* Comment *#}b"', "`a${/* Comment */''}b`;"
  eqJS '"a#{#* 1 *#}b#{#* 2 *#}c"', "`a${/* 1 */''}b${/* 2 */''}c`;"

test "#4629: Block comment in CSX interpolation", ->
  eqJS '<div>{#* Comment *#}</div>', '<div>{/* Comment */}</div>;'
  eqJS '''
  <div>
  {#*
    Multiline
    Comment
  *#}
  </div>''', '''
  <div>
  {/*
    Multiline
    Comment
  */}
  </div>;'''

test "Line comment in an interpolated string", ->
  eqJS '''
  "a#{# Comment
  1}b"
  ''', '''
  `a${// Comment
  1}b`;'''

test "Line comments before `throw`", ->
  eqJS '''
  if indented
    1/0
    # Uh-oh!
    # You really shouldn’t have done that.
    throw DivideByZeroError()
  ''', '''
  if (indented) {
    1 / 0;
    // Uh-oh!
    // You really shouldn’t have done that.
    throw DivideByZeroError();
  }'''

test "Comments before if this exists", ->
  js = CoffeeScript.compile '''
  1
  # Comment
  if @huh?
    2
  '''
  ok js.includes '// Comment'

test "Comment before unary (`not`)", ->
  js = CoffeeScript.compile '''
  1
  # Comment
  if not doubleNegative
    dontDoIt()
  '''
  ok js.includes '// Comment'

test "Comments before postfix", ->
  js = CoffeeScript.compile '''
  # 1
  2

  # 3
  return unless window?

  #* 4 *#
  return if global?
  '''
  ok js.includes '// 3'
  ok js.includes '/* 4 */'

test "Comments before assignment if", ->
  js = CoffeeScript.compile '''
  1
  # Line comment
  a = if b
    3
  else
    4

  #* Block comment *#
  c = if d
    5
  '''
  ok js.includes '// Line comment'
  ok js.includes '/* Block comment */'


test "Comments before soak", ->
  js = CoffeeScript.compile '''
  # 1
  2

  # 3
  return unless window?.location?.hash

  #* 4 *#
  return if process?.env?.ENV
  '''
  ok js.includes '// 3'
  ok js.includes '/* 4 */'

test "Block comments can appear with function arguments", ->
  eqJS '''
  fn = (str #*: string *#, num #*: number *#) -> str + num
  ''', '''
  var fn;

  fn = function(str/*: string */, num/*: number */) {
    return str + num;
  };'''

test "Block comments can appear between function parameters and function opening brace", ->
  eqJS '''
  fn = (str #*: string *#, num #*: number *#) #*: string *# ->
    str + num
  ''', '''
  var fn;

  fn = function(str/*: string */, num/*: number */)/*: string */ {
    return str + num;
  };'''

test "Flow comment-based syntax support", ->
  eqJS '''
  # @flow

  fn = (str #*: string *#, num #*: number *#) #*: string *# ->
    str + num
  ''', '''
  // @flow
  var fn;

  fn = function(str/*: string */, num/*: number */)/*: string */ {
    return str + num;
  };'''

test "#4706: Flow comments around function parameters", ->
  eqJS '''
  identity = #*::<T>*# (value #*: T *#) #*: T *# ->
    value
  ''', '''
  var identity;

  identity = function/*::<T>*/(value/*: T */)/*: T */ {
    return value;
  };'''

test "#4706: Flow comments around function parameters", ->
  eqJS '''
  copy = arr.map(#*:: <T> *#(item #*: T *#) #*: T *# => item)
  ''', '''
  var copy;

  copy = arr.map(/*:: <T> */(item/*: T */)/*: T */ => {
    return item;
  });'''

test "#4706: Flow comments after class name", ->
  eqJS '''
  class Container #*::<T> *#
    method: #*::<U> *# () -> true
  ''', '''
  var Container;

  Container = class Container/*::<T> */ {
    method() {
      return true;
    }

  };'''

test "#4706: Identifiers with comments wrapped in parentheses remain wrapped", ->
  eqJS '(arr #*: Array<number> *#)', '(arr/*: Array<number> */);'
  eqJS 'other = (arr #*: any *#)', '''
  var other;

  other = (arr/*: any */);'''

test "#4706: Flow comments before class methods", ->
  eqJS '''
  class Container
    #*::
    method: (number) => string;
    method: (string) => number;
    *#
    method: -> true
  ''', '''
  var Container;

  Container = class Container {
    /*::
    method: (number) => string;
    method: (string) => number;
    */
    method() {
      return true;
    }

  };'''

test "#4706: Flow comments for class method params", ->
  eqJS '''
  class Container
    method: (param #*: string *#) -> true
  ''', '''
  var Container;

  Container = class Container {
    method(param/*: string */) {
      return true;
    }

  };'''

test "#4706: Flow comments for class method returns", ->
  eqJS '''
  class Container
    method: () #*: string *# -> true
  ''', '''
  var Container;

  Container = class Container {
    method()/*: string */ {
      return true;
    }

  };'''

test "#4706: Flow comments for function spread", ->
  eqJS '''
  method = (...rest #*: Array<string> *#) =>
  ''', '''
  var method;

  method = (...rest/*: Array<string> */) => {};'''

test "#4747: Flow comments for local variable declaration", ->
  eqJS 'a #*: number *# = 1', '''
  var a/*: number */;

  a = 1;
  '''

test "#4747: Flow comments for local variable declarations", ->
  eqJS '''
  a #*: number *# = 1
  b #*: string *# = 'c'
  ''', '''
  var a/*: number */, b/*: string */;

  a = 1;

  b = 'c';
  '''

test "#4747: Flow comments for local variable declarations with reassignment", ->
  eqJS '''
  a #*: number *# = 1
  b #*: string *# = 'c'
  a #* some other comment *# = 2
  ''', '''
  var a/*: number */, b/*: string */;

  a = 1;

  b = 'c';

  a/* some other comment */ = 2;
  '''

test "#4756: Comment before ? operation", ->
  eqJS '''
  do ->
    #* Comment *#
    @foo ? 42
  ''', '''
  (function() {
    var ref;
    /* Comment */
    return (ref = this.foo) != null ? ref : 42;
  })();
  '''


test "Mixing ### and #* *#", ->
  eqJS '''
    ### comment 1 ###
    a = 1
    #* comment 2 *#
  ''', '''
   /* comment 1 */
   var a;

   a = 1;

   /* comment 2 */
  '''
