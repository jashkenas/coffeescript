# The **Scope** class regulates lexical scoping within CoffeeScript. As you
# generate code, you create a tree of scopes in the same shape as the nested
# function bodies. Each scope knows about the variables declared within it,
# and has a reference to its parent enclosing scope. In this way, we know which
# variables are new and need to be declared with `var`, and which are shared
# with the outside.

# Set up exported variables for both **Node.js** and the browser.
this.exports: this unless process?
utilities: if process? then require('./utilities').utilities else this.utilities

exports.Scope: class Scope

  # Initialize a scope with its parent, for lookups up the chain,
  # as well as a reference to the **Expressions** node is belongs to, which is
  # where it should declare its variables, and a reference to the function that
  # it wraps.
  constructor: (parent, expressions, method) ->
    [@parent, @expressions, @method]: [parent, expressions, method]
    @variables: {}
    @temp_var: if @parent then @parent.temp_var else '_a'

  # Find the top-most scope object, used for defined global variables
  topmost: ->
    if @parent then @parent.topmost() else @

  # Look up a variable name in lexical scope, and declare it if it does not
  # already exist.
  find: (name) ->
    return true if @check name
    @variables[name]: 'var'
    false

  # Test variables and return true the first time fn(v, k) returns true
  any: (fn) ->
    for v, k of @variables when fn(v, k)
      return true
    return false

  # Reserve a variable name as originating from a function parameter for this
  # scope. No `var` required for internal references.
  parameter: (name) ->
    @variables[name]: 'param'

  # Just check to see if a variable has already been declared, without reserving.
  check: (name) ->
    return true if @variables[name]
    !!(@parent and @parent.check(name))

  # If we need to store an intermediate result, find an available name for a
  # compiler-generated variable. `_a`, `_b`, and so on...
  free_variable: ->
    while @check @temp_var
      ordinal: 1 + parseInt @temp_var.substr(1), 36
      @temp_var: '_' + ordinal.toString(36).replace(/\d/g, 'a')
    @variables[@temp_var]: 'var'
    @temp_var

  # Ensure that an assignment is made at the top of this scope
  # (or at the top-level scope, if requested).
  assign: (name, value, top_level) ->
    return @topmost().assign(name, value) if top_level
    @variables[name]: {value: value, assigned: true}

  # Ensure the CoffeeScript utility object is included in the top level
  # then return a CallNode curried constructor bound to the utility function
  utility: (name) ->
    return @topmost().utility(name) if @parent
    if utilities.functions[name]?
      @utilities: or {}
      @utilities[name]: utilities.functions[name]
      @utility(dep) for dep in (utilities.dependencies[name] or []) when not @utilities[dep]
    "__$name"

  # Formats an javascript object containing the utility methods required
  # in the scope
  included_utilities: (tab) ->
    if @utilities?
      utilities.format(key, tab) for key of @utilities
    else []

  # Does this scope reference any variables that need to be declared in the
  # given function body?
  has_declarations: (body) ->
    body is @expressions and @any (k, val) -> val is 'var'

  # Does this scope reference any assignments that need to be declared at the
  # top of the given function body?
  has_assignments: (body) ->
    body is @expressions and (@utilities? or @any (k, val) -> val.assigned)

  # Return the list of variables first declared in this scope.
  declared_variables: ->
    (key for key, val of @variables when val is 'var').sort()

  # Return the list of assignments that are supposed to be made at the top
  # of this scope.
  assigned_variables: ->
    "$key = ${val.value}" for key, val of @variables when val.assigned

  # Compile the JavaScript for all of the variable declarations in this scope.
  compiled_declarations: ->
    @declared_variables().join ', '

  # Compile the JavaScript for all of the variable assignments in this scope.
  compiled_assignments: (tab) ->
    [@assigned_variables()..., @included_utilities(tab)...].join ', '
