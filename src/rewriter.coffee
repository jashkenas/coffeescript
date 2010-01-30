# In order to keep the grammar simple, the stream of tokens that the Lexer
# emits is rewritten by the Rewriter, smoothing out ambiguities, mis-nested
# indentation, and single-line flavors of expressions.
exports.Rewriter: re: ->

# Tokens that must be balanced.
BALANCED_PAIRS: [['(', ')'], ['[', ']'], ['{', '}'], ['INDENT', 'OUTDENT'],
  ['PARAM_START', 'PARAM_END'], ['CALL_START', 'CALL_END'], ['INDEX_START', 'INDEX_END']]

# Tokens that signal the start of a balanced pair.
EXPRESSION_START: pair[0] for pair in BALANCED_PAIRS

# Tokens that signal the end of a balanced pair.
EXPRESSION_TAIL: pair[1] for pair in BALANCED_PAIRS

# Tokens that indicate the close of a clause of an expression.
EXPRESSION_CLOSE: ['CATCH', 'WHEN', 'ELSE', 'FINALLY'].concat(EXPRESSION_TAIL)

# Tokens pairs that, in immediate succession, indicate an implicit call.
IMPLICIT_FUNC: ['IDENTIFIER', 'SUPER', ')', 'CALL_END', ']', 'INDEX_END']
IMPLICIT_END:  ['IF', 'UNLESS', 'FOR', 'WHILE', "\n", 'OUTDENT']
IMPLICIT_CALL: ['IDENTIFIER', 'NUMBER', 'STRING', 'JS', 'REGEX', 'NEW', 'PARAM_START',
                 'TRY', 'DELETE', 'TYPEOF', 'SWITCH', 'ARGUMENTS',
                 'TRUE', 'FALSE', 'YES', 'NO', 'ON', 'OFF', '!', '!!', 'NOT',
                 '->', '=>', '[', '(', '{']

# The inverse mappings of token pairs we're trying to fix up.
INVERSES: {}
for pair in BALANCED_PAIRS
  INVERSES[pair[0]]: pair[1]
  INVERSES[pair[1]]: pair[0]

# Single-line flavors of block expressions that have unclosed endings.
# The grammar can't disambiguate them, so we insert the implicit indentation.
SINGLE_LINERS: ['ELSE', "->", "=>", 'TRY', 'FINALLY', 'THEN']
SINGLE_CLOSERS: ["\n", 'CATCH', 'FINALLY', 'ELSE', 'OUTDENT', 'LEADING_WHEN', 'PARAM_START']

# Rewrite the token stream in multiple passes, one logical filter at
# a time. This could certainly be changed into a single pass through the
# stream, with a big ol' efficient switch, but it's much nicer like this.
re::rewrite: (tokens) ->
  this.tokens: tokens
  this.adjust_comments()
  this.remove_leading_newlines()
  this.remove_mid_expression_newlines()
  this.move_commas_outside_outdents()
  this.close_open_calls_and_indexes()
  this.add_implicit_parentheses()
  this.add_implicit_indentation()
  # this.ensure_balance(BALANCED_PAIRS)
  # this.rewrite_closing_parens()
  this.tokens

# Rewrite the token stream, looking one token ahead and behind.
# Allow the return value of the block to tell us how many tokens to move
# forwards (or backwards) in the stream, to make sure we don't miss anything
# as the stream changes length under our feet.
re::scan_tokens: (yield) ->
  i: 0
  while true
    break unless this.tokens[i]
    move: yield(this.tokens[i - 1], this.tokens[i], this.tokens[i + 1], i)
    i += move
  true

# Massage newlines and indentations so that comments don't have to be
# correctly indented, or appear on their own line.
re::adjust_comments: ->
  this.scan_tokens (prev, token, post, i) =>
    return 1 unless token[0] is 'COMMENT'
    before: this.tokens[i - 2]
    after:  this.tokens[i + 2]
    if before and after and
        ((before[0] is 'INDENT' and after[0] is 'OUTDENT') or
        (before[0] is 'OUTDENT' and after[0] is 'INDENT')) and
        before[1] is after[1]
      this.tokens.splice(i + 2, 1)
      this.tokens.splice(i - 2, 1)
      return 0
    else if prev[0] is "\n" and after[0] is 'INDENT'
      this.tokens.splice(i + 2, 1)
      this.tokens[i - 1]: after
      return 1
    else if prev[0] isnt "\n" and prev[0] isnt 'INDENT' and prev[0] isnt 'OUTDENT'
      this.tokens.splice(i, 0, ["\n", "\n"])
      return 2
    else
      return 1

