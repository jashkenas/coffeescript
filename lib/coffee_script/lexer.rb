class Lexer

  KEYWORDS   = ["if", "else", "then", "unless",
                "true", "false", "null",
                "and", "or", "is", "aint", "not",
                "new", "return",
                "try", "catch", "finally", "throw",
                "break", "continue",
                "for", "in", "while",
                "switch", "case",
                "super"]

  IDENTIFIER = /\A([a-zA-Z$_]\w*)/
  NUMBER     = /\A\b((0(x|X)[0-9a-fA-F]+)|([0-9]+(\.[0-9]+)?(e[+\-]?[0-9]+)?))\b/i
  STRING     = /\A("(.*?)[^\\]"|'(.*?)[^\\]')/m
  JS         = /\A(`(.*?)`)/
  OPERATOR   = /\A([+\*&|\/\-%=<>]+)/
  WHITESPACE = /\A([ \t\r]+)/
  NEWLINE    = /\A([\r\n]+)/
  COMMENT    = /\A(#[^\r\n]*)/
  CODE       = /\A(=>)/
  REGEX      = /\A(\/(.*?)[^\\]\/[imgy]{0,4})/

  JS_CLEANER = /(\A`|`\Z)/
  MULTILINER = /[\r\n]/

  EXP_START  = ['{', '(', '[']
  EXP_END    = ['}', ')', ']']

  # This is how to implement a very simple scanner.
  # Scan one caracter at the time until you find something to parse.
  def tokenize(code)
    @code = code.chomp    # Cleanup code by remove extra line breaks
    @i = 0                # Current character position we're parsing
    @line = 1             # The current line.
    @tokens = []          # Collection of all parsed tokens in the form [:TOKEN_TYPE, value]
    while @i < @code.length
      @chunk = @code[@i..-1]
      extract_next_token
    end
    @tokens
  end

  def extract_next_token
    return if identifier_token
    return if number_token
    return if string_token
    return if js_token
    return if regex_token
    return if remove_comment
    return if whitespace_token
    return    literal_token
  end

  # Matching if, print, method names, etc.
  def identifier_token
    return false unless identifier = @chunk[IDENTIFIER, 1]
    # Keywords are special identifiers tagged with their own name, 'if' will result
    # in an [:IF, "if"] token
    tag = KEYWORDS.include?(identifier) ? identifier.upcase.to_sym : :IDENTIFIER
    @tokens[-1][0] = :PROPERTY_ACCESS if tag == :IDENTIFIER && last_value == '.'
    token(tag, identifier)
    @i += identifier.length
  end

  def number_token
    return false unless number = @chunk[NUMBER, 1]
    token(:NUMBER, number)
    @i += number.length
  end

  def string_token
    return false unless string = @chunk[STRING, 1]
    escaped = string.gsub(MULTILINER) do |match|
      @line += 1
      "\\\n"
    end
    token(:STRING, escaped)
    @i += string.length
  end

  def js_token
    return false unless script = @chunk[JS, 1]
    token(:JS, script.gsub(JS_CLEANER, ''))
    @i += script.length
  end

  def regex_token
    return false unless regex = @chunk[REGEX, 1]
    token(:REGEX, regex)
    @i += regex.length
  end

  def remove_comment
    return false unless comment = @chunk[COMMENT, 1]
    @i += comment.length
  end

  # Ignore whitespace
  def whitespace_token
    return false unless whitespace = @chunk[WHITESPACE, 1]
    @i += whitespace.length
  end

  # We treat all other single characters as a token. Eg.: ( ) , . !
  # Multi-character operators are also literal tokens, so that Racc can assign
  # the proper order of operations. Multiple newlines get merged.
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

  def token(tag, value)
    @tokens << [tag, Value.new(value, @line)]
  end

  def last_value
    @tokens.last && @tokens.last[1]
  end

  # The main source of ambiguity in our grammar was Parameter lists (as opposed
  # to argument lists in method calls). Tag parameter identifiers to avoid this.
  def tag_parameters
    index = 0
    loop do
      tok = @tokens[index -= 1]
      next if tok[0] == ','
      return if tok[0] != :IDENTIFIER
      tok[0] = :PARAM
    end
  end

  def skip_following_newlines
    newlines = @code[(@i+1)..-1][NEWLINE, 1]
    if newlines
      @line += newlines.length
      @i += newlines.length
    end
  end

  def remove_leading_newlines
    @tokens.pop if last_value == "\n"
  end

end