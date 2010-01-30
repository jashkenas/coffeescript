sys: require 'sys'

# The lexer reads a stream of CoffeeScript and divvys it up into tagged
# tokens. A minor bit of the ambiguity in the grammar has been avoided by
# pushing some extra smarts into the Lexer.
exports.Lexer: lex: ->

# The list of keywords passed verbatim to the parser.
lex.KEYWORDS: [
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
lex.IDENTIFIER : /^([a-zA-Z$_](\w|\$)*)/
lex.NUMBER     : /^(\b((0(x|X)[0-9a-fA-F]+)|([0-9]+(\.[0-9]+)?(e[+\-]?[0-9]+)?)))\b/i
lex.STRING     : /^(""|''|"([\s\S]*?)([^\\]|\\\\)"|'([\s\S]*?)([^\\]|\\\\)')/
lex.HEREDOC    : /^("{6}|'{6}|"{3}\n?([\s\S]*?)\n?([ \t]*)"{3}|'{3}\n?([\s\S]*?)\n?([ \t]*)'{3})/
lex.JS         : /^(``|`([\s\S]*?)([^\\]|\\\\)`)/
lex.OPERATOR   : /^([+\*&|\/\-%=<>:!?]+)/
lex.WHITESPACE : /^([ \t]+)/
lex.COMMENT    : /^(((\n?[ \t]*)?#.*$)+)/
lex.CODE       : /^((-|=)>)/
lex.REGEX      : /^(\/(.*?)([^\\]|\\\\)\/[imgy]{0,4})/
lex.MULTI_DENT : /^((\n([ \t]*))+)(\.)?/
lex.LAST_DENT  : /\n([ \t]*)/
lex.ASSIGNMENT : /^(:|=)$/

# Token cleaning regexes.
lex.JS_CLEANER      : /(^`|`$)/g
lex.MULTILINER      : /\n/g
lex.STRING_NEWLINES : /\n[ \t]*/g
lex.COMMENT_CLEANER : /(^[ \t]*#|\n[ \t]*$)/mg
lex.NO_NEWLINE      : /^([+\*&|\/\-%=<>:!.\\][<>=&|]*|and|or|is|isnt|not|delete|typeof|instanceof)$/
lex.HEREDOC_INDENT  : /^[ \t]+/g

# Tokens which a regular expression will never immediately follow, but which
# a division operator might.
# See: http://www.mozilla.org/js/language/js20-2002-04/rationale/syntax.html#regular-expressions
lex.NOT_REGEX: [
  'IDENTIFIER', 'NUMBER', 'REGEX', 'STRING',
  ')', '++', '--', ']', '}',
  'FALSE', 'NULL', 'TRUE'
]

# Tokens which could legitimately be invoked or indexed.
lex.CALLABLE: ['IDENTIFIER', 'SUPER', ')', ']', '}', 'STRING']

# Scan by attempting to match tokens one character at a time. Slow and steady.
lex::tokenize: (code) ->
  this.code    : code       # Cleanup code by remove extra line breaks, TODO: chomp
  this.i       : 0          # Current character position we're parsing
  this.line    : 1          # The current line.
  this.indent  : 0          # The current indent level.
  this.indents : []         # The stack of all indent levels we are currently within.
  this.tokens  : []         # Collection of all parsed tokens in the form [:TOKEN_TYPE, value]
  while this.i < this.code.length
    this.chunk: this.code.slice(this.i)
    this.extract_next_token()
  # sys.puts "original stream: #{@tokens.inspect}" if process.ENV['VERBOSE']
  # this.close_indentation()
  # (new Rewriter()).rewrite(this.tokens)
  this.tokens

# At every position, run through this list of attempted matches,
# short-circuiting if any of them succeed.
lex::extract_next_token: ->
  return if this.identifier_token()
  return if this.number_token()
  return if this.heredoc_token()
  return if this.string_token()
  return if this.js_token()
  return if this.regex_token()
  # return if this.indent_token()
  return if this.comment_token()
  return if this.whitespace_token()
  return    this.literal_token()

# Tokenizers ==========================================================

# Matches identifying literals: variables, keywords, method names, etc.
lex::identifier_token: ->
  return false unless id: this.match lex.IDENTIFIER, 1
  # Keywords are special identifiers tagged with their own name,
  # 'if' will result in an ['IF', "if"] token.
  tag: if lex.KEYWORDS.indexOf(id) >= 0 then id.toUpperCase() else 'IDENTIFIER'
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

# Matches numbers, including decimals, hex, and exponential notation.
lex::number_token: ->
  return false unless number: this.match lex.NUMBER, 1
  this.token 'NUMBER', number
  this.i += number.length

# Matches strings, including multi-line strings.
lex::string_token: ->
  return false unless string: this.match lex.STRING, 1
  escaped: string.replace STRING_NEWLINES, " \\\n"
  this.token 'STRING', escaped
  this.line += this.count string, "\n"
  this.i += string.length

# Matches heredocs, adjusting indentation to the correct level.
lex::heredoc_token: ->
  return false unless match = this.chunk.match(lex.HEREDOC)
  doc: match[2] or match[4]
  indent: doc.match(lex.HEREDOC_INDENT).sort()[0]
  doc: doc.replace(new RegExp("^" + indent, 'g'), '')
          .replace(lex.MULTILINER, "\\n")
          .replace('"', '\\"')
  this.token 'STRING', '"' + doc + '"'
  this.line += this.count match[1], "\n"
  this.i += match[1].length

# Matches interpolated JavaScript.
lex::js_token: ->
  return false unless script: this.match lex.JS, 1
  this.token 'JS', script.replace(lex.JS_CLEANER, '')
  this.i += script.length

# Matches regular expression literals.
lex::regex_token: ->
  return false unless regex: this.match lex.REGEX, 1
  return false if lex.NOT_REGEX.indexOf(this.tag()) >= 0
  this.token 'REGEX', regex
  this.i += regex.length

# Matches and conumes comments.
lex::comment_token: ->
  return false unless comment: this.match lex.COMMENT, 1
  this.line += comment.match(lex.MULTILINER).length
  this.token 'COMMENT', comment.replace(lex.COMMENT_CLEANER, '').split(lex.MULTILINER)
  this.token "\n", "\n"
  this.i += comment.length





# Matches and consumes non-meaningful whitespace.
lex::whitespace_token: ->
  return false unless space: this.match lex.WHITESPACE, 1
  this.value().spaced: true
  this.i += space.length

# We treat all other single characters as a token. Eg.: ( ) , . !
# Multi-character operators are also literal tokens, so that Racc can assign
# the proper order of operations.
lex::literal_token: ->
  match: this.chunk.match(lex.OPERATOR)
  value: match and match[1]
  tag_parameters() if value and value.match(lex.CODE)
  value ||= this.chunk.substr(0, 1)
  tag: if value.match(lex.ASSIGNMENT) then 'ASSIGN' else value
  if this.value() and this.value().spaced and lex.CALLABLE.indexOf(this.tag() >= 0)
    tag: 'CALL_START'  if value is '('
    tag: 'INDEX_START' if value is '['
  this.token tag, value
  this.i += value.length

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
lex::count: (string, char) ->
  num: 0
  pos: string.indexOf(char)
  while pos isnt -1
    count += 1
    pos: string.indexOf(char, pos + 1)
  count

# Attempt to match a string against the current chunk, returning the indexed
# match.
lex::match: (regex, index) ->
  return false unless m: this.chunk.match(regex)
  if m then m[index] else false




























