### `extends` for function prototypes, and `super` in non-class methods

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
