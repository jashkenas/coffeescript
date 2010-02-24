(function(){
  var BALANCED_PAIRS, EXPRESSION_CLOSE, EXPRESSION_START, EXPRESSION_TAIL, IMPLICIT_BLOCK, IMPLICIT_CALL, IMPLICIT_END, IMPLICIT_FUNC, INVERSES, SINGLE_CLOSERS, SINGLE_LINERS, _a, _b, _c, _d, _e, _f, _g, _h, pair, re;
  var __hasProp = Object.prototype.hasOwnProperty;
  if (!((typeof process !== "undefined" && process !== null))) {
    this.exports = this;
  }
  // In order to keep the grammar simple, the stream of tokens that the Lexer
  // emits is rewritten by the Rewriter, smoothing out ambiguities, mis-nested
  // indentation, and single-line flavors of expressions.
  exports.Rewriter = (re = function re() {  });
  // Tokens that must be balanced.
  BALANCED_PAIRS = [['(', ')'], ['[', ']'], ['{', '}'], ['INDENT', 'OUTDENT'], ['PARAM_START', 'PARAM_END'], ['CALL_START', 'CALL_END'], ['INDEX_START', 'INDEX_END'], ['SOAKED_INDEX_START', 'SOAKED_INDEX_END']];
  // Tokens that signal the start of a balanced pair.
  EXPRESSION_START = (function() {
    _a = []; _b = BALANCED_PAIRS;
    for (_c = 0; _c < _b.length; _c++) {
      pair = _b[_c];
      _a.push(pair[0]);
    }
    return _a;
  }).call(this);
  // Tokens that signal the end of a balanced pair.
  EXPRESSION_TAIL = (function() {
    _d = []; _e = BALANCED_PAIRS;
    for (_f = 0; _f < _e.length; _f++) {
      pair = _e[_f];
      _d.push(pair[1]);
    }
    return _d;
  }).call(this);
  // Tokens that indicate the close of a clause of an expression.
  EXPRESSION_CLOSE = ['CATCH', 'WHEN', 'ELSE', 'FINALLY'].concat(EXPRESSION_TAIL);
  // Tokens pairs that, in immediate succession, indicate an implicit call.
  IMPLICIT_FUNC = ['IDENTIFIER', 'SUPER', ')', 'CALL_END', ']', 'INDEX_END'];
  IMPLICIT_BLOCK = ['->', '=>', '{', '[', ','];
  IMPLICIT_END = ['IF', 'UNLESS', 'FOR', 'WHILE', 'TERMINATOR', 'INDENT', 'OUTDENT'];
  IMPLICIT_CALL = ['IDENTIFIER', 'NUMBER', 'STRING', 'JS', 'REGEX', 'NEW', 'PARAM_START', 'TRY', 'DELETE', 'TYPEOF', 'SWITCH', 'TRUE', 'FALSE', 'YES', 'NO', 'ON', 'OFF', '!', '!!', 'NOT', '@', '->', '=>', '[', '(', '{'];
  // The inverse mappings of token pairs we're trying to fix up.
  INVERSES = {};
  _g = BALANCED_PAIRS;
  for (_h = 0; _h < _g.length; _h++) {
    pair = _g[_h];
    INVERSES[pair[0]] = pair[1];
    INVERSES[pair[1]] = pair[0];
  }
  // Single-line flavors of block expressions that have unclosed endings.
  // The grammar can't disambiguate them, so we insert the implicit indentation.
  SINGLE_LINERS = ['ELSE', "->", "=>", 'TRY', 'FINALLY', 'THEN'];
  SINGLE_CLOSERS = ['TERMINATOR', 'CATCH', 'FINALLY', 'ELSE', 'OUTDENT', 'LEADING_WHEN', 'PARAM_START'];
  // Rewrite the token stream in multiple passes, one logical filter at
  // a time. This could certainly be changed into a single pass through the
  // stream, with a big ol' efficient switch, but it's much nicer like this.
  re.prototype.rewrite = function rewrite(tokens) {
    this.tokens = tokens;
    this.adjust_comments();
    this.remove_leading_newlines();
    this.remove_mid_expression_newlines();
    this.move_commas_outside_outdents();
    this.close_open_calls_and_indexes();
    this.add_implicit_indentation();
    this.add_implicit_parentheses();
    this.ensure_balance(BALANCED_PAIRS);
    this.rewrite_closing_parens();
    return this.tokens;
  };
  // Rewrite the token stream, looking one token ahead and behind.
  // Allow the return value of the block to tell us how many tokens to move
  // forwards (or backwards) in the stream, to make sure we don't miss anything
  // as the stream changes length under our feet.
  re.prototype.scan_tokens = function scan_tokens(block) {
    var i, move;
    i = 0;
    while (true) {
      if (!(this.tokens[i])) {
        break;
      }
      move = block(this.tokens[i - 1], this.tokens[i], this.tokens[i + 1], i);
      i += move;
    }
    return true;
  };
  // Massage newlines and indentations so that comments don't have to be
  // correctly indented, or appear on their own line.
  re.prototype.adjust_comments = function adjust_comments() {
    return this.scan_tokens((function(__this) {
      var __func = function(prev, token, post, i) {
        var after, before;
        if (!(token[0] === 'COMMENT')) {
          return 1;
        }
        before = this.tokens[i - 2];
        after = this.tokens[i + 2];
        if (before && after && ((before[0] === 'INDENT' && after[0] === 'OUTDENT') || (before[0] === 'OUTDENT' && after[0] === 'INDENT')) && before[1] === after[1]) {
          this.tokens.splice(i + 2, 1);
          this.tokens.splice(i - 2, 1);
          return 0;
        } else if (prev && prev[0] === 'TERMINATOR' && after && after[0] === 'INDENT') {
          this.tokens.splice(i + 2, 1);
          this.tokens[i - 1] = after;
          return 1;
        } else if (prev && prev[0] !== 'TERMINATOR' && prev[0] !== 'INDENT' && prev[0] !== 'OUTDENT') {
          this.tokens.splice(i, 0, ['TERMINATOR', "\n", prev[2]]);
          return 2;
        } else {
          return 1;
        }
      };
      return (function() {
        return __func.apply(__this, arguments);
      });
    })(this));
  };
  // Leading newlines would introduce an ambiguity in the grammar, so we
  // dispatch them here.
  re.prototype.remove_leading_newlines = function remove_leading_newlines() {
    if (this.tokens[0][0] === 'TERMINATOR') {
      return this.tokens.shift();
    }
  };
  // Some blocks occur in the middle of expressions -- when we're expecting
  // this, remove their trailing newlines.
  re.prototype.remove_mid_expression_newlines = function remove_mid_expression_newlines() {
    return this.scan_tokens((function(__this) {
      var __func = function(prev, token, post, i) {
        if (!(post && EXPRESSION_CLOSE.indexOf(post[0]) >= 0 && token[0] === 'TERMINATOR')) {
          return 1;
        }
        this.tokens.splice(i, 1);
        return 0;
      };
      return (function() {
        return __func.apply(__this, arguments);
      });
    })(this));
  };
  // Make sure that we don't accidentally break trailing commas, which need
  // to go on the outside of expression closers.
  re.prototype.move_commas_outside_outdents = function move_commas_outside_outdents() {
    return this.scan_tokens((function(__this) {
      var __func = function(prev, token, post, i) {
        if (token[0] === 'OUTDENT' && prev[0] === ',') {
          this.tokens.splice(i, 1, token);
        }
        return 1;
      };
      return (function() {
        return __func.apply(__this, arguments);
      });
    })(this));
  };
  // We've tagged the opening parenthesis of a method call, and the opening
  // bracket of an indexing operation. Match them with their close.
  re.prototype.close_open_calls_and_indexes = function close_open_calls_and_indexes() {
    var brackets, parens;
    parens = [0];
    brackets = [0];
    return this.scan_tokens((function(__this) {
      var __func = function(prev, token, post, i) {
        var _i;
        if ((_i = token[0]) === 'CALL_START') {
          parens.push(0);
        } else if (_i === 'INDEX_START') {
          brackets.push(0);
        } else if (_i === '(') {
          parens[parens.length - 1] += 1;
        } else if (_i === '[') {
          brackets[brackets.length - 1] += 1;
        } else if (_i === ')') {
          if (parens[parens.length - 1] === 0) {
            parens.pop();
            token[0] = 'CALL_END';
          } else {
            parens[parens.length - 1] -= 1;
          }
        } else if (_i === ']') {
          if (brackets[brackets.length - 1] === 0) {
            brackets.pop();
            token[0] = 'INDEX_END';
          } else {
            brackets[brackets.length - 1] -= 1;
          }
        }
        return 1;
      };
      return (function() {
        return __func.apply(__this, arguments);
      });
    })(this));
  };
  // Methods may be optionally called without parentheses, for simple cases.
  // Insert the implicit parentheses here, so that the parser doesn't have to
  // deal with them.
  re.prototype.add_implicit_parentheses = function add_implicit_parentheses() {
    var stack;
    stack = [0];
    return this.scan_tokens((function(__this) {
      var __func = function(prev, token, post, i) {
        var _i, _j, _k, _l, idx, last, size, stack_pointer, tag, tmp;
        tag = token[0];
        if (tag === 'INDENT') {
          stack.push(0);
        }
        if (tag === 'OUTDENT') {
          last = stack.pop();
          stack[stack.length - 1] += last;
        }
        if (IMPLICIT_END.indexOf(tag) >= 0 || !(typeof post !== "undefined" && post !== null)) {
          if (tag === 'INDENT' && prev && IMPLICIT_BLOCK.indexOf(prev[0]) >= 0) {
            return 1;
          }
          if (stack[stack.length - 1] > 0 || tag === 'INDENT') {
            idx = tag === 'OUTDENT' ? i + 1 : i;
            stack_pointer = tag === 'INDENT' ? 2 : 1;
            _k = 0; _l = stack[stack.length - stack_pointer];
            for (_j = 0, tmp=_k; (_k <= _l ? tmp < _l : tmp > _l); (_k <= _l ? tmp += 1 : tmp -= 1), _j++) {
              this.tokens.splice(idx, 0, ['CALL_END', ')', token[2]]);
            }
            size = stack[stack.length - stack_pointer] + 1;
            stack[stack.length - stack_pointer] = 0;
            return size;
          }
        }
        if (!(prev && IMPLICIT_FUNC.indexOf(prev[0]) >= 0 && IMPLICIT_CALL.indexOf(tag) >= 0)) {
          return 1;
        }
        this.tokens.splice(i, 0, ['CALL_START', '(', token[2]]);
        stack[stack.length - 1] += 1;
        return 2;
      };
      return (function() {
        return __func.apply(__this, arguments);
      });
    })(this));
  };
  // Because our grammar is LALR(1), it can't handle some single-line
  // expressions that lack ending delimiters. Use the lexer to add the implicit
  // blocks, so it doesn't need to.
  // ')' can close a single-line block, but we need to make sure it's balanced.
  re.prototype.add_implicit_indentation = function add_implicit_indentation() {
    return this.scan_tokens((function(__this) {
      var __func = function(prev, token, post, i) {
        var idx, insertion, parens, starter, tok;
        if (!(SINGLE_LINERS.indexOf(token[0]) >= 0 && post[0] !== 'INDENT' && !(token[0] === 'ELSE' && post[0] === 'IF'))) {
          return 1;
        }
        starter = token[0];
        this.tokens.splice(i + 1, 0, ['INDENT', 2, token[2]]);
        idx = i + 1;
        parens = 0;
        while (true) {
          idx += 1;
          tok = this.tokens[idx];
          if ((!tok || (SINGLE_CLOSERS.indexOf(tok[0]) >= 0 && tok[1] !== ';') || (tok[0] === ')' && parens === 0)) && !(starter === 'ELSE' && tok[0] === 'ELSE')) {
            insertion = this.tokens[idx - 1][0] === "," ? idx - 1 : idx;
            this.tokens.splice(insertion, 0, ['OUTDENT', 2, token[2]]);
            break;
          }
          if (tok[0] === '(') {
            parens += 1;
          }
          if (tok[0] === ')') {
            parens -= 1;
          }
        }
        if (!(token[0] === 'THEN')) {
          return 1;
        }
        this.tokens.splice(i, 1);
        return 0;
      };
      return (function() {
        return __func.apply(__this, arguments);
      });
    })(this));
  };
  // Ensure that all listed pairs of tokens are correctly balanced throughout
  // the course of the token stream.
  re.prototype.ensure_balance = function ensure_balance(pairs) {
    var _i, _j, key, levels, unclosed, value;
    levels = {};
    this.scan_tokens((function(__this) {
      var __func = function(prev, token, post, i) {
        var _i, _j, _k, close, open;
        _i = pairs;
        for (_j = 0; _j < _i.length; _j++) {
          pair = _i[_j];
          _k = pair;
          open = _k[0];
          close = _k[1];
          levels[open] = levels[open] || 0;
          if (token[0] === open) {
            levels[open] += 1;
          }
          if (token[0] === close) {
            levels[open] -= 1;
          }
          if (levels[open] < 0) {
            throw new Error("too many " + token[1]);
          }
        }
        return 1;
      };
      return (function() {
        return __func.apply(__this, arguments);
      });
    })(this));
    unclosed = (function() {
      _i = []; _j = levels;
      for (key in _j) { if (__hasProp.call(_j, key)) {
        value = _j[key];
        if (value > 0) {
          _i.push(key);
        }
      }}
      return _i;
    }).call(this);
    if (unclosed.length) {
      throw new Error("unclosed " + unclosed[0]);
    }
  };
  // We'd like to support syntax like this:
  //    el.click((event) ->
  //      el.hide())
  // In order to accomplish this, move outdents that follow closing parens
  // inwards, safely. The steps to accomplish this are:
  //
  // 1. Check that all paired tokens are balanced and in order.
  // 2. Rewrite the stream with a stack: if you see an '(' or INDENT, add it
  //    to the stack. If you see an ')' or OUTDENT, pop the stack and replace
  //    it with the inverse of what we've just popped.
  // 3. Keep track of "debt" for tokens that we fake, to make sure we end
  //    up balanced in the end.
  //
  re.prototype.rewrite_closing_parens = function rewrite_closing_parens() {
    var _i, debt, key, stack, val;
    stack = [];
    debt = {};
    _i = INVERSES;
    for (key in _i) { if (__hasProp.call(_i, key)) {
      val = _i[key];
      ((debt[key] = 0));
    }}
    return this.scan_tokens((function(__this) {
      var __func = function(prev, token, post, i) {
        var inv, match, mtag, tag;
        tag = token[0];
        inv = INVERSES[token[0]];
        // Push openers onto the stack.
        if (EXPRESSION_START.indexOf(tag) >= 0) {
          stack.push(token);
          return 1;
          // The end of an expression, check stack and debt for a pair.
        } else if (EXPRESSION_TAIL.indexOf(tag) >= 0) {
          // If the tag is already in our debt, swallow it.
          if (debt[inv] > 0) {
            debt[inv] -= 1;
            this.tokens.splice(i, 1);
            return 0;
          } else {
            // Pop the stack of open delimiters.
            match = stack.pop();
            mtag = match[0];
            // Continue onwards if it's the expected tag.
            if (tag === INVERSES[mtag]) {
              return 1;
            } else {
              // Unexpected close, insert correct close, adding to the debt.
              debt[mtag] += 1;
              val = mtag === 'INDENT' ? match[1] : INVERSES[mtag];
              this.tokens.splice(i, 0, [INVERSES[mtag], val]);
              return 1;
            }
          }
        } else {
          return 1;
        }
      };
      return (function() {
        return __func.apply(__this, arguments);
      });
    })(this));
  };
})();
