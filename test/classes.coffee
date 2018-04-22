# Classes
# -------

# * Class Definition
# * Class Instantiation
# * Inheritance and Super
# * ES2015+ Class Interoperability

test "classes with a four-level inheritance chain", ->

  class Base
    func: (string) ->
      "zero/#{string}"

    @static: (string) ->
      "static/#{string}"

  class FirstChild extends Base
    func: (string) ->
      super('one/') + string

  SecondChild = class extends FirstChild
    func: (string) ->
      super('two/') + string

  thirdCtor = ->
    @array = [1, 2, 3]

  class ThirdChild extends SecondChild
    constructor: ->
      super()
      thirdCtor.call this

    # Gratuitous comment for testing.
    func: (string) ->
      super('three/') + string

  result = (new ThirdChild).func 'four'

  ok result is 'zero/one/two/three/four'
  ok Base.static('word') is 'static/word'

  ok (new ThirdChild).array.join(' ') is '1 2 3'


test "constructors with inheritance and super", ->

  identity = (f) -> f

  class TopClass
    constructor: (arg) ->
      @prop = 'top-' + arg

  class SuperClass extends TopClass
    constructor: (arg) ->
      identity super 'super-' + arg

  class SubClass extends SuperClass
    constructor: ->
      identity super 'sub'

  ok (new SubClass).prop is 'top-super-sub'


test "'super' with accessors", ->
  class Base
    m: -> 4
    n: -> 5
    o: -> 6

  name = 'o'
  class A extends Base
    m: -> super()
    n: -> super.n()
    "#{name}": -> super()
    p: -> super[name]()

  a = new A
  eq 4, a.m()
  eq 5, a.n()
  eq 6, a.o()
  eq 6, a.p()


test "soaked 'super' invocation", ->
  class Base
    method: -> 2

  class A extends Base
    method: -> super?()
    noMethod: -> super?()

  a = new A
  eq 2, a.method()
  eq undefined, a.noMethod()

  name = 'noMethod'
  class B extends Base
    "#{'method'}": -> super?()
    "#{'noMethod'}": -> super?() ? super['method']()

  b = new B
  eq 2, b.method()
  eq 2, b.noMethod()

test "'@' referring to the current instance, and not being coerced into a call", ->

  class ClassName
    amI: ->
      @ instanceof ClassName

  obj = new ClassName
  ok obj.amI()


test "super() calls in constructors of classes that are defined as object properties", ->

  class Hive
    constructor: (name) -> @name = name

  class Hive.Bee extends Hive
    constructor: (name) -> super name

  maya = new Hive.Bee 'Maya'
  ok maya.name is 'Maya'


test "classes with JS-keyword properties", ->

  class Class
    class: 'class'
    name: -> @class

  instance = new Class
  ok instance.class is 'class'
  ok instance.name() is 'class'


test "Classes with methods that are pre-bound to the instance, or statically, to the class", ->

  class Dog
    constructor: (name) ->
      @name = name

    bark: =>
      "#{@name} woofs!"

    @static = =>
      new this('Dog')

  spark = new Dog('Spark')
  fido  = new Dog('Fido')
  fido.bark = spark.bark

  ok fido.bark() is 'Spark woofs!'

  obj = func: Dog.static

  ok obj.func().name is 'Dog'


test "a bound function in a bound function", ->

  class Mini
    num: 10
    generate: =>
      for i in [1..3]
        =>
          @num

  m = new Mini
  eq (func() for func in m.generate()).join(' '), '10 10 10'


test "contructor called with varargs", ->

  class Connection
    constructor: (one, two, three) ->
      [@one, @two, @three] = [one, two, three]

    out: ->
      "#{@one}-#{@two}-#{@three}"

  list = [3, 2, 1]
  conn = new Connection list...
  ok conn instanceof Connection
  ok conn.out() is '3-2-1'


test "calling super and passing along all arguments", ->

  class Parent
    method: (args...) -> @args = args

  class Child extends Parent
    method: -> super arguments...

  c = new Child
  c.method 1, 2, 3, 4
  ok c.args.join(' ') is '1 2 3 4'


test "classes wrapped in decorators", ->

  func = (klass) ->
    klass::prop = 'value'
    klass

  func class Test
    prop2: 'value2'

  ok (new Test).prop  is 'value'
  ok (new Test).prop2 is 'value2'


test "anonymous classes", ->

  obj =
    klass: class
      method: -> 'value'

  instance = new obj.klass
  ok instance.method() is 'value'


test "Implicit objects as static properties", ->

  class Static
    @static =
      one: 1
      two: 2

  ok Static.static.one is 1
  ok Static.static.two is 2


test "nothing classes", ->

  c = class
  ok c instanceof Function


test "classes with static-level implicit objects", ->

  class A
    @static = one: 1
    two: 2

  class B
    @static = one: 1,
    two: 2

  eq A.static.one, 1
  eq A.static.two, undefined
  eq (new A).two, 2

  eq B.static.one, 1
  eq B.static.two, 2
  eq (new B).two, undefined


test "classes with value'd constructors", ->

  counter = 0
  classMaker = ->
    inner = ++counter
    ->
      @value = inner
      @

  class One
    constructor: classMaker()

  class Two
    constructor: classMaker()

  eq (new One).value, 1
  eq (new Two).value, 2
  eq (new One).value, 1
  eq (new Two).value, 2


