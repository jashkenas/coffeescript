## Classes, Inheritance, and Super

JavaScript’s prototypal inheritance has always been a bit of a brain-bender, with a whole family tree of libraries that provide a cleaner syntax for classical inheritance on top of JavaScript’s prototypes: [Base2](http://code.google.com/p/base2/), [Prototype.js](http://prototypejs.org/), [JS.Class](http://jsclass.jcoglan.com/), etc. The libraries provide syntactic sugar, but the built-in inheritance would be completely usable if it weren’t for a couple of small exceptions: it’s awkward to call **super** (the prototype object’s implementation of the current function), and it’s awkward to correctly set the prototype chain.

Instead of repetitively attaching functions to a prototype, CoffeeScript provides a basic `class` structure that allows you to name your class, set the superclass, assign prototypal properties, and define the constructor, in a single assignable expression.

Constructor functions are named, to better support helpful stack traces. In the first class in the example below, `this.constructor.name is "Animal"`.

```
codeFor('classes', true)
```

If structuring your prototypes classically isn’t your cup of tea, CoffeeScript provides a couple of lower-level conveniences. The `extends` operator helps with proper prototype setup, and can be used to create an inheritance chain between any pair of constructor functions; `::` gives you quick access to an object’s prototype; and `super()` is converted into a call against the immediate ancestor’s method of the same name.

```
codeFor('prototypes', '"one_two".dasherize()')
```

Finally, class definitions are blocks of executable code, which make for interesting metaprogramming possibilities. Because in the context of a class definition, `this` is the class object itself (the constructor function), you can assign static properties by using
`@property: value`, and call functions defined in parent classes: `@attr 'title', type: 'text'`
