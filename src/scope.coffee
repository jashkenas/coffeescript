this.exports: this unless process?

# Scope objects form a tree corresponding to the shape of the function
# definitions present in the script. They provide lexical scope, to determine
# whether a variable has been seen before or if it needs to be declared.
#
# Initialize a scope with its parent, for lookups up the chain,
# as well as the Expressions body where it should declare its variables,
# and the function that it wraps.
exports.Scope: class Scope

  constructor: (parent, expressions, method) ->
    [@parent, @expressions, @method]: [parent, expressions, method]
    @variables: {}
    @temp_var: if @parent then @parent.temp_var else '_a'

  # Look up a variable in lexical scope, or declare it if not found.
  find: (name) ->
    return true if @check name
    @variables[name]: 'var'
    false

  # Define a local variable as originating from a parameter in current scope
  # -- no var required.
  parameter: (name) ->
    @variables[name]: 'param'

  # Just check to see if a variable has already been declared.
  check: (name) ->
    return true if @variables[name]
    !!(@parent and @parent.check(name))

  # You can reset a found variable on the immediate scope.
  reset: (name) ->
    delete @variables[name]

  # Find an available, short, name for a compiler-generated variable.
  free_variable: ->
    while @check @temp_var
      ordinal: 1 + parseInt @temp_var.substr(1), 36
      @temp_var: '_' + ordinal.toString(36).replace(/\d/g, 'a')
    @variables[@temp_var]: 'var'
    @temp_var

  # Ensure that an assignment is made at the top of scope (or top-level
  # scope, if requested).
  assign: (name, value, top_level) ->
    return @parent.assign(name, value, top_level) if top_level and @parent
    @variables[name]: {value: value, assigned: true}

  # Does this scope reference any variables that need to be declared in the
  # given function body?
  has_declarations: (body) ->
    body is @expressions and @declared_variables().length

  # Does this scope reference any assignments that need to be declared at the
  # top of the given function body?
  has_assignments: (body) ->
    body is @expressions and @assigned_variables().length

  # Return the list of variables first declared in current scope.
  declared_variables: ->
    (key for key, val of @variables when val is 'var').sort()

  # Return the list of variables that are supposed to be assigned at the top
  # of scope.
  assigned_variables: ->
    key + ' = ' + val.value for key, val of @variables when val.assigned

  # Compile the string representing all of the declared variables for this scope.
  compiled_declarations: ->
    @declared_variables().join ', '

  # Compile the string performing all of the variable assignments for this scope.
  compiled_assignments: ->
    @assigned_variables().join ', '
