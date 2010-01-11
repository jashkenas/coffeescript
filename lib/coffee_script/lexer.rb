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
                  "for", "in", "of", "by", "where", "while",
                  "switch", "when",
                  "super", "extends",
                  "arguments",
                  "delete", "instanceof", "typeof"]

    # Token matching regexes.
    IDENTIFIER = /\A([a-zA-Z$_](\w|\$)*)/
    NUMBER     = /\A(\b((0(x|X)[0-9a-fA-F]+)|([0-9]+(\.[0-9]+)?(e[+\-]?[0-9]+)?)))\b/i
    STRING     = /\A(""|''|"(.*?)([^\\]|\\\\)"|'(.*?)([^\\]|\\\\)')/m
    JS         = /\A(``|`(.*?)([^\\]|\\\\)`)/m
    OPERATOR   = /\A([+\*&|\/\-%=<>:!]+)/
    WHITESPACE = /\A([ \t]+)/
    COMMENT    = /\A(((\n?[ \t]*)?#.*$)+)/
    CODE       = /\A(=>)/
    REGEX      = /\A(\/(.*?)([^\\]|\\\\)\/[imgy]{0,4})/
    MULTI_DENT = /\A((\n([ \t]*))+)(\.)?/
    LAST_DENT  = /\n([ \t]*)/
    ASSIGNMENT = /\A(:|=)\Z/

    # Token cleaning regexes.
    JS_CLEANER = /(\A`|`\Z)/
    MULTILINER = /\n/
    COMMENT_CLEANER = /(^\s*#|\n\s*$)/
    NO_NEWLINE = /\A([+\*&|\/\-%=<>:!.\\][<>=&|]*|and|or|is|isnt|not|delete|typeof|instanceof)\Z/

    # Tokens which a regular expression will never immediately follow, but which
    # a division operator might.
    # See: http://www.mozilla.org/js/language/js20-2002-04/rationale/syntax.html#regular-expressions
    NOT_REGEX  = [
      :IDENTIFIER, :NUMBER, :REGEX, :STRING,
      ')', '++', '--', ']', '}',
      :FALSE, :NULL, :THIS, :TRUE
    ]

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
      puts "original stream: #{@tokens.inspect}" if ENV['VERBOSE']
      close_indentation
      Rewriter.new.rewrite(@tokens)
    end

    # At every position, run through this list of attempted matches,
    # short-circuiting if any of them succeed.
    def extract_next_token
      return if identifier_token
      return if number_token
      return if string_token
      return if js_token
      return if regex_token
      return if indent_token
      return if comment_token
      return if whitespace_token
      return    literal_token
    end

    # Tokenizers ==========================================================

    # Matches identifying literals: variables, keywords, method names, etc.
    def identifier_token
      return false unless identifier = @chunk[IDENTIFIER, 1]
      # Keywords are special identifiers tagged with their own name,
      # 'if' will result in an [:IF, "if"] token.
      tag = KEYWORDS.include?(identifier) ? identifier.upcase.to_sym : :IDENTIFIER
      tag = :LEADING_WHEN if tag == :WHEN && [:OUTDENT, :INDENT, "\n"].include?(last_tag)
      @tokens[-1][0] = :PROPERTY_ACCESS if tag == :IDENTIFIER && last_value == '.' && !(@tokens[-2] && @tokens[-2][1] == '.')
      @tokens[-1][0] = :PROTOTYPE_ACCESS if tag == :IDENTIFIER && last_value == '::'
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
      return false if NOT_REGEX.include?(last_tag)
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
      return false unless indent = @chunk[MULTI_DENT, 1]
      @line += indent.scan(MULTILINER).size
      @i += indent.size
      next_character = @chunk[MULTI_DENT, 4]
      no_newlines = next_character == '.' || (last_value.to_s.match(NO_NEWLINE) && last_value != "=>")
      return suppress_newlines(indent) if no_newlines
      size = indent.scan(LAST_DENT).last.last.length
      return newline_token(indent) if size == @indent
      if size > @indent
        token(:INDENT, size - @indent)
        @indents << (size - @indent)
      else
        outdent_token(@indent - size)
      end
      @indent = size
    end

    # Record an oudent token or tokens, if we're moving back inwards past
    # multiple recorded indents.
    def outdent_token(move_out)
      while move_out > 0 && !@indents.empty?
        last_indent = @indents.pop
        token(:OUTDENT, last_indent)
        move_out -= last_indent
      end
      token("\n", "\n")
    end

    # Matches and consumes non-meaningful whitespace.
    def whitespace_token
      return false unless whitespace = @chunk[WHITESPACE, 1]
      @i += whitespace.length
    end

    # Multiple newlines get merged together.
    # Use a trailing \ to escape newlines.
    def newline_token(newlines)
      token("\n", "\n") unless last_value == "\n"
      true
    end

    # Tokens to explicitly escape newlines are removed once their job is done.
    def suppress_newlines(newlines)
      @tokens.pop if last_value == "\\"
      true
    end

    # We treat all other single characters as a token. Eg.: ( ) , . !
    # Multi-character operators are also literal tokens, so that Racc can assign
    # the proper order of operations.
    def literal_token
      value = @chunk[OPERATOR, 1]
      tag_parameters if value && value.match(CODE)
      value ||= @chunk[0,1]
      tag = value.match(ASSIGNMENT) ? :ASSIGN : value
      token(tag, value)
      @i += value.length
    end

    # Helpers ==========================================================

    # Add a token to the results, taking note of the line number, and
    # immediately-preceding comment.
    def token(tag, value)
      @tokens << [tag, Value.new(value, @line)]
    end

    # Peek at the previous token's value.
    def last_value
      @tokens.last && @tokens.last[1]
    end

    # Peek at the previous token's tag.
    def last_tag
      @tokens.last && @tokens.last[0]
    end

    # A source of ambiguity in our grammar was parameter lists in function
    # definitions (as opposed to argument lists in function calls). Tag
    # parameter identifiers in order to avoid this. Also, parameter lists can
    # make use of splats.
    def tag_parameters
      i = 0
      loop do
        i -= 1
        tok = @tokens[i]
        return if !tok
        next if ['.', ','].include?(tok[0])
        return if tok[0] != :IDENTIFIER
        tok[0] = :PARAM
      end
    end

    # Close up all remaining open blocks. IF the first token is an indent,
    # axe it.
    def close_indentation
      outdent_token(@indent)
    end

  end
end