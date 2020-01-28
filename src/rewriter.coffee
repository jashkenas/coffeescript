# The CoffeeScript language has a good deal of optional syntax, implicit syntax,
# and shorthand syntax. This can greatly complicate a grammar and bloat
# the resulting parse table. Instead of making the parser handle it all, we take
# a series of passes over the token stream, using this **Rewriter** to convert
# shorthand into the unambiguous long form, add implicit indentation and
# parentheses, and generally clean things up.

{throwSyntaxError, extractAllCommentTokens} = require './helpers'

# Move attached comments from one token to another.
moveComments = (fromToken, toToken) ->
  return unless fromToken.comments
  if toToken.comments and toToken.comments.length isnt 0
    unshiftedComments = []
    for comment in fromToken.comments
      if comment.unshift
        unshiftedComments.push comment
      else
        toToken.comments.push comment
    toToken.comments = unshiftedComments.concat toToken.comments
  else
    toToken.comments = fromToken.comments
  delete fromToken.comments

# Create a generated token: one that exists due to a use of implicit syntax.
# Optionally have this new token take the attached comments from another token.
generate = (tag, value, origin, commentsToken) ->
  token = [tag, value]
  token.generated = yes
  token.origin = origin if origin
  moveComments commentsToken, token if commentsToken
  token

