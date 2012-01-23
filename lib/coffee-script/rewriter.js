(function() {
  var BALANCED_PAIRS, EXPRESSION_CLOSE, EXPRESSION_END, EXPRESSION_START, IMPLICIT_BLOCK, IMPLICIT_CALL, IMPLICIT_END, IMPLICIT_FUNC, IMPLICIT_UNSPACED_CALL, INVERSES, LINEBREAKS, SINGLE_CLOSERS, SINGLE_LINERS, left, rite, _i, _len, _ref,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __slice = Array.prototype.slice;

  exports.Rewriter = (function() {

    Rewriter.name = 'Rewriter';

    function Rewriter() {}

    Rewriter.prototype.rewrite = function(tokens) {
      this.tokens = tokens;
      this.removeLeadingNewlines();
      this.removeMidExpressionNewlines();
      this.closeOpenCalls();
      this.closeOpenIndexes();
      this.addImplicitIndentation();
      this.tagPostfixConditionals();
      this.addImplicitBracesAndParentheses();
      return this.tokens;
    };

    Rewriter.prototype.scanTokens = function(block) {
      var i, token, tokens;
      tokens = this.tokens;
      i = 0;
      while (token = tokens[i]) {
        i += block.call(this, token, i, tokens);
      }
      return true;
    };

    Rewriter.prototype.detectEnd = function(start, condition, action, state, recursiveAction, startLevels) {
      var i, levels, skip, token, _ref, _ref2;
      if (state == null) state = {};
      if (recursiveAction == null) recursiveAction = null;
      if (startLevels == null) startLevels = 0;
      levels = startLevels;
      i = start;
      try {
        while (token = this.tokens[i]) {
          if (recursiveAction) {
            skip = recursiveAction.call(this, token, i);
            if (skip != null) {
              i += skip;
              continue;
            }
          }
          if (_ref = token[0], __indexOf.call(EXPRESSION_END, _ref) >= 0) {
            levels -= 1;
            if (levels < 0) throw 'STOP';
            i += 1;
          } else {
            if (levels === 0) {
              i += condition.call(this, token, i, state);
            } else {
              i += 1;
            }
            if (_ref2 = token[0], __indexOf.call(EXPRESSION_START, _ref2) >= 0) {
              levels += 1;
            }
          }
        }
      } catch (stop) {
        if (stop !== 'STOP') throw stop;
        if (action != null) i += action.call(this, token, i);
        return i - start;
      }
      throw new Error("End not found in detectEnd");
    };

    Rewriter.prototype.removeLeadingNewlines = function() {
      var i, tag, _i, _len, _ref;
      _ref = this.tokens;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        tag = _ref[i][0];
        if (tag !== 'TERMINATOR') break;
      }
      if (i) return this.tokens.splice(0, i);
    };

    Rewriter.prototype.removeMidExpressionNewlines = function() {
      return this.scanTokens(function(token, i, tokens) {
        var _ref;
        if (!(token[0] === 'TERMINATOR' && (_ref = this.tag(i + 1), __indexOf.call(EXPRESSION_CLOSE, _ref) >= 0))) {
          return 1;
        }
        tokens.splice(i, 1);
        return 0;
      });
    };

    Rewriter.prototype.closeOpenCalls = function() {
      var action, condition;
      condition = function(token, i) {
        var _ref;
        if (((_ref = token[0]) === ')' || _ref === 'CALL_END') || token[0] === 'OUTDENT' && this.tag(i - 1) === ')') {
          throw 'STOP';
        }
        return 1;
      };
      action = function(token, i) {
        return this.tokens[token[0] === 'OUTDENT' ? i - 1 : i][0] = 'CALL_END';
      };
      return this.scanTokens(function(token, i) {
        if (token[0] === 'CALL_START') this.detectEnd(i + 1, condition, action);
        return 1;
      });
    };

    Rewriter.prototype.closeOpenIndexes = function() {
      var action, condition;
      condition = function(token, i) {
        var _ref;
        if ((_ref = token[0]) === ']' || _ref === 'INDEX_END') throw 'STOP';
        return 1;
      };
      action = function(token, i) {
        return token[0] = 'INDEX_END';
      };
      return this.scanTokens(function(token, i) {
        if (token[0] === 'INDEX_START') this.detectEnd(i + 1, condition, action);
        return 1;
      });
    };

    Rewriter.prototype.addImplicitBracesAndParentheses = function() {
      var addEndBrace, addEndParentheses, addStartAndEnd, detectEndBrace, detectEndParentheses, detectStartBrace, detectStartParentheses, lineBreakListeners, lineType, priorLineType, stack,
        _this = this;
      stack = [];
      priorLineType = null;
      lineType = null;
      lineBreakListeners = [];
      detectStartBrace = function(token, i) {
        var _ref, _ref2, _ref3;
        return token[0] === ':' && (!(((_ref = stack[stack.length - 1]) != null ? _ref[0] : void 0) === '{' || ((_ref2 = stack[stack.length - 1]) != null ? _ref2[0] : void 0) === 'INDENT' && ((_ref3 = stack[stack.length - 2]) != null ? _ref3[0] : void 0) === '{' && !stack[stack.length - 2].generated) || _this.tag(i - 2) === ':');
      };
      detectStartParentheses = function(token, i) {
        var callObject, current, next1, next2, noCall, prev, tag, _ref, _ref2, _ref3, _ref4;
        if (token.fromThen) return false;
        tag = token[0];
        noCall = (lineType === 'CLASS') || (priorLineType === 'CLASS') && tag === 'INDENT';
        _ref = _this.tokens.slice(i - 1, (i + 2) + 1 || 9e9), prev = _ref[0], current = _ref[1], next1 = _ref[2], next2 = _ref[3];
        while ((next1 != null ? next1[0] : void 0) === 'HERECOMMENT') {
          i += 2;
          _ref2 = _this.tokens.slice(i + 1, (i + 2) + 1 || 9e9), next1 = _ref2[0], next2 = _ref2[1];
        }
        callObject = prev && (_ref3 = prev[0], __indexOf.call(IMPLICIT_FUNC, _ref3) >= 0) && !noCall && tag === 'INDENT' && next1 && next2 && next2[0] === ':';
        if (prev && !prev.spaced && tag === '?') token.call = true;
        return callObject || (prev != null ? prev.spaced : void 0) && (prev.call || (_ref4 = prev[0], __indexOf.call(IMPLICIT_FUNC, _ref4) >= 0)) && (__indexOf.call(IMPLICIT_CALL, tag) >= 0 || !(token.spaced || token.newLine) && __indexOf.call(IMPLICIT_UNSPACED_CALL, tag) >= 0);
      };
      addStartAndEnd = function(token, i) {
        var cb, idx, prevTag, scanState, tag, tok, value, _i, _len, _ref, _ref2, _ref3;
        if (_ref = (tag = token[0]), __indexOf.call(LINEBREAKS, _ref) >= 0) {
          for (_i = 0, _len = lineBreakListeners.length; _i < _len; _i++) {
            cb = lineBreakListeners[_i];
            cb();
          }
          lineBreakListeners = [];
          priorLineType = lineType;
          lineType = null;
        }
        if (__indexOf.call(EXPRESSION_START, tag) >= 0) {
          if (stack[stack.length - 1] !== token) stack.push(token);
        } else if (__indexOf.call(EXPRESSION_END, tag) >= 0) {
          if (((_ref2 = stack[stack.length - 1]) != null ? _ref2.generated : void 0) === token.generated && INVERSES[tag] === ((_ref3 = stack[stack.length - 1]) != null ? _ref3[0] : void 0)) {
            stack.pop();
          }
        }
        if (tag === 'CLASS') {
          priorLineType = lineType;
          lineType = tag;
        }
        if (detectStartBrace(token, i)) {
          idx = _this.tag(i - 2) === '@' ? i - 2 : i - 1;
          while (_this.tag(idx - 2) === 'HERECOMMENT') {
            idx -= 2;
          }
          prevTag = _this.tag(idx - 1);
          scanState = {
            sameLine: true,
            startsLine: !prevTag || (__indexOf.call(LINEBREAKS, prevTag) >= 0)
          };
          lineBreakListeners.push(function() {
            return scanState.sameLine = false;
          });
          value = new String('{');
          value.generated = true;
          tok = _this.generate('{', value, token[2]);
          if (stack[stack.length - 1] === token) {
            stack.splice(stack.length - 1, 0, tok);
          } else {
            stack.push(tok);
          }
          _this.tokens.splice(idx, 0, tok);
          return 2 + _this.detectEnd(i + 2, detectEndBrace, addEndBrace, scanState, addStartAndEnd);
        }
        if (detectStartParentheses(token, i)) {
          tok = _this.generate('CALL_START', '(', token[2]);
          if (stack[stack.length - 1] === token) {
            stack.splice(stack.length - 1, 0, tok);
          } else {
            stack.push(tok);
          }
          if (_this.tag(i - 1) === '?') _this.tokens[i - 1][0] = 'FUNC_EXIST';
          _this.tokens.splice(i, 0, tok);
          if (token[0] === 'INDENT') {
            return 2 + _this.detectEnd(i + 2, detectEndParentheses, addEndParentheses, null, addStartAndEnd, 1);
          } else {
            return 1 + _this.detectEnd(i + 1, detectEndParentheses, addEndParentheses, null, addStartAndEnd, 0);
          }
        }
        return null;
      };
      detectEndBrace = function(token, i, _arg) {
        var line, naiveEnd, one, otherEnd, sameLine, special1, special2, startsLine, tag, three, two, value, _ref, _ref2;
        sameLine = _arg.sameLine, startsLine = _arg.startsLine;
        tag = token[0], value = token[1], line = token[2];
        _ref = this.tokens.slice(i + 1, (i + 3) + 1 || 9e9), one = _ref[0], two = _ref[1], three = _ref[2];
        if ('HERECOMMENT' === (one != null ? one[0] : void 0)) return 1;
        naiveEnd = (tag === 'TERMINATOR') || (__indexOf.call(IMPLICIT_END, tag) >= 0 && sameLine);
        special1 = !startsLine && this.tag(i - 1) !== ',';
        special2 = !((two != null ? two[0] : void 0) === ':' || (one != null ? one[0] : void 0) === '@' && (three != null ? three[0] : void 0) === ':');
        otherEnd = tag === ',' && one && ((_ref2 = one[0]) !== 'IDENTIFIER' && _ref2 !== 'NUMBER' && _ref2 !== 'STRING' && _ref2 !== '@' && _ref2 !== 'TERMINATOR' && _ref2 !== 'OUTDENT');
        if (naiveEnd && (special1 || special2) || otherEnd) throw 'STOP';
        return 1;
      };
      addEndBrace = function(token, i) {
        var tok;
        stack.pop();
        tok = this.generate('}', '}', token[2]);
        this.tokens.splice(i, 0, tok);
        return 1;
      };
      detectEndParentheses = function(token, i, $) {
        var cond1, cond2, cond3a, cond3b, line, post, tag, value, _ref, _ref2;
        tag = token[0], value = token[1], line = token[2];
        if (!$.seenSingle && token.fromThen) throw 'STOP';
        if (tag === 'IF' || tag === 'ELSE' || tag === 'CATCH' || tag === '->' || tag === '=>' || tag === 'CLASS') {
          $.seenSingle = true;
        }
        if (tag === 'IF' || tag === 'ELSE' || tag === 'SWITCH' || tag === 'TRY' || tag === '=') {
          $.seenControl = true;
        }
        if ((tag === '.' || tag === '?.' || tag === '::') && this.tag(i - 1) === 'OUTDENT') {
          throw 'STOP';
        }
        cond1 = !token.generated && this.tag(i - 1) !== ',';
        cond2 = __indexOf.call(IMPLICIT_END, tag) >= 0 || (tag === 'INDENT' && !$.seenControl);
        cond3a = tag !== 'INDENT';
        cond3b = ((_ref = this.tag(i - 2)) !== 'CLASS' && _ref !== 'EXTENDS') && (_ref2 = this.tag(i - 1), __indexOf.call(IMPLICIT_BLOCK, _ref2) < 0) && !((post = this.tokens[i + 1]) && post.generated && post[0] === '{');
        if (cond1 && cond2 && (cond3a || cond3b)) throw 'STOP';
        return 1;
      };
      addEndParentheses = function(token, i) {
        var popped, tok;
        if (stack[stack.length - 1][0] === 'INDENT') stack.pop();
        popped = stack.pop();
        require('assert').equal(popped[0], 'CALL_START', "Illegal stack, expected CALL_START on top but found " + popped[0]);
        tok = this.generate('CALL_END', ')', token[2]);
        this.tokens.splice(i, 0, tok);
        return 1;
      };
      return this.scanTokens(function(token, i) {
        var offset;
        offset = addStartAndEnd(token, i);
        if (offset != null) return offset;
        return 1;
      });
    };

    Rewriter.prototype.addImplicitIndentation = function() {
      var action, condition, indent, outdent, starter;
      starter = indent = outdent = null;
      condition = function(token, i) {
        var _ref;
        if (token[1] !== ';' && (_ref = token[0], __indexOf.call(SINGLE_CLOSERS, _ref) >= 0) && !(token[0] === 'ELSE' && (starter !== 'IF' && starter !== 'THEN'))) {
          throw 'STOP';
        }
        return 1;
      };
      action = function(token, i) {
        return this.tokens.splice((this.tag(i - 1) === ',' ? i - 1 : i), 0, outdent);
      };
      return this.scanTokens(function(token, i, tokens) {
        var tag, _ref, _ref2;
        tag = token[0];
        if (tag === 'TERMINATOR' && this.tag(i + 1) === 'THEN') {
          tokens.splice(i, 1);
          return 0;
        }
        if (tag === 'ELSE' && this.tag(i - 1) !== 'OUTDENT') {
          tokens.splice.apply(tokens, [i, 0].concat(__slice.call(this.indentation(token))));
          return 2;
        }
        if (tag === 'CATCH' && ((_ref = this.tag(i + 2)) === 'OUTDENT' || _ref === 'TERMINATOR' || _ref === 'FINALLY')) {
          tokens.splice.apply(tokens, [i + 2, 0].concat(__slice.call(this.indentation(token))));
          return 4;
        }
        if (__indexOf.call(SINGLE_LINERS, tag) >= 0 && this.tag(i + 1) !== 'INDENT' && !(tag === 'ELSE' && this.tag(i + 1) === 'IF')) {
          starter = tag;
          _ref2 = this.indentation(token, true), indent = _ref2[0], outdent = _ref2[1];
          if (tag === 'THEN') indent.fromThen = true;
          tokens.splice(i + 1, 0, indent);
          this.detectEnd(i + 2, condition, action);
          if (tag === 'THEN') tokens.splice(i, 1);
          return 1;
        }
        return 1;
      });
    };

    Rewriter.prototype.tagPostfixConditionals = function() {
      var action, condition, original;
      original = null;
      condition = function(token, i) {
        var _ref;
        if ((_ref = token[0]) === 'TERMINATOR' || _ref === 'INDENT') throw 'STOP';
        return 1;
      };
      action = function(token, i) {
        if (token[0] !== 'INDENT' || (token.generated && !token.fromThen)) {
          return original[0] = 'POST_' + original[0];
        }
      };
      return this.scanTokens(function(token, i) {
        if (token[0] !== 'IF') return 1;
        original = token;
        this.detectEnd(i + 1, condition, action);
        return 1;
      });
    };

    Rewriter.prototype.indentation = function(token, implicit) {
      var indent, outdent;
      if (implicit == null) implicit = false;
      indent = ['INDENT', 2, token[2]];
      outdent = ['OUTDENT', 2, token[2]];
      if (implicit) indent.generated = outdent.generated = true;
      return [indent, outdent];
    };

    Rewriter.prototype.generate = function(tag, value, line) {
      var tok;
      tok = [tag, value, line];
      tok.generated = true;
      return tok;
    };

    Rewriter.prototype.tag = function(i) {
      var _ref;
      return (_ref = this.tokens[i]) != null ? _ref[0] : void 0;
    };

    return Rewriter;

  })();

  BALANCED_PAIRS = [['(', ')'], ['[', ']'], ['{', '}'], ['INDENT', 'OUTDENT'], ['CALL_START', 'CALL_END'], ['PARAM_START', 'PARAM_END'], ['INDEX_START', 'INDEX_END']];

  exports.INVERSES = INVERSES = {};

  EXPRESSION_START = [];

  EXPRESSION_END = [];

  for (_i = 0, _len = BALANCED_PAIRS.length; _i < _len; _i++) {
    _ref = BALANCED_PAIRS[_i], left = _ref[0], rite = _ref[1];
    EXPRESSION_START.push(INVERSES[rite] = left);
    EXPRESSION_END.push(INVERSES[left] = rite);
  }

  EXPRESSION_CLOSE = ['CATCH', 'WHEN', 'ELSE', 'FINALLY'].concat(EXPRESSION_END);

  IMPLICIT_FUNC = ['IDENTIFIER', 'SUPER', ')', 'CALL_END', ']', 'INDEX_END', '@', 'THIS'];

  IMPLICIT_CALL = ['IDENTIFIER', 'NUMBER', 'STRING', 'JS', 'REGEX', 'NEW', 'PARAM_START', 'CLASS', 'IF', 'TRY', 'SWITCH', 'THIS', 'BOOL', 'UNARY', 'SUPER', '@', '->', '=>', '[', '(', '{', '--', '++'];

  IMPLICIT_UNSPACED_CALL = ['+', '-'];

  IMPLICIT_BLOCK = ['->', '=>', '{', '[', ','];

  IMPLICIT_END = ['POST_IF', 'FOR', 'WHILE', 'UNTIL', 'WHEN', 'BY', 'LOOP', 'TERMINATOR'];

  SINGLE_LINERS = ['ELSE', '->', '=>', 'TRY', 'FINALLY', 'THEN'];

  SINGLE_CLOSERS = ['TERMINATOR', 'CATCH', 'FINALLY', 'ELSE', 'OUTDENT', 'LEADING_WHEN'];

  LINEBREAKS = ['TERMINATOR', 'INDENT', 'OUTDENT'];

}).call(this);
