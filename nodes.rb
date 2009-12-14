class Node
  # Tabs are two spaces for pretty-printing.
  TAB = '  '

  def line_ending
    ';'
  end

  def compile(indent='', last=false)
  end
end

# Collection of nodes each one representing an expression.
class Nodes < Node
  attr_reader :nodes
  def initialize(nodes)
    @nodes = nodes
  end

  def <<(node)
    @nodes << node
    self
  end

  # Flatten redundant nested node lists until we have multiple nodes on the
  # same level to work with.
  def reduce
    return nodes.first.reduce if nodes.length == 1 && nodes.first.is_a?(Nodes)
    nodes
  end

  def compile(indent='')
    reduce.map {|n| indent + n.compile(indent) + n.line_ending }.join("\n")
  end
end

# Literals are static values that have a Ruby representation, eg.: a string, a number,
# true, false, nil, etc.
class LiteralNode < Node
  def initialize(value)
    @value = value
  end

  def compile(indent, last=false)
    @value.to_s
  end
end

class ReturnNode < Node
  def initialize(expression)
    @expression = expression
  end

  def compile(indent, last=false)
    "#{indent}return #{@expression.compile(indent)};"
  end
end

# Node of a method call or local variable access, can take any of these forms:
#
#   method # this form can also be a local variable
#   method(argument1, argument2)
#   receiver.method
#   receiver.method(argument1, argument2)
#
class CallNode < Node
  def initialize(variable, arguments=[], new_instance=false)
    @variable, @arguments, @new = variable, arguments, new_instance
  end

  def compile(indent, last=false)
    args = @arguments.map{|a| a.compile(indent) }.join(', ')
    prefix = @new ? "new " : ''
    "#{prefix}#{@variable.compile(indent)}(#{args})"
  end
end

class VariableNode < Node
  def initialize(name, properties=[])
    @name, @properties = name, properties
  end

  def <<(other)
    @properties << other
    self
  end

  def properties?
    return !@properties.empty?
  end

  def compile(indent, last=false)
    [@name, @properties].flatten.map { |v|
      v.respond_to?(:compile) ? v.compile(indent) : v.to_s
    }.join('')
  end
end

class AccessorNode
  def initialize(name)
    @name = name
  end

  def compile(indent, last=false)
    ".#{@name}"
  end
end

class IndexNode
  def initialize(index)
    @index = index
  end

  def compile(indent, last=false)
    "[#{@index.compile(indent)}]"
  end
end

# Setting the value of a local variable.
class AssignNode < Node
  def initialize(variable, value, context=nil)
    @variable, @value, @context = variable, value, context
  end

  def compile(indent, last=false)
    return "#{@variable}: #{@value.compile(indent + TAB)}" if @context == :object
    var_part = @variable.compile(indent)
    var_part = "var " + var_part unless @variable.properties? || last
    "#{var_part} = #{@value.compile(indent)}"
  end
end

# Simple Arithmetic and logical operations
class OpNode < Node
  CONVERSIONS = {
    "=="    => "===",
    "!="    => "!==",
    'and'   => '&&',
    'or'    => '||',
    'is'    => '===',
    "aint"  => "!==",
    'not'   => '!',
  }
  CONDITIONALS = ['||=', '&&=']

  def initialize(operator, first, second=nil)
    @first, @second = first, second
    @operator = CONVERSIONS[operator] || operator
  end

  def unary?
    @second.nil?
  end

  def compile(indent, last=false)
    return compile_conditional(indent) if CONDITIONALS.include?(@operator)
    "(#{@first.compile(indent)} #{@operator} #{@second.compile(indent)})"
  end

  def compile_conditional(indent)
    first, second = @first.compile(indent), @second.compile(indent)
    sym = @operator[0..1]
    "(#{first} = #{first} #{sym} #{second})"
  end
end

# Method definition.
class CodeNode < Node
  def initialize(params, body)
    @params = params
    @body = body
  end

  def compile(indent, last=false)
    nodes   = @body.respond_to?(:reduce) ? @body.reduce : [@body]
    code    = nodes.map { |node|
      last  = node == nodes.last
      line  = node.compile(indent + TAB, last)
      line  = "return #{line}" if last
      indent + TAB + line + node.line_ending
    }.join("\n")
    "function(#{@params.join(', ')}) {\n#{code}\n#{indent}}"
  end
end

class ObjectNode < Node
  def initialize(properties = [])
    @properties = properties
  end

  def compile(indent, last=false)
    props = @properties.map {|p| indent + TAB + p.compile(indent) }.join(",\n")
    "{\n#{props}\n#{indent}}"
  end
end

class ArrayNode < Node
  def initialize(objects=[])
    @objects = objects
  end

  def compile(indent, last=false)
    objects = @objects.map {|o| o.compile(indent) }.join(', ')
    "[#{objects}]"
  end
end

# "if-else" control structure. Look at this node if you want to implement other control
# structures like while, for, loop, etc.
class IfNode < Node
  FORCE_STATEMENT = [Nodes, ReturnNode]

  def initialize(condition, body, else_body=nil)
    @condition, @body, @else_body = condition, body, else_body
  end

  def statement?
    FORCE_STATEMENT.include?(@body.class) || FORCE_STATEMENT.include?(@else_body.class)
  end

  def line_ending
    statement? ? '' : ';'
  end

  def compile(indent, last=false)
    statement? ? compile_statement(indent) : compile_ternary(indent)
  end

  def compile_statement(indent)
    if_part   = "if (#{@condition.compile(indent)}) {\n#{@body.compile(indent + TAB)}\n#{indent}}"
    else_part = @else_body ? " else {\n#{@else_body.compile(indent + TAB)}\n#{indent}}" : ''
    if_part + else_part
  end

  def compile_ternary(indent)
    if_part   = "#{@condition.compile(indent)} ? #{@body.compile(indent)}"
    else_part = @else_body ? "#{@else_body.compile(indent)}" : 'null'
    "#{if_part} : #{else_part}"
  end
end

class ParentheticalNode < Node
  def initialize(expressions)
    @expressions = expressions
  end

  def compile(indent, last=false)
    compiled = @expressions.compile(indent)
    compiled = compiled[0...-1] if compiled[-1..-1] == ';'
    "(#{compiled})"
  end
end
