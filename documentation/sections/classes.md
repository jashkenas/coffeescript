## Classes, Inheritance, and Super

CoffeeScript 1 provided the `class` and `extends` keywords as syntactic sugar for working with prototypal functions. With ES2015, JavaScript has adopted those keywords; so CoffeeScript 2 compiles its `class` and `extends` keywords to ES2015 classes.

```
codeFor('classes', true)
```

Static methods can be defined using `@` before the method name:

```
codeFor('static', 'Teenager.say("Are we there yet?")')
```

And `::` gives you quick access to an object’s prototype:

```
codeFor('prototypes', '"one_two".dasherize()')
```
