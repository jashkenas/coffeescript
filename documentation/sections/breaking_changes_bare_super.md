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
