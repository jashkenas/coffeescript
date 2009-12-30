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
      puts "#{self.class.to_s}:\n#{@options.inspect}\n#{code}\n\n" if ENV['VERBOSE']
      code
    end

    def compile(o={})
      @options = o.dup
    end

    # Default implementations of the common node methods.
    def unwrap;                                 self;   end
    def line_ending;                            ';';    end
    def statement?;                             false;  end
    def custom_return?;                         false;  end
    def custom_assign?;                         false;  end
  end

  # A collection of nodes, each one representing an expression.
  class Expressions < Node
    statement
    attr_reader :expressions

    STRIP_TRAILING_WHITESPACE = /\s+$/

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

    # Is the node last in this block of expressions.
    def last?(node)
      @last_index ||= @expressions.last.is_a?(CommentNode) ? -2 : -1
      node == @expressions[@last_index]
    end

    # If this is the top-level Expressions, wrap everything in a safety closure.
    def root_compile(o={})
      indent = o[:no_wrap] ? '' : TAB
      code = compile(o.merge(:indent => indent, :scope => Scope.new), o[:no_wrap] ? nil : :code)
      code.gsub!(STRIP_TRAILING_WHITESPACE, '')
      o[:no_wrap] ? code : "(function(){\n#{code}\n})();"
    end

    # The extra fancy is to handle pushing down returns and assignments
    # recursively to the final lines of inner statements.
    # Variables first defined within the Expressions body have their
    # declarations pushed up to the top scope.
    def compile(options={}, parent=nil)
      return root_compile(options) unless options[:scope]
      compiled = @expressions.map do |node|
        o = super(options)
        if last?(node) && (o[:return] || o[:assign])
          if o[:return]
            if node.statement? || node.custom_return?
              "#{o[:indent]}#{node.compile(o)}#{node.line_ending}"
            else
              o.delete(:return)
              "#{o[:indent]}return #{node.compile(o)}#{node.line_ending}"
            end
          elsif o[:assign]
            if node.statement? || node.custom_assign?
              "#{o[:indent]}#{node.compile(o)}#{node.line_ending}"
            else
              "#{o[:indent]}#{AssignNode.new(o[:assign], node).compile(o)};"
            end
          end
        else
          o.delete(:return) and o.delete(:assign)
          "#{o[:indent]}#{node.compile(o)}#{node.line_ending}"
        end
      end
      scope = options[:scope]
      declarations = scope.any_declared? && parent == :code ? "#{options[:indent]}var #{scope.declared_variables.join(', ')};\n" : ''
      code = declarations + compiled.join("\n")
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

    def compile(o={})
      o = super(o)
      write(@value.to_s)
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

    def compile(o={})
      o = super(o)
      return write(@expression.compile(o.merge(:return => true))) if @expression.custom_return?
      compiled = @expression.compile(o)
      write(@expression.statement? ? "#{compiled}\n#{indent}return null" : "return #{compiled}")
    end
  end

  # Pass through CoffeeScript comments into JavaScript comments at the
  # same position.
  class CommentNode < Node
    statement

    def initialize(lines)
      @lines = lines.value
    end

    def line_ending
      ''
    end

    def compile(o={})
      delimiter = "\n#{o[:indent]}//"
      comment   = "#{delimiter}#{@lines.join(delimiter)}"
      write(comment)
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

    def compile(o={})
      o = super(o)
      args = @arguments.map{|a| a.compile(o) }.join(', ')
      return write(compile_super(args, o)) if super?
      prefix = @new ? "new " : ''
      write("#{prefix}#{@variable.compile(o)}(#{args})")
    end

    def compile_super(args, o)
      methname = o[:last_assign].sub(LEADING_DOT, '')
      arg_part = args.empty? ? '' : ", #{args}"
      "#{o[:proto_assign]}.__superClass__.#{methname}.call(this#{arg_part})"
    end
  end

  # Node to extend an object's prototype with an ancestor object.
  # After goog.inherits from the Closure Library.
  class ExtendsNode < Node
    attr_reader :sub_object, :super_object

    def initialize(sub_object, super_object)
      @sub_object, @super_object = sub_object, super_object
    end

    def compile(o={})
      sub, sup = @sub_object.compile(o), @super_object.compile(o)
      "#{sub}.__superClass__ = #{sup}.prototype;\n#{o[:indent]}" +
      "#{sub}.prototype = new #{sup}();\n#{o[:indent]}" +
      "#{sub}.prototype.constructor = #{sub}"
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

    def compile(o={})
      o = super(o)
      parts = [@literal, @properties].flatten.map do |val|
        val.respond_to?(:compile) ? val.compile(o) : val.to_s
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

    def compile(o={})
      o = super(o)
      write(".#{@name}")
    end
  end

  # An indexed accessor into a part of an array or object.
  class IndexNode < Node
    attr_reader :index

    def initialize(index)
      @index = index
    end

    def compile(o={})
      o = super(o)
      write("[#{@index.compile(o)}]")
    end
  end

  # A range literal. Ranges can be used to extract portions (slices) of arrays,
  # or to specify a range for array comprehensions.
  class RangeNode
    attr_reader :from, :to

    def initialize(from, to, exclusive=false)
      @from, @to, @exclusive = from, to, exclusive
    end

    def exclusive?
      @exclusive
    end

    def less_operator
      @exclusive ? '<' : '<='
    end

    def greater_operator
      @exclusive ? '>' : '>='
    end

    def compile(o, fv, tv)
      fvv, tvv = @from.compile(o), @to.compile(o)
      vars     = "#{fv}=#{fvv}, #{tv}=#{tvv}"
      compare  = "(#{fvv} <= #{tvv} ? #{fv} #{less_operator} #{tv} : #{fv} #{greater_operator} #{tv})"
      incr     = "(#{fvv} <= #{tvv} ? #{fv} += 1 : #{fv} -= 1)"
      "#{vars}; #{compare}; #{incr}"
    end

  end

  # An array slice literal. Unlike JavaScript's Array#slice, the second parameter
  # specifies the index of the end of the slice (just like the first parameter)
  # is the index of the beginning.
  class SliceNode < Node
    attr_reader :range

    def initialize(range)
      @range = range
    end

    def compile(o={})
      o         = super(o)
      from      = @range.from.compile(o)
      to        = @range.to.compile(o)
      plus_part = @range.exclusive? ? '' : ' + 1'
      write(".slice(#{from}, #{to}#{plus_part})")
    end
  end

  # Setting the value of a local variable, or the value of an object property.
  class AssignNode < Node
    PROTO_ASSIGN = /\A(\S+)\.prototype/

    custom_return

    attr_reader :variable, :value, :context

    def initialize(variable, value, context=nil)
      @variable, @value, @context = variable, value, context
    end

    def line_ending
      @value.custom_assign? ? '' : ';'
    end

    def compile(o={})
      o = super(o)
      name      = @variable.compile(o)
      last      = @variable.last.to_s
      proto     = name[PROTO_ASSIGN, 1]
      o         = o.merge(:assign => @variable, :last_assign => last, :proto_assign => proto)
      return write("#{name}: #{@value.compile(o)}") if @context == :object
      o[:scope].find(name) unless @variable.properties?
      return write(@value.compile(o)) if @value.custom_assign?
      val = "#{name} = #{@value.compile(o)}"
      write(o[:return] && !@value.custom_return? ? "return (#{val})" : val)
    end
  end

  # Simple Arithmetic and logical operations. Performs some conversion from
  # CoffeeScript operations into their JavaScript equivalents.
  class OpNode < Node
    CONVERSIONS = {
      :==     => "===",
      :'!='   => "!==",
      :and    => '&&',
      :or     => '||',
      :is     => '===',
      :isnt   => "!==",
      :not    => '!'
    }
    CONDITIONALS     = [:'||=', :'&&=']
    PREFIX_OPERATORS = [:typeof, :delete]

    attr_reader :operator, :first, :second

    def initialize(operator, first, second=nil, flip=false)
      @first, @second, @flip = first, second, flip
      @operator = CONVERSIONS[operator.to_sym] || operator
    end

    def unary?
      @second.nil?
    end

    def compile(o={})
      o = super(o)
      return write(compile_conditional(o)) if CONDITIONALS.include?(@operator.to_sym)
      return write(compile_unary(o)) if unary?
      write("#{@first.compile(o)} #{@operator} #{@second.compile(o)}")
    end

    def compile_conditional(o)
      first, second = @first.compile(o), @second.compile(o)
      sym = @operator[0..1]
      "#{first} = #{first} #{sym} #{second}"
    end

    def compile_unary(o)
      space = PREFIX_OPERATORS.include?(@operator.to_sym) ? ' ' : ''
      parts = [@operator.to_s, space, @first.compile(o)]
      parts.reverse! if @flip
      parts.join('')
    end
  end

  # A function definition. The only node that creates a new Scope.
  class CodeNode < Node
    attr_reader :params, :body

    def initialize(params, body)
      @params = params
      @body = body
    end

    def compile(o={})
      o = super(o)
      o[:scope] = Scope.new(o[:scope])
      o[:return] = true
      indent = o[:indent]
      o[:indent] += TAB
      o.delete(:assign)
      o.delete(:no_wrap)
      @params.each {|id| o[:scope].parameter(id.to_s) }
      code = @body.compile(o, :code)
      write("function(#{@params.join(', ')}) {\n#{code}\n#{indent}}")
    end
  end

  # An object literal.
  class ObjectNode < Node
    attr_reader :properties

    def initialize(properties = [])
      @properties = properties
    end

    def compile(o={})
      o = super(o)
      indent = o[:indent]
      o[:indent] += TAB
      props = @properties.map { |prop|
        joiner = prop == @properties.last ? '' : prop.is_a?(CommentNode) ? "\n" : ",\n"
        o[:indent] + prop.compile(o) + joiner
      }.join('')
      write("{\n#{props}\n#{indent}}")
    end
  end

  # An array literal.
  class ArrayNode < Node
    attr_reader :objects

    def initialize(objects=[])
      @objects = objects
    end

    def compile(o={})
      o = super(o)
      objects = @objects.map { |obj|
        joiner = obj.is_a?(CommentNode) ? "\n#{o[:indent] + TAB}" : obj == @objects.last ? '' : ', '
        obj.compile(o.merge(:indent => o[:indent] + TAB)) + joiner
      }.join('')
      ending = objects.include?("\n") ? "\n#{o[:indent]}]" : ']'
      write("[#{objects}#{ending}")
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

    def compile(o={})
      o = super(o)
      o.delete(:return)
      indent = o[:indent] + TAB
      cond = @condition.compile(o)
      write("while (#{cond}) {\n#{@body.compile(o.merge(:indent => indent))}\n#{o[:indent]}}")
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

    def compile(o={})
      o = super(o)
      range         = @source.is_a?(RangeNode)
      scope         = o[:scope]
      name_found    = scope.find(@name)
      index_found   = @index && scope.find(@index)
      svar          = scope.free_variable
      ivar          = range ? name : scope.free_variable
      lvar          = scope.free_variable
      rvar          = scope.free_variable
      index_name    = @index ? @index : nil
      if range
        source_part = ''
        var_part    = ''
        index_part  = ''
        index_var   = scope.free_variable
        for_part    = "#{index_var}=0, #{@source.compile(o, ivar, lvar)}, #{index_var}++"
      else
        index_var   = nil
        source_part = "#{svar} = #{@source.compile(o)};\n#{o[:indent]}"
        for_part    = "#{ivar}=0, #{lvar}=#{svar}.length; #{ivar}<#{lvar}; #{ivar}++"
        var_part    = "\n#{o[:indent] + TAB}#{@name} = #{svar}[#{ivar}];"
        index_part  = @index ? "\n#{o[:indent] + TAB}#{index_name} = #{ivar};" : ''
      end
      body          = @body
      suffix        = ';'
      set_result    = "#{rvar} = [];\n#{o[:indent]}"
      save_result   = "#{rvar}[#{index_var || ivar}] = "
      return_result = rvar

      if o[:return] || o[:assign]
        return_result = "#{o[:assign].compile(o)} = #{return_result}" if o[:assign]
        return_result = "return #{return_result}" if o[:return]
        o.delete(:assign)
        o.delete(:return)
        if @filter
          body = CallNode.new(ValueNode.new(LiteralNode.new(rvar), [AccessorNode.new('push')]), [@body])
          body = IfNode.new(@filter, body, nil, :statement => true)
          save_result = ''
          suffix = ''
        end
      elsif @filter
        body = IfNode.new(@filter, @body)
      end

      return_result = "\n#{o[:indent]}#{return_result};"
      indent = o[:indent] + TAB
      body = body.compile(o.merge(:indent => indent))
      write("#{source_part}#{set_result}for (#{for_part}) {#{var_part}#{index_part}\n#{indent}#{save_result}#{body}#{suffix}\n#{o[:indent]}}#{return_result}")
    end
  end

  # A try/catch/finally block.
  class TryNode < Node
    statement
    custom_return
    custom_assign

    attr_reader :try, :error, :recovery, :finally

    def initialize(try, error, recovery, finally=nil)
      @try, @error, @recovery, @finally = try, error, recovery, finally
    end

    def line_ending
      ''
    end

    def compile(o={})
      o = super(o)
      indent = o[:indent]
      o[:indent] += TAB
      error_part = @error ? " (#{@error}) " : ' '
      catch_part = @recovery &&  " catch#{error_part}{\n#{@recovery.compile(o)}\n#{indent}}"
      finally_part = @finally && " finally {\n#{@finally.compile(o.merge(:assign => nil, :return => nil))}\n#{indent}}"
      write("try {\n#{@try.compile(o)}\n#{indent}}#{catch_part}#{finally_part}")
    end
  end

  # Throw an exception.
  class ThrowNode < Node
    statement

    attr_reader :expression

    def initialize(expression)
      @expression = expression
    end

    def compile(o={})
      o = super(o)
      write("throw #{@expression.compile(o)}")
    end
  end

  # An extra set of parentheses, supplied by the script source.
  # You can't wrap parentheses around bits that get compiled into JS statements,
  # unfortunately.
  class ParentheticalNode < Node
    attr_reader :expressions

    def initialize(expressions)
      @expressions = expressions.unwrap
    end

    def statement?
      @expressions.unwrap.statement?
    end

    def custom_assign?
      @expressions.custom_assign?
    end

    def custom_return?
      @expressions.custom_return?
    end

    def compile(o={})
      raise SyntaxError, "parentheses can't be wrapped around a statement" if statement?
      o = super(o)
      compiled = @expressions.compile(o)
      compiled = compiled[0...-1] if compiled[-1..-1] == ';'
      write("(#{compiled})")
    end
  end

  # If/else statements. Switch/whens get compiled into these. Acts as an
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
      @condition = OpNode.new("!", ParentheticalNode.new(@condition)) if @tags[:invert]
    end

    def <<(else_body)
      eb = else_body.unwrap
      @else_body ? @else_body << eb : @else_body = eb
      self
    end
    
    def force_statement
      @tags[:statement] = true
      self
    end

    # Rewrite a chain of IfNodes with their switch condition for equality.
    def rewrite_condition(expression)
      @condition = OpNode.new("is", expression, @condition)
      @else_body.rewrite_condition(expression) if chain?
      self
    end

    # Rewrite a chain of IfNodes to add a default case as the final else.
    def add_else(exprs)
      chain? ? @else_body.add_else(exprs) : @else_body = (exprs && exprs.unwrap)
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

    def compile(o={})
      o = super(o)
      write(statement? ? compile_statement(o) : compile_ternary(o))
    end

    # Compile the IfNode as a regular if-else statement. Flattened chains
    # force sub-else bodies into statement form.
    def compile_statement(o)
      indent = o[:indent]
      cond_o = o.dup
      cond_o.delete(:assign)
      cond_o.delete(:return)
      o[:indent] += TAB
      if_part   = "if (#{@condition.compile(cond_o)}) {\n#{Expressions.wrap(@body).compile(o)}\n#{indent}}"
      return if_part unless @else_body
      else_part = chain? ?
        " else #{@else_body.compile(o.merge(:indent => indent))}" :
        " else {\n#{Expressions.wrap(@else_body).compile(o)}\n#{indent}}"
      if_part + else_part
    end

    # Compile the IfNode into a ternary operator.
    def compile_ternary(o)
      if_part   = "#{@condition.compile(o)} ? #{@body.compile(o)}"
      else_part = @else_body ? "#{@else_body.compile(o)}" : 'null'
      "#{if_part} : #{else_part}"
    end
  end

end