# The **Rewriter** class is used by the [Lexer](lexer.html), directly against
# its internal array of tokens.
exports.Rewriter = class Rewriter

  # Rewrite the token stream in multiple passes, one logical filter at
  # a time. This could certainly be changed into a single pass through the
  # stream, with a big ol’ efficient switch, but it’s much nicer to work with
  # like this. The order of these passes matters—indentation must be
  # corrected before implicit parentheses can be wrapped around blocks of code.
  rewrite: (@tokens) ->
    # Set environment variable `DEBUG_TOKEN_STREAM` to `true` to output token
    # debugging info. Also set `DEBUG_REWRITTEN_TOKEN_STREAM` to `true` to
    # output the token stream after it has been rewritten by this file.
    if process?.env?.DEBUG_TOKEN_STREAM
      console.log 'Initial token stream:' if process.env.DEBUG_REWRITTEN_TOKEN_STREAM
      console.log (t[0] + '/' + t[1] + (if t.comments then '*' else '') for t in @tokens).join ' '
    @removeLeadingNewlines()
    @closeOpenCalls()
    @closeOpenIndexes()
    @normalizeLines()
    @tagPostfixConditionals()
    @addImplicitBracesAndParens()
    @rescueStowawayComments()
    @addLocationDataToGeneratedTokens()
    @enforceValidJSXAttributes()
    @fixIndentationLocationData()
    @exposeTokenDataToGrammar()
    if process?.env?.DEBUG_REWRITTEN_TOKEN_STREAM
      console.log 'Rewritten token stream:' if process.env.DEBUG_TOKEN_STREAM
      console.log (t[0] + '/' + t[1] + (if t.comments then '*' else '') for t in @tokens).join ' '
    @tokens

  # Rewrite the token stream, looking one token ahead and behind.
  # Allow the return value of the block to tell us how many tokens to move
  # forwards (or backwards) in the stream, to make sure we don’t miss anything
  # as tokens are inserted and removed, and the stream changes length under
  # our feet.
  scanTokens: (block) ->
    {tokens} = this
    i = 0
    i += block.call this, token, i, tokens while token = tokens[i]
    true

  detectEnd: (i, condition, action, opts = {}) ->
    {tokens} = this
    levels = 0
    while token = tokens[i]
      return action.call this, token, i if levels is 0 and condition.call this, token, i
      if token[0] in EXPRESSION_START
        levels += 1
      else if token[0] in EXPRESSION_END
        levels -= 1
      if levels < 0
        return if opts.returnOnNegativeLevel
        return action.call this, token, i
      i += 1
    i - 1

  # Leading newlines would introduce an ambiguity in the grammar, so we
  # dispatch them here.
  removeLeadingNewlines: ->
    # Find the index of the first non-`TERMINATOR` token.
    break for [tag], i in @tokens when tag isnt 'TERMINATOR'
    return if i is 0
    # If there are any comments attached to the tokens we’re about to discard,
    # shift them forward to what will become the new first token.
    for leadingNewlineToken in @tokens[0...i]
      moveComments leadingNewlineToken, @tokens[i]
    # Discard all the leading newline tokens.
    @tokens.splice 0, i

  # The lexer has tagged the opening parenthesis of a method call. Match it with
  # its paired close.
  closeOpenCalls: ->
    condition = (token, i) ->
      token[0] in [')', 'CALL_END']

    action = (token, i) ->
      token[0] = 'CALL_END'

    @scanTokens (token, i) ->
      @detectEnd i + 1, condition, action if token[0] is 'CALL_START'
      1

  # The lexer has tagged the opening bracket of an indexing operation call.
  # Match it with its paired close.
  closeOpenIndexes: ->
    startToken = null
    condition = (token, i) ->
      token[0] in [']', 'INDEX_END']

    action = (token, i) ->
      if @tokens.length >= i and @tokens[i + 1][0] is ':'
        startToken[0] = '['
        token[0] = ']'
      else
        token[0] = 'INDEX_END'

    @scanTokens (token, i) ->
      if token[0] is 'INDEX_START'
        startToken = token
        @detectEnd i + 1, condition, action
      1

  # Match tags in token stream starting at `i` with `pattern`.
  # `pattern` may consist of strings (equality), an array of strings (one of)
  # or null (wildcard). Returns the index of the match or -1 if no match.
  indexOfTag: (i, pattern...) ->
    fuzz = 0
    for j in [0 ... pattern.length]
      continue if not pattern[j]?
      pattern[j] = [pattern[j]] if typeof pattern[j] is 'string'
      return -1 if @tag(i + j + fuzz) not in pattern[j]
    i + j + fuzz - 1

  # Returns `yes` if standing in front of something looking like
  # `@<x>:`, `<x>:` or `<EXPRESSION_START><x>...<EXPRESSION_END>:`.
  looksObjectish: (j) ->
    return yes if @indexOfTag(j, '@', null, ':') isnt -1 or @indexOfTag(j, null, ':') isnt -1
    index = @indexOfTag j, EXPRESSION_START
    if index isnt -1
      end = null
      @detectEnd index + 1, ((token) -> token[0] in EXPRESSION_END), ((token, i) -> end = i)
      return yes if @tag(end + 1) is ':'
    no

  # Returns `yes` if current line of tokens contain an element of tags on same
  # expression level. Stop searching at `LINEBREAKS` or explicit start of
  # containing balanced expression.
  findTagsBackwards: (i, tags) ->
    backStack = []
    while i >= 0 and (backStack.length or
          @tag(i) not in tags and
          (@tag(i) not in EXPRESSION_START or @tokens[i].generated) and
          @tag(i) not in LINEBREAKS)
      backStack.push @tag(i) if @tag(i) in EXPRESSION_END
      backStack.pop() if @tag(i) in EXPRESSION_START and backStack.length
      i -= 1
    @tag(i) in tags

  # Look for signs of implicit calls and objects in the token stream and
  # add them.
  addImplicitBracesAndParens: ->
    # Track current balancing depth (both implicit and explicit) on stack.
    stack = []
    start = null

    @scanTokens (token, i, tokens) ->
      [tag]     = token
      [prevTag] = prevToken = if i > 0 then tokens[i - 1] else []
      [nextTag] = nextToken = if i < tokens.length - 1 then tokens[i + 1] else []
      stackTop  = -> stack[stack.length - 1]
      startIdx  = i

      # Helper function, used for keeping track of the number of tokens consumed
      # and spliced, when returning for getting a new token.
      forward   = (n) -> i - startIdx + n

      # Helper functions
      isImplicit        = (stackItem) -> stackItem?[2]?.ours
      isImplicitObject  = (stackItem) -> isImplicit(stackItem) and stackItem?[0] is '{'
      isImplicitCall    = (stackItem) -> isImplicit(stackItem) and stackItem?[0] is '('
      inImplicit        = -> isImplicit stackTop()
      inImplicitCall    = -> isImplicitCall stackTop()
      inImplicitObject  = -> isImplicitObject stackTop()
      # Unclosed control statement inside implicit parens (like
      # class declaration or if-conditionals).
      inImplicitControl = -> inImplicit() and stackTop()?[0] is 'CONTROL'

      startImplicitCall = (idx) ->
        stack.push ['(', idx, ours: yes]
        tokens.splice idx, 0, generate 'CALL_START', '(', ['', 'implicit function call', token[2]], prevToken

      endImplicitCall = ->
        stack.pop()
        tokens.splice i, 0, generate 'CALL_END', ')', ['', 'end of input', token[2]], prevToken
        i += 1

      startImplicitObject = (idx, {startsLine = yes, continuationLineIndent} = {}) ->
        stack.push ['{', idx, sameLine: yes, startsLine: startsLine, ours: yes, continuationLineIndent: continuationLineIndent]
        val = new String '{'
        val.generated = yes
        tokens.splice idx, 0, generate '{', val, token, prevToken

      endImplicitObject = (j) ->
        j = j ? i
        stack.pop()
        tokens.splice j, 0, generate '}', '}', token, prevToken
        i += 1

      implicitObjectContinues = (j) =>
        nextTerminatorIdx = null
        @detectEnd j,
          (token) -> token[0] is 'TERMINATOR'
          (token, i) -> nextTerminatorIdx = i
          returnOnNegativeLevel: yes
        return no unless nextTerminatorIdx?
        @looksObjectish nextTerminatorIdx + 1

      # Don’t end an implicit call/object on next indent if any of these are in an argument/value.
      if (
        (inImplicitCall() or inImplicitObject()) and tag in CONTROL_IN_IMPLICIT or
        inImplicitObject() and prevTag is ':' and tag is 'FOR'
      )
        stack.push ['CONTROL', i, ours: yes]
        return forward(1)

      if tag is 'INDENT' and inImplicit()

        # An `INDENT` closes an implicit call unless
        #
        #  1. We have seen a `CONTROL` argument on the line.
        #  2. The last token before the indent is part of the list below.
        if prevTag not in ['=>', '->', '[', '(', ',', '{', 'ELSE', '=']
          while inImplicitCall() or inImplicitObject() and prevTag isnt ':'
            if inImplicitCall()
              endImplicitCall()
            else
              endImplicitObject()
        stack.pop() if inImplicitControl()
        stack.push [tag, i]
        return forward(1)

      # Straightforward start of explicit expression.
      if tag in EXPRESSION_START
        stack.push [tag, i]
        return forward(1)

      # Close all implicit expressions inside of explicitly closed expressions.
      if tag in EXPRESSION_END
        while inImplicit()
          if inImplicitCall()
            endImplicitCall()
          else if inImplicitObject()
            endImplicitObject()
          else
            stack.pop()
        start = stack.pop()

      inControlFlow = =>
        seenFor = @findTagsBackwards(i, ['FOR']) and @findTagsBackwards(i, ['FORIN', 'FOROF', 'FORFROM'])
        controlFlow = seenFor or @findTagsBackwards i, ['WHILE', 'UNTIL', 'LOOP', 'LEADING_WHEN']
        return no unless controlFlow
        isFunc = no
        tagCurrentLine = token[2].first_line
        @detectEnd i,
          (token, i) -> token[0] in LINEBREAKS
          (token, i) ->
            [prevTag, ,{first_line}] = tokens[i - 1] || []
            isFunc = tagCurrentLine is first_line and prevTag in ['->', '=>']
          returnOnNegativeLevel: yes
        isFunc

      # Recognize standard implicit calls like
      # f a, f() b, f? c, h[0] d etc.
      # Added support for spread dots on the left side: f ...a
      if (tag in IMPLICIT_FUNC and token.spaced or
          tag is '?' and i > 0 and not tokens[i - 1].spaced) and
         (nextTag in IMPLICIT_CALL or
         (nextTag is '...' and @tag(i + 2) in IMPLICIT_CALL and not @findTagsBackwards(i, ['INDEX_START', '['])) or
          nextTag in IMPLICIT_UNSPACED_CALL and
          not nextToken.spaced and not nextToken.newLine) and
          not inControlFlow()
        tag = token[0] = 'FUNC_EXIST' if tag is '?'
        startImplicitCall i + 1
        return forward(2)

      # Implicit call taking an implicit indented object as first argument.
      #
      #     f
      #       a: b
      #       c: d
      #
      # Don’t accept implicit calls of this type, when on the same line
      # as the control structures below as that may misinterpret constructs like:
      #
      #     if f
      #        a: 1
      # as
      #
      #     if f(a: 1)
      #
      # which is probably always unintended.
      # Furthermore don’t allow this in literal arrays, as
      # that creates grammatical ambiguities.
      if tag in IMPLICIT_FUNC and
         @indexOfTag(i + 1, 'INDENT') > -1 and @looksObjectish(i + 2) and
         not @findTagsBackwards(i, ['CLASS', 'EXTENDS', 'IF', 'CATCH',
          'SWITCH', 'LEADING_WHEN', 'FOR', 'WHILE', 'UNTIL'])
        startImplicitCall i + 1
        stack.push ['INDENT', i + 2]
        return forward(3)

      # Implicit objects start here.
      if tag is ':'
        # Go back to the (implicit) start of the object.
        s = switch
          when @tag(i - 1) in EXPRESSION_END
            [startTag, startIndex] = start
            if startTag is '[' and startIndex > 0 and @tag(startIndex - 1) is '@' and not tokens[startIndex - 1].spaced
              startIndex - 1
            else
              startIndex
          when @tag(i - 2) is '@' then i - 2
          else i - 1

        startsLine = s <= 0 or @tag(s - 1) in LINEBREAKS or tokens[s - 1].newLine
        # Are we just continuing an already declared object?
        if stackTop()
          [stackTag, stackIdx] = stackTop()
          if (stackTag is '{' or stackTag is 'INDENT' and @tag(stackIdx - 1) is '{') and
             (startsLine or @tag(s - 1) is ',' or @tag(s - 1) is '{') and
             @tag(s - 1) not in UNFINISHED
            return forward(1)

        preObjectToken = if i > 1 then tokens[i - 2] else []
        startImplicitObject(s, {startsLine: !!startsLine, continuationLineIndent: preObjectToken.continuationLineIndent})
        return forward(2)

      # End implicit calls when chaining method calls
      # like e.g.:
      #
      #     f ->
      #       a
      #     .g b, ->
      #       c
      #     .h a
      #
      # and also
      #
      #     f a
      #     .g b
      #     .h a

      # Mark all enclosing objects as not sameLine
      if tag in LINEBREAKS
        for stackItem in stack by -1
          break unless isImplicit stackItem
          stackItem[2].sameLine = no if isImplicitObject stackItem

      # End indented-continuation-line implicit objects once that indentation is over.
      if tag is 'TERMINATOR' and token.endsContinuationLineIndentation
        {preContinuationLineIndent} = token.endsContinuationLineIndentation
        while inImplicitObject() and (implicitObjectIndent = stackTop()[2].continuationLineIndent)? and implicitObjectIndent > preContinuationLineIndent
          endImplicitObject()

      newLine = prevTag is 'OUTDENT' or prevToken.newLine
      if tag in IMPLICIT_END or
          (tag in CALL_CLOSERS and newLine) or
          (tag in ['..', '...'] and @findTagsBackwards(i, ["INDEX_START"]))
        while inImplicit()
          [stackTag, stackIdx, {sameLine, startsLine}] = stackTop()
          # Close implicit calls when reached end of argument list
          if inImplicitCall() and prevTag isnt ',' or
              (prevTag is ',' and tag is 'TERMINATOR' and not nextTag?)
            endImplicitCall()
          # Close implicit objects such as:
          # return a: 1, b: 2 unless true
          else if inImplicitObject() and sameLine and
                  tag isnt 'TERMINATOR' and prevTag isnt ':' and
                  not (tag in ['POST_IF', 'FOR', 'WHILE', 'UNTIL'] and startsLine and implicitObjectContinues(i + 1))
            endImplicitObject()
          # Close implicit objects when at end of line, line didn't end with a comma
          # and the implicit object didn't start the line or the next line doesn’t look like
          # the continuation of an object.
          else if inImplicitObject() and tag is 'TERMINATOR' and prevTag isnt ',' and
                  not (startsLine and @looksObjectish(i + 1))
            endImplicitObject()
          else if inImplicitControl() and tokens[stackTop()[1]][0] is 'CLASS' and tag is 'TERMINATOR'
            stack.pop()
          else
            break

      # Close implicit object if comma is the last character
      # and what comes after doesn’t look like it belongs.
      # This is used for trailing commas and calls, like:
      #
      #     x =
      #         a: b,
      #         c: d,
      #     e = 2
      #
      # and
      #
      #     f a, b: c, d: e, f, g: h: i, j
      #
      if tag is ',' and not @looksObjectish(i + 1) and inImplicitObject() and not (@tag(i + 2) in ['FOROF', 'FORIN']) and
         (nextTag isnt 'TERMINATOR' or not @looksObjectish(i + 2))
        # When nextTag is OUTDENT the comma is insignificant and
        # should just be ignored so embed it in the implicit object.
        #
        # When it isn’t the comma go on to play a role in a call or
        # array further up the stack, so give it a chance.
        offset = if nextTag is 'OUTDENT' then 1 else 0
        while inImplicitObject()
          endImplicitObject i + offset
      return forward(1)

  # Make sure only strings and wrapped expressions are used in JSX attributes.
  enforceValidJSXAttributes: ->
    @scanTokens (token, i, tokens) ->
      if token.jsxColon
        next = tokens[i + 1]
        if next[0] not in ['STRING_START', 'STRING', '(']
          throwSyntaxError 'expected wrapped or quoted JSX attribute', next[2]
      return 1

  # Not all tokens survive processing by the parser. To avoid comments getting
  # lost into the ether, find comments attached to doomed tokens and move them
  # to a token that will make it to the other side.
  rescueStowawayComments: ->
    insertPlaceholder = (token, j, tokens, method) ->
      tokens[method] generate 'TERMINATOR', '\n', tokens[j] unless tokens[j][0] is 'TERMINATOR'
      tokens[method] generate 'JS', '', tokens[j], token

    dontShiftForward = (i, tokens) ->
      j = i + 1
      while j isnt tokens.length and tokens[j][0] in DISCARDED
        return yes if tokens[j][0] is 'INTERPOLATION_END'
        j++
      no

    shiftCommentsForward = (token, i, tokens) ->
      # Find the next surviving token and attach this token’s comments to it,
      # with a flag that we know to output such comments *before* that
      # token’s own compilation. (Otherwise comments are output following
      # the token they’re attached to.)
      j = i
      j++ while j isnt tokens.length and tokens[j][0] in DISCARDED
      unless j is tokens.length or tokens[j][0] in DISCARDED
        comment.unshift = yes for comment in token.comments
        moveComments token, tokens[j]
        return 1
      else # All following tokens are doomed!
        j = tokens.length - 1
        insertPlaceholder token, j, tokens, 'push'
        # The generated tokens were added to the end, not inline, so we don’t skip.
        return 1

    shiftCommentsBackward = (token, i, tokens) ->
      # Find the last surviving token and attach this token’s comments to it.
      j = i
      j-- while j isnt -1 and tokens[j][0] in DISCARDED
      unless j is -1 or tokens[j][0] in DISCARDED
        moveComments token, tokens[j]
        return 1
      else # All previous tokens are doomed!
        insertPlaceholder token, 0, tokens, 'unshift'
        # We added two tokens, so shift forward to account for the insertion.
        return 3

    @scanTokens (token, i, tokens) ->
      return 1 unless token.comments
      ret = 1
      if token[0] in DISCARDED
        # This token won’t survive passage through the parser, so we need to
        # rescue its attached tokens and redistribute them to nearby tokens.
        # Comments that don’t start a new line can shift backwards to the last
        # safe token, while other tokens should shift forward.
        dummyToken = comments: []
        j = token.comments.length - 1
        until j is -1
          if token.comments[j].newLine is no and token.comments[j].here is no
            dummyToken.comments.unshift token.comments[j]
            token.comments.splice j, 1
          j--
        if dummyToken.comments.length isnt 0
          ret = shiftCommentsBackward dummyToken, i - 1, tokens
        if token.comments.length isnt 0
          shiftCommentsForward token, i, tokens
      else unless dontShiftForward i, tokens
        # If any of this token’s comments start a line—there’s only
        # whitespace between the preceding newline and the start of the
        # comment—and this isn’t one of the special `JS` tokens, then
        # shift this comment forward to precede the next valid token.
        # `Block.compileComments` also has logic to make sure that
        # “starting new line” comments follow or precede the nearest
        # newline relative to the token that the comment is attached to,
        # but that newline might be inside a `}` or `)` or other generated
        # token that we really want this comment to output after. Therefore
        # we need to shift the comments here, avoiding such generated and
        # discarded tokens.
        dummyToken = comments: []
        j = token.comments.length - 1
        until j is -1
          if token.comments[j].newLine and not token.comments[j].unshift and
             not (token[0] is 'JS' and token.generated)
            dummyToken.comments.unshift token.comments[j]
            token.comments.splice j, 1
          j--
        if dummyToken.comments.length isnt 0
          ret = shiftCommentsForward dummyToken, i + 1, tokens
      delete token.comments if token.comments?.length is 0
      ret

  # Add location data to all tokens generated by the rewriter.
  addLocationDataToGeneratedTokens: ->
    @scanTokens (token, i, tokens) ->
      return 1 if     token[2]
      return 1 unless token.generated or token.explicit
      if token.fromThen and token[0] is 'INDENT'
        token[2] = token.origin[2]
        return 1
      if token[0] is '{' and nextLocation=tokens[i + 1]?[2]
        {first_line: line, first_column: column, range: [rangeIndex]} = nextLocation
      else if prevLocation = tokens[i - 1]?[2]
        {last_line: line, last_column: column, range: [, rangeIndex]} = prevLocation
        column += 1
      else
        line = column = 0
        rangeIndex = 0
      token[2] = {
        first_line:            line
        first_column:          column
        last_line:             line
        last_column:           column
        last_line_exclusive:   line
        last_column_exclusive: column
        range: [rangeIndex, rangeIndex]
      }
      return 1

  # `OUTDENT` tokens should always be positioned at the last character of the
  # previous token, so that AST nodes ending in an `OUTDENT` token end up with a
  # location corresponding to the last “real” token under the node.
  fixIndentationLocationData: ->
    @allComments ?= extractAllCommentTokens @tokens
    findPrecedingComment = (token, {afterPosition, indentSize, first, indented}) =>
      tokenStart = token[2].range[0]
      matches = (comment) ->
        if comment.outdented
          return no unless indentSize? and comment.indentSize > indentSize
        return no if indented and not comment.indented
        return no unless comment.locationData.range[0] < tokenStart
        return no unless comment.locationData.range[0] > afterPosition
        yes
      if first
        lastMatching = null
        for comment in @allComments by -1
          if matches comment
            lastMatching = comment
          else if lastMatching
            return lastMatching
        return lastMatching
      for comment in @allComments when matches comment by -1
        return comment
      null

    @scanTokens (token, i, tokens) ->
      return 1 unless token[0] in ['INDENT', 'OUTDENT'] or
        (token.generated and token[0] is 'CALL_END' and not token.data?.closingTagNameToken) or
        (token.generated and token[0] is '}')
      isIndent = token[0] is 'INDENT'
      prevToken = token.prevToken ? tokens[i - 1]
      prevLocationData = prevToken[2]
      # addLocationDataToGeneratedTokens() set the outdent’s location data
      # to the preceding token’s, but in order to detect comments inside an
      # empty "block" we want to look for comments preceding the next token.
      useNextToken = token.explicit or token.generated
      if useNextToken
        nextToken = token
        nextTokenIndex = i
        nextToken = tokens[nextTokenIndex++] while (nextToken.explicit or nextToken.generated) and nextTokenIndex isnt tokens.length - 1
      precedingComment = findPrecedingComment(
        if useNextToken
          nextToken
        else
          token
        afterPosition: prevLocationData.range[0]
        indentSize: token.indentSize
        first: isIndent
        indented: useNextToken
      )
      if isIndent
        return 1 unless precedingComment?.newLine
      # We don’t want e.g. an implicit call at the end of an `if` condition to
      # include a following indented comment.
      return 1 if token.generated and token[0] is 'CALL_END' and precedingComment?.indented
      prevLocationData = precedingComment.locationData if precedingComment?
      token[2] =
        first_line:
          if precedingComment?
            prevLocationData.first_line
          else
            prevLocationData.last_line
        first_column:
          if precedingComment?
            if isIndent
              0
            else
              prevLocationData.first_column
          else
            prevLocationData.last_column
        last_line:              prevLocationData.last_line
        last_column:            prevLocationData.last_column
        last_line_exclusive:    prevLocationData.last_line_exclusive
        last_column_exclusive:  prevLocationData.last_column_exclusive
        range:
          if isIndent and precedingComment?
            [
              prevLocationData.range[0] - precedingComment.indentSize
              prevLocationData.range[1]
            ]
          else
            prevLocationData.range
      return 1

  # Because our grammar is LALR(1), it can’t handle some single-line
  # expressions that lack ending delimiters. The **Rewriter** adds the implicit
  # blocks, so it doesn’t need to. To keep the grammar clean and tidy, trailing
  # newlines within expressions are removed and the indentation tokens of empty
  # blocks are added.
  normalizeLines: ->
    starter = indent = outdent = null
    leading_switch_when = null
    leading_if_then = null
    # Count `THEN` tags
    ifThens = []

    condition = (token, i) ->
      token[1] isnt ';' and token[0] in SINGLE_CLOSERS and
      not (token[0] is 'TERMINATOR' and @tag(i + 1) in EXPRESSION_CLOSE) and
      not (token[0] is 'ELSE' and
           (starter isnt 'THEN' or (leading_if_then or leading_switch_when))) and
      not (token[0] in ['CATCH', 'FINALLY'] and starter in ['->', '=>']) or
      token[0] in CALL_CLOSERS and
      (@tokens[i - 1].newLine or @tokens[i - 1][0] is 'OUTDENT')

    action = (token, i) ->
      ifThens.pop() if token[0] is 'ELSE' and starter is 'THEN'
      @tokens.splice (if @tag(i - 1) is ',' then i - 1 else i), 0, outdent

    closeElseTag = (tokens, i) =>
      tlen = ifThens.length
      return i unless tlen > 0
      lastThen = ifThens.pop()
      [, outdentElse] = @indentation tokens[lastThen]
      # Insert `OUTDENT` to close inner `IF`.
      outdentElse[1] = tlen*2
      tokens.splice(i, 0, outdentElse)
      # Insert `OUTDENT` to close outer `IF`.
      outdentElse[1] = 2
      tokens.splice(i + 1, 0, outdentElse)
      # Remove outdents from the end.
      @detectEnd i + 2,
        (token, i) -> token[0] in ['OUTDENT', 'TERMINATOR']
        (token, i) ->
            if @tag(i) is 'OUTDENT' and @tag(i + 1) is 'OUTDENT'
              tokens.splice i, 2
      i + 2

    @scanTokens (token, i, tokens) ->
      [tag] = token
      conditionTag = tag in ['->', '=>'] and
        @findTagsBackwards(i, ['IF', 'WHILE', 'FOR', 'UNTIL', 'SWITCH', 'WHEN', 'LEADING_WHEN', '[', 'INDEX_START']) and
        not (@findTagsBackwards i, ['THEN', '..', '...'])

      if tag is 'TERMINATOR'
        if @tag(i + 1) is 'ELSE' and @tag(i - 1) isnt 'OUTDENT'
          tokens.splice i, 1, @indentation()...
          return 1
        if @tag(i + 1) in EXPRESSION_CLOSE
          if token[1] is ';' and @tag(i + 1) is 'OUTDENT'
            tokens[i + 1].prevToken = token
            moveComments token, tokens[i + 1]
          tokens.splice i, 1
          return 0
      if tag is 'CATCH'
        for j in [1..2] when @tag(i + j) in ['OUTDENT', 'TERMINATOR', 'FINALLY']
          tokens.splice i + j, 0, @indentation()...
          return 2 + j
      if tag in ['->', '=>'] and (@tag(i + 1) in [',', ']'] or @tag(i + 1) is '.' and token.newLine)
        [indent, outdent] = @indentation tokens[i]
        tokens.splice i + 1, 0, indent, outdent
        return 1
      if tag in SINGLE_LINERS and @tag(i + 1) isnt 'INDENT' and
         not (tag is 'ELSE' and @tag(i + 1) is 'IF') and
         not conditionTag
        starter = tag
        [indent, outdent] = @indentation tokens[i]
        indent.fromThen   = true if starter is 'THEN'
        if tag is 'THEN'
          leading_switch_when = @findTagsBackwards(i, ['LEADING_WHEN']) and @tag(i + 1) is 'IF'
          leading_if_then = @findTagsBackwards(i, ['IF']) and @tag(i + 1) is 'IF'
        ifThens.push i if tag is 'THEN' and @findTagsBackwards(i, ['IF'])
        # `ELSE` tag is not closed.
        if tag is 'ELSE' and @tag(i - 1) isnt 'OUTDENT'
          i = closeElseTag tokens, i
        tokens.splice i + 1, 0, indent
        @detectEnd i + 2, condition, action
        tokens.splice i, 1 if tag is 'THEN'
        return 1
      return 1

  # Tag postfix conditionals as such, so that we can parse them with a
  # different precedence.
  tagPostfixConditionals: ->
    original = null

    condition = (token, i) ->
      [tag] = token
      [prevTag] = @tokens[i - 1]
      tag is 'TERMINATOR' or (tag is 'INDENT' and prevTag not in SINGLE_LINERS)

    action = (token, i) ->
      if token[0] isnt 'INDENT' or (token.generated and not token.fromThen)
        original[0] = 'POST_' + original[0]

    @scanTokens (token, i) ->
      return 1 unless token[0] is 'IF'
      original = token
      @detectEnd i + 1, condition, action
      return 1

  # For tokens with extra data, we want to make that data visible to the grammar
  # by wrapping the token value as a String() object and setting the data as
  # properties of that object. The grammar should then be responsible for
  # cleaning this up for the node constructor: unwrapping the token value to a
  # primitive string and separately passing any expected token data properties
  exposeTokenDataToGrammar: ->
    @scanTokens (token, i) ->
      if token.generated or (token.data and Object.keys(token.data).length isnt 0)
        token[1] = new String token[1]
        token[1][key] = val for own key, val of (token.data ? {})
        token[1].generated = yes if token.generated
      1

  # Generate the indentation tokens, based on another token on the same line.
  indentation: (origin) ->
    indent  = ['INDENT', 2]
    outdent = ['OUTDENT', 2]
    if origin
      indent.generated = outdent.generated = yes
      indent.origin = outdent.origin = origin
    else
      indent.explicit = outdent.explicit = yes
    [indent, outdent]

  generate: generate

  # Look up a tag by token index.
  tag: (i) -> @tokens[i]?[0]

