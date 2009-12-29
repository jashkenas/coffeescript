module CoffeeScript

  # The lexer reads a stream of CoffeeScript and divvys it up into tagged
  # tokens. A minor bit of the ambiguity in the grammar has been avoided by
  # pushing some extra smarts into the Lexer.
  class Lexer

    # The list of keywords passed verbatim to the parser.
    KEYWORDS   = ["if", "else", "then", "unless",
                  "true", "false", "yes", "no", "on", "off",
                  "and", "or", "is", "isnt", "not",
                  "new", "return",
                  "try", "catch", "finally", "throw",
                  "break", "continue",
                  "for", "in", "where", "while",
                  "switch", "when",
                  "super", "extends",
                  "delete", "instanceof", "typeof"]

    # Token matching regexes.
    IDENTIFIER = /\A([a-zA-Z$_]\w*)/
    NUMBER     = /\A((\b|-)((0(x|X)[0-9a-fA-F]+)|([0-9]+(\.[0-9]+)?(e[+\-]?[0-9]+)?)))\b/i
    STRING     = /\A(""|''|"(.*?)[^\\]"|'(.*?)[^\\]')/m
    JS         = /\A(``|`(.*?)[^\\]`)/m
    OPERATOR   = /\A([+\*&|\/\-%=<>:!]+)/
    WHITESPACE = /\A([ \t\r]+)/
    COMMENT    = /\A((#[^\n]*\s*)+)/m
    CODE       = /\A(=>)/
    REGEX      = /\A(\/(.*?)[^\\]\/[imgy]{0,4})/
    INDENT     = /\A\n([ \t\r]*)/
    NEWLINE    = /\A(\n+)([ \t\r]*)/

    # Token cleaning regexes.
    JS_CLEANER = /(\A`|`\Z)/
    MULTILINER = /\n/
    COMMENT_CLEANER = /(^\s*#|\n\s*$)/

    # Tokens that always constitute the start of an expression.
    EXP_START  = ['{', '(', '[']

    # Tokens that always constitute the end of an expression.
    EXP_END    = ['}', ')', ']']

    # Assignment tokens.
    ASSIGN     = [':', '=']

    # Tokens that must be balanced.
    BALANCED_PAIRS = [['(', ')'], ['[', ']'], ['{', '}'], [:INDENT, :OUTDENT]]

    # Scan by attempting to match tokens one character at a time. Slow and steady.
    def tokenize(code)
      @code = code.chomp  # Cleanup code by remove extra line breaks
      @i = 0              # Current character position we're parsing
      @line = 1           # The current line.
      @indent = 0         # The current indent level.
      @indents = []       # The stack of all indent levels we are currently within.
      @tokens = []        # Collection of all parsed tokens in the form [:TOKEN_TYPE, value]
      while @i < @code.length
        @chunk = @code[@i..-1]
        extract_next_token
      end
      close_indentation
      remove_empty_outdents
      ensure_balance(*BALANCED_PAIRS)
      rewrite_closing_parens
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
      return if indent_token
      return if whitespace_token
      return    literal_token
    end

    # Matches identifying literals: variables, keywords, method names, etc.
    def identifier_token
      return false unless identifier = @chunk[IDENTIFIER, 1]
      # Keywords are special identifiers tagged with their own name, 'if' will result
      # in an [:IF, "if"] token
      tag = KEYWORDS.include?(identifier) ? identifier.upcase.to_sym : :IDENTIFIER
      @tokens[-1][0] = :PROPERTY_ACCESS if tag == :IDENTIFIER && last_value == '.' && !(@tokens[-2][1] == '.')
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
        " \\\n"
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
      @line += comment.scan(MULTILINER).length
      token(:COMMENT, comment.gsub(COMMENT_CLEANER, '').split(MULTILINER))
      token("\n", "\n")
      @i += comment.length
    end

    # Record tokens for indentation differing from the previous line.
    def indent_token
      return false unless indent = @chunk[INDENT, 1]
      size = indent.size
      return newline_token(indent) if size == @indent
      if size > @indent
        token(:INDENT, size - @indent)
        @indents << size - @indent
        @indent = size
      else
        outdent_token(@indent - size)
      end
      @line += 1
      @i += (size + 1)
    end

    def outdent_token(move_out)
      while move_out > 0
        last_indent = @indents.pop
        token(:OUTDENT, last_indent)
        move_out -= last_indent
      end
      # token("\n", "\n")
      @indent = @indents.last || 0
    end

    # Matches and consumes non-meaningful whitespace.
    def whitespace_token
      return false unless whitespace = @chunk[WHITESPACE, 1]
      @i += whitespace.length
    end

    # Multiple newlines get merged together.
    # Use a trailing \ to escape newlines.
    def newline_token(newlines)
      return false unless newlines = @chunk[NEWLINE, 1]
      @line += newlines.length
      token("\n", "\n") unless ["\n", "\\"].include?(last_value)
      @tokens.pop if last_value == "\\"
      @i += newlines.length
    end

    # We treat all other single characters as a token. Eg.: ( ) , . !
    # Multi-character operators are also literal tokens, so that Racc can assign
    # the proper order of operations.
    def literal_token
      value = @chunk[OPERATOR, 1]
      tag_parameters if value && value.match(CODE)
      value ||= @chunk[0,1]
      skip_following_newlines if EXP_START.include?(value)
      remove_leading_newlines if EXP_END.include?(value)
      tag = ASSIGN.include?(value) ? :ASSIGN : value
      token(tag, value)
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

    # Close up all remaining open blocks.
    def close_indentation
      outdent_token(@indent)
    end

    # Rewrite the token stream, looking one token ahead and behind.
    def scan_tokens
      i = 0
      while i < @tokens.length
        yield(@tokens[i - 1], @tokens[i], @tokens[i + 1], i)
        i += 1
      end
    end

    # You should be able to put blank lines within indented expressions.
    # To that end, remove redundant outdent/indents from the token stream.
    def remove_empty_outdents
      scan_tokens do |prev, token, post, i|
        if prev[0] == :OUTDENT && token[1] == "\n" && post[0] == :INDENT && prev[1] == post[1]
          @tokens.delete_at(i + 1)
          @tokens.delete_at(i - 1)
        end
        if prev[0] == :OUTDENT && token[0] == :INDENT && prev[1] == token[1]
          @tokens.delete_at(i)
          @tokens.delete_at(i - 1)
          @tokens.insert(i - 1, ["\n", Value.new("\n", prev[1].line)])
        end
      end
    end

    # We'd like to support syntax like this:
    #    el.click(event =>
    #      el.hide())
    # In order to accomplish this, move outdents that follow closing parens
    # inwards, safely. The steps to accomplish this are:
    #
    # 1. Check that parentheses are balanced and in order.
    # 2. Check that indent/outdents are balanced and in order.
    # 3. Rewrite the stream with a stack: if you see an '(' or INDENT, add it
    #    to the stack. If you see an ')' or OUTDENT, pop the stack and replace
    #    it with the inverse of what we've just popped.
    #
    def rewrite_closing_parens
      stack = []
      scan_tokens do |prev, token, post, i|
        stack.push(token) if [:INDENT, '('].include?(token[0])
        if [:OUTDENT, ')'].include?(token[0])
          reciprocal = stack.pop
          if reciprocal[0] == :INDENT
            @tokens[i] = [:OUTDENT, Value.new(reciprocal[1], token[1].line)]
          else
            @tokens[i] = [')', Value.new(')', token[1].line)]
          end
        end
      end
    end

    def ensure_balance(*pairs)
      levels = Hash.new(0)
      scan_tokens do |prev, token, post, i|
        pairs.each do |pair|
          open, close = *pair
          levels[open] += 1 if token[0] == open
          levels[open] -= 1 if token[0] == close
          raise ParseError.new(token[0], token[1], nil) if levels[open] < 0
        end
      end
      unclosed = levels.detect {|k, v| v > 0 }
      raise SyntaxError, "unclosed '#{unclosed[0]}'" if unclosed
    end

  end

end