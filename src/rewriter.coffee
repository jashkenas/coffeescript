# The CoffeeScript language has a good deal of optional syntax, implicit syntax,
# and shorthand syntax. This can greatly complicate a grammar and bloat
# the resulting parse table. Instead of making the parser handle it all, we take
# a series of passes over the token stream, using this **Rewriter** to convert
# shorthand into the unambiguous long form, add implicit indentation and
# parentheses, balance incorrect nestings, and generally clean things up.

# Set up exported variables for both Node.js and the browser.
if process?
  {helpers} = require('./helpers')
else
  this.exports = this
  helpers      = this.helpers

# Import the helpers we need.
{include} = helpers

# The **Rewriter** class is used by the [Lexer](lexer.html), directly against
# its internal array of tokens.
exports.Rewriter = class Rewriter

  # Helpful snippet for debugging:
  #     puts (t[0] + '/' + t[1] for t in @tokens).join ' '

  # Rewrite the token stream in multiple passes, one logical filter at
  # a time. This could certainly be changed into a single pass through the
  # stream, with a big ol' efficient switch, but it's much nicer to work with
  # like this. The order of these passes matters -- indentation must be
  # corrected before implicit parentheses can be wrapped around blocks of code.
  rewrite: (tokens) ->
    @tokens = tokens
    @adjustComments()
    @removeLeadingNewlines()
    @removeMidExpressionNewlines()
    @closeOpenCalls()
    @closeOpenIndexes()
    @addImplicitIndentation()
    @tagPostfixConditionals()
    @addImplicitBraces()
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
    i = 0
    loop
      break unless @tokens[i]
      move = block.call this, @tokens[i], i
      i += move
    true

  detectEnd: (i, condition, action) ->
    levels = 0
    loop
      token = @tokens[i]
      return action.call this, token, i     if levels is 0 and condition.call this, token, i
      return action.call this, token, i - 1 if not token or levels < 0
      levels += 1 if include EXPRESSION_START, token[0]
      levels -= 1 if include EXPRESSION_END, token[0]
      i += 1
    i - 1

  # Massage newlines and indentations so that comments don't have to be
  # correctly indented, or appear on a line of their own.
  adjustComments: ->
    @scanTokens (token, i) ->
      return 1 unless token[0] is 'HERECOMMENT'
      [before, prev, post, after] = [@tokens[i - 2], @tokens[i - 1], @tokens[i + 1], @tokens[i + 2]]
      if after and after[0] is 'INDENT'
        @tokens.splice i + 2, 1
        if before and before[0] is 'OUTDENT' and post and prev[0] is post[0] is 'TERMINATOR'
          @tokens.splice i - 2, 1
        else
          @tokens.splice i, 0, after
      else if prev and prev[0] not in ['TERMINATOR', 'INDENT', 'OUTDENT']
        if post and post[0] is 'TERMINATOR' and after and after[0] is 'OUTDENT'
          @tokens.splice(i + 2, 0, @tokens.splice(i, 2)...)
          if @tokens[i + 2][0] isnt 'TERMINATOR'
            @tokens.splice i + 2, 0, ['TERMINATOR', "\n", prev[2]]
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
    @scanTokens (token, i) ->
      return 1 unless include(EXPRESSION_CLOSE, @tag(i + 1)) and token[0] is 'TERMINATOR'
      @tokens.splice i, 1
      return 0

  # The lexer has tagged the opening parenthesis of a method call. Match it with
  # its paired close. We have the mis-nested outdent case included here for
  # calls that close on the same line, just before their outdent.
  closeOpenCalls: ->
    @scanTokens (token, i) ->
      if token[0] is 'CALL_START'
        condition = (token, i) ->
          (token[0] in [')', 'CALL_END']) or (token[0] is 'OUTDENT' and @tokens[i - 1][0] is ')')
        action = (token, i) ->
          idx = if token[0] is 'OUTDENT' then i - 1 else i
          @tokens[idx][0] = 'CALL_END'
        @detectEnd i + 1, condition, action
      return 1

  # The lexer has tagged the opening parenthesis of an indexing operation call.
  # Match it with its paired close.
  closeOpenIndexes: ->
    @scanTokens (token, i) ->
      if token[0] is 'INDEX_START'
        condition = (token, i) -> token[0] in [']', 'INDEX_END']
        action    = (token, i) -> token[0] = 'INDEX_END'
        @detectEnd i + 1, condition, action
      return 1

  # Object literals may be written with implicit braces, for simple cases.
  # Insert the missing braces here, so that the parser doesn't have to.
  addImplicitBraces: ->
    stack = []
    @scanTokens (token, i) ->
      if include EXPRESSION_START, token[0]
        stack.push(if (token[0] is 'INDENT' and (@tag(i - 1) is '{')) then '{' else token[0])
      if include EXPRESSION_END, token[0]
        stack.pop()
      last = stack[stack.length - 1]
      if token[0] is ':' and (not last or last[0] isnt '{')
        stack.push '{'
        idx = if @tag(i - 2) is '@' then i - 2 else i - 1
        tok = ['{', '{', token[2]]
        tok.generated = yes
        @tokens.splice idx, 0, tok
        condition = (token, i) ->
          [one, two, three] = @tokens.slice(i + 1, i + 4)
          return false if 'HERECOMMENT' in [@tag(i + 1), @tag(i - 1)]
          ((token[0] in ['TERMINATOR', 'OUTDENT']) and not ((two and two[0] is ':') or (one and one[0] is '@' and three and three[0] is ':'))) or
            (token[0] is ',' and one and (one[0] not in ['IDENTIFIER', 'STRING', '@', 'TERMINATOR', 'OUTDENT']))
        action = (token, i) ->
          @tokens.splice i, 0, ['}', '}', token[2]]
        @detectEnd i + 2, condition, action
        return 2
      return 1

  # Methods may be optionally called without parentheses, for simple cases.
  # Insert the implicit parentheses here, so that the parser doesn't have to
  # deal with them.
  addImplicitParentheses: ->
    classLine    = no
    @scanTokens (token, i) ->
      classLine  = yes if token[0] is 'CLASS'
      prev       = @tokens[i - 1]
      next       = @tokens[i + 1]
      idx        = 1
      callObject = not classLine and token[0] is 'INDENT' and next and next.generated and next[0] is '{' and prev and include(IMPLICIT_FUNC, prev[0])
      idx        = 2 if callObject
      seenSingle = no
      classLine  = no  if include(LINEBREAKS, token[0])
      token.call = yes if prev and not prev.spaced and token[0] is '?'
      if prev and (prev.spaced and (include(IMPLICIT_FUNC, prev[0]) or prev.call) and include(IMPLICIT_CALL, token[0]) and
          not (token[0] is 'UNARY' and (@tag(i + 1) in ['IN', 'OF', 'INSTANCEOF']))) or callObject
        @tokens.splice i, 0, ['CALL_START', '(', token[2]]
        condition = (token, i) ->
          return yes if not seenSingle and token.fromThen
          seenSingle = yes if token[0] in ['IF', 'ELSE', 'UNLESS', '->', '=>']
          (not token.generated and @tokens[i - 1][0] isnt ',' and include(IMPLICIT_END, token[0]) and
            not (token[0] is 'INDENT' and (include(IMPLICIT_BLOCK, @tag(i - 1)) or @tag(i - 2) is 'CLASS' or @tag(i + 1) is '{'))) or
            token[0] is 'PROPERTY_ACCESS' and @tag(i - 1) is 'OUTDENT'
        action = (token, i) ->
          idx = if token[0] is 'OUTDENT' then i + 1 else i
          @tokens.splice idx, 0, ['CALL_END', ')', token[2]]
        @detectEnd i + idx, condition, action
        prev[0] = 'FUNC_EXIST' if prev[0] is '?'
        return 2
      return 1

  # Because our grammar is LALR(1), it can't handle some single-line
  # expressions that lack ending delimiters. The **Rewriter** adds the implicit
  # blocks, so it doesn't need to. ')' can close a single-line block,
  # but we need to make sure it's balanced.
  addImplicitIndentation: ->
    @scanTokens (token, i) ->
      if token[0] is 'ELSE' and @tag(i - 1) isnt 'OUTDENT'
        @tokens.splice i, 0, @indentation(token)...
        return 2
      if token[0] is 'CATCH' and
          (@tag(i + 2) is 'TERMINATOR' or @tag(i + 2) is 'FINALLY')
        @tokens.splice i + 2, 0, @indentation(token)...
        return 4
      if include(SINGLE_LINERS, token[0]) and @tag(i + 1) isnt 'INDENT' and
          not (token[0] is 'ELSE' and @tag(i + 1) is 'IF')
        starter = token[0]
        [indent, outdent] = @indentation token
        indent.fromThen   = true if starter is 'THEN'
        indent.generated  = outdent.generated = true
        @tokens.splice i + 1, 0, indent
        condition = (token, i) ->
          (include(SINGLE_CLOSERS, token[0]) and token[1] isnt ';') and
            not (token[0] is 'ELSE' and starter not in ['IF', 'THEN'])
        action = (token, i) ->
          idx = if @tokens[i - 1][0] is ',' then i - 1 else i
          @tokens.splice idx, 0, outdent
        @detectEnd i + 2, condition, action
        @tokens.splice i, 1 if token[0] is 'THEN'
        return 2
      return 1

  # Tag postfix conditionals as such, so that we can parse them with a
  # different precedence.
  tagPostfixConditionals: ->
    @scanTokens (token, i) ->
      if token[0] in ['IF', 'UNLESS']
        original  = token
        condition = (token, i) ->
          token[0] in ['TERMINATOR', 'INDENT']
        action    = (token, i) ->
          original[0] = 'POST_' + original[0] if token[0] isnt 'INDENT'
        @detectEnd i + 1, condition, action
        return 1
      return 1

  # Ensure that all listed pairs of tokens are correctly balanced throughout
  # the course of the token stream.
  ensureBalance: (pairs) ->
    levels   = {}
    openLine = {}
    @scanTokens (token, i) ->
      for pair in pairs
        [open, close] = pair
        levels[open] or= 0
        if token[0] is open
          openLine[open] = token[2] if levels[open] == 0
          levels[open] += 1
        levels[open] -= 1 if token[0] is close
        throw new Error("too many #{token[1]} on line #{token[2] + 1}") if levels[open] < 0
      return 1
    unclosed = key for key, value of levels when value > 0
    if unclosed.length
      open = unclosed[0]
      line = openLine[open] + 1
      throw new Error "unclosed #{open} on line #{line}"

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
    stack = []
    debt  = {}
    (debt[key] = 0) for key, val of INVERSES
    @scanTokens (token, i) ->
      tag = token[0]
      inv = INVERSES[token[0]]
      if include EXPRESSION_START, tag
        stack.push token
        return 1
      else if include EXPRESSION_END, tag
        if debt[inv] > 0
          debt[inv] -= 1
          @tokens.splice i, 1
          return 0
        else
          match = stack.pop()
          mtag  = match[0]
          oppos = INVERSES[mtag]
          return 1 if tag is oppos
          debt[mtag] += 1
          val = [oppos, if mtag is 'INDENT' then match[1] else oppos]
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

  # Look up a tag by token index.
  tag: (i) ->
    @tokens[i] and @tokens[i][0]

