# The CoffeeScript Lexer. Uses a series of token-matching regexes to attempt
# matches against the beginning of the source code. When a match is found,
# a token is produced, we consume the match, and start again. Tokens are in the
# form:
#
#     [tag, value, locationData]
#
# where locationData is {first_line, first_column, last_line, last_column}, which is a
# format that can be fed directly into [Jison](http://github.com/zaach/jison).  These
# are read by jison in the `parser.lexer` function defined in coffee-script.coffee.

{Rewriter, INVERSES} = require './rewriter'

# Import the helpers we need.
{count, starts, compact, last, repeat, invertLiterate,
locationDataToString,  throwSyntaxError} = require './helpers'

# The Lexer Class
# ---------------

# The Lexer class reads a stream of CoffeeScript and divvies it up into tagged
# tokens. Some potential ambiguity in the grammar has been avoided by
# pushing some extra smarts into the Lexer.
exports.Lexer = class Lexer

  # **tokenize** is the Lexer's main method. Scan by attempting to match tokens
  # one at a time, using a regular expression anchored at the start of the
  # remaining code, or a custom recursive token-matching method
  # (for interpolations). When the next token has been recorded, we move forward
  # within the code past the token, and begin again.
  #
  # Each tokenizing method is responsible for returning the number of characters
  # it has consumed.
  #
  # Before returning the token stream, run it through the [Rewriter](rewriter.html).
  tokenize: (code, opts = {}) ->
    @literate   = opts.literate  # Are we lexing literate CoffeeScript?
    @indent     = 0              # The current indentation level.
    @baseIndent = 0              # The overall minimum indentation level
    @indebt     = 0              # The over-indentation at the current level.
    @outdebt    = 0              # The under-outdentation at the current level.
    @indents    = []             # The stack of all current indentation levels.
    @ends       = []             # The stack for pairing up tokens.
    @tokens     = []             # Stream of parsed tokens in the form `['TYPE', value, location data]`.

    @chunkLine =
      opts.line or 0         # The start line for the current @chunk.
    @chunkColumn =
      opts.column or 0       # The start column of the current @chunk.
    code = @clean code         # The stripped, cleaned original source code.

    # At every position, run through this list of attempted matches,
    # short-circuiting if any of them succeed. Their order determines precedence:
    # `@literalToken` is the fallback catch-all.
    i = 0
    while @chunk = code[i..]
      consumed = \
           @identifierToken() or
           @commentToken()    or
           @whitespaceToken() or
           @lineToken()       or
           @stringToken()     or
           @numberToken()     or
           @regexToken()      or
           @jsToken()         or
           @literalToken()

      # Update position
      [@chunkLine, @chunkColumn] = @getLineAndColumnFromChunk consumed

      i += consumed

      return {@tokens, index: i} if opts.untilBalanced and @ends.length is 0

    @closeIndentation()
    throwSyntaxError "missing #{end.tag}", end.origin[2] if end = @ends.pop()
    return @tokens if opts.rewrite is off
    (new Rewriter).rewrite @tokens

  # Preprocess the code to remove leading and trailing whitespace, carriage
  # returns, etc. If we're lexing literate CoffeeScript, strip external Markdown
  # by removing all lines that aren't indented by at least four spaces or a tab.
  clean: (code) ->
    code = code.slice(1) if code.charCodeAt(0) is BOM
    code = code.replace(/\r/g, '').replace TRAILING_SPACES, ''
    if WHITESPACE.test code
      code = "\n#{code}"
      @chunkLine--
    code = invertLiterate code if @literate
    code

  # Tokenizers
  # ----------

  # Matches identifying literals: variables, keywords, method names, etc.
  # Check to ensure that JavaScript reserved words aren't being used as
  # identifiers. Because CoffeeScript reserves a handful of keywords that are
  # allowed in JavaScript, we're careful not to tag them as keywords when
  # referenced as property names here, so you can still do `jQuery.is()` even
  # though `is` means `===` otherwise.
  identifierToken: ->
    return 0 unless match = IDENTIFIER.exec @chunk
    [input, id, colon] = match

    # Preserve length of id for location data
    idLength = id.length
    poppedToken = undefined

    if id is 'own' and @tag() is 'FOR'
      @token 'OWN', id
      return id.length
    if id is 'from' and @tag() is 'YIELD'
      @token 'FROM', id
      return id.length
    forcedIdentifier = colon or
      (prev = last @tokens) and (prev[0] in ['.', '?.', '::', '?::'] or
      not prev.spaced and prev[0] is '@')
    tag = 'IDENTIFIER'

    if not forcedIdentifier and (id in JS_KEYWORDS or id in COFFEE_KEYWORDS)
      tag = id.toUpperCase()
      if tag is 'WHEN' and @tag() in LINE_BREAK
        tag = 'LEADING_WHEN'
      else if tag is 'FOR'
        @seenFor = yes
      else if tag is 'UNLESS'
        tag = 'IF'
      else if tag in UNARY
        tag = 'UNARY'
      else if tag in RELATION
        if tag isnt 'INSTANCEOF' and @seenFor
          tag = 'FOR' + tag
          @seenFor = no
        else
          tag = 'RELATION'
          if @value() is '!'
            poppedToken = @tokens.pop()
            id = '!' + id

    if id in JS_FORBIDDEN
      if forcedIdentifier
        tag = 'IDENTIFIER'
        id  = new String id
        id.reserved = yes
      else if id in RESERVED
        @error "reserved word \"#{id}\""

    unless forcedIdentifier
      id  = COFFEE_ALIAS_MAP[id] if id in COFFEE_ALIASES
      tag = switch id
        when '!'                 then 'UNARY'
        when '==', '!='          then 'COMPARE'
        when '&&', '||'          then 'LOGIC'
        when 'true', 'false'     then 'BOOL'
        when 'break', 'continue' then 'STATEMENT'
        else  tag

    tagToken = @token tag, id, 0, idLength
    tagToken.variable = not forcedIdentifier
    if poppedToken
      [tagToken[2].first_line, tagToken[2].first_column] =
        [poppedToken[2].first_line, poppedToken[2].first_column]
    if colon
      colonOffset = input.lastIndexOf ':'
      @token ':', ':', colonOffset, colon.length

    input.length

  # Matches numbers, including decimals, hex, and exponential notation.
  # Be careful not to interfere with ranges-in-progress.
  numberToken: ->
    return 0 unless match = NUMBER.exec @chunk
    number = match[0]
    if /^0[BOX]/.test number
      @error "radix prefix '#{number}' must be lowercase"
    else if /E/.test(number) and not /^0x/.test number
      @error "exponential notation '#{number}' must be indicated with a lowercase 'e'"
    else if /^0\d*[89]/.test number
      @error "decimal literal '#{number}' must not be prefixed with '0'"
    else if /^0\d+/.test number
      @error "octal literal '#{number}' must be prefixed with '0o'"
    lexedLength = number.length
    if octalLiteral = /^0o([0-7]+)/.exec number
      number = '0x' + parseInt(octalLiteral[1], 8).toString 16
    if binaryLiteral = /^0b([01]+)/.exec number
      number = '0x' + parseInt(binaryLiteral[1], 2).toString 16
    @token 'NUMBER', number, 0, lexedLength
    lexedLength

  # Matches strings, including multi-line strings, as well as heredocs, with or without
  # interpolation.
  stringToken: ->
    [quote] = STRING_START.exec(@chunk) || []
    return 0 unless quote
    regex = switch quote
      when "'"   then STRING_SINGLE
      when '"'   then STRING_DOUBLE
      when "'''" then HEREDOC_SINGLE
      when '"""' then HEREDOC_DOUBLE
    heredoc = quote.length is 3

    start = quote.length
    {tokens, index: end} = @matchWithInterpolations @chunk[start..], regex, quote, start
    $ = tokens.length - 1

    if heredoc
      # Find the smallest indentation. It will be removed from all lines later.
      indent = null
      doc = (token[1] for token, i in tokens when token[0] is 'NEOSTRING').join '#{}'
      while match = HEREDOC_INDENT.exec doc
        attempt = match[1]
        indent = attempt if indent is null or 0 < attempt.length < indent.length
      indentRegex = /// ^#{indent} ///gm if indent
      @mergeInterpolationTokens tokens, {quote: quote[0], start, end}, (value, i) =>
        value = @formatString value
        value = value.replace LEADING_BLANK_LINE,  '' if i is 0
        value = value.replace TRAILING_BLANK_LINE, '' if i is $
        value = value.replace indentRegex, ''
        value = value.replace MULTILINER, '\\n'
        value
    else
      @mergeInterpolationTokens tokens, {quote, start, end}, (value, i) =>
        value = @formatString value
        value = value.replace STRING_OMIT, (match, offset) ->
          if (i is 0 and offset is 0) or
             (i is $ and offset + match.length is value.length)
            ''
          else
            ' '
        value

    end

  # Matches and consumes comments.
  commentToken: ->
    return 0 unless match = @chunk.match COMMENT
    [comment, here] = match
    if here
      if match = HERECOMMENT_ILLEGAL.exec comment
        @error "block comments cannot contain #{match[0]}", match.index
      if here.indexOf('\n') >= 0
        here = here.replace /// \n #{repeat ' ', @indent} ///g, '\n'
      @token 'HERECOMMENT', here, 0, comment.length
    comment.length

  # Matches JavaScript interpolated directly into the source via backticks.
  jsToken: ->
    return 0 unless @chunk.charAt(0) is '`' and match = JSTOKEN.exec @chunk
    @token 'JS', (script = match[0])[1...-1], 0, script.length
    script.length

  # Matches regular expression literals, as well as multiline extended ones.
  # Lexing regular expressions is difficult to distinguish from division, so we
  # borrow some basic heuristics from JavaScript and Ruby.
  regexToken: ->
    switch
      when match = REGEX_ILLEGAL.exec @chunk
        @error "regular expressions cannot begin with #{match[2]}", match.index + match[1].length
      when @chunk[...3] is '///'
        {tokens, index} = @matchWithInterpolations @chunk[3..], HEREGEX, '///', 3
      when match = REGEX.exec @chunk
        [regex, closed] = match
        index = regex.length
        prev = last @tokens
        if prev
          if prev.spaced and prev[0] in CALLABLE and not prev.stringEnd and not prev.regexEnd
            return 0 if not closed or POSSIBLY_DIVISION.test regex
          else if prev[0] in NOT_REGEX
            return 0
        @error 'missing / (unclosed regex)' unless closed
      else
        return 0

    [flags] = REGEX_FLAGS.exec @chunk[index..]
    end = index + flags.length
    switch
      when not VALID_FLAGS.test flags
        @error "invalid regular expression flags #{flags}", index
      when regex
        @token 'REGEX', "#{regex}#{flags}"
      when tokens.length is 1
        re = @formatHeregex(tokens[0][1]).replace(/\//g, '\\/')
        @token 'REGEX', "/#{ re or '(?:)' }/#{flags}"
      else
        @token 'IDENTIFIER', 'RegExp', 0, 0
        @token 'CALL_START', '(', 0, 0
        @mergeInterpolationTokens tokens, {quote: '"', start: 3, end}, (value) =>
          @formatHeregex(value).replace(/\\/g, '\\\\')
        if flags
          @token ',', ',', index, 0
          @token 'STRING', '"' + flags + '"', index, flags.length
        rparen = @token ')', ')', end, 0
        rparen.regexEnd = true

    end

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
    return 0 unless match = MULTI_DENT.exec @chunk
    indent = match[0]
    @seenFor = no
    size = indent.length - 1 - indent.lastIndexOf '\n'
    noNewlines = @unfinished()
    if size - @indebt is @indent
      if noNewlines then @suppressNewlines() else @newlineToken 0
      return indent.length

    if size > @indent
      if noNewlines
        @indebt = size - @indent
        @suppressNewlines()
        return indent.length
      unless @tokens.length
        @baseIndent = @indent = size
        return indent.length
      diff = size - @indent + @outdebt
      @token 'INDENT', diff, indent.length - size, size
      @indents.push diff
      @ends.push {tag: 'OUTDENT'}
      @outdebt = @indebt = 0
      @indent = size
    else if size < @baseIndent
      @error 'missing indentation', indent.length
    else
      @indebt = 0
      @outdentToken @indent - size, noNewlines, indent.length
    indent.length

  # Record an outdent token or multiple tokens, if we happen to be moving back
  # inwards past several recorded indents. Sets new @indent value.
  outdentToken: (moveOut, noNewlines, outdentLength) ->
    decreasedIndent = @indent - moveOut
    while moveOut > 0
      lastIndent = @indents[@indents.length - 1]
      if not lastIndent
        moveOut = 0
      else if lastIndent is @outdebt
        moveOut -= @outdebt
        @outdebt = 0
      else if lastIndent < @outdebt
        @outdebt -= lastIndent
        moveOut  -= lastIndent
      else
        dent = @indents.pop() + @outdebt
        if outdentLength and @chunk[outdentLength] in INDENTABLE_CLOSERS
          decreasedIndent -= dent - moveOut
          moveOut = dent
        @outdebt = 0
        # pair might call outdentToken, so preserve decreasedIndent
        @pair 'OUTDENT'
        @token 'OUTDENT', moveOut, 0, outdentLength
        moveOut -= dent
    @outdebt -= moveOut if dent
    @tokens.pop() while @value() is ';'

    @token 'TERMINATOR', '\n', outdentLength, 0 unless @tag() is 'TERMINATOR' or noNewlines
    @indent = decreasedIndent
    this

  # Matches and consumes non-meaningful whitespace. Tag the previous token
  # as being "spaced", because there are some cases where it makes a difference.
  whitespaceToken: ->
    return 0 unless (match = WHITESPACE.exec @chunk) or
                    (nline = @chunk.charAt(0) is '\n')
    prev = last @tokens
    prev[if match then 'spaced' else 'newLine'] = true if prev
    if match then match[0].length else 0

  # Generate a newline token. Consecutive newlines get merged together.
  newlineToken: (offset) ->
    @tokens.pop() while @value() is ';'
    @token 'TERMINATOR', '\n', offset, 0 unless @tag() is 'TERMINATOR'
    this

  # Use a `\` at a line-ending to suppress the newline.
  # The slash is removed here once its job is done.
  suppressNewlines: ->
    @tokens.pop() if @value() is '\\'
    this

  # We treat all other single characters as a token. E.g.: `( ) , . !`
  # Multi-character operators are also literal tokens, so that Jison can assign
  # the proper order of operations. There are some symbols that we tag specially
  # here. `;` and newlines are both treated as a `TERMINATOR`, we distinguish
  # parentheses that indicate a method call from regular parentheses, and so on.
  literalToken: ->
    if match = OPERATOR.exec @chunk
      [value] = match
      @tagParameters() if CODE.test value
    else
      value = @chunk.charAt 0
    tag  = value
    prev = last @tokens
    if value is '=' and prev
      if not prev[1].reserved and prev[1] in JS_FORBIDDEN
        @error "reserved word \"#{@value()}\" can't be assigned"
      if prev[1] in ['||', '&&']
        prev[0] = 'COMPOUND_ASSIGN'
        prev[1] += '='
        return value.length
    if value is ';'
      @seenFor = no
      tag = 'TERMINATOR'
    else if value in MATH            then tag = 'MATH'
    else if value in COMPARE         then tag = 'COMPARE'
    else if value in COMPOUND_ASSIGN then tag = 'COMPOUND_ASSIGN'
    else if value in UNARY           then tag = 'UNARY'
    else if value in UNARY_MATH      then tag = 'UNARY_MATH'
    else if value in SHIFT           then tag = 'SHIFT'
    else if value in LOGIC or value is '?' and prev?.spaced then tag = 'LOGIC'
    else if prev and not prev.spaced
      if value is '(' and prev[0] in CALLABLE and not prev.stringEnd and not prev.regexEnd
        prev[0] = 'FUNC_EXIST' if prev[0] is '?'
        tag = 'CALL_START'
      else if value is '[' and prev[0] in INDEXABLE
        tag = 'INDEX_START'
        switch prev[0]
          when '?'  then prev[0] = 'INDEX_SOAK'
    token = @makeToken tag, value
    switch value
      when '(', '{', '[' then @ends.push {tag: INVERSES[value], origin: token}
      when ')', '}', ']' then @pair value
    @tokens.push token
    value.length

  # Token Manipulators
  # ------------------

  # A source of ambiguity in our grammar used to be parameter lists in function
  # definitions versus argument lists in function calls. Walk backwards, tagging
  # parameters specially in order to make things easier for the parser.
  tagParameters: ->
    return this if @tag() isnt ')'
    stack = []
    {tokens} = this
    i = tokens.length
    tokens[--i][0] = 'PARAM_END'
    while tok = tokens[--i]
      switch tok[0]
        when ')'
          stack.push tok
        when '(', 'CALL_START'
          if stack.length then stack.pop()
          else if tok[0] is '('
            tok[0] = 'PARAM_START'
            return this
          else return this
    this

  # Close up all remaining open blocks at the end of the file.
  closeIndentation: ->
    @outdentToken @indent

  # Match the contents of a delimited token and expand variables and expressions
  # inside it using Ruby-like notation for substitution of arbitrary
  # expressions.
  #
  #     "Hello #{name.capitalize()}."
  #
  # If it encounters an interpolation, this method will recursively create a new
  # Lexer and tokenize until the `{` of `#{` is balanced with a `}`.
  #
  #  - `str` is the start of the token contents (with the starting delimiter
  #    stripped off.)
  #  - `regex` matches the contents of a token (but not `end`, and not `#{` if
  #    interpolations are desired).
  #  - `end` is the terminator of the token.
  #  - `offsetInChunk` is the start of the interpolated string in the current
  #    chunk, including the starting delimiter.
  #
  # Examples of delimiters are `'`, `"`, `'''`, `"""` and `///`.
  #
  # This method allows us to have strings within interpolations within strings,
  # ad infinitum.
  matchWithInterpolations: (str, regex, end, offsetInChunk) ->
    tokens = []
    loop
      [strPart] = regex.exec str

      # Push a fake 'NEOSTRING' token, which will get turned into a real string later.
      tokens.push @makeToken 'NEOSTRING', strPart, offsetInChunk

      str = str[strPart.length..]
      offsetInChunk += strPart.length

      break unless str[...2] is '#{'

      # The `1`s are to remove the `#` in `#{`.
      [line, column] = @getLineAndColumnFromChunk offsetInChunk + 1
      {tokens: nested, index} =
        new Lexer().tokenize str[1..], line: line, column: column, untilBalanced: on
      # Skip the trailing `}`.
      index += 1

      # Turn the leading and trailing `{` and `}` into parentheses. Unnecessary
      # parentheses will be removed later.
      [open, ..., close] = nested
      open[0]  = open[1]  = '('
      close[0] = close[1] = ')'
      close.origin = ['', 'end of interpolation', close[2]]

      # Remove leading 'TERMINATOR' (if any).
      nested.splice 1, 1 if nested[1]?[0] is 'TERMINATOR'

      # Push a fake 'TOKENS' token, which will get turned into real tokens later.
      tokens.push ['TOKENS', nested]

      str = str[index..]
      offsetInChunk += index

    unless str[...end.length] is end
      @error "missing #{end}"

    {tokens, index: offsetInChunk + end.length}

  # Merge the array `tokens` of the fake token types 'TOKENS' and 'NEOSTRING'
  # (as returned by `matchWithInterpolations`) into the token stream. The value
  # of 'NEOSTRING's are converted using `fn` and turned into strings using
  # `quote` first.  The tokens are wrapped in parentheses if needed, using
  # `start` and `end` for their location data.
  mergeInterpolationTokens: (tokens, {quote, start, end}, fn) ->
    if interpolated = tokens.length > 1
      errorToken = @makeToken '', 'interpolation', start + tokens[0][1].length, 2
      @token '(', '(', 0, 0, errorToken

    firstIndex = @tokens.length
    for token, i in tokens
      [tag, value] = token
      switch tag
        when 'TOKENS'
          # Optimize out empty interpolations (an empty pair of parentheses).
          continue if value.length is 2
          # Push all the tokens in the fake 'TOKENS' token. These already have
          # sane location data.
          locationToken = value[0]
          tokensToPush = value
        when 'NEOSTRING'
          # Convert 'NEOSTRING' into 'STRING'.
          converted = fn token[1], i
          # Optimize out empty strings. We ensure that the tokens stream always
          # starts with a string token, though, to make sure that the result
          # really is a string.
          if converted.length is 0
            if i is 0
              firstEmptyStringIndex = @tokens.length
            else
              continue
          # However, there is one case where we can optimize away a starting
          # empty string.
          if i is 2 and firstEmptyStringIndex?
            @tokens.splice firstEmptyStringIndex, 2 # Remove empty string and the plus.
          token[0] = 'STRING'
          token[1] = @makeString converted, quote
          locationToken = token
          tokensToPush = [token]
      if @tokens.length > firstIndex
        # Create a 0-length "+" token.
        plusToken = @token '+', '+'
        plusToken[2] =
          first_line:   locationToken[2].first_line
          first_column: locationToken[2].first_column
          last_line:    locationToken[2].first_line
          last_column:  locationToken[2].first_column
      @tokens.push tokensToPush...

    if interpolated
      rparen = @token ')', ')', end, 0
      rparen.stringEnd = true

  # Pairs up a closing token, ensuring that all listed pairs of tokens are
  # correctly balanced throughout the course of the token stream.
  pair: (tag) ->
    unless tag is wanted = last(@ends)?.tag
      @error "unmatched #{tag}" unless 'OUTDENT' is wanted
      # Auto-close INDENT to support syntax like this:
      #
      #     el.click((event) ->
      #       el.hide())
      #
      @outdentToken last(@indents), true
      return @pair tag
    @ends.pop()

  # Helpers
  # -------

  # Returns the line and column number from an offset into the current chunk.
  #
  # `offset` is a number of characters into @chunk.
  getLineAndColumnFromChunk: (offset) ->
    if offset is 0
      return [@chunkLine, @chunkColumn]

    if offset >= @chunk.length
      string = @chunk
    else
      string = @chunk[..offset-1]

    lineCount = count string, '\n'

    column = @chunkColumn
    if lineCount > 0
      lines = string.split '\n'
      column = last(lines).length
    else
      column += string.length

    [@chunkLine + lineCount, column]

  # Same as "token", exception this just returns the token without adding it
  # to the results.
  makeToken: (tag, value, offsetInChunk = 0, length = value.length) ->
    locationData = {}
    [locationData.first_line, locationData.first_column] =
      @getLineAndColumnFromChunk offsetInChunk

    # Use length - 1 for the final offset - we're supplying the last_line and the last_column,
    # so if last_column == first_column, then we're looking at a character of length 1.
    lastCharacter = Math.max 0, length - 1
    [locationData.last_line, locationData.last_column] =
      @getLineAndColumnFromChunk offsetInChunk + lastCharacter

    token = [tag, value, locationData]

    token

  # Add a token to the results.
  # `offset` is the offset into the current @chunk where the token starts.
  # `length` is the length of the token in the @chunk, after the offset.  If
  # not specified, the length of `value` will be used.
  #
  # Returns the new token.
  token: (tag, value, offsetInChunk, length, origin) ->
    token = @makeToken tag, value, offsetInChunk, length
    token.origin = origin if origin
    @tokens.push token
    token

  # Peek at a tag in the current token stream.
  tag: (index, tag) ->
    (tok = last @tokens, index) and if tag then tok[0] = tag else tok[0]

  # Peek at a value in the current token stream.
  value: (index, val) ->
    (tok = last @tokens, index) and if val then tok[1] = val else tok[1]

  # Are we in the midst of an unfinished expression?
  unfinished: ->
    LINE_CONTINUER.test(@chunk) or
    @tag() in ['\\', '.', '?.', '?::', 'UNARY', 'MATH', 'UNARY_MATH', '+', '-', 'YIELD',
               '**', 'SHIFT', 'RELATION', 'COMPARE', 'LOGIC', 'THROW', 'EXTENDS']

  formatString: (str) ->
    # Ignore escaped backslashes and remove escaped newlines.
    str.replace /\\[^\S\n]*(\n|\\)\s*/g, (escaped, character) ->
      if character is '\n' then '' else escaped

  formatHeregex: (str) ->
    str.replace(HEREGEX_OMIT, '$1$2').replace(MULTILINER, '\\n')

  # Constructs a string token by escaping quotes.
  makeString: (body, quote) ->
    return quote + quote unless body
    # Ignore escaped backslashes and unescape quotes.
    body = body.replace /// \\( #{quote} | \\ ) ///g, (match, contents) ->
      if contents is quote then contents else match
    body = body.replace /// #{quote} ///g, '\\$&'
    if match = OCTAL_ESCAPE.exec body
      @error "octal escape sequences are not allowed #{match[2]}", match.index + match[1].length + 1
    quote + body + quote

  # Throws a compiler error on the current position.
  error: (message, offset = 0) ->
    # TODO: Are there some cases we could improve the error line number by
    # passing the offset in the chunk where the error happened?
    [first_line, first_column] = @getLineAndColumnFromChunk offset
    throwSyntaxError message, {first_line, first_column}

# Constants
# ---------

# Keywords that CoffeeScript shares in common with JavaScript.
JS_KEYWORDS = [
  'true', 'false', 'null', 'this'
  'new', 'delete', 'typeof', 'in', 'instanceof'
  'return', 'throw', 'break', 'continue', 'debugger', 'yield'
  'if', 'else', 'switch', 'for', 'while', 'do', 'try', 'catch', 'finally'
  'class', 'extends', 'super'
]

# CoffeeScript-only keywords.
COFFEE_KEYWORDS = ['undefined', 'then', 'unless', 'until', 'loop', 'of', 'by', 'when']

COFFEE_ALIAS_MAP =
  and  : '&&'
  or   : '||'
  is   : '=='
  isnt : '!='
  not  : '!'
  yes  : 'true'
  no   : 'false'
  on   : 'true'
  off  : 'false'

COFFEE_ALIASES  = (key for key of COFFEE_ALIAS_MAP)
COFFEE_KEYWORDS = COFFEE_KEYWORDS.concat COFFEE_ALIASES

# The list of keywords that are reserved by JavaScript, but not used, or are
# used by CoffeeScript internally. We throw an error when these are encountered,
# to avoid having a JavaScript error at runtime.
RESERVED = [
  'case', 'default', 'function', 'var', 'void', 'with', 'const', 'let', 'enum'
  'export', 'import', 'native', 'implements', 'interface', 'package', 'private'
  'protected', 'public', 'static'
]

STRICT_PROSCRIBED = ['arguments', 'eval', 'yield*']

# The superset of both JavaScript keywords and reserved words, none of which may
# be used as identifiers or properties.
JS_FORBIDDEN = JS_KEYWORDS.concat(RESERVED).concat(STRICT_PROSCRIBED)

exports.RESERVED = RESERVED.concat(JS_KEYWORDS).concat(COFFEE_KEYWORDS).concat(STRICT_PROSCRIBED)
exports.STRICT_PROSCRIBED = STRICT_PROSCRIBED

# The character code of the nasty Microsoft madness otherwise known as the BOM.
BOM = 65279

# Token matching regexes.
IDENTIFIER = /// ^
  (?!\d)
  ( (?: (?!\s)[$\w\x7f-\uffff] )+ )
  ( [^\n\S]* : (?!:) )?  # Is this a property name?
///

NUMBER     = ///
  ^ 0b[01]+    |              # binary
  ^ 0o[0-7]+   |              # octal
  ^ 0x[\da-f]+ |              # hex
  ^ \d*\.?\d+ (?:e[+-]?\d+)?  # decimal
///i

OPERATOR   = /// ^ (
  ?: [-=]>             # function
   | [-+*/%<>&|^!?=]=  # compound assign / compare
   | >>>=?             # zero-fill right shift
   | ([-+:])\1         # doubles
   | ([&|<>*/%])\2=?   # logic / shift / power / floor division / modulo
   | \?(\.|::)         # soak access
   | \.{2,3}           # range or splat
) ///

