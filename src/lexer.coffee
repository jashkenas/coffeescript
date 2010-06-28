# The CoffeeScript Lexer. Uses a series of token-matching regexes to attempt
# matches against the beginning of the source code. When a match is found,
# a token is produced, we consume the match, and start again. Tokens are in the
# form:
#
#     [tag, value, lineNumber]
#
# Which is a format that can be fed directly into [Jison](http://github.com/zaach/jison).

# Set up the Lexer for both Node.js and the browser, depending on where we are.
if process?
  {Rewriter}: require('./rewriter')
  {helpers}:  require('./helpers')
else
  this.exports: this
  Rewriter:     this.Rewriter
  helpers:      this.helpers

# Import the helpers we need.
{include, count, starts, compact, balancedString}: helpers

# The Lexer Class
# ---------------

# The Lexer class reads a stream of CoffeeScript and divvys it up into tagged
# tokens. Some potential ambiguity in the grammar has been avoided by
# pushing some extra smarts into the Lexer.
exports.Lexer: class Lexer

  # **tokenize** is the Lexer's main method. Scan by attempting to match tokens
  # one at a time, using a regular expression anchored at the start of the
  # remaining code, or a custom recursive token-matching method
  # (for interpolations). When the next token has been recorded, we move forward
  # within the code past the token, and begin again.
  #
  # Each tokenizing method is responsible for incrementing `@i` by the number of
  # characters it has consumed. `@i` can be thought of as our finger on the page
  # of source.
  #
  # Before returning the token stream, run it through the [Rewriter](rewriter.html)
  # unless explicitly asked not to.
  tokenize: (code, options) ->
    code     : code.replace /(\r|\s+$)/g, ''
    o        : options or {}
    @code    : code         # The remainder of the source code.
    @i       : 0            # Current character position we're parsing.
    @line    : o.line or 0  # The current line.
    @indent  : 0            # The current indentation level.
    @outdebt : 0            # The under-outdentation of the last outdent.
    @indents : []           # The stack of all current indentation levels.
    @tokens  : []           # Stream of parsed tokens in the form ['TYPE', value, line]
    while @i < @code.length
      @chunk: @code.slice @i
      @extractNextToken()
    @closeIndentation()
    return @tokens if o.rewrite is off
    (new Rewriter()).rewrite @tokens

  # At every position, run through this list of attempted matches,
  # short-circuiting if any of them succeed. Their order determines precedence:
  # `@literalToken` is the fallback catch-all.
  extractNextToken: ->
    return if @identifierToken()
    return if @commentToken()
    return if @whitespaceToken()
    return if @lineToken()
    return if @heredocToken()
    return if @stringToken()
    return if @numberToken()
    return if @regexToken()
    return if @jsToken()
    return    @literalToken()

  # Tokenizers
  # ----------

  # Matches identifying literals: variables, keywords, method names, etc.
  # Check to ensure that JavaScript reserved words aren't being used as
  # identifiers. Because CoffeeScript reserves a handful of keywords that are
  # allowed in JavaScript, we're careful not to tag them as keywords when
  # referenced as property names here, so you can still do `jQuery.is()` even
  # though `is` means `===` otherwise.
  identifierToken: ->
    return false unless id: @match IDENTIFIER, 1
    @i: + id.length
    forcedIdentifier: @tagAccessor() or @match ASSIGNED, 1
    tag: 'IDENTIFIER'
    tag: id.toUpperCase() if include(JS_KEYWORDS, id) or (not forcedIdentifier and include(COFFEE_KEYWORDS, id))
    tag: 'LEADING_WHEN'   if tag is 'WHEN' and include LINE_BREAK, @tag()
    if include(JS_FORBIDDEN, id)
      if forcedIdentifier
        tag: 'STRING'
        id:  "'$id'"
        if forcedIdentifier is 'accessor'
          close_index: true
          @tokens.pop() if @tag() isnt '@'
          @token 'INDEX_START', '['
      else if include(RESERVED, id)
        @identifierError id
    unless forcedIdentifier
      tag: id: CONVERSIONS[id]         if include COFFEE_ALIASES, id
      return @tagHalfAssignment tag  if @prev() and @prev()[0] is 'ASSIGN' and include HALF_ASSIGNMENTS, tag
    @token tag, id
    @token ']', ']' if close_index
    true

  # Matches numbers, including decimals, hex, and exponential notation.
  # Be careful not to interfere with ranges-in-progress.
  numberToken: ->
    return false unless number: @match NUMBER, 1
    return false if @tag() is '.' and starts number, '.'
    @i: + number.length
    @token 'NUMBER', number
    true

  # Matches strings, including multi-line strings. Ensures that quotation marks
  # are balanced within the string's contents, and within nested interpolations.
  stringToken: ->
    return false unless starts(@chunk, '"') or starts(@chunk, "'")
    return false unless string:
      @balancedToken(['"', '"'], ['${', '}']) or
      @balancedToken ["'", "'"]
    @interpolateString string.replace STRING_NEWLINES, " \\\n"
    @line: + count string, "\n"
    @i: + string.length
    true

  # Matches heredocs, adjusting indentation to the correct level, as heredocs
  # preserve whitespace, but ignore indentation to the left.
  heredocToken: ->
    return false unless match: @chunk.match(HEREDOC)
    quote: match[1].substr 0, 1
    doc: @sanitizeHeredoc match[2] or match[4], {quote}
    @interpolateString "$quote$doc$quote"
    @line: + count match[1], "\n"
    @i: + match[1].length
    true

  # Matches and conumes comments.
  commentToken: ->
    return false unless match: @chunk.match(COMMENT)
    @line: + count match[1], "\n"
    @i: + match[1].length
    true

  # Matches JavaScript interpolated directly into the source via backticks.
  jsToken: ->
    return false unless starts @chunk, '`'
    return false unless script: @balancedToken ['`', '`']
    @token 'JS', script.replace JS_CLEANER, ''
    @i: + script.length
    true

  # Matches regular expression literals. Lexing regular expressions is difficult
  # to distinguish from division, so we borrow some basic heuristics from
  # JavaScript and Ruby, borrow slash balancing from `@balancedToken`, and
  # borrow interpolation from `@interpolateString`.
  regexToken: ->
    return false unless @chunk.match REGEX_START
    return false if     include NOT_REGEX, @tag()
    return false unless regex: @balancedToken ['/', '/']
    return false unless end: @chunk.substr(regex.length).match REGEX_END
    regex: + flags: end[2] if end[2]
    if regex.match REGEX_INTERPOLATION
      str: regex.substring(1).split('/')[0]
      str: str.replace REGEX_ESCAPE, (escaped) -> '\\' + escaped
      @tokens: @tokens.concat [['(', '('], ['NEW', 'new'], ['IDENTIFIER', 'RegExp'], ['CALL_START', '(']]
      @interpolateString "\"$str\"", yes
      @tokens: @tokens.concat [[',', ','], ['STRING', "\"$flags\""], [')', ')'], [')', ')']]
    else
      @token 'REGEX', regex
    @i: + regex.length
    true

  # Matches a token in which which the passed delimiter pairs must be correctly
  # balanced (ie. strings, JS literals).
  balancedToken: (delimited...) ->
    balancedString @chunk, delimited

  # Matches newlines, indents, and outdents, and determines which is which.
  # If we can detect that the current line is continued onto the the next line,
  # then the newline is suppressed:
  #
  #     elements
  #       .each( ... )
  #       .map( ... )
  #
  # Keeps track of the level of indentation, because a single outdent token
  # can close multiple indents, so we need to know how far in we happen to be.
  lineToken: ->
    return false unless indent: @match MULTI_DENT, 1
    @line: + count indent, "\n"
    @i   : + indent.length
    prev: @prev(2)
    size: indent.match(LAST_DENTS).reverse()[0].match(LAST_DENT)[1].length
    nextCharacter: @match NEXT_CHARACTER, 1
    noNewlines: nextCharacter is '.' or nextCharacter is ',' or @unfinished()
    if size is @indent
      return @suppressNewlines() if noNewlines
      return @newlineToken indent
    else if size > @indent
      return @suppressNewlines() if noNewlines
      diff: size - @indent
      @token 'INDENT', diff
      @indents.push diff
    else
      @outdentToken @indent - size, noNewlines
    @indent: size
    true

  # Record an outdent token or multiple tokens, if we happen to be moving back
  # inwards past several recorded indents.
  outdentToken: (moveOut, noNewlines) ->
    if moveOut > -@outdebt
      while moveOut > 0 and @indents.length
        lastIndent: @indents.pop()
        @token 'OUTDENT', lastIndent
        moveOut: - lastIndent
    else
      @outdebt: + moveOut
    @outdebt: moveOut unless noNewlines
    @token 'TERMINATOR', "\n" unless @tag() is 'TERMINATOR' or noNewlines
    true

  # Matches and consumes non-meaningful whitespace. Tag the previous token
  # as being "spaced", because there are some cases where it makes a difference.
  whitespaceToken: ->
    return false unless space: @match WHITESPACE, 1
    prev: @prev()
    prev.spaced: true if prev
    @i: + space.length
    true

  # Generate a newline token. Consecutive newlines get merged together.
  newlineToken: (newlines) ->
    @token 'TERMINATOR', "\n" unless @tag() is 'TERMINATOR'
    true

  # Use a `\` at a line-ending to suppress the newline.
  # The slash is removed here once its job is done.
  suppressNewlines: ->
    @tokens.pop() if @value() is "\\"
    true

  # We treat all other single characters as a token. Eg.: `( ) , . !`
  # Multi-character operators are also literal tokens, so that Jison can assign
  # the proper order of operations. There are some symbols that we tag specially
  # here. `;` and newlines are both treated as a `TERMINATOR`, we distinguish
  # parentheses that indicate a method call from regular parentheses, and so on.
  literalToken: ->
    match: @chunk.match OPERATOR
    value: match and match[1]
    space: match and match[2]
    @tagParameters() if value and value.match CODE
    value: or @chunk.substr 0, 1
    prevSpaced: @prev() and @prev().spaced
    tag: value
    if value.match ASSIGNMENT
      tag: 'ASSIGN'
      @assignmentError() if include JS_FORBIDDEN, @value
    else if value is ';'
      tag: 'TERMINATOR'
    else if include(CALLABLE, @tag()) and not prevSpaced
      if value is '('
        tag: 'CALL_START'
      else if value is '['
        tag: 'INDEX_START'
        @tag 1, 'INDEX_SOAK'  if @tag() is '?'
        @tag 1, 'INDEX_PROTO' if @tag() is '::'
    @i: + value.length
    return @tagHalfAssignment tag if space and prevSpaced and @prev()[0] is 'ASSIGN' and include HALF_ASSIGNMENTS, tag
    @token tag, value
    true

  # Token Manipulators
  # ------------------

  # As we consume a new `IDENTIFIER`, look at the previous token to determine
  # if it's a special kind of accessor. Return `true` if any type of accessor
  # is the previous token.
  tagAccessor: ->
    return false if (not prev: @prev()) or (prev and prev.spaced)
    accessor: if prev[1] is '::'
      @tag 1, 'PROTOTYPE_ACCESS'
    else if prev[1] is '.' and not (@value(2) is '.')
      if @tag(2) is '?'
        @tag(1, 'SOAK_ACCESS')
        @tokens.splice(-2, 1)
      else
        @tag 1, 'PROPERTY_ACCESS'
    else
      prev[0] is '@'
    if accessor then 'accessor' else false

  # Sanitize a heredoc by escaping internal double quotes and
  # erasing all external indentation on the left-hand side.
  sanitizeHeredoc: (doc, options) ->
    while match: HEREDOC_INDENT.exec doc
      attempt: if match[2]? then match[2] else match[3]
      indent: attempt if not indent or attempt.length < indent.length
    doc.replace(new RegExp("^" +indent, 'gm'), '')
       .replace(MULTILINER, "\\n")
       .replace(new RegExp(options.quote, 'g'), "\\$options.quote")

  # Tag a half assignment.
  tagHalfAssignment: (tag) ->
    last: @tokens.pop()
    @tokens.push ["$tag=", "$tag=", last[2]]
    true

  # A source of ambiguity in our grammar used to be parameter lists in function
  # definitions versus argument lists in function calls. Walk backwards, tagging
  # parameters specially in order to make things easier for the parser.
  tagParameters: ->
    return if @tag() isnt ')'
    i: 0
    loop
      i: + 1
      tok: @prev i
      return if not tok
      switch tok[0]
        when 'IDENTIFIER'       then tok[0]: 'PARAM'
        when ')'                then tok[0]: 'PARAM_END'
        when '(', 'CALL_START'  then return tok[0]: 'PARAM_START'
    true

  # Close up all remaining open blocks at the end of the file.
  closeIndentation: ->
    @outdentToken @indent

  # The error for when you try to use a forbidden word in JavaScript as
  # an identifier.
  identifierError: (word) ->
    throw new Error "SyntaxError: Reserved word \"$word\" on line ${@line + 1}"

  # The error for when you try to assign to a reserved word in JavaScript,
  # like "function" or "default".
  assignmentError: ->
    throw new Error "SyntaxError: Reserved word \"${@value()}\" on line ${@line + 1} can't be assigned"

  # Expand variables and expressions inside double-quoted strings using
  # [ECMA Harmony's interpolation syntax](http://wiki.ecmascript.org/doku.php?id=strawman:string_interpolation)
  # for substitution of bare variables as well as arbitrary expressions.
  #
  #     "Hello $name."
  #     "Hello ${name.capitalize()}."
  #
  # If it encounters an interpolation, this method will recursively create a
  # new Lexer, tokenize the interpolated contents, and merge them into the
  # token stream.
  interpolateString: (str, escapeQuotes) ->
    if str.length < 3 or not starts str, '"'
      @token 'STRING', str
    else
      lexer:    new Lexer()
      tokens:   []
      quote:    str.substring 0, 1
      [i, pi]:  [1, 1]
      while i < str.length - 1
        if starts str, '\\', i
          i: + 1
        else if match: str.substring(i).match INTERPOLATION
          [group, interp]: match
          interp: "this.${ interp.substring(1) }" if starts interp, '@'
          tokens.push ['STRING', "$quote${ str.substring(pi, i) }$quote"] if pi < i
          tokens.push ['IDENTIFIER', interp]
          i: + group.length - 1
          pi: i + 1
        else if (expr: balancedString str.substring(i), [['${', '}']])
          tokens.push ['STRING', "$quote${ str.substring(pi, i) }$quote"] if pi < i
          inner: expr.substring(2, expr.length - 1)
          if inner.length
            nested: lexer.tokenize "($inner)", {line: @line}
            (tok[0]: ')') for tok, idx in nested when tok[0] is 'CALL_END'
            nested.pop()
            tokens.push ['TOKENS', nested]
          else
            tokens.push ['STRING', "$quote$quote"]
          i: + expr.length - 1
          pi: i + 1
        i: + 1
      tokens.push ['STRING', "$quote${ str.substring(pi, i) }$quote"] if pi < i and pi < str.length - 1
      tokens.unshift ['STRING', '""'] unless tokens[0][0] is 'STRING'
      interpolated: tokens.length > 1
      @token '(', '(' if interpolated
      for token, i in tokens
        [tag, value]: token
        if tag is 'TOKENS'
          @tokens: @tokens.concat value
        else if tag is 'STRING' and escapeQuotes
          escaped: value.substring(1, value.length - 1).replace(/"/g, '\\"')
          @token tag, "\"$escaped\""
        else
          @token tag, value
        @token '+', '+' if i < tokens.length - 1
      @token ')', ')' if interpolated
      tokens

  # Helpers
  # -------

  # Add a token to the results, taking note of the line number.
  token: (tag, value) ->
    @tokens.push [tag, value, @line]

  # Peek at a tag in the current token stream.
  tag: (index, newTag) ->
    return unless tok: @prev index
    return tok[0]: newTag if newTag?
    tok[0]

  # Peek at a value in the current token stream.
  value: (index, val) ->
    return unless tok: @prev index
    return tok[1]: val if val?
    tok[1]

  # Peek at a previous token, entire.
  prev: (index) ->
    @tokens[@tokens.length - (index or 1)]

  # Attempt to match a string against the current chunk, returning the indexed
  # match if successful, and `false` otherwise.
  match: (regex, index) ->
    return false unless m: @chunk.match regex
    if m then m[index] else false

  # Are we in the midst of an unfinished expression?
  unfinished: ->
    prev: @prev(2)
    @value() and @value().match and @value().match(NO_NEWLINE) and
      prev and (prev[0] isnt '.') and not @value().match(CODE)

# Constants
# ---------

# Keywords that CoffeeScript shares in common with JavaScript.
JS_KEYWORDS: [
  "if", "else",
  "true", "false",
  "new", "return",
  "try", "catch", "finally", "throw",
  "break", "continue",
  "for", "in", "while",
  "delete", "instanceof", "typeof",
  "switch", "super", "extends", "class",
  "this", "null"
]

# CoffeeScript-only keywords, which we're more relaxed about allowing. They can't
# be used standalone, but you can reference them as an attached property.
COFFEE_ALIASES:  ["and", "or", "is", "isnt", "not"]
COFFEE_KEYWORDS: COFFEE_ALIASES.concat [
  "then", "unless", "until", "loop",
  "yes", "no", "on", "off",
  "of", "by", "where", "when"
]

# The list of keywords that are reserved by JavaScript, but not used, or are
# used by CoffeeScript internally. We throw an error when these are encountered,
# to avoid having a JavaScript error at runtime.
RESERVED: [
  "case", "default", "do", "function", "var", "void", "with"
  "const", "let", "enum", "export", "import", "native"
]

# The superset of both JavaScript keywords and reserved words, none of which may
# be used as identifiers or properties.
JS_FORBIDDEN: JS_KEYWORDS.concat RESERVED

# Token matching regexes.
IDENTIFIER    : /^([a-zA-Z\$_](\w|\$)*)/
NUMBER        : /^(((\b0(x|X)[0-9a-fA-F]+)|((\b[0-9]+(\.[0-9]+)?|\.[0-9]+)(e[+\-]?[0-9]+)?)))\b/i
HEREDOC       : /^("{6}|'{6}|"{3}\n?([\s\S]*?)\n?([ \t]*)"{3}|'{3}\n?([\s\S]*?)\n?([ \t]*)'{3})/
INTERPOLATION : /^\$([a-zA-Z_@]\w*(\.\w+)*)/
OPERATOR      : /^([+\*&|\/\-%=<>:!?]+)([ \t]*)/
WHITESPACE    : /^([ \t]+)/
COMMENT       : /^(\s*#{3}(?!#)[ \t]*\n+([\s\S]*?)[ \t]*\n+[ \t]*#{3}|(\s*#[^\n]*)+)/
CODE          : /^((-|=)>)/
MULTI_DENT    : /^((\n([ \t]*))+)(\.)?/
LAST_DENTS    : /\n([ \t]*)/g
LAST_DENT     : /\n([ \t]*)/
ASSIGNMENT    : /^[:=]$/

# Regex-matching-regexes.
REGEX_START        : /^\/[^\/ ]/
REGEX_INTERPOLATION: /([^\\]\$[a-zA-Z_@]|[^\\]\$\{.*[^\\]\})/
REGEX_END          : /^(([imgy]{1,4})\b|\W|$)/
REGEX_ESCAPE       : /\\[^\$]/g

# Token cleaning regexes.
JS_CLEANER      : /(^`|`$)/g
MULTILINER      : /\n/g
STRING_NEWLINES : /\n[ \t]*/g
NO_NEWLINE      : /^([+\*&|\/\-%=<>:!.\\][<>=&|]*|and|or|is|isnt|not|delete|typeof|instanceof)$/
HEREDOC_INDENT  : /(\n+([ \t]*)|^([ \t]+))/g
ASSIGNED        : /^([a-zA-Z\$_]\w*[ \t]*?[:=])/
NEXT_CHARACTER  : /^\s*(\S)/

# Tokens which a regular expression will never immediately follow, but which
# a division operator might.
#
# See: http://www.mozilla.org/js/language/js20-2002-04/rationale/syntax.html#regular-expressions
#
# Our list is shorter, due to sans-parentheses method calls.
NOT_REGEX: [
  'NUMBER', 'REGEX', '++', '--', 'FALSE', 'NULL', 'TRUE', ']'
]

# Tokens which could legitimately be invoked or indexed. A opening
# parentheses or bracket following these tokens will be recorded as the start
# of a function invocation or indexing operation.
CALLABLE: ['IDENTIFIER', 'SUPER', ')', ']', '}', 'STRING', '@', 'THIS', '?', '::']

# Tokens that, when immediately preceding a `WHEN`, indicate that the `WHEN`
# occurs at the start of a line. We disambiguate these from trailing whens to
# avoid an ambiguity in the grammar.
LINE_BREAK: ['INDENT', 'OUTDENT', 'TERMINATOR']

# Half-assignments...
HALF_ASSIGNMENTS: ['-', '+', '/', '*', '%', '||', '&&', '?']

# Conversions from CoffeeScript operators into JavaScript ones.
CONVERSIONS: {
  'and':  '&&'
  'or':   '||'
  'is':   '=='
  'isnt': '!='
  'not':  '!'
}