# Constants
# ---------

# List of the token pairs that must be balanced.
BALANCED_PAIRS = [['(', ')'], ['[', ']'], ['{', '}'], ['INDENT', 'OUTDENT'],
  ['PARAM_START', 'PARAM_END'], ['CALL_START', 'CALL_END'], ['INDEX_START', 'INDEX_END']]

# The inverse mappings of `BALANCED_PAIRS` we're trying to fix up, so we can
# look things up from either end.
INVERSES = {}
for pair in BALANCED_PAIRS
  INVERSES[pair[0]] = pair[1]
  INVERSES[pair[1]] = pair[0]

# The tokens that signal the start of a balanced pair.
EXPRESSION_START = pair[0] for pair in BALANCED_PAIRS

# The tokens that signal the end of a balanced pair.
EXPRESSION_END   = pair[1] for pair in BALANCED_PAIRS

# Tokens that indicate the close of a clause of an expression.
EXPRESSION_CLOSE = ['CATCH', 'WHEN', 'ELSE', 'FINALLY'].concat EXPRESSION_END

# Tokens that, if followed by an `IMPLICIT_CALL`, indicate a function invocation.
IMPLICIT_FUNC    = ['IDENTIFIER', 'SUPER', ')', 'CALL_END', ']', 'INDEX_END', '@', 'THIS']

