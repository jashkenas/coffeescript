module CoffeeScript

  # Racc will raise this Exception whenever a syntax error occurs. The main
  # benefit over the Racc::ParseError is that the CoffeeScript::ParseError is
  # line-number aware.
  class ParseError < Racc::ParseError

    def initialize(token_id, value, stack)
      @token_id, @value, @stack = token_id, value, stack
    end

    def message
      line      = @value.respond_to?(:line) ? @value.line : "END"
      line_part = "line #{line}:"
      id_part   = @token_id != @value.inspect ? ", unexpected #{@token_id.to_s.downcase}" : ""
      val_part  = ['INDENT', 'OUTDENT'].include?(@token_id) ? '' : " for '#{@value.to_s}'"
      "#{line_part} syntax error#{val_part}#{id_part}"
    end
    alias_method :inspect, :message

  end

end