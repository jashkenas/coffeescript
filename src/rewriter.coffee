# The CoffeeScript language has a good deal of optional syntax, implicit syntax,
# and shorthand syntax. This can greatly complicate a grammar and bloat
# the resulting parse table. Instead of making the parser handle it all, we take
# a series of passes over the token stream, using this **Rewriter** to convert
# shorthand into the unambiguous long form, add implicit indentation and
# parentheses, balance incorrect nestings, and generally clean things up.

# Set up exported variables for both Node.js and the browser.
if process?
  {helpers}: require('./helpers')
else
  this.exports: this
  helpers:      this.helpers

# Import the helpers we need.
{include}: helpers

# The **Rewriter** class is used by the [Lexer](lexer.html), directly against
# its internal array of tokens.
exports.Rewriter: class Rewriter

  # Rewrite the token stream in multiple passes, one logical filter at
  # a time. This could certainly be changed into a single pass through the
  # stream, with a big ol' efficient switch, but it's much nicer to work with
  # like this. The order of these passes matters -- indentation must be
  # corrected before implicit parentheses can be wrapped around blocks of code.
  rewrite: (tokens) ->
    @tokens: tokens
    @adjustComments()
    @removeLeadingNewlines()
    @removeMidExpressionNewlines()
    @closeOpenCallsAndIndexes()
    @addImplicitIndentation()
    @addImplicitParentheses()
    @ensureBalance BALANCED_PAIRS
    @rewriteClosingParens()
    @tokens

  # Rewrite the token stream, looking one token ahead and behind.
  # Allow the return value of the block to tell us how many tokens to move
  # forwards (or backwards) in the stream, to make sure we don't miss anything
  # as tokens are inserted and removed, and the stream changes length under
  # our feet.
  scanTokens: (block) ->
    i: 0
    loop
      break unless @tokens[i]
      move: block @tokens[i - 1], @tokens[i], @tokens[i + 1], i
      i: + move
    true

  # Massage newlines and indentations so that comments don't have to be
  # correctly indented, or appear on a line of their own.
  adjustComments: ->
    @scanTokens (prev, token, post, i) =>
      return 1 unless token[0] is 'HERECOMMENT'
      [before, after]: [@tokens[i - 2], @tokens[i + 2]]
      if after and after[0] is 'INDENT'
        @tokens.splice i + 2, 1
        if before and before[0] is 'OUTDENT' and post and prev[0] is post[0] is 'TERMINATOR'
          @tokens.splice i - 2, 1
        else
          @tokens.splice i, 0, after
      else if prev and prev[0] not in ['TERMINATOR', 'INDENT', 'OUTDENT']
        if post and post[0] is 'TERMINATOR' and after and after[0] is 'OUTDENT'
          @tokens.splice(i + 3, 0, @tokens.splice(i, 2)...)
          @tokens.splice(i + 3, 0, ['TERMINATOR', "\n", prev[2]])
        else
          @tokens.splice i, 0, ['TERMINATOR', "\n", prev[2]]
        return 2
      return 1

  # Leading newlines would introduce an ambiguity in the grammar, so we
  # dispatch them here.
  removeLeadingNewlines: ->
    @tokens.shift() while @tokens[0] and @tokens[0][0] is 'TERMINATOR'

  # Some blocks occur in the middle of expressions -- when we're expecting
  # this, remove their trailing newlines.
  removeMidExpressionNewlines: ->
    @scanTokens (prev, token, post, i) =>
      return 1 unless post and include(EXPRESSION_CLOSE, post[0]) and token[0] is 'TERMINATOR'
      @tokens.splice i, 1
      return 0

  # The lexer has tagged the opening parenthesis of a method call, and the
  # opening bracket of an indexing operation. Match them with their paired
  # close.
  closeOpenCallsAndIndexes: ->
    parens:   [0]
    brackets: [0]
    @scanTokens (prev, token, post, i) =>
      switch token[0]
        when 'CALL_START'  then parens.push 0
        when 'INDEX_START' then brackets.push 0
        when '('           then parens[parens.length - 1]: + 1
        when '['           then brackets[brackets.length - 1]: + 1
        when ')'
          if parens[parens.length - 1] is 0
            parens.pop()
            token[0]: 'CALL_END'
          else
            parens[parens.length - 1]: - 1
        when ']'
          if brackets[brackets.length - 1] == 0
            brackets.pop()
            token[0]: 'INDEX_END'
          else
            brackets[brackets.length - 1]: - 1
      return 1

  # Methods may be optionally called without parentheses, for simple cases.
  # Insert the implicit parentheses here, so that the parser doesn't have to
  # deal with them.
  addImplicitParentheses: ->
    stack: [0]
    closeCalls: (i) =>
      for tmp in [0...stack[stack.length - 1]]
        @tokens.splice(i, 0, ['CALL_END', ')', @tokens[i][2]])
      size: stack[stack.length - 1] + 1
      stack[stack.length - 1]: 0
      size
    @scanTokens (prev, token, post, i) =>
      tag: token[0]
      stack[stack.length - 2]: + stack.pop() if tag is 'OUTDENT'
      open: stack[stack.length - 1] > 0
      if prev and prev.spaced and include(IMPLICIT_FUNC, prev[0]) and include(IMPLICIT_CALL, tag) and
          not (tag is '!' and (post[0] in ['IN', 'OF']))
        @tokens.splice i, 0, ['CALL_START', '(', token[2]]
        stack[stack.length - 1]: + 1
        stack.push 0 if include(EXPRESSION_START, tag)
        return 2
      if include(EXPRESSION_START, tag)
        if tag is 'INDENT' and !token.generated and open and not (prev and include(IMPLICIT_BLOCK, prev[0]))
          size: closeCalls(i)
          stack.push 0
          return size
        stack.push 0
        return 1
      if open and !token.generated and prev[0] isnt ',' and (!post or include(IMPLICIT_END, tag))
        j: 1; j++ while (nx: @tokens[i + j])? and include(IMPLICIT_END, nx[0])
        if nx? and nx[0] is ','
          @tokens.splice(i, 1) if tag is 'TERMINATOR'
        else
          size: closeCalls(i)
          stack.pop() if tag isnt 'OUTDENT' and include EXPRESSION_END, tag
          return size
      if tag isnt 'OUTDENT' and include EXPRESSION_END, tag
        stack[stack.length - 2]: + stack.pop()
        return 1
      return 1

  # Because our grammar is LALR(1), it can't handle some single-line
  # expressions that lack ending delimiters. The **Rewriter** adds the implicit
  # blocks, so it doesn't need to. ')' can close a single-line block,
  # but we need to make sure it's balanced.
  addImplicitIndentation: ->
    @scanTokens (prev, token, post, i) =>
      if token[0] is 'ELSE' and prev[0] isnt 'OUTDENT'
        @tokens.splice i, 0, @indentation(token)...
        return 2
      if token[0] is 'CATCH' and
          (@tokens[i + 2][0] is 'TERMINATOR' or @tokens[i + 2][0] is 'FINALLY')
        @tokens.splice i + 2, 0, @indentation(token)...
        return 4
      return 1 unless include(SINGLE_LINERS, token[0]) and
        post[0] isnt 'INDENT' and
        not (token[0] is 'ELSE' and post[0] is 'IF')
      starter: token[0]
      [indent, outdent]: @indentation token
      indent.generated: outdent.generated: true
      @tokens.splice i + 1, 0, indent
      idx: i + 1
      parens: 0
      loop
        idx: + 1
        tok: @tokens[idx]
        pre: @tokens[idx - 1]
        if (not tok or
            (include(SINGLE_CLOSERS, tok[0]) and tok[1] isnt ';' and parens is 0) or
            (tok[0] is ')' and parens is 0)) and
            not (tok[0] is 'ELSE' and starter not in ['IF', 'THEN'])
          insertion: if pre[0] is "," then idx - 1 else idx
          @tokens.splice insertion, 0, outdent
          break
        parens: + 1 if tok[0] is '('
        parens: - 1 if tok[0] is ')'
      return 1 unless token[0] is 'THEN'
      @tokens.splice i, 1
      return 0

  # Ensure that all listed pairs of tokens are correctly balanced throughout
  # the course of the token stream.
  ensureBalance: (pairs) ->
    levels: {}
    openLine: {}
    @scanTokens (prev, token, post, i) =>
      for pair in pairs
        [open, close]: pair
        levels[open]: or 0
        if token[0] is open
          openLine[open]: token[2] if levels[open] == 0
          levels[open]: + 1
        levels[open]: - 1 if token[0] is close
        throw new Error("too many ${token[1]} on line ${token[2] + 1}") if levels[open] < 0
      return 1
    unclosed: key for key, value of levels when value > 0
    if unclosed.length
      open: unclosed[0]
      line: openLine[open] + 1
      throw new Error "unclosed $open on line $line"

  # We'd like to support syntax like this:
  #
  #     el.click((event) ->
  #       el.hide())
  #
  # In order to accomplish this, move outdents that follow closing parens
  # inwards, safely. The steps to accomplish this are:
  #
  # 1. Check that all paired tokens are balanced and in order.
  # 2. Rewrite the stream with a stack: if you see an `EXPRESSION_START`, add it
  #    to the stack. If you see an `EXPRESSION_END`, pop the stack and replace
  #    it with the inverse of what we've just popped.
  # 3. Keep track of "debt" for tokens that we manufacture, to make sure we end
  #    up balanced in the end.
  # 4. Be careful not to alter array or parentheses delimiters with overzealous
  #    rewriting.
  rewriteClosingParens: ->
    stack: []
    debt:  {}
    (debt[key]: 0) for key, val of INVERSES
    @scanTokens (prev, token, post, i) =>
      tag: token[0]
      inv: INVERSES[token[0]]
      if include EXPRESSION_START, tag
        stack.push token
        return 1
      else if include EXPRESSION_END, tag
        if debt[inv] > 0
          debt[inv]: - 1
          @tokens.splice i, 1
          return 0
        else
          match: stack.pop()
          mtag:  match[0]
          oppos: INVERSES[mtag]
          return 1 if tag is oppos
          debt[mtag]: + 1
          val: [oppos, if mtag is 'INDENT' then match[1] else oppos]
          if @tokens[i + 2]?[0] is mtag
            @tokens.splice i + 3, 0, val
            stack.push(match)
          else
            @tokens.splice i, 0, val
          return 1
      else
        return 1

  # Generate the indentation tokens, based on another token on the same line.
  indentation: (token) ->
    [['INDENT', 2, token[2]], ['OUTDENT', 2, token[2]]]