test "executable class bodies", ->

  class A
    if true
      b: 'b'
    else
      c: 'c'

  a = new A

  eq a.b, 'b'
  eq a.c, undefined


test "#2502: parenthesizing inner object values", ->

  class A
    category:  (type: 'string')
    sections:  (type: 'number', default: 0)

  eq (new A).category.type, 'string'

  eq (new A).sections.default, 0


test "conditional prototype property assignment", ->
  debug = false

  class Person
    if debug
      age: -> 10
    else
      age: -> 20

  eq (new Person).age(), 20


test "mild metaprogramming", ->

  class Base
    @attr: (name) ->
      @::[name] = (val) ->
        if arguments.length > 0
          @["_#{name}"] = val
        else
          @["_#{name}"]

  class Robot extends Base
    @attr 'power'
    @attr 'speed'

  robby = new Robot

  ok robby.power() is undefined

  robby.power 11
  robby.speed Infinity

  eq robby.power(), 11
  eq robby.speed(), Infinity


test "namespaced classes do not reserve their function name in outside scope", ->

  one = {}
  two = {}

  class one.Klass
    @label = "one"

  class two.Klass
    @label = "two"

  eq typeof Klass, 'undefined'
  eq one.Klass.label, 'one'
  eq two.Klass.label, 'two'


test "nested classes", ->

  class Outer
    constructor: ->
      @label = 'outer'

    class @Inner
      constructor: ->
        @label = 'inner'

  eq (new Outer).label, 'outer'
  eq (new Outer.Inner).label, 'inner'


test "variables in constructor bodies are correctly scoped", ->

  class A
    x = 1
    constructor: ->
      x = 10
      y = 20
    y = 2
    captured: ->
      {x, y}

  a = new A
  eq a.captured().x, 10
  eq a.captured().y, 2


test "Issue #924: Static methods in nested classes", ->

  class A
    @B: class
      @c = -> 5

  eq A.B.c(), 5


test "`class extends this`", ->

  class A
    func: -> 'A'

  B = null
  makeClass = ->
    B = class extends this
      func: -> super() + ' B'

  makeClass.call A

  eq (new B()).func(), 'A B'


test "ensure that constructors invoked with splats return a new object", ->

  args = [1, 2, 3]
  Type = (@args) ->
  type = new Type args

  ok type and type instanceof Type
  ok type.args and type.args instanceof Array
  ok v is args[i] for v, i in type.args

  Type1 = (@a, @b, @c) ->
  type1 = new Type1 args...

  ok type1 instanceof   Type1
  eq type1.constructor, Type1
  ok type1.a is args[0] and type1.b is args[1] and type1.c is args[2]

  # Ensure that constructors invoked with splats cache the function.
  called = 0
  get = -> if called++ then false else class Type
  new (get()) args...

test "`new` shouldn't add extra parens", ->

  ok new Date().constructor is Date


test "`new` works against bare function", ->

  eq Date, new ->
    Date


test "#1182: a subclass should be able to set its constructor to an external function", ->
  ctor = ->
    @val = 1
    return
  class A
  class B extends A
    constructor: ctor
  eq (new B).val, 1

test "#1182: external constructors continued", ->
  ctor = ->
  class A
  class B extends A
    method: ->
    constructor: ctor
  ok B::method

test "#1313: misplaced __extends", ->
  nonce = {}
  class A
  class B extends A
    prop: nonce
    constructor: -> super()
  eq nonce, B::prop

test "#1182: execution order needs to be considered as well", ->
  counter = 0
  makeFn = (n) -> eq n, ++counter; ->
  class B extends (makeFn 1)
    @B: makeFn 2
    constructor: makeFn 3

test "#1182: external constructors with bound functions", ->
  fn = ->
    {one: 1}
    this
  class B
  class A
    constructor: fn
    method: => this instanceof A
  ok (new A).method.call(new B)

test "#1372: bound class methods with reserved names", ->
  class C
    delete: =>
  ok C::delete

test "#1380: `super` with reserved names", ->
  class C
    do: -> super()
  ok C::do

  class B
    0: -> super()
  ok B::[0]

test "#1464: bound class methods should keep context", ->
  nonce  = {}
  nonce2 = {}
  class C
    constructor: (@id) ->
    @boundStaticColon: => new this(nonce)
    @boundStaticEqual= => new this(nonce2)
  eq nonce,  C.boundStaticColon().id
  eq nonce2, C.boundStaticEqual().id

test "#1009: classes with reserved words as determined names", -> (->
  eq 'function', typeof (class @for)
  ok not /\beval\b/.test (class @eval).toString()
  ok not /\barguments\b/.test (class @arguments).toString()
).call {}

test "#1482: classes can extend expressions", ->
  id = (x) -> x
  nonce = {}
  class A then nonce: nonce
  class B extends id A
  eq nonce, (new B).nonce

test "#1598: super works for static methods too", ->

  class Parent
    method: ->
      'NO'
    @method: ->
      'yes'

  class Child extends Parent
    @method: ->
      'pass? ' + super()

  eq Child.method(), 'pass? yes'

