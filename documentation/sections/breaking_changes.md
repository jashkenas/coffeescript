## Breaking Changes From CoffeeScript 1.x to 2

CoffeeScript 2 aims to output as much idiomatic ES2015+ syntax as possible with as few breaking changes from CoffeeScript 1.x as possible. Some breaking changes, unfortunately, were unavoidable.

### Function parameter default values

Per the [ES2015 spec regarding default parameters](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions/Default_parameters), default values are only applied when a parameter value is missing or `undefined`. In CoffeeScript 1.x, the default value would be applied in those cases but also if the parameter value was `null`.

```
codeFor('breaking_change_function_parameter_default_values', 'f(null)')
```

### Bound generator functions

Bound generator functions, a.k.a. generator arrow functions, [aren’t allowed in ECMAScript](http://stackoverflow.com/questions/27661306/can-i-use-es6s-arrow-function-syntax-with-generators-arrow-notation). You can write `function*` or `=>`, but not both. Therefore, CoffeeScript code like this:

> ```coffee
f = => yield this  # Throws a compiler error
```

Needs to be rewritten the old-fashioned way:

```
codeFor('breaking_change_bound_generator_function')
```

### Classes are compiled to ES2015 classes

ES2015 classes and their methods have some restrictions beyond those on regular functions.

Class constructors can’t be invoked without `new`:

> ```coffee
(class)()  # Throws a TypeError at runtime
```

Derived (extended) class `constructor`s cannot use `this` before calling `super`:

> ```coffee
class B extends A
  constructor: -> this  # Throws a compiler error
```

Class methods can’t be used with `new` (uncommon):

> ```coffee
class Namespace
  @Klass = ->
new Namespace.Klass  # Throws a TypeError at runtime
```

### Bare `super`

Due to a syntax clash with `super` with accessors, bare `super` no longer compiles to a super call forwarding all arguments.

> ```coffee
class B extends A
  foo: -> super    # Throws a compiler error
```

Arguments can be forwarded explicitly using splats:

```
codeFor('breaking_change_super_with_arguments')
```

Or if you know that the parent function doesn’t require arguments, just call `super()`:

```
codeFor('breaking_change_super_without_arguments')
```

### `super` in non-class methods

In CoffeeScript 1.x it is possible to use `super` in more than just class methods, such as in manually prototype-assigned functions:

> ```coffee
A = ->
B = ->
B extends A
B.prototype.foo = -> super arguments...  # Throws a compiler error
```

Due to the switch to ES2015 `super`, this is no longer supported. The above case could be refactored to:

```
codeFor('breaking_change_super_in_non-class_methods_refactor_with_apply')
```

or

```
codeFor('breaking_change_super_in_non-class_methods_refactor_with_class')
```

### Dynamic class keys exclude executable class scope

Due to the hoisting required to compile to ES2015 classes, dynamic keys in class methods can’t use values from the executable class body unless the methods are assigned in prototype style.

> ```coffee
class A
  name = 'method'
  "#{name}": ->   # This method will be named 'undefined'
  @::[name] = ->  # This will work; assigns to `A.prototype.method`
```
