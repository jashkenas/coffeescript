dup: (input) ->
  output: null
  if input instanceof Array
    output: []
    for val in input
      output.push(val)
  else
    output: {}
    for key, val of input
      output.key: val
    output
  output

# scope objects form a tree corresponding to the shape of the function
# definitions present in the script. They provide lexical scope, to determine
# whether a variable has been seen before or if it needs to be declared.
exports.Scope: (parent, expressions, func) ->
  # Initialize a scope with its parent, for lookups up the chain,
  # as well as the Expressions body where it should declare its variables,
  # and the function that it wraps.
  this.parent: parent
  this.expressions: expressions
  this.function: func
  this.variables: {}
  this.temp_variable: if this.parent then dup(this.parent.temp_variable) else '__a'

# Look up a variable in lexical scope, or declare it if not found.
exports.Scope::find: (name, rem) ->
  remote: if rem? then rem else false
  found: this.check(name)
  return found if found || remote
  this.variables[name]: 'var'
  found

# Define a local variable as originating from a parameter in current scope
# -- no var required.
exports.Scope::parameter: (name) ->
  this.variables[name]: 'param'

# Just check to see if a variable has already been declared.
exports.Scope::check: (name) ->
  return true if this.variables[name]?
  # TODO: what does that ruby !! mean..? need to follow up
  # .. this next line is prolly wrong ..
  not not (this.parent and this.parent.check(name))

# You can reset a found variable on the immediate scope.
exports.Scope::reset: (name) ->
  this.variables[name]: undefined
