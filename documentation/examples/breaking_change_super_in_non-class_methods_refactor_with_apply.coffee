A = ->
B = ->
B extends A
B.prototype.foo = -> A::foo.apply this, arguments
