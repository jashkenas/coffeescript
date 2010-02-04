dup: (input) ->
  output: null
  if input instaceof Array
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
  this.temp_variable: if this.parent then dup(this.parent.temp_variable) : '__a'

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
  this.variables[name]: = 'param'

# Just check to see if a variable has already been declared.
exports.Scope::check: (name) ->
  return true if this.variables[name]?
  # TODO: what does that ruby !! mean..? need to follow up
  # .. this next line is prolly wrong ..
  not not (this.parent and this.parent.check(name))

# You can reset a found variable on the immediate scope.
exports.Scope::reset: (name) ->
  this.variables[name]: undefined

exports.Scope::free_variable: ->
  # need .succ! impl

    # Find an available, short, name for a compiler-generated variable.
    def free_variable
      @temp_variable.succ! while check(@temp_variable)
      @variables[@temp_variable.to_sym] = :var
      Value.new(@temp_variable.dup)
    end

    # Ensure that an assignment is made at the top of scope (or top-level
    # scope, if requested).
    def assign(name, value, top=false)
      return @parent.assign(name, value, top) if top && @parent
      @variables[name.to_sym] = Value.new(value)
    end

    def declarations?(body)
      !declared_variables.empty? && body == @expressions
    end

    def assignments?(body)
      !assigned_variables.empty? && body == @expressions
    end

    # Return the list of variables first declared in current scope.
    def declared_variables
      @variables.select {|k, v| v == :var }.map {|pair| pair[0].to_s }.sort
    end

    # Return the list of variables that are supposed to be assigned at the top
    # of scope.
    def assigned_variables
      @variables.select {|k, v| v.is_a?(Value) }.sort_by {|pair| pair[0].to_s }
    end

    def compiled_declarations
      declared_variables.join(', ')
    end

    def compiled_assignments
      assigned_variables.map {|name, val| "#{name} = #{val}"}.join(', ')
    end

    def inspect
      "<Scope:#{__id__} #{@variables.inspect}>"
    end

  end
