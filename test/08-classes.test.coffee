# Test class operations

test "basic class", ->
  class Animal
    constructor: (@name) ->

    speak: -> "#{@name} makes a sound"

  dog = new Animal("Rex")
  eq dog.name, "Rex"
  eq dog.speak(), "Rex makes a sound"

test "class inheritance", ->
  class Vehicle
    constructor: (@wheels) ->

    describe: -> "Has #{@wheels} wheels"

  class Car extends Vehicle
    constructor: ->
      super(4)

    type: -> "Car"

  car = new Car()
  eq car.wheels, 4
  eq car.describe(), "Has 4 wheels"
  eq car.type(), "Car"

test "class with static methods", ->
  class MathUtils
    @square: (x) -> x * x
    @cube: (x) -> x * x * x

  eq MathUtils.square(3), 9
  eq MathUtils.cube(2), 8

test "class with getters and setters", ->
  class Person
    constructor: (@firstName, @lastName) ->

    fullName: -> "#{@firstName} #{@lastName}"

  person = new Person("John", "Doe")
  eq person.fullName(), "John Doe"

test "class with private fields", ->
  class Counter
    count = 0

    increment: -> count++

    getValue: -> count

  counter = new Counter()
  counter.increment()
  counter.increment()
  eq counter.getValue(), 2

test "class with bound methods", ->
  class Button
    constructor: (@label) ->

    click: => @label

  button = new Button("Submit")
  clickHandler = button.click
  eq clickHandler(), "Submit"

test "instanceof with classes", ->
  class Shape
  class Circle extends Shape

  circle = new Circle()
  ok circle instanceof Circle
  ok circle instanceof Shape

test "super in methods", ->
  class Base
    greet: (name) -> "Hello, #{name}"

  class Derived extends Base
    greet: (name) -> super(name) + "!"

  obj = new Derived()
  eq obj.greet("World"), "Hello, World!"

test "class with constructor parameters", ->
  class Point
    constructor: (@x = 0, @y = 0) ->

  p1 = new Point()
  eq p1.x, 0
  eq p1.y, 0

  p2 = new Point(3, 4)
  eq p2.x, 3
  eq p2.y, 4
