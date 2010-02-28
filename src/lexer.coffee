if process?
  Rewriter: require('./rewriter').Rewriter
else
  this.exports: this
  Rewriter: this.Rewriter

# Constants ============================================================

# Keywords that CoffeScript shares in common with JS.
JS_KEYWORDS: [
  "if", "else",
  "true", "false",
  "new", "return",
  "try", "catch", "finally", "throw",
  "break", "continue",
  "for", "in", "while",
  "delete", "instanceof", "typeof",
  "switch", "super", "extends", "class"
]

# CoffeeScript-only keywords -- which we're more relaxed about allowing.
COFFEE_KEYWORDS: [
  "then", "unless",
  "yes", "no", "on", "off",
  "and", "or", "is", "isnt", "not",
  "of", "by", "where", "when"
]

# The list of keywords passed verbatim to the parser.
KEYWORDS: JS_KEYWORDS.concat COFFEE_KEYWORDS

# The list of keywords that are reserved by JavaScript, but not used, or are
# used by CoffeeScript internally. Using these will throw an error.
RESERVED: [
  "case", "default", "do", "function", "var", "void", "with"
  "const", "let", "debugger", "enum", "export", "import", "native",
  "__extends", "__hasProp"
]

# JavaScript keywords and reserved words together, excluding CoffeeScript ones.
JS_FORBIDDEN: JS_KEYWORDS.concat RESERVED