test "#1842: Regression with bound functions within bound class methods", ->

  class Store
    @bound: =>
      do =>
        eq this, Store

  Store.bound()

  # And a fancier case:

  class Store

    eq this, Store

    @bound: =>
      do =>
        eq this, Store

    @unbound: ->
      eq this, Store

    instance: =>
      ok this instanceof Store

  Store.bound()
  Store.unbound()
  (new Store).instance()

test "#1876: Class @A extends A", ->
  class A
  class @A extends A

  ok (new @A) instanceof A

test "#1813: Passing class definitions as expressions", ->
  ident = (x) -> x

  result = ident class A then x = 1

  eq result, A

  result = ident class B extends A
    x = 1

  eq result, B

test "#1966: external constructors should produce their return value", ->
  ctor = -> {}
  class A then constructor: ctor
  ok (new A) not instanceof A

test "#1980: regression with an inherited class with static function members", ->

  class A

  class B extends A
    @static: => 'value'

  eq B.static(), 'value'

test "#1534: class then 'use strict'", ->
  # [14.1 Directive Prologues and the Use Strict Directive](http://es5.github.com/#x14.1)
  nonce = {}
  error = 'do -> ok this'
  strictTest = "do ->'use strict';#{error}"
  return unless (try CoffeeScript.run strictTest, bare: yes catch e then nonce) is nonce

  throws -> CoffeeScript.run "class then 'use strict';#{error}", bare: yes
  doesNotThrow -> CoffeeScript.run "class then #{error}", bare: yes
  doesNotThrow -> CoffeeScript.run "class then #{error};'use strict'", bare: yes

  # comments are ignored in the Directive Prologue
  comments = ["""
  class
    ### comment ###
    'use strict'
    #{error}""",
  """
  class
    ### comment 1 ###
    ### comment 2 ###
    'use strict'
    #{error}""",
  """
  class
    ### comment 1 ###
    ### comment 2 ###
    'use strict'
    #{error}
    ### comment 3 ###"""
  ]
  throws (-> CoffeeScript.run comment, bare: yes) for comment in comments

  # [ES5 §14.1](http://es5.github.com/#x14.1) allows for other directives
  directives = ["""
  class
    'directive 1'
    'use strict'
    #{error}""",
  """
  class
    'use strict'
    'directive 2'
    #{error}""",
  """
  class
    ### comment 1 ###
    'directive 1'
    'use strict'
    #{error}""",
  """
  class
    ### comment 1 ###
    'directive 1'
    ### comment 2 ###
    'use strict'
    #{error}"""
  ]
  throws (-> CoffeeScript.run directive, bare: yes) for directive in directives

test "#2052: classes should work in strict mode", ->
  try
    do ->
      'use strict'
      class A
  catch e
    ok no

test "directives in class with extends ", ->
  strictTest = """
    class extends Object
      ### comment ###
      'use strict'
      do -> eq this, undefined
  """
  CoffeeScript.run strictTest, bare: yes

test "#2630: class bodies can't reference arguments", ->
  throws ->
    CoffeeScript.compile('class Test then arguments')

  # #4320: Don't be too eager when checking, though.
  class Test
    arguments: 5
  eq 5, Test::arguments

test "#2319: fn class n extends o.p [INDENT] x = 123", ->
  first = ->

  base = onebase: ->

  first class OneKeeper extends base.onebase
    one = 1
    one: -> one

  eq new OneKeeper().one(), 1


test "#2599: other typed constructors should be inherited", ->
  class Base
    constructor: -> return {}

  class Derived extends Base

  ok (new Derived) not instanceof Derived
  ok (new Derived) not instanceof Base
  ok (new Base) not instanceof Base

test "extending native objects works with and without defining a constructor", ->
  class MyArray extends Array
    method: -> 'yes!'

  myArray = new MyArray
  ok myArray instanceof MyArray
  ok 'yes!', myArray.method()

  class OverrideArray extends Array
    constructor: -> super()
    method: -> 'yes!'

  overrideArray = new OverrideArray
  ok overrideArray instanceof OverrideArray
  eq 'yes!', overrideArray.method()


test "#2782: non-alphanumeric-named bound functions", ->
  class A
    'b:c': =>
      'd'

  eq (new A)['b:c'](), 'd'


test "#2781: overriding bound functions", ->
  class A
    a: ->
        @b()
    b: =>
        1

  class B extends A
    b: =>
        2

  b = (new A).b
  eq b(), 1

  b = (new B).b
  eq b(), 2


test "#2791: bound function with destructured argument", ->
  class Foo
    method: ({a}) => 'Bar'

  eq (new Foo).method({a: 'Bar'}), 'Bar'


test "#2796: ditto, ditto, ditto", ->
  answer = null

  outsideMethod = (func) ->
    func.call message: 'wrong!'

  class Base
    constructor: ->
      @message = 'right!'
      outsideMethod @echo

    echo: =>
      answer = @message

  new Base
  eq answer, 'right!'

test "#3063: Class bodies cannot contain pure statements", ->
  throws -> CoffeeScript.compile """
    class extends S
      return if S.f
      @f: => this
  """

test "#2949: super in static method with reserved name", ->
  class Foo
    @static: -> 'baz'

  class Bar extends Foo
    @static: -> super()

  eq Bar.static(), 'baz'