# If preceded by an `IMPLICIT_FUNC`, indicates a function invocation.
IMPLICIT_CALL    = [
  'IDENTIFIER', 'NUMBER', 'STRING', 'JS', 'REGEX', 'NEW', 'PARAM_START', 'CLASS',
  'IF', 'UNLESS', 'TRY', 'SWITCH', 'THIS', 'NULL', 'UNARY'
  'TRUE', 'FALSE', 'YES', 'NO', 'ON', 'OFF',
  '@', '->', '=>', '[', '(', '{'
]

# Tokens indicating that the implicit call must enclose a block of expressions.
IMPLICIT_BLOCK   = ['->', '=>', '{', '[', ',']

# Tokens that always mark the end of an implicit call for single-liners.
IMPLICIT_END     = ['POST_IF', 'POST_UNLESS', 'FOR', 'WHILE', 'UNTIL', 'LOOP', 'TERMINATOR', 'INDENT']

# Single-line flavors of block expressions that have unclosed endings.
# The grammar can't disambiguate them, so we insert the implicit indentation.
SINGLE_LINERS    = ['ELSE', "->", "=>", 'TRY', 'FINALLY', 'THEN']
SINGLE_CLOSERS   = ['TERMINATOR', 'CATCH', 'FINALLY', 'ELSE', 'OUTDENT', 'LEADING_WHEN']

# Tokens that end a line.
LINEBREAKS       = ['TERMINATOR', 'INDENT', 'OUTDENT']
