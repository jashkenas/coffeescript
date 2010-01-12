module CoffeeScript

  # Racc will raise this Exception whenever a syntax error occurs. The main
  # benefit over the Racc::ParseError is that the CoffeeScript::ParseError is
  # line-number aware.
  class ParseError < Racc::ParseError

    TOKEN_MAP = {
      'INDENT'  => 'indent',
      'OUTDENT' => 'outdent',
      "\n"      => 'newline'
    }

    def initialize(token_id, value, stack)
      @token_id, @value, @stack = token_id, value, stack
    end

    def message
      line      = @value.respond_to?(:line) ? @value.line : "END"
      line_part = "line #{line}:"
      id_part   = @token_id != @value.inspect ? ", unexpected #{@token_id.to_s.downcase}" : ""
      val_part  = " for #{TOKEN_MAP[@value.to_s] || "'#{@value}'"}"
      "#{line_part} syntax error#{val_part}#{id_part}"
    end
    alias_method :inspect, :message

  end

end