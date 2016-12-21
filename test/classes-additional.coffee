# Classes
# -------

# * Class Instantiation
# * Inheritance and Super
# * Default parameters
# * Version Compatability
test "multiple super calls", ->
  # class A 
  #   constructor: (@drink) ->
  #   make: -> "Making a #{@drink}"

  # class MultiSuper extends A
  #   constructor: (drink) ->
  #     super(drink)
  #     super(drink)
  #     @newDrink = drink
  # eq (new MultiSuper('Late')).make(), 'Making a Late'

test "@ params", ->
  class A 
    constructor: (@drink, @shots, @flavor) ->
    make: -> "Making a #{@flavor} #{@drink} with #{@shots} shot(s)"

  a = new A('Machiato', 2, 'chocolate')
  eq a.make(),  "Making a chocolate Machiato with 2 shot(s)"

  class B extends A
  b = new B('Machiato', 2, 'chocolate')
  eq b.make(),  "Making a chocolate Machiato with 2 shot(s)"

test "@ params with defaults", ->
  class A 
    # Multiple @ params with defaults
    constructor: (@drink = 'Americano', @shots = '1', @flavor = 'caramel') ->
    make: -> "Making a #{@flavor} #{@drink} with #{@shots} shot(s)"

  a = new A()
  eq a.make(),  "Making a caramel Americano with 1 shot(s)"

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
  class A 
    constructor: (@drink) ->
    make: -> "Making a #{@drink}"
  a = new A('Machiato')
  eq a.make(),  "Making a Machiato"

  throwsB = """
  class B extends A
    #implied super
    constructor: (@drink) ->
      if @drink is 'Machiato'
        @cost = 'expensive'
    make: -> "Making an #{@cost} #{@drink}"
  b = new B('Machiato', 'Cafe Ole', 'Americano')
  eq b.make(),  "Making an expensive Machiato" 
  """
  throws -> CoffeeScript.run classA + throwsB, bare: yes

  throwsC = """
  class C extends A
    # super with splats
    constructor: (@params...) ->
      super(@params[0])
      console.log @params

  c = new C('Machiato', 'Cafe Ole', 'Americano')
  # eq c.make(),  "Making a Machiato" 
  """
  throws -> CoffeeScript.run classA + throwsC, bare: yes


test "super and external constructors", ->
  ctorA = (@drink) ->
  class A 
    constructor: ctorA
    make: -> "Making a #{@drink}"

  # # External constructor with super
  # ctorB = (drink, flavor) ->
  #   super(drink)
  #   @flavor = flavor

  # class B extends A
  #   constructor: ctorB
  # b = new B('Machiato')
  # eq b.make(),  "Making a Machiato"

test "super and external overrides", ->
  # class A 
  #   constructor: (@drink) ->
  #   make: -> "Making a #{@drink}"

  # # External method and super
  # makeB = (@flavor) -> super.make() + " with #{@flavor}"

  # class B extends A 
  #   make: makeB
  # b = new B('Machiato')
  # eq b.make('caramel'),  "Making a Machiato with caramel"

  # # External bound method and super
  # makeC = (@flavor) => super.make() + " with #{@flavor}"

  # class C extends A 
  #   make: makeC
  # e = new C('Machiato')
  # eq e.make('caramel'),  "Making a Machiato with caramel"

  # class D extends A 
  # d = new D('Machiato')
  # d.make = (@flavor) -> super.make() + " with #{@flavor}"
  # eq d.make('caramel'),  "Making a Machiato with caramel"

  # # class G extends A 
  # # g = new G('Machiato')
  # # g.make = (@flavor) => super.make() + " with #{@flavor}"
  # # eq g.make('caramel'),  "Making a Machiato with caramel"
  # # Bound function with @

test "super in external prototype", ->
  ctorA = (drink) ->
    @drink = drink

  class A 
    constructor: (drink) ->
    make: -> "Making a #{@drink}"

  # Fails
  class B extends A 
  B::make = (@flavor) -> super.make() + " with #{@flavor}"
  b = new B('Machiato')
  eq b.make('caramel'),  "Making a Machiato with caramel"


test "bound functions without super", ->
  # Bound function with @
  # This should throw on compile, since bound 
  # constructors are illegal
  ctorA = (@drink) =>
    
  class A 
    constructor: ctorA
    make: => 
      "Making a #{@drink}"
  ok (new A('Machiato')).make() isnt  "Making a Machiato" 


  # extended bound function, extending fails too.
  class B extends A
  b = new B('Machiato')
  ok (new B('Machiato')).make() isnt  "Making a Machiato" 

test "super in a bound function", ->
  class A 
    constructor: (@drink) ->
    make: -> "Making a #{@drink}"
  
  class B extends A
    make: (@flavor) =>
      super + " with #{@flavor}"

  b = new B('Machiato')
  eq b.make('vanilla'),  "Making a Machiato with vanilla" 

  # super in a bound function in a bound function
  class C extends A
    make: (@flavor) =>
      func = () =>
        super + " with #{@flavor}"
      func()

  c = new C('Machiato')
  eq c.make('vanilla'),  "Making a Machiato with vanilla" 

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
          super
  """

  throwsC = """
  ctor = ->
    try
      super
  
  class C extends A
      constructor: ctor
  """
  throws -> CoffeeScript.run classA + throwsB, bare: yes
  throws -> CoffeeScript.run classA + throwsC, bare: yes
     
