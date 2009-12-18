module CoffeeScript

  # The abstract base class for all CoffeeScript nodes.
  class Node
    # Tabs are two spaces for pretty-printing.
    TAB = '  '

    def flatten;          self;   end
    def line_ending;      ';';    end
    def statement?;       false;  end
    def custom_return?;   false;  end
    def custom_assign?;   false;  end

    def compile(indent='', scope=nil, opts={}); end
  end

  # A collection of nodes, each one representing an expression.
  class Expressions < Node
    attr_reader :expressions

    def self.wrap(node)
      node.is_a?(Expressions) ? node : Expressions.new([node])
    end

    def initialize(nodes)
      @expressions = nodes
    end

    def <<(node)
      @expressions << node
      self
    end

    def flatten
      @expressions.length == 1 ? @expressions.first : self
    end

    def begin_compile
      "(function(){\n#{compile(TAB, Scope.new)}\n})();"
    end

    def statement?
      true
    end

    # Fancy to handle pushing down returns recursively to the final lines of
    # inner statements (to make expressions out of them).
    def compile(indent='', scope=nil, opts={})
      return begin_compile unless scope
      @expressions.map { |n|
        if opts[:return] && n == @expressions.last
          if n.statement? || n.custom_return?
            "#{indent}#{n.compile(indent, scope, opts)}#{n.line_ending}"
          else
            "#{indent}return #{n.compile(indent, scope, opts)}#{n.line_ending}"
          end
        else
          "#{indent}#{n.compile(indent, scope)}#{n.line_ending}"
        end
      }.join("\n")
    end
  end

  # Literals are static values that have a Ruby representation, eg.: a string, a number,
  # true, false, nil, etc.
  class LiteralNode < Node
    STATEMENTS = ['break', 'continue']

    def initialize(value)
      @value = value
    end

    def statement?
      STATEMENTS.include?(@value.to_s)
    end

    def compile(indent, scope, opts={})
      @value.to_s
    end
  end

  class ReturnNode < Node
    def initialize(expression)
      @expression = expression
    end

    def statement?
      true
    end

    def custom_return?
      true
    end

    def compile(indent, scope, opts={})
      return @expression.compile(indent, scope, opts.merge(:return => true)) if @expression.custom_return?
      compiled = @expression.compile(indent, scope)
      @expression.statement? ? "#{compiled}\n#{indent}return null" : "return #{compiled}"
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
    LEADING_DOT = /\A\./

    def initialize(variable, arguments=[])
      @variable, @arguments = variable, arguments
    end

    def new_instance
      @new = true
      self
    end

    def super?
      @variable == :super
    end

    def compile(indent, scope, opts={})
      args = @arguments.map{|a| a.compile(indent, scope, :no_paren => true) }.join(', ')
      return compile_super(args, indent, scope, opts) if super?
      prefix = @new ? "new " : ''
      "#{prefix}#{@variable.compile(indent, scope)}(#{args})"
    end

    def compile_super(args, indent, scope, opts)
      methname = opts[:last_assign].sub(LEADING_DOT, '')
      "this.constructor.prototype.#{methname}.call(this, #{args})"
    end
  end

  class ValueNode < Node
    attr_reader :last

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

    def compile(indent, scope, opts={})
      parts = [@name, @properties].flatten.map do |v|
        v.respond_to?(:compile) ? v.compile(indent, scope) : v.to_s
      end
      @last = parts.last
      parts.join('')
    end
  end

  class AccessorNode
    def initialize(name)
      @name = name
    end

    def compile(indent, scope, opts={})
      ".#{@name}"
    end
  end

  class IndexNode
    def initialize(index)
      @index = index
    end

    def compile(indent, scope, opts={})
      "[#{@index.compile(indent, scope)}]"
    end
  end

  class SliceNode
    def initialize(from, to)
      @from, @to = from, to
    end

    def compile(indent, scope, opts={})
      ".slice(#{@from.compile(indent, scope, opts)}, #{@to.compile(indent, scope, opts)} + 1)"
    end
  end

  # Setting the value of a local variable.
  class AssignNode < Node
    def initialize(variable, value, context=nil)
      @variable, @value, @context = variable, value, context
    end

    def custom_return?
      true
    end

    def statement?
      true
    end

    def compile(indent, scope, opts={})
      name      = @variable.compile(indent, scope) if @variable.respond_to?(:compile)
      last      = @variable.respond_to?(:last) ? @variable.last : name
      opts      = opts.merge({:assign => name, :last_assign => last})
      value     = @value.compile(indent + TAB, scope, opts)
      return "#{@variable}: #{value}" if @context == :object
      return "#{name} = #{value}" if @variable.properties?
      defined   = scope.find(name)
      postfix   = !defined && opts[:return] ? ";\n#{indent}return #{name}" : ''
      def_part  = defined ? "" : "var #{name};\n#{indent}"
      return def_part + @value.compile(indent, scope, opts) if @value.custom_assign?
      def_part  = defined ? name : "var #{name}"
      "#{def_part} = #{@value.compile(indent, scope, opts)}#{postfix}"
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

    def compile(indent, scope, opts={})
      return compile_conditional(indent, scope) if CONDITIONALS.include?(@operator)
      return compile_unary(indent, scope) if unary?
      "#{@first.compile(indent, scope)} #{@operator} #{@second.compile(indent, scope)}"
    end

    def compile_conditional(indent, scope)
      first, second = @first.compile(indent, scope), @second.compile(indent, scope)
      sym = @operator[0..1]
      "#{first} = #{first} #{sym} #{second}"
    end

    def compile_unary(indent, scope)
      space = @operator == 'delete' ? ' ' : ''
      "#{@operator}#{space}#{@first.compile(indent, scope)}"
    end
  end

  # Method definition.
  class CodeNode < Node
    def initialize(params, body)
      @params = params
      @body = body
    end

    def compile(indent, scope, opts={})
      scope = Scope.new(scope)
      @params.each {|id| scope.find(id) }
      opts  = opts.merge(:return => true)
      code  = @body.compile(indent + TAB, scope, opts)
      "function(#{@params.join(', ')}) {\n#{code}\n#{indent}}"
    end
  end

  class ObjectNode < Node
    def initialize(properties = [])
      @properties = properties
    end

    def compile(indent, scope, opts={})
      props = @properties.map {|p| indent + TAB + p.compile(indent, scope) }.join(",\n")
      "{\n#{props}\n#{indent}}"
    end
  end

  class ArrayNode < Node
    def initialize(objects=[])
      @objects = objects
    end

    def compile(indent, scope, opts={})
      objects = @objects.map {|o| o.compile(indent, scope) }.join(', ')
      "[#{objects}]"
    end
  end

  class WhileNode < Node
    def initialize(condition, body)
      @condition, @body = condition, body
    end

    def line_ending
      ''
    end

    def statement?
      true
    end

    def compile(indent, scope, opts={})
      "while (#{@condition.compile(indent, scope, :no_paren => true)}) {\n#{@body.compile(indent + TAB, scope)}\n#{indent}}"
    end
  end

  class ForNode < Node

    def initialize(body, source, name, index=nil)
      @body, @source, @name, @index = body, source, name, index
    end

    def line_ending
      ''
    end

    def custom_return?
      true
    end

    def custom_assign?
      true
    end

    def statement?
      true
    end

    def compile(indent, scope, opts={})
      svar        = scope.free_variable
      ivar        = scope.free_variable
      lvar        = scope.free_variable
      name_part   = scope.find(@name) ? @name : "var #{@name}"
      index_name  = @index ? (scope.find(@index) ? @index : "var #{@index}") : nil
      source_part = "var #{svar} = #{@source.compile(indent, scope)};"
      for_part    = "var #{ivar}=0, #{lvar}=#{svar}.length; #{ivar}<#{lvar}; #{ivar}++"
      var_part    = "\n#{indent + TAB}#{name_part} = #{svar}[#{ivar}];\n"
      index_part  = @index ? "#{indent + TAB}#{index_name} = #{ivar};\n" : ''

      set_result    = ''
      save_result   = ''
      return_result = ''
      if opts[:return] || opts[:assign]
        rvar          = scope.free_variable
        set_result    = "var #{rvar} = [];\n#{indent}"
        save_result   = "#{rvar}[#{ivar}] = "
        return_result = rvar
        return_result = "#{opts[:assign]} = #{return_result}" if opts[:assign]
        return_result = "return #{return_result}" if opts[:return]
        return_result = "\n#{indent}#{return_result}"
      end

      body = @body.compile(indent + TAB, scope)
      "#{source_part}\n#{indent}#{set_result}for (#{for_part}) {#{var_part}#{index_part}#{indent + TAB}#{save_result}#{body};\n#{indent}}#{return_result}"
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

    def compile(indent, scope, opts={})
      catch_part = @recovery &&  " catch (#{@error}) {\n#{@recovery.compile(indent + TAB, scope, opts)}\n#{indent}}"
      finally_part = @finally && " finally {\n#{@finally.compile(indent + TAB, scope, opts)}\n#{indent}}"
      "try {\n#{@try.compile(indent + TAB, scope, opts)}\n#{indent}}#{catch_part}#{finally_part}"
    end
  end

  class ThrowNode < Node
    def initialize(expression)
      @expression = expression
    end

    def statement?
      true
    end

    def compile(indent, scope, opts={})
      "throw #{@expression.compile(indent, scope)}"
    end
  end

  class ParentheticalNode < Node
    def initialize(expressions)
      @expressions = expressions
    end

    def compile(indent, scope, opts={})
      compiled = @expressions.flatten.compile(indent, scope)
      compiled = compiled[0...-1] if compiled[-1..-1] == ';'
      opts[:no_paren] ? compiled : "(#{compiled})"
    end
  end

  # "if-else" control structure. Look at this node if you want to implement other control
  # structures like while, for, loop, etc.
  class IfNode < Node
    def initialize(condition, body, else_body=nil, tag=nil)
      @condition = condition
      @body      = body && body.flatten
      @else_body = else_body && else_body.flatten
      @condition = OpNode.new("!", @condition) if tag == :invert
    end

    def <<(else_body)
      eb = else_body.flatten
      @else_body ? @else_body << eb : @else_body = eb
      self
    end

    # Rewrite a chain of IfNodes with their switch condition for equality.
    def rewrite_condition(expression)
      @condition = OpNode.new("is", expression, @condition)
      @else_body.rewrite_condition(expression) if chain?
      self
    end

    # Rewrite a chain of IfNodes to add a default case as the final else.
    def add_else(expressions)
      chain? ? @else_body.add_else(expressions) : @else_body = expressions
      self
    end

    def chain?
      @chain ||= @else_body && @else_body.is_a?(IfNode)
    end

    def statement?
      @is_statement ||= (@body.statement? || (@else_body && @else_body.statement?))
    end

    def line_ending
      statement? ? '' : ';'
    end

    def compile(indent, scope, opts={})
      statement? ? compile_statement(indent, scope, opts) : compile_ternary(indent, scope)
    end

    def compile_statement(indent, scope, opts)
      if_part   = "if (#{@condition.compile(indent, scope, :no_paren => true)}) {\n#{Expressions.wrap(@body).compile(indent + TAB, scope, opts)}\n#{indent}}"
      else_part = @else_body ? " else {\n#{Expressions.wrap(@else_body).compile(indent + TAB, scope, opts)}\n#{indent}}" : ''
      if_part + else_part
    end

    def compile_ternary(indent, scope)
      if_part   = "#{@condition.compile(indent, scope)} ? #{@body.compile(indent, scope)}"
      else_part = @else_body ? "#{@else_body.compile(indent, scope)}" : 'null'
      "#{if_part} : #{else_part}"
    end
  end

end