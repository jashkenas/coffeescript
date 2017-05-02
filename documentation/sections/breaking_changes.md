## Breaking Changes From CoffeeScript 1.x to 2

CoffeeScript 2 aims to output as much idiomatic ES2015+ syntax as possible with as few breaking changes from CoffeeScript 1.x as possible. Some breaking changes, unfortunately, were unavoidable.

<section id="breaking-changes-default-values">

### Default values for function parameters and destructured elements

Per the [ES2015 spec regarding function default parameters](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions/Default_parameters) and [destructuring default values](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Destructuring_assignment#Default_values), default values are only applied when a value is missing or `undefined`. In CoffeeScript 1.x, the default value would be applied in those cases but also if the  value was `null`.

```
codeFor('breaking_change_function_parameter_default_values', 'f(null)')
```

```
codeFor('breaking_change_destructuring_default_values', 'a')
```

</section>
<section id="breaking-changes-bound-generator-functions">

### Bound generator functions

Bound generator functions, a.k.a. generator arrow functions, [aren’t allowed in ECMAScript](http://stackoverflow.com/questions/27661306/can-i-use-es6s-arrow-function-syntax-with-generators-arrow-notation). You can write `function*` or `=>`, but not both. Therefore, CoffeeScript code like this:

```coffee
f = => yield this
# Throws a compiler error
```

Needs to be rewritten the old-fashioned way:

```
codeFor('breaking_change_bound_generator_function')
```

</section>
<section id="breaking-changes-classes">

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

</section>
<section id="breaking-changes-bare-super">

### Bare `super`

Due to a syntax clash with `super` with accessors, bare `super` no longer compiles to a super call forwarding all arguments.

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

</section>
<section id="breaking-changes-super-in-non-class-methods">

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

</section>
<section id="breaking-changes-dynamic-class-keys-exclude-executable-class-scope">

### Dynamic class keys exclude executable class scope

Due to the hoisting required to compile to ES2015 classes, dynamic keys in class methods can’t use values from the executable class body unless the methods are assigned in prototype style.

```coffee
class A
  name = 'method'
  "#{name}": ->   # This method will be named 'undefined'
  @::[name] = ->  # This will work; assigns to `A.prototype.method`
```

</section>

<section id="breaking-changes-literate-coffeescript">

### Literate CoffeeScript parsing now more standardized

In CoffeeScript 2’s parsing of Literate CoffeeScript this has been refactored to now be more careful about not treating indented lists as code blocks; but this means that all code blocks (unless they are to be interpreted as comments) must be separated by at least one blank line from lists.

Code blocks should also now maintain a consistent indentation level—so an indentation of one tab (or whatever you consider to be a tab stop, like 2 spaces or 4 spaces) should be treated as your code’s “left margin,” with all code in the file relative to that column.

Code blocks that you want to be part of the commentary, and not executed, must have at least one line (ideally the first line of the block) completely unindented.