# Constants
# ---------

# List of the token pairs that must be balanced.
BALANCED_PAIRS = [
  ['(', ')']
  ['[', ']']
  ['{', '}']
  ['INDENT', 'OUTDENT'],
  ['CALL_START', 'CALL_END']
  ['PARAM_START', 'PARAM_END']
  ['INDEX_START', 'INDEX_END']
  ['STRING_START', 'STRING_END']
  ['INTERPOLATION_START', 'INTERPOLATION_END']
  ['REGEX_START', 'REGEX_END']
]

# The inverse mappings of `BALANCED_PAIRS` we’re trying to fix up, so we can
# look things up from either end.
exports.INVERSES = INVERSES = {}

# The tokens that signal the start/end of a balanced pair.
EXPRESSION_START = []
EXPRESSION_END   = []

for [left, right] in BALANCED_PAIRS
  EXPRESSION_START.push INVERSES[right] = left
  EXPRESSION_END  .push INVERSES[left] = right

# Tokens that indicate the close of a clause of an expression.
EXPRESSION_CLOSE = ['CATCH', 'THEN', 'ELSE', 'FINALLY'].concat EXPRESSION_END

# Tokens that, if followed by an `IMPLICIT_CALL`, indicate a function invocation.
IMPLICIT_FUNC    = ['IDENTIFIER', 'PROPERTY', 'SUPER', ')', 'CALL_END', ']', 'INDEX_END', '@', 'THIS']

