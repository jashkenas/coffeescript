### `super` and `extends`

Due to a syntax clash with `super` with accessors, “bare” `super` (the keyword `super` without parentheses) no longer compiles to a super call forwarding all arguments.

```coffee
class B extends A
  foo: -> super
  # Throws a compiler error
```

Arguments can be forwarded explicitly using splats:

```
codeFor('breaking_change_super_with_arguments')
```

Or if you know that the parent function doesn’t require arguments, just call `super()`:

```
codeFor('breaking_change_super_without_arguments')
```

CoffeeScript 1.x allowed the `extends` keyword to set up prototypal inheritance between functions, and `super` could be used manually prototype-assigned functions:

```coffee
A = ->
B = ->
B extends A
B.prototype.foo = -> super arguments...
# Last two lines each throw compiler errors in CoffeeScript 2
```

Due to the switch to ES2015 `extends` and `super`, using these keywords for prototypal functions are no longer supported. The above case could be refactored to:

```
codeFor('breaking_change_super_in_non-class_methods_refactor_with_apply')
```

or

```
codeFor('breaking_change_super_in_non-class_methods_refactor_with_class')
```
