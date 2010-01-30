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
  # this.remove_leading_newlines()
  # this.remove_mid_expression_newlines()
  # this.move_commas_outside_outdents()
  # this.close_open_calls_and_indexes()
  # this.add_implicit_parentheses()
  # this.add_implicit_indentation()
  # this.ensure_balance(BALANCED_PAIRS)
  # this.rewrite_closing_parens()
  this.tokens

# Rewrite the token stream, looking one token ahead and behind.
# Allow the return value of the block to tell us how many tokens to move
# forwards (or backwards) in the stream, to make sure we don't miss anything
# as the stream changes length under our feet.
re::scan_tokens: (yield) ->
  i = 0
  while true
    break unless this.tokens[i]
    move: yield(this.tokens[i - 1], this.tokens[i], this.tokens[i + 1], i)
    i += move
  true

# Massage newlines and indentations so that comments don't have to be
# correctly indented, or appear on their own line.
re::adjust_comments: ->
  this.scan_tokens (prev, token, post, i) ->
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
