# Constants
# ---------

# List of the token pairs that must be balanced.
BALANCED_PAIRS: [['(', ')'], ['[', ']'], ['{', '}'], ['INDENT', 'OUTDENT'],
  ['PARAM_START', 'PARAM_END'], ['CALL_START', 'CALL_END'], ['INDEX_START', 'INDEX_END']]

# The inverse mappings of `BALANCED_PAIRS` we're trying to fix up, so we can
# look things up from either end.
INVERSES: {}
for pair in BALANCED_PAIRS
  INVERSES[pair[0]]: pair[1]
  INVERSES[pair[1]]: pair[0]

# The tokens that signal the start of a balanced pair.
EXPRESSION_START: pair[0] for pair in BALANCED_PAIRS

# The tokens that signal the end of a balanced pair.
EXPRESSION_END:   pair[1] for pair in BALANCED_PAIRS

# Tokens that indicate the close of a clause of an expression.
EXPRESSION_CLOSE: ['CATCH', 'WHEN', 'ELSE', 'FINALLY'].concat EXPRESSION_END

# Tokens that, if followed by an `IMPLICIT_CALL`, indicate a function invocation.
IMPLICIT_FUNC:  ['IDENTIFIER', 'SUPER', ')', 'CALL_END', ']', 'INDEX_END', '@']