test "#3232: super in static methods (not object-assigned)", ->
  class Foo
    @baz = -> true
    @qux = -> true

  class Bar extends Foo
    @baz = -> super()
    Bar.qux = -> super()

  ok Bar.baz()
  ok Bar.qux()

test "#1392 calling `super` in methods defined on namespaced classes", ->
  class Base
    m: -> 5
    n: -> 4
  namespace =
    A: ->
    B: ->
  class namespace.A extends Base
    m: -> super()

  eq 5, (new namespace.A).m()
  namespace.B::m = namespace.A::m
  namespace.A::m = null
  eq 5, (new namespace.B).m()

  class C
    @a: class extends Base
      m: -> super()
  eq 5, (new C.a).m()


test "#4436 immediately instantiated named class", ->
  ok new class Foo


test "dynamic method names", ->
  class A
    "#{name = 'm'}": -> 1
  eq 1, new A().m()

  class B extends A
    "#{name = 'm'}": -> super()
  eq 1, new B().m()

  getName = -> 'm'
  class C
    "#{name = getName()}": -> 1
  eq 1, new C().m()


test "dynamic method names and super", ->
  class Base
    @m: -> 6
    m: -> 5
    m2: -> 4.5
    n: -> 4

  name = -> count++; 'n'
  count = 0

  m = 'm'
  class A extends Base
    "#{m}": -> super()
    "#{name()}": -> super()

  m = 'n'
  eq 5, (new A).m()

  eq 4, (new A).n()
  eq 1, count

  m = 'm'
  m2 = 'm2'
  count = 0
  class B extends Base
    @[name()] = -> super()
    "#{m}": -> super()
    "#{m2}": -> super()
  b = new B
  m = m2 = 'n'
  eq 6, B.m()
  eq 5, b.m()
  eq 4.5, b.m2()
  eq 1, count

  class C extends B
    m: -> super()
  eq 5, (new C).m()

# ES2015+ class interoperability
# Based on https://github.com/balupton/es6-javascript-class-interop
# Helper functions to generate true ES classes to extend:
getBasicClass = ->
  ```
  class BasicClass {
    constructor (greeting) {
      this.greeting = greeting || 'hi'
    }
  }
  ```
  BasicClass

getExtendedClass = (BaseClass) ->
  ```
  class ExtendedClass extends BaseClass {
    constructor (greeting, name) {
      super(greeting || 'hello')
      this.name = name
    }
  }
  ```
  ExtendedClass

test "can instantiate a basic ES class", ->
  BasicClass = getBasicClass()
  i = new BasicClass 'howdy!'
  eq i.greeting, 'howdy!'

test "can instantiate an extended ES class", ->
  BasicClass = getBasicClass()
  ExtendedClass = getExtendedClass BasicClass
  i = new ExtendedClass 'yo', 'buddy'
  eq i.greeting, 'yo'
  eq i.name, 'buddy'

test "can extend a basic ES class", ->
  BasicClass = getBasicClass()
  class ExtendedClass extends BasicClass
    constructor: (@name) ->
      super()
  i = new ExtendedClass 'dude'
  eq i.name, 'dude'

test "can extend an extended ES class", ->
  BasicClass = getBasicClass()
  ExtendedClass = getExtendedClass BasicClass

  class ExtendedExtendedClass extends ExtendedClass
    constructor: (@value) ->
      super()
    getDoubledValue: ->
      @value * 2

  i = new ExtendedExtendedClass 7
  eq i.getDoubledValue(), 14

test "CoffeeScript class can be extended in ES", ->
  class CoffeeClass
    constructor: (@favoriteDrink = 'latte', @size = 'grande') ->
    getDrinkOrder: ->
      "#{@size} #{@favoriteDrink}"

  ```
  class ECMAScriptClass extends CoffeeClass {
    constructor (favoriteDrink) {
      super(favoriteDrink);
      this.favoriteDrink = this.favoriteDrink + ' with a dash of semicolons';
    }
  }
  ```

  e = new ECMAScriptClass 'coffee'
  eq e.getDrinkOrder(), 'grande coffee with a dash of semicolons'

test "extended CoffeeScript class can be extended in ES", ->
  class CoffeeClass
    constructor: (@favoriteDrink = 'latte') ->

  class CoffeeClassWithDrinkOrder extends CoffeeClass
    constructor: (@favoriteDrink, @size = 'grande') ->
      super()
    getDrinkOrder: ->
      "#{@size} #{@favoriteDrink}"

  ```
  class ECMAScriptClass extends CoffeeClassWithDrinkOrder {
    constructor (favoriteDrink) {
      super(favoriteDrink);
      this.favoriteDrink = this.favoriteDrink + ' with a dash of semicolons';
    }
  }
  ```

  e = new ECMAScriptClass 'coffee'
  eq e.getDrinkOrder(), 'grande coffee with a dash of semicolons'

test "`this` access after `super` in extended classes", ->
  class Base

  class Test extends Base
    constructor: (param, @param) ->
      eq param, nonce

      result = { super: super(), @param, @method }
      eq result.super, this
      eq result.param, @param
      eq result.method, @method
      ok result.method isnt Test::method

    method: =>

  nonce = {}
  new Test nonce, {}

