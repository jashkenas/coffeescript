(function() {
  var BALANCED_PAIRS, EXPRESSION_CLOSE, EXPRESSION_END, EXPRESSION_START, IMPLICIT_BLOCK, IMPLICIT_CALL, IMPLICIT_END, IMPLICIT_FUNC, INVERSES, Rewriter, SINGLE_CLOSERS, SINGLE_LINERS, _a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, helpers, include, pair;
  var __bind = function(func, context) {
    return function(){ return func.apply(context, arguments); };
  }, __hasProp = Object.prototype.hasOwnProperty;
  if ((typeof process !== "undefined" && process !== null)) {
    _a = require('./helpers');
    helpers = _a.helpers;
  } else {
    this.exports = this;
    helpers = this.helpers;
  }
  _b = helpers;
  include = _b.include;
  exports.Rewriter = (function() {
    Rewriter = function() {};
    Rewriter.prototype.rewrite = function(tokens) {
      this.tokens = tokens;
      this.adjustComments();
      this.removeLeadingNewlines();
      this.removeMidExpressionNewlines();
      this.closeOpenCalls();
      this.closeOpenIndexes();
      this.addImplicitIndentation();
      this.addImplicitBraces();
      this.addImplicitParentheses();
      this.ensureBalance(BALANCED_PAIRS);
      this.rewriteClosingParens();
      return this.tokens;
    };
    Rewriter.prototype.scanTokens = function(block) {
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
    Rewriter.prototype.detectEnd = function(i, condition, action) {
      var levels, token;
      levels = 0;
      while (true) {
        if (!(token = this.tokens[i])) {
          break;
        }
        if (levels === 0 && condition(token, i)) {
          return action(token, i);
        }
        if (levels < 0) {
          return action(token, i - 1);
        }
        if (include(EXPRESSION_START, token[0])) {
          levels += 1;
        }
        if (include(EXPRESSION_END, token[0])) {
          levels -= 1;
        }
        i += 1;
      }
      return i - 1;
    };
    Rewriter.prototype.adjustComments = function() {
      return this.scanTokens(__bind(function(prev, token, post, i) {
        var _c, _d, after, before;
        if (!(token[0] === 'HERECOMMENT')) {
          return 1;
        }
        _c = [this.tokens[i - 2], this.tokens[i + 2]];
        before = _c[0];
        after = _c[1];
        if (after && after[0] === 'INDENT') {
          this.tokens.splice(i + 2, 1);
          before && before[0] === 'OUTDENT' && post && (prev[0] === post[0]) && (post[0] === 'TERMINATOR') ? this.tokens.splice(i - 2, 1) : this.tokens.splice(i, 0, after);
        } else if (prev && !('TERMINATOR' === (_d = prev[0]) || 'INDENT' === _d || 'OUTDENT' === _d)) {
          if (post && post[0] === 'TERMINATOR' && after && after[0] === 'OUTDENT') {
            this.tokens.splice.apply(this.tokens, [i + 2, 0].concat(this.tokens.splice(i, 2)));
            this.tokens[i + 2][0] !== 'TERMINATOR' ? this.tokens.splice(i + 2, 0, ['TERMINATOR', "\n", prev[2]]) : null;
          } else {
            this.tokens.splice(i, 0, ['TERMINATOR', "\n", prev[2]]);
          }
          return 2;
        }
        return 1;
      }, this));
    };
    Rewriter.prototype.removeLeadingNewlines = function() {
      var _c;
      _c = [];
      while (this.tokens[0] && this.tokens[0][0] === 'TERMINATOR') {
        _c.push(this.tokens.shift());
      }
      return _c;
    };
    Rewriter.prototype.removeMidExpressionNewlines = function() {
      return this.scanTokens(__bind(function(prev, token, post, i) {
        if (!(post && include(EXPRESSION_CLOSE, post[0]) && token[0] === 'TERMINATOR')) {
          return 1;
        }
        this.tokens.splice(i, 1);
        return 0;
      }, this));
    };
    Rewriter.prototype.closeOpenCalls = function() {
      return this.scanTokens(__bind(function(prev, token, post, i) {
        var action, condition;
        if (token[0] === 'CALL_START') {
          condition = function(token, i) {
            var _c;
            return (')' === (_c = token[0]) || 'CALL_END' === _c);
          };
          action = function(token, i) {
            return (token[0] = 'CALL_END');
          };
          this.detectEnd(i + 1, condition, action);
        }
        return 1;
      }, this));
    };
    Rewriter.prototype.closeOpenIndexes = function() {
      return this.scanTokens(__bind(function(prev, token, post, i) {
        var action, condition;
        if (token[0] === 'INDEX_START') {
          condition = function(token, i) {
            var _c;
            return (']' === (_c = token[0]) || 'INDEX_END' === _c);
          };
          action = function(token, i) {
            return (token[0] = 'INDEX_END');
          };
          this.detectEnd(i + 1, condition, action);
        }
        return 1;
      }, this));
    };
    Rewriter.prototype.addImplicitBraces = function() {
      var stack;
      stack = [];
      return this.scanTokens(__bind(function(prev, token, post, i) {
        var action, before, condition, idx, last;
        include(EXPRESSION_START, token[0]) ? stack.push((token[0] === 'INDENT' && (prev && prev[0] === '{')) ? '{' : token[0]) : null;
        include(EXPRESSION_END, token[0]) ? stack.pop() : null;
        last = stack[stack.length - 1];
        before = this.tokens[i - 2];
        if (token[0] === ':' && (!last || last[0] !== '{')) {
          stack.push('{');
          idx = before[0] === '@' ? i - 2 : i - 1;
          this.tokens.splice(idx, 0, ['{', '{', token[2]]);
          condition = __bind(function(token, i) {
            var _c, _d, _e, one, three, two;
            _c = this.tokens.slice(i + 1, i + 4);
            one = _c[0];
            two = _c[1];
            three = _c[2];
            return ((('TERMINATOR' === (_d = token[0]) || 'OUTDENT' === _d)) && !((two && two[0] === ':') || (one && one[0] === '@' && three && three[0] === ':'))) || (token[0] === ',' && one && (!('IDENTIFIER' === (_e = one[0]) || 'STRING' === _e || '@' === _e || 'TERMINATOR' === _e || 'OUTDENT' === _e)));
          }, this);
          action = __bind(function(token, i) {
            return this.tokens.splice(i, 0, ['}', '}', token[2]]);
          }, this);
          this.detectEnd(i + 2, condition, action);
          return 2;
        }
        return 1;
      }, this));
    };
    Rewriter.prototype.addImplicitParentheses = function() {
      var closeCalls, stack;
      stack = [0];
      closeCalls = __bind(function(i) {
        var _c, size, tmp;
        _c = stack[stack.length - 1];
        for (tmp = 0; (0 <= _c ? tmp < _c : tmp > _c); (0 <= _c ? tmp += 1 : tmp -= 1)) {
          this.tokens.splice(i, 0, ['CALL_END', ')', this.tokens[i][2]]);
        }
        size = stack[stack.length - 1] + 1;
        stack[stack.length - 1] = 0;
        return size;
      }, this);
      return this.scanTokens(__bind(function(prev, token, post, i) {
        var _c, _d, before, j, nx, open, size, tag;
        tag = token[0];
        before = this.tokens[i - 2] && this.tokens[i - 2][0];
        if (tag === 'OUTDENT') {
          stack[stack.length - 2] += stack.pop();
        }
        open = stack[stack.length - 1] > 0;
        if (prev && prev.spaced && include(IMPLICIT_FUNC, prev[0]) && include(IMPLICIT_CALL, tag) && !(tag === '!' && (('IN' === (_c = post[0]) || 'OF' === _c)))) {
          this.tokens.splice(i, 0, ['CALL_START', '(', token[2]]);
          stack[stack.length - 1] += 1;
          if (include(EXPRESSION_START, tag)) {
            stack.push(0);
          }
          return 2;
        }
        if (include(EXPRESSION_START, tag)) {
          if (tag === 'INDENT' && !token.generated && open && !((prev && include(IMPLICIT_BLOCK, prev[0])) || before && before === 'CLASS')) {
            size = closeCalls(i);
            stack.push(0);
            return size;
          }
          stack.push(0);
          return 1;
        }
        if (open && !token.generated && prev[0] !== ',' && (!post || include(IMPLICIT_END, tag))) {
          j = 1;
          while ((typeof (_d = (nx = this.tokens[i + j])) !== "undefined" && _d !== null) && include(IMPLICIT_END, nx[0])) {
            j++;
          }
          if ((typeof nx !== "undefined" && nx !== null) && nx[0] === ',' && this.tokens[i + j - 1][0] === 'OUTDENT') {
            if (tag === 'TERMINATOR') {
              this.tokens.splice(i, 1);
            }
          } else {
            size = closeCalls(i);
            if (tag !== 'OUTDENT' && include(EXPRESSION_END, tag)) {
              stack.pop();
            }
            return size;
          }
        }
        if (tag !== 'OUTDENT' && include(EXPRESSION_END, tag)) {
          stack[stack.length - 2] += stack.pop();
          return 1;
        }
        return 1;
      }, this));
    };
    Rewriter.prototype.addImplicitIndentation = function() {
      return this.scanTokens(__bind(function(prev, token, post, i) {
        var _c, idx, indent, insertion, outdent, parens, pre, starter, tok;
        if (token[0] === 'ELSE' && prev[0] !== 'OUTDENT') {
          this.tokens.splice.apply(this.tokens, [i, 0].concat(this.indentation(token)));
          return 2;
        }
        if (token[0] === 'CATCH' && (this.tokens[i + 2][0] === 'TERMINATOR' || this.tokens[i + 2][0] === 'FINALLY')) {
          this.tokens.splice.apply(this.tokens, [i + 2, 0].concat(this.indentation(token)));
          return 4;
        }
        if (!(include(SINGLE_LINERS, token[0]) && post[0] !== 'INDENT' && !(token[0] === 'ELSE' && post[0] === 'IF'))) {
          return 1;
        }
        starter = token[0];
        _c = this.indentation(token);
        indent = _c[0];
        outdent = _c[1];
        indent.generated = (outdent.generated = true);
        this.tokens.splice(i + 1, 0, indent);
        idx = i + 1;
        parens = 0;
        while (true) {
          idx += 1;
          tok = this.tokens[idx];
          pre = this.tokens[idx - 1];
          if ((!tok || (include(SINGLE_CLOSERS, tok[0]) && tok[1] !== ';' && parens === 0) || (tok[0] === ')' && parens === 0)) && !(tok[0] === 'ELSE' && !('IF' === starter || 'THEN' === starter))) {
            insertion = pre[0] === "," ? idx - 1 : idx;
            this.tokens.splice(insertion, 0, outdent);
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
      }, this));
    };
    Rewriter.prototype.ensureBalance = function(pairs) {
      var _c, _d, key, levels, line, open, openLine, unclosed, value;
      levels = {};
      openLine = {};
      this.scanTokens(__bind(function(prev, token, post, i) {
        var _c, _d, _e, _f, close, open, pair;
        _d = pairs;
        for (_c = 0, _e = _d.length; _c < _e; _c++) {
          pair = _d[_c];
          _f = pair;
          open = _f[0];
          close = _f[1];
          levels[open] = levels[open] || 0;
          if (token[0] === open) {
            if (levels[open] === 0) {
              openLine[open] = token[2];
            }
            levels[open] += 1;
          }
          if (token[0] === close) {
            levels[open] -= 1;
          }
          if (levels[open] < 0) {
            throw new Error(("too many " + (token[1]) + " on line " + (token[2] + 1)));
          }
        }
        return 1;
      }, this));
      unclosed = (function() {
        _c = []; _d = levels;
        for (key in _d) {
          if (!__hasProp.call(_d, key)) continue;
          value = _d[key];
          value > 0 ? _c.push(key) : null;
        }
        return _c;
      })();
      if (unclosed.length) {
        open = unclosed[0];
        line = openLine[open] + 1;
        throw new Error(("unclosed " + (open) + " on line " + (line)));
      }
    };
    Rewriter.prototype.rewriteClosingParens = function() {
      var _c, debt, key, stack, val;
      stack = [];
      debt = {};
      _c = INVERSES;
      for (key in _c) {
        if (!__hasProp.call(_c, key)) continue;
        val = _c[key];
        (debt[key] = 0);
      }
      return this.scanTokens(__bind(function(prev, token, post, i) {
        var inv, match, mtag, oppos, tag;
        tag = token[0];
        inv = INVERSES[token[0]];
        if (include(EXPRESSION_START, tag)) {
          stack.push(token);
          return 1;
        } else if (include(EXPRESSION_END, tag)) {
          if (debt[inv] > 0) {
            debt[inv] -= 1;
            this.tokens.splice(i, 1);
            return 0;
          } else {
            match = stack.pop();
            mtag = match[0];
            oppos = INVERSES[mtag];
            if (tag === oppos) {
              return 1;
            }
            debt[mtag] += 1;
            val = [oppos, mtag === 'INDENT' ? match[1] : oppos];
            if ((this.tokens[i + 2] == undefined ? undefined : this.tokens[i + 2][0]) === mtag) {
              this.tokens.splice(i + 3, 0, val);
              stack.push(match);
            } else {
              this.tokens.splice(i, 0, val);
            }
            return 1;
          }
        } else {
          return 1;
        }
      }, this));
    };
    Rewriter.prototype.indentation = function(token) {
      return [['INDENT', 2, token[2]], ['OUTDENT', 2, token[2]]];
    };
    return Rewriter;
  })();
  BALANCED_PAIRS = [['(', ')'], ['[', ']'], ['{', '}'], ['INDENT', 'OUTDENT'], ['PARAM_START', 'PARAM_END'], ['CALL_START', 'CALL_END'], ['INDEX_START', 'INDEX_END']];
  INVERSES = {};
  _d = BALANCED_PAIRS;
  for (_c = 0, _e = _d.length; _c < _e; _c++) {
    pair = _d[_c];
    INVERSES[pair[0]] = pair[1];
    INVERSES[pair[1]] = pair[0];
  }
  EXPRESSION_START = (function() {
    _f = []; _h = BALANCED_PAIRS;
    for (_g = 0, _i = _h.length; _g < _i; _g++) {
      pair = _h[_g];
      _f.push(pair[0]);
    }
    return _f;
  })();
  EXPRESSION_END = (function() {
    _j = []; _l = BALANCED_PAIRS;
    for (_k = 0, _m = _l.length; _k < _m; _k++) {
      pair = _l[_k];
      _j.push(pair[1]);
    }
    return _j;
  })();
  EXPRESSION_CLOSE = ['CATCH', 'WHEN', 'ELSE', 'FINALLY'].concat(EXPRESSION_END);
  IMPLICIT_FUNC = ['IDENTIFIER', 'SUPER', ')', 'CALL_END', ']', 'INDEX_END', '@'];
  IMPLICIT_CALL = ['IDENTIFIER', 'NUMBER', 'STRING', 'JS', 'REGEX', 'NEW', 'PARAM_START', 'CLASS', 'TRY', 'DELETE', 'TYPEOF', 'SWITCH', 'THIS', 'NULL', 'TRUE', 'FALSE', 'YES', 'NO', 'ON', 'OFF', '!', '!!', '@', '->', '=>', '[', '(', '{'];
  IMPLICIT_BLOCK = ['->', '=>', '{', '[', ','];
  IMPLICIT_END = ['IF', 'UNLESS', 'FOR', 'WHILE', 'UNTIL', 'LOOP', 'TERMINATOR', 'INDENT'].concat(EXPRESSION_END);
  SINGLE_LINERS = ['ELSE', "->", "=>", 'TRY', 'FINALLY', 'THEN'];
  SINGLE_CLOSERS = ['TERMINATOR', 'CATCH', 'FINALLY', 'ELSE', 'OUTDENT', 'LEADING_WHEN'];
})();
