# Property Overloads
#
# Allows developers to define getter/setter methods on
# classes.
test "creating property getter on class", ->
  greeting = "hello"
  planets = ["earth", "mars"]
  index = 0

  class Overloaded

    shorthand: ~> "#{greeting} #{planets[index]}"

  instance = new Overloaded()
  ok instance.shorthand is "hello earth"
  index++
  ok instance.shorthand is "hello mars"

test "creating property setter on class", ->
  current_val = null
  times_called = 0

  class Overloaded

    shorthand: (new_val) ~>
      times_called++
      current_val = new_val

  instance = new Overloaded()
  instance.shorthand = "hello world"
  ok times_called is 1
  instance.shorthand = "hello mars"
  ok times_called is 2
