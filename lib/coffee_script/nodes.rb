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

    # Tag this node as a statement that cannot be transformed into an expression.
    # (break, continue, etc.) It doesn't make sense to try to transform it.
    def self.statement_only
      statement
      class_eval "def statement_only?; true; end"
    end

    def write(code)
      puts "#{self.class.to_s}:\n#{@options.inspect}\n#{code}\n\n" if ENV['VERBOSE']
      code
    end

    # This is extremely important -- we convert JS statements into expressions
    # by wrapping them in a closure, only if it's possible, and we're not at
    # the top level of a block (which would be unnecessary), and we haven't
    # already been asked to return the result.
    def compile(o={})
      @options = o.dup
      top = @options.delete(:top)
      closure = statement? && !statement_only? && !top && !@options[:return]
      closure ? compile_closure(@options) : compile_node(@options)
    end

    def compile_closure(o={})
      indent = o[:indent]
      o[:indent] += TAB
      "(function() {\n#{compile_node(o.merge(:return => true))}\n#{indent}})()"
    end

    # Default implementations of the common node methods.
    def unwrap;           self;   end
    def statement?;       false;  end
    def statement_only?;  false;  end
  end

  # A collection of nodes, each one representing an expression.
  class Expressions < Node
    statement
    attr_reader :expressions

    STRIP_TRAILING_WHITESPACE = /\s+$/

    # Wrap up a node as an Expressions, unless it already is.
    def self.wrap(*nodes)
      return nodes[0] if nodes.length == 1 && nodes[0].is_a?(Expressions)
      Expressions.new(*nodes)
    end

    def initialize(*nodes)
      @expressions = nodes.flatten
    end

    # Tack an expression onto the end of this node.
    def <<(node)
      @expressions << node
      self
    end

    def unshift(node)
      @expressions.unshift(node)
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

    def compile(o={})
      o[:scope] ? super(o) : compile_root(o)
    end

    # The extra fancy is to handle pushing down returns to the final lines of
    # inner statements. Variables first defined within the Expressions body
    # have their declarations pushed up top of the closest scope.
    def compile_node(options={})
      compiled = @expressions.map do |node|
        o = options.dup
        returns = o.delete(:return)
        code = node.compile(o)
        if last?(node) && returns && !node.statement_only?
          if node.statement?
            node.compile(o.merge(:return => true))
          else
            "#{o[:indent]}return #{node.compile(o)};"
          end
        else
          ending = node.statement? ? '' : ';'
          indent = node.statement? ? '' : o[:indent]
          "#{indent}#{node.compile(o.merge(:top => true))}#{ending}"
        end
      end
      write(compiled.join("\n"))
    end

    # If this is the top-level Expressions, wrap everything in a safety closure.
    def compile_root(o={})
      indent = o[:no_wrap] ? '' : TAB
      o.merge!(:indent => indent, :scope => Scope.new(nil, self))
      code = o[:no_wrap] ? compile_node(o) : compile_with_declarations(o)
      code.gsub!(STRIP_TRAILING_WHITESPACE, '')
      o[:no_wrap] ? code : "(function(){\n#{code}\n})();"
    end

    def compile_with_declarations(o={})
      decls = ''
      decls = "#{o[:indent]}var #{o[:scope].declared_variables.join(', ')};\n" if o[:scope].declarations?(self)
      code  = decls + compile_node(o)
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
    alias_method :statement_only?, :statement?

    def compile_node(o)
      indent = statement? ? o[:indent] : ''
      ending = statement? ? ';' : ''
      write(indent + @value.to_s + ending)
    end
  end

  # Try to return your expression, or tell it to return itself.
  class ReturnNode < Node
    statement_only

    attr_reader :expression

    def initialize(expression)
      @expression = expression
    end

    def compile_node(o)
      return write(@expression.compile(o.merge(:return => true))) if @expression.statement?
      compiled = @expression.compile(o)
      write(@expression.statement? ? "#{compiled}\n#{o[:indent]}return null;" : "#{o[:indent]}return #{compiled};")
    end
  end

  # Pass through CoffeeScript comments into JavaScript comments at the
  # same position.
  class CommentNode < Node
    statement_only

    def initialize(lines)
      @lines = lines.value
    end

    def compile_node(o={})
      delimiter = "\n#{o[:indent]}//"
      comment   = "#{delimiter}#{@lines.join(delimiter)}"
      write(comment)
    end

  end

  # Node for a function invocation. Takes care of converting super() calls into
  # calls against the prototype's function of the same name.
  class CallNode < Node
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

    def prefix
      @new ? "new " : ''
    end

    def splat?
      @arguments.any? {|a| a.is_a?(ArgSplatNode) }
    end

    def <<(argument)
      @arguments << argument
    end

    def compile_node(o)
      return write(compile_splat(o)) if splat?
      args = @arguments.map{|a| a.compile(o) }.join(', ')
      return write(compile_super(args, o)) if super?
      write("#{prefix}#{@variable.compile(o)}(#{args})")
    end

    def compile_super(args, o)
      methname = o[:last_assign]
      arg_part = args.empty? ? '' : ", #{args}"
      "#{o[:proto_assign]}.__superClass__.#{methname}.call(this#{arg_part})"
    end

    def compile_splat(o)
      meth = @variable.compile(o)
      obj  = @variable.source || 'this'
      args = @arguments.map do |arg|
        code = arg.compile(o)
        code = arg.is_a?(ArgSplatNode) ? code : "[#{code}]"
        arg.equal?(@arguments.first) ? code : ".concat(#{code})"
      end
      "#{prefix}#{meth}.apply(#{obj}, #{args.join('')})"
    end
  end

  # Node to extend an object's prototype with an ancestor object.
  # After goog.inherits from the Closure Library.
  class ExtendsNode < Node
    statement
    attr_reader :sub_object, :super_object

    def initialize(sub_object, super_object)
      @sub_object, @super_object = sub_object, super_object
    end

    def compile_node(o={})
      sub, sup = @sub_object.compile(o), @super_object.compile(o)
      "#{o[:indent]}#{sub}.__superClass__ = #{sup}.prototype;\n#{o[:indent]}" +
      "#{sub}.prototype = new #{sup}();\n#{o[:indent]}" +
      "#{sub}.prototype.constructor = #{sub};"
    end

  end

  # A value, indexed or dotted into, or vanilla.
  class ValueNode < Node
    attr_reader :literal, :properties, :last, :source

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

    def compile_node(o)
      only  = o.delete(:only_first)
      props = only ? @properties[0...-1] : @properties
      parts = [@literal, props].flatten.map do |val|
        val.respond_to?(:compile) ? val.compile(o) : val.to_s
      end
      @last = parts.last
      @source = parts.length > 1 ? parts[0...-1].join('') : nil
      write(parts.join(''))
    end
  end

  # A dotted accessor into a part of a value.
  class AccessorNode < Node
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def compile_node(o)
      write(".#{@name}")
    end
  end

  # An indexed accessor into a part of an array or object.
  class IndexNode < Node
    attr_reader :index

    def initialize(index)
      @index = index
    end

    def compile_node(o)
      write("[#{@index.compile(o)}]")
    end
  end

  # A range literal. Ranges can be used to extract portions (slices) of arrays,
  # or to specify a range for array comprehensions.
  class RangeNode < Node
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

    def compile_variables(o)
      idt = o[:indent]
      @from_var, @to_var = o[:scope].free_variable, o[:scope].free_variable
      from_val,  to_val  = @from.compile(o), @to.compile(o)
      write("#{idt}#{@from_var} = #{from_val};\n#{idt}#{@to_var} = #{to_val};\n#{idt}")
    end

    def compile_node(o)
      idx, step = o.delete(:index), o.delete(:step)
      raise SyntaxError, "unexpected range literal" unless idx
      vars     = "#{idx}=#{@from_var}"
      step     = step ? step.compile(o) : '1'
      compare  = "(#{@from_var} <= #{@to_var} ? #{idx} #{less_operator} #{@to_var} : #{idx} #{greater_operator} #{@to_var})"
      incr     = "(#{@from_var} <= #{@to_var} ? #{idx} += #{step} : #{idx} -= #{step})"
      write("#{vars}; #{compare}; #{incr}")
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

    def compile_node(o)
      from      = @range.from.compile(o)
      to        = @range.to.compile(o)
      plus_part = @range.exclusive? ? '' : ' + 1'
      write(".slice(#{from}, #{to}#{plus_part})")
    end
  end

  # Setting the value of a local variable, or the value of an object property.
  class AssignNode < Node
    PROTO_ASSIGN = /\A(\S+)\.prototype/
    LEADING_DOT = /\A\./

    attr_reader :variable, :value, :context

    def initialize(variable, value, context=nil)
      @variable, @value, @context = variable, value, context
    end

    def compile_node(o)
      return compile_splice(o) if @variable.properties.last.is_a?(SliceNode)
      name      = @variable.compile(o)
      last      = @variable.last.to_s.sub(LEADING_DOT, '')
      proto     = name[PROTO_ASSIGN, 1]
      o         = o.merge(:last_assign => last, :proto_assign => proto)
      o[:immediate_assign] = last if @value.is_a?(CodeNode) && last.match(Lexer::IDENTIFIER)
      return write("#{name}: #{@value.compile(o)}") if @context == :object
      o[:scope].find(name) unless @variable.properties?
      val = "#{name} = #{@value.compile(o)}"
      write(o[:return] ? "#{o[:indent]}return (#{val})" : val)
    end

    def compile_splice(o)
      var   = @variable.compile(o.merge(:only_first => true))
      range = @variable.properties.last.range
      plus  = range.exclusive? ? '' : ' + 1'
      from  = range.from.compile(o)
      to    = "#{range.to.compile(o)} - #{from}#{plus}"
      write("#{var}.splice.apply(#{var}, [#{from}, #{to}].concat(#{@value.compile(o)}))")
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

    def compile_node(o)
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

    def compile_node(o)
      shared_scope = o.delete(:shared_scope)
      indent       = o[:indent]
      o[:scope]    = shared_scope || Scope.new(o[:scope], @body)
      o[:return]   = true
      o[:top]      = true
      o[:indent]  += TAB
      o.delete(:no_wrap)
      name = o.delete(:immediate_assign)
      if @params.last.is_a?(ParamSplatNode)
        splat = @params.pop
        splat.index = @params.length
        @body.unshift(splat)
      end
      @params.each {|id| o[:scope].parameter(id.to_s) }
      code = @body.compile_with_declarations(o)
      name_part = name ? " #{name}" : ''
      write("function#{name_part}(#{@params.join(', ')}) {\n#{code}\n#{indent}}")
    end
  end

  # A parameter splat in a function definition.
  class ParamSplatNode < Node
    attr_accessor :index
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def compile_node(o={})
      o[:scope].find(@name)
      write("#{@name} = Array.prototype.slice.call(arguments, #{@index})")
    end
  end

  class ArgSplatNode < Node
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def compile_node(o={})
      write(@value.compile(o))
    end

  end

  # An object literal.
  class ObjectNode < Node
    attr_reader :properties

    def initialize(properties = [])
      @properties = properties
    end

    # All the mucking about with commas is to make sure that CommentNodes and
    # AssignNodes get interleaved correctly, with no trailing commas or
    # commas affixed to comments. TODO: Extract this and add it to ArrayNode.
    def compile_node(o)
      indent = o[:indent]
      o[:indent] += TAB
      joins = Hash.new("\n")
      non_comments = @properties.select {|p| !p.is_a?(CommentNode) }
      non_comments.each {|p| joins[p] = p == non_comments.last ? "\n" : ",\n" }
      props = @properties.map { |prop|
        join = joins[prop]
        join = '' if prop == @properties.last
        o[:indent] + prop.compile(o) + join
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

    def compile_node(o)
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

    def compile_node(o)
      o.delete(:return)
      indent      = o[:indent]
      o[:indent] += TAB
      o[:top]     = true
      cond        = @condition.compile(o)
      write("#{indent}while (#{cond}) {\n#{@body.compile(o)}\n#{indent}}")
    end
  end

  # The replacement for the for loop is an array comprehension (that compiles)
  # into a for loop. Also acts as an expression, able to return the result
  # of the comprehenion. Unlike Python array comprehensions, it's able to pass
  # the current index of the loop as a second parameter.
  class ForNode < Node
    statement

    attr_reader :body, :source, :name, :index, :filter, :step

    def initialize(body, source, name, index=nil)
      @body, @name, @index = body, name, index
      @source = source[:source]
      @filter = source[:filter]
      @step   = source[:step]
    end

    def compile_node(o)
      range         = @source.is_a?(RangeNode)
      scope         = o[:scope]
      name_found    = scope.find(@name)
      index_found   = @index && scope.find(@index)
      svar          = scope.free_variable
      ivar          = range ? name : @index ? @index : scope.free_variable
      rvar          = scope.free_variable
      tvar          = scope.free_variable
      if range
        body_dent   = o[:indent] + TAB
        var_part, pre_cond, post_cond = '', '', ''
        index_var   = scope.free_variable
        source_part = @source.compile_variables(o)
        for_part    = "#{index_var}=0, #{@source.compile(o.merge(:index => ivar, :step => @step))}, #{index_var}++"
      else
        index_var   = nil
        body_dent   = o[:indent] + TAB + TAB
        source_part = "#{o[:indent]}#{svar} = #{@source.compile(o)};\n#{o[:indent]}"
        for_part    = "#{ivar} in #{svar}"
        pre_cond    = "\n#{o[:indent] + TAB}if (#{svar}.hasOwnProperty(#{ivar})) {"
        var_part    = "\n#{body_dent}#{@name} = #{svar}[#{ivar}];"
        post_cond   = "\n#{o[:indent] + TAB}}"
      end
      body          = @body
      set_result    = "#{rvar} = [];\n#{o[:indent]}"
      return_result = rvar
      temp_var      = ValueNode.new(LiteralNode.new(tvar))
      body = Expressions.wrap(
        AssignNode.new(temp_var, @body.unwrap),
        CallNode.new(ValueNode.new(LiteralNode.new(rvar), [AccessorNode.new('push')]), [temp_var])
      )
      if o[:return]
        return_result = "return #{return_result}" if o[:return]
        o.delete(:return)
        body = IfNode.new(@filter, body, nil, :statement => true) if @filter
      elsif @filter
        body = Expressions.wrap(IfNode.new(@filter, @body))
      end

      return_result = "\n#{o[:indent]}#{return_result};"
      body = body.compile(o.merge(:indent => body_dent, :top => true))
      write("#{source_part}#{set_result}for (#{for_part}) {#{pre_cond}#{var_part}\n#{body}#{post_cond}\n#{o[:indent]}}#{return_result}")
    end
  end

  # A try/catch/finally block.
  class TryNode < Node
    statement

    attr_reader :try, :error, :recovery, :finally

    def initialize(try, error, recovery, finally=nil)
      @try, @error, @recovery, @finally = try, error, recovery, finally
    end

    def compile_node(o)
      indent = o[:indent]
      o[:indent] += TAB
      o[:top] = true
      error_part = @error ? " (#{@error}) " : ' '
      catch_part = @recovery &&  " catch#{error_part}{\n#{@recovery.compile(o)}\n#{indent}}"
      finally_part = @finally && " finally {\n#{@finally.compile(o.merge(:return => nil))}\n#{indent}}"
      write("#{indent}try {\n#{@try.compile(o)}\n#{indent}}#{catch_part}#{finally_part}")
    end
  end

  # Throw an exception.
  class ThrowNode < Node
    statement_only

    attr_reader :expression

    def initialize(expression)
      @expression = expression
    end

    def compile_node(o)
      write("#{o[:indent]}throw #{@expression.compile(o)};")
    end
  end

  # Check an expression for existence (meaning not null or undefined).
  class ExistenceNode < Node
    attr_reader :expression

    def initialize(expression)
      @expression = expression
    end

    def compile_node(o)
      val = @expression.compile(o)
      write("(typeof #{val} !== 'undefined' && #{val} !== null)")
    end
  end

  # An extra set of parentheses, supplied by the script source.
  # You can't wrap parentheses around bits that get compiled into JS statements,
  # unfortunately.
  class ParentheticalNode < Node
    attr_reader :expressions

    def initialize(expressions, line=nil)
      @expressions = expressions.unwrap
      @line = line
    end

    def compile_node(o)
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

    def compile_node(o)
      write(statement? ? compile_statement(o) : compile_ternary(o))
    end

    # Compile the IfNode as a regular if-else statement. Flattened chains
    # force sub-else bodies into statement form.
    def compile_statement(o)
      indent = o[:indent]
      child  = o.delete(:chain_child)
      cond_o = o.dup
      cond_o.delete(:return)
      o[:indent] += TAB
      o[:top] = true
      if_dent = child ? '' : indent
      if_part = "#{if_dent}if (#{@condition.compile(cond_o)}) {\n#{Expressions.wrap(@body).compile(o)}\n#{indent}}"
      return if_part unless @else_body
      else_part = chain? ?
        " else #{@else_body.compile(o.merge(:indent => indent, :chain_child => true))}" :
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