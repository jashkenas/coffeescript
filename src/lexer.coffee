# The CoffeeScript Lexer. Uses a series of token-matching regexes to attempt
# matches against the beginning of the source code. When a match is found,
# a token is produced, we consume the match, and start again. Tokens are in the
# form:
#
#     [tag, value, locationData]
#
# where locationData is {first_line, first_column, last_line, last_column, last_line_exclusive, last_column_exclusive}, which is a
# format that can be fed directly into [Jison](https://github.com/zaach/jison).  These
# are read by jison in the `parser.lexer` function defined in coffeescript.coffee.

{Rewriter, INVERSES} = require './rewriter'

# Import the helpers we need.
{count, starts, compact, repeat, invertLiterate, merge,
attachCommentsToNode, locationDataToString, throwSyntaxError
replaceUnicodeCodePointEscapes} = require './helpers'

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
    @baseIndent = 0              # The overall minimum indentation level.
    @indebt     = 0              # The over-indentation at the current level.
    @outdebt    = 0              # The under-outdentation at the current level.
    @indents    = []             # The stack of all current indentation levels.
    @indentLiteral = ''          # The indentation.
    @ends       = []             # The stack for pairing up tokens.
    @tokens     = []             # Stream of parsed tokens in the form `['TYPE', value, location data]`.
    @seenFor    = no             # Used to recognize `FORIN`, `FOROF` and `FORFROM` tokens.
    @seenImport = no             # Used to recognize `IMPORT FROM? AS?` tokens.
    @seenExport = no             # Used to recognize `EXPORT FROM? AS?` tokens.
    @importSpecifierList = no    # Used to identify when in an `IMPORT {...} FROM? ...`.
    @exportSpecifierList = no    # Used to identify when in an `EXPORT {...} FROM? ...`.
    @csxDepth = 0                # Used to optimize CSX checks, how deep in CSX we are.
    @csxObjAttribute = {}        # Used to detect if CSX attributes is wrapped in {} (<div {props...} />).

    @chunkLine =
      opts.line or 0             # The start line for the current @chunk.
    @chunkColumn =
      opts.column or 0           # The start column of the current @chunk.
    @chunkOffset =
      opts.offset or 0           # The start offset for the current @chunk.
    code = @clean code           # The stripped, cleaned original source code.

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
           @csxToken()        or
           @regexToken()      or
           @jsToken()         or
           @literalToken()

      # Update position.
      [@chunkLine, @chunkColumn, @chunkOffset] = @getLineAndColumnFromChunk consumed

      i += consumed

      return {@tokens, index: i} if opts.untilBalanced and @ends.length is 0

    @closeIndentation()
    @error "missing #{end.tag}", (end.origin ? end)[2] if end = @ends.pop()
    return @tokens if opts.rewrite is off
    (new Rewriter).rewrite @tokens

  # Preprocess the code to remove leading and trailing whitespace, carriage
  # returns, etc. If we’re lexing literate CoffeeScript, strip external Markdown
  # by removing all lines that aren’t indented by at least four spaces or a tab.
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
  # Check to ensure that JavaScript reserved words aren’t being used as
  # identifiers. Because CoffeeScript reserves a handful of keywords that are
  # allowed in JavaScript, we’re careful not to tag them as keywords when
  # referenced as property names here, so you can still do `jQuery.is()` even
  # though `is` means `===` otherwise.
  identifierToken: ->
    inCSXTag = @atCSXTag()
    regex = if inCSXTag then CSX_ATTRIBUTE else IDENTIFIER
    return 0 unless match = regex.exec @chunk
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
    if id is 'as' and @seenImport
      if @value() is '*'
        @tokens[@tokens.length - 1][0] = 'IMPORT_ALL'
      else if @value(yes) in COFFEE_KEYWORDS
        prev = @prev()
        [prev[0], prev[1]] = ['IDENTIFIER', @value(yes)]
      if @tag() in ['DEFAULT', 'IMPORT_ALL', 'IDENTIFIER']
        @token 'AS', id
        return id.length
    if id is 'as' and @seenExport
      if @tag() in ['IDENTIFIER', 'DEFAULT']
        @token 'AS', id
        return id.length
      if @value(yes) in COFFEE_KEYWORDS
        prev = @prev()
        [prev[0], prev[1]] = ['IDENTIFIER', @value(yes)]
        @token 'AS', id
        return id.length
    if id is 'default' and @seenExport and @tag() in ['EXPORT', 'AS']
      @token 'DEFAULT', id
      return id.length
    if id is 'do' and regExSuper = /^(\s*super)(?!\(\))/.exec @chunk[3...]
      @token 'SUPER', 'super'
      @token 'CALL_START', '('
      @token 'CALL_END', ')'
      [input, sup] = regExSuper
      return sup.length + 3

    prev = @prev()

    tag =
      if colon or prev? and
         (prev[0] in ['.', '?.', '::', '?::'] or
         not prev.spaced and prev[0] is '@')
        'PROPERTY'
      else
        'IDENTIFIER'

    tokenData = {}
    if tag is 'IDENTIFIER' and (id in JS_KEYWORDS or id in COFFEE_KEYWORDS) and
       not (@exportSpecifierList and id in COFFEE_KEYWORDS)
      tag = id.toUpperCase()
      if tag is 'WHEN' and @tag() in LINE_BREAK
        tag = 'LEADING_WHEN'
      else if tag is 'FOR'
        @seenFor = yes
      else if tag is 'UNLESS'
        tag = 'IF'
      else if tag is 'IMPORT'
        @seenImport = yes
      else if tag is 'EXPORT'
        @seenExport = yes
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
            tokenData.invert = poppedToken.data?.original ? poppedToken[1]
    else if tag is 'IDENTIFIER' and @seenFor and id is 'from' and
       isForFrom(prev)
      tag = 'FORFROM'
      @seenFor = no
    # Throw an error on attempts to use `get` or `set` as keywords, or
    # what CoffeeScript would normally interpret as calls to functions named
    # `get` or `set`, i.e. `get({foo: function () {}})`.
    else if tag is 'PROPERTY' and prev
      if prev.spaced and prev[0] in CALLABLE and /^[gs]et$/.test(prev[1]) and
         @tokens.length > 1 and @tokens[@tokens.length - 2][0] not in ['.', '?.', '@']
        @error "'#{prev[1]}' cannot be used as a keyword, or as a function call
        without parentheses", prev[2]
      else if prev[0] is '.' and @tokens.length > 1 and (prevprev = @tokens[@tokens.length - 2])[0] is 'UNARY' and prevprev[1] is 'new'
        prevprev[0] = 'NEW_TARGET'
      else if @tokens.length > 2
        prevprev = @tokens[@tokens.length - 2]
        if prev[0] in ['@', 'THIS'] and prevprev and prevprev.spaced and
           /^[gs]et$/.test(prevprev[1]) and
           @tokens[@tokens.length - 3][0] not in ['.', '?.', '@']
          @error "'#{prevprev[1]}' cannot be used as a keyword, or as a
          function call without parentheses", prevprev[2]

    if tag is 'IDENTIFIER' and id in RESERVED
      @error "reserved word '#{id}'", length: id.length

    unless tag is 'PROPERTY' or @exportSpecifierList or @importSpecifierList
      if id in COFFEE_ALIASES
        alias = id
        id = COFFEE_ALIAS_MAP[id]
        tokenData.original = alias
      tag = switch id
        when '!'                 then 'UNARY'
        when '==', '!='          then 'COMPARE'
        when 'true', 'false'     then 'BOOL'
        when 'break', 'continue', \
             'debugger'          then 'STATEMENT'
        when '&&', '||'          then id
        else  tag

    tagToken = @token tag, id, length: idLength, data: tokenData
    tagToken.origin = [tag, alias, tagToken[2]] if alias
    if poppedToken
      [tagToken[2].first_line, tagToken[2].first_column, tagToken[2].range[0]] =
        [poppedToken[2].first_line, poppedToken[2].first_column, poppedToken[2].range[0]]
    if colon
      colonOffset = input.lastIndexOf if inCSXTag then '=' else ':'
      colonToken = @token ':', ':', offset: colonOffset, length: colon.length
      colonToken.csxColon = yes if inCSXTag # used by rewriter
    if inCSXTag and tag is 'IDENTIFIER' and prev[0] isnt ':'
      @token ',', ',', length: 0, origin: tagToken

    input.length

  # Matches numbers, including decimals, hex, and exponential notation.
  # Be careful not to interfere with ranges in progress.
  numberToken: ->
    return 0 unless match = NUMBER.exec @chunk

    number = match[0]
    lexedLength = number.length

    switch
      when /^0[BOX]/.test number
        @error "radix prefix in '#{number}' must be lowercase", offset: 1
      when /^(?!0x).*E/.test number
        @error "exponential notation in '#{number}' must be indicated with a lowercase 'e'",
          offset: number.indexOf('E')
      when /^0\d*[89]/.test number
        @error "decimal literal '#{number}' must not be prefixed with '0'", length: lexedLength
      when /^0\d+/.test number
        @error "octal literal '#{number}' must be prefixed with '0o'", length: lexedLength

    parsedValue = Number number

    tag = if Number.isFinite(parsedValue) then 'NUMBER' else 'INFINITY'
    @token tag, number,
      length: lexedLength
      data: {parsedValue}
    lexedLength

  # Matches strings, including multiline strings, as well as heredocs, with or without
  # interpolation.
  stringToken: ->
    [quote] = STRING_START.exec(@chunk) || []
    return 0 unless quote

    # If the preceding token is `from` and this is an import or export statement,
    # properly tag the `from`.
    prev = @prev()
    if prev and @value() is 'from' and (@seenImport or @seenExport)
      prev[0] = 'FROM'

    regex = switch quote
      when "'"   then STRING_SINGLE
      when '"'   then STRING_DOUBLE
      when "'''" then HEREDOC_SINGLE
      when '"""' then HEREDOC_DOUBLE

    {tokens, index: end} = @matchWithInterpolations regex, quote

    heredoc = quote.length is 3
    if heredoc
      # Find the smallest indentation. It will be removed from all lines later.
      indent = null
      doc = (token[1] for token, i in tokens when token[0] is 'NEOSTRING').join '#{}'
      while match = HEREDOC_INDENT.exec doc
        attempt = match[1]
        indent = attempt if indent is null or 0 < attempt.length < indent.length

    delimiter = quote.charAt(0)
    @mergeInterpolationTokens tokens, {quote, indent}, (value) =>
      @validateUnicodeCodePointEscapes value, delimiter: quote

    if @atCSXTag()
      @token ',', ',', length: 0, origin: @prev

    end

  # Matches and consumes comments. The comments are taken out of the token
  # stream and saved for later, to be reinserted into the output after
  # everything has been parsed and the JavaScript code generated.
  commentToken: (chunk = @chunk) ->
    return 0 unless match = chunk.match COMMENT
    [comment, here] = match
    contents = null
    # Does this comment follow code on the same line?
    newLine = /^\s*\n+\s*#/.test comment
    if here
      matchIllegal = HERECOMMENT_ILLEGAL.exec comment
      if matchIllegal
        @error "block comments cannot contain #{matchIllegal[0]}",
          offset: matchIllegal.index, length: matchIllegal[0].length

      # Parse indentation or outdentation as if this block comment didn’t exist.
      chunk = chunk.replace "####{here}###", ''
      # Remove leading newlines, like `Rewriter::removeLeadingNewlines`, to
      # avoid the creation of unwanted `TERMINATOR` tokens.
      chunk = chunk.replace /^\n+/, ''
      @lineToken chunk

      # Pull out the ###-style comment’s content, and format it.
      content = here
      if '\n' in content
        content = content.replace /// \n #{repeat ' ', @indent} ///g, '\n'
      contents = [content]
    else
      # The `COMMENT` regex captures successive line comments as one token.
      # Remove any leading newlines before the first comment, but preserve
      # blank lines between line comments.
      content = comment.replace /^(\n*)/, ''
      content = content.replace /^([ |\t]*)#/gm, ''
      contents = content.split '\n'

    commentAttachments = for content, i in contents
      content: content
      here: here?
      newLine: newLine or i isnt 0 # Line comments after the first one start new lines, by definition.

    prev = @prev()
    unless prev
      # If there’s no previous token, create a placeholder token to attach
      # this comment to; and follow with a newline.
      commentAttachments[0].newLine = yes
      @lineToken @chunk[comment.length..] # Set the indent.
      placeholderToken = @makeToken 'JS', ''
      placeholderToken.generated = yes
      placeholderToken.comments = commentAttachments
      @tokens.push placeholderToken
      @newlineToken 0
    else
      attachCommentsToNode commentAttachments, prev

    comment.length

  # Matches JavaScript interpolated directly into the source via backticks.
  jsToken: ->
    return 0 unless @chunk.charAt(0) is '`' and
      (match = (matchedHere = HERE_JSTOKEN.exec(@chunk)) or JSTOKEN.exec(@chunk))
    # Convert escaped backticks to backticks, and escaped backslashes
    # just before escaped backticks to backslashes
    script = match[1]
    {length} = match[0]
    @token 'JS', script, {length, data: {here: !!matchedHere}}
    length

  # Matches regular expression literals, as well as multiline extended ones.
  # Lexing regular expressions is difficult to distinguish from division, so we
  # borrow some basic heuristics from JavaScript and Ruby.
  regexToken: ->
    switch
      when match = REGEX_ILLEGAL.exec @chunk
        @error "regular expressions cannot begin with #{match[2]}",
          offset: match.index + match[1].length
      when match = @matchWithInterpolations HEREGEX, '///'
        {tokens, index} = match
        comments = @chunk[0...index].match /\s+(#(?!{).*)/g
        @commentToken comment for comment in comments if comments
      when match = REGEX.exec @chunk
        [regex, body, closed] = match
        @validateEscapes body, isRegex: yes, offsetInChunk: 1
        index = regex.length
        prev = @prev()
        if prev
          if prev.spaced and prev[0] in CALLABLE
            return 0 if not closed or POSSIBLY_DIVISION.test regex
          else if prev[0] in NOT_REGEX
            return 0
        @error 'missing / (unclosed regex)' unless closed
      else
        return 0

    [flags] = REGEX_FLAGS.exec @chunk[index..]
    end = index + flags.length
    origin = @makeToken 'REGEX', null, length: end
    switch
      when not VALID_FLAGS.test flags
        @error "invalid regular expression flags #{flags}", offset: index, length: flags.length
      when regex or tokens.length is 1
        delimiter = if body then '/' else '///'
        body ?= tokens[0][1]
        @validateUnicodeCodePointEscapes body, {delimiter}
        @token 'REGEX', "/#{body}/#{flags}", {length: end, origin, data: {delimiter}}
      else
        @token 'REGEX_START', '(',    {length: 0, origin}
        @token 'IDENTIFIER', 'RegExp', length: 0
        @token 'CALL_START', '(',      length: 0
        @mergeInterpolationTokens tokens, {double: yes, heregex: {flags}}, (str) =>
          @validateUnicodeCodePointEscapes str, {delimiter}
        if flags
          @token ',', ',',                    offset: index - 1, length: 0
          @token 'STRING', '"' + flags + '"', offset: index - 1, length: flags.length
        @token ')', ')',                      offset: end - 1,   length: 0
        @token 'REGEX_END', ')',              offset: end - 1,   length: 0

    end

  # Matches newlines, indents, and outdents, and determines which is which.
  # If we can detect that the current line is continued onto the next line,
  # then the newline is suppressed:
  #
  #     elements
  #       .each( ... )
  #       .map( ... )
  #
  # Keeps track of the level of indentation, because a single outdent token
  # can close multiple indents, so we need to know how far in we happen to be.
  lineToken: (chunk = @chunk) ->
    return 0 unless match = MULTI_DENT.exec chunk
    indent = match[0]

    prev = @prev()
    backslash = prev?[0] is '\\'
    @seenFor = no unless backslash and @seenFor
    @seenImport = no unless (backslash and @seenImport) or @importSpecifierList
    @seenExport = no unless (backslash and @seenExport) or @exportSpecifierList

    size = indent.length - 1 - indent.lastIndexOf '\n'
    noNewlines = @unfinished()
    noIndents = @shouldSuppressIndents()

    newIndentLiteral = if size > 0 then indent[-size..] else ''
    unless /^(.?)\1*$/.exec newIndentLiteral
      @error 'mixed indentation', offset: indent.length
      return indent.length

    minLiteralLength = Math.min newIndentLiteral.length, @indentLiteral.length
    if newIndentLiteral[...minLiteralLength] isnt @indentLiteral[...minLiteralLength]
      @error 'indentation mismatch', offset: indent.length
      return indent.length

    if size - @indebt is @indent
      if noNewlines then @suppressNewlines() else @newlineToken 0
      return indent.length

    if size > @indent
      if noNewlines
        @indebt = size - @indent unless backslash
        @suppressNewlines()
        return indent.length
      if noIndents
        @newlineToken 0
        return indent.length
      unless @tokens.length
        @baseIndent = @indent = size
        @indentLiteral = newIndentLiteral
        return indent.length
      diff = size - @indent + @outdebt
      @token 'INDENT', diff, offset: indent.length - size, length: size
      @indents.push diff
      @ends.push {tag: 'OUTDENT'}
      @outdebt = @indebt = 0
      @indent = size
      @indentLiteral = newIndentLiteral
    else if size < @baseIndent
      @error 'missing indentation', offset: indent.length
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
        @outdebt = moveOut = 0
      else if @outdebt and moveOut <= @outdebt
        @outdebt -= moveOut
        moveOut   = 0
      else
        dent = @indents.pop() + @outdebt
        if outdentLength and @chunk[outdentLength] in INDENTABLE_CLOSERS
          decreasedIndent -= dent - moveOut
          moveOut = dent
        @outdebt = 0
        # pair might call outdentToken, so preserve decreasedIndent
        @pair 'OUTDENT'
        @token 'OUTDENT', moveOut, length: outdentLength
        moveOut -= dent
    @outdebt -= moveOut if dent
    @suppressSemicolons()

    @token 'TERMINATOR', '\n', offset: outdentLength, length: 0 unless @tag() is 'TERMINATOR' or noNewlines
    @indent = decreasedIndent
    @indentLiteral = @indentLiteral[...decreasedIndent]
    this

  # Matches and consumes non-meaningful whitespace. Tag the previous token
  # as being “spaced”, because there are some cases where it makes a difference.
  whitespaceToken: ->
    return 0 unless (match = WHITESPACE.exec @chunk) or
                    (nline = @chunk.charAt(0) is '\n')
    prev = @prev()
    prev[if match then 'spaced' else 'newLine'] = true if prev
    if match then match[0].length else 0

  # Generate a newline token. Consecutive newlines get merged together.
  newlineToken: (offset) ->
    @suppressSemicolons()
    @token 'TERMINATOR', '\n', {offset, length: 0} unless @tag() is 'TERMINATOR'
    this

  # Use a `\` at a line-ending to suppress the newline.
  # The slash is removed here once its job is done.
  suppressNewlines: ->
    prev = @prev()
    if prev[1] is '\\'
      if prev.comments and @tokens.length > 1
        # `@tokens.length` should be at least 2 (some code, then `\`).
        # If something puts a `\` after nothing, they deserve to lose any
        # comments that trail it.
        attachCommentsToNode prev.comments, @tokens[@tokens.length - 2]
      @tokens.pop()
    this

  # CSX is like JSX but for CoffeeScript.
  csxToken: ->
    firstChar = @chunk[0]
    # Check the previous token to detect if attribute is spread.
    prevChar = if @tokens.length > 0 then @tokens[@tokens.length - 1][0] else ''
    if firstChar is '<'
      match = CSX_IDENTIFIER.exec(@chunk[1...]) or CSX_FRAGMENT_IDENTIFIER.exec(@chunk[1...])
      return 0 unless match and (
        @csxDepth > 0 or
        # Not the right hand side of an unspaced comparison (i.e. `a<b`).
        not (prev = @prev()) or
        prev.spaced or
        prev[0] not in COMPARABLE_LEFT_SIDE
      )
      [input, id] = match
      fullId = id
      if '.' in id
        [id, properties...] = id.split '.'
      else
        properties = []
      tagToken = @token 'CSX_TAG', id,
        length: id.length + 1
        data:
          openingBracketToken: @makeToken '<', '<'
          tagNameToken: @makeToken 'IDENTIFIER', id, offset: 1
      offset = id.length + 1
      for property in properties
        @token '.', '.', {offset}
        offset += 1
        @token 'PROPERTY', property, {offset}
        offset += property.length
      @token 'CALL_START', '(', generated: yes
      @token '[', '[', generated: yes
      @ends.push {tag: '/>', origin: tagToken, name: id, properties}
      @csxDepth++
      return fullId.length + 1
    else if csxTag = @atCSXTag()
      if @chunk[...2] is '/>' # Self-closing tag.
        @pair '/>'
        @token ']', ']',
          length: 2
          generated: yes
        @token 'CALL_END', ')',
          length: 2
          generated: yes
          data:
            selfClosingSlashToken: @makeToken '/', '/'
            closingBracketToken: @makeToken '>', '>', offset: 1
        @csxDepth--
        return 2
      else if firstChar is '{'
        if prevChar is ':'
          token = @token '(', '('
          @csxObjAttribute[@csxDepth] = no
        else
          token = @token '{', '{'
          @csxObjAttribute[@csxDepth] = yes
        @ends.push {tag: '}', origin: token}
        return 1
      else if firstChar is '>' # end of opening tag
        # Ignore terminators inside a tag.
        {origin: openingTagToken} = @pair '/>' # As if the current tag was self-closing.
        @token ']', ']',
          generated: yes
          data:
            closingBracketToken: @makeToken '>', '>'
        @token ',', 'JSX_COMMA', generated: yes
        {tokens, index: end} =
          @matchWithInterpolations INSIDE_CSX, '>', '</', CSX_INTERPOLATION
        @mergeInterpolationTokens tokens, {}, (value) =>
          @validateUnicodeCodePointEscapes value, delimiter: '>'
        match = CSX_IDENTIFIER.exec(@chunk[end...]) or CSX_FRAGMENT_IDENTIFIER.exec(@chunk[end...])
        if not match or match[1] isnt "#{csxTag.name}#{(".#{property}" for property in csxTag.properties).join ''}"
          @error "expected corresponding CSX closing tag for #{csxTag.name}",
            csxTag.origin.data.tagNameToken[2]
        [, fullTagName] = match
        afterTag = end + fullTagName.length
        if @chunk[afterTag] isnt '>'
          @error "missing closing > after tag name", offset: afterTag, length: 1
        # -2/+2 for the opening `</` and +1 for the closing `>`.
        endToken = @token 'CALL_END', ')',
          offset: end - 2
          length: fullTagName.length + 3
          generated: yes
          data:
            closingTagOpeningBracketToken: @makeToken '<', '<', offset: end - 2
            closingTagSlashToken: @makeToken '/', '/', offset: end - 1
            # TODO: individual tokens for complex tag name? eg < / A . B >
            closingTagNameToken: @makeToken 'IDENTIFIER', fullTagName, offset: end
            closingTagClosingBracketToken: @makeToken '>', '>', offset: end + fullTagName.length
        # make the closing tag location data more easily accessible to the grammar
        addTokenData openingTagToken, endToken.data
        @csxDepth--
        return afterTag + 1
      else
        return 0
    else if @atCSXTag 1
      if firstChar is '}'
        @pair firstChar
        if @csxObjAttribute[@csxDepth]
          @token '}', '}'
          @csxObjAttribute[@csxDepth] = no
        else
          @token ')', ')'
        @token ',', ','
        return 1
      else
        return 0
    else
      return 0

  atCSXTag: (depth = 0) ->
    return no if @csxDepth is 0
    i = @ends.length - 1
    i-- while @ends[i]?.tag is 'OUTDENT' or depth-- > 0 # Ignore indents.
    last = @ends[i]
    last?.tag is '/>' and last

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
    prev = @prev()

    if prev and value in ['=', COMPOUND_ASSIGN...]
      skipToken = false
      if value is '=' and prev[1] in ['||', '&&'] and not prev.spaced
        prev[0] = 'COMPOUND_ASSIGN'
        prev[1] += '='
        prev.data.original += '=' if prev.data?.original
        prev = @tokens[@tokens.length - 2]
        skipToken = true
      if prev and prev[0] isnt 'PROPERTY'
        origin = prev.origin ? prev
        message = isUnassignable prev[1], origin[1]
        @error message, origin[2] if message
      return value.length if skipToken

    if value is '{' and @seenImport
      @importSpecifierList = yes
    else if @importSpecifierList and value is '}'
      @importSpecifierList = no
    else if value is '{' and prev?[0] is 'EXPORT'
      @exportSpecifierList = yes
    else if @exportSpecifierList and value is '}'
      @exportSpecifierList = no

    if value is ';'
      @error 'unexpected ;' if prev?[0] in ['=', UNFINISHED...]
      @seenFor = @seenImport = @seenExport = no
      tag = 'TERMINATOR'
    else if value is '*' and prev?[0] is 'EXPORT'
      tag = 'EXPORT_ALL'
    else if value in MATH            then tag = 'MATH'
    else if value in COMPARE         then tag = 'COMPARE'
    else if value in COMPOUND_ASSIGN then tag = 'COMPOUND_ASSIGN'
    else if value in UNARY           then tag = 'UNARY'
    else if value in UNARY_MATH      then tag = 'UNARY_MATH'
    else if value in SHIFT           then tag = 'SHIFT'
    else if value is '?' and prev?.spaced then tag = 'BIN?'
    else if prev
      if value is '(' and not prev.spaced and prev[0] in CALLABLE
        prev[0] = 'FUNC_EXIST' if prev[0] is '?'
        tag = 'CALL_START'
      else if value is '[' and ((prev[0] in INDEXABLE and not prev.spaced) or
         (prev[0] is '::')) # `.prototype` can’t be a method you can call.
        tag = 'INDEX_START'
        switch prev[0]
          when '?'  then prev[0] = 'INDEX_SOAK'
    token = @makeToken tag, value
    switch value
      when '(', '{', '[' then @ends.push {tag: INVERSES[value], origin: token}
      when ')', '}', ']' then @pair value
    @tokens.push @makeToken tag, value
    value.length

  # Token Manipulators
  # ------------------

  # A source of ambiguity in our grammar used to be parameter lists in function
  # definitions versus argument lists in function calls. Walk backwards, tagging
  # parameters specially in order to make things easier for the parser.
  tagParameters: ->
    return @tagDoIife() if @tag() isnt ')'
    stack = []
    {tokens} = this
    i = tokens.length
    paramEndToken = tokens[--i]
    paramEndToken[0] = 'PARAM_END'
    while tok = tokens[--i]
      switch tok[0]
        when ')'
          stack.push tok
        when '(', 'CALL_START'
          if stack.length then stack.pop()
          else if tok[0] is '('
            tok[0] = 'PARAM_START'
            return @tagDoIife i - 1
          else
            paramEndToken[0] = 'CALL_END'
            return this
    this

  # Tag `do` followed by a function differently than `do` followed by eg an
  # identifier to allow for different grammar precedence
  tagDoIife: (tokenIndex) ->
    tok = @tokens[tokenIndex ? @tokens.length - 1]
    return this unless tok?[0] is 'DO'
    tok[0] = 'DO_IIFE'
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
  #  - `regex` matches the contents of a token (but not `delimiter`, and not
  #    `#{` if interpolations are desired).
  #  - `delimiter` is the delimiter of the token. Examples are `'`, `"`, `'''`,
  #    `"""` and `///`.
  #  - `closingDelimiter` is different from `delimiter` only in CSX
  #  - `interpolators` matches the start of an interpolation, for CSX it's both
  #    `{` and `<` (i.e. nested CSX tag)
  #
  # This method allows us to have strings within interpolations within strings,
  # ad infinitum.
  matchWithInterpolations: (regex, delimiter, closingDelimiter = delimiter, interpolators = /^#\{/) ->
    tokens = []
    offsetInChunk = delimiter.length
    return null unless @chunk[...offsetInChunk] is delimiter
    str = @chunk[offsetInChunk..]
    loop
      [strPart] = regex.exec str

      @validateEscapes strPart, {isRegex: delimiter.charAt(0) is '/', offsetInChunk}

      # Push a fake `'NEOSTRING'` token, which will get turned into a real string later.
      tokens.push @makeToken 'NEOSTRING', strPart, offset: offsetInChunk

      str = str[strPart.length..]
      offsetInChunk += strPart.length

      break unless match = interpolators.exec str
      [interpolator] = match

      # To remove the `#` in `#{`.
      interpolationOffset = interpolator.length - 1
      [line, column, offset] = @getLineAndColumnFromChunk offsetInChunk + interpolationOffset
      rest = str[interpolationOffset..]
      {tokens: nested, index} =
        new Lexer().tokenize rest, {line, column, offset, untilBalanced: on}
      # Account for the `#` in `#{`.
      index += interpolationOffset

      braceInterpolator = str[index - 1] is '}'
      if braceInterpolator
        # Turn the leading and trailing `{` and `}` into parentheses. Unnecessary
        # parentheses will be removed later.
        [open, ..., close] = nested
        open[0]  = 'INTERPOLATION_START'
        open[1]  = '('
        close[0]  = 'INTERPOLATION_END'
        close[1] = ')'
        close.origin = ['', 'end of interpolation', close[2]]

      # Remove leading `'TERMINATOR'` (if any).
      nested.splice 1, 1 if nested[1]?[0] is 'TERMINATOR'
      # Remove trailing `'INDENT'/'OUTDENT'` pair (if any).
      nested.splice -3, 2 if nested[nested.length - 3]?[0] is 'INDENT' and nested[nested.length - 2][0] is 'OUTDENT'

      unless braceInterpolator
        # We are not using `{` and `}`, so wrap the interpolated tokens instead.
        open = @makeToken 'INTERPOLATION_START', '(', offset: offsetInChunk,         length: 0
        close = @makeToken 'INTERPOLATION_END', ')',  offset: offsetInChunk + index, length: 0
        nested = [open, nested..., close]

      # Push a fake `'TOKENS'` token, which will get turned into real tokens later.
      tokens.push ['TOKENS', nested]

      str = str[index..]
      offsetInChunk += index

    unless str[...closingDelimiter.length] is closingDelimiter
      @error "missing #{closingDelimiter}", length: delimiter.length

    [firstToken, ..., lastToken] = tokens
    firstToken[2].first_column -= delimiter.length
    firstToken[2].range[0]     -= delimiter.length
    lastToken[2].range[1]      += closingDelimiter.length
    if lastToken[1].substr(-1) is '\n'
      lastToken[2].last_line += 1
      lastToken[2].last_column = closingDelimiter.length - 1
    else
      lastToken[2].last_column += closingDelimiter.length
    lastToken[2].last_column_exclusive += closingDelimiter.length
    if lastToken[1].length is 0
      lastToken[2].last_column -= 1
      lastToken[2].range[1]    -= 1

    {tokens, index: offsetInChunk + closingDelimiter.length}

  # Merge the array `tokens` of the fake token types `'TOKENS'` and `'NEOSTRING'`
  # (as returned by `matchWithInterpolations`) into the token stream. The value
  # of `'NEOSTRING'`s are converted using `fn` and turned into strings using
  # `options` first.
  mergeInterpolationTokens: (tokens, options, fn) ->
    {quote, indent, double, heregex} = options

    if tokens.length > 1
      lparen = @token 'STRING_START', '(', length: 0, data: {quote}

    firstIndex = @tokens.length
    $ = tokens.length - 1
    for token, i in tokens
      [tag, value] = token
      switch tag
        when 'TOKENS'
          # There are comments (and nothing else) in this interpolation.
          if value.length is 2 and (value[0].comments or value[1].comments)
            placeholderToken = @makeToken 'JS', ''
            placeholderToken.generated = yes
            # Use the same location data as the first parenthesis.
            placeholderToken[2] = value[0][2]
            for val in value when val.comments
              placeholderToken.comments ?= []
              placeholderToken.comments.push val.comments...
            value.splice 1, 0, placeholderToken
          # Push all the tokens in the fake `'TOKENS'` token. These already have
          # sane location data.
          locationToken = value[0]
          tokensToPush = value
        when 'NEOSTRING'
          # Convert `'NEOSTRING'` into `'STRING'`.
          converted = fn.call this, token[1], i
          addTokenData token, initialChunk: yes if i is 0
          addTokenData token, finalChunk: yes   if i is $
          addTokenData token, {indent, quote, double}
          addTokenData token, {heregex} if heregex
          token[0] = 'STRING'
          token[1] = '"' + converted + '"'
          locationToken = token
          tokensToPush = [token]
      @tokens.push tokensToPush...

    if lparen
      [..., lastToken] = tokens
      lparen.origin = ['STRING', null,
        first_line:            lparen[2].first_line
        first_column:          lparen[2].first_column
        last_line:             lastToken[2].last_line
        last_column:           lastToken[2].last_column
        last_line_exclusive:   lastToken[2].last_line_exclusive
        last_column_exclusive: lastToken[2].last_column_exclusive
        range: [
          lparen[2].range[0]
          lastToken[2].range[1]
        ]
      ]
      lparen[2] = lparen.origin[2]
      rparen = @token 'STRING_END', ')'
      rparen[2] =
        first_line:            lastToken[2].last_line
        first_column:          lastToken[2].last_column
        last_line:             lastToken[2].last_line
        last_column:           lastToken[2].last_column
        last_line_exclusive:   lastToken[2].last_line_exclusive
        last_column_exclusive: lastToken[2].last_column_exclusive
        range:                 lastToken[2].range

  # Pairs up a closing token, ensuring that all listed pairs of tokens are
  # correctly balanced throughout the course of the token stream.
  pair: (tag) ->
    [..., prev] = @ends
    unless tag is wanted = prev?.tag
      @error "unmatched #{tag}" unless 'OUTDENT' is wanted
      # Auto-close `INDENT` to support syntax like this:
      #
      #     el.click((event) ->
      #       el.hide())
      #
      [..., lastIndent] = @indents
      @outdentToken lastIndent, true
      return @pair tag
    @ends.pop()

  # Helpers
  # -------

  # Returns the line and column number from an offset into the current chunk.
  #
  # `offset` is a number of characters into `@chunk`.
  getLineAndColumnFromChunk: (offset) ->
    if offset is 0
      return [@chunkLine, @chunkColumn, @chunkOffset]

    if offset >= @chunk.length
      string = @chunk
    else
      string = @chunk[..offset-1]

    lineCount = count string, '\n'

    column = @chunkColumn
    if lineCount > 0
      [..., lastLine] = string.split '\n'
      column = lastLine.length
    else
      column += string.length

    [@chunkLine + lineCount, column, @chunkOffset + offset]

  makeLocationData: ({ offsetInChunk, length }) ->
    locationData = range: []
    [locationData.first_line, locationData.first_column, locationData.range[0]] =
      @getLineAndColumnFromChunk offsetInChunk

    # Use length - 1 for the final offset - we’re supplying the last_line and the last_column,
    # so if last_column == first_column, then we’re looking at a character of length 1.
    lastCharacter = if length > 0 then (length - 1) else 0
    [locationData.last_line, locationData.last_column, endOffset] =
      @getLineAndColumnFromChunk offsetInChunk + lastCharacter
    [locationData.last_line_exclusive, locationData.last_column_exclusive] =
      @getLineAndColumnFromChunk offsetInChunk + lastCharacter + 1
    locationData.range[1] = if length > 0 then endOffset + 1 else endOffset

    locationData

  # Same as `token`, except this just returns the token without adding it
  # to the results.
  makeToken: (tag, value, {offset: offsetInChunk = 0, length = value.length, origin} = {}) ->
    token = [tag, value, @makeLocationData {offsetInChunk, length}]
    token.origin = origin if origin
    token

  # Add a token to the results.
  # `offset` is the offset into the current `@chunk` where the token starts.
  # `length` is the length of the token in the `@chunk`, after the offset.  If
  # not specified, the length of `value` will be used.
  #
  # Returns the new token.
  token: (tag, value, {offset, length, origin, data} = {}) ->
    token = @makeToken tag, value, {offset, length, origin}
    addTokenData token, data if data
    @tokens.push token
    token

  # Peek at the last tag in the token stream.
  tag: ->
    [..., token] = @tokens
    token?[0]

  # Peek at the last value in the token stream.
  value: (useOrigin = no) ->
    [..., token] = @tokens
    if useOrigin and token?.origin?
      token.origin[1]
    else
      token?[1]

  # Get the previous token in the token stream.
  prev: ->
    @tokens[@tokens.length - 1]

  # Are we in the midst of an unfinished expression?
  unfinished: ->
    LINE_CONTINUER.test(@chunk) or
    @tag() in UNFINISHED

  validateUnicodeCodePointEscapes: (str, options) ->
    replaceUnicodeCodePointEscapes str, merge options, {@error}

  # Should an indent be treated as just a TERMINATOR?
  shouldSuppressIndents: ->
    INDENT_SUPPRESSOR.test @chunk

  # Validates escapes in strings and regexes.
  validateEscapes: (str, options = {}) ->
    invalidEscapeRegex =
      if options.isRegex
        REGEX_INVALID_ESCAPE
      else
        STRING_INVALID_ESCAPE
    match = invalidEscapeRegex.exec str
    return unless match
    [[], before, octal, hex, unicodeCodePoint, unicode] = match
    message =
      if octal
        "octal escape sequences are not allowed"
      else
        "invalid escape sequence"
    invalidEscape = "\\#{octal or hex or unicodeCodePoint or unicode}"
    @error "#{message} #{invalidEscape}",
      offset: (options.offsetInChunk ? 0) + match.index + before.length
      length: invalidEscape.length

  suppressSemicolons: ->
    while @value() is ';'
      @tokens.pop()
      @error 'unexpected ;' if @prev()?[0] in ['=', UNFINISHED...]

  # Throws an error at either a given offset from the current chunk or at the
  # location of a token (`token[2]`).
  error: (message, options = {}) =>
    location =
      if 'first_line' of options
        options
      else
        [first_line, first_column] = @getLineAndColumnFromChunk options.offset ? 0
        {first_line, first_column, last_column: first_column + (options.length ? 1) - 1}
    throwSyntaxError message, location

# Helper functions
# ----------------

isUnassignable = (name, displayName = name) -> switch
  when name in [JS_KEYWORDS..., COFFEE_KEYWORDS...]
    "keyword '#{displayName}' can't be assigned"
  when name in STRICT_PROSCRIBED
    "'#{displayName}' can't be assigned"
  when name in RESERVED
    "reserved word '#{displayName}' can't be assigned"
  else
    false

exports.isUnassignable = isUnassignable

# `from` isn’t a CoffeeScript keyword, but it behaves like one in `import` and
# `export` statements (handled above) and in the declaration line of a `for`
# loop. Try to detect when `from` is a variable identifier and when it is this
# “sometimes” keyword.
isForFrom = (prev) ->
  if prev[0] is 'IDENTIFIER'
    # `for i from from`, `for from from iterable`
    if prev[1] is 'from'
      prev[1][0] = 'IDENTIFIER'
      yes
    # `for i from iterable`
    yes
  # `for from…`
  else if prev[0] is 'FOR'
    no
  # `for {from}…`, `for [from]…`, `for {a, from}…`, `for {a: from}…`
  else if prev[1] in ['{', '[', ',', ':']
    no
  else
    yes

addTokenData = (token, data) ->
  Object.assign (token.data ?= {}), data

# Constants
# ---------

# Keywords that CoffeeScript shares in common with JavaScript.
JS_KEYWORDS = [
  'true', 'false', 'null', 'this'
  'new', 'delete', 'typeof', 'in', 'instanceof'
  'return', 'throw', 'break', 'continue', 'debugger', 'yield', 'await'
  'if', 'else', 'switch', 'for', 'while', 'do', 'try', 'catch', 'finally'
  'class', 'extends', 'super'
  'import', 'export', 'default'
]

# CoffeeScript-only keywords.
COFFEE_KEYWORDS = [
  'undefined', 'Infinity', 'NaN'
  'then', 'unless', 'until', 'loop', 'of', 'by', 'when'
]

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
  'case', 'function', 'var', 'void', 'with', 'const', 'let', 'enum'
  'native', 'implements', 'interface', 'package', 'private'
  'protected', 'public', 'static'
]

STRICT_PROSCRIBED = ['arguments', 'eval']

# The superset of both JavaScript keywords and reserved words, none of which may
# be used as identifiers or properties.
exports.JS_FORBIDDEN = JS_KEYWORDS.concat(RESERVED).concat(STRICT_PROSCRIBED)

# The character code of the nasty Microsoft madness otherwise known as the BOM.
BOM = 65279

# Token matching regexes.
IDENTIFIER = /// ^
  (?!\d)
  ( (?: (?!\s)[$\w\x7f-\uffff] )+ )
  ( [^\n\S]* : (?!:) )?  # Is this a property name?
///

CSX_IDENTIFIER = /// ^
  (?![\d<]) # Must not start with `<`.
  ( (?: (?!\s)[\.\-$\w\x7f-\uffff] )+ ) # Like `IDENTIFIER`, but includes `-`s and `.`s.
///

# Fragment: <></>
CSX_FRAGMENT_IDENTIFIER = /// ^
  ()> # Ends immediately with `>`.
///

CSX_ATTRIBUTE = /// ^
  (?!\d)
  ( (?: (?!\s)[\-$\w\x7f-\uffff] )+ ) # Like `IDENTIFIER`, but includes `-`s.
  ( [^\S]* = (?!=) )?  # Is this an attribute with a value?
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

COMMENT    = /^\s*###([^#][\s\S]*?)(?:###[^\n\S]*|###$)|^(?:\s*#(?!##[^#]).*)+/

CODE       = /^[-=]>/

MULTI_DENT = /^(?:\n[^\n\S]*)+/

JSTOKEN      = ///^ `(?!``) ((?: [^`\\] | \\[\s\S]           )*) `   ///
HERE_JSTOKEN = ///^ ```     ((?: [^`\\] | \\[\s\S] | `(?!``) )*) ``` ///

# String-matching-regexes.
STRING_START   = /^(?:'''|"""|'|")/

STRING_SINGLE  = /// ^(?: [^\\']  | \\[\s\S]                      )* ///
STRING_DOUBLE  = /// ^(?: [^\\"#] | \\[\s\S] |           \#(?!\{) )* ///
HEREDOC_SINGLE = /// ^(?: [^\\']  | \\[\s\S] | '(?!'')            )* ///
HEREDOC_DOUBLE = /// ^(?: [^\\"#] | \\[\s\S] | "(?!"") | \#(?!\{) )* ///

INSIDE_CSX = /// ^(?:
    [^
      \{ # Start of CoffeeScript interpolation.
      <  # Maybe CSX tag (`<` not allowed even if bare).
    ]
  )* /// # Similar to `HEREDOC_DOUBLE` but there is no escaping.
CSX_INTERPOLATION = /// ^(?:
      \{       # CoffeeScript interpolation.
    | <(?!/)   # CSX opening tag.
  )///

HEREDOC_INDENT     = /\n+([^\n\S]*)(?=\S)/g

# Regex-matching-regexes.
REGEX = /// ^
  / (?!/) ((
  ?: [^ [ / \n \\ ]  # Every other thing.
   | \\[^\n]         # Anything but newlines escaped.
   | \[              # Character class.
       (?: \\[^\n] | [^ \] \n \\ ] )*
     \]
  )*) (/)?
///

REGEX_FLAGS  = /^\w*/
VALID_FLAGS  = /^(?!.*(.).*\1)[gimsuy]*$/

HEREGEX      = /// ^
  (?:
      # Match any character, except those that need special handling below.
      [^\\/#\s]
      # Match `\` followed by any character.
    | \\[\s\S]
      # Match any `/` except `///`.
    | /(?!//)
      # Match `#` which is not part of interpolation, e.g. `#{}`.
    | \#(?!\{)
      # Comments consume everything until the end of the line, including `///`.
    | \s+(?:#(?!\{).*)?
  )*
///

REGEX_ILLEGAL = /// ^ ( / | /{3}\s*) (\*) ///

POSSIBLY_DIVISION   = /// ^ /=?\s ///

# Other regexes.
HERECOMMENT_ILLEGAL = /\*\//

LINE_CONTINUER      = /// ^ \s* (?: , | \??\.(?![.\d]) | \??:: ) ///
INDENT_SUPPRESSOR   = /// ^ \s* (?: and\s+(?!:)\S | or\s+(?!:)\S | && | \|\| ) ///

STRING_INVALID_ESCAPE = ///
  ( (?:^|[^\\]) (?:\\\\)* )        # Make sure the escape isn’t escaped.
  \\ (
     ?: (0[0-7]|[1-7])             # octal escape
      | (x(?![\da-fA-F]{2}).{0,2}) # hex escape
      | (u\{(?![\da-fA-F]{1,}\})[^}]*\}?) # unicode code point escape
      | (u(?!\{|[\da-fA-F]{4}).{0,4}) # unicode escape
  )
///
REGEX_INVALID_ESCAPE = ///
  ( (?:^|[^\\]) (?:\\\\)* )        # Make sure the escape isn’t escaped.
  \\ (
     ?: (0[0-7])                   # octal escape
      | (x(?![\da-fA-F]{2}).{0,2}) # hex escape
      | (u\{(?![\da-fA-F]{1,}\})[^}]*\}?) # unicode code point escape
      | (u(?!\{|[\da-fA-F]{4}).{0,4}) # unicode escape
  )
///

TRAILING_SPACES     = /\s+$/

# Compound assignment tokens.
COMPOUND_ASSIGN = [
  '-=', '+=', '/=', '*=', '%=', '||=', '&&=', '?=', '<<=', '>>=', '>>>='
  '&=', '^=', '|=', '**=', '//=', '%%='
]

# Unary tokens.
UNARY = ['NEW', 'TYPEOF', 'DELETE']

UNARY_MATH = ['!', '~']

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
CALLABLE  = ['IDENTIFIER', 'PROPERTY', ')', ']', '?', '@', 'THIS', 'SUPER']
INDEXABLE = CALLABLE.concat [
  'NUMBER', 'INFINITY', 'NAN', 'STRING', 'STRING_END', 'REGEX', 'REGEX_END'
  'BOOL', 'NULL', 'UNDEFINED', '}', '::'
]

# Tokens which can be the left-hand side of a less-than comparison, i.e. `a<b`.
COMPARABLE_LEFT_SIDE = ['IDENTIFIER', ')', ']', 'NUMBER']

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

# Tokens that, when appearing at the end of a line, suppress a following TERMINATOR/INDENT token
UNFINISHED = ['\\', '.', '?.', '?::', 'UNARY', 'DO', 'DO_IIFE', 'MATH', 'UNARY_MATH', '+', '-',
           '**', 'SHIFT', 'RELATION', 'COMPARE', '&', '^', '|', '&&', '||',
           'BIN?', 'EXTENDS']
