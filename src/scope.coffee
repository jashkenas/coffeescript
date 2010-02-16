this.exports: this unless process?

# Scope objects form a tree corresponding to the shape of the function
# definitions present in the script. They provide lexical scope, to determine
# whether a variable has been seen before or if it needs to be declared.
#
# Initialize a scope with its parent, for lookups up the chain,
# as well as the Expressions body where it should declare its variables,
# and the function that it wraps.
Scope: exports.Scope: (parent, expressions, method) ->
  @parent: parent
  @expressions: expressions
  @method: method
  @variables: {}
  @temp_variable: if @parent then @parent.temp_variable else 1
  this

# Look up a variable in lexical scope, or declare it if not found.
Scope::find: (name, remote) ->
  found: @check name
  return found if found or remote
  @variables[name]: 'var'
  found

# Define a local variable as originating from a parameter in current scope
# -- no var required.
Scope::parameter: (name) ->
  @variables[name]: 'param'

# Just check to see if a variable has already been declared.
Scope::check: (name) ->
  return true if @variables[name]
  !!(@parent and @parent.check(name))

# You can reset a found variable on the immediate scope.
Scope::reset: (name) ->
  delete @variables[name]

# Find an available, short, name for a compiler-generated variable.
Scope::free_variable: ->
  id: '_' + @temp_variable
  while @check(id)
    id: '_' + (@temp_variable += 1)
  @variables[id]: 'var'
  id

# Ensure that an assignment is made at the top of scope (or top-level
# scope, if requested).
Scope::assign: (name, value, top_level) ->
  return @parent.assign(name, value, top_level) if top_level and @parent
  @variables[name]: {value: value, assigned: true}

# Does this scope reference any variables that need to be declared in the
# given function body?
Scope::has_declarations: (body) ->
  body is @expressions and @declared_variables().length

# Does this scope reference any assignments that need to be declared at the
# top of the given function body?
Scope::has_assignments: (body) ->
  body is @expressions and @assigned_variables().length

# Return the list of variables first declared in current scope.
Scope::declared_variables: ->
  (key for key, val of @variables when val is 'var').sort()

# Return the list of variables that are supposed to be assigned at the top
# of scope.
Scope::assigned_variables: ->
  ([key, val.value] for key, val of @variables when val.assigned).sort()

Scope::compiled_declarations: ->
  @declared_variables().join(', ')

Scope::compiled_assignments: ->
  (t[0] + ' = ' + t[1] for t in @assigned_variables()).join(', ')
