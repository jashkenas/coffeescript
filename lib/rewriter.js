(function() {
  var BALANCED_PAIRS, EXPRESSION_CLOSE, EXPRESSION_END, EXPRESSION_START, IMPLICIT_BLOCK, IMPLICIT_CALL, IMPLICIT_END, IMPLICIT_FUNC, INVERSES, LINEBREAKS, Rewriter, SINGLE_CLOSERS, SINGLE_LINERS, _i, _len, _ref, _result, include, pair;
  var __hasProp = Object.prototype.hasOwnProperty;
  _ref = require('./helpers');
  include = _ref.include;
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
        var _ref2, after, before, post, prev;
        if (token[0] !== 'HERECOMMENT') {
          return 1;
        }
        _ref2 = [this.tokens[i - 2], this.tokens[i - 1], this.tokens[i + 1], this.tokens[i + 2]];
        before = _ref2[0];
        prev = _ref2[1];
        post = _ref2[2];
        after = _ref2[3];
        if (after && after[0] === 'INDENT') {
          this.tokens.splice(i + 2, 1);
          if (before && before[0] === 'OUTDENT' && post && (prev[0] === post[0]) && (post[0] === 'TERMINATOR')) {
            this.tokens.splice(i - 2, 1);
          } else {
            this.tokens.splice(i, 0, after);
          }
        } else if (prev && !('TERMINATOR' === (_ref2 = prev[0]) || 'INDENT' === _ref2 || 'OUTDENT' === _ref2)) {
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
      var _result;
      _result = [];
      while (this.tokens[0] && this.tokens[0][0] === 'TERMINATOR') {
        _result.push(this.tokens.shift());
      }
      return _result;
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
            var _ref2;
            return ((')' === (_ref2 = token[0]) || 'CALL_END' === _ref2)) || (token[0] === 'OUTDENT' && this.tokens[i - 1][0] === ')');
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
            var _ref2;
            return (']' === (_ref2 = token[0]) || 'INDEX_END' === _ref2);
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
          if (this.tag(idx - 2) === 'HERECOMMENT') {
            idx -= 2;
          }
          tok = ['{', '{', token[2]];
          tok.generated = true;
          this.tokens.splice(idx, 0, tok);
          condition = function(token, i) {
            var _ref2, one, three, two;
            _ref2 = this.tokens.slice(i + 1, i + 4);
            one = _ref2[0];
            two = _ref2[1];
            three = _ref2[2];
            if ((this.tag(i + 1) === 'HERECOMMENT' || this.tag(i - 1) === 'HERECOMMENT')) {
              return false;
            }
            return ((('TERMINATOR' === (_ref2 = token[0]) || 'OUTDENT' === _ref2)) && !((two && two[0] === ':') || (one && one[0] === '@' && three && three[0] === ':'))) || (token[0] === ',' && one && (!('IDENTIFIER' === (_ref2 = one[0]) || 'STRING' === _ref2 || '@' === _ref2 || 'TERMINATOR' === _ref2 || 'OUTDENT' === _ref2)));
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
        var _ref2, action, callObject, condition, idx, next, prev, seenSingle;
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
        if (prev && (prev.spaced && (include(IMPLICIT_FUNC, prev[0]) || prev.call) && include(IMPLICIT_CALL, token[0]) && !(token[0] === 'UNARY' && (('IN' === (_ref2 = this.tag(i + 1)) || 'OF' === _ref2 || 'INSTANCEOF' === _ref2)))) || callObject) {
          this.tokens.splice(i, 0, ['CALL_START', '(', token[2]]);
          condition = function(token, i) {
            var _ref2, post;
            if (!seenSingle && token.fromThen) {
              return true;
            }
            if (('IF' === (_ref2 = token[0]) || 'ELSE' === _ref2 || 'UNLESS' === _ref2 || '->' === _ref2 || '=>' === _ref2)) {
              seenSingle = true;
            }
            post = this.tokens[i + 1];
            return (!token.generated && this.tokens[i - 1][0] !== ',' && include(IMPLICIT_END, token[0]) && !(token[0] === 'INDENT' && (include(IMPLICIT_BLOCK, this.tag(i - 1)) || this.tag(i - 2) === 'CLASS' || (post && post.generated && post[0] === '{')))) || token[0] === 'PROPERTY_ACCESS' && this.tag(i - 1) === 'OUTDENT';
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
        var _ref2, action, condition, indent, outdent, starter;
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
          _ref2 = this.indentation(token);
          indent = _ref2[0];
          outdent = _ref2[1];
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
        var _ref2, action, condition, original;
        if (('IF' === (_ref2 = token[0]) || 'UNLESS' === _ref2)) {
          original = token;
          condition = function(token, i) {
            var _ref2;
            return ('TERMINATOR' === (_ref2 = token[0]) || 'INDENT' === _ref2);
          };
          action = function(token, i) {
            return token[0] !== 'INDENT' ? (original[0] = 'POST_' + original[0]) : null;
          };
          this.detectEnd(i + 1, condition, action);
          return 1;
        }
        return 1;
      });
    };
    Rewriter.prototype.ensureBalance = function(pairs) {
      var _ref2, _result, key, levels, line, open, openLine, unclosed, value;
      levels = {};
      openLine = {};
      this.scanTokens(function(token, i) {
        var _i, _len, _ref2, _ref3, close, open, pair;
        _ref2 = pairs;
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          pair = _ref2[_i];
          _ref3 = pair;
          open = _ref3[0];
          close = _ref3[1];
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
        _result = []; _ref2 = levels;
        for (key in _ref2) {
          if (!__hasProp.call(_ref2, key)) continue;
          value = _ref2[key];
          if (value > 0) {
            _result.push(key);
          }
        }
        return _result;
      })();
      if (unclosed.length) {
        open = unclosed[0];
        line = openLine[open] + 1;
        throw new Error("unclosed " + (open) + " on line " + (line));
      }
    };
    Rewriter.prototype.rewriteClosingParens = function() {
      var _ref2, debt, key, stack, val;
      stack = [];
      debt = {};
      _ref2 = INVERSES;
      for (key in _ref2) {
        if (!__hasProp.call(_ref2, key)) continue;
        val = _ref2[key];
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
  _ref = BALANCED_PAIRS;
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    pair = _ref[_i];
    INVERSES[pair[0]] = pair[1];
    INVERSES[pair[1]] = pair[0];
  }
  EXPRESSION_START = (function() {
    _result = []; _ref = BALANCED_PAIRS;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      pair = _ref[_i];
      _result.push(pair[0]);
    }
    return _result;
  })();
  EXPRESSION_END = (function() {
    _result = []; _ref = BALANCED_PAIRS;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      pair = _ref[_i];
      _result.push(pair[1]);
    }
    return _result;
  })();
  EXPRESSION_CLOSE = ['CATCH', 'WHEN', 'ELSE', 'FINALLY'].concat(EXPRESSION_END);
  IMPLICIT_FUNC = ['IDENTIFIER', 'SUPER', ')', 'CALL_END', ']', 'INDEX_END', '@', 'THIS'];
  IMPLICIT_CALL = ['IDENTIFIER', 'NUMBER', 'STRING', 'JS', 'REGEX', 'NEW', 'PARAM_START', 'CLASS', 'IF', 'UNLESS', 'TRY', 'SWITCH', 'THIS', 'NULL', 'UNARY', 'TRUE', 'FALSE', 'YES', 'NO', 'ON', 'OFF', '@', '->', '=>', '[', '(', '{'];
  IMPLICIT_BLOCK = ['->', '=>', '{', '[', ','];
  IMPLICIT_END = ['POST_IF', 'POST_UNLESS', 'FOR', 'WHILE', 'UNTIL', 'LOOP', 'TERMINATOR', 'INDENT'];
  SINGLE_LINERS = ['ELSE', "->", "=>", 'TRY', 'FINALLY', 'THEN'];
  SINGLE_CLOSERS = ['TERMINATOR', 'CATCH', 'FINALLY', 'ELSE', 'OUTDENT', 'LEADING_WHEN'];
  LINEBREAKS = ['TERMINATOR', 'INDENT', 'OUTDENT'];
}).call(this);
