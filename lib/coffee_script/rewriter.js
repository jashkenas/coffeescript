(function(){
  var BALANCED_PAIRS, EXPRESSION_CLOSE, EXPRESSION_START, EXPRESSION_TAIL, IMPLICIT_CALL, IMPLICIT_END, IMPLICIT_FUNC, INVERSES, SINGLE_CLOSERS, SINGLE_LINERS, __a, __b, __c, __d, __e, __f, __g, __h, pair, re;
  // In order to keep the grammar simple, the stream of tokens that the Lexer
  // emits is rewritten by the Rewriter, smoothing out ambiguities, mis-nested
  // indentation, and single-line flavors of expressions.
  exports.Rewriter = (re = function re() {  });
  // Tokens that must be balanced.
  BALANCED_PAIRS = [['(', ')'], ['[', ']'], ['{', '}'], ['INDENT', 'OUTDENT'], ['PARAM_START', 'PARAM_END'], ['CALL_START', 'CALL_END'], ['INDEX_START', 'INDEX_END']];
  // Tokens that signal the start of a balanced pair.
  EXPRESSION_START = (function() {
    __a = []; __b = BALANCED_PAIRS;
    for (__c = 0; __c < __b.length; __c++) {
      pair = __b[__c];
      __a.push(pair[0]);
    }
    return __a;
  }).call(this);
  // Tokens that signal the end of a balanced pair.
  EXPRESSION_TAIL = (function() {
    __d = []; __e = BALANCED_PAIRS;
    for (__f = 0; __f < __e.length; __f++) {
      pair = __e[__f];
      __d.push(pair[1]);
    }
    return __d;
  }).call(this);
  // Tokens that indicate the close of a clause of an expression.
  EXPRESSION_CLOSE = ['CATCH', 'WHEN', 'ELSE', 'FINALLY'].concat(EXPRESSION_TAIL);
  // Tokens pairs that, in immediate succession, indicate an implicit call.
  IMPLICIT_FUNC = ['IDENTIFIER', 'SUPER', ')', 'CALL_END', ']', 'INDEX_END'];
  IMPLICIT_END = ['IF', 'UNLESS', 'FOR', 'WHILE', "\n", 'OUTDENT'];
  IMPLICIT_CALL = ['IDENTIFIER', 'NUMBER', 'STRING', 'JS', 'REGEX', 'NEW', 'PARAM_START', 'TRY', 'DELETE', 'TYPEOF', 'SWITCH', 'ARGUMENTS', 'TRUE', 'FALSE', 'YES', 'NO', 'ON', 'OFF', '!', '!!', 'NOT', '->', '=>', '[', '(', '{'];
  // The inverse mappings of token pairs we're trying to fix up.
  INVERSES = {
  };
  __g = BALANCED_PAIRS;
  for (__h = 0; __h < __g.length; __h++) {
    pair = __g[__h];
    INVERSES[pair[0]] = pair[1];
    INVERSES[pair[1]] = pair[0];
  }
  // Single-line flavors of block expressions that have unclosed endings.
  // The grammar can't disambiguate them, so we insert the implicit indentation.
  SINGLE_LINERS = ['ELSE', "->", "=>", 'TRY', 'FINALLY', 'THEN'];
  SINGLE_CLOSERS = ["\n", 'CATCH', 'FINALLY', 'ELSE', 'OUTDENT', 'LEADING_WHEN', 'PARAM_START'];
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
    this.add_implicit_parentheses();
    this.add_implicit_indentation();
    // this.ensure_balance(BALANCED_PAIRS)
    // this.rewrite_closing_parens()
    return this.tokens;
  };
  // Rewrite the token stream, looking one token ahead and behind.
  // Allow the return value of the block to tell us how many tokens to move
  // forwards (or backwards) in the stream, to make sure we don't miss anything
  // as the stream changes length under our feet.
  re.prototype.scan_tokens = function scan_tokens(yield) {
    var i, move;
    i = 0;
    while (true) {
      if (!(this.tokens[i])) {
        break;
      }
      move = yield(this.tokens[i - 1], this.tokens[i], this.tokens[i + 1], i);
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
        } else if (prev[0] === "\n" && after[0] === 'INDENT') {
          this.tokens.splice(i + 2, 1);
          this.tokens[i - 1] = after;
          return 1;
        } else if (prev[0] !== "\n" && prev[0] !== 'INDENT' && prev[0] !== 'OUTDENT') {
          this.tokens.splice(i, 0, ["\n", "\n"]);
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
    if (this.tokens[0][0] === "\n") {
      return this.tokens.shift();
    }
  };
  // Some blocks occur in the middle of expressions -- when we're expecting
  // this, remove their trailing newlines.
  re.prototype.remove_mid_expression_newlines = function remove_mid_expression_newlines() {
    return this.scan_tokens((function(__this) {
      var __func = function(prev, token, post, i) {
        if (!(post && EXPRESSION_CLOSE.indexOf(post[0]) >= 0 && token[0] === "\n")) {
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
        if (token[0] === 'CALL_START') {
          parens.push(0);
        } else if (token[0] === 'INDEX_START') {
          brackets.push(0);
        } else if (token[0] === '(') {
          parens[-1] += 1;
        } else if (token[0] === '[') {
          brackets[-1] += 1;
        } else if (token[0] === ')') {
          if (parens[parens.length - 1] === 0) {
            parens.pop;
            token[0] = 'CALL_END';
          } else {
            parens[parens.length - 1] -= 1;
          }
        } else if (token[0] === ']') {
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
        var __i, __j, __k, __l, idx, last, size, tmp;
        if (token[0] === 'INDENT') {
          stack.push(0);
        }
        if (token[0] === 'OUTDENT') {
          last = stack.pop();
          stack[stack.length - 1] += last;
        }
        if (stack[stack.length - 1] > 0 && (IMPLICIT_END.indexOf(token[0]) >= 0 || !(typeof post !== "undefined" && post !== null))) {
          idx = token[0] === 'OUTDENT' ? i + 1 : i;
          __k = 0; __l = stack[stack.length - 1];
          for (__j=0, tmp=__k; (__k <= __l ? tmp < __l : tmp > __l); (__k <= __l ? tmp += 1 : tmp -= 1), __j++) {
            this.tokens.splice(idx, 0, ['CALL_END', ')']);
          }
          size = stack[stack.length - 1] + 1;
          stack[stack.length - 1] = 0;
          return size;
        }
        if (!(prev && IMPLICIT_FUNC.indexOf(prev[0]) >= 0 && IMPLICIT_CALL.indexOf(token[0]) >= 0)) {
          return 1;
        }
        this.tokens.splice(i, 0, ['CALL_START', '(']);
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
        this.tokens.splice(i + 1, 0, ['INDENT', 2]);
        idx = i + 1;
        parens = 0;
        while (true) {
          idx += 1;
          tok = this.tokens[idx];
          if ((!tok || SINGLE_CLOSERS.indexOf(tok[0]) >= 0 || (tok[0] === ')' && parens === 0)) && !(starter === 'ELSE' && tok[0] === 'ELSE')) {
            insertion = this.tokens[idx - 1][0] === "," ? idx - 1 : idx;
            this.tokens.splice(insertion, 0, ['OUTDENT', 2]);
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
})();