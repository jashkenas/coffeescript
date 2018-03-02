### Classes are compiled to ES2015 classes

ES2015 classes and their methods have some restrictions beyond those on regular functions.

Class constructors can’t be invoked without `new`:

```coffee
(class)()
# Throws a TypeError at runtime
```

ES2015 classes don’t allow bound (fat arrow) methods. The CoffeeScript compiler goes through some contortions to preserve support for them, but one thing that can’t be accommodated is calling a bound method before it is bound:

```coffee
class Base
  constructor: ->
    @onClick()      # This works
    clickHandler = @onClick
    clickHandler()  # This throws a runtime error

class Component extends Base
  onClick: =>
    console.log 'Clicked!', @
```

Class methods can’t be used with `new` (uncommon):

```coffee
class Namespace
  @Klass = ->
new Namespace.Klass  # Throws a TypeError at runtime
```

Due to the hoisting required to compile to ES2015 classes, dynamic keys in class methods can’t use values from the executable class body unless the methods are assigned in prototype style.

```coffee
class A
  name = 'method'
  "#{name}": ->   # This method will be named 'undefined'
  @::[name] = ->  # This will work; assigns to `A.prototype.method`
```
