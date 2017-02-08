## Breaking Changes

CoffeeScript 2 aims to output as much idiomatic ES2015+ syntax as possible with as few breaking changes from CoffeeScript 1.x as possible. Some breaking changes, unfortunately, were unavoidable.

### Function parameter default values

Per the [ES2015 spec regarding default parameters](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions/Default_parameters), default values are only applied when a parameter value is missing or `undefined`. In CoffeeScript 1.x, the default value would be applied in those cases but also if the parameter value was `null`.

> ```coffee
f = (a = 1) -> a
f(null)  # Returns 1 in CoffeeScript 1.x, null in CoffeeScript 2
```

### Bound generator functions

Bound generator functions, a.k.a. generator arrow functions, [aren’t allowed in ECMAScript](http://stackoverflow.com/questions/27661306/can-i-use-es6s-arrow-function-syntax-with-generators-arrow-notation). You can write `function*` or `=>`, but not both. Therefore, CoffeeScript code like this:

> ```coffee
f = => yield this
```

Needs to be rewritten the old-fashioned way:

> ```coffee
self = this
f = -> yield self
```

### Classes are compiled to ES2015 classes

ES2015 classes and their methods have some restrictions beyond those on regular functions.

Class constructors can’t be invoked without `new`:

> ```coffee
(class)()  # throws a TypeError at runtime
```

Derived (extended) class `constructor`s cannot use `this` before calling `super`:

> ```coffee
class B extends A
  constructor: -> this  # throws a compiler error
```

Class methods can’t be used with `new` (uncommon):

> ```coffee
class Namespace
  Klass: ->
new Namespace::Klass  # throws a TypeError at runtime
```

### Bare `super`

Due to a syntax clash with `super` with accessors, bare `super` no longer compiles to a super call forwarding all arguments.

> ```coffee
class B extends A
  foo: -> super
```

Arguments can be forwarded explicitly using splats:

> ```coffee
class B extends A
  foo: -> super arguments...
```

### `super` in non-class methods

In CoffeeScript 1.x it is possible to use `super` in more than just class methods, such as in manually prototype-assigned functions:

> ```coffee
A = ->
B = ->
B extends A
B.prototype.foo = -> super arguments...
```

Due to the switch to ES2015 `super`, this is no longer supported. The above case could be refactored for 2.x to:

> ```coffee
A = ->
B = ->
B extends A
B.prototype.foo = -> A::foo.apply this, arguments
>  
> # OR
>
class A
class B extends A
  foo: -> super arguments...
```

### Dynamic class keys exclude executable class scope

Due to the hoisting required to compile to ES2015 classes, dynamic keys in class methods can’t use values from the executable class body unless the methods are assigned in prototype style.

> ```coffee
class A
  name = 'method'
  "#{name}": ->   # This method will be named 'undefined'
  @::[name] = ->  # This will work; assigns to `A.prototype.method`
```