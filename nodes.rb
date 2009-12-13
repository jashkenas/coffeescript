# Tabs are two spaces for pretty-printing.
TAB = '  '

# Collection of nodes each one representing an expression.
class Nodes
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
    reduce.map { |node|
      indent + node.compile(indent) + (node.is_a?(IfNode) ? '' : ';')
    }.join("\n")
  end
end

# Literals are static values that have a Ruby representation, eg.: a string, a number,
# true, false, nil, etc.
class LiteralNode
  def initialize(value)
    @value = value
  end

  def compile(indent)
    @value.to_s
  end
end

# Node of a method call or local variable access, can take any of these forms:
#
#   method # this form can also be a local variable
#   method(argument1, argument2)
#   receiver.method
#   receiver.method(argument1, argument2)
#
class CallNode
  def initialize(variable, arguments=[])
    @variable, @arguments = variable, arguments
  end

  def compile(indent)
    args = @arguments.map{|a| a.compile(indent) }.join(', ')
    "#{@variable.compile(indent)}(#{args})"
  end
end

class VariableNode
  def initialize(name)
    @name = name
    @properties = []
  end

  def <<(other)
    @properties << other
    self
  end

  def compile(indent)
    [@name, @properties].flatten.join('.')
  end
end

# Setting the value of a local variable.
class AssignNode
  def initialize(variable, value, context=nil)
    @variable, @value, @context = variable, value, context
  end

  def compile(indent)
    return "#{@variable}: #{@value.compile(indent + TAB)}" if @context == :object
    "var #{@variable.compile(indent)} = #{@value.compile(indent)}"
  end
end

# Simple Arithmetic and logical operations
class OpNode
  CONVERSIONS = {
    "=="    => "===",
    "!="    => "!==",
    'and'   => '&&',
    'or'    => '||',
    'is'    => '===',
    "aint"  => "!==",
    'not'   => '!',
  }

  def initialize(operator, first, second=nil)
    @first, @second = first, second
    @operator = CONVERSIONS[operator] || operator
  end

  def unary?
    @second.nil?
  end

  def compile(indent)
    "(#{@first.compile(indent)} #{@operator} #{@second.compile(indent)})"
  end
end

# Method definition.
class CodeNode
  def initialize(params, body)
    @params = params
    @body = body
  end

  def compile(indent)
    nodes = @body.reduce
    exprs = nodes.map {|n| n.compile(indent + TAB) }
    exprs[-1] = "return #{exprs[-1]};"
    exprs = exprs.map {|e| indent + TAB + e }
    "function(#{@params.join(', ')}) {\n#{exprs.join(";\n")}\n#{indent}}"
  end
end

class ObjectNode
  def initialize(properties = [])
    @properties = properties
  end

  def compile(indent)
    props = @properties.map {|p| indent + TAB + p.compile(indent) }.join(",\n")
    "{\n#{props}\n#{indent}}"
  end
end

class ArrayNode
  def initialize(objects=[])
    @objects = objects
  end

  def compile(indent)
    objects = @objects.map {|o| o.compile(indent) }.join(', ')
    "[#{objects}]"
  end
end

# "if-else" control structure. Look at this node if you want to implement other control
# structures like while, for, loop, etc.
class IfNode
  def initialize(condition, body, else_body=nil)
    @condition, @body, @else_body = condition, body, else_body
  end

  def compile(indent)
    if_part   = "if (#{@condition.compile(indent)}) {\n#{@body.compile(indent + TAB)}\n#{indent}}"
    else_part = @else_body ? " else {\n#{@else_body.compile(indent + TAB)}\n#{indent}}" : ''
    if_part + else_part
  end
end

class TernaryNode
  def initialize(condition, body, else_body=nil)
    @condition, @body, @else_body = condition, body, else_body
  end

  def compile(indent)
    if_part   = "#{@condition.compile(indent)} ? #{@body.compile(indent)}"
    else_part = @else_body ? "#{@else_body.compile(indent)}" : 'null'
    "#{if_part} : #{else_part}"
  end
end