test "`@`-params and bound methods with multiple `super` paths (blocks)", ->
  nonce = {}

  class Base
    constructor: (@name) ->

  class Test extends Base
    constructor: (param, @param) ->
      if param
        super 'param'
        eq @name, 'param'
      else
        super 'not param'
        eq @name, 'not param'
      eq @param, nonce
      ok @method isnt Test::method
    method: =>
  new Test true, nonce
  new Test false, nonce


test "`@`-params and bound methods with multiple `super` paths (expressions)", ->
  nonce = {}

  class Base
    constructor: (@name) ->

  class Test extends Base
    constructor: (param, @param) ->
      # Contrived example: force each path into an expression with inline assertions
      if param
        result = (
          eq (super 'param'), @;
          eq @name, 'param';
          eq @param, nonce;
          ok @method isnt Test::method
        )
      else
        result = (
          eq (super 'not param'), @;
          eq @name, 'not param';
          eq @param, nonce;
          ok @method isnt Test::method
        )
    method: =>
  new Test true, nonce
  new Test false, nonce

test "constructor super in arrow functions", ->
  class Test extends (class)
    constructor: (@param) ->
      do => super()
      eq @param, nonce

  new Test nonce = {}

# TODO Some of these tests use CoffeeScript.compile and CoffeeScript.run when they could use
# regular test mechanics.
# TODO Some of these tests might be better placed in `test/error_messages.coffee`.
# TODO Some of these tests are duplicates.

# Ensure that we always throw if we experience more than one super()
# call in a constructor.  This ends up being a runtime error.
# Should be caught at compile time.
test "multiple super calls", ->
  throwsA = """
  class A
    constructor: (@drink) ->
    make: -> "Making a #{@drink}"

  class MultiSuper extends A
    constructor: (drink) ->
      super(drink)
      super(drink)
      @newDrink = drink
  new MultiSuper('Late').make()
  """
  throws -> CoffeeScript.run throwsA, bare: yes

# Basic test to ensure we can pass @params in a constuctor and
# inheritance works correctly
test "@ params", ->
  class A
    constructor: (@drink, @shots, @flavor) ->
    make: -> "Making a #{@flavor} #{@drink} with #{@shots} shot(s)"

  a = new A('Machiato', 2, 'chocolate')
  eq a.make(),  "Making a chocolate Machiato with 2 shot(s)"

  class B extends A
  b = new B('Machiato', 2, 'chocolate')
  eq b.make(),  "Making a chocolate Machiato with 2 shot(s)"

# Ensure we can accept @params with default parameters in a constructor
test "@ params with defaults in a constructor", ->
  class A
    # Multiple @ params with defaults
    constructor: (@drink = 'Americano', @shots = '1', @flavor = 'caramel') ->
    make: -> "Making a #{@flavor} #{@drink} with #{@shots} shot(s)"

  a = new A()
  eq a.make(),  "Making a caramel Americano with 1 shot(s)"

# Ensure we can handle default constructors with class params
test "@ params with class params", ->
  class Beverage
    drink: 'Americano'
    shots: '1'
    flavor: 'caramel'

  class A
    # Class creation as a default param with `this`
    constructor: (@drink = new Beverage()) ->
  a = new A()
  eq a.drink.drink, 'Americano'

  beverage = new Beverage
  class B
    # class costruction with a default external param
    constructor: (@drink = beverage) ->

  b = new B()
  eq b.drink.drink, 'Americano'

  class C
    # Default constructor with anonymous empty class
    constructor: (@meta = class) ->
  c = new C()
  ok c.meta instanceof Function

test "@ params without super, including errors", ->
  classA = """
  class A
    constructor: (@drink) ->
    make: -> "Making a #{@drink}"
  a = new A('Machiato')
  """

  throwsB = """
  class B extends A
    #implied super
    constructor: (@drink) ->
  b = new B('Machiato')
  """
  throws -> CoffeeScript.compile classA + throwsB, bare: yes

test "@ params super race condition", ->
  classA = """
  class A
    constructor: (@drink) ->
    make: -> "Making a #{@drink}"
  """

  throwsB = """
  class B extends A
    constructor: (@params) ->

  b = new B('Machiato')
  """
  throws -> CoffeeScript.compile classA + throwsB, bare: yes

  # Race condition with @ and super
  throwsC = """
  class C extends A
    constructor: (@params) ->
      super(@params)

  c = new C('Machiato')
  """
  throws -> CoffeeScript.compile classA + throwsC, bare: yes


test "@ with super call", ->
  class D
    make: -> "Making a #{@drink}"

  class E extends D
    constructor: (@drink) ->
      super()

  e = new E('Machiato')
  eq e.make(),  "Making a Machiato"

test "@ with splats and super call", ->
  class A
    make: -> "Making a #{@drink}"

  class B extends A
    constructor: (@drink...) ->
      super()

  B = new B('Machiato')
  eq B.make(),  "Making a Machiato"


