## Classes

CoffeeScript 1 provided the `class` and `extends` keywords as syntactic sugar for working with prototypal functions. With ES2015, JavaScript has adopted those keywords; so CoffeeScript 2 compiles its `class` and `extends` keywords to ES2015 classes.

```
codeFor('classes', true)
```

Static methods can be defined using `@` before the method name:

```
codeFor('static', 'Teenager.say("Are we there yet?")')
```

Finally, class definitions are blocks of executable code, which make for interesting metaprogramming possibilities. In the context of a class definition, `this` is the class object itself; therefore, you can assign static properties by using `@property: value`.
