class Lexer

  KEYWORDS   = ["if", "else", "then",
                "true", "false", "null",
                "and", "or", "is", "aint", "not",
                "new", "return",
                "try", "catch", "finally", "throw"]

  IDENTIFIER = /\A([a-zA-Z$_]\w*)/
  NUMBER     = /\A([0-9]+(\.[0-9]+)?)/
  STRING     = /\A("(.*?)"|'(.*?)')/
  OPERATOR   = /\A([+\*&|\/\-%=<>]+)/
  WHITESPACE = /\A([ \t\r]+)/
  NEWLINE    = /\A([\r\n]+)/
  COMMENT    = /\A(#[^\r\n]*)/
  CODE       = /\A(=>)/
  REGEX      = /\A(\/(.*?)\/[imgy]{0,4})/

  # This is how to implement a very simple scanner.
  # Scan one caracter at the time until you find something to parse.
  def tokenize(code)
    @code = code.chomp    # Cleanup code by remove extra line breaks
    @i = 0                # Current character position we're parsing
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
    if tag == :IDENTIFIER && @tokens[-1] && @tokens[-1][1] == '.'
      @tokens[-1] = [:PROPERTY_ACCESS, '.']
    end
    @tokens << [tag, identifier]
    @i += identifier.length
  end

  def number_token
    return false unless number = @chunk[NUMBER, 1]
    float = number.include?('.')
    @tokens << [:NUMBER, float ? number.to_f : number.to_i]
    @i += number.length
  end

  def string_token
    return false unless string = @chunk[STRING, 1]
    @tokens << [:STRING, string]
    @i += string.length
  end

  def regex_token
    return false unless regex = @chunk[REGEX, 1]
    @tokens << [:REGEX, regex]
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
      @tokens << ["\n", "\n"] unless @tokens.last && @tokens.last[0] == "\n"
      return @i += value.length
    end
    value = @chunk[OPERATOR, 1]
    tag_parameters if value && value.match(CODE)
    value ||= @chunk[0,1]
    @tokens << [value, value]
    @i += value.length
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

end