test "super and external constructors", ->
  # external constructor with @ param is allowed
  ctorA = (@drink) ->
  class A
    constructor: ctorA
    make: -> "Making a #{@drink}"
  a = new A('Machiato')
  eq a.make(),  "Making a Machiato"

  # External constructor with super
  throwsC = """
  class B
    constructor: (@drink) ->
    make: -> "Making a #{@drink}"

  ctorC = (drink) ->
    super(drink)

  class C extends B
    constructor: ctorC
  c = new C('Machiato')
  """
  throws -> CoffeeScript.compile throwsC, bare: yes


test "bound functions without super", ->
  # Bound function with @
  # Throw on compile, since bound
  # constructors are illegal
  throwsA = """
  class A
    constructor: (drink) =>
      @drink = drink

  """
  throws -> CoffeeScript.compile throwsA, bare: yes

test "super in a bound function in a constructor", ->
  throwsB = """
  class A
  class B extends A
    constructor: do => super
  """
  throws -> CoffeeScript.compile throwsB, bare: yes

test "super in a bound function", ->
  class A
    constructor: (@drink) ->
    make: -> "Making a #{@drink}"

  class B extends A
    make: (@flavor) =>
      super() + " with #{@flavor}"

  b = new B('Machiato')
  eq b.make('vanilla'),  "Making a Machiato with vanilla"

  # super in a bound function in a bound function
  class C extends A
    make: (@flavor) =>
      func = () =>
        super() + " with #{@flavor}"
      func()

  c = new C('Machiato')
  eq c.make('vanilla'), "Making a Machiato with vanilla"

  # bound function in a constructor
  class D extends A
    constructor: (drink) ->
      super(drink)
      x = =>
        eq @drink,  "Machiato"
      x()
  d = new D('Machiato')
  eq d.make(),  "Making a Machiato"

# duplicate
test "super in a try/catch", ->
  classA = """
  class A
    constructor: (param) ->
      throw "" unless param
  """

  throwsB = """
  class B extends A
      constructor: ->
        try
          super()
  """

  throwsC = """
  ctor = ->
    try
      super()

  class C extends A
      constructor: ctor
  """
  throws -> CoffeeScript.run classA + throwsB, bare: yes
  throws -> CoffeeScript.run classA + throwsC, bare: yes

test "mixed ES6 and CS6 classes with a four-level inheritance chain", ->
  # Extended test
  # ES2015+ class interoperability

  ```
  class Base {
    constructor (greeting) {
      this.greeting = greeting || 'hi';
    }
    func (string) {
      return 'zero/' + string;
    }
    static  staticFunc (string) {
      return 'static/' + string;
    }
  }
  ```

  class FirstChild extends Base
    func: (string) ->
      super('one/') + string


  ```
  class SecondChild extends FirstChild {
    func (string) {
      return super.func('two/' + string);
    }
  }
  ```

  thirdCtor = ->
    @array = [1, 2, 3]

  class ThirdChild extends SecondChild
    constructor: ->
      super()
      thirdCtor.call this
    func: (string) ->
      super('three/') + string

  result = (new ThirdChild).func 'four'
  ok result is 'zero/one/two/three/four'
  ok Base.staticFunc('word') is 'static/word'

# exercise extends in a nested class
test "nested classes with super", ->
  class Outer
    constructor: ->
      @label = 'outer'

    class @Inner
      constructor: ->
        @label = 'inner'

    class @ExtendedInner extends @Inner
      constructor: ->
        tmp = super()
        @label = tmp.label + ' extended'

    @extender: () =>
      class ExtendedSelf extends @
        constructor: ->
          tmp = super()
          @label = tmp.label + ' from this'
      new ExtendedSelf

  eq (new Outer).label, 'outer'
  eq (new Outer.Inner).label, 'inner'
  eq (new Outer.ExtendedInner).label, 'inner extended'
  eq (Outer.extender()).label, 'outer from this'

test "Static methods generate 'static' keywords", ->
  compile = """
  class CheckStatic
    constructor: (@drink) ->
    @className: -> 'CheckStatic'

  c = new CheckStatic('Machiato')
  """
  result = CoffeeScript.compile compile, bare: yes
  ok result.match(' static ')

test "Static methods in nested classes", ->
  class Outer
    @name: -> 'Outer'

    class @Inner
      @name: -> 'Inner'

  eq Outer.name(), 'Outer'
  eq Outer.Inner.name(), 'Inner'


test "mixed constructors with inheritance and ES6 super", ->
  identity = (f) -> f

  class TopClass
    constructor: (arg) ->
      @prop = 'top-' + arg

  ```
  class SuperClass extends TopClass {
    constructor (arg) {
      identity(super('super-' + arg));
    }
  }
  ```
  class SubClass extends SuperClass
    constructor: ->
      identity super 'sub'

  ok (new SubClass).prop is 'top-super-sub'

test "ES6 static class methods can be overriden", ->
  class A
    @name: -> 'A'

  class B extends A
    @name: -> 'B'

  eq A.name(), 'A'
  eq B.name(), 'B'

# If creating static by direct assignment rather than ES6 static keyword
test "ES6 Static methods should set `this` to undefined // ES6 ", ->
  class A
    @test: ->
      eq this, undefined