# Leading newlines would introduce an ambiguity in the grammar, so we
# dispatch them here.
re::remove_leading_newlines: ->
  this.tokens.shift() if this.tokens[0][0] is "\n"

# Some blocks occur in the middle of expressions -- when we're expecting
# this, remove their trailing newlines.
re::remove_mid_expression_newlines: ->
  this.scan_tokens (prev, token, post, i) =>
    return 1 unless post and EXPRESSION_CLOSE.indexOf(post[0]) >= 0 and token[0] is "\n"
    this.tokens.splice(i, 1)
    return 0

# Make sure that we don't accidentally break trailing commas, which need
# to go on the outside of expression closers.
re::move_commas_outside_outdents: ->
  this.scan_tokens (prev, token, post, i) =>
    this.tokens.splice(i, 1, token) if token[0] is 'OUTDENT' and prev[0] is ','
    return 1

# We've tagged the opening parenthesis of a method call, and the opening
# bracket of an indexing operation. Match them with their close.
re::close_open_calls_and_indexes: ->
  parens:   [0]
  brackets: [0]
  this.scan_tokens (prev, token, post, i) =>
    switch token[0]
      when 'CALL_START'  then parens.push(0)
      when 'INDEX_START' then brackets.push(0)
      when '('           then parens[-1] += 1
      when '['           then brackets[-1] += 1
      when ')'
        if parens[parens.length - 1] is 0
          parens.pop
          token[0]: 'CALL_END'
        else
          parens[parens.length - 1] -= 1
      when ']'
        if brackets[brackets.length - 1] == 0
          brackets.pop()
          token[0]: 'INDEX_END'
        else
          brackets[brackets.length - 1] -= 1
    return 1

# Methods may be optionally called without parentheses, for simple cases.
# Insert the implicit parentheses here, so that the parser doesn't have to
# deal with them.
re::add_implicit_parentheses: ->
  stack: [0]
  this.scan_tokens (prev, token, post, i) =>
    stack.push(0) if token[0] is 'INDENT'
    if token[0] is 'OUTDENT'
      last: stack.pop()
      stack[stack.length - 1] += last
    if stack[stack.length - 1] > 0 and (IMPLICIT_END.indexOf(token[0]) >= 0 or !post?)
      idx: if token[0] is 'OUTDENT' then i + 1 else i
      for tmp in [0...stack[stack.length - 1]]
        this.tokens.splice(idx, 0, ['CALL_END', ')'])
      size: stack[stack.length - 1] + 1
      stack[stack.length - 1]: 0
      return size
    return 1 unless prev and IMPLICIT_FUNC.indexOf(prev[0]) >= 0 and IMPLICIT_CALL.indexOf(token[0]) >= 0
    this.tokens.splice(i, 0, ['CALL_START', '('])
    stack[stack.length - 1] += 1
    return 2

# Because our grammar is LALR(1), it can't handle some single-line
# expressions that lack ending delimiters. Use the lexer to add the implicit
# blocks, so it doesn't need to.
# ')' can close a single-line block, but we need to make sure it's balanced.
re::add_implicit_indentation: ->
  this.scan_tokens (prev, token, post, i) =>
    return 1 unless SINGLE_LINERS.indexOf(token[0]) >= 0 and post[0] isnt 'INDENT' and
      not (token[0] is 'ELSE' and post[0] is 'IF')
    starter: token[0]
    this.tokens.splice(i + 1, 0, ['INDENT', 2])
    idx: i + 1
    parens: 0
    while true
      idx += 1
      tok: this.tokens[idx]
      if (not tok or SINGLE_CLOSERS.indexOf(tok[0]) >= 0 or
          (tok[0] is ')' && parens is 0)) and
          not (starter is 'ELSE' and tok[0] is 'ELSE')
        insertion: if this.tokens[idx - 1][0] is "," then idx - 1 else idx
        this.tokens.splice(insertion, 0, ['OUTDENT', 2])
        break
      parens += 1 if tok[0] is '('
      parens -= 1 if tok[0] is ')'
    return 1 unless token[0] is 'THEN'
    this.tokens.splice(i, 1)
    return 0








































