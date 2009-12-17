# A class to handle lookups for lexically scoped variables.
class Scope

  attr_reader :parent, :temp_variable

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

  # Just check for the pre-definition of a variable.
  def check(name, remote=false)
    return true if @variables[name]
    @parent && @parent.find(name, true)
  end

  # Find an available, short variable name.
  def free_variable
    @temp_variable.succ! while check(@temp_variable)
    @variables[@temp_variable] = true
    @temp_variable.dup
  end

end