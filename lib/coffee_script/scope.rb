module CoffeeScript

  # Scope objects form a tree corresponding to the shape of the function
  # definitions present in the script. They provide lexical scope, to determine
  # whether a variable has been seen before or if it needs to be declared.
  class Scope

    attr_reader :parent, :expressions, :function, :variables, :temp_variable

    # Initialize a scope with its parent, for lookups up the chain,
    # as well as the Expressions body where it should declare its variables,
    # and the function that it wraps.
    def initialize(parent, expressions, function)
      @parent, @expressions, @function = parent, expressions, function
      @variables = {}
      @temp_variable = @parent ? @parent.temp_variable.dup : '__a'
    end

    # Look up a variable in lexical scope, or declare it if not found.
    def find(name, remote=false)
      found = check(name)
      return found if found || remote
      @variables[name.to_sym] = :var
      found
    end

    # Define a local variable as originating from a parameter in current scope
    # -- no var required.
    def parameter(name)
      @variables[name.to_sym] = :param
    end

    # Just check to see if a variable has already been declared.
    def check(name)
      return true if @variables[name.to_sym]
      !!(@parent && @parent.check(name))
    end

    # You can reset a found variable on the immediate scope.
    def reset(name)
      @variables[name.to_sym] = false
    end

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

    # Does this scope reference any variables that need to be declared in the
    # given function body?
    def declarations?(body)
      !declared_variables.empty? && body == @expressions
    end

    # Does this scope reference any assignments that need to be declared at the
    # top of the given function body?
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

end