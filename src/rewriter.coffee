# The CoffeeScript language has a decent amount of optional syntax,
# implicit syntax, and shorthand syntax. These things can greatly complicate a
# grammar and bloat the resulting parse table. Instead of making the parser
# handle it all, we take a series of passes over the token stream,
# using this **Rewriter** to convert shorthand into the unambiguous long form,
# add implicit indentation and parentheses, balance incorrect nestings, and
# generally clean things up.

# Set up exported variables for both Node.js and the browser.
if process?
  process.mixin require './helpers'
else
  this.exports: this

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
    @adjust_comments()
    @remove_leading_newlines()
    @remove_mid_expression_newlines()
    @close_open_calls_and_indexes()
    @add_implicit_indentation()
    @add_implicit_parentheses()
    @ensure_balance(BALANCED_PAIRS)
    @rewrite_closing_parens()
    @tokens

  # Rewrite the token stream, looking one token ahead and behind.
  # Allow the return value of the block to tell us how many tokens to move
  # forwards (or backwards) in the stream, to make sure we don't miss anything
  # as tokens are inserted and removed, and the stream changes length under
  # our feet.
  scan_tokens: (block) ->
    i: 0
    while true
      break unless @tokens[i]
      move: block(@tokens[i - 1], @tokens[i], @tokens[i + 1], i)
      i += move
    true

  # Massage newlines and indentations so that comments don't have to be
  # correctly indented, or appear on a line of their own.
  adjust_comments: ->
    @scan_tokens (prev, token, post, i) =>
      return 1 unless token[0] is 'COMMENT'
      after:  @tokens[i + 2]
      if after and after[0] is 'INDENT'
        @tokens.splice(i + 2, 1)
        @tokens.splice(i, 0, after)
        return 1
      else if prev and prev[0] isnt 'TERMINATOR' and prev[0] isnt 'INDENT' and prev[0] isnt 'OUTDENT'
        @tokens.splice(i, 0, ['TERMINATOR', "\n", prev[2]])
        return 2
      else
        return 1

  # Leading newlines would introduce an ambiguity in the grammar, so we
  # dispatch them here.
  remove_leading_newlines: ->
    @tokens.shift() while @tokens[0] and @tokens[0][0] is 'TERMINATOR'

  # Some blocks occur in the middle of expressions -- when we're expecting
  # this, remove their trailing newlines.
  remove_mid_expression_newlines: ->
    @scan_tokens (prev, token, post, i) =>
      return 1 unless post and include(EXPRESSION_CLOSE, post[0]) and token[0] is 'TERMINATOR'
      @tokens.splice(i, 1)
      return 0

  # The lexer has tagged the opening parenthesis of a method call, and the
  # opening bracket of an indexing operation. Match them with their paired
  # close.
  close_open_calls_and_indexes: ->
    parens:   [0]
    brackets: [0]
    @scan_tokens (prev, token, post, i) =>
      switch token[0]
        when 'CALL_START'  then parens.push(0)
        when 'INDEX_START' then brackets.push(0)
        when '('           then parens[parens.length - 1] += 1
        when '['           then brackets[brackets.length - 1] += 1
        when ')'
          if parens[parens.length - 1] is 0
            parens.pop()
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
  add_implicit_parentheses: ->
    stack: [0]
    @scan_tokens (prev, token, post, i) =>
      tag: token[0]
      stack.push(0) if tag is 'INDENT'
      if tag is 'OUTDENT'
        last: stack.pop()
        stack[stack.length - 1] += last
      if !post? or include IMPLICIT_END, tag
        return 1 if tag is 'INDENT' and prev and include IMPLICIT_BLOCK, prev[0]
        if stack[stack.length - 1] > 0 or tag is 'INDENT'
          idx: if tag is 'OUTDENT' then i + 1 else i
          stack_pointer: if tag is 'INDENT' then 2 else 1
          for tmp in [0...stack[stack.length - stack_pointer]]
            @tokens.splice(idx, 0, ['CALL_END', ')', token[2]])
          size: stack[stack.length - stack_pointer] + 1
          stack[stack.length - stack_pointer]: 0
          return size
      return 1 unless prev and include(IMPLICIT_FUNC, prev[0]) and include IMPLICIT_CALL, tag
      @tokens.splice(i, 0, ['CALL_START', '(', token[2]])
      stack[stack.length - 1] += 1
      return 2

  # Because our grammar is LALR(1), it can't handle some single-line
  # expressions that lack ending delimiters. The **Rewriter** adds the implicit
  # blocks, so it doesn't need to. ')' can close a single-line block,
  # but we need to make sure it's balanced.
  add_implicit_indentation: ->
    @scan_tokens (prev, token, post, i) =>
      return 1 unless include(SINGLE_LINERS, token[0]) and
        post[0] isnt 'INDENT' and
        not (token[0] is 'ELSE' and post[0] is 'IF')
      starter: token[0]
      @tokens.splice(i + 1, 0, ['INDENT', 2, token[2]])
      idx: i + 1
      parens: 0
      while true
        idx += 1
        tok: @tokens[idx]
        pre: @tokens[idx - 1]
        if (not tok or
            (include(SINGLE_CLOSERS, tok[0]) and tok[1] isnt ';') or
            (tok[0] is ')' && parens is 0)) and
            not (starter is 'ELSE' and tok[0] is 'ELSE')
          insertion: if pre[0] is "," then idx - 1 else idx
          @tokens.splice(insertion, 0, ['OUTDENT', 2, token[2]])
          break
        parens += 1 if tok[0] is '('
        parens -= 1 if tok[0] is ')'
      return 1 unless token[0] is 'THEN'
      @tokens.splice(i, 1)
      return 0

  # Ensure that all listed pairs of tokens are correctly balanced throughout
  # the course of the token stream.
  ensure_balance: (pairs) ->
    levels: {}
    @scan_tokens (prev, token, post, i) =>
      for pair in pairs
        [open, close]: pair
        levels[open] ||= 0
        levels[open] += 1 if token[0] is open
        levels[open] -= 1 if token[0] is close
        throw new Error("too many ${token[1]} on line ${token[2] + 1}") if levels[open] < 0
      return 1
    unclosed: key for key, value of levels when value > 0
    throw new Error("unclosed ${unclosed[0]}") if unclosed.length

  # We'd like to support syntax like this:
  #
  #     el.click((event) ->
  #       el.hide())
  #
  # In order to accomplish this, move outdents that follow closing parens
  # inwards, safely. The steps to accomplish this are:
  #
  # 1. Check that all paired tokens are balanced and in order.
  # 2. Rewrite the stream with a stack: if you see an '(' or INDENT, add it
  #    to the stack. If you see an ')' or OUTDENT, pop the stack and replace
  #    it with the inverse of what we've just popped.
  # 3. Keep track of "debt" for tokens that we fake, to make sure we end
  #    up balanced in the end.
  #
  rewrite_closing_parens: ->
    stack: []
    debt:  {}
    (debt[key]: 0) for key, val of INVERSES
    @scan_tokens (prev, token, post, i) =>
      tag: token[0]
      inv: INVERSES[token[0]]
      if include EXPRESSION_START, tag
        stack.push token
        return 1
      else if include EXPRESSION_END, tag
        if debt[inv] > 0
          debt[inv] -= 1
          @tokens.splice i, 1
          return 0
        else
          match: stack.pop()
          mtag:  match[0]
          return 1 if tag is INVERSES[mtag]
          debt[mtag] += 1
          val: if mtag is 'INDENT' then match[1] else INVERSES[mtag]
          @tokens.splice i, 0, [INVERSES[mtag], val]
          return 1
      else
        return 1

