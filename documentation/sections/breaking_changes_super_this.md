### `super` and `this`

In the constructor of a derived class (a class that `extends` another class), `this` cannot be used before calling `super`:

```coffee
class B extends A
  constructor: -> this  # Throws a compiler error
```
This also means you cannot pass a reference to `this` as an argument to `super` in the constructor of a derived class:

```coffee
class B extends A
  constructor: (@arg) ->
    super @arg  # Throws a compiler error
```
This is a limitation of ES2015 classes. As a workaround, assign to `this` after the `super` call:

```
codeFor('breaking_change_super_this')
```