# Ensure that our object prototypes work with ES6
test "ES6 prototypes can be overriden", ->
  class A
    className: 'classA'

  ```
  class B {
    test () {return "B";};
  }
  ```
  b = new B
  a = new A
  eq a.className, 'classA'
  eq b.test(), 'B'
  Object.setPrototypeOf(b, a)
  eq b.className, 'classA'
  # This shouldn't throw,
  # as we only change inheritance not object construction
  # This may be an issue with ES, rather than CS construction?
  #eq b.test(), 'B'

  class D extends B
  B::test = () -> 'D'
  eq (new D).test(), 'D'

# TODO: implement this error check
# test "ES6 conformance to extending non-classes", ->
#   A = (@title) ->
#     'Title: ' + @

#   class B extends A
#   b = new B('caffeinated')
#   eq b.title, 'caffeinated'

#   # Check inheritance chain
#   A::getTitle = () -> @title
#   eq b.getTitle(), 'caffeinated'

#   throwsC = """
#   C = {title: 'invalid'}
#   class D extends {}
#   """
#   # This should catch on compile and message should be "class can only extend classes and functions."
#   throws -> CoffeeScript.run throwsC, bare: yes

# TODO: Evaluate future compliance with "strict mode";
# test "Class function environment should be in `strict mode`, ie as if 'use strict' was in use", ->
#   class A
#     # this might be a meaningless test, since these are likely to be runtime errors and different
#     # for every browser.  Thoughts?
#     constructor: () ->
#       # Ivalid: prop reassignment
#       @state = {prop: [1], prop: {a: 'a'}}
#       # eval reassignment
#       @badEval = eval;

#   # Should throw, but doesn't
#   a = new A

# TODO: new.target needs support  Separate issue
# test "ES6 support for new.target (functions and constructors)", ->
#   throwsA = """
#   class A
#     constructor: () ->
#       a = new.target.name
#   """
#   throws -> CoffeeScript.compile throwsA, bare: yes

test "only one method named constructor allowed", ->
  throwsA = """
  class A
    constructor: (@first) ->
    constructor: (@last) ->
  """
  throws -> CoffeeScript.compile throwsA, bare: yes

test "If the constructor of a child class does not call super,it should return an object.", ->
  nonce = {}

  class A
  class B extends A
    constructor: ->
      return nonce

  eq nonce, new B


test "super can only exist in extended classes", ->
  throwsA = """
  class A
    constructor: (@name) ->
      super()
  """
  throws -> CoffeeScript.compile throwsA, bare: yes

# --- CS1 classes compatability breaks ---
test "CS6 Class extends a CS1 compiled class", ->
  ```
  // Generated by CoffeeScript 1.11.1
  var BaseCS1, ExtendedCS1,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  BaseCS1 = (function() {
    function BaseCS1(drink) {
      this.drink = drink;
    }

    BaseCS1.prototype.make = function() {
      return "making a " + this.drink;
    };

    BaseCS1.className = function() {
      return 'BaseCS1';
    };

    return BaseCS1;

  })();

  ExtendedCS1 = (function(superClass) {
    extend(ExtendedCS1, superClass);

    function ExtendedCS1(flavor) {
      this.flavor = flavor;
      ExtendedCS1.__super__.constructor.call(this, 'cafe ole');
    }

    ExtendedCS1.prototype.make = function() {
      return "making a " + this.drink + " with " + this.flavor;
    };

    ExtendedCS1.className = function() {
      return 'ExtendedCS1';
    };

    return ExtendedCS1;

  })(BaseCS1);

  ```
  class B extends BaseCS1
  eq B.className(), 'BaseCS1'
  b = new B('machiato')
  eq b.make(), "making a machiato"


test "CS6 Class extends an extended CS1 compiled class", ->
  ```
  // Generated by CoffeeScript 1.11.1
  var BaseCS1, ExtendedCS1,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  BaseCS1 = (function() {
    function BaseCS1(drink) {
      this.drink = drink;
    }

    BaseCS1.prototype.make = function() {
      return "making a " + this.drink;
    };

    BaseCS1.className = function() {
      return 'BaseCS1';
    };

    return BaseCS1;

  })();

  ExtendedCS1 = (function(superClass) {
    extend(ExtendedCS1, superClass);

    function ExtendedCS1(flavor) {
      this.flavor = flavor;
      ExtendedCS1.__super__.constructor.call(this, 'cafe ole');
    }

    ExtendedCS1.prototype.make = function() {
      return "making a " + this.drink + " with " + this.flavor;
    };

    ExtendedCS1.className = function() {
      return 'ExtendedCS1';
    };

    return ExtendedCS1;

  })(BaseCS1);

  ```
  class B extends ExtendedCS1
  eq B.className(), 'ExtendedCS1'
  b = new B('vanilla')
  eq b.make(), "making a cafe ole with vanilla"