# Token matching regexes. (keep the IDENTIFIER regex in sync with AssignNode.)
IDENTIFIER : /^([a-zA-Z$_](\w|\$)*)/
NUMBER     : /^(\b((0(x|X)[0-9a-fA-F]+)|([0-9]+(\.[0-9]+)?(e[+\-]?[0-9]+)?)))\b/i
STRING     : /^(""|''|"([\s\S]*?)([^\\]|\\\\)"|'([\s\S]*?)([^\\]|\\\\)')/
HEREDOC    : /^("{6}|'{6}|"{3}\n?([\s\S]*?)\n?([ \t]*)"{3}|'{3}\n?([\s\S]*?)\n?([ \t]*)'{3})/
JS         : /^(``|`([\s\S]*?)([^\\]|\\\\)`)/
OPERATOR   : /^([+\*&|\/\-%=<>:!?]+)/
WHITESPACE : /^([ \t]+)/
COMMENT    : /^(((\n?[ \t]*)?#[^\n]*)+)/
CODE       : /^((-|=)>)/
REGEX      : /^(\/(\S.*?)?([^\\]|\\\\)\/[imgy]{0,4})/
MULTI_DENT : /^((\n([ \t]*))+)(\.)?/
LAST_DENTS : /\n([ \t]*)/g
LAST_DENT  : /\n([ \t]*)/
ASSIGNMENT : /^(:|=)$/

# Token cleaning regexes.
JS_CLEANER      : /(^`|`$)/g
MULTILINER      : /\n/g
STRING_NEWLINES : /\n[ \t]*/g
COMMENT_CLEANER : /(^[ \t]*#|\n[ \t]*$)/mg
NO_NEWLINE      : /^([+\*&|\/\-%=<>:!.\\][<>=&|]*|and|or|is|isnt|not|delete|typeof|instanceof)$/
HEREDOC_INDENT  : /^[ \t]+/mg

# Tokens which a regular expression will never immediately follow, but which
# a division operator might.
# See: http://www.mozilla.org/js/language/js20-2002-04/rationale/syntax.html#regular-expressions
# Our list is shorter, due to sans-parentheses method calls.
NOT_REGEX: [
  'NUMBER', 'REGEX', '++', '--', 'FALSE', 'NULL', 'TRUE'
]

# Tokens which could legitimately be invoked or indexed.
CALLABLE: ['IDENTIFIER', 'SUPER', ')', ']', '}', 'STRING', '@']

# Tokens that indicate an access -- keywords immediately following will be
# treated as identifiers.
ACCESSORS: ['PROPERTY_ACCESS', 'PROTOTYPE_ACCESS', 'SOAK_ACCESS', '@']

# Tokens that, when immediately preceding a 'WHEN', indicate that its leading.
BEFORE_WHEN: ['INDENT', 'OUTDENT', 'TERMINATOR']

# The lexer reads a stream of CoffeeScript and divvys it up into tagged
# tokens. A minor bit of the ambiguity in the grammar has been avoided by
# pushing some extra smarts into the Lexer.
exports.Lexer: class Lexer

  # Scan by attempting to match tokens one character at a time. Slow and steady.
  tokenize: (code) ->
    @code    : code       # Cleanup code by remove extra line breaks, TODO: chomp
    @i       : 0          # Current character position we're parsing
    @line    : 1          # The current line.
    @indent  : 0          # The current indent level.
    @indents : []         # The stack of all indent levels we are currently within.
    @tokens  : []         # Collection of all parsed tokens in the form [:TOKEN_TYPE, value]
    while @i < @code.length
      @chunk: @code.slice(@i)
      @extract_next_token()
    @close_indentation()
    (new Rewriter()).rewrite @tokens

  # At every position, run through this list of attempted matches,
  # short-circuiting if any of them succeed.
  extract_next_token: ->
    return if @identifier_token()
    return if @number_token()
    return if @heredoc_token()
    return if @string_token()
    return if @js_token()
    return if @regex_token()
    return if @indent_token()
    return if @comment_token()
    return if @whitespace_token()
    return    @literal_token()

  # Tokenizers ==========================================================

  # Matches identifying literals: variables, keywords, method names, etc.
  identifier_token: ->
    return false unless id: @match IDENTIFIER, 1
    @tag(1, 'PROTOTYPE_ACCESS') if @value() is '::'
    if @value() is '.' and not (@value(2) is '.')
      if @tag(2) is '?'
        @tag(1, 'SOAK_ACCESS')
        @tokens.splice(-2, 1)
      else
        @tag(1, 'PROPERTY_ACCESS')
    tag: 'IDENTIFIER'
    tag:  id.toUpperCase() if KEYWORDS.indexOf(id) >= 0 and
      not ((ACCESSORS.indexOf(@tag()) >= 0) and not @prev().spaced)
    throw new Error('SyntaxError: Reserved word "' + id + '" on line ' + @line) if RESERVED.indexOf(id) >= 0
    tag: 'LEADING_WHEN' if tag is 'WHEN' and BEFORE_WHEN.indexOf(@tag()) >= 0
    @token(tag, id)
    @i += id.length
    true

  # Matches numbers, including decimals, hex, and exponential notation.
  number_token: ->
    return false unless number: @match NUMBER, 1
    @token 'NUMBER', number
    @i += number.length
    true

  # Matches strings, including multi-line strings.
  string_token: ->
    return false unless string: @match STRING, 1
    escaped: string.replace STRING_NEWLINES, " \\\n"
    @token 'STRING', escaped
    @line += @count string, "\n"
    @i += string.length
    true

  # Matches heredocs, adjusting indentation to the correct level.
  heredoc_token: ->
    return false unless match = @chunk.match(HEREDOC)
    doc: match[2] or match[4]
    indent: (doc.match(HEREDOC_INDENT) or ['']).sort()[0]
    doc: doc.replace(new RegExp("^" + indent, 'gm'), '')
            .replace(MULTILINER, "\\n")
            .replace('"', '\\"')
    @token 'STRING', '"' + doc + '"'
    @line += @count match[1], "\n"
    @i += match[1].length
    true

  # Matches interpolated JavaScript.
  js_token: ->
    return false unless script: @match JS, 1
    @token 'JS', script.replace(JS_CLEANER, '')
    @i += script.length
    true

  # Matches regular expression literals.
  regex_token: ->
    return false unless regex: @match REGEX, 1
    return false if NOT_REGEX.indexOf(@tag()) >= 0
    @token 'REGEX', regex
    @i += regex.length
    true

  # Matches and conumes comments.
  comment_token: ->
    return false unless comment: @match COMMENT, 1
    @line += (comment.match(MULTILINER) or []).length
    @token 'COMMENT', comment.replace(COMMENT_CLEANER, '').split(MULTILINER)
    @token 'TERMINATOR', "\n"
    @i += comment.length
    true

  # Record tokens for indentation differing from the previous line.
  indent_token: ->
    return false unless indent: @match MULTI_DENT, 1
    @line += indent.match(MULTILINER).length
    @i    += indent.length
    next_character: @chunk.match(MULTI_DENT)[4]
    prev: @prev(2)
    no_newlines: next_character is '.' or (@value() and @value().match(NO_NEWLINE) and prev and (prev[0] isnt '.') and not @value().match(CODE))
    return @suppress_newlines(indent) if no_newlines
    size: indent.match(LAST_DENTS).reverse()[0].match(LAST_DENT)[1].length
    return @newline_token(indent) if size is @indent
    if size > @indent
      diff: size - @indent
      @token 'INDENT', diff
      @indents.push diff
    else
      @outdent_token @indent - size
    @indent: size
    true

  # Record an oudent token or tokens, if we're moving back inwards past
  # multiple recorded indents.
  outdent_token: (move_out) ->
    while move_out > 0 and @indents.length
      last_indent: @indents.pop()
      @token 'OUTDENT', last_indent
      move_out -= last_indent
    @token 'TERMINATOR', "\n" unless @tag() is 'TERMINATOR'
    true

  # Matches and consumes non-meaningful whitespace.
  whitespace_token: ->
    return false unless space: @match WHITESPACE, 1
    prev: @prev()
    prev.spaced: true if prev
    @i += space.length
    true

  # Multiple newlines get merged together.
  # Use a trailing \ to escape newlines.
  newline_token: (newlines) ->
    @token 'TERMINATOR', "\n" unless @tag() is 'TERMINATOR'
    true

  # Tokens to explicitly escape newlines are removed once their job is done.
  suppress_newlines: (newlines) ->
    @tokens.pop() if @value() is "\\"
    true

  # We treat all other single characters as a token. Eg.: ( ) , . !
  # Multi-character operators are also literal tokens, so that Racc can assign
  # the proper order of operations.
  literal_token: ->
    match: @chunk.match(OPERATOR)
    value: match and match[1]
    @tag_parameters() if value and value.match(CODE)
    value ||= @chunk.substr(0, 1)
    not_spaced: not @prev() or not @prev().spaced
    tag: value
    if value.match(ASSIGNMENT)
      tag: 'ASSIGN'
      throw new Error('SyntaxError: Reserved word "' + @value() + '" on line ' + @line + ' can\'t be assigned') if JS_FORBIDDEN.indexOf(@value()) >= 0
    else if value is ';'
      tag: 'TERMINATOR'
    else if value is '[' and @tag() is '?' and not_spaced
      tag: 'SOAKED_INDEX_START'
      @soaked_index: true
      @tokens.pop()
    else if value is ']' and @soaked_index
      tag: 'SOAKED_INDEX_END'
      @soaked_index: false
    else if CALLABLE.indexOf(@tag()) >= 0 and not_spaced
      tag: 'CALL_START'  if value is '('
      tag: 'INDEX_START' if value is '['
    @token tag, value
    @i += value.length
    true

  # Helpers =============================================================

  # Add a token to the results, taking note of the line number.
  token: (tag, value) ->
    @tokens.push([tag, value, @line])

  # Look at a tag in the current token stream.
  tag: (index, tag) ->
    return unless tok: @prev(index)
    return tok[0]: tag if tag?
    tok[0]

  # Look at a value in the current token stream.
  value: (index, val) ->
    return unless tok: @prev(index)
    return tok[1]: val if val?
    tok[1]

  # Look at a previous token.
  prev: (index) ->
    @tokens[@tokens.length - (index or 1)]

  # Count the occurences of a character in a string.
  count: (string, letter) ->
    num: 0
    pos: string.indexOf(letter)
    while pos isnt -1
      num += 1
      pos: string.indexOf(letter, pos + 1)
    num

  # Attempt to match a string against the current chunk, returning the indexed
  # match.
  match: (regex, index) ->
    return false unless m: @chunk.match(regex)
    if m then m[index] else false

  # A source of ambiguity in our grammar was parameter lists in function
  # definitions (as opposed to argument lists in function calls). Tag
  # parameter identifiers in order to avoid this. Also, parameter lists can
  # make use of splats.
  tag_parameters: ->
    return if @tag() isnt ')'
    i: 0
    while true
      i += 1
      tok: @prev(i)
      return if not tok
      switch tok[0]
        when 'IDENTIFIER' then tok[0]: 'PARAM'
        when ')'          then tok[0]: 'PARAM_END'
        when '('          then return tok[0]: 'PARAM_START'
    true

  # Close up all remaining open blocks. IF the first token is an indent,
  # axe it.
  close_indentation: ->
    @outdent_token(@indent)
