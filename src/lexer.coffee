Rewriter: require('./rewriter').Rewriter

# The lexer reads a stream of CoffeeScript and divvys it up into tagged
# tokens. A minor bit of the ambiguity in the grammar has been avoided by
# pushing some extra smarts into the Lexer.
exports.Lexer: lex: ->

# Constants ============================================================

# The list of keywords passed verbatim to the parser.
KEYWORDS: [
  "if", "else", "then", "unless",
  "true", "false", "yes", "no", "on", "off",
  "and", "or", "is", "isnt", "not",
  "new", "return", "arguments",
  "try", "catch", "finally", "throw",
  "break", "continue",
  "for", "in", "of", "by", "where", "while",
  "delete", "instanceof", "typeof",
  "switch", "when",
  "super", "extends"
]

# Token matching regexes.
IDENTIFIER : /^([a-zA-Z$_](\w|\$)*)/
NUMBER     : /^(\b((0(x|X)[0-9a-fA-F]+)|([0-9]+(\.[0-9]+)?(e[+\-]?[0-9]+)?)))\b/i
STRING     : /^(""|''|"([\s\S]*?)([^\\]|\\\\)"|'([\s\S]*?)([^\\]|\\\\)')/
HEREDOC    : /^("{6}|'{6}|"{3}\n?([\s\S]*?)\n?([ \t]*)"{3}|'{3}\n?([\s\S]*?)\n?([ \t]*)'{3})/
JS         : /^(``|`([\s\S]*?)([^\\]|\\\\)`)/
OPERATOR   : /^([+\*&|\/\-%=<>:!?]+)/
WHITESPACE : /^([ \t]+)/
COMMENT    : /^(((\n?[ \t]*)?#.*$)+)/
CODE       : /^((-|=)>)/
REGEX      : /^(\/(.*?)([^\\]|\\\\)\/[imgy]{0,4})/
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
HEREDOC_INDENT  : /^[ \t]+/g

# Tokens which a regular expression will never immediately follow, but which
# a division operator might.
# See: http://www.mozilla.org/js/language/js20-2002-04/rationale/syntax.html#regular-expressions
NOT_REGEX: [
  'IDENTIFIER', 'NUMBER', 'REGEX', 'STRING',
  ')', '++', '--', ']', '}',
  'FALSE', 'NULL', 'TRUE'
]

# Tokens which could legitimately be invoked or indexed.
CALLABLE: ['IDENTIFIER', 'SUPER', ')', ']', '}', 'STRING']

# Scan by attempting to match tokens one character at a time. Slow and steady.
lex::tokenize: (code) ->
  this.code    : code       # Cleanup code by remove extra line breaks, TODO: chomp
  this.i       : 0          # Current character position we're parsing
  this.line    : 1          # The current line.
  this.indent  : 0          # The current indent level.
  this.indents : []         # The stack of all indent levels we are currently within.
  this.tokens  : []         # Collection of all parsed tokens in the form [:TOKEN_TYPE, value]
  this.spaced  : null       # The last token that has a space following it.
  while this.i < this.code.length
    this.chunk: this.code.slice(this.i)
    this.extract_next_token()
  this.close_indentation()
  (new Rewriter()).rewrite this.tokens

# At every position, run through this list of attempted matches,
# short-circuiting if any of them succeed.
lex::extract_next_token: ->
  return if this.identifier_token()
  return if this.number_token()
  return if this.heredoc_token()
  return if this.string_token()
  return if this.js_token()
  return if this.regex_token()
  return if this.indent_token()
  return if this.comment_token()
  return if this.whitespace_token()
  return    this.literal_token()

# Tokenizers ==========================================================

# Matches identifying literals: variables, keywords, method names, etc.
lex::identifier_token: ->
  return false unless id: this.match IDENTIFIER, 1
  # Keywords are special identifiers tagged with their own name,
  # 'if' will result in an ['IF', "if"] token.
  tag: if KEYWORDS.indexOf(id) >= 0 then id.toUpperCase() else 'IDENTIFIER'
  tag: 'LEADING_WHEN' if tag is 'WHEN' and (this.tag() is 'OUTDENT' or this.tag() is 'INDENT')
  this.tag(-1, 'PROTOTYPE_ACCESS') if tag is 'IDENTIFIER' and this.value() is '::'
  if tag is 'IDENTIFIER' and this.value() is '.' and !(this.value(-2) is '.')
    if this.tag(-2) is '?'
      this.tag(-1, 'SOAK_ACCESS')
      this.tokens.splice(-2, 1)
    else
      this.tag(-1, 'PROPERTY_ACCESS')
  this.token(tag, id)
  this.i += id.length
  true

# Matches numbers, including decimals, hex, and exponential notation.
lex::number_token: ->
  return false unless number: this.match NUMBER, 1
  this.token 'NUMBER', number
  this.i += number.length
  true

# Matches strings, including multi-line strings.
lex::string_token: ->
  return false unless string: this.match STRING, 1
  escaped: string.replace STRING_NEWLINES, " \\\n"
  this.token 'STRING', escaped
  this.line += this.count string, "\n"
  this.i += string.length
  true

# Matches heredocs, adjusting indentation to the correct level.
lex::heredoc_token: ->
  return false unless match = this.chunk.match(HEREDOC)
  doc: match[2] or match[4]
  indent: doc.match(HEREDOC_INDENT).sort()[0]
  doc: doc.replace(new RegExp("^" + indent, 'g'), '')
          .replace(MULTILINER, "\\n")
          .replace('"', '\\"')
  this.token 'STRING', '"' + doc + '"'
  this.line += this.count match[1], "\n"
  this.i += match[1].length
  true

# Matches interpolated JavaScript.
lex::js_token: ->
  return false unless script: this.match JS, 1
  this.token 'JS', script.replace(JS_CLEANER, '')
  this.i += script.length
  true

# Matches regular expression literals.
lex::regex_token: ->
  return false unless regex: this.match REGEX, 1
  return false if NOT_REGEX.indexOf(this.tag()) >= 0
  this.token 'REGEX', regex
  this.i += regex.length
  true

# Matches and conumes comments.
lex::comment_token: ->
  return false unless comment: this.match COMMENT, 1
  this.line += comment.match(MULTILINER).length
  this.token 'COMMENT', comment.replace(COMMENT_CLEANER, '').split(MULTILINER)
  this.token 'TERMINATOR', "\n"
  this.i += comment.length
  true

# Record tokens for indentation differing from the previous line.
lex::indent_token: ->
  return false unless indent: this.match MULTI_DENT, 1
  this.line += indent.match(MULTILINER).length
  this.i    += indent.length
  next_character: this.chunk.match(MULTI_DENT)[4]
  no_newlines: next_character is '.' or (this.value().match(NO_NEWLINE) and this.tokens[this.tokens.length - 2][0] isnt '.' and not this.value().match(CODE))
  return this.suppress_newlines(indent) if no_newlines
  size: indent.match(LAST_DENTS).reverse()[0].match(LAST_DENT)[1].length
  return this.newline_token(indent) if size is this.indent
  if size > this.indent
    diff: size - this.indent
    this.token 'INDENT', diff
    this.indents.push diff
  else
    this.outdent_token this.indent - size
  this.indent: size
  true

# Record an oudent token or tokens, if we're moving back inwards past
# multiple recorded indents.
lex::outdent_token: (move_out) ->
  while move_out > 0 and this.indents.length
    last_indent: this.indents.pop()
    this.token 'OUTDENT', last_indent
    move_out -= last_indent
  this.token 'TERMINATOR', "\n"
  true

# Matches and consumes non-meaningful whitespace.
lex::whitespace_token: ->
  return false unless space: this.match WHITESPACE, 1
  this.spaced: this.value()
  this.i += space.length
  true

# Multiple newlines get merged together.
# Use a trailing \ to escape newlines.
lex::newline_token: (newlines) ->
  this.token 'TERMINATOR', "\n" unless this.value() is "\n"
  true

# Tokens to explicitly escape newlines are removed once their job is done.
lex::suppress_newlines: (newlines) ->
  this.tokens.pop() if this.value() is "\\"
  true

# We treat all other single characters as a token. Eg.: ( ) , . !
# Multi-character operators are also literal tokens, so that Racc can assign
# the proper order of operations.
lex::literal_token: ->
  match: this.chunk.match(OPERATOR)
  value: match and match[1]
  this.tag_parameters() if value and value.match(CODE)
  value ||= this.chunk.substr(0, 1)
  tag: if value.match(ASSIGNMENT) then 'ASSIGN' else value
  tag: 'TERMINATOR' if value == ';'
  if this.value() isnt this.spaced and CALLABLE.indexOf(this.tag()) >= 0
    tag: 'CALL_START'  if value is '('
    tag: 'INDEX_START' if value is '['
  this.token tag, value
  this.i += value.length
  true

# Helpers =============================================================

# Add a token to the results, taking note of the line number.
lex::token: (tag, value) ->
  this.tokens.push([tag, value])
  # this.tokens.push([tag, Value.new(value, @line)])

# Look at a tag in the current token stream.
lex::tag: (index, tag) ->
  return unless tok: this.tokens[this.tokens.length - (index || 1)]
  return tok[0]: tag if tag?
  tok[0]

# Look at a value in the current token stream.
lex::value: (index, val) ->
  return unless tok: this.tokens[this.tokens.length - (index || 1)]
  return tok[1]: val if val?
  tok[1]

# Count the occurences of a character in a string.
lex::count: (string, letter) ->
  num: 0
  pos: string.indexOf(letter)
  while pos isnt -1
    count += 1
    pos: string.indexOf(letter, pos + 1)
  count

# Attempt to match a string against the current chunk, returning the indexed
# match.
lex::match: (regex, index) ->
  return false unless m: this.chunk.match(regex)
  if m then m[index] else false

# A source of ambiguity in our grammar was parameter lists in function
# definitions (as opposed to argument lists in function calls). Tag
# parameter identifiers in order to avoid this. Also, parameter lists can
# make use of splats.
lex::tag_parameters: ->
  return if this.tag() isnt ')'
  i: 0
  while true
    i += 1
    tok: this.tokens[this.tokens.length - i]
    return if not tok
    switch tok[0]
      when 'IDENTIFIER' then tok[0]: 'PARAM'
      when ')'          then tok[0]: 'PARAM_END'
      when '('          then return tok[0]: 'PARAM_START'
  true

# Close up all remaining open blocks. IF the first token is an indent,
# axe it.
lex::close_indentation: ->
  this.outdent_token(this.indent)