test "CS6 Class extends a CS1 compiled class with super()", ->
  ```
  // Generated by CoffeeScript 1.11.1
  var BaseCS1, ExtendedCS1,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  BaseCS1 = (function() {
    function BaseCS1(drink) {
      this.drink = drink;
    }

    BaseCS1.prototype.make = function() {
      return "making a " + this.drink;
    };

    BaseCS1.className = function() {
      return 'BaseCS1';
    };

    return BaseCS1;

  })();

  ExtendedCS1 = (function(superClass) {
    extend(ExtendedCS1, superClass);

    function ExtendedCS1(flavor) {
      this.flavor = flavor;
      ExtendedCS1.__super__.constructor.call(this, 'cafe ole');
    }

    ExtendedCS1.prototype.make = function() {
      return "making a " + this.drink + " with " + this.flavor;
    };

    ExtendedCS1.className = function() {
      return 'ExtendedCS1';
    };

    return ExtendedCS1;

  })(BaseCS1);

  ```
  class B extends ExtendedCS1
    constructor: (@shots) ->
      super('caramel')
    make: () ->
      super() + " and #{@shots} shots of espresso"

  eq B.className(), 'ExtendedCS1'
  b = new B('three')
  eq b.make(), "making a cafe ole with caramel and three shots of espresso"

test 'Bound method called normally before binding is ok', ->
  class Base
    constructor: ->
      @setProp()
      eq @derivedBound(), 3

  class Derived extends Base
    setProp: ->
      @prop = 3

    derivedBound: =>
      @prop

  d = new Derived

test 'Bound method called as callback after super() is ok', ->
  class Base

  class Derived extends Base
    constructor: (@prop = 3) ->
      super()
      f = @derivedBound
      eq f(), 3

    derivedBound: =>
      @prop

  d = new Derived
  {derivedBound} = d
  eq derivedBound(), 3

test 'Bound method of base class called as callback is ok', ->
  class Base
    constructor: (@prop = 3) ->
      f = @baseBound
      eq f(), 3

    baseBound: =>
      @prop

  b = new Base
  {baseBound} = b
  eq baseBound(), 3

test 'Bound method of prop-named class called as callback is ok', ->
  Hive = {}
  class Hive.Bee
    constructor: (@prop = 3) ->
      f = @baseBound
      eq f(), 3

    baseBound: =>
      @prop

  b = new Hive.Bee
  {baseBound} = b
  eq baseBound(), 3

test 'Bound method of class with expression base class called as callback is ok', ->
  calledB = no
  B = ->
    throw new Error if calledB
    calledB = yes
    class
  class A extends B()
    constructor: (@prop = 3) ->
      super()
      f = @derivedBound
      eq f(), 3

    derivedBound: =>
      @prop

  b = new A
  {derivedBound} = b
  eq derivedBound(), 3

test 'Bound method of class with expression class name called as callback is ok', ->
  calledF = no
  obj = {}
  B = class
  f = ->
    throw new Error if calledF
    calledF = yes
    obj
  class f().A extends B
    constructor: (@prop = 3) ->
      super()
      g = @derivedBound
      eq g(), 3

    derivedBound: =>
      @prop

  a = new obj.A
  {derivedBound} = a
  eq derivedBound(), 3

test 'Bound method of anonymous child class called as callback is ok', ->
  f = ->
    B = class
    class extends B
      constructor: (@prop = 3) ->
        super()
        g = @derivedBound
        eq g(), 3

      derivedBound: =>
        @prop

  a = new (f())
  {derivedBound} = a
  eq derivedBound(), 3

test 'Bound method of immediately instantiated class with expression base class called as callback is ok', ->
  calledF = no
  obj = {}
  B = class
  f = ->
    throw new Error if calledF
    calledF = yes
    obj
  a = new class f().A extends B
    constructor: (@prop = 3) ->
      super()
      g = @derivedBound
      eq g(), 3

    derivedBound: =>
      @prop

  {derivedBound} = a
  eq derivedBound(), 3

test "#4591: super.x.y, super['x'].y", ->
  class A
    x:
      y: 1
      z: -> 2

  class B extends A
    constructor: ->
      super()

      @w = super.x.y
      @v = super['x'].y
      @u = super.x['y']
      @t = super.x.z()
      @s = super['x'].z()
      @r = super.x['z']()

  b = new B
  eq 1, b.w
  eq 1, b.v
  eq 1, b.u
  eq 2, b.t
  eq 2, b.s
  eq 2, b.r

test "#4464: backticked expressions in class body", ->
  class A
    `get x() { return 42; }`

  class B
    `get x() { return 42; }`
    constructor: ->
      @y = 84

  a = new A
  eq 42, a.x
  b = new B
  eq 42, b.x
  eq 84, b.y

test "#4724: backticked expression in a class body with hoisted member", ->
  class A
    `get x() { return 42; }`
    hoisted: 84

  a = new A
  eq 42, a.x
  eq 84, a.hoisted

test "#4822: nested anonymous classes use non-conflicting variable names", ->
  Class = class
    @a: class
      @b: 1

  eq Class.a.b, 1

test "#4827: executable class body wrappers have correct context", ->
  test = ->
    class @A
    class @B extends @A
      @property = 1

  o = {}
  test.call o
  ok typeof o.A is typeof o.B is 'function'

test "#4868: Incorrect ‘Can’t call super with @params’ error", ->
  class A
    constructor: (@func = ->) ->
      @x = 1
      @func()

  class B extends A
    constructor: ->
      super -> @x = 2

  a = new A
  b = new B
  eq 1, a.x
  eq 2, b.x

  class C
    constructor: (@c = class) -> @c

  class D extends C
    constructor: ->
      super class then constructor: (@a) -> @a = 3

  d = new (new D).c
  eq 3, d.a