WHITESPACE = /^[^\n\S]+/

COMMENT    = /^###([^#][\s\S]*?)(?:###[^\n\S]*|###$)|^(?:\s*#(?!##[^#]).*)+/

CODE       = /^[-=]>/

MULTI_DENT = /^(?:\n[^\n\S]*)+/

JSTOKEN    = /^`[^\\`]*(?:\\.[^\\`]*)*`/

# String-matching-regexes.
STRING_START   = /^(?:'''|"""|'|")/

STRING_SINGLE  = /// ^(?: [^\\']  | \\[\s\S]                      )* ///
STRING_DOUBLE  = /// ^(?: [^\\"#] | \\[\s\S] |           \#(?!\{) )* ///
HEREDOC_SINGLE = /// ^(?: [^\\']  | \\[\s\S] | '(?!'')            )* ///
HEREDOC_DOUBLE = /// ^(?: [^\\"#] | \\[\s\S] | "(?!"") | \#(?!\{) )* ///

STRING_OMIT    = /\s*\n\s*/g
HEREDOC_INDENT = /\n+([^\n\S]*)(?=\S)/g

# Regex-matching-regexes.
REGEX = /// ^
  / (?!/) (
  ?: [^ [ / \n \\ ]  # every other thing
   | \\.             # anything (but newlines) escaped
   | \[              # character class
       (?: \\. | [^ \] \n \\ ] )*
     ]
  )* (/)?
///

REGEX_FLAGS  = /^\w*/
VALID_FLAGS  = /^(?!.*(.).*\1)[imgy]*$/

HEREGEX      = /// ^(?: [^\\/#] | \\[\s\S] | /(?!//) | \#(?!\{) )* ///

HEREGEX_OMIT = ///
    ((?:\\\\)+)     # consume (and preserve) an even number of backslashes
  | \\(\s|/)        # preserve escaped whitespace and "de-escape" slashes
  | \s+(?:#.*)?     # remove whitespace and comments
///g

REGEX_ILLEGAL = /// ^ ( / | /{3}\s*) (\*) ///

POSSIBLY_DIVISION   = /// ^ /=?\s ///

# Other regexes.
MULTILINER          = /\n/g

HERECOMMENT_ILLEGAL = /\*\//

LINE_CONTINUER      = /// ^ \s* (?: , | \??\.(?![.\d]) | :: ) ///

OCTAL_ESCAPE        = /// ^ ((?: \\. | [^\\] )*) (\\ (?: 0[0-7] | [1-7] )) ///

LEADING_BLANK_LINE  = /^[^\n\S]*\n/
TRAILING_BLANK_LINE = /\n[^\n\S]*$/

TRAILING_SPACES     = /\s+$/

# Compound assignment tokens.
COMPOUND_ASSIGN = [
  '-=', '+=', '/=', '*=', '%=', '||=', '&&=', '?=', '<<=', '>>=', '>>>='
  '&=', '^=', '|=', '**=', '//=', '%%='
]

# Unary tokens.
UNARY = ['NEW', 'TYPEOF', 'DELETE', 'DO']

UNARY_MATH = ['!', '~']

# Logical tokens.
LOGIC = ['&&', '||', '&', '|', '^']

# Bit-shifting tokens.
SHIFT = ['<<', '>>', '>>>']

# Comparison tokens.
COMPARE = ['==', '!=', '<', '>', '<=', '>=']

# Mathematical tokens.
MATH = ['*', '/', '%', '//', '%%']

# Relational tokens that are negatable with `not` prefix.
RELATION = ['IN', 'OF', 'INSTANCEOF']

# Boolean tokens.
BOOL = ['TRUE', 'FALSE']

# Tokens which could legitimately be invoked or indexed. An opening
# parentheses or bracket following these tokens will be recorded as the start
# of a function invocation or indexing operation.
CALLABLE  = ['IDENTIFIER', ')', ']', '?', '@', 'THIS', 'SUPER']
INDEXABLE = CALLABLE.concat ['NUMBER', 'STRING', 'REGEX', 'BOOL', 'NULL', 'UNDEFINED', '}', '::']

# Tokens which a regular expression will never immediately follow (except spaced
# CALLABLEs in some cases), but which a division operator can.
#
# See: http://www-archive.mozilla.org/js/language/js20-2002-04/rationale/syntax.html#regular-expressions
NOT_REGEX = INDEXABLE.concat ['++', '--']

# Tokens that, when immediately preceding a `WHEN`, indicate that the `WHEN`
# occurs at the start of a line. We disambiguate these from trailing whens to
# avoid an ambiguity in the grammar.
LINE_BREAK = ['INDENT', 'OUTDENT', 'TERMINATOR']

# Additional indent in front of these is ignored.
INDENTABLE_CLOSERS = [')', '}', ']']
