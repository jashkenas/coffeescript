module CoffeeScript

  # Scope objects form a tree corresponding to the shape of the function
  # definitions present in the script. They provide lexical scope, to determine
  # whether a variable has been seen before or if it needs to be declared.
  class Scope

    attr_reader :parent, :temp_variable

    # Initialize a scope with its parent, for lookups up the chain.
    def initialize(parent=nil)
      @parent = parent
      @variables = {}
      @temp_variable = @parent ? @parent.temp_variable : 'a'
    end

    # Look up a variable in lexical scope, or declare it if not found.
    def find(name, remote=false)
      found = check(name, remote)
      return found if found || remote
      @variables[name] = true
      found
    end

    # Just check to see if a variable has already been declared.
    def check(name, remote=false)
      return true if @variables[name]
      @parent && @parent.find(name, true)
    end

    # Find an available, short, name for a compiler-generated variable.
    def free_variable
      @temp_variable.succ! while check(@temp_variable)
      @variables[@temp_variable] = true
      @temp_variable.dup
    end

  end

end