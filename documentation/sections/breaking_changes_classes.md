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
  constructor: -> this
  # Throws a compiler error
```

Class methods can’t be used with `new` (uncommon):

```coffee
class Namespace
  @Klass = ->
new Namespace.Klass
# Throws a TypeError at runtime
```
