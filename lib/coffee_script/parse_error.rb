module CoffeeScript

  class ParseError < Racc::ParseError

    def initialize(token_id, value, stack)
      @token_id, @value, @stack = token_id, value, stack
    end

    def message(source_file=nil)
      line      = @value.respond_to?(:line) ? @value.line : "END"
      line_part = source_file ? "#{source_file}:#{line}:" : "line #{line}:"
      id_part   = @token_id != @value.inspect ? ", unexpected #{@token_id.downcase}" : ""
      "#{line_part} syntax error for '#{@value.to_s}'#{id_part}"
    end
    alias_method :inspect, :message

  end

end