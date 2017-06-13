# Helper functions
hasProp = {}.hasOwnProperty
extend = (child, parent) ->
  ctor = ->
    @constructor = child
    return
  for key of parent
    if hasProp.call(parent, key)
      child[key] = parent[key]
  ctor.prototype = parent.prototype
  child.prototype = new ctor
  child


A = ->
B = ->
extend B, A
B.prototype.foo = -> A::foo.apply this, arguments
