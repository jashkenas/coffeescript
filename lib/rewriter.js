(function() {
  var BALANCED_PAIRS, EXPRESSION_CLOSE, EXPRESSION_END, EXPRESSION_START, IMPLICIT_BLOCK, IMPLICIT_CALL, IMPLICIT_END, IMPLICIT_FUNC, INVERSES, LINEBREAKS, Rewriter, SINGLE_CLOSERS, SINGLE_LINERS, _a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, helpers, include, pair;
  var __hasProp = Object.prototype.hasOwnProperty;
  if (typeof process !== "undefined" && process !== null) {
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
      this.tagPostfixConditionals();
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
        move = block.call(this, this.tokens[i], i);
        i += move;
      }
      return true;
    };
    Rewriter.prototype.detectEnd = function(i, condition, action) {
      var levels, token;
      levels = 0;
      while (true) {
        token = this.tokens[i];
        if (levels === 0 && condition.call(this, token, i)) {
          return action.call(this, token, i);
        }
        if (!token || levels < 0) {
          return action.call(this, token, i - 1);
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
      return this.scanTokens(function(token, i) {
        var _c, _d, after, before, post, prev;
        if (token[0] !== 'HERECOMMENT') {
          return 1;
        }
        _c = [this.tokens[i - 2], this.tokens[i - 1], this.tokens[i + 1], this.tokens[i + 2]];
        before = _c[0];
        prev = _c[1];
        post = _c[2];
        after = _c[3];
        if (after && after[0] === 'INDENT') {
          this.tokens.splice(i + 2, 1);
          if (before && before[0] === 'OUTDENT' && post && (prev[0] === post[0]) && (post[0] === 'TERMINATOR')) {
            this.tokens.splice(i - 2, 1);
          } else {
            this.tokens.splice(i, 0, after);
          }
        } else if (prev && !('TERMINATOR' === (_d = prev[0]) || 'INDENT' === _d || 'OUTDENT' === _d)) {
          if (post && post[0] === 'TERMINATOR' && after && after[0] === 'OUTDENT') {
            this.tokens.splice.apply(this.tokens, [i + 2, 0].concat(this.tokens.splice(i, 2)));
            if (this.tokens[i + 2][0] !== 'TERMINATOR') {
              this.tokens.splice(i + 2, 0, ['TERMINATOR', "\n", prev[2]]);
            }
          } else {
            this.tokens.splice(i, 0, ['TERMINATOR', "\n", prev[2]]);
          }
          return 2;
        }
        return 1;
      });
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
      return this.scanTokens(function(token, i) {
        if (!(include(EXPRESSION_CLOSE, this.tag(i + 1)) && token[0] === 'TERMINATOR')) {
          return 1;
        }
        this.tokens.splice(i, 1);
        return 0;
      });
    };
    Rewriter.prototype.closeOpenCalls = function() {
      return this.scanTokens(function(token, i) {
        var action, condition;
        if (token[0] === 'CALL_START') {
          condition = function(token, i) {
            var _c;
            return ((')' === (_c = token[0]) || 'CALL_END' === _c)) || (token[0] === 'OUTDENT' && this.tokens[i - 1][0] === ')');
          };
          action = function(token, i) {
            var idx;
            idx = token[0] === 'OUTDENT' ? i - 1 : i;
            return (this.tokens[idx][0] = 'CALL_END');
          };
          this.detectEnd(i + 1, condition, action);
        }
        return 1;
      });
    };
    Rewriter.prototype.closeOpenIndexes = function() {
      return this.scanTokens(function(token, i) {
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
      });
    };
    Rewriter.prototype.addImplicitBraces = function() {
      var stack;
      stack = [];
      return this.scanTokens(function(token, i) {
        var action, condition, idx, last, tok;
        if (include(EXPRESSION_START, token[0])) {
          stack.push((token[0] === 'INDENT' && (this.tag(i - 1) === '{')) ? '{' : token[0]);
        }
        if (include(EXPRESSION_END, token[0])) {
          stack.pop();
        }
        last = stack[stack.length - 1];
        if (token[0] === ':' && (!last || last[0] !== '{')) {
          stack.push('{');
          idx = this.tag(i - 2) === '@' ? i - 2 : i - 1;
          tok = ['{', '{', token[2]];
          tok.generated = true;
          this.tokens.splice(idx, 0, tok);
          condition = function(token, i) {
            var _c, _d, _e, one, three, two;
            _c = this.tokens.slice(i + 1, i + 4);
            one = _c[0];
            two = _c[1];
            three = _c[2];
            if ((this.tag(i + 1) === 'HERECOMMENT' || this.tag(i - 1) === 'HERECOMMENT')) {
              return false;
            }
            return ((('TERMINATOR' === (_d = token[0]) || 'OUTDENT' === _d)) && !((two && two[0] === ':') || (one && one[0] === '@' && three && three[0] === ':'))) || (token[0] === ',' && one && (!('IDENTIFIER' === (_e = one[0]) || 'STRING' === _e || '@' === _e || 'TERMINATOR' === _e || 'OUTDENT' === _e)));
          };
          action = function(token, i) {
            return this.tokens.splice(i, 0, ['}', '}', token[2]]);
          };
          this.detectEnd(i + 2, condition, action);
          return 2;
        }
        return 1;
      });
    };
    Rewriter.prototype.addImplicitParentheses = function() {
      var classLine;
      classLine = false;
      return this.scanTokens(function(token, i) {
        var _c, action, callObject, condition, idx, next, prev, seenSingle;
        if (token[0] === 'CLASS') {
          classLine = true;
        }
        prev = this.tokens[i - 1];
        next = this.tokens[i + 1];
        idx = 1;
        callObject = !classLine && token[0] === 'INDENT' && next && next.generated && next[0] === '{' && prev && include(IMPLICIT_FUNC, prev[0]);
        if (callObject) {
          idx = 2;
        }
        seenSingle = false;
        if (include(LINEBREAKS, token[0])) {
          classLine = false;
        }
        if (prev && !prev.spaced && token[0] === '?') {
          token.call = true;
        }
        if (prev && (prev.spaced && (include(IMPLICIT_FUNC, prev[0]) || prev.call) && include(IMPLICIT_CALL, token[0]) && !(token[0] === 'UNARY' && (('IN' === (_c = this.tag(i + 1)) || 'OF' === _c || 'INSTANCEOF' === _c)))) || callObject) {
          this.tokens.splice(i, 0, ['CALL_START', '(', token[2]]);
          condition = function(token, i) {
            var _c;
            if (!seenSingle && token.fromThen) {
              return true;
            }
            if (('IF' === (_c = token[0]) || 'ELSE' === _c || 'UNLESS' === _c || '->' === _c || '=>' === _c)) {
              seenSingle = true;
            }
            return (!token.generated && this.tokens[i - 1][0] !== ',' && include(IMPLICIT_END, token[0]) && !(token[0] === 'INDENT' && (include(IMPLICIT_BLOCK, this.tag(i - 1)) || this.tag(i - 2) === 'CLASS' || this.tag(i + 1) === '{'))) || token[0] === 'PROPERTY_ACCESS' && this.tag(i - 1) === 'OUTDENT';
          };
          action = function(token, i) {
            idx = token[0] === 'OUTDENT' ? i + 1 : i;
            return this.tokens.splice(idx, 0, ['CALL_END', ')', token[2]]);
          };
          this.detectEnd(i + idx, condition, action);
          if (prev[0] === '?') {
            prev[0] = 'FUNC_EXIST';
          }
          return 2;
        }
        return 1;
      });
    };
    Rewriter.prototype.addImplicitIndentation = function() {
      return this.scanTokens(function(token, i) {
        var _c, action, condition, indent, outdent, starter;
        if (token[0] === 'ELSE' && this.tag(i - 1) !== 'OUTDENT') {
          this.tokens.splice.apply(this.tokens, [i, 0].concat(this.indentation(token)));
          return 2;
        }
        if (token[0] === 'CATCH' && (this.tag(i + 2) === 'TERMINATOR' || this.tag(i + 2) === 'FINALLY')) {
          this.tokens.splice.apply(this.tokens, [i + 2, 0].concat(this.indentation(token)));
          return 4;
        }
        if (include(SINGLE_LINERS, token[0]) && this.tag(i + 1) !== 'INDENT' && !(token[0] === 'ELSE' && this.tag(i + 1) === 'IF')) {
          starter = token[0];
          _c = this.indentation(token);
          indent = _c[0];
          outdent = _c[1];
          if (starter === 'THEN') {
            indent.fromThen = true;
          }
          indent.generated = (outdent.generated = true);
          this.tokens.splice(i + 1, 0, indent);
          condition = function(token, i) {
            return (include(SINGLE_CLOSERS, token[0]) && token[1] !== ';') && !(token[0] === 'ELSE' && !('IF' === starter || 'THEN' === starter));
          };
          action = function(token, i) {
            var idx;
            idx = this.tokens[i - 1][0] === ',' ? i - 1 : i;
            return this.tokens.splice(idx, 0, outdent);
          };
          this.detectEnd(i + 2, condition, action);
          if (token[0] === 'THEN') {
            this.tokens.splice(i, 1);
          }
          return 2;
        }
        return 1;
      });
    };
    Rewriter.prototype.tagPostfixConditionals = function() {
      return this.scanTokens(function(token, i) {
        var _c, action, condition, original;
        if (('IF' === (_c = token[0]) || 'UNLESS' === _c)) {
          original = token;
          condition = function(token, i) {
            var _c;
            return ('TERMINATOR' === (_c = token[0]) || 'INDENT' === _c);
          };
          action = function(token, i) {
            if (token[0] !== 'INDENT') {
              return (original[0] = 'POST_' + original[0]);
            }
          };
          this.detectEnd(i + 1, condition, action);
          return 1;
        }
        return 1;
      });
    };
    Rewriter.prototype.ensureBalance = function(pairs) {
      var _c, _d, key, levels, line, open, openLine, unclosed, value;
      levels = {};
      openLine = {};
      this.scanTokens(function(token, i) {
        var _c, _d, _e, _f, close, open, pair;
        _d = pairs;
        for (_c = 0, _e = _d.length; _c < _e; _c++) {
          pair = _d[_c];
          _f = pair;
          open = _f[0];
          close = _f[1];
          levels[open] || (levels[open] = 0);
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
            throw new Error("too many " + (token[1]) + " on line " + (token[2] + 1));
          }
        }
        return 1;
      });
      unclosed = (function() {
        _c = []; _d = levels;
        for (key in _d) {
          if (!__hasProp.call(_d, key)) continue;
          value = _d[key];
          if (value > 0) {
            _c.push(key);
          }
        }
        return _c;
      })();
      if (unclosed.length) {
        open = unclosed[0];
        line = openLine[open] + 1;
        throw new Error("unclosed " + (open) + " on line " + (line));
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
      return this.scanTokens(function(token, i) {
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
            if ((this.tokens[i + 2] == null ? undefined : this.tokens[i + 2][0]) === mtag) {
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
      });
    };
    Rewriter.prototype.indentation = function(token) {
      return [['INDENT', 2, token[2]], ['OUTDENT', 2, token[2]]];
    };
    Rewriter.prototype.tag = function(i) {
      return this.tokens[i] && this.tokens[i][0];
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
  IMPLICIT_FUNC = ['IDENTIFIER', 'SUPER', ')', 'CALL_END', ']', 'INDEX_END', '@', 'THIS'];
  IMPLICIT_CALL = ['IDENTIFIER', 'NUMBER', 'STRING', 'JS', 'REGEX', 'NEW', 'PARAM_START', 'CLASS', 'IF', 'UNLESS', 'TRY', 'SWITCH', 'THIS', 'NULL', 'UNARY', 'TRUE', 'FALSE', 'YES', 'NO', 'ON', 'OFF', '@', '->', '=>', '[', '(', '{'];
  IMPLICIT_BLOCK = ['->', '=>', '{', '[', ','];
  IMPLICIT_END = ['POST_IF', 'POST_UNLESS', 'FOR', 'WHILE', 'UNTIL', 'LOOP', 'TERMINATOR', 'INDENT'];
  SINGLE_LINERS = ['ELSE', "->", "=>", 'TRY', 'FINALLY', 'THEN'];
  SINGLE_CLOSERS = ['TERMINATOR', 'CATCH', 'FINALLY', 'ELSE', 'OUTDENT', 'LEADING_WHEN'];
  LINEBREAKS = ['TERMINATOR', 'INDENT', 'OUTDENT'];
})();
