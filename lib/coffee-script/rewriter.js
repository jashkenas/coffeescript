(function() {
  var BALANCED_PAIRS, EXPRESSION_CLOSE, EXPRESSION_END, EXPRESSION_START, IMPLICIT_BLOCK, IMPLICIT_CALL, IMPLICIT_END, IMPLICIT_FUNC, IMPLICIT_UNSPACED_CALL, INVERSES, LINEBREAKS, SINGLE_CLOSERS, SINGLE_LINERS, debug, left, local, rite, _i, _len, _ref,
    __slice = Array.prototype.slice,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  local = function(fn) {
    return fn();
  };

  debug = function() {
    var stuff;
    stuff = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
  };

  exports.Rewriter = (function() {

    Rewriter.name = 'Rewriter';

    function Rewriter() {}

    Rewriter.prototype.rewrite = function(tokens) {
      var t;
      this.tokens = tokens;
      this.removeLeadingNewlines();
      this.removeMidExpressionNewlines();
      this.closeOpenCalls();
      this.closeOpenIndexes();
      this.addImplicitIndentation();
      this.tagPostfixConditionals();
      if (false) {
        this.addImplicitBraces();
      } else {
        debug('');
        debug(((function() {
          var _i, _len, _ref, _results;
          _ref = this.tokens;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            t = _ref[_i];
            _results.push(t[0] + '/' + t[1]);
          }
          return _results;
        }).call(this)).join('  '));
        debug('');
        this.addImplicitBracesAndParentheses();
        debug('');
        debug(((function() {
          var _i, _len, _ref, _results;
          _ref = this.tokens;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            t = _ref[_i];
            _results.push(t[0] + '/' + t[1]);
          }
          return _results;
        }).call(this)).join('  '));
        debug('');
      }
      this.addImplicitParentheses();
      return this.tokens;
    };

    Rewriter.prototype.scanTokens = function(i, block, state) {
      var token, tokens;
      if (state == null) state = {};
      tokens = this.tokens;
      while (token = tokens[i]) {
        i += block.call(this, token, i, tokens, state);
      }
      return true;
    };

    Rewriter.prototype.scanEnd = function(start, block, state) {
      var i, token, tokens;
      if (state == null) state = {};
      tokens = this.tokens;
      i = start;
      try {
        while (token = tokens[i]) {
          i += block.call(this, token, i, tokens, state);
        }
      } catch (stopValue) {
        if (typeof stopValue !== 'number') throw stopValue;
        return i - start + stopValue;
      }
      throw 'End not found in scanEnd.';
    };

    Rewriter.prototype.detectEnd = function(i, condition, action) {
      var levels, token, tokens, _ref, _ref2;
      tokens = this.tokens;
      levels = 0;
      while (token = tokens[i]) {
        if (levels === 0 && condition.call(this, token, i)) {
          return action.call(this, token, i);
        }
        if (!token || levels < 0) return action.call(this, token, i - 1);
        if (_ref = token[0], __indexOf.call(EXPRESSION_START, _ref) >= 0) {
          levels += 1;
        } else if (_ref2 = token[0], __indexOf.call(EXPRESSION_END, _ref2) >= 0) {
          levels -= 1;
        }
        i += 1;
      }
      return i - 1;
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
      return this.scanTokens(0, function(token, i, tokens) {
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
        return ((_ref = token[0]) === ')' || _ref === 'CALL_END') || token[0] === 'OUTDENT' && this.tag(i - 1) === ')';
      };
      action = function(token, i) {
        return this.tokens[token[0] === 'OUTDENT' ? i - 1 : i][0] = 'CALL_END';
      };
      return this.scanTokens(0, function(token, i) {
        if (token[0] === 'CALL_START') this.detectEnd(i + 1, condition, action);
        return 1;
      });
    };

    Rewriter.prototype.closeOpenIndexes = function() {
      var action, condition;
      condition = function(token, i) {
        var _ref;
        return (_ref = token[0]) === ']' || _ref === 'INDEX_END';
      };
      action = function(token, i) {
        return token[0] = 'INDEX_END';
      };
      return this.scanTokens(0, function(token, i) {
        if (token[0] === 'INDEX_START') this.detectEnd(i + 1, condition, action);
        return 1;
      });
    };

    Rewriter.prototype.addImplicitBracesAndParentheses = function() {
      var addEndBrace, addEndParentheses, addStartAndEnd, detectStartBrace, detectStartParentheses, lineBreakListeners, stack,
        _this = this;
      stack = [];
      lineBreakListeners = [];
      detectStartBrace = function(token, i) {
        var _ref, _ref2, _ref3;
        return token[0] === ':' && (!(((_ref = stack[stack.length - 1]) != null ? _ref[0] : void 0) === '{' || ((_ref2 = stack[stack.length - 1]) != null ? _ref2[0] : void 0) === 'INDENT' && ((_ref3 = stack[stack.length - 2]) != null ? _ref3[0] : void 0) === '{' && !stack[stack.length - 2].generated) || _this.tag(i - 2) === ':');
      };
      detectStartParentheses = function(token, i) {
        return false;
      };
      addStartAndEnd = function(token, i) {
        var cb, idx, prevTag, scanState, tag, tok, value, _i, _len, _ref, _ref2, _ref3;
        if (_ref = (tag = token[0]), __indexOf.call(LINEBREAKS, _ref) >= 0) {
          for (_i = 0, _len = lineBreakListeners.length; _i < _len; _i++) {
            cb = lineBreakListeners[_i];
            cb();
          }
          lineBreakListeners = [];
        }
        if (__indexOf.call(EXPRESSION_START, tag) >= 0) {
          stack.push(token);
          return 1;
        }
        if (__indexOf.call(EXPRESSION_END, tag) >= 0) {
          if (((_ref2 = stack[stack.length - 1]) != null ? _ref2.generated : void 0) === token.generated && INVERSES[tag] === ((_ref3 = stack[stack.length - 1]) != null ? _ref3[0] : void 0)) {
            stack.pop();
            return 1;
          } else {
            return null;
          }
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
          stack.push((tok = _this.generate('{', value, token[2])));
          _this.tokens.splice(idx, 0, tok);
          return 2 + _this.scanEnd(i + 2, addEndBrace, scanState);
        }
        if (detectStartParentheses(token, i)) {
          stack.push((tok = _this.generate('CALL_START', '(', token[2])));
          _this.tokens.splice(i, 0, tok);
          return 2 + _this.scanEnd(i + 2, addEndParentheses);
        }
        return null;
      };
      addEndBrace = function(token, i, tokens, _arg) {
        var forcedEnd, line, naiveEnd, offset, one, otherEnd, sameLine, special1, special2, startsLine, tag, three, tok, two, value, _ref, _ref2, _ref3, _ref4;
        sameLine = _arg.sameLine, startsLine = _arg.startsLine;
        offset = addStartAndEnd(token, i);
        if (offset != null) return offset;
        if (!(((_ref = stack[stack.length - 1]) != null ? _ref.generated : void 0) && ((_ref2 = stack[stack.length - 1]) != null ? _ref2[0] : void 0) === '{')) {
          return 1;
        }
        _ref3 = tokens.slice(i + 1, (i + 3) + 1 || 9e9), one = _ref3[0], two = _ref3[1], three = _ref3[2];
        if ('HERECOMMENT' === (one != null ? one[0] : void 0)) return 1;
        tag = token[0], value = token[1], line = token[2];
        forcedEnd = __indexOf.call(EXPRESSION_END, tag) >= 0;
        naiveEnd = (tag === 'TERMINATOR') || (__indexOf.call(IMPLICIT_END, tag) >= 0 && sameLine);
        special1 = !startsLine && this.tag(i - 1) !== ',';
        special2 = !((two != null ? two[0] : void 0) === ':' || (one != null ? one[0] : void 0) === '@' && (three != null ? three[0] : void 0) === ':');
        otherEnd = tag === ',' && one && ((_ref4 = one[0]) !== 'IDENTIFIER' && _ref4 !== 'NUMBER' && _ref4 !== 'STRING' && _ref4 !== '@' && _ref4 !== 'TERMINATOR' && _ref4 !== 'OUTDENT');
        if (forcedEnd || naiveEnd && (special1 || special2) || otherEnd) {
          stack.pop();
          tok = this.generate('}', '}', token[2]);
          tokens.splice(i, 0, tok);
          throw 1;
        }
        return 1;
      };
      addEndParentheses = function(token, i, tokens, _arg) {
        var offset, startLine, tok;
        startLine = _arg.startLine;
        offset = addStartAndEnd(token, i);
        if (offset != null) return offset;
        if (false) {
          stack.pop();
          tok = this.generate('CALL_END', ')', token[2]);
          tokens.splice(i, 0, tok);
          throw 2;
        }
        return 1;
      };
      return this.scanTokens(0, function(token, i) {
        var _ref;
        return (_ref = addStartAndEnd(token, i)) != null ? _ref : 1;
      });
    };

    Rewriter.prototype.addImplicitBraces = function() {
      var action, condition, sameLine, stack, startsLine;
      stack = [];
      startsLine = null;
      sameLine = true;
      condition = function(token, i) {
        var one, tag, three, two, _ref, _ref2;
        _ref = this.tokens.slice(i + 1, (i + 3) + 1 || 9e9), one = _ref[0], two = _ref[1], three = _ref[2];
        if ('HERECOMMENT' === (one != null ? one[0] : void 0)) return false;
        tag = token[0];
        if (__indexOf.call(LINEBREAKS, tag) >= 0) sameLine = false;
        return (((tag === 'TERMINATOR' || tag === 'OUTDENT') || (__indexOf.call(IMPLICIT_END, tag) >= 0 && sameLine)) && ((!startsLine && this.tag(i - 1) !== ',') || !((two != null ? two[0] : void 0) === ':' || (one != null ? one[0] : void 0) === '@' && (three != null ? three[0] : void 0) === ':'))) || (tag === ',' && one && ((_ref2 = one[0]) !== 'IDENTIFIER' && _ref2 !== 'NUMBER' && _ref2 !== 'STRING' && _ref2 !== '@' && _ref2 !== 'TERMINATOR' && _ref2 !== 'OUTDENT'));
      };
      action = function(token, i) {
        var tok;
        tok = this.generate('}', '}', token[2]);
        return this.tokens.splice(i, 0, tok);
      };
      return this.scanTokens(0, function(token, i, tokens) {
        var idx, prevTag, tag, tok, value, _ref, _ref2;
        if (_ref = (tag = token[0]), __indexOf.call(EXPRESSION_START, _ref) >= 0) {
          stack.push([(tag === 'INDENT' && this.tag(i - 1) === '{' ? '{' : tag), i]);
          return 1;
        }
        if (__indexOf.call(EXPRESSION_END, tag) >= 0) {
          stack.pop();
          return 1;
        }
        if (!(tag === ':' && (((_ref2 = stack[stack.length - 1]) != null ? _ref2[0] : void 0) !== '{' || this.tag(i - 2) === ':'))) {
          return 1;
        }
        sameLine = true;
        stack.push(['{']);
        idx = this.tag(i - 2) === '@' ? i - 2 : i - 1;
        while (this.tag(idx - 2) === 'HERECOMMENT') {
          idx -= 2;
        }
        prevTag = this.tag(idx - 1);
        startsLine = !prevTag || (__indexOf.call(LINEBREAKS, prevTag) >= 0);
        value = new String('{');
        value.generated = true;
        tok = this.generate('{', value, token[2]);
        tokens.splice(idx, 0, tok);
        this.detectEnd(i + 2, condition, action);
        return 2;
      });
    };

    Rewriter.prototype.addImplicitParentheses = function() {
      var action, condition, noCall, seenControl, seenSingle;
      noCall = seenSingle = seenControl = false;
      condition = function(token, i) {
        var post, tag, _ref, _ref2;
        tag = token[0];
        if (!seenSingle && token.fromThen) return true;
        if (tag === 'IF' || tag === 'ELSE' || tag === 'CATCH' || tag === '->' || tag === '=>' || tag === 'CLASS') {
          seenSingle = true;
        }
        if (tag === 'IF' || tag === 'ELSE' || tag === 'SWITCH' || tag === 'TRY' || tag === '=') {
          seenControl = true;
        }
        if ((tag === '.' || tag === '?.' || tag === '::') && this.tag(i - 1) === 'OUTDENT') {
          return true;
        }
        return !token.generated && this.tag(i - 1) !== ',' && (__indexOf.call(IMPLICIT_END, tag) >= 0 || (tag === 'INDENT' && !seenControl)) && (tag !== 'INDENT' || (((_ref = this.tag(i - 2)) !== 'CLASS' && _ref !== 'EXTENDS') && (_ref2 = this.tag(i - 1), __indexOf.call(IMPLICIT_BLOCK, _ref2) < 0) && !((post = this.tokens[i + 1]) && post.generated && post[0] === '{')));
      };
      action = function(token, i) {
        return this.tokens.splice(i, 0, this.generate('CALL_END', ')', token[2]));
      };
      return this.scanTokens(0, function(token, i, tokens) {
        var callObject, current, next, prev, tag, _ref, _ref2, _ref3;
        tag = token[0];
        if (tag === 'CLASS' || tag === 'IF') noCall = true;
        _ref = tokens.slice(i - 1, (i + 1) + 1 || 9e9), prev = _ref[0], current = _ref[1], next = _ref[2];
        callObject = !noCall && tag === 'INDENT' && next && next.generated && next[0] === '{' && prev && (_ref2 = prev[0], __indexOf.call(IMPLICIT_FUNC, _ref2) >= 0);
        seenSingle = false;
        seenControl = false;
        if (__indexOf.call(LINEBREAKS, tag) >= 0) noCall = false;
        if (prev && !prev.spaced && tag === '?') token.call = true;
        if (token.fromThen) return 1;
        if (!(callObject || (prev != null ? prev.spaced : void 0) && (prev.call || (_ref3 = prev[0], __indexOf.call(IMPLICIT_FUNC, _ref3) >= 0)) && (__indexOf.call(IMPLICIT_CALL, tag) >= 0 || !(token.spaced || token.newLine) && __indexOf.call(IMPLICIT_UNSPACED_CALL, tag) >= 0))) {
          return 1;
        }
        tokens.splice(i, 0, this.generate('CALL_START', '(', token[2]));
        this.detectEnd(i + 1, condition, action);
        if (prev[0] === '?') prev[0] = 'FUNC_EXIST';
        return 2;
      });
    };

    Rewriter.prototype.addImplicitIndentation = function() {
      var action, condition, indent, outdent, starter;
      starter = indent = outdent = null;
      condition = function(token, i) {
        var _ref;
        return token[1] !== ';' && (_ref = token[0], __indexOf.call(SINGLE_CLOSERS, _ref) >= 0) && !(token[0] === 'ELSE' && (starter !== 'IF' && starter !== 'THEN'));
      };
      action = function(token, i) {
        return this.tokens.splice((this.tag(i - 1) === ',' ? i - 1 : i), 0, outdent);
      };
      return this.scanTokens(0, function(token, i, tokens) {
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
        return (_ref = token[0]) === 'TERMINATOR' || _ref === 'INDENT';
      };
      action = function(token, i) {
        if (token[0] !== 'INDENT' || (token.generated && !token.fromThen)) {
          return original[0] = 'POST_' + original[0];
        }
      };
      return this.scanTokens(0, function(token, i) {
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
