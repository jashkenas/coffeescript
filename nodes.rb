class Node
  # Tabs are two spaces for pretty-printing.
  TAB = '  '

  def line_ending
    ';'
  end

  def statement?
    false
  end

  def compile(indent='', opts={})
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

  #   line  = node.compile(indent + TAB, {:last => last})
  #   line  = "return #{line}" if last
  #   indent + TAB + line + node.line_ending

  def compile(indent='', opts={})
    @nodes.map { |n|
      if opts[:return] && n == @nodes.last
        if n.statement?
          "#{indent}#{n.compile(indent, {:return => true})}#{n.line_ending}"
        else
          "#{indent}return #{n.compile(indent)}#{n.line_ending}"
        end
      else
        "#{indent}#{n.compile(indent)}#{n.line_ending}"
      end
    }.join("\n")
  end
end

# Literals are static values that have a Ruby representation, eg.: a string, a number,
# true, false, nil, etc.
class LiteralNode < Node
  def initialize(value)
    @value = value
  end

  def compile(indent, opts={})
    @value.to_s
  end
end

class ReturnNode < Node
  def initialize(expression)
    @expression = expression
  end

  def compile(indent, opts={})
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
  def initialize(variable, arguments=[])
    @variable, @arguments = variable, arguments
  end

  def new_instance
    @new = true
    self
  end

  def compile(indent, opts={})
    args = @arguments.map{|a| a.compile(indent, :no_paren => true) }.join(', ')
    prefix = @new ? "new " : ''
    "#{prefix}#{@variable.compile(indent)}(#{args})"
  end
end

class ValueNode < Node
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

  def compile(indent, opts={})
    [@name, @properties].flatten.map { |v|
      v.respond_to?(:compile) ? v.compile(indent) : v.to_s
    }.join('')
  end
end

class AccessorNode
  def initialize(name)
    @name = name
  end

  def compile(indent, opts={})
    ".#{@name}"
  end
end

class IndexNode
  def initialize(index)
    @index = index
  end

  def compile(indent, opts={})
    "[#{@index.compile(indent)}]"
  end
end

# Setting the value of a local variable.
class AssignNode < Node
  def initialize(variable, value, context=nil)
    @variable, @value, @context = variable, value, context
  end

  def compile(indent, opts={})
    return "#{@variable}: #{@value.compile(indent + TAB)}" if @context == :object
    var_part = @variable.compile(indent)
    var_part = "var " + var_part unless @variable.properties? || opts[:last]
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

  def compile(indent, opts={})
    return compile_conditional(indent) if CONDITIONALS.include?(@operator)
    op = "#{@first.compile(indent)} #{@operator} #{@second.compile(indent)}"
    opts[:no_paren] ? op : "(#{op})"
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

  def compile(indent, opts={})
    # nodes   = @body.respond_to?(:reduce) ? @body.reduce : [@body]
    # code    = nodes.map { |node|
    #   last  = node == nodes.last
    #   line  = node.compile(indent + TAB, {:last => last})
    #   line  = "return #{line}" if last
    #   indent + TAB + line + node.line_ending
    # }.join("\n")
    code = @body.compile(indent + TAB, {:return => true})
    "function(#{@params.join(', ')}) {\n#{code}\n#{indent}}"
  end
end

class ObjectNode < Node
  def initialize(properties = [])
    @properties = properties
  end

  def compile(indent, opts={})
    props = @properties.map {|p| indent + TAB + p.compile(indent) }.join(",\n")
    "{\n#{props}\n#{indent}}"
  end
end

class ArrayNode < Node
  def initialize(objects=[])
    @objects = objects
  end

  def compile(indent, opts={})
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

  def compile(indent, opts={})
    statement? ? compile_statement(indent, opts) : compile_ternary(indent)
  end

  def compile_statement(indent, opts)
    if_part   = "if (#{@condition.compile(indent, :no_paren => true)}) {\n#{@body.compile(indent + TAB, opts)}\n#{indent}}"
    else_part = @else_body ? " else {\n#{@else_body.compile(indent + TAB, opts)}\n#{indent}}" : ''
    if_part + else_part
  end

  def compile_ternary(indent)
    if_part   = "#{@condition.compile(indent)} ? #{@body.compile(indent)}"
    else_part = @else_body ? "#{@else_body.compile(indent)}" : 'null'
    "#{if_part} : #{else_part}"
  end
end

class TryNode < Node
  def initialize(try, error, recovery, finally=nil)
    @try, @error, @recovery, @finally = try, error, recovery, finally
  end

  def line_ending
    ''
  end

  def statement?
    true
  end

  def compile(indent, opts={})
    catch_part = @recovery &&  " catch (#{@error}) {\n#{@recovery.compile(indent + TAB, opts)}\n#{indent}}"
    finally_part = @finally && " finally {\n#{@finally.compile(indent + TAB, opts)}\n#{indent}}"
    "try {\n#{@try.compile(indent + TAB, opts)}\n#{indent}}#{catch_part}#{finally_part}"
  end
end

class ThrowNode < Node
  def initialize(expression)
    @expression = expression
  end

  def compile(indent, opts={})
    "throw #{@expression.compile(indent)}"
  end
end

class ParentheticalNode < Node
  def initialize(expressions)
    @expressions = expressions
  end

  def compile(indent, opts={})
    compiled = @expressions.compile(indent)
    compiled = compiled[0...-1] if compiled[-1..-1] == ';'
    opts[:no_paren] ? compiled : "(#{compiled})"
  end
end