# If preceded by an `IMPLICIT_FUNC`, indicates a function invocation.
IMPLICIT_CALL:  ['IDENTIFIER', 'NUMBER', 'STRING', 'JS', 'REGEX', 'NEW', 'PARAM_START',
                 'TRY', 'DELETE', 'TYPEOF', 'SWITCH',
                 'TRUE', 'FALSE', 'YES', 'NO', 'ON', 'OFF', '!', '!!',
                 'THIS', 'NULL',
                 '@', '->', '=>', '[', '(', '{']

# Tokens indicating that the implicit call must enclose a block of expressions.
IMPLICIT_BLOCK: ['->', '=>', '{', '[', ',']

# Tokens that always mark the end of an implicit call for single-liners.
IMPLICIT_END:   ['IF', 'UNLESS', 'FOR', 'WHILE', 'UNTIL', 'LOOP', 'TERMINATOR', 'INDENT'].concat EXPRESSION_END

# Single-line flavors of block expressions that have unclosed endings.
# The grammar can't disambiguate them, so we insert the implicit indentation.
SINGLE_LINERS: ['ELSE', "->", "=>", 'TRY', 'FINALLY', 'THEN']
SINGLE_CLOSERS: ['TERMINATOR', 'CATCH', 'FINALLY', 'ELSE', 'OUTDENT', 'LEADING_WHEN']