# If preceded by an `IMPLICIT_FUNC`, indicates a function invocation.
IMPLICIT_CALL    = [
  'IDENTIFIER', 'JSX_TAG', 'PROPERTY', 'NUMBER', 'INFINITY', 'NAN'
  'STRING', 'STRING_START', 'REGEX', 'REGEX_START', 'JS'
  'NEW', 'PARAM_START', 'CLASS', 'IF', 'TRY', 'SWITCH', 'THIS'
  'UNDEFINED', 'NULL', 'BOOL'
  'UNARY', 'DO', 'DO_IIFE', 'YIELD', 'AWAIT', 'UNARY_MATH', 'SUPER', 'THROW'
  '@', '->', '=>', '[', '(', '{', '--', '++'
]

IMPLICIT_UNSPACED_CALL = ['+', '-']

# Tokens that always mark the end of an implicit call for single-liners.
IMPLICIT_END     = ['POST_IF', 'FOR', 'WHILE', 'UNTIL', 'WHEN', 'BY',
  'LOOP', 'TERMINATOR']

# Single-line flavors of block expressions that have unclosed endings.
# The grammar can’t disambiguate them, so we insert the implicit indentation.
SINGLE_LINERS    = ['ELSE', '->', '=>', 'TRY', 'FINALLY', 'THEN']
SINGLE_CLOSERS   = ['TERMINATOR', 'CATCH', 'FINALLY', 'ELSE', 'OUTDENT', 'LEADING_WHEN']

