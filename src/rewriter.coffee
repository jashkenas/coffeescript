# The CoffeeScript language has a good deal of optional syntax, implicit syntax,
# and shorthand syntax. This can greatly complicate a grammar and bloat
# the resulting parse table. Instead of making the parser handle it all, we take
# a series of passes over the token stream, using this **Rewriter** to convert
# shorthand into the unambiguous long form, add implicit indentation and
# parentheses, balance incorrect nestings, and generally clean things up.

# The **Rewriter** class is used by the [Lexer](lexer.html), directly against
# its internal array of tokens.
class exports.Rewriter

  # Helpful snippet for debugging:
  #     console.log (t[0] + '/' + t[1] for t in @tokens).join ' '

  # Rewrite the token stream in multiple passes, one logical filter at
  # a time. This could certainly be changed into a single pass through the
  # stream, with a big ol' efficient switch, but it's much nicer to work with
  # like this. The order of these passes matters -- indentation must be
  # corrected before implicit parentheses can be wrapped around blocks of code.
  rewrite: (@tokens) ->
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
    {tokens} = this
    i = 0
    i += block.call this, token, i, tokens while token = tokens[i]
    true

  detectEnd: (i, condition, action) ->
    {tokens} = this
    levels = 0
    while token = tokens[i]
      return action.call this, token, i     if levels is 0 and condition.call this, token, i
      return action.call this, token, i - 1 if not token or levels < 0
      if token[0] in EXPRESSION_START
        levels += 1
      else if token[0] in EXPRESSION_END
        levels -= 1
      i += 1
    i - 1

  # Leading newlines would introduce an ambiguity in the grammar, so we
  # dispatch them here.
  removeLeadingNewlines: ->
    break for [tag], i in @tokens when tag isnt 'TERMINATOR'
    @tokens.splice 0, i if i

  # Some blocks occur in the middle of expressions -- when we're expecting
  # this, remove their trailing newlines.
  removeMidExpressionNewlines: ->
    @scanTokens (token, i, tokens) ->
      return 1 unless token[0] is 'TERMINATOR' and @tag(i + 1) in EXPRESSION_CLOSE
      tokens.splice i, 1
      0

  # The lexer has tagged the opening parenthesis of a method call. Match it with
  # its paired close. We have the mis-nested outdent case included here for
  # calls that close on the same line, just before their outdent.
  closeOpenCalls: ->
    condition = (token, i) ->
      token[0] in [')', 'CALL_END'] or
      token[0] is 'OUTDENT' and @tag(i - 1) is ')'
    action = (token, i) ->
      @tokens[if token[0] is 'OUTDENT' then i - 1 else i][0] = 'CALL_END'
    @scanTokens (token, i) ->
      @detectEnd i + 1, condition, action if token[0] is 'CALL_START'
      1

  # The lexer has tagged the opening parenthesis of an indexing operation call.
  # Match it with its paired close.
  closeOpenIndexes: ->
    condition = (token, i) -> token[0] in [']', 'INDEX_END']
    action    = (token, i) -> token[0] = 'INDEX_END'
    @scanTokens (token, i) ->
      @detectEnd i + 1, condition, action if token[0] is 'INDEX_START'
      1

  # Object literals may be written with implicit braces, for simple cases.
  # Insert the missing braces here, so that the parser doesn't have to.
  addImplicitBraces: ->
    stack       = []
    start       = null
    startIndent = 0
    condition = (token, i) ->
      [one, two, three] = @tokens[i + 1 .. i + 3]
      return false if 'HERECOMMENT' is one?[0]
      [tag] = token
      (tag in ['TERMINATOR', 'OUTDENT'] and
        not (two?[0] is ':' or one?[0] is '@' and three?[0] is ':')) or
        (tag is ',' and one and
          one[0] not in ['IDENTIFIER', 'NUMBER', 'STRING', '@', 'TERMINATOR', 'OUTDENT'])
    action = (token, i) ->
      tok = ['}', '}', token[2]]
      tok.generated = yes
      @tokens.splice i, 0, tok
    @scanTokens (token, i, tokens) ->
      if (tag = token[0]) in EXPRESSION_START
        stack.push [(if tag is 'INDENT' and @tag(i - 1) is '{' then '{' else tag), i]
        return 1
      if tag in EXPRESSION_END
        start = stack.pop()
        return 1
      return 1 unless tag is ':' and
        ((ago = @tag i - 2) is ':' or stack[stack.length - 1]?[0] isnt '{')
      stack.push ['{']
      idx =  if ago is '@' then i - 2 else i - 1
      idx -= 2 while @tag(idx - 2) is 'HERECOMMENT'
      value = new String('{')
      value.generated = yes
      tok = ['{', value, token[2]]
      tok.generated = yes
      tokens.splice idx, 0, tok
      @detectEnd i + 2, condition, action
      2

  # Methods may be optionally called without parentheses, for simple cases.
  # Insert the implicit parentheses here, so that the parser doesn't have to
  # deal with them.
  addImplicitParentheses: ->
    noCall = no
    action = (token, i) ->
      idx = if token[0] is 'OUTDENT' then i + 1 else i
      @tokens.splice idx, 0, ['CALL_END', ')', token[2]]
    @scanTokens (token, i, tokens) ->
      tag     = token[0]
      noCall  = yes if tag in ['CLASS', 'IF']
      [prev, current, next] = tokens[i - 1 .. i + 1]
      callObject = not noCall and tag is 'INDENT' and
                   next and next.generated and next[0] is '{' and
                   prev and prev[0] in IMPLICIT_FUNC
      seenSingle = no
      noCall     = no if tag in LINEBREAKS
      token.call = yes if prev and not prev.spaced and tag is '?'
      return 1 if token.fromThen
      return 1 unless callObject or
        prev?.spaced and (prev.call or prev[0] in IMPLICIT_FUNC) and
        (tag in IMPLICIT_CALL or not (token.spaced or token.newLine) and tag in IMPLICIT_UNSPACED_CALL)
      tokens.splice i, 0, ['CALL_START', '(', token[2]]
      @detectEnd i + 1, (token, i) ->
        [tag] = token
        return yes if not seenSingle and token.fromThen
        seenSingle = yes if tag in ['IF', 'ELSE', '->', '=>']
        return yes if tag in ['.', '?.', '::'] and @tag(i - 1) is 'OUTDENT'
        not token.generated and @tag(i - 1) isnt ',' and tag in IMPLICIT_END and
        (tag isnt 'INDENT' or
         (@tag(i - 2) isnt 'CLASS' and @tag(i - 1) not in IMPLICIT_BLOCK and
          not ((post = @tokens[i + 1]) and post.generated and post[0] is '{')))
      , action
      prev[0] = 'FUNC_EXIST' if prev[0] is '?'
      2

  # Because our grammar is LALR(1), it can't handle some single-line
  # expressions that lack ending delimiters. The **Rewriter** adds the implicit
  # blocks, so it doesn't need to. ')' can close a single-line block,
  # but we need to make sure it's balanced.
  addImplicitIndentation: ->
    @scanTokens (token, i, tokens) ->
      [tag] = token
      if tag is 'TERMINATOR' and @tag(i + 1) is 'THEN'
        tokens.splice i, 1
        return 0
      if tag is 'ELSE' and @tag(i - 1) isnt 'OUTDENT'
        tokens.splice i, 0, @indentation(token)...
        return 2
      if tag is 'CATCH' and @tag(i + 2) in ['OUTDENT', 'TERMINATOR', 'FINALLY']
        tokens.splice i + 2, 0, @indentation(token)...
        return 4
      if tag in SINGLE_LINERS and @tag(i + 1) isnt 'INDENT' and
         not (tag is 'ELSE' and @tag(i + 1) is 'IF')
        starter = tag
        [indent, outdent] = @indentation token
        indent.fromThen   = true if starter is 'THEN'
        indent.generated  = outdent.generated = true
        tokens.splice i + 1, 0, indent
        condition = (token, i) ->
          token[1] isnt ';' and token[0] in SINGLE_CLOSERS and
          not (token[0] is 'ELSE' and starter not in ['IF', 'THEN'])
        action = (token, i) ->
          @tokens.splice (if @tag(i - 1) is ',' then i - 1 else i), 0, outdent
        @detectEnd i + 2, condition, action
        tokens.splice i, 1 if tag is 'THEN'
        return 1
      return 1

  # Tag postfix conditionals as such, so that we can parse them with a
  # different precedence.
  tagPostfixConditionals: ->
    condition = (token, i) -> token[0] in ['TERMINATOR', 'INDENT']
    @scanTokens (token, i) ->
      return 1 unless token[0] is 'IF'
      original = token
      @detectEnd i + 1, condition, (token, i) ->
        original[0] = 'POST_' + original[0] if token[0] isnt 'INDENT'
      1

  # Ensure that all listed pairs of tokens are correctly balanced throughout
  # the course of the token stream.
  ensureBalance: (pairs) ->
    levels   = {}
    openLine = {}
    for token in @tokens
      [tag] = token
      for [open, close] in pairs
        levels[open] |= 0
        if tag is open
          openLine[open] = token[2] if levels[open]++ is 0
        else if tag is close and --levels[open] < 0
          throw Error "too many #{token[1]} on line #{token[2] + 1}"
    for open, level of levels when level > 0
      throw Error "unclosed #{ open } on line #{openLine[open] + 1}"
    this

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
    debt[key] = 0 for key of INVERSES
    @scanTokens (token, i, tokens) ->
      if (tag = token[0]) in EXPRESSION_START
        stack.push token
        return 1
      return 1 unless tag in EXPRESSION_END
      if debt[inv = INVERSES[tag]] > 0
        debt[inv] -= 1
        tokens.splice i, 1
        return 0
      match = stack.pop()
      mtag  = match[0]
      oppos = INVERSES[mtag]
      return 1 if tag is oppos
      debt[mtag] += 1
      val = [oppos, if mtag is 'INDENT' then match[1] else oppos]
      if @tag(i + 2) is mtag
        tokens.splice i + 3, 0, val
        stack.push match
      else
        tokens.splice i, 0, val
      1

  # Generate the indentation tokens, based on another token on the same line.
  indentation: (token) ->
    [['INDENT', 2, token[2]], ['OUTDENT', 2, token[2]]]

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
]