# Constants
# ---------

# List of the token pairs that must be balanced.
BALANCED_PAIRS: [['(', ')'], ['[', ']'], ['{', '}'], ['INDENT', 'OUTDENT'],
  ['PARAM_START', 'PARAM_END'], ['CALL_START', 'CALL_END'],
  ['INDEX_START', 'INDEX_END'], ['SOAKED_INDEX_START', 'SOAKED_INDEX_END']]

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
IMPLICIT_FUNC:  ['IDENTIFIER', 'SUPER', ')', 'CALL_END', ']', 'INDEX_END']

# If preceded by an `IMPLICIT_FUNC`, indicates a function invocation.
IMPLICIT_CALL:  ['IDENTIFIER', 'NUMBER', 'STRING', 'JS', 'REGEX', 'NEW', 'PARAM_START',
                 'TRY', 'DELETE', 'TYPEOF', 'SWITCH',
                 'TRUE', 'FALSE', 'YES', 'NO', 'ON', 'OFF', '!', '!!', 'NOT',
                 '@', '->', '=>', '[', '(', '{']

# Tokens indicating that the implicit call must enclose a block of expressions.
IMPLICIT_BLOCK: ['->', '=>', '{', '[', ',']

# Tokens that always mark the end of an implicit call for single-liners.
IMPLICIT_END:   ['IF', 'UNLESS', 'FOR', 'WHILE', 'TERMINATOR', 'INDENT', 'OUTDENT']

# Single-line flavors of block expressions that have unclosed endings.
# The grammar can't disambiguate them, so we insert the implicit indentation.
SINGLE_LINERS: ['ELSE', "->", "=>", 'TRY', 'FINALLY', 'THEN']
SINGLE_CLOSERS: ['TERMINATOR', 'CATCH', 'FINALLY', 'ELSE', 'OUTDENT', 'LEADING_WHEN']
