module CoffeeScript

  # The abstract base class for all CoffeeScript nodes.
  class Node
    # Tabs are two spaces for pretty-printing.
    TAB = '  '

    # Tag this node as a statement, meaning that it can't be used directly as
    # the result of an expression.
    def self.statement
      class_eval "def statement?; true; end"
    end

    # Tag this node as having a custom return, meaning that instead of returning
    # it from the outside, you ask it to return itself, and it obliges.
    def self.custom_return
      class_eval "def custom_return?; true; end"
    end

    # Tag this node as having a custom assignment, meaning that instead of
    # assigning it to a variable name from the outside, you pass it the variable
    # name and let it take care of it.
    def self.custom_assign
      class_eval "def custom_assign?; true; end"
    end

    def write(code)
      puts "#{self.class.to_s}:\n#{code}\n\n" if ENV['VERBOSE']
      code
    end

    # Default implementations of the common node methods.
    def unwrap;                                 self;   end
    def line_ending;                            ';';    end
    def statement?;                             false;  end
    def custom_return?;                         false;  end
    def custom_assign?;                         false;  end
    def compile(indent='', scope=nil, opts={});         end
  end

  # A collection of nodes, each one representing an expression.
  class Expressions < Node
    statement
    attr_reader :expressions

    # Wrap up a node as an Expressions, unless it already is.
    def self.wrap(node)
      node.is_a?(Expressions) ? node : Expressions.new([node])
    end

    def initialize(nodes)
      @expressions = nodes
    end

    # Tack an expression onto the end of this node.
    def <<(node)
      @expressions << node
      self
    end

    # If this Expressions consists of a single node, pull it back out.
    def unwrap
      @expressions.length == 1 ? @expressions.first : self
    end

    # If this is the top-level Expressions, wrap everything in a safety closure.
    def root_compile
      "(function(){\n#{compile(TAB, Scope.new)}\n})();"
    end

    # The extra fancy is to handle pushing down returns and assignments
    # recursively to the final lines of inner statements.
    def compile(indent='', scope=nil, opts={})
      return root_compile unless scope
      code = @expressions.map { |n|
        if n == @expressions.last && (opts[:return] || opts[:assign])
          if opts[:return]
            if n.statement? || n.custom_return?
              "#{indent}#{n.compile(indent, scope, opts)}#{n.line_ending}"
            else
              "#{indent}return #{n.compile(indent, scope, opts)}#{n.line_ending}"
            end
          elsif opts[:assign]
            if n.statement? || n.custom_assign?
              "#{indent}#{n.compile(indent, scope, opts)}#{n.line_ending}"
            else
              "#{indent}#{AssignNode.new(ValueNode.new(LiteralNode.new(opts[:assign])), n).compile(indent, scope, opts)};"
            end
          end
        else
          "#{indent}#{n.compile(indent, scope)}#{n.line_ending}"
        end
      }.join("\n")
      write(code)
    end
  end

  # Literals are static values that have a Ruby representation, eg.: a string, a number,
  # true, false, nil, etc.
  class LiteralNode < Node
    STATEMENTS = ['break', 'continue']

    attr_reader :value

    def initialize(value)
      @value = value
    end

    def statement?
      STATEMENTS.include?(@value.to_s)
    end

    def line_ending
      @value.to_s[-1..-1] == ';' ? '' : ';'
    end

    def compile(indent, scope, opts={})
      code = @value.to_s
      write(code)
    end
  end

  # Try to return your expression, or tell it to return itself.
  class ReturnNode < Node
    statement
    custom_return

    attr_reader :expression

    def initialize(expression)
      @expression = expression
    end

    def line_ending
      @expression.custom_return? ? '' : ';'
    end

    def compile(indent, scope, opts={})
      return write(@expression.compile(indent, scope, opts.merge(:return => true))) if @expression.custom_return?
      compiled = @expression.compile(indent, scope)
      write(@expression.statement? ? "#{compiled}\n#{indent}return null" : "return #{compiled}")
    end
  end

  # Node for a function invocation. Takes care of converting super() calls into
  # calls against the prototype's function of the same name.
  class CallNode < Node
    LEADING_DOT = /\A\./

    attr_reader :variable, :arguments

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
      return write(compile_super(args, indent, scope, opts)) if super?
      prefix = @new ? "new " : ''
      write("#{prefix}#{@variable.compile(indent, scope)}(#{args})")
    end

    def compile_super(args, indent, scope, opts)
      methname = opts[:last_assign].sub(LEADING_DOT, '')
      "this.constructor.prototype.#{methname}.call(this, #{args})"
    end
  end

  class ExtendNode < Node

    attr_reader :subclass, :superclass

    def initialize(subclass, superclass)
      @subclass, @superclass = subclass, superclass
    end

    def compile(indent, scope, opts={})
      "#{@subclass}.prototype = #{@superclass.compile(indent, scope, opts)}"
    end

  end

  # A value, indexed or dotted into, or vanilla.
  class ValueNode < Node
    attr_reader :literal, :properties, :last

    def initialize(literal, properties=[])
      @literal, @properties = literal, properties
    end

    def <<(other)
      @properties << other
      self
    end

    def properties?
      return !@properties.empty?
    end

    def statement?
      @literal.is_a?(Node) && @literal.statement? && !properties?
    end

    def custom_assign?
      @literal.is_a?(Node) && @literal.custom_assign? && !properties?
    end

    def custom_return?
      @literal.is_a?(Node) && @literal.custom_return? && !properties?
    end

    def compile(indent, scope, opts={})
      parts = [@literal, @properties].flatten.map do |v|
        v.respond_to?(:compile) ? v.compile(indent, scope, opts) : v.to_s
      end
      @last = parts.last
      write(parts.join(''))
    end
  end

  # A dotted accessor into a part of a value.
  class AccessorNode < Node
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def compile(indent, scope, opts={})
      write(".#{@name}")
    end
  end

  # An indexed accessor into a part of an array or object.
  class IndexNode < Node
    attr_reader :index

    def initialize(index)
      @index = index
    end

    def compile(indent, scope, opts={})
      write("[#{@index.compile(indent, scope)}]")
    end
  end

  # An array slice literal. Unlike JavaScript's Array#slice, the second parameter
  # specifies the index of the end of the slice (just like the first parameter)
  # is the index of the beginning.
  class SliceNode < Node
    attr_reader :from, :to

    def initialize(from, to)
      @from, @to = from, to
    end

    def compile(indent, scope, opts={})
      write(".slice(#{@from.compile(indent, scope, opts)}, #{@to.compile(indent, scope, opts)} + 1)")
    end
  end

  # Setting the value of a local variable, or the value of an object property.
  class AssignNode < Node
    LEADING_VAR = /\Avar\s+/

    statement
    custom_return

    attr_reader :variable, :value, :context

    def initialize(variable, value, context=nil)
      @variable, @value, @context = variable, value, context
    end

    def line_ending
      @value.custom_assign? ? '' : ';'
    end

    def compile(indent, scope, opts={})
      name      = @variable.respond_to?(:compile) ? @variable.compile(indent, scope) : @variable
      last      = @variable.respond_to?(:last) ? @variable.last.to_s : name.to_s
      opts      = opts.merge({:assign => name, :last_assign => last})
      return write("#{@variable}: #{@value.compile(indent, scope, opts)}") if @context == :object
      return write("#{name} = #{@value.compile(indent, scope, opts)}") if @variable.properties?
      defined   = scope.find(name)
      postfix   = !defined && opts[:return] ? ";\n#{indent}return #{name}" : ''
      def_part  = defined ? "" : "var #{name};\n#{indent}"
      return write(def_part + @value.compile(indent, scope, opts)) if @value.custom_assign?
      def_part  = defined ? name : "var #{name}"
      val_part  = @value.compile(indent, scope, opts).sub(LEADING_VAR, '')
      write("#{def_part} = #{val_part}#{postfix}")
    end
  end

  # Simple Arithmetic and logical operations. Performs some conversion from
  # CoffeeScript operations into their JavaScript equivalents.
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

    attr_reader :operator, :first, :second

    def initialize(operator, first, second=nil)
      @first, @second = first, second
      @operator = CONVERSIONS[operator] || operator
    end

    def unary?
      @second.nil?
    end

    def compile(indent, scope, opts={})
      return write(compile_conditional(indent, scope)) if CONDITIONALS.include?(@operator)
      return write(compile_unary(indent, scope)) if unary?
      write("#{@first.compile(indent, scope)} #{@operator} #{@second.compile(indent, scope)}")
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

  # A function definition. The only node that creates a new Scope.
  class CodeNode < Node
    attr_reader :params, :body

    def initialize(params, body)
      @params = params
      @body = body
    end

    def compile(indent, scope, opts={})
      scope = Scope.new(scope)
      @params.each {|id| scope.find(id.to_s) }
      opts[:return] = true
      opts.delete(:assign)
      code  = @body.compile(indent + TAB, scope, opts)
      write("function(#{@params.join(', ')}) {\n#{code}\n#{indent}}")
    end
  end

  # An object literal.
  class ObjectNode < Node
    attr_reader :properties

    def initialize(properties = [])
      @properties = properties
    end

    def compile(indent, scope, opts={})
      props = @properties.map {|p| indent + TAB + p.compile(indent + TAB, scope) }.join(",\n")
      write("{\n#{props}\n#{indent}}")
    end
  end

  # An array literal.
  class ArrayNode < Node
    attr_reader :objects

    def initialize(objects=[])
      @objects = objects
    end

    def compile(indent, scope, opts={})
      objects = @objects.map {|o| o.compile(indent, scope) }.join(', ')
      write("[#{objects}]")
    end
  end

  # A while loop, the only sort of low-level loop exposed by CoffeeScript. From
  # it, all other loops can be manufactured.
  class WhileNode < Node
    statement

    attr_reader :condition, :body

    def initialize(condition, body)
      @condition, @body = condition, body
    end

    def line_ending
      ''
    end

    def compile(indent, scope, opts={})
      write("while (#{@condition.compile(indent, scope, :no_paren => true)}) {\n#{@body.compile(indent + TAB, scope)}\n#{indent}}")
    end
  end

  # The replacement for the for loop is an array comprehension (that compiles)
  # into a for loop. Also acts as an expression, able to return the result
  # of the comprehenion. Unlike Python array comprehensions, it's able to pass
  # the current index of the loop as a second parameter.
  class ForNode < Node
    statement
    custom_return
    custom_assign

    attr_reader :body, :source, :name, :filter, :index

    def initialize(body, source, name, filter, index=nil)
      @body, @source, @name, @filter, @index = body, source, name, filter, index
    end

    def line_ending
      ''
    end

    def compile(indent, scope, opts={})
      name_found  = scope.find(@name)
      index_found = @index && scope.find(@index)
      svar        = scope.free_variable
      ivar        = scope.free_variable
      lvar        = scope.free_variable
      name_part   = name_found ? @name : "var #{@name}"
      index_name  = @index ? (index_found ? @index : "var #{@index}") : nil
      source_part = "var #{svar} = #{@source.compile(indent, scope)};"
      for_part    = "var #{ivar}=0, #{lvar}=#{svar}.length; #{ivar}<#{lvar}; #{ivar}++"
      var_part    = "\n#{indent + TAB}#{name_part} = #{svar}[#{ivar}];\n"
      index_part  = @index ? "#{indent + TAB}#{index_name} = #{ivar};\n" : ''

      set_result    = ''
      save_result   = ''
      return_result = ''
      body = @body
      suffix = ';'
      if opts[:return] || opts[:assign]
        rvar          = scope.free_variable
        set_result    = "var #{rvar} = [];\n#{indent}"
        save_result += "#{rvar}[#{ivar}] = "
        return_result = rvar
        return_result = "#{opts[:assign]} = #{return_result};" if opts[:assign]
        return_result = "return #{return_result};" if opts[:return]
        return_result = "\n#{indent}#{return_result}"
        if @filter
          body = CallNode.new(ValueNode.new(LiteralNode.new(rvar), [AccessorNode.new('push')]), [@body])
          body = IfNode.new(@filter, body, nil, :statement)
          save_result = ''
          suffix = ''
        end
      elsif @filter
        body = IfNode.new(@filter, @body)
      end

      body = body.compile(indent + TAB, scope)
      write("#{source_part}\n#{indent}#{set_result}for (#{for_part}) {#{var_part}#{index_part}#{indent + TAB}#{save_result}#{body}#{suffix}\n#{indent}}#{return_result}")
    end
  end

  # A try/catch/finally block.
  class TryNode < Node
    statement

    attr_reader :try, :error, :recovery, :finally

    def initialize(try, error, recovery, finally=nil)
      @try, @error, @recovery, @finally = try, error, recovery, finally
    end

    def line_ending
      ''
    end

    def compile(indent, scope, opts={})
      catch_part = @recovery &&  " catch (#{@error}) {\n#{@recovery.compile(indent + TAB, scope, opts)}\n#{indent}}"
      finally_part = @finally && " finally {\n#{@finally.compile(indent + TAB, scope, opts)}\n#{indent}}"
      write("try {\n#{@try.compile(indent + TAB, scope, opts)}\n#{indent}}#{catch_part}#{finally_part}")
    end
  end

  # Throw an exception.
  class ThrowNode < Node
    statement

    attr_reader :expression

    def initialize(expression)
      @expression = expression
    end

    def compile(indent, scope, opts={})
      write("throw #{@expression.compile(indent, scope)}")
    end
  end

  # An extra set of parenthesis, supplied by the script source.
  class ParentheticalNode < Node
    attr_reader :expressions

    def initialize(expressions)
      @expressions = expressions.unwrap
    end

    def statement?
      @expressions.statement?
    end

    def custom_assign?
      @expressions.custom_assign?
    end

    def custom_return?
      @expressions.custom_return?
    end

    def compile(indent, scope, opts={})
      compiled = @expressions.compile(indent, scope, opts)
      compiled = compiled[0...-1] if compiled[-1..-1] == ';'
      write(opts[:no_paren] || statement? ? compiled : "(#{compiled})")
    end
  end

  # If/else statements. Switch/cases get compiled into these. Acts as an
  # expression by pushing down requested returns to the expression bodies.
  # Single-expression IfNodes are compiled into ternary operators if possible,
  # because ternaries are first-class returnable assignable expressions.
  class IfNode < Node
    attr_reader :condition, :body, :else_body

    def initialize(condition, body, else_body=nil, tags={})
      @condition = condition
      @body      = body && body.unwrap
      @else_body = else_body && else_body.unwrap
      @tags      = tags
      @condition = OpNode.new("!", @condition) if @tags[:invert]
    end

    def <<(else_body)
      eb = else_body.unwrap
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

    # If the else_body is an IfNode itself, then we've got an if-else chain.
    def chain?
      @chain ||= @else_body && @else_body.is_a?(IfNode)
    end

    # The IfNode only compiles into a statement if either of the bodies needs
    # to be a statement.
    def statement?
      @is_statement ||= !!(@tags[:statement] || @body.statement? || (@else_body && @else_body.statement?))
    end

    def custom_return?
      statement?
    end

    def custom_assign?
      statement?
    end

    def line_ending
      statement? ? '' : ';'
    end

    def compile(indent, scope, opts={})
      write(opts[:statement] || statement? ? compile_statement(indent, scope, opts) : compile_ternary(indent, scope))
    end

    # Compile the IfNode as a regular if-else statement. Flattened chains
    # force sub-else bodies into statement form.
    def compile_statement(indent, scope, opts)
      if_part   = "if (#{@condition.compile(indent, scope, :no_paren => true)}) {\n#{Expressions.wrap(@body).compile(indent + TAB, scope, opts)}\n#{indent}}"
      return if_part unless @else_body
      else_part = chain? ?
        " else #{@else_body.compile(indent, scope, opts.merge(:statement => true))}" :
        " else {\n#{Expressions.wrap(@else_body).compile(indent + TAB, scope, opts)}\n#{indent}}"
      if_part + else_part
    end

    # Compile the IfNode into a ternary operator.
    def compile_ternary(indent, scope)
      if_part   = "#{@condition.compile(indent, scope)} ? #{@body.compile(indent, scope)}"
      else_part = @else_body ? "#{@else_body.compile(indent, scope)}" : 'null'
      "#{if_part} : #{else_part}"
    end
  end

end