### Classes are compiled to ES2015 classes

ES2015 classes and their methods have some restrictions beyond those on regular functions.

Class constructors can’t be invoked without `new`:

```coffee
(class)()
# Throws a TypeError at runtime
```

Derived (extended) class `constructor`s cannot use `this` before calling `super`:

```coffee
class B extends A
  constructor: -> this  # Throws a compiler error
```

Class methods can’t be bound (i.e. you can’t define a class method using a fat arrow) though you can define such methods in the constructor instead:

```coffee
class B extends A
  method: =>  # Throws a compiler error
  
  constructor: ->
    super()
    @method = =>  # This works
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
