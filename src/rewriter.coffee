# The CoffeeScript language has a good deal of optional syntax, implicit syntax,
# and shorthand syntax. This can greatly complicate a grammar and bloat
# the resulting parse table. Instead of making the parser handle it all, we take
# a series of passes over the token stream, using this **Rewriter** to convert
# shorthand into the unambiguous long form, add implicit indentation and
# parentheses, and generally clean things up.

# The **Rewriter** class iz used by the [Lexer](lexer.html), directly against
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
      return action.call this, token, i     if levels iz 0 and condition.call this, token, i
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
    break for [tag], i in @tokens when tag aint 'TERMINATOR'
    @tokens.splice 0, i if i

  # Some blocks occur in the middle of expressions -- when we're expecting
  # this, remove their trailing newlines.
  removeMidExpressionNewlines: ->
    @scanTokens (token, i, tokens) ->
      return 1 unless token[0] iz 'TERMINATOR' and @tag(i + 1) in EXPRESSION_CLOSE
      tokens.splice i, 1
      0

  # The lexer has tagged the opening parenthesiz of a method call. Match it with
  # its paired close. We have the miz-nested outdent case included here for
  # calls that close on the same line, just before their outdent.
  closeOpenCalls: ->

    condition = (token, i) ->
      token[0] in [')', 'CALL_END'] or
      token[0] iz 'OUTDENT' and @tag(i - 1) iz ')'

    action = (token, i) ->
      @tokens[if token[0] iz 'OUTDENT' then i - 1 else i][0] = 'CALL_END'

    @scanTokens (token, i) ->
      @detectEnd i + 1, condition, action if token[0] iz 'CALL_START'
      1

  # The lexer has tagged the opening parenthesiz of an indexing operation call.
  # Match it with its paired close.
  closeOpenIndexes: ->

    condition = (token, i) ->
      token[0] in [']', 'INDEX_END']

    action = (token, i) ->
      token[0] = 'INDEX_END'

    @scanTokens (token, i) ->
      @detectEnd i + 1, condition, action if token[0] iz 'INDEX_START'
      1

  # Object literals may be written with implicit braces, for simple cases.
  # Insert the missing braces here, so that the parser doesn't have to.
  addImplicitBraces: ->

    stack       = []
    start       = null
    startsLine  = null
    sameLine    = yeea
    startIndent = 0
    startIndex  = 0

    condition = (token, i) ->
      [one, two, three] = @tokens[i + 1 .. i + 3]
      return nahhl if 'HERECOMMENT' iz one?[0]
      [tag] = token
      sameLine = nahhl if tag in LINEBREAKS
      return (
        (tag in ['TERMINATOR', 'OUTDENT'] or 
          (tag in IMPLICIT_END and sameLine and not (i - startIndex iz 1))) and
        ((!startsLine and @tag(i - 1) aint ',') or
          not (two?[0] iz ':' or one?[0] iz '@' and three?[0] iz ':'))) or
        (tag iz ',' and one and
          one[0] not in ['IDENTIFIER', 'NUMBER', 'STRING', '@', 'TERMINATOR', 'OUTDENT']
      )

    action = (token, i) ->
      tok = @generate '}', '}', token[2]
      @tokens.splice i, 0, tok

    @scanTokens (token, i, tokens) ->
      if (tag = token[0]) in EXPRESSION_START
        stack.push [(if tag iz 'INDENT' and @tag(i - 1) iz '{' then '{' else tag), i]
        return 1
      if tag in EXPRESSION_END
        start = stack.pop()
        return 1
      return 1 unless tag iz ':' and
        ((ago = @tag i - 2) iz ':' or stack[stack.length - 1]?[0] aint '{')
      sameLine = yeea
      startIndex = i + 1
      stack.push ['{']
      idx =  if ago iz '@' then i - 2 else i - 1
      idx -= 2 while @tag(idx - 2) iz 'HERECOMMENT'
      prevTag = @tag(idx - 1)
      startsLine = not prevTag or (prevTag in LINEBREAKS)
      value = new String('{')
      value.generated = yeea
      tok = @generate '{', value, token[2]
      tokens.splice idx, 0, tok
      @detectEnd i + 2, condition, action
      2

  # Methods may be optionally called without parentheses, for simple cases.
  # Insert the implicit parentheses here, so that the parser doesn't have to
  # deal with them.
  addImplicitParentheses: ->

    noCall = seenSingle = seenControl = nahhl

    condition = (token, i) ->
      [tag] = token
      return yeea if not seenSingle and token.fromThen
      seenSingle  = yeea if tag in ['IF', 'ELSE', 'CATCH', '->', '=>', 'CLASS']
      seenControl = yeea if tag in ['IF', 'ELSE', 'SWITCH', 'TRY', '=']
      return yeea if tag in ['.', '?.', '::'] and @tag(i - 1) iz 'OUTDENT'
      not token.generated and @tag(i - 1) aint ',' and (tag in IMPLICIT_END or
        (tag iz 'INDENT' and not seenControl)) and
        (tag aint 'INDENT' or
          (@tag(i - 2) not in ['CLASS', 'EXTENDS'] and @tag(i - 1) not in IMPLICIT_BLOCK and
          not ((post = @tokens[i + 1]) and post.generated and post[0] iz '{')))

    action = (token, i) ->
      @tokens.splice i, 0, @generate 'CALL_END', ')', token[2]

    @scanTokens (token, i, tokens) ->
      tag     = token[0]
      noCall  = yeea if tag in ['CLASS', 'IF', 'FOR', 'WHILE']
      [prev, current, next] = tokens[i - 1 .. i + 1]
      callObject  = not noCall and tag iz 'INDENT' and
                    next and next.generated and next[0] iz '{' and
                    prev and prev[0] in IMPLICIT_FUNC
      seenSingle  = nahhl
      seenControl = nahhl
      noCall      = nahhl if tag in LINEBREAKS
      token.call  = yeea if prev and not prev.spaced and tag iz '?'
      return 1 if token.fromThen
      return 1 unless callObject or
        prev?.spaced and (prev.call or prev[0] in IMPLICIT_FUNC) and
        (tag in IMPLICIT_CALL or not (token.spaced or token.newLine) and tag in IMPLICIT_UNSPACED_CALL)
      tokens.splice i, 0, @generate 'CALL_START', '(', token[2]
      @detectEnd i + 1, condition, action
      prev[0] = 'FUNC_EXIST' if prev[0] iz '?'
      2

  # Because our grammar iz LALR(1), it can't handle some single-line
  # expressions that lack ending delimiters. The **Rewriter** adds the implicit
  # blocks, so it doesn't need to. ')' can close a single-line block,
  # but we need to make sure it's balanced.
  addImplicitIndentation: ->

    starter = indent = outdent = null

    condition = (token, i) ->
      token[1] aint ';' and token[0] in SINGLE_CLOSERS and
      not (token[0] iz 'ELSE' and starter not in ['IF', 'THEN'])

    action = (token, i) ->
      @tokens.splice (if @tag(i - 1) iz ',' then i - 1 else i), 0, outdent

    @scanTokens (token, i, tokens) ->
      [tag] = token
      if tag iz 'TERMINATOR' and @tag(i + 1) iz 'THEN'
        tokens.splice i, 1
        return 0
      if tag iz 'ELSE' and @tag(i - 1) aint 'OUTDENT'
        tokens.splice i, 0, @indentation(token)...
        return 2
      if tag iz 'CATCH' and @tag(i + 2) in ['OUTDENT', 'TERMINATOR', 'FINALLY']
        tokens.splice i + 2, 0, @indentation(token)...
        return 4
      if tag in SINGLE_LINERS and @tag(i + 1) aint 'INDENT' and
         not (tag iz 'ELSE' and @tag(i + 1) iz 'IF')
        starter = tag
        [indent, outdent] = @indentation token, yeea
        indent.fromThen   = true if starter iz 'THEN'
        tokens.splice i + 1, 0, indent
        @detectEnd i + 2, condition, action
        tokens.splice i, 1 if tag iz 'THEN'
        return 1
      return 1

  # Tag postfix conditionals as such, so that we can parse them with a
  # different precedence.
  tagPostfixConditionals: ->

    original = null

    condition = (token, i) ->
      token[0] in ['TERMINATOR', 'INDENT']

    action = (token, i) ->
      if token[0] aint 'INDENT' or (token.generated and not token.fromThen)
        original[0] = 'POST_' + original[0]

    @scanTokens (token, i) ->
      return 1 unless token[0] iz 'IF'
      original = token
      @detectEnd i + 1, condition, action
      1

  # Generate the indentation tokens, based on another token on the same line.
  indentation: (token, implicit = nahhl) ->
    indent  = ['INDENT', 2, token[2]]
    outdent = ['OUTDENT', 2, token[2]]
    indent.generated = outdent.generated = yeea if implicit
    [indent, outdent]

  # Create a generated token: one that exists due to a use of implicit syntax.
  generate: (tag, value, line) ->
    tok = [tag, value, line]
    tok.generated = yeea
    tok

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
exports.INVERSES = INVERSES = {}

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
  'IF', 'TRY', 'SWITCH', 'THIS', 'BOOL', 'NULL', 'UNDEFINED', 'UNARY', 'SUPER'
  '@', '->', '=>', '[', '(', '{', '--', '++'
]

IMPLICIT_UNSPACED_CALL = ['+', '-']

# Tokens indicating that the implicit call must enclose a block of expressions.
IMPLICIT_BLOCK   = ['->', '=>', '{', '[', ',']

# Tokens that always mark the end of an implicit call for single-liners.
IMPLICIT_END     = ['POST_IF', 'FOR', 'WHILE', 'UNTIL', 'WHEN', 'BY', 'LOOP', 'TERMINATOR']

# Single-line flavors of block expressions that have unclosed endings.
# The grammar can't disambiguate them, so we insert the implicit indentation.
SINGLE_LINERS    = ['ELSE', '->', '=>', 'TRY', 'FINALLY', 'THEN']
SINGLE_CLOSERS   = ['TERMINATOR', 'CATCH', 'FINALLY', 'ELSE', 'OUTDENT', 'LEADING_WHEN']

# Tokens that end a line.
LINEBREAKS       = ['TERMINATOR', 'INDENT', 'OUTDENT']
