## get and set
`get` and `set`, as keywords preceding functions or class methods, are intentionally not implemented in CoffeeScript. 

This is to avoid grammatical ambiguity, since in CoffeeScript such a construct looks identical to a function call (e.g. get(function foo() {})) and because there is an alternate syntax that is slightly more verbose but just as effective:

```coffeescript
screen = 
  width: 1200
  ratio: 0.8

Object.defineProperty screen, "height", 
  get: () ->
    screen.width * screen.ratio
  set: (val) ->
    console.log "Can't set the height."

console.log screen.height   # 960
```

Check out [the MDN Reference](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/defineProperty).

Another alternative is to use a [Proxy object](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Proxy).