### Dynamic class keys exclude executable class scope

Due to the hoisting required to compile to ES2015 classes, dynamic keys in class methods can’t use values from the executable class body unless the methods are assigned in prototype style.

```coffee
class A
  name = 'method'
  "#{name}": ->   # This method will be named 'undefined'
  @::[name] = ->  # This will work; assigns to `A.prototype.method`
```
