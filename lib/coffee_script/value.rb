module CoffeeScript

  # Instead of producing raw Ruby objects, the Lexer produces values of this
  # class, wrapping native objects tagged with line number information.
  # Values masquerade as both strings and nodes -- being used both as nodes in
  # the AST, and as literally-interpolated values in the generated code.
  class Value
    attr_reader :value, :line

    def initialize(value, line=nil)
      @value, @line = value, line
    end

    def to_str
      @value.to_s
    end
    alias_method :to_s, :to_str

    def to_sym
      to_str.to_sym
    end

    def compile(o={})
      to_s
    end

    def inspect
      @value.inspect
    end

    def ==(other)
      @value == other
    end

    def [](index)
      @value[index]
    end

    def eql?(other)
      @value.eql?(other)
    end

    def hash
      @value.hash
    end

    def match(regex)
      @value.match(regex)
    end

    def children
      []
    end

    def statement_only?
      false
    end
  end

end