# The inverse mappings of `BALANCED_PAIRS` we're trying to fix up, so we can
# look things up from either end.
INVERSES = {}

# The tokens that signal the start/end of a balanced pair.
EXPRESSION_START = []
EXPRESSION_END   = []

for [left, rite] in BALANCED_PAIRS
  EXPRESSION_START.push INVERSES[rite] = left
  EXPRESSION_END  .push INVERSES[left] = rite

# Tokens that indicate the close of a clause of an expression.
EXPRESSION_CLOSE = ['CATCH', 'WHEN', 'ELSE', 'FINALLY'].concat EXPRESSION_END

# Tokens that, if followed by an `IMPLICIT_CALL`, indicate a function invocation.
IMPLICIT_FUNC    = ['IDENTIFIER', 'SUPER', ')', 'CALL_END', ']', 'INDEX_END', '@', 'THIS']

# If preceded by an `IMPLICIT_FUNC`, indicates a function invocation.
IMPLICIT_CALL    = [
  'IDENTIFIER', 'NUMBER', 'STRING', 'JS', 'REGEX', 'NEW', 'PARAM_START', 'CLASS'
  'IF', 'TRY', 'SWITCH', 'THIS', 'BOOL', 'UNARY', 'SUPER'
  '@', '->', '=>', '[', '(', '{', '--', '++'
]

IMPLICIT_UNSPACED_CALL = ['+', '-']

# Tokens indicating that the implicit call must enclose a block of expressions.
IMPLICIT_BLOCK   = ['->', '=>', '{', '[', ',']

# Tokens that always mark the end of an implicit call for single-liners.
IMPLICIT_END     = ['POST_IF', 'FOR', 'WHILE', 'UNTIL', 'WHEN', 'BY', 'LOOP', 'TERMINATOR', 'INDENT']

# Single-line flavors of block expressions that have unclosed endings.
# The grammar can't disambiguate them, so we insert the implicit indentation.
SINGLE_LINERS    = ['ELSE', '->', '=>', 'TRY', 'FINALLY', 'THEN']
SINGLE_CLOSERS   = ['TERMINATOR', 'CATCH', 'FINALLY', 'ELSE', 'OUTDENT', 'LEADING_WHEN']

# Tokens that end a line.
LINEBREAKS       = ['TERMINATOR', 'INDENT', 'OUTDENT']
