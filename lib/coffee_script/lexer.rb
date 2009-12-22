module CoffeeScript

  # The lexer reads a stream of CoffeeScript and divvys it up into tagged
  # tokens. A minor bit of the ambiguity in the grammar has been avoided by
  # pushing some extra smarts into the Lexer.
  class Lexer

    # The list of keywords passed verbatim to the parser.
    KEYWORDS   = ["if", "else", "then", "unless",
                  "true", "false", "null",
                  "and", "or", "is", "aint", "not",
                  "new", "return",
                  "try", "catch", "finally", "throw",
                  "break", "continue",
                  "for", "in", "while",
                  "switch", "case",
                  "super",
                  "delete"]

    # Token matching regexes.
    IDENTIFIER = /\A([a-zA-Z$_]\w*)/
    NUMBER     = /\A\b((0(x|X)[0-9a-fA-F]+)|([0-9]+(\.[0-9]+)?(e[+\-]?[0-9]+)?))\b/i
    STRING     = /\A(""|''|"(.*?)[^\\]"|'(.*?)[^\\]')/m
    JS         = /\A(`(.*?)`)/
    OPERATOR   = /\A([+\*&|\/\-%=<>]+)/
    WHITESPACE = /\A([ \t\r]+)/
    NEWLINE    = /\A(\n+)/
    COMMENT    = /\A((#[^\n]*\s*)+)/m
    CODE       = /\A(=>)/
    REGEX      = /\A(\/(.*?)[^\\]\/[imgy]{0,4})/

    # Token cleaning regexes.
    JS_CLEANER = /(\A`|`\Z)/
    MULTILINER = /\n/
    COMMENT_CLEANER = /(^\s*#|\n\s*$)/

    # Tokens that always constitute the start of an expression.
    EXP_START  = ['{', '(', '[']

    # Tokens that always constitute the end of an expression.
    EXP_END    = ['}', ')', ']']

    # Scan by attempting to match tokens one character at a time. Slow and steady.
    def tokenize(code)
      @code = code.chomp  # Cleanup code by remove extra line breaks
      @i = 0              # Current character position we're parsing
      @line = 1           # The current line.
      @tokens = []        # Collection of all parsed tokens in the form [:TOKEN_TYPE, value]
      while @i < @code.length
        @chunk = @code[@i..-1]
        extract_next_token
      end
      @tokens
    end

    # At every position, run this list of match attempts, short-circuiting if
    # any of them succeed.
    def extract_next_token
      return if identifier_token
      return if number_token
      return if string_token
      return if js_token
      return if regex_token
      return if comment_token
      return if whitespace_token
      return    literal_token
    end

    # Matches identifying literals: variables, keywords, method names, etc.
    def identifier_token
      return false unless identifier = @chunk[IDENTIFIER, 1]
      # Keywords are special identifiers tagged with their own name, 'if' will result
      # in an [:IF, "if"] token
      tag = KEYWORDS.include?(identifier) ? identifier.upcase.to_sym : :IDENTIFIER
      @tokens[-1][0] = :PROPERTY_ACCESS if tag == :IDENTIFIER && last_value == '.'
      token(tag, identifier)
      @i += identifier.length
    end

    # Matches numbers, including decimals, hex, and exponential notation.
    def number_token
      return false unless number = @chunk[NUMBER, 1]
      token(:NUMBER, number)
      @i += number.length
    end

    # Matches strings, including multi-line strings.
    def string_token
      return false unless string = @chunk[STRING, 1]
      escaped = string.gsub(MULTILINER) do |match|
        @line += 1
        "\\\n"
      end
      token(:STRING, escaped)
      @i += string.length
    end

    # Matches interpolated JavaScript.
    def js_token
      return false unless script = @chunk[JS, 1]
      token(:JS, script.gsub(JS_CLEANER, ''))
      @i += script.length
    end

    # Matches regular expression literals.
    def regex_token
      return false unless regex = @chunk[REGEX, 1]
      token(:REGEX, regex)
      @i += regex.length
    end

    # Matches and consumes comments.
    def comment_token
      return false unless comment = @chunk[COMMENT, 1]
      token(:COMMENT, comment.gsub(COMMENT_CLEANER, '').split(MULTILINER))
      token("\n", "\n")
      @i += comment.length
    end

    # Matches and consumes non-meaningful whitespace.
    def whitespace_token
      return false unless whitespace = @chunk[WHITESPACE, 1]
      @i += whitespace.length
    end

    # We treat all other single characters as a token. Eg.: ( ) , . !
    # Multi-character operators are also literal tokens, so that Racc can assign
    # the proper order of operations. Multiple newlines get merged together.
    def literal_token
      value = @chunk[NEWLINE, 1]
      if value
        @line += value.length
        token("\n", "\n") unless last_value == "\n"
        return @i += value.length
      end
      value = @chunk[OPERATOR, 1]
      tag_parameters if value && value.match(CODE)
      value ||= @chunk[0,1]
      skip_following_newlines if EXP_START.include?(value)
      remove_leading_newlines if EXP_END.include?(value)
      token(value, value)
      @i += value.length
    end

    # Add a token to the results, taking note of the line number, and
    # immediately-preceding comment.
    def token(tag, value)
      @tokens << [tag, Value.new(value, @line)]
    end

    # Peek at the previous token.
    def last_value
      @tokens.last && @tokens.last[1]
    end

    # A source of ambiguity in our grammar was parameter lists in function
    # definitions (as opposed to argument lists in function calls). Tag
    # parameter identifiers in order to avoid this.
    def tag_parameters
      index = 0
      loop do
        tok = @tokens[index -= 1]
        return if !tok
        next if tok[0] == ','
        return if tok[0] != :IDENTIFIER
        tok[0] = :PARAM
      end
    end

    # Consume and ignore newlines immediately after this point.
    def skip_following_newlines
      newlines = @code[(@i+1)..-1][NEWLINE, 1]
      if newlines
        @line += newlines.length
        @i += newlines.length
      end
    end

    # Discard newlines immediately before this point.
    def remove_leading_newlines
      @tokens.pop if last_value == "\n"
    end

  end

end