# Tokens that end a line.
LINEBREAKS       = ['TERMINATOR', 'INDENT', 'OUTDENT']

# Tokens that close open calls when they follow a newline.
CALL_CLOSERS     = ['.', '?.', '::', '?::']

# Tokens that prevent a subsequent indent from ending implicit calls/objects
CONTROL_IN_IMPLICIT = ['IF', 'TRY', 'FINALLY', 'CATCH', 'CLASS', 'SWITCH']

# Tokens that are swallowed up by the parser, never leading to code generation.
# You can spot these in `grammar.coffee` because the `o` function second
# argument doesn’t contain a `new` call for these tokens.
# `STRING_START` isn’t on this list because its `locationData` matches that of
# the node that becomes `StringWithInterpolations`, and therefore
# `addDataToNode` attaches `STRING_START`’s tokens to that node.
DISCARDED = ['(', ')', '[', ']', '{', '}', ':', '.', '..', '...', ',', '=', '++', '--', '?',
  'AS', 'AWAIT', 'CALL_START', 'CALL_END', 'DEFAULT', 'DO', 'DO_IIFE', 'ELSE',
  'EXTENDS', 'EXPORT', 'FORIN', 'FOROF', 'FORFROM', 'IMPORT', 'INDENT', 'INDEX_SOAK',
  'INTERPOLATION_START', 'INTERPOLATION_END', 'LEADING_WHEN', 'OUTDENT', 'PARAM_END',
  'REGEX_START', 'REGEX_END', 'RETURN', 'STRING_END', 'THROW', 'UNARY', 'YIELD'
].concat IMPLICIT_UNSPACED_CALL.concat IMPLICIT_END.concat CALL_CLOSERS.concat CONTROL_IN_IMPLICIT

# Tokens that, when appearing at the end of a line, suppress a following TERMINATOR/INDENT token
exports.UNFINISHED = UNFINISHED = ['\\', '.', '?.', '?::', 'UNARY', 'DO', 'DO_IIFE', 'MATH', 'UNARY_MATH', '+', '-',
           '**', 'SHIFT', 'RELATION', 'COMPARE', '&', '^', '|', '&&', '||',
           'BIN?', 'EXTENDS']
