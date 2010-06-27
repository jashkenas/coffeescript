/**
 * CoffeeScript Compiler v0.6.2
 * http://coffeescript.org
 *
 * Copyright 2010, Jeremy Ashkenas
 * Released under the MIT License
 */
(function(){
  var balancedString, compact, count, del, extend, flatten, helpers, include, indexOf, merge, starts;
  var __hasProp = Object.prototype.hasOwnProperty;
  // This file contains the common helper functions that we'd like to share among
  // the **Lexer**, **Rewriter**, and the **Nodes**. Merge objects, flatten
  // arrays, count characters, that sort of thing.
  // Set up exported variables for both **Node.js** and the browser.
  if (!((typeof process !== "undefined" && process !== null))) {
    this.exports = this;
  }
  helpers = (exports.helpers = {});
  // Cross-browser indexOf, so that IE can join the party.
  helpers.indexOf = (indexOf = function(array, item, from) {
    var _a, _b, index, other;
    if (array.indexOf) {
      return array.indexOf(item, from);
    }
    _a = array;
    for (index = 0, _b = _a.length; index < _b; index++) {
      other = _a[index];
      if (other === item && (!from || (from <= index))) {
        return index;
      }
    }
    return -1;
  });
  // Does a list include a value?
  helpers.include = (include = function(list, value) {
    return indexOf(list, value) >= 0;
  });
  // Peek at the beginning of a given string to see if it matches a sequence.
  helpers.starts = (starts = function(string, literal, start) {
    return string.substring(start, (start || 0) + literal.length) === literal;
  });
  // Trim out all falsy values from an array.
  helpers.compact = (compact = function(array) {
    var _a, _b, _c, _d, item;
    _a = []; _c = array;
    for (_b = 0, _d = _c.length; _b < _d; _b++) {
      item = _c[_b];
      item ? _a.push(item) : null;
    }
    return _a;
  });
  // Count the number of occurences of a character in a string.
  helpers.count = (count = function(string, letter) {
    var num, pos;
    num = 0;
    pos = indexOf(string, letter);
    while (pos !== -1) {
      num += 1;
      pos = indexOf(string, letter, pos + 1);
    }
    return num;
  });
  // Merge objects, returning a fresh copy with attributes from both sides.
  // Used every time `BaseNode#compile` is called, to allow properties in the
  // options hash to propagate down the tree without polluting other branches.
  helpers.merge = (merge = function(options, overrides) {
    var _a, _b, fresh, key, val;
    fresh = {};
    _a = options;
    for (key in _a) { if (__hasProp.call(_a, key)) {
      val = _a[key];
      (fresh[key] = val);
    }}
    if (overrides) {
      _b = overrides;
      for (key in _b) { if (__hasProp.call(_b, key)) {
        val = _b[key];
        (fresh[key] = val);
      }}
    }
    return fresh;
  });
  // Extend a source object with the properties of another object (shallow copy).
  // We use this to simulate Node's deprecated `process.mixin`
  helpers.extend = (extend = function(object, properties) {
    var _a, _b, key, val;
    _a = []; _b = properties;
    for (key in _b) { if (__hasProp.call(_b, key)) {
      val = _b[key];
      _a.push((object[key] = val));
    }}
    return _a;
  });
  // Return a completely flattened version of an array. Handy for getting a
  // list of `children` from the nodes.
  helpers.flatten = (flatten = function(array) {
    var _a, _b, _c, item, memo;
    memo = [];
    _b = array;
    for (_a = 0, _c = _b.length; _a < _c; _a++) {
      item = _b[_a];
      item instanceof Array ? (memo = memo.concat(item)) : memo.push(item);
    }
    return memo;
  });
  // Delete a key from an object, returning the value. Useful when a node is
  // looking for a particular method in an options hash.
  helpers.del = (del = function(obj, key) {
    var val;
    val = obj[key];
    delete obj[key];
    return val;
  });
  // Matches a balanced group such as a single or double-quoted string. Pass in
  // a series of delimiters, all of which must be nested correctly within the
  // contents of the string. This method allows us to have strings within
  // interpolations within strings, ad infinitum.
  helpers.balancedString = (balancedString = function(str, delimited, options) {
    var _a, _b, _c, _d, close, i, levels, open, pair, slash;
    options = options || {};
    slash = delimited[0][0] === '/';
    levels = [];
    i = 0;
    while (i < str.length) {
      if (levels.length && starts(str, '\\', i)) {
        i += 1;
      } else {
        _b = delimited;
        for (_a = 0, _c = _b.length; _a < _c; _a++) {
          pair = _b[_a];
          _d = pair;
          open = _d[0];
          close = _d[1];
          if (levels.length && starts(str, close, i) && levels[levels.length - 1] === pair) {
            levels.pop();
            i += close.length - 1;
            if (!(levels.length)) {
              i += 1;
            }
            break;
          } else if (starts(str, open, i)) {
            levels.push(pair);
            i += open.length - 1;
            break;
          }
        }
      }
      if (!levels.length || slash && starts(str, '\n', i)) {
        break;
      }
      i += 1;
    }
    if (levels.length) {
      if (slash) {
        return false;
      }
      throw new Error(("SyntaxError: Unterminated " + (levels.pop()[0]) + " starting on line " + (this.line + 1)));
    }
    if (!i) {
      return false;
    } else {
      return str.substring(0, i);
    }
  });
})();
(function(){
  var BALANCED_PAIRS, COMMENTS, EXPRESSION_CLOSE, EXPRESSION_END, EXPRESSION_START, IMPLICIT_BLOCK, IMPLICIT_CALL, IMPLICIT_END, IMPLICIT_FUNC, INVERSES, Rewriter, SINGLE_CLOSERS, SINGLE_LINERS, _a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, helpers, include, pair;
  var __hasProp = Object.prototype.hasOwnProperty;
  // The CoffeeScript language has a good deal of optional syntax, implicit syntax,
  // and shorthand syntax. This can greatly complicate a grammar and bloat
  // the resulting parse table. Instead of making the parser handle it all, we take
  // a series of passes over the token stream, using this **Rewriter** to convert
  // shorthand into the unambiguous long form, add implicit indentation and
  // parentheses, balance incorrect nestings, and generally clean things up.
  // Set up exported variables for both Node.js and the browser.
  if ((typeof process !== "undefined" && process !== null)) {
    _a = require('./helpers');
    helpers = _a.helpers;
  } else {
    this.exports = this;
    helpers = this.helpers;
  }
  // Import the helpers we need.
  _b = helpers;
  include = _b.include;
  // The **Rewriter** class is used by the [Lexer](lexer.html), directly against
  // its internal array of tokens.
  exports.Rewriter = (function() {
    Rewriter = function() {    };
    // Rewrite the token stream in multiple passes, one logical filter at
    // a time. This could certainly be changed into a single pass through the
    // stream, with a big ol' efficient switch, but it's much nicer to work with
    // like this. The order of these passes matters -- indentation must be
    // corrected before implicit parentheses can be wrapped around blocks of code.
    Rewriter.prototype.rewrite = function(tokens) {
      this.tokens = tokens;
      this.adjustComments();
      this.removeLeadingNewlines();
      this.removeMidExpressionNewlines();
      this.closeOpenCallsAndIndexes();
      this.addImplicitIndentation();
      this.addImplicitParentheses();
      this.ensureBalance(BALANCED_PAIRS);
      this.rewriteClosingParens();
      return this.tokens;
    };
    // Rewrite the token stream, looking one token ahead and behind.
    // Allow the return value of the block to tell us how many tokens to move
    // forwards (or backwards) in the stream, to make sure we don't miss anything
    // as tokens are inserted and removed, and the stream changes length under
    // our feet.
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
    // Massage newlines and indentations so that comments don't have to be
    // correctly indented, or appear on a line of their own.
    Rewriter.prototype.adjustComments = function() {
      return this.scanTokens((function(__this) {
        var __func = function(prev, token, post, i) {
          var _c, _d, after, before;
          if (!(include(COMMENTS, token[0]))) {
            return 1;
          }
          _c = [this.tokens[i - 2], this.tokens[i + 2]];
          before = _c[0];
          after = _c[1];
          if (after && after[0] === 'INDENT') {
            this.tokens.splice(i + 2, 1);
            before && before[0] === 'OUTDENT' && post && (prev[0] === post[0]) && (post[0] === 'TERMINATOR') ? this.tokens.splice(i - 2, 1) : this.tokens.splice(i, 0, after);
          } else if (prev && !('TERMINATOR' === (_d = prev[0]) || 'INDENT' === _d || 'OUTDENT' === _d)) {
            post && post[0] === 'TERMINATOR' && after && after[0] === 'OUTDENT' ? this.tokens.splice.apply(this.tokens, [i, 0].concat(this.tokens.splice(i + 2, 2))) : this.tokens.splice(i, 0, ['TERMINATOR', "\n", prev[2]]);
            return 2;
          } else if (before && before[0] === 'OUTDENT' && prev && prev[0] === 'TERMINATOR' && post && post[0] === 'TERMINATOR' && after && after[0] === 'ELSE') {
            this.tokens.splice(i + 1, 0, this.tokens.splice(i - 2, 1)[0]);
          }
          return 1;
        };
        return (function() {
          return __func.apply(__this, arguments);
        });
      })(this));
    };
    // Leading newlines would introduce an ambiguity in the grammar, so we
    // dispatch them here.
    Rewriter.prototype.removeLeadingNewlines = function() {
      var _c;
      _c = [];
      while (this.tokens[0] && this.tokens[0][0] === 'TERMINATOR') {
        _c.push(this.tokens.shift());
      }
      return _c;
    };
    // Some blocks occur in the middle of expressions -- when we're expecting
    // this, remove their trailing newlines.
    Rewriter.prototype.removeMidExpressionNewlines = function() {
      return this.scanTokens((function(__this) {
        var __func = function(prev, token, post, i) {
          if (!(post && include(EXPRESSION_CLOSE, post[0]) && token[0] === 'TERMINATOR')) {
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
    // The lexer has tagged the opening parenthesis of a method call, and the
    // opening bracket of an indexing operation. Match them with their paired
    // close.
    Rewriter.prototype.closeOpenCallsAndIndexes = function() {
      var brackets, parens;
      parens = [0];
      brackets = [0];
      return this.scanTokens((function(__this) {
        var __func = function(prev, token, post, i) {
          var _c;
          if ((_c = token[0]) === 'CALL_START') {
            parens.push(0);
          } else if (_c === 'INDEX_START') {
            brackets.push(0);
          } else if (_c === '(') {
            parens[parens.length - 1] += 1;
          } else if (_c === '[') {
            brackets[brackets.length - 1] += 1;
          } else if (_c === ')') {
            if (parens[parens.length - 1] === 0) {
              parens.pop();
              token[0] = 'CALL_END';
            } else {
              parens[parens.length - 1] -= 1;
            }
          } else if (_c === ']') {
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
    Rewriter.prototype.addImplicitParentheses = function() {
      var closeCalls, stack;
      stack = [0];
      closeCalls = (function(__this) {
        var __func = function(i) {
          var _c, size, tmp;
          (_c = stack[stack.length - 1]);

          for (tmp = 0; tmp < _c; tmp += 1) {
            this.tokens.splice(i, 0, ['CALL_END', ')', this.tokens[i][2]]);
          }
          size = stack[stack.length - 1] + 1;
          stack[stack.length - 1] = 0;
          return size;
        };
        return (function() {
          return __func.apply(__this, arguments);
        });
      })(this);
      return this.scanTokens((function(__this) {
        var __func = function(prev, token, post, i) {
          var _c, _d, j, nx, open, size, tag;
          tag = token[0];
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
            if (tag === 'INDENT' && !token.generated && open && !(prev && include(IMPLICIT_BLOCK, prev[0]))) {
              size = closeCalls(i);
              stack.push(0);
              return size;
            }
            stack.push(0);
            return 1;
          }
          if (open && !token.generated && (!post || include(IMPLICIT_END, tag))) {
            j = 1;
            while ((typeof (_d = (nx = this.tokens[i + j])) !== "undefined" && _d !== null) && include(IMPLICIT_END, nx[0])) {
              j++;
            }
            if ((typeof nx !== "undefined" && nx !== null) && nx[0] === ',') {
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
        };
        return (function() {
          return __func.apply(__this, arguments);
        });
      })(this));
    };
    // Because our grammar is LALR(1), it can't handle some single-line
    // expressions that lack ending delimiters. The **Rewriter** adds the implicit
    // blocks, so it doesn't need to. ')' can close a single-line block,
    // but we need to make sure it's balanced.
    Rewriter.prototype.addImplicitIndentation = function() {
      return this.scanTokens((function(__this) {
        var __func = function(prev, token, post, i) {
          var idx, indent, insertion, outdent, parens, pre, starter, tok;
          if (!(include(SINGLE_LINERS, token[0]) && post[0] !== 'INDENT' && !(token[0] === 'ELSE' && post[0] === 'IF'))) {
            return 1;
          }
          starter = token[0];
          indent = ['INDENT', 2, token[2]];
          indent.generated = true;
          this.tokens.splice(i + 1, 0, indent);
          idx = i + 1;
          parens = 0;
          while (true) {
            idx += 1;
            tok = this.tokens[idx];
            pre = this.tokens[idx - 1];
            if ((!tok || (include(SINGLE_CLOSERS, tok[0]) && tok[1] !== ';' && parens === 0) || (tok[0] === ')' && parens === 0)) && !(tok[0] === 'ELSE' && !('IF' === starter || 'THEN' === starter))) {
              insertion = pre[0] === "," ? idx - 1 : idx;
              outdent = ['OUTDENT', 2, token[2]];
              outdent.generated = true;
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
        };
        return (function() {
          return __func.apply(__this, arguments);
        });
      })(this));
    };
    // Ensure that all listed pairs of tokens are correctly balanced throughout
    // the course of the token stream.
    Rewriter.prototype.ensureBalance = function(pairs) {
      var _c, _d, key, levels, line, open, openLine, unclosed, value;
      levels = {};
      openLine = {};
      this.scanTokens((function(__this) {
        var __func = function(prev, token, post, i) {
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
        };
        return (function() {
          return __func.apply(__this, arguments);
        });
      })(this));
      unclosed = (function() {
        _c = []; _d = levels;
        for (key in _d) { if (__hasProp.call(_d, key)) {
          value = _d[key];
          value > 0 ? _c.push(key) : null;
        }}
        return _c;
      })();
      if (unclosed.length) {
        open = unclosed[0];
        line = openLine[open] + 1;
        throw new Error(("unclosed " + open + " on line " + line));
      }
    };
    // We'd like to support syntax like this:
    //     el.click((event) ->
    //       el.hide())
    // In order to accomplish this, move outdents that follow closing parens
    // inwards, safely. The steps to accomplish this are:
    // 1. Check that all paired tokens are balanced and in order.
    // 2. Rewrite the stream with a stack: if you see an `EXPRESSION_START`, add it
    //    to the stack. If you see an `EXPRESSION_END`, pop the stack and replace
    //    it with the inverse of what we've just popped.
    // 3. Keep track of "debt" for tokens that we manufacture, to make sure we end
    //    up balanced in the end.
    // 4. Be careful not to alter array or parentheses delimiters with overzealous
    //    rewriting.
    Rewriter.prototype.rewriteClosingParens = function() {
      var _c, debt, key, stack, val;
      stack = [];
      debt = {};
      _c = INVERSES;
      for (key in _c) { if (__hasProp.call(_c, key)) {
        val = _c[key];
        (debt[key] = 0);
      }}
      return this.scanTokens((function(__this) {
        var __func = function(prev, token, post, i) {
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
        };
        return (function() {
          return __func.apply(__this, arguments);
        });
      })(this));
    };
    return Rewriter;
  })();
  // Constants
  // ---------
  // List of the token pairs that must be balanced.
  BALANCED_PAIRS = [['(', ')'], ['[', ']'], ['{', '}'], ['INDENT', 'OUTDENT'], ['PARAM_START', 'PARAM_END'], ['CALL_START', 'CALL_END'], ['INDEX_START', 'INDEX_END']];
  // The inverse mappings of `BALANCED_PAIRS` we're trying to fix up, so we can
  // look things up from either end.
  INVERSES = {};
  _d = BALANCED_PAIRS;
  for (_c = 0, _e = _d.length; _c < _e; _c++) {
    pair = _d[_c];
    INVERSES[pair[0]] = pair[1];
    INVERSES[pair[1]] = pair[0];
  }
  // The tokens that signal the start of a balanced pair.
  EXPRESSION_START = (function() {
    _f = []; _h = BALANCED_PAIRS;
    for (_g = 0, _i = _h.length; _g < _i; _g++) {
      pair = _h[_g];
      _f.push(pair[0]);
    }
    return _f;
  })();
  // The tokens that signal the end of a balanced pair.
  EXPRESSION_END = (function() {
    _j = []; _l = BALANCED_PAIRS;
    for (_k = 0, _m = _l.length; _k < _m; _k++) {
      pair = _l[_k];
      _j.push(pair[1]);
    }
    return _j;
  })();
  // Tokens that indicate the close of a clause of an expression.
  EXPRESSION_CLOSE = ['CATCH', 'WHEN', 'ELSE', 'FINALLY'].concat(EXPRESSION_END);
  // Tokens that, if followed by an `IMPLICIT_CALL`, indicate a function invocation.
  IMPLICIT_FUNC = ['IDENTIFIER', 'SUPER', ')', 'CALL_END', ']', 'INDEX_END', '@'];
  // If preceded by an `IMPLICIT_FUNC`, indicates a function invocation.
  IMPLICIT_CALL = ['IDENTIFIER', 'NUMBER', 'STRING', 'JS', 'REGEX', 'NEW', 'PARAM_START', 'TRY', 'DELETE', 'TYPEOF', 'SWITCH', 'TRUE', 'FALSE', 'YES', 'NO', 'ON', 'OFF', '!', '!!', 'THIS', 'NULL', '@', '->', '=>', '[', '(', '{'];
  // Tokens indicating that the implicit call must enclose a block of expressions.
  IMPLICIT_BLOCK = ['->', '=>', '{', '[', ','];
  // Tokens that always mark the end of an implicit call for single-liners.
  IMPLICIT_END = ['IF', 'UNLESS', 'FOR', 'WHILE', 'UNTIL', 'LOOP', 'TERMINATOR', 'INDENT'].concat(EXPRESSION_END);
  // Single-line flavors of block expressions that have unclosed endings.
  // The grammar can't disambiguate them, so we insert the implicit indentation.
  SINGLE_LINERS = ['ELSE', "->", "=>", 'TRY', 'FINALLY', 'THEN'];
  SINGLE_CLOSERS = ['TERMINATOR', 'CATCH', 'FINALLY', 'ELSE', 'OUTDENT', 'LEADING_WHEN'];
  // Comment flavors.
  COMMENTS = ['COMMENT', 'HERECOMMENT'];
})();
(function(){
  var ASSIGNED, ASSIGNMENT, CALLABLE, CODE, COFFEE_ALIASES, COFFEE_KEYWORDS, COMMENT, COMMENT_CLEANER, CONVERSIONS, HALF_ASSIGNMENTS, HEREDOC, HEREDOC_INDENT, IDENTIFIER, INTERPOLATION, JS_CLEANER, JS_FORBIDDEN, JS_KEYWORDS, LAST_DENT, LAST_DENTS, LINE_BREAK, Lexer, MULTILINER, MULTI_DENT, NEXT_CHARACTER, NOT_REGEX, NO_NEWLINE, NUMBER, OPERATOR, REGEX_END, REGEX_ESCAPE, REGEX_INTERPOLATION, REGEX_START, RESERVED, Rewriter, STRING_NEWLINES, WHITESPACE, _a, _b, _c, balancedString, compact, count, helpers, include, starts;
  var __slice = Array.prototype.slice;
  // The CoffeeScript Lexer. Uses a series of token-matching regexes to attempt
  // matches against the beginning of the source code. When a match is found,
  // a token is produced, we consume the match, and start again. Tokens are in the
  // form:
  //     [tag, value, lineNumber]
  // Which is a format that can be fed directly into [Jison](http://github.com/zaach/jison).
  // Set up the Lexer for both Node.js and the browser, depending on where we are.
  if ((typeof process !== "undefined" && process !== null)) {
    _a = require('./rewriter');
    Rewriter = _a.Rewriter;
    _b = require('./helpers');
    helpers = _b.helpers;
  } else {
    this.exports = this;
    Rewriter = this.Rewriter;
    helpers = this.helpers;
  }
  // Import the helpers we need.
  _c = helpers;
  include = _c.include;
  count = _c.count;
  starts = _c.starts;
  compact = _c.compact;
  balancedString = _c.balancedString;
  // The Lexer Class
  // ---------------
  // The Lexer class reads a stream of CoffeeScript and divvys it up into tagged
  // tokens. Some potential ambiguity in the grammar has been avoided by
  // pushing some extra smarts into the Lexer.
  exports.Lexer = (function() {
    Lexer = function() {    };
    // **tokenize** is the Lexer's main method. Scan by attempting to match tokens
    // one at a time, using a regular expression anchored at the start of the
    // remaining code, or a custom recursive token-matching method
    // (for interpolations). When the next token has been recorded, we move forward
    // within the code past the token, and begin again.
    // Each tokenizing method is responsible for incrementing `@i` by the number of
    // characters it has consumed. `@i` can be thought of as our finger on the page
    // of source.
    // Before returning the token stream, run it through the [Rewriter](rewriter.html)
    // unless explicitly asked not to.
    Lexer.prototype.tokenize = function(code, options) {
      var o;
      code = code.replace(/(\r|\s+$)/g, '');
      o = options || {};
      this.code = code;
      // The remainder of the source code.
      this.i = 0;
      // Current character position we're parsing.
      this.line = o.line || 0;
      // The current line.
      this.indent = 0;
      // The current indentation level.
      this.outdebt = 0;
      // The under-outdentation of the last outdent.
      this.indents = [];
      // The stack of all current indentation levels.
      this.tokens = [];
      // Stream of parsed tokens in the form ['TYPE', value, line]
      while (this.i < this.code.length) {
        this.chunk = this.code.slice(this.i);
        this.extractNextToken();
      }
      this.closeIndentation();
      if (o.rewrite === false) {
        return this.tokens;
      }
      return (new Rewriter()).rewrite(this.tokens);
    };
    // At every position, run through this list of attempted matches,
    // short-circuiting if any of them succeed. Their order determines precedence:
    // `@literalToken` is the fallback catch-all.
    Lexer.prototype.extractNextToken = function() {
      if (this.identifierToken()) {
        return null;
      }
      if (this.commentToken()) {
        return null;
      }
      if (this.whitespaceToken()) {
        return null;
      }
      if (this.lineToken()) {
        return null;
      }
      if (this.heredocToken()) {
        return null;
      }
      if (this.stringToken()) {
        return null;
      }
      if (this.numberToken()) {
        return null;
      }
      if (this.regexToken()) {
        return null;
      }
      if (this.jsToken()) {
        return null;
      }
      return this.literalToken();
    };
    // Tokenizers
    // ----------
    // Matches identifying literals: variables, keywords, method names, etc.
    // Check to ensure that JavaScript reserved words aren't being used as
    // identifiers. Because CoffeeScript reserves a handful of keywords that are
    // allowed in JavaScript, we're careful not to tag them as keywords when
    // referenced as property names here, so you can still do `jQuery.is()` even
    // though `is` means `===` otherwise.
    Lexer.prototype.identifierToken = function() {
      var close_index, forcedIdentifier, id, tag;
      if (!(id = this.match(IDENTIFIER, 1))) {
        return false;
      }
      this.i += id.length;
      forcedIdentifier = this.tagAccessor() || this.match(ASSIGNED, 1);
      tag = 'IDENTIFIER';
      if (include(JS_KEYWORDS, id) || (!forcedIdentifier && include(COFFEE_KEYWORDS, id))) {
        tag = id.toUpperCase();
      }
      if (tag === 'WHEN' && include(LINE_BREAK, this.tag())) {
        tag = 'LEADING_WHEN';
      }
      if (include(JS_FORBIDDEN, id)) {
        if (forcedIdentifier) {
          tag = 'STRING';
          id = ("'" + id + "'");
          if (forcedIdentifier === 'accessor') {
            close_index = true;
            if (this.tag() !== '@') {
              this.tokens.pop();
            }
            this.token('INDEX_START', '[');
          }
        } else if (include(RESERVED, id)) {
          this.identifierError(id);
        }
      }
      if (!(forcedIdentifier)) {
        if (include(COFFEE_ALIASES, id)) {
          tag = (id = CONVERSIONS[id]);
        }
        if (this.prev() && this.prev()[0] === 'ASSIGN' && include(HALF_ASSIGNMENTS, tag)) {
          return this.tagHalfAssignment(tag);
        }
      }
      this.token(tag, id);
      if (close_index) {
        this.token(']', ']');
      }
      return true;
    };
    // Matches numbers, including decimals, hex, and exponential notation.
    // Be careful not to interfere with ranges-in-progress.
    Lexer.prototype.numberToken = function() {
      var number;
      if (!(number = this.match(NUMBER, 1))) {
        return false;
      }
      if (this.tag() === '.' && starts(number, '.')) {
        return false;
      }
      this.i += number.length;
      this.token('NUMBER', number);
      return true;
    };
    // Matches strings, including multi-line strings. Ensures that quotation marks
    // are balanced within the string's contents, and within nested interpolations.
    Lexer.prototype.stringToken = function() {
      var string;
      if (!(starts(this.chunk, '"') || starts(this.chunk, "'"))) {
        return false;
      }
      if (!(string = this.balancedToken(['"', '"'], ['${', '}']) || this.balancedToken(["'", "'"]))) {
        return false;
      }
      this.interpolateString(string.replace(STRING_NEWLINES, " \\\n"));
      this.line += count(string, "\n");
      this.i += string.length;
      return true;
    };
    // Matches heredocs, adjusting indentation to the correct level, as heredocs
    // preserve whitespace, but ignore indentation to the left.
    Lexer.prototype.heredocToken = function() {
      var doc, match, quote;
      if (!(match = this.chunk.match(HEREDOC))) {
        return false;
      }
      quote = match[1].substr(0, 1);
      doc = this.sanitizeHeredoc(match[2] || match[4], {
        quote: quote
      });
      this.interpolateString(("" + quote + doc + quote));
      this.line += count(match[1], "\n");
      this.i += match[1].length;
      return true;
    };
    // Matches and conumes comments. We pass through comments into JavaScript,
    // so they're treated as real tokens, like any other part of the language.
    Lexer.prototype.commentToken = function() {
      var comment, i, lines, match;
      if (!(match = this.chunk.match(COMMENT))) {
        return false;
      }
      if (match[3]) {
        comment = this.sanitizeHeredoc(match[3], {
          herecomment: true
        });
        this.token('HERECOMMENT', comment.split(MULTILINER));
        this.token('TERMINATOR', '\n');
      } else {
        lines = compact(match[1].replace(COMMENT_CLEANER, '').split(MULTILINER));
        i = this.tokens.length - 1;
        if (this.unfinished()) {
          while (this.tokens[i] && !include(LINE_BREAK, this.tokens[i][0])) {
            i -= 1;
          }
        }
        this.tokens.splice(i + 1, 0, ['COMMENT', lines, this.line], ['TERMINATOR', '\n', this.line]);
      }
      this.line += count(match[1], "\n");
      this.i += match[1].length;
      return true;
    };
    // Matches JavaScript interpolated directly into the source via backticks.
    Lexer.prototype.jsToken = function() {
      var script;
      if (!(starts(this.chunk, '`'))) {
        return false;
      }
      if (!(script = this.balancedToken(['`', '`']))) {
        return false;
      }
      this.token('JS', script.replace(JS_CLEANER, ''));
      this.i += script.length;
      return true;
    };
    // Matches regular expression literals. Lexing regular expressions is difficult
    // to distinguish from division, so we borrow some basic heuristics from
    // JavaScript and Ruby, borrow slash balancing from `@balancedToken`, and
    // borrow interpolation from `@interpolateString`.
    Lexer.prototype.regexToken = function() {
      var end, flags, regex, str;
      if (!(this.chunk.match(REGEX_START))) {
        return false;
      }
      if (include(NOT_REGEX, this.tag())) {
        return false;
      }
      if (!(regex = this.balancedToken(['/', '/']))) {
        return false;
      }
      if (!(end = this.chunk.substr(regex.length).match(REGEX_END))) {
        return false;
      }
      if (end[2]) {
        regex += (flags = end[2]);
      }
      if (regex.match(REGEX_INTERPOLATION)) {
        str = regex.substring(1).split('/')[0];
        str = str.replace(REGEX_ESCAPE, function(escaped) {
          return '\\' + escaped;
        });
        this.tokens = this.tokens.concat([['(', '('], ['NEW', 'new'], ['IDENTIFIER', 'RegExp'], ['CALL_START', '(']]);
        this.interpolateString(("\"" + str + "\""), true);
        this.tokens = this.tokens.concat([[',', ','], ['STRING', ("\"" + flags + "\"")], [')', ')'], [')', ')']]);
      } else {
        this.token('REGEX', regex);
      }
      this.i += regex.length;
      return true;
    };
    // Matches a token in which which the passed delimiter pairs must be correctly
    // balanced (ie. strings, JS literals).
    Lexer.prototype.balancedToken = function() {
      var delimited;
      var _d = arguments.length, _e = _d >= 1;
      delimited = __slice.call(arguments, 0, _d - 0);
      return balancedString(this.chunk, delimited);
    };
    // Matches newlines, indents, and outdents, and determines which is which.
    // If we can detect that the current line is continued onto the the next line,
    // then the newline is suppressed:
    //     elements
    //       .each( ... )
    //       .map( ... )
    // Keeps track of the level of indentation, because a single outdent token
    // can close multiple indents, so we need to know how far in we happen to be.
    Lexer.prototype.lineToken = function() {
      var diff, indent, nextCharacter, noNewlines, prev, size;
      if (!(indent = this.match(MULTI_DENT, 1))) {
        return false;
      }
      this.line += count(indent, "\n");
      this.i += indent.length;
      prev = this.prev(2);
      size = indent.match(LAST_DENTS).reverse()[0].match(LAST_DENT)[1].length;
      nextCharacter = this.chunk.match(NEXT_CHARACTER)[1];
      noNewlines = nextCharacter === '.' || nextCharacter === ',' || this.unfinished();
      if (size === this.indent) {
        if (noNewlines) {
          return this.suppressNewlines();
        }
        return this.newlineToken(indent);
      } else if (size > this.indent) {
        if (noNewlines) {
          return this.suppressNewlines();
        }
        diff = size - this.indent;
        this.token('INDENT', diff);
        this.indents.push(diff);
      } else {
        this.outdentToken(this.indent - size, noNewlines);
      }
      this.indent = size;
      return true;
    };
    // Record an outdent token or multiple tokens, if we happen to be moving back
    // inwards past several recorded indents.
    Lexer.prototype.outdentToken = function(moveOut, noNewlines) {
      var lastIndent;
      if (moveOut > -this.outdebt) {
        while (moveOut > 0 && this.indents.length) {
          lastIndent = this.indents.pop();
          this.token('OUTDENT', lastIndent);
          moveOut -= lastIndent;
        }
      } else {
        this.outdebt += moveOut;
      }
      if (!(noNewlines)) {
        this.outdebt = moveOut;
      }
      if (!(this.tag() === 'TERMINATOR' || noNewlines)) {
        this.token('TERMINATOR', "\n");
      }
      return true;
    };
    // Matches and consumes non-meaningful whitespace. Tag the previous token
    // as being "spaced", because there are some cases where it makes a difference.
    Lexer.prototype.whitespaceToken = function() {
      var prev, space;
      if (!(space = this.match(WHITESPACE, 1))) {
        return false;
      }
      prev = this.prev();
      if (prev) {
        prev.spaced = true;
      }
      this.i += space.length;
      return true;
    };
    // Generate a newline token. Consecutive newlines get merged together.
    Lexer.prototype.newlineToken = function(newlines) {
      if (!(this.tag() === 'TERMINATOR')) {
        this.token('TERMINATOR', "\n");
      }
      return true;
    };
    // Use a `\` at a line-ending to suppress the newline.
    // The slash is removed here once its job is done.
    Lexer.prototype.suppressNewlines = function() {
      if (this.value() === "\\") {
        this.tokens.pop();
      }
      return true;
    };
    // We treat all other single characters as a token. Eg.: `( ) , . !`
    // Multi-character operators are also literal tokens, so that Jison can assign
    // the proper order of operations. There are some symbols that we tag specially
    // here. `;` and newlines are both treated as a `TERMINATOR`, we distinguish
    // parentheses that indicate a method call from regular parentheses, and so on.
    Lexer.prototype.literalToken = function() {
      var match, prevSpaced, space, tag, value;
      match = this.chunk.match(OPERATOR);
      value = match && match[1];
      space = match && match[2];
      if (value && value.match(CODE)) {
        this.tagParameters();
      }
      value = value || this.chunk.substr(0, 1);
      prevSpaced = this.prev() && this.prev().spaced;
      tag = value;
      if (value.match(ASSIGNMENT)) {
        tag = 'ASSIGN';
        if (include(JS_FORBIDDEN, this.value)) {
          this.assignmentError();
        }
      } else if (value === ';') {
        tag = 'TERMINATOR';
      } else if (include(CALLABLE, this.tag()) && !prevSpaced) {
        if (value === '(') {
          tag = 'CALL_START';
        } else if (value === '[') {
          tag = 'INDEX_START';
          if (this.tag() === '?') {
            this.tag(1, 'INDEX_SOAK');
          }
          if (this.tag() === '::') {
            this.tag(1, 'INDEX_PROTO');
          }
        }
      }
      this.i += value.length;
      if (space && prevSpaced && this.prev()[0] === 'ASSIGN' && include(HALF_ASSIGNMENTS, tag)) {
        return this.tagHalfAssignment(tag);
      }
      this.token(tag, value);
      return true;
    };
    // Token Manipulators
    // ------------------
    // As we consume a new `IDENTIFIER`, look at the previous token to determine
    // if it's a special kind of accessor. Return `true` if any type of accessor
    // is the previous token.
    Lexer.prototype.tagAccessor = function() {
      var accessor, prev;
      if ((!(prev = this.prev())) || (prev && prev.spaced)) {
        return false;
      }
      accessor = (function() {
        if (prev[1] === '::') {
          return this.tag(1, 'PROTOTYPE_ACCESS');
        } else if (prev[1] === '.' && !(this.value(2) === '.')) {
          if (this.tag(2) === '?') {
            this.tag(1, 'SOAK_ACCESS');
            return this.tokens.splice(-2, 1);
          } else {
            return this.tag(1, 'PROPERTY_ACCESS');
          }
        } else {
          return prev[0] === '@';
        }
      }).call(this);
      if (accessor) {
        return 'accessor';
      } else {
        return false;
      }
    };
    // Sanitize a heredoc or herecomment by escaping internal double quotes and
    // erasing all external indentation on the left-hand side.
    Lexer.prototype.sanitizeHeredoc = function(doc, options) {
      var _d, attempt, indent, match;
      while (match = HEREDOC_INDENT.exec(doc)) {
        attempt = (typeof (_d = match[2]) !== "undefined" && _d !== null) ? match[2] : match[3];
        if (!indent || attempt.length < indent.length) {
          indent = attempt;
        }
      }
      doc = doc.replace(new RegExp("^" + indent, 'gm'), '');
      if (options.herecomment) {
        return doc;
      }
      return doc.replace(MULTILINER, "\\n").replace(new RegExp(options.quote, 'g'), ("\\" + options.quote));
    };
    // Tag a half assignment.
    Lexer.prototype.tagHalfAssignment = function(tag) {
      var last;
      last = this.tokens.pop();
      this.tokens.push([("" + tag + "="), ("" + tag + "="), last[2]]);
      return true;
    };
    // A source of ambiguity in our grammar used to be parameter lists in function
    // definitions versus argument lists in function calls. Walk backwards, tagging
    // parameters specially in order to make things easier for the parser.
    Lexer.prototype.tagParameters = function() {
      var _d, i, tok;
      if (this.tag() !== ')') {
        return null;
      }
      i = 0;
      while (true) {
        i += 1;
        tok = this.prev(i);
        if (!tok) {
          return null;
        }
        if ((_d = tok[0]) === 'IDENTIFIER') {
          tok[0] = 'PARAM';
        } else if (_d === ')') {
          tok[0] = 'PARAM_END';
        } else if (_d === '(' || _d === 'CALL_START') {
          tok[0] = 'PARAM_START';
          return tok[0];
        }
      }
      return true;
    };
    // Close up all remaining open blocks at the end of the file.
    Lexer.prototype.closeIndentation = function() {
      return this.outdentToken(this.indent);
    };
    // The error for when you try to use a forbidden word in JavaScript as
    // an identifier.
    Lexer.prototype.identifierError = function(word) {
      throw new Error(("SyntaxError: Reserved word \"" + word + "\" on line " + (this.line + 1)));
    };
    // The error for when you try to assign to a reserved word in JavaScript,
    // like "function" or "default".
    Lexer.prototype.assignmentError = function() {
      throw new Error(("SyntaxError: Reserved word \"" + (this.value()) + "\" on line " + (this.line + 1) + " can't be assigned"));
    };
    // Expand variables and expressions inside double-quoted strings using
    // [ECMA Harmony's interpolation syntax](http://wiki.ecmascript.org/doku.php?id=strawman:string_interpolation)
    // for substitution of bare variables as well as arbitrary expressions.
    //     "Hello $name."
    //     "Hello ${name.capitalize()}."
    // If it encounters an interpolation, this method will recursively create a
    // new Lexer, tokenize the interpolated contents, and merge them into the
    // token stream.
    Lexer.prototype.interpolateString = function(str, escapeQuotes) {
      var _d, _e, _f, _g, _h, _i, _j, escaped, expr, group, i, idx, inner, interp, interpolated, lexer, match, nested, pi, quote, tag, tok, token, tokens, value;
      if (str.length < 3 || !starts(str, '"')) {
        return this.token('STRING', str);
      } else {
        lexer = new Lexer();
        tokens = [];
        quote = str.substring(0, 1);
        _d = [1, 1];
        i = _d[0];
        pi = _d[1];
        while (i < str.length - 1) {
          if (starts(str, '\\', i)) {
            i += 1;
          } else if ((match = str.substring(i).match(INTERPOLATION))) {
            _e = match;
            group = _e[0];
            interp = _e[1];
            if (starts(interp, '@')) {
              interp = ("this." + (interp.substring(1)));
            }
            if (pi < i) {
              tokens.push(['STRING', ("" + quote + (str.substring(pi, i)) + quote)]);
            }
            tokens.push(['IDENTIFIER', interp]);
            i += group.length - 1;
            pi = i + 1;
          } else if ((expr = balancedString(str.substring(i), [['${', '}']]))) {
            if (pi < i) {
              tokens.push(['STRING', ("" + quote + (str.substring(pi, i)) + quote)]);
            }
            inner = expr.substring(2, expr.length - 1);
            if (inner.length) {
              nested = lexer.tokenize(("(" + inner + ")"), {
                line: this.line
              });
              _f = nested;
              for (idx = 0, _g = _f.length; idx < _g; idx++) {
                tok = _f[idx];
                tok[0] === 'CALL_END' ? (tok[0] = ')') : null;
              }
              nested.pop();
              tokens.push(['TOKENS', nested]);
            } else {
              tokens.push(['STRING', ("" + quote + quote)]);
            }
            i += expr.length - 1;
            pi = i + 1;
          }
          i += 1;
        }
        if (pi < i && pi < str.length - 1) {
          tokens.push(['STRING', ("" + quote + (str.substring(pi, i)) + quote)]);
        }
        if (!(tokens[0][0] === 'STRING')) {
          tokens.unshift(['STRING', '""']);
        }
        interpolated = tokens.length > 1;
        if (interpolated) {
          this.token('(', '(');
        }
        _h = tokens;
        for (i = 0, _i = _h.length; i < _i; i++) {
          token = _h[i];
          _j = token;
          tag = _j[0];
          value = _j[1];
          if (tag === 'TOKENS') {
            this.tokens = this.tokens.concat(value);
          } else if (tag === 'STRING' && escapeQuotes) {
            escaped = value.substring(1, value.length - 1).replace(/"/g, '\\"');
            this.token(tag, ("\"" + escaped + "\""));
          } else {
            this.token(tag, value);
          }
          if (i < tokens.length - 1) {
            this.token('+', '+');
          }
        }
        if (interpolated) {
          this.token(')', ')');
        }
        return tokens;
      }
    };
    // Helpers
    // -------
    // Add a token to the results, taking note of the line number.
    Lexer.prototype.token = function(tag, value) {
      return this.tokens.push([tag, value, this.line]);
    };
    // Peek at a tag in the current token stream.
    Lexer.prototype.tag = function(index, newTag) {
      var tok;
      if (!(tok = this.prev(index))) {
        return null;
      }
      if ((typeof newTag !== "undefined" && newTag !== null)) {
        tok[0] = newTag;
        return tok[0];
      }
      return tok[0];
    };
    // Peek at a value in the current token stream.
    Lexer.prototype.value = function(index, val) {
      var tok;
      if (!(tok = this.prev(index))) {
        return null;
      }
      if ((typeof val !== "undefined" && val !== null)) {
        tok[1] = val;
        return tok[1];
      }
      return tok[1];
    };
    // Peek at a previous token, entire.
    Lexer.prototype.prev = function(index) {
      return this.tokens[this.tokens.length - (index || 1)];
    };
    // Attempt to match a string against the current chunk, returning the indexed
    // match if successful, and `false` otherwise.
    Lexer.prototype.match = function(regex, index) {
      var m;
      if (!(m = this.chunk.match(regex))) {
        return false;
      }
      if (m) {
        return m[index];
      } else {
        return false;
      }
    };
    // Are we in the midst of an unfinished expression?
    Lexer.prototype.unfinished = function() {
      var prev;
      prev = this.prev(2);
      return this.value() && this.value().match && this.value().match(NO_NEWLINE) && prev && (prev[0] !== '.') && !this.value().match(CODE);
    };
    return Lexer;
  })();
  // Constants
  // ---------
  // Keywords that CoffeeScript shares in common with JavaScript.
  JS_KEYWORDS = ["if", "else", "true", "false", "new", "return", "try", "catch", "finally", "throw", "break", "continue", "for", "in", "while", "delete", "instanceof", "typeof", "switch", "super", "extends", "class", "this", "null"];
  // CoffeeScript-only keywords, which we're more relaxed about allowing. They can't
  // be used standalone, but you can reference them as an attached property.
  COFFEE_ALIASES = ["and", "or", "is", "isnt", "not"];
  COFFEE_KEYWORDS = COFFEE_ALIASES.concat(["then", "unless", "until", "loop", "yes", "no", "on", "off", "of", "by", "where", "when"]);
  // The list of keywords that are reserved by JavaScript, but not used, or are
  // used by CoffeeScript internally. We throw an error when these are encountered,
  // to avoid having a JavaScript error at runtime.
  RESERVED = ["case", "default", "do", "function", "var", "void", "with", "const", "let", "enum", "export", "import", "native"];
  // The superset of both JavaScript keywords and reserved words, none of which may
  // be used as identifiers or properties.
  JS_FORBIDDEN = JS_KEYWORDS.concat(RESERVED);
  // Token matching regexes.
  IDENTIFIER = /^([a-zA-Z\$_](\w|\$)*)/;
  NUMBER = /^(((\b0(x|X)[0-9a-fA-F]+)|((\b[0-9]+(\.[0-9]+)?|\.[0-9]+)(e[+\-]?[0-9]+)?)))\b/i;
  HEREDOC = /^("{6}|'{6}|"{3}\n?([\s\S]*?)\n?([ \t]*)"{3}|'{3}\n?([\s\S]*?)\n?([ \t]*)'{3})/;
  INTERPOLATION = /^\$([a-zA-Z_@]\w*(\.\w+)*)/;
  OPERATOR = /^([+\*&|\/\-%=<>:!?]+)([ \t]*)/;
  WHITESPACE = /^([ \t]+)/;
  COMMENT = /^((\n?[ \t]*)?#{3}(?!#)[ \t]*\n+([\s\S]*?)[ \t]*\n+[ \t]*#{3}|((\n?[ \t]*)?#[^\n]*)+)/;
  CODE = /^((-|=)>)/;
  MULTI_DENT = /^((\n([ \t]*))+)(\.)?/;
  LAST_DENTS = /\n([ \t]*)/g;
  LAST_DENT = /\n([ \t]*)/;
  ASSIGNMENT = /^[:=]$/;
  // Regex-matching-regexes.
  REGEX_START = /^\/[^\/ ]/;
  REGEX_INTERPOLATION = /([^\\]\$[a-zA-Z_@]|[^\\]\$\{.*[^\\]\})/;
  REGEX_END = /^(([imgy]{1,4})\b|\W|$)/;
  REGEX_ESCAPE = /\\[^\$]/g;
  // Token cleaning regexes.
  JS_CLEANER = /(^`|`$)/g;
  MULTILINER = /\n/g;
  STRING_NEWLINES = /\n[ \t]*/g;
  COMMENT_CLEANER = /(^[ \t]*#|\n[ \t]*$)/mg;
  NO_NEWLINE = /^([+\*&|\/\-%=<>:!.\\][<>=&|]*|and|or|is|isnt|not|delete|typeof|instanceof)$/;
  HEREDOC_INDENT = /(\n+([ \t]*)|^([ \t]+))/g;
  ASSIGNED = /^([a-zA-Z\$_]\w*[ \t]*?[:=])/;
  NEXT_CHARACTER = /^\s*(\S)/;
  // Tokens which a regular expression will never immediately follow, but which
  // a division operator might.
  // See: http://www.mozilla.org/js/language/js20-2002-04/rationale/syntax.html#regular-expressions
  // Our list is shorter, due to sans-parentheses method calls.
  NOT_REGEX = ['NUMBER', 'REGEX', '++', '--', 'FALSE', 'NULL', 'TRUE', ']'];
  // Tokens which could legitimately be invoked or indexed. A opening
  // parentheses or bracket following these tokens will be recorded as the start
  // of a function invocation or indexing operation.
  CALLABLE = ['IDENTIFIER', 'SUPER', ')', ']', '}', 'STRING', '@', 'THIS', '?', '::'];
  // Tokens that, when immediately preceding a `WHEN`, indicate that the `WHEN`
  // occurs at the start of a line. We disambiguate these from trailing whens to
  // avoid an ambiguity in the grammar.
  LINE_BREAK = ['INDENT', 'OUTDENT', 'TERMINATOR'];
  // Half-assignments...
  HALF_ASSIGNMENTS = ['-', '+', '/', '*', '%', '||', '&&', '?'];
  // Conversions from CoffeeScript operators into JavaScript ones.
  CONVERSIONS = {
    'and': '&&',
    'or': '||',
    'is': '==',
    'isnt': '!=',
    'not': '!'
  };
})();
/* Jison generated parser */
var parser = (function(){
var parser = {trace: function trace() { },
yy: {},
symbols_: {"error":2,"Root":3,"TERMINATOR":4,"Body":5,"Block":6,"Line":7,"Expression":8,"Statement":9,"Return":10,"Throw":11,"BREAK":12,"CONTINUE":13,"Value":14,"Call":15,"Code":16,"Operation":17,"Assign":18,"If":19,"Try":20,"While":21,"For":22,"Switch":23,"Extends":24,"Class":25,"Splat":26,"Existence":27,"Comment":28,"INDENT":29,"OUTDENT":30,"Identifier":31,"IDENTIFIER":32,"AlphaNumeric":33,"NUMBER":34,"STRING":35,"Literal":36,"JS":37,"REGEX":38,"TRUE":39,"FALSE":40,"YES":41,"NO":42,"ON":43,"OFF":44,"Assignable":45,"ASSIGN":46,"AssignObj":47,"RETURN":48,"COMMENT":49,"HERECOMMENT":50,"?":51,"PARAM_START":52,"ParamList":53,"PARAM_END":54,"FuncGlyph":55,"->":56,"=>":57,"OptComma":58,",":59,"Param":60,"PARAM":61,".":62,"SimpleAssignable":63,"Accessor":64,"Invocation":65,"ThisProperty":66,"Array":67,"Object":68,"Parenthetical":69,"Range":70,"This":71,"NULL":72,"PROPERTY_ACCESS":73,"PROTOTYPE_ACCESS":74,"::":75,"SOAK_ACCESS":76,"Index":77,"Slice":78,"INDEX_START":79,"INDEX_END":80,"INDEX_SOAK":81,"INDEX_PROTO":82,"{":83,"AssignList":84,"}":85,"CLASS":86,"EXTENDS":87,"ClassBody":88,"ClassAssign":89,"NEW":90,"Super":91,"Arguments":92,"CALL_START":93,"ArgList":94,"CALL_END":95,"SUPER":96,"THIS":97,"@":98,"[":99,"]":100,"SimpleArgs":101,"TRY":102,"Catch":103,"FINALLY":104,"CATCH":105,"THROW":106,"(":107,")":108,"WhileSource":109,"WHILE":110,"WHEN":111,"UNTIL":112,"Loop":113,"LOOP":114,"FOR":115,"ForVariables":116,"ForSource":117,"ForValue":118,"IN":119,"OF":120,"BY":121,"SWITCH":122,"Whens":123,"ELSE":124,"When":125,"LEADING_WHEN":126,"IfStart":127,"IF":128,"UNLESS":129,"IfBlock":130,"!":131,"!!":132,"-":133,"+":134,"~":135,"--":136,"++":137,"DELETE":138,"TYPEOF":139,"*":140,"/":141,"%":142,"<<":143,">>":144,">>>":145,"&":146,"|":147,"^":148,"<=":149,"<":150,">":151,">=":152,"==":153,"!=":154,"&&":155,"||":156,"-=":157,"+=":158,"/=":159,"*=":160,"%=":161,"||=":162,"&&=":163,"?=":164,"INSTANCEOF":165,"$accept":0,"$end":1},
terminals_: {"2":"error","4":"TERMINATOR","12":"BREAK","13":"CONTINUE","29":"INDENT","30":"OUTDENT","32":"IDENTIFIER","34":"NUMBER","35":"STRING","37":"JS","38":"REGEX","39":"TRUE","40":"FALSE","41":"YES","42":"NO","43":"ON","44":"OFF","46":"ASSIGN","48":"RETURN","49":"COMMENT","50":"HERECOMMENT","51":"?","52":"PARAM_START","54":"PARAM_END","56":"->","57":"=>","59":",","61":"PARAM","62":".","72":"NULL","73":"PROPERTY_ACCESS","74":"PROTOTYPE_ACCESS","75":"::","76":"SOAK_ACCESS","79":"INDEX_START","80":"INDEX_END","81":"INDEX_SOAK","82":"INDEX_PROTO","83":"{","85":"}","86":"CLASS","87":"EXTENDS","90":"NEW","93":"CALL_START","95":"CALL_END","96":"SUPER","97":"THIS","98":"@","99":"[","100":"]","102":"TRY","104":"FINALLY","105":"CATCH","106":"THROW","107":"(","108":")","110":"WHILE","111":"WHEN","112":"UNTIL","114":"LOOP","115":"FOR","119":"IN","120":"OF","121":"BY","122":"SWITCH","124":"ELSE","126":"LEADING_WHEN","128":"IF","129":"UNLESS","131":"!","132":"!!","133":"-","134":"+","135":"~","136":"--","137":"++","138":"DELETE","139":"TYPEOF","140":"*","141":"/","142":"%","143":"<<","144":">>","145":">>>","146":"&","147":"|","148":"^","149":"<=","150":"<","151":">","152":">=","153":"==","154":"!=","155":"&&","156":"||","157":"-=","158":"+=","159":"/=","160":"*=","161":"%=","162":"||=","163":"&&=","164":"?=","165":"INSTANCEOF"},
productions_: [0,[3,0],[3,1],[3,1],[3,2],[5,1],[5,3],[5,2],[7,1],[7,1],[9,1],[9,1],[9,1],[9,1],[8,1],[8,1],[8,1],[8,1],[8,1],[8,1],[8,1],[8,1],[8,1],[8,1],[8,1],[8,1],[8,1],[8,1],[8,1],[6,3],[6,2],[6,2],[31,1],[33,1],[33,1],[36,1],[36,1],[36,1],[36,1],[36,1],[36,1],[36,1],[36,1],[36,1],[18,3],[47,1],[47,1],[47,3],[47,3],[47,1],[10,2],[10,1],[28,1],[28,1],[27,2],[16,5],[16,2],[55,1],[55,1],[58,0],[58,1],[53,0],[53,1],[53,3],[60,1],[60,4],[26,4],[63,1],[63,2],[63,2],[63,1],[45,1],[45,1],[45,1],[14,1],[14,1],[14,1],[14,1],[14,1],[14,1],[64,2],[64,2],[64,1],[64,2],[64,1],[64,1],[77,3],[77,2],[77,2],[68,4],[84,0],[84,1],[84,3],[84,4],[84,6],[25,2],[25,4],[25,5],[25,7],[89,1],[89,3],[88,0],[88,1],[88,3],[15,1],[15,2],[15,1],[24,3],[65,2],[65,2],[92,4],[91,5],[71,1],[71,1],[66,2],[70,6],[70,7],[78,6],[78,7],[67,4],[94,0],[94,1],[94,3],[94,4],[94,6],[101,1],[101,3],[20,3],[20,4],[20,5],[103,3],[11,2],[69,3],[109,2],[109,4],[109,2],[109,4],[21,2],[21,2],[21,2],[21,1],[113,2],[113,2],[22,4],[22,4],[22,4],[118,1],[118,1],[118,1],[116,1],[116,3],[117,2],[117,2],[117,4],[117,4],[117,4],[117,6],[117,6],[23,5],[23,7],[23,4],[23,6],[123,1],[123,2],[125,3],[125,4],[125,3],[127,3],[127,3],[127,5],[130,1],[130,3],[19,1],[19,3],[19,3],[19,3],[19,3],[17,2],[17,2],[17,2],[17,2],[17,2],[17,2],[17,2],[17,2],[17,2],[17,2],[17,2],[17,3],[17,3],[17,3],[17,3],[17,3],[17,3],[17,3],[17,3],[17,3],[17,3],[17,3],[17,3],[17,3],[17,3],[17,3],[17,3],[17,3],[17,3],[17,3],[17,3],[17,3],[17,3],[17,3],[17,3],[17,3],[17,3],[17,3],[17,3],[17,3],[17,3],[17,3],[17,4],[17,4]],
performAction: function anonymous(yytext,yyleng,yylineno,yy) {

var $$ = arguments[5],$0=arguments[5].length;
switch(arguments[4]) {
case 1:return this.$ = new Expressions();
break;
case 2:return this.$ = new Expressions();
break;
case 3:return this.$ = $$[$0-1+1-1];
break;
case 4:return this.$ = $$[$0-2+1-1];
break;
case 5:this.$ = Expressions.wrap([$$[$0-1+1-1]]);
break;
case 6:this.$ = $$[$0-3+1-1].push($$[$0-3+3-1]);
break;
case 7:this.$ = $$[$0-2+1-1];
break;
case 8:this.$ = $$[$0-1+1-1];
break;
case 9:this.$ = $$[$0-1+1-1];
break;
case 10:this.$ = $$[$0-1+1-1];
break;
case 11:this.$ = $$[$0-1+1-1];
break;
case 12:this.$ = new LiteralNode($$[$0-1+1-1]);
break;
case 13:this.$ = new LiteralNode($$[$0-1+1-1]);
break;
case 14:this.$ = $$[$0-1+1-1];
break;
case 15:this.$ = $$[$0-1+1-1];
break;
case 16:this.$ = $$[$0-1+1-1];
break;
case 17:this.$ = $$[$0-1+1-1];
break;
case 18:this.$ = $$[$0-1+1-1];
break;
case 19:this.$ = $$[$0-1+1-1];
break;
case 20:this.$ = $$[$0-1+1-1];
break;
case 21:this.$ = $$[$0-1+1-1];
break;
case 22:this.$ = $$[$0-1+1-1];
break;
case 23:this.$ = $$[$0-1+1-1];
break;
case 24:this.$ = $$[$0-1+1-1];
break;
case 25:this.$ = $$[$0-1+1-1];
break;
case 26:this.$ = $$[$0-1+1-1];
break;
case 27:this.$ = $$[$0-1+1-1];
break;
case 28:this.$ = $$[$0-1+1-1];
break;
case 29:this.$ = $$[$0-3+2-1];
break;
case 30:this.$ = new Expressions();
break;
case 31:this.$ = Expressions.wrap([$$[$0-2+2-1]]);
break;
case 32:this.$ = new LiteralNode($$[$0-1+1-1]);
break;
case 33:this.$ = new LiteralNode($$[$0-1+1-1]);
break;
case 34:this.$ = new LiteralNode($$[$0-1+1-1]);
break;
case 35:this.$ = $$[$0-1+1-1];
break;
case 36:this.$ = new LiteralNode($$[$0-1+1-1]);
break;
case 37:this.$ = new LiteralNode($$[$0-1+1-1]);
break;
case 38:this.$ = new LiteralNode(true);
break;
case 39:this.$ = new LiteralNode(false);
break;
case 40:this.$ = new LiteralNode(true);
break;
case 41:this.$ = new LiteralNode(false);
break;
case 42:this.$ = new LiteralNode(true);
break;
case 43:this.$ = new LiteralNode(false);
break;
case 44:this.$ = new AssignNode($$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 45:this.$ = new ValueNode($$[$0-1+1-1]);
break;
case 46:this.$ = $$[$0-1+1-1];
break;
case 47:this.$ = new AssignNode(new ValueNode($$[$0-3+1-1]), $$[$0-3+3-1], 'object');
break;
case 48:this.$ = new AssignNode(new ValueNode($$[$0-3+1-1]), $$[$0-3+3-1], 'object');
break;
case 49:this.$ = $$[$0-1+1-1];
break;
case 50:this.$ = new ReturnNode($$[$0-2+2-1]);
break;
case 51:this.$ = new ReturnNode(new ValueNode(new LiteralNode('null')));
break;
case 52:this.$ = new CommentNode($$[$0-1+1-1]);
break;
case 53:this.$ = new CommentNode($$[$0-1+1-1], 'herecomment');
break;
case 54:this.$ = new ExistenceNode($$[$0-2+1-1]);
break;
case 55:this.$ = new CodeNode($$[$0-5+2-1], $$[$0-5+5-1], $$[$0-5+4-1]);
break;
case 56:this.$ = new CodeNode([], $$[$0-2+2-1], $$[$0-2+1-1]);
break;
case 57:this.$ = 'func';
break;
case 58:this.$ = 'boundfunc';
break;
case 59:this.$ = $$[$0-1+1-1];
break;
case 60:this.$ = $$[$0-1+1-1];
break;
case 61:this.$ = [];
break;
case 62:this.$ = [$$[$0-1+1-1]];
break;
case 63:this.$ = $$[$0-3+1-1].concat([$$[$0-3+3-1]]);
break;
case 64:this.$ = new LiteralNode($$[$0-1+1-1]);
break;
case 65:this.$ = new SplatNode($$[$0-4+1-1]);
break;
case 66:this.$ = new SplatNode($$[$0-4+1-1]);
break;
case 67:this.$ = new ValueNode($$[$0-1+1-1]);
break;
case 68:this.$ = $$[$0-2+1-1].push($$[$0-2+2-1]);
break;
case 69:this.$ = new ValueNode($$[$0-2+1-1], [$$[$0-2+2-1]]);
break;
case 70:this.$ = $$[$0-1+1-1];
break;
case 71:this.$ = $$[$0-1+1-1];
break;
case 72:this.$ = new ValueNode($$[$0-1+1-1]);
break;
case 73:this.$ = new ValueNode($$[$0-1+1-1]);
break;
case 74:this.$ = $$[$0-1+1-1];
break;
case 75:this.$ = new ValueNode($$[$0-1+1-1]);
break;
case 76:this.$ = new ValueNode($$[$0-1+1-1]);
break;
case 77:this.$ = new ValueNode($$[$0-1+1-1]);
break;
case 78:this.$ = $$[$0-1+1-1];
break;
case 79:this.$ = new ValueNode(new LiteralNode('null'));
break;
case 80:this.$ = new AccessorNode($$[$0-2+2-1]);
break;
case 81:this.$ = new AccessorNode($$[$0-2+2-1], 'prototype');
break;
case 82:this.$ = new AccessorNode(new LiteralNode('prototype'));
break;
case 83:this.$ = new AccessorNode($$[$0-2+2-1], 'soak');
break;
case 84:this.$ = $$[$0-1+1-1];
break;
case 85:this.$ = new SliceNode($$[$0-1+1-1]);
break;
case 86:this.$ = new IndexNode($$[$0-3+2-1]);
break;
case 87:this.$ = (function () {
        $$[$0-2+2-1].soakNode = true;
        return $$[$0-2+2-1];
      }());
break;
case 88:this.$ = (function () {
        $$[$0-2+2-1].proto = true;
        return $$[$0-2+2-1];
      }());
break;
case 89:this.$ = new ObjectNode($$[$0-4+2-1]);
break;
case 90:this.$ = [];
break;
case 91:this.$ = [$$[$0-1+1-1]];
break;
case 92:this.$ = $$[$0-3+1-1].concat([$$[$0-3+3-1]]);
break;
case 93:this.$ = $$[$0-4+1-1].concat([$$[$0-4+4-1]]);
break;
case 94:this.$ = $$[$0-6+1-1].concat($$[$0-6+4-1]);
break;
case 95:this.$ = new ClassNode($$[$0-2+2-1]);
break;
case 96:this.$ = new ClassNode($$[$0-4+2-1], $$[$0-4+4-1]);
break;
case 97:this.$ = new ClassNode($$[$0-5+2-1], null, $$[$0-5+4-1]);
break;
case 98:this.$ = new ClassNode($$[$0-7+2-1], $$[$0-7+4-1], $$[$0-7+6-1]);
break;
case 99:this.$ = $$[$0-1+1-1];
break;
case 100:this.$ = new AssignNode(new ValueNode($$[$0-3+1-1]), $$[$0-3+3-1], 'this');
break;
case 101:this.$ = [];
break;
case 102:this.$ = [$$[$0-1+1-1]];
break;
case 103:this.$ = $$[$0-3+1-1].concat($$[$0-3+3-1]);
break;
case 104:this.$ = $$[$0-1+1-1];
break;
case 105:this.$ = $$[$0-2+2-1].newInstance();
break;
case 106:this.$ = $$[$0-1+1-1];
break;
case 107:this.$ = new ExtendsNode($$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 108:this.$ = new CallNode($$[$0-2+1-1], $$[$0-2+2-1]);
break;
case 109:this.$ = new CallNode($$[$0-2+1-1], $$[$0-2+2-1]);
break;
case 110:this.$ = $$[$0-4+2-1];
break;
case 111:this.$ = new CallNode('super', $$[$0-5+3-1]);
break;
case 112:this.$ = new ValueNode(new LiteralNode('this'));
break;
case 113:this.$ = new ValueNode(new LiteralNode('this'));
break;
case 114:this.$ = new ValueNode(new LiteralNode('this'), [new AccessorNode($$[$0-2+2-1])]);
break;
case 115:this.$ = new RangeNode($$[$0-6+2-1], $$[$0-6+5-1]);
break;
case 116:this.$ = new RangeNode($$[$0-7+2-1], $$[$0-7+6-1], true);
break;
case 117:this.$ = new RangeNode($$[$0-6+2-1], $$[$0-6+5-1]);
break;
case 118:this.$ = new RangeNode($$[$0-7+2-1], $$[$0-7+6-1], true);
break;
case 119:this.$ = new ArrayNode($$[$0-4+2-1]);
break;
case 120:this.$ = [];
break;
case 121:this.$ = [$$[$0-1+1-1]];
break;
case 122:this.$ = $$[$0-3+1-1].concat([$$[$0-3+3-1]]);
break;
case 123:this.$ = $$[$0-4+1-1].concat([$$[$0-4+4-1]]);
break;
case 124:this.$ = $$[$0-6+1-1].concat($$[$0-6+4-1]);
break;
case 125:this.$ = $$[$0-1+1-1];
break;
case 126:this.$ = (function () {
        if ($$[$0-3+1-1] instanceof Array) {
          return $$[$0-3+1-1].concat([$$[$0-3+3-1]]);
        } else {
          return [$$[$0-3+1-1]].concat([$$[$0-3+3-1]]);
        }
      }());
break;
case 127:this.$ = new TryNode($$[$0-3+2-1], $$[$0-3+3-1][0], $$[$0-3+3-1][1]);
break;
case 128:this.$ = new TryNode($$[$0-4+2-1], null, null, $$[$0-4+4-1]);
break;
case 129:this.$ = new TryNode($$[$0-5+2-1], $$[$0-5+3-1][0], $$[$0-5+3-1][1], $$[$0-5+5-1]);
break;
case 130:this.$ = [$$[$0-3+2-1], $$[$0-3+3-1]];
break;
case 131:this.$ = new ThrowNode($$[$0-2+2-1]);
break;
case 132:this.$ = new ParentheticalNode($$[$0-3+2-1]);
break;
case 133:this.$ = new WhileNode($$[$0-2+2-1]);
break;
case 134:this.$ = new WhileNode($$[$0-4+2-1], {
          guard: $$[$0-4+4-1]
        });
break;
case 135:this.$ = new WhileNode($$[$0-2+2-1], {
          invert: true
        });
break;
case 136:this.$ = new WhileNode($$[$0-4+2-1], {
          invert: true,
          guard: $$[$0-4+4-1]
        });
break;
case 137:this.$ = $$[$0-2+1-1].addBody($$[$0-2+2-1]);
break;
case 138:this.$ = $$[$0-2+2-1].addBody(Expressions.wrap([$$[$0-2+1-1]]));
break;
case 139:this.$ = $$[$0-2+2-1].addBody(Expressions.wrap([$$[$0-2+1-1]]));
break;
case 140:this.$ = $$[$0-1+1-1];
break;
case 141:this.$ = new WhileNode(new LiteralNode('true')).addBody($$[$0-2+2-1]);
break;
case 142:this.$ = new WhileNode(new LiteralNode('true')).addBody(Expressions.wrap([$$[$0-2+2-1]]));
break;
case 143:this.$ = new ForNode($$[$0-4+1-1], $$[$0-4+4-1], $$[$0-4+3-1][0], $$[$0-4+3-1][1]);
break;
case 144:this.$ = new ForNode($$[$0-4+1-1], $$[$0-4+4-1], $$[$0-4+3-1][0], $$[$0-4+3-1][1]);
break;
case 145:this.$ = new ForNode($$[$0-4+4-1], $$[$0-4+3-1], $$[$0-4+2-1][0], $$[$0-4+2-1][1]);
break;
case 146:this.$ = $$[$0-1+1-1];
break;
case 147:this.$ = new ValueNode($$[$0-1+1-1]);
break;
case 148:this.$ = new ValueNode($$[$0-1+1-1]);
break;
case 149:this.$ = [$$[$0-1+1-1]];
break;
case 150:this.$ = [$$[$0-3+1-1], $$[$0-3+3-1]];
break;
case 151:this.$ = {
          source: $$[$0-2+2-1]
        };
break;
case 152:this.$ = {
          source: $$[$0-2+2-1],
          object: true
        };
break;
case 153:this.$ = {
          source: $$[$0-4+2-1],
          guard: $$[$0-4+4-1]
        };
break;
case 154:this.$ = {
          source: $$[$0-4+2-1],
          guard: $$[$0-4+4-1],
          object: true
        };
break;
case 155:this.$ = {
          source: $$[$0-4+2-1],
          step: $$[$0-4+4-1]
        };
break;
case 156:this.$ = {
          source: $$[$0-6+2-1],
          guard: $$[$0-6+4-1],
          step: $$[$0-6+6-1]
        };
break;
case 157:this.$ = {
          source: $$[$0-6+2-1],
          step: $$[$0-6+4-1],
          guard: $$[$0-6+6-1]
        };
break;
case 158:this.$ = $$[$0-5+4-1].switchesOver($$[$0-5+2-1]);
break;
case 159:this.$ = $$[$0-7+4-1].switchesOver($$[$0-7+2-1]).addElse($$[$0-7+6-1], true);
break;
case 160:this.$ = $$[$0-4+3-1];
break;
case 161:this.$ = $$[$0-6+3-1].addElse($$[$0-6+5-1], true);
break;
case 162:this.$ = $$[$0-1+1-1];
break;
case 163:this.$ = $$[$0-2+1-1].addElse($$[$0-2+2-1]);
break;
case 164:this.$ = new IfNode($$[$0-3+2-1], $$[$0-3+3-1], {
          statement: true
        });
break;
case 165:this.$ = new IfNode($$[$0-4+2-1], $$[$0-4+3-1], {
          statement: true
        });
break;
case 166:this.$ = (function () {
        $$[$0-3+3-1].comment = $$[$0-3+1-1];
        return $$[$0-3+3-1];
      }());
break;
case 167:this.$ = new IfNode($$[$0-3+2-1], $$[$0-3+3-1]);
break;
case 168:this.$ = new IfNode($$[$0-3+2-1], $$[$0-3+3-1], {
          invert: true
        });
break;
case 169:this.$ = $$[$0-5+1-1].addElse((new IfNode($$[$0-5+4-1], $$[$0-5+5-1])).forceStatement());
break;
case 170:this.$ = $$[$0-1+1-1];
break;
case 171:this.$ = $$[$0-3+1-1].addElse($$[$0-3+3-1]);
break;
case 172:this.$ = $$[$0-1+1-1];
break;
case 173:this.$ = new IfNode($$[$0-3+3-1], Expressions.wrap([$$[$0-3+1-1]]), {
          statement: true
        });
break;
case 174:this.$ = new IfNode($$[$0-3+3-1], Expressions.wrap([$$[$0-3+1-1]]), {
          statement: true
        });
break;
case 175:this.$ = new IfNode($$[$0-3+3-1], Expressions.wrap([$$[$0-3+1-1]]), {
          statement: true,
          invert: true
        });
break;
case 176:this.$ = new IfNode($$[$0-3+3-1], Expressions.wrap([$$[$0-3+1-1]]), {
          statement: true,
          invert: true
        });
break;
case 177:this.$ = new OpNode('!', $$[$0-2+2-1]);
break;
case 178:this.$ = new OpNode('!!', $$[$0-2+2-1]);
break;
case 179:this.$ = new OpNode('-', $$[$0-2+2-1]);
break;
case 180:this.$ = new OpNode('+', $$[$0-2+2-1]);
break;
case 181:this.$ = new OpNode('~', $$[$0-2+2-1]);
break;
case 182:this.$ = new OpNode('--', $$[$0-2+2-1]);
break;
case 183:this.$ = new OpNode('++', $$[$0-2+2-1]);
break;
case 184:this.$ = new OpNode('delete', $$[$0-2+2-1]);
break;
case 185:this.$ = new OpNode('typeof', $$[$0-2+2-1]);
break;
case 186:this.$ = new OpNode('--', $$[$0-2+1-1], null, true);
break;
case 187:this.$ = new OpNode('++', $$[$0-2+1-1], null, true);
break;
case 188:this.$ = new OpNode('*', $$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 189:this.$ = new OpNode('/', $$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 190:this.$ = new OpNode('%', $$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 191:this.$ = new OpNode('+', $$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 192:this.$ = new OpNode('-', $$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 193:this.$ = new OpNode('<<', $$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 194:this.$ = new OpNode('>>', $$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 195:this.$ = new OpNode('>>>', $$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 196:this.$ = new OpNode('&', $$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 197:this.$ = new OpNode('|', $$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 198:this.$ = new OpNode('^', $$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 199:this.$ = new OpNode('<=', $$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 200:this.$ = new OpNode('<', $$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 201:this.$ = new OpNode('>', $$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 202:this.$ = new OpNode('>=', $$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 203:this.$ = new OpNode('==', $$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 204:this.$ = new OpNode('!=', $$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 205:this.$ = new OpNode('&&', $$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 206:this.$ = new OpNode('||', $$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 207:this.$ = new OpNode('?', $$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 208:this.$ = new OpNode('-=', $$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 209:this.$ = new OpNode('+=', $$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 210:this.$ = new OpNode('/=', $$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 211:this.$ = new OpNode('*=', $$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 212:this.$ = new OpNode('%=', $$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 213:this.$ = new OpNode('||=', $$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 214:this.$ = new OpNode('&&=', $$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 215:this.$ = new OpNode('?=', $$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 216:this.$ = new OpNode('instanceof', $$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 217:this.$ = new InNode($$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 218:this.$ = new OpNode('in', $$[$0-3+1-1], $$[$0-3+3-1]);
break;
case 219:this.$ = new OpNode('!', new InNode($$[$0-4+1-1], $$[$0-4+4-1]));
break;
case 220:this.$ = new OpNode('!', new ParentheticalNode(new OpNode('in', $$[$0-4+1-1], $$[$0-4+4-1])));
break;
}
},
table: [{"1":[2,1],"3":1,"4":[1,2],"5":3,"6":4,"7":5,"8":7,"9":8,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"29":[1,6],"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"1":[3]},{"1":[2,2],"28":90,"49":[1,56],"50":[1,57]},{"1":[2,3],"4":[1,91]},{"4":[1,92]},{"1":[2,5],"4":[2,5],"30":[2,5]},{"5":93,"7":5,"8":7,"9":8,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"30":[1,94],"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"1":[2,8],"4":[2,8],"30":[2,8],"51":[1,116],"62":[1,133],"108":[2,8],"109":131,"110":[1,79],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"128":[1,129],"129":[1,130],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"1":[2,9],"4":[2,9],"30":[2,9],"108":[2,9],"109":136,"110":[1,79],"112":[1,80],"115":[1,137],"128":[1,134],"129":[1,135]},{"1":[2,14],"4":[2,14],"29":[2,14],"30":[2,14],"51":[2,14],"59":[2,14],"62":[2,14],"64":139,"73":[1,141],"74":[1,142],"75":[1,143],"76":[1,144],"77":145,"78":146,"79":[1,147],"80":[2,14],"81":[1,148],"82":[1,149],"85":[2,14],"92":138,"93":[1,140],"95":[2,14],"100":[2,14],"108":[2,14],"110":[2,14],"111":[2,14],"112":[2,14],"115":[2,14],"119":[2,14],"120":[2,14],"121":[2,14],"128":[2,14],"129":[2,14],"131":[2,14],"133":[2,14],"134":[2,14],"136":[2,14],"137":[2,14],"140":[2,14],"141":[2,14],"142":[2,14],"143":[2,14],"144":[2,14],"145":[2,14],"146":[2,14],"147":[2,14],"148":[2,14],"149":[2,14],"150":[2,14],"151":[2,14],"152":[2,14],"153":[2,14],"154":[2,14],"155":[2,14],"156":[2,14],"157":[2,14],"158":[2,14],"159":[2,14],"160":[2,14],"161":[2,14],"162":[2,14],"163":[2,14],"164":[2,14],"165":[2,14]},{"1":[2,15],"4":[2,15],"29":[2,15],"30":[2,15],"51":[2,15],"59":[2,15],"62":[2,15],"80":[2,15],"85":[2,15],"95":[2,15],"100":[2,15],"108":[2,15],"110":[2,15],"111":[2,15],"112":[2,15],"115":[2,15],"119":[2,15],"120":[2,15],"121":[2,15],"128":[2,15],"129":[2,15],"131":[2,15],"133":[2,15],"134":[2,15],"136":[2,15],"137":[2,15],"140":[2,15],"141":[2,15],"142":[2,15],"143":[2,15],"144":[2,15],"145":[2,15],"146":[2,15],"147":[2,15],"148":[2,15],"149":[2,15],"150":[2,15],"151":[2,15],"152":[2,15],"153":[2,15],"154":[2,15],"155":[2,15],"156":[2,15],"157":[2,15],"158":[2,15],"159":[2,15],"160":[2,15],"161":[2,15],"162":[2,15],"163":[2,15],"164":[2,15],"165":[2,15]},{"1":[2,16],"4":[2,16],"29":[2,16],"30":[2,16],"51":[2,16],"59":[2,16],"62":[2,16],"80":[2,16],"85":[2,16],"95":[2,16],"100":[2,16],"108":[2,16],"110":[2,16],"111":[2,16],"112":[2,16],"115":[2,16],"119":[2,16],"120":[2,16],"121":[2,16],"128":[2,16],"129":[2,16],"131":[2,16],"133":[2,16],"134":[2,16],"136":[2,16],"137":[2,16],"140":[2,16],"141":[2,16],"142":[2,16],"143":[2,16],"144":[2,16],"145":[2,16],"146":[2,16],"147":[2,16],"148":[2,16],"149":[2,16],"150":[2,16],"151":[2,16],"152":[2,16],"153":[2,16],"154":[2,16],"155":[2,16],"156":[2,16],"157":[2,16],"158":[2,16],"159":[2,16],"160":[2,16],"161":[2,16],"162":[2,16],"163":[2,16],"164":[2,16],"165":[2,16]},{"1":[2,17],"4":[2,17],"29":[2,17],"30":[2,17],"51":[2,17],"59":[2,17],"62":[2,17],"80":[2,17],"85":[2,17],"95":[2,17],"100":[2,17],"108":[2,17],"110":[2,17],"111":[2,17],"112":[2,17],"115":[2,17],"119":[2,17],"120":[2,17],"121":[2,17],"128":[2,17],"129":[2,17],"131":[2,17],"133":[2,17],"134":[2,17],"136":[2,17],"137":[2,17],"140":[2,17],"141":[2,17],"142":[2,17],"143":[2,17],"144":[2,17],"145":[2,17],"146":[2,17],"147":[2,17],"148":[2,17],"149":[2,17],"150":[2,17],"151":[2,17],"152":[2,17],"153":[2,17],"154":[2,17],"155":[2,17],"156":[2,17],"157":[2,17],"158":[2,17],"159":[2,17],"160":[2,17],"161":[2,17],"162":[2,17],"163":[2,17],"164":[2,17],"165":[2,17]},{"1":[2,18],"4":[2,18],"29":[2,18],"30":[2,18],"51":[2,18],"59":[2,18],"62":[2,18],"80":[2,18],"85":[2,18],"95":[2,18],"100":[2,18],"108":[2,18],"110":[2,18],"111":[2,18],"112":[2,18],"115":[2,18],"119":[2,18],"120":[2,18],"121":[2,18],"128":[2,18],"129":[2,18],"131":[2,18],"133":[2,18],"134":[2,18],"136":[2,18],"137":[2,18],"140":[2,18],"141":[2,18],"142":[2,18],"143":[2,18],"144":[2,18],"145":[2,18],"146":[2,18],"147":[2,18],"148":[2,18],"149":[2,18],"150":[2,18],"151":[2,18],"152":[2,18],"153":[2,18],"154":[2,18],"155":[2,18],"156":[2,18],"157":[2,18],"158":[2,18],"159":[2,18],"160":[2,18],"161":[2,18],"162":[2,18],"163":[2,18],"164":[2,18],"165":[2,18]},{"1":[2,19],"4":[2,19],"29":[2,19],"30":[2,19],"51":[2,19],"59":[2,19],"62":[2,19],"80":[2,19],"85":[2,19],"95":[2,19],"100":[2,19],"108":[2,19],"110":[2,19],"111":[2,19],"112":[2,19],"115":[2,19],"119":[2,19],"120":[2,19],"121":[2,19],"128":[2,19],"129":[2,19],"131":[2,19],"133":[2,19],"134":[2,19],"136":[2,19],"137":[2,19],"140":[2,19],"141":[2,19],"142":[2,19],"143":[2,19],"144":[2,19],"145":[2,19],"146":[2,19],"147":[2,19],"148":[2,19],"149":[2,19],"150":[2,19],"151":[2,19],"152":[2,19],"153":[2,19],"154":[2,19],"155":[2,19],"156":[2,19],"157":[2,19],"158":[2,19],"159":[2,19],"160":[2,19],"161":[2,19],"162":[2,19],"163":[2,19],"164":[2,19],"165":[2,19]},{"1":[2,20],"4":[2,20],"29":[2,20],"30":[2,20],"51":[2,20],"59":[2,20],"62":[2,20],"80":[2,20],"85":[2,20],"95":[2,20],"100":[2,20],"108":[2,20],"110":[2,20],"111":[2,20],"112":[2,20],"115":[2,20],"119":[2,20],"120":[2,20],"121":[2,20],"128":[2,20],"129":[2,20],"131":[2,20],"133":[2,20],"134":[2,20],"136":[2,20],"137":[2,20],"140":[2,20],"141":[2,20],"142":[2,20],"143":[2,20],"144":[2,20],"145":[2,20],"146":[2,20],"147":[2,20],"148":[2,20],"149":[2,20],"150":[2,20],"151":[2,20],"152":[2,20],"153":[2,20],"154":[2,20],"155":[2,20],"156":[2,20],"157":[2,20],"158":[2,20],"159":[2,20],"160":[2,20],"161":[2,20],"162":[2,20],"163":[2,20],"164":[2,20],"165":[2,20]},{"1":[2,21],"4":[2,21],"29":[2,21],"30":[2,21],"51":[2,21],"59":[2,21],"62":[2,21],"80":[2,21],"85":[2,21],"95":[2,21],"100":[2,21],"108":[2,21],"110":[2,21],"111":[2,21],"112":[2,21],"115":[2,21],"119":[2,21],"120":[2,21],"121":[2,21],"128":[2,21],"129":[2,21],"131":[2,21],"133":[2,21],"134":[2,21],"136":[2,21],"137":[2,21],"140":[2,21],"141":[2,21],"142":[2,21],"143":[2,21],"144":[2,21],"145":[2,21],"146":[2,21],"147":[2,21],"148":[2,21],"149":[2,21],"150":[2,21],"151":[2,21],"152":[2,21],"153":[2,21],"154":[2,21],"155":[2,21],"156":[2,21],"157":[2,21],"158":[2,21],"159":[2,21],"160":[2,21],"161":[2,21],"162":[2,21],"163":[2,21],"164":[2,21],"165":[2,21]},{"1":[2,22],"4":[2,22],"29":[2,22],"30":[2,22],"51":[2,22],"59":[2,22],"62":[2,22],"80":[2,22],"85":[2,22],"95":[2,22],"100":[2,22],"108":[2,22],"110":[2,22],"111":[2,22],"112":[2,22],"115":[2,22],"119":[2,22],"120":[2,22],"121":[2,22],"128":[2,22],"129":[2,22],"131":[2,22],"133":[2,22],"134":[2,22],"136":[2,22],"137":[2,22],"140":[2,22],"141":[2,22],"142":[2,22],"143":[2,22],"144":[2,22],"145":[2,22],"146":[2,22],"147":[2,22],"148":[2,22],"149":[2,22],"150":[2,22],"151":[2,22],"152":[2,22],"153":[2,22],"154":[2,22],"155":[2,22],"156":[2,22],"157":[2,22],"158":[2,22],"159":[2,22],"160":[2,22],"161":[2,22],"162":[2,22],"163":[2,22],"164":[2,22],"165":[2,22]},{"1":[2,23],"4":[2,23],"29":[2,23],"30":[2,23],"51":[2,23],"59":[2,23],"62":[2,23],"80":[2,23],"85":[2,23],"95":[2,23],"100":[2,23],"108":[2,23],"110":[2,23],"111":[2,23],"112":[2,23],"115":[2,23],"119":[2,23],"120":[2,23],"121":[2,23],"128":[2,23],"129":[2,23],"131":[2,23],"133":[2,23],"134":[2,23],"136":[2,23],"137":[2,23],"140":[2,23],"141":[2,23],"142":[2,23],"143":[2,23],"144":[2,23],"145":[2,23],"146":[2,23],"147":[2,23],"148":[2,23],"149":[2,23],"150":[2,23],"151":[2,23],"152":[2,23],"153":[2,23],"154":[2,23],"155":[2,23],"156":[2,23],"157":[2,23],"158":[2,23],"159":[2,23],"160":[2,23],"161":[2,23],"162":[2,23],"163":[2,23],"164":[2,23],"165":[2,23]},{"1":[2,24],"4":[2,24],"29":[2,24],"30":[2,24],"51":[2,24],"59":[2,24],"62":[2,24],"80":[2,24],"85":[2,24],"95":[2,24],"100":[2,24],"108":[2,24],"110":[2,24],"111":[2,24],"112":[2,24],"115":[2,24],"119":[2,24],"120":[2,24],"121":[2,24],"128":[2,24],"129":[2,24],"131":[2,24],"133":[2,24],"134":[2,24],"136":[2,24],"137":[2,24],"140":[2,24],"141":[2,24],"142":[2,24],"143":[2,24],"144":[2,24],"145":[2,24],"146":[2,24],"147":[2,24],"148":[2,24],"149":[2,24],"150":[2,24],"151":[2,24],"152":[2,24],"153":[2,24],"154":[2,24],"155":[2,24],"156":[2,24],"157":[2,24],"158":[2,24],"159":[2,24],"160":[2,24],"161":[2,24],"162":[2,24],"163":[2,24],"164":[2,24],"165":[2,24]},{"1":[2,25],"4":[2,25],"29":[2,25],"30":[2,25],"51":[2,25],"59":[2,25],"62":[2,25],"80":[2,25],"85":[2,25],"95":[2,25],"100":[2,25],"108":[2,25],"110":[2,25],"111":[2,25],"112":[2,25],"115":[2,25],"119":[2,25],"120":[2,25],"121":[2,25],"128":[2,25],"129":[2,25],"131":[2,25],"133":[2,25],"134":[2,25],"136":[2,25],"137":[2,25],"140":[2,25],"141":[2,25],"142":[2,25],"143":[2,25],"144":[2,25],"145":[2,25],"146":[2,25],"147":[2,25],"148":[2,25],"149":[2,25],"150":[2,25],"151":[2,25],"152":[2,25],"153":[2,25],"154":[2,25],"155":[2,25],"156":[2,25],"157":[2,25],"158":[2,25],"159":[2,25],"160":[2,25],"161":[2,25],"162":[2,25],"163":[2,25],"164":[2,25],"165":[2,25]},{"1":[2,26],"4":[2,26],"29":[2,26],"30":[2,26],"51":[2,26],"59":[2,26],"62":[2,26],"80":[2,26],"85":[2,26],"95":[2,26],"100":[2,26],"108":[2,26],"110":[2,26],"111":[2,26],"112":[2,26],"115":[2,26],"119":[2,26],"120":[2,26],"121":[2,26],"128":[2,26],"129":[2,26],"131":[2,26],"133":[2,26],"134":[2,26],"136":[2,26],"137":[2,26],"140":[2,26],"141":[2,26],"142":[2,26],"143":[2,26],"144":[2,26],"145":[2,26],"146":[2,26],"147":[2,26],"148":[2,26],"149":[2,26],"150":[2,26],"151":[2,26],"152":[2,26],"153":[2,26],"154":[2,26],"155":[2,26],"156":[2,26],"157":[2,26],"158":[2,26],"159":[2,26],"160":[2,26],"161":[2,26],"162":[2,26],"163":[2,26],"164":[2,26],"165":[2,26]},{"1":[2,27],"4":[2,27],"29":[2,27],"30":[2,27],"51":[2,27],"59":[2,27],"62":[2,27],"80":[2,27],"85":[2,27],"95":[2,27],"100":[2,27],"108":[2,27],"110":[2,27],"111":[2,27],"112":[2,27],"115":[2,27],"119":[2,27],"120":[2,27],"121":[2,27],"128":[2,27],"129":[2,27],"131":[2,27],"133":[2,27],"134":[2,27],"136":[2,27],"137":[2,27],"140":[2,27],"141":[2,27],"142":[2,27],"143":[2,27],"144":[2,27],"145":[2,27],"146":[2,27],"147":[2,27],"148":[2,27],"149":[2,27],"150":[2,27],"151":[2,27],"152":[2,27],"153":[2,27],"154":[2,27],"155":[2,27],"156":[2,27],"157":[2,27],"158":[2,27],"159":[2,27],"160":[2,27],"161":[2,27],"162":[2,27],"163":[2,27],"164":[2,27],"165":[2,27]},{"1":[2,28],"4":[2,28],"29":[2,28],"30":[2,28],"51":[2,28],"59":[2,28],"62":[2,28],"80":[2,28],"85":[2,28],"95":[2,28],"100":[2,28],"108":[2,28],"110":[2,28],"111":[2,28],"112":[2,28],"115":[2,28],"119":[2,28],"120":[2,28],"121":[2,28],"128":[2,28],"129":[2,28],"131":[2,28],"133":[2,28],"134":[2,28],"136":[2,28],"137":[2,28],"140":[2,28],"141":[2,28],"142":[2,28],"143":[2,28],"144":[2,28],"145":[2,28],"146":[2,28],"147":[2,28],"148":[2,28],"149":[2,28],"150":[2,28],"151":[2,28],"152":[2,28],"153":[2,28],"154":[2,28],"155":[2,28],"156":[2,28],"157":[2,28],"158":[2,28],"159":[2,28],"160":[2,28],"161":[2,28],"162":[2,28],"163":[2,28],"164":[2,28],"165":[2,28]},{"1":[2,10],"4":[2,10],"30":[2,10],"108":[2,10],"110":[2,10],"112":[2,10],"115":[2,10],"128":[2,10],"129":[2,10]},{"1":[2,11],"4":[2,11],"30":[2,11],"108":[2,11],"110":[2,11],"112":[2,11],"115":[2,11],"128":[2,11],"129":[2,11]},{"1":[2,12],"4":[2,12],"30":[2,12],"108":[2,12],"110":[2,12],"112":[2,12],"115":[2,12],"128":[2,12],"129":[2,12]},{"1":[2,13],"4":[2,13],"30":[2,13],"108":[2,13],"110":[2,13],"112":[2,13],"115":[2,13],"128":[2,13],"129":[2,13]},{"1":[2,74],"4":[2,74],"29":[2,74],"30":[2,74],"46":[1,150],"51":[2,74],"59":[2,74],"62":[2,74],"73":[2,74],"74":[2,74],"75":[2,74],"76":[2,74],"79":[2,74],"80":[2,74],"81":[2,74],"82":[2,74],"85":[2,74],"93":[2,74],"95":[2,74],"100":[2,74],"108":[2,74],"110":[2,74],"111":[2,74],"112":[2,74],"115":[2,74],"119":[2,74],"120":[2,74],"121":[2,74],"128":[2,74],"129":[2,74],"131":[2,74],"133":[2,74],"134":[2,74],"136":[2,74],"137":[2,74],"140":[2,74],"141":[2,74],"142":[2,74],"143":[2,74],"144":[2,74],"145":[2,74],"146":[2,74],"147":[2,74],"148":[2,74],"149":[2,74],"150":[2,74],"151":[2,74],"152":[2,74],"153":[2,74],"154":[2,74],"155":[2,74],"156":[2,74],"157":[2,74],"158":[2,74],"159":[2,74],"160":[2,74],"161":[2,74],"162":[2,74],"163":[2,74],"164":[2,74],"165":[2,74]},{"1":[2,75],"4":[2,75],"29":[2,75],"30":[2,75],"51":[2,75],"59":[2,75],"62":[2,75],"73":[2,75],"74":[2,75],"75":[2,75],"76":[2,75],"79":[2,75],"80":[2,75],"81":[2,75],"82":[2,75],"85":[2,75],"93":[2,75],"95":[2,75],"100":[2,75],"108":[2,75],"110":[2,75],"111":[2,75],"112":[2,75],"115":[2,75],"119":[2,75],"120":[2,75],"121":[2,75],"128":[2,75],"129":[2,75],"131":[2,75],"133":[2,75],"134":[2,75],"136":[2,75],"137":[2,75],"140":[2,75],"141":[2,75],"142":[2,75],"143":[2,75],"144":[2,75],"145":[2,75],"146":[2,75],"147":[2,75],"148":[2,75],"149":[2,75],"150":[2,75],"151":[2,75],"152":[2,75],"153":[2,75],"154":[2,75],"155":[2,75],"156":[2,75],"157":[2,75],"158":[2,75],"159":[2,75],"160":[2,75],"161":[2,75],"162":[2,75],"163":[2,75],"164":[2,75],"165":[2,75]},{"1":[2,76],"4":[2,76],"29":[2,76],"30":[2,76],"51":[2,76],"59":[2,76],"62":[2,76],"73":[2,76],"74":[2,76],"75":[2,76],"76":[2,76],"79":[2,76],"80":[2,76],"81":[2,76],"82":[2,76],"85":[2,76],"93":[2,76],"95":[2,76],"100":[2,76],"108":[2,76],"110":[2,76],"111":[2,76],"112":[2,76],"115":[2,76],"119":[2,76],"120":[2,76],"121":[2,76],"128":[2,76],"129":[2,76],"131":[2,76],"133":[2,76],"134":[2,76],"136":[2,76],"137":[2,76],"140":[2,76],"141":[2,76],"142":[2,76],"143":[2,76],"144":[2,76],"145":[2,76],"146":[2,76],"147":[2,76],"148":[2,76],"149":[2,76],"150":[2,76],"151":[2,76],"152":[2,76],"153":[2,76],"154":[2,76],"155":[2,76],"156":[2,76],"157":[2,76],"158":[2,76],"159":[2,76],"160":[2,76],"161":[2,76],"162":[2,76],"163":[2,76],"164":[2,76],"165":[2,76]},{"1":[2,77],"4":[2,77],"29":[2,77],"30":[2,77],"51":[2,77],"59":[2,77],"62":[2,77],"73":[2,77],"74":[2,77],"75":[2,77],"76":[2,77],"79":[2,77],"80":[2,77],"81":[2,77],"82":[2,77],"85":[2,77],"93":[2,77],"95":[2,77],"100":[2,77],"108":[2,77],"110":[2,77],"111":[2,77],"112":[2,77],"115":[2,77],"119":[2,77],"120":[2,77],"121":[2,77],"128":[2,77],"129":[2,77],"131":[2,77],"133":[2,77],"134":[2,77],"136":[2,77],"137":[2,77],"140":[2,77],"141":[2,77],"142":[2,77],"143":[2,77],"144":[2,77],"145":[2,77],"146":[2,77],"147":[2,77],"148":[2,77],"149":[2,77],"150":[2,77],"151":[2,77],"152":[2,77],"153":[2,77],"154":[2,77],"155":[2,77],"156":[2,77],"157":[2,77],"158":[2,77],"159":[2,77],"160":[2,77],"161":[2,77],"162":[2,77],"163":[2,77],"164":[2,77],"165":[2,77]},{"1":[2,78],"4":[2,78],"29":[2,78],"30":[2,78],"51":[2,78],"59":[2,78],"62":[2,78],"73":[2,78],"74":[2,78],"75":[2,78],"76":[2,78],"79":[2,78],"80":[2,78],"81":[2,78],"82":[2,78],"85":[2,78],"93":[2,78],"95":[2,78],"100":[2,78],"108":[2,78],"110":[2,78],"111":[2,78],"112":[2,78],"115":[2,78],"119":[2,78],"120":[2,78],"121":[2,78],"128":[2,78],"129":[2,78],"131":[2,78],"133":[2,78],"134":[2,78],"136":[2,78],"137":[2,78],"140":[2,78],"141":[2,78],"142":[2,78],"143":[2,78],"144":[2,78],"145":[2,78],"146":[2,78],"147":[2,78],"148":[2,78],"149":[2,78],"150":[2,78],"151":[2,78],"152":[2,78],"153":[2,78],"154":[2,78],"155":[2,78],"156":[2,78],"157":[2,78],"158":[2,78],"159":[2,78],"160":[2,78],"161":[2,78],"162":[2,78],"163":[2,78],"164":[2,78],"165":[2,78]},{"1":[2,79],"4":[2,79],"29":[2,79],"30":[2,79],"51":[2,79],"59":[2,79],"62":[2,79],"73":[2,79],"74":[2,79],"75":[2,79],"76":[2,79],"79":[2,79],"80":[2,79],"81":[2,79],"82":[2,79],"85":[2,79],"93":[2,79],"95":[2,79],"100":[2,79],"108":[2,79],"110":[2,79],"111":[2,79],"112":[2,79],"115":[2,79],"119":[2,79],"120":[2,79],"121":[2,79],"128":[2,79],"129":[2,79],"131":[2,79],"133":[2,79],"134":[2,79],"136":[2,79],"137":[2,79],"140":[2,79],"141":[2,79],"142":[2,79],"143":[2,79],"144":[2,79],"145":[2,79],"146":[2,79],"147":[2,79],"148":[2,79],"149":[2,79],"150":[2,79],"151":[2,79],"152":[2,79],"153":[2,79],"154":[2,79],"155":[2,79],"156":[2,79],"157":[2,79],"158":[2,79],"159":[2,79],"160":[2,79],"161":[2,79],"162":[2,79],"163":[2,79],"164":[2,79],"165":[2,79]},{"1":[2,104],"4":[2,104],"29":[2,104],"30":[2,104],"51":[2,104],"59":[2,104],"62":[2,104],"64":152,"73":[1,141],"74":[1,142],"75":[1,143],"76":[1,144],"77":145,"78":146,"79":[1,147],"80":[2,104],"81":[1,148],"82":[1,149],"85":[2,104],"92":151,"93":[1,140],"95":[2,104],"100":[2,104],"108":[2,104],"110":[2,104],"111":[2,104],"112":[2,104],"115":[2,104],"119":[2,104],"120":[2,104],"121":[2,104],"128":[2,104],"129":[2,104],"131":[2,104],"133":[2,104],"134":[2,104],"136":[2,104],"137":[2,104],"140":[2,104],"141":[2,104],"142":[2,104],"143":[2,104],"144":[2,104],"145":[2,104],"146":[2,104],"147":[2,104],"148":[2,104],"149":[2,104],"150":[2,104],"151":[2,104],"152":[2,104],"153":[2,104],"154":[2,104],"155":[2,104],"156":[2,104],"157":[2,104],"158":[2,104],"159":[2,104],"160":[2,104],"161":[2,104],"162":[2,104],"163":[2,104],"164":[2,104],"165":[2,104]},{"14":154,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":155,"63":156,"65":153,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"97":[1,73],"98":[1,74],"99":[1,72],"107":[1,71]},{"1":[2,106],"4":[2,106],"29":[2,106],"30":[2,106],"51":[2,106],"59":[2,106],"62":[2,106],"80":[2,106],"85":[2,106],"95":[2,106],"100":[2,106],"108":[2,106],"110":[2,106],"111":[2,106],"112":[2,106],"115":[2,106],"119":[2,106],"120":[2,106],"121":[2,106],"128":[2,106],"129":[2,106],"131":[2,106],"133":[2,106],"134":[2,106],"136":[2,106],"137":[2,106],"140":[2,106],"141":[2,106],"142":[2,106],"143":[2,106],"144":[2,106],"145":[2,106],"146":[2,106],"147":[2,106],"148":[2,106],"149":[2,106],"150":[2,106],"151":[2,106],"152":[2,106],"153":[2,106],"154":[2,106],"155":[2,106],"156":[2,106],"157":[2,106],"158":[2,106],"159":[2,106],"160":[2,106],"161":[2,106],"162":[2,106],"163":[2,106],"164":[2,106],"165":[2,106]},{"53":157,"54":[2,61],"59":[2,61],"60":158,"61":[1,159]},{"4":[1,161],"6":160,"29":[1,6]},{"8":162,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":164,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":165,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":166,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":167,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":168,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":169,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":170,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":171,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"1":[2,172],"4":[2,172],"29":[2,172],"30":[2,172],"51":[2,172],"59":[2,172],"62":[2,172],"80":[2,172],"85":[2,172],"95":[2,172],"100":[2,172],"108":[2,172],"110":[2,172],"111":[2,172],"112":[2,172],"115":[2,172],"119":[2,172],"120":[2,172],"121":[2,172],"128":[2,172],"129":[2,172],"131":[2,172],"133":[2,172],"134":[2,172],"136":[2,172],"137":[2,172],"140":[2,172],"141":[2,172],"142":[2,172],"143":[2,172],"144":[2,172],"145":[2,172],"146":[2,172],"147":[2,172],"148":[2,172],"149":[2,172],"150":[2,172],"151":[2,172],"152":[2,172],"153":[2,172],"154":[2,172],"155":[2,172],"156":[2,172],"157":[2,172],"158":[2,172],"159":[2,172],"160":[2,172],"161":[2,172],"162":[2,172],"163":[2,172],"164":[2,172],"165":[2,172]},{"4":[1,161],"6":172,"29":[1,6]},{"4":[1,161],"6":173,"29":[1,6]},{"1":[2,140],"4":[2,140],"29":[2,140],"30":[2,140],"51":[2,140],"59":[2,140],"62":[2,140],"80":[2,140],"85":[2,140],"95":[2,140],"100":[2,140],"108":[2,140],"110":[2,140],"111":[2,140],"112":[2,140],"115":[2,140],"119":[2,140],"120":[2,140],"121":[2,140],"128":[2,140],"129":[2,140],"131":[2,140],"133":[2,140],"134":[2,140],"136":[2,140],"137":[2,140],"140":[2,140],"141":[2,140],"142":[2,140],"143":[2,140],"144":[2,140],"145":[2,140],"146":[2,140],"147":[2,140],"148":[2,140],"149":[2,140],"150":[2,140],"151":[2,140],"152":[2,140],"153":[2,140],"154":[2,140],"155":[2,140],"156":[2,140],"157":[2,140],"158":[2,140],"159":[2,140],"160":[2,140],"161":[2,140],"162":[2,140],"163":[2,140],"164":[2,140],"165":[2,140]},{"31":176,"32":[1,89],"67":177,"68":178,"83":[1,84],"99":[1,179],"116":174,"118":175},{"8":180,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"29":[1,181],"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"1":[2,71],"4":[2,71],"29":[2,71],"30":[2,71],"46":[2,71],"51":[2,71],"59":[2,71],"62":[2,71],"73":[2,71],"74":[2,71],"75":[2,71],"76":[2,71],"79":[2,71],"80":[2,71],"81":[2,71],"82":[2,71],"85":[2,71],"87":[1,182],"93":[2,71],"95":[2,71],"100":[2,71],"108":[2,71],"110":[2,71],"111":[2,71],"112":[2,71],"115":[2,71],"119":[2,71],"120":[2,71],"121":[2,71],"128":[2,71],"129":[2,71],"131":[2,71],"133":[2,71],"134":[2,71],"136":[2,71],"137":[2,71],"140":[2,71],"141":[2,71],"142":[2,71],"143":[2,71],"144":[2,71],"145":[2,71],"146":[2,71],"147":[2,71],"148":[2,71],"149":[2,71],"150":[2,71],"151":[2,71],"152":[2,71],"153":[2,71],"154":[2,71],"155":[2,71],"156":[2,71],"157":[2,71],"158":[2,71],"159":[2,71],"160":[2,71],"161":[2,71],"162":[2,71],"163":[2,71],"164":[2,71],"165":[2,71]},{"14":154,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":155,"63":183,"65":184,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"97":[1,73],"98":[1,74],"99":[1,72],"107":[1,71]},{"1":[2,52],"4":[2,52],"29":[2,52],"30":[2,52],"49":[2,52],"50":[2,52],"51":[2,52],"59":[2,52],"62":[2,52],"80":[2,52],"85":[2,52],"95":[2,52],"100":[2,52],"104":[2,52],"105":[2,52],"108":[2,52],"110":[2,52],"111":[2,52],"112":[2,52],"115":[2,52],"119":[2,52],"120":[2,52],"121":[2,52],"124":[2,52],"126":[2,52],"128":[2,52],"129":[2,52],"131":[2,52],"133":[2,52],"134":[2,52],"136":[2,52],"137":[2,52],"140":[2,52],"141":[2,52],"142":[2,52],"143":[2,52],"144":[2,52],"145":[2,52],"146":[2,52],"147":[2,52],"148":[2,52],"149":[2,52],"150":[2,52],"151":[2,52],"152":[2,52],"153":[2,52],"154":[2,52],"155":[2,52],"156":[2,52],"157":[2,52],"158":[2,52],"159":[2,52],"160":[2,52],"161":[2,52],"162":[2,52],"163":[2,52],"164":[2,52],"165":[2,52]},{"1":[2,53],"4":[2,53],"29":[2,53],"30":[2,53],"49":[2,53],"50":[2,53],"51":[2,53],"59":[2,53],"62":[2,53],"80":[2,53],"85":[2,53],"95":[2,53],"100":[2,53],"104":[2,53],"105":[2,53],"108":[2,53],"110":[2,53],"111":[2,53],"112":[2,53],"115":[2,53],"119":[2,53],"120":[2,53],"121":[2,53],"124":[2,53],"126":[2,53],"128":[2,53],"129":[2,53],"131":[2,53],"133":[2,53],"134":[2,53],"136":[2,53],"137":[2,53],"140":[2,53],"141":[2,53],"142":[2,53],"143":[2,53],"144":[2,53],"145":[2,53],"146":[2,53],"147":[2,53],"148":[2,53],"149":[2,53],"150":[2,53],"151":[2,53],"152":[2,53],"153":[2,53],"154":[2,53],"155":[2,53],"156":[2,53],"157":[2,53],"158":[2,53],"159":[2,53],"160":[2,53],"161":[2,53],"162":[2,53],"163":[2,53],"164":[2,53],"165":[2,53]},{"1":[2,51],"4":[2,51],"8":185,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"30":[2,51],"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"108":[2,51],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[2,51],"129":[2,51],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":186,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"1":[2,72],"4":[2,72],"29":[2,72],"30":[2,72],"46":[2,72],"51":[2,72],"59":[2,72],"62":[2,72],"73":[2,72],"74":[2,72],"75":[2,72],"76":[2,72],"79":[2,72],"80":[2,72],"81":[2,72],"82":[2,72],"85":[2,72],"93":[2,72],"95":[2,72],"100":[2,72],"108":[2,72],"110":[2,72],"111":[2,72],"112":[2,72],"115":[2,72],"119":[2,72],"120":[2,72],"121":[2,72],"128":[2,72],"129":[2,72],"131":[2,72],"133":[2,72],"134":[2,72],"136":[2,72],"137":[2,72],"140":[2,72],"141":[2,72],"142":[2,72],"143":[2,72],"144":[2,72],"145":[2,72],"146":[2,72],"147":[2,72],"148":[2,72],"149":[2,72],"150":[2,72],"151":[2,72],"152":[2,72],"153":[2,72],"154":[2,72],"155":[2,72],"156":[2,72],"157":[2,72],"158":[2,72],"159":[2,72],"160":[2,72],"161":[2,72],"162":[2,72],"163":[2,72],"164":[2,72],"165":[2,72]},{"1":[2,73],"4":[2,73],"29":[2,73],"30":[2,73],"46":[2,73],"51":[2,73],"59":[2,73],"62":[2,73],"73":[2,73],"74":[2,73],"75":[2,73],"76":[2,73],"79":[2,73],"80":[2,73],"81":[2,73],"82":[2,73],"85":[2,73],"93":[2,73],"95":[2,73],"100":[2,73],"108":[2,73],"110":[2,73],"111":[2,73],"112":[2,73],"115":[2,73],"119":[2,73],"120":[2,73],"121":[2,73],"128":[2,73],"129":[2,73],"131":[2,73],"133":[2,73],"134":[2,73],"136":[2,73],"137":[2,73],"140":[2,73],"141":[2,73],"142":[2,73],"143":[2,73],"144":[2,73],"145":[2,73],"146":[2,73],"147":[2,73],"148":[2,73],"149":[2,73],"150":[2,73],"151":[2,73],"152":[2,73],"153":[2,73],"154":[2,73],"155":[2,73],"156":[2,73],"157":[2,73],"158":[2,73],"159":[2,73],"160":[2,73],"161":[2,73],"162":[2,73],"163":[2,73],"164":[2,73],"165":[2,73]},{"1":[2,35],"4":[2,35],"29":[2,35],"30":[2,35],"51":[2,35],"59":[2,35],"62":[2,35],"73":[2,35],"74":[2,35],"75":[2,35],"76":[2,35],"79":[2,35],"80":[2,35],"81":[2,35],"82":[2,35],"85":[2,35],"93":[2,35],"95":[2,35],"100":[2,35],"108":[2,35],"110":[2,35],"111":[2,35],"112":[2,35],"115":[2,35],"119":[2,35],"120":[2,35],"121":[2,35],"128":[2,35],"129":[2,35],"131":[2,35],"133":[2,35],"134":[2,35],"136":[2,35],"137":[2,35],"140":[2,35],"141":[2,35],"142":[2,35],"143":[2,35],"144":[2,35],"145":[2,35],"146":[2,35],"147":[2,35],"148":[2,35],"149":[2,35],"150":[2,35],"151":[2,35],"152":[2,35],"153":[2,35],"154":[2,35],"155":[2,35],"156":[2,35],"157":[2,35],"158":[2,35],"159":[2,35],"160":[2,35],"161":[2,35],"162":[2,35],"163":[2,35],"164":[2,35],"165":[2,35]},{"1":[2,36],"4":[2,36],"29":[2,36],"30":[2,36],"51":[2,36],"59":[2,36],"62":[2,36],"73":[2,36],"74":[2,36],"75":[2,36],"76":[2,36],"79":[2,36],"80":[2,36],"81":[2,36],"82":[2,36],"85":[2,36],"93":[2,36],"95":[2,36],"100":[2,36],"108":[2,36],"110":[2,36],"111":[2,36],"112":[2,36],"115":[2,36],"119":[2,36],"120":[2,36],"121":[2,36],"128":[2,36],"129":[2,36],"131":[2,36],"133":[2,36],"134":[2,36],"136":[2,36],"137":[2,36],"140":[2,36],"141":[2,36],"142":[2,36],"143":[2,36],"144":[2,36],"145":[2,36],"146":[2,36],"147":[2,36],"148":[2,36],"149":[2,36],"150":[2,36],"151":[2,36],"152":[2,36],"153":[2,36],"154":[2,36],"155":[2,36],"156":[2,36],"157":[2,36],"158":[2,36],"159":[2,36],"160":[2,36],"161":[2,36],"162":[2,36],"163":[2,36],"164":[2,36],"165":[2,36]},{"1":[2,37],"4":[2,37],"29":[2,37],"30":[2,37],"51":[2,37],"59":[2,37],"62":[2,37],"73":[2,37],"74":[2,37],"75":[2,37],"76":[2,37],"79":[2,37],"80":[2,37],"81":[2,37],"82":[2,37],"85":[2,37],"93":[2,37],"95":[2,37],"100":[2,37],"108":[2,37],"110":[2,37],"111":[2,37],"112":[2,37],"115":[2,37],"119":[2,37],"120":[2,37],"121":[2,37],"128":[2,37],"129":[2,37],"131":[2,37],"133":[2,37],"134":[2,37],"136":[2,37],"137":[2,37],"140":[2,37],"141":[2,37],"142":[2,37],"143":[2,37],"144":[2,37],"145":[2,37],"146":[2,37],"147":[2,37],"148":[2,37],"149":[2,37],"150":[2,37],"151":[2,37],"152":[2,37],"153":[2,37],"154":[2,37],"155":[2,37],"156":[2,37],"157":[2,37],"158":[2,37],"159":[2,37],"160":[2,37],"161":[2,37],"162":[2,37],"163":[2,37],"164":[2,37],"165":[2,37]},{"1":[2,38],"4":[2,38],"29":[2,38],"30":[2,38],"51":[2,38],"59":[2,38],"62":[2,38],"73":[2,38],"74":[2,38],"75":[2,38],"76":[2,38],"79":[2,38],"80":[2,38],"81":[2,38],"82":[2,38],"85":[2,38],"93":[2,38],"95":[2,38],"100":[2,38],"108":[2,38],"110":[2,38],"111":[2,38],"112":[2,38],"115":[2,38],"119":[2,38],"120":[2,38],"121":[2,38],"128":[2,38],"129":[2,38],"131":[2,38],"133":[2,38],"134":[2,38],"136":[2,38],"137":[2,38],"140":[2,38],"141":[2,38],"142":[2,38],"143":[2,38],"144":[2,38],"145":[2,38],"146":[2,38],"147":[2,38],"148":[2,38],"149":[2,38],"150":[2,38],"151":[2,38],"152":[2,38],"153":[2,38],"154":[2,38],"155":[2,38],"156":[2,38],"157":[2,38],"158":[2,38],"159":[2,38],"160":[2,38],"161":[2,38],"162":[2,38],"163":[2,38],"164":[2,38],"165":[2,38]},{"1":[2,39],"4":[2,39],"29":[2,39],"30":[2,39],"51":[2,39],"59":[2,39],"62":[2,39],"73":[2,39],"74":[2,39],"75":[2,39],"76":[2,39],"79":[2,39],"80":[2,39],"81":[2,39],"82":[2,39],"85":[2,39],"93":[2,39],"95":[2,39],"100":[2,39],"108":[2,39],"110":[2,39],"111":[2,39],"112":[2,39],"115":[2,39],"119":[2,39],"120":[2,39],"121":[2,39],"128":[2,39],"129":[2,39],"131":[2,39],"133":[2,39],"134":[2,39],"136":[2,39],"137":[2,39],"140":[2,39],"141":[2,39],"142":[2,39],"143":[2,39],"144":[2,39],"145":[2,39],"146":[2,39],"147":[2,39],"148":[2,39],"149":[2,39],"150":[2,39],"151":[2,39],"152":[2,39],"153":[2,39],"154":[2,39],"155":[2,39],"156":[2,39],"157":[2,39],"158":[2,39],"159":[2,39],"160":[2,39],"161":[2,39],"162":[2,39],"163":[2,39],"164":[2,39],"165":[2,39]},{"1":[2,40],"4":[2,40],"29":[2,40],"30":[2,40],"51":[2,40],"59":[2,40],"62":[2,40],"73":[2,40],"74":[2,40],"75":[2,40],"76":[2,40],"79":[2,40],"80":[2,40],"81":[2,40],"82":[2,40],"85":[2,40],"93":[2,40],"95":[2,40],"100":[2,40],"108":[2,40],"110":[2,40],"111":[2,40],"112":[2,40],"115":[2,40],"119":[2,40],"120":[2,40],"121":[2,40],"128":[2,40],"129":[2,40],"131":[2,40],"133":[2,40],"134":[2,40],"136":[2,40],"137":[2,40],"140":[2,40],"141":[2,40],"142":[2,40],"143":[2,40],"144":[2,40],"145":[2,40],"146":[2,40],"147":[2,40],"148":[2,40],"149":[2,40],"150":[2,40],"151":[2,40],"152":[2,40],"153":[2,40],"154":[2,40],"155":[2,40],"156":[2,40],"157":[2,40],"158":[2,40],"159":[2,40],"160":[2,40],"161":[2,40],"162":[2,40],"163":[2,40],"164":[2,40],"165":[2,40]},{"1":[2,41],"4":[2,41],"29":[2,41],"30":[2,41],"51":[2,41],"59":[2,41],"62":[2,41],"73":[2,41],"74":[2,41],"75":[2,41],"76":[2,41],"79":[2,41],"80":[2,41],"81":[2,41],"82":[2,41],"85":[2,41],"93":[2,41],"95":[2,41],"100":[2,41],"108":[2,41],"110":[2,41],"111":[2,41],"112":[2,41],"115":[2,41],"119":[2,41],"120":[2,41],"121":[2,41],"128":[2,41],"129":[2,41],"131":[2,41],"133":[2,41],"134":[2,41],"136":[2,41],"137":[2,41],"140":[2,41],"141":[2,41],"142":[2,41],"143":[2,41],"144":[2,41],"145":[2,41],"146":[2,41],"147":[2,41],"148":[2,41],"149":[2,41],"150":[2,41],"151":[2,41],"152":[2,41],"153":[2,41],"154":[2,41],"155":[2,41],"156":[2,41],"157":[2,41],"158":[2,41],"159":[2,41],"160":[2,41],"161":[2,41],"162":[2,41],"163":[2,41],"164":[2,41],"165":[2,41]},{"1":[2,42],"4":[2,42],"29":[2,42],"30":[2,42],"51":[2,42],"59":[2,42],"62":[2,42],"73":[2,42],"74":[2,42],"75":[2,42],"76":[2,42],"79":[2,42],"80":[2,42],"81":[2,42],"82":[2,42],"85":[2,42],"93":[2,42],"95":[2,42],"100":[2,42],"108":[2,42],"110":[2,42],"111":[2,42],"112":[2,42],"115":[2,42],"119":[2,42],"120":[2,42],"121":[2,42],"128":[2,42],"129":[2,42],"131":[2,42],"133":[2,42],"134":[2,42],"136":[2,42],"137":[2,42],"140":[2,42],"141":[2,42],"142":[2,42],"143":[2,42],"144":[2,42],"145":[2,42],"146":[2,42],"147":[2,42],"148":[2,42],"149":[2,42],"150":[2,42],"151":[2,42],"152":[2,42],"153":[2,42],"154":[2,42],"155":[2,42],"156":[2,42],"157":[2,42],"158":[2,42],"159":[2,42],"160":[2,42],"161":[2,42],"162":[2,42],"163":[2,42],"164":[2,42],"165":[2,42]},{"1":[2,43],"4":[2,43],"29":[2,43],"30":[2,43],"51":[2,43],"59":[2,43],"62":[2,43],"73":[2,43],"74":[2,43],"75":[2,43],"76":[2,43],"79":[2,43],"80":[2,43],"81":[2,43],"82":[2,43],"85":[2,43],"93":[2,43],"95":[2,43],"100":[2,43],"108":[2,43],"110":[2,43],"111":[2,43],"112":[2,43],"115":[2,43],"119":[2,43],"120":[2,43],"121":[2,43],"128":[2,43],"129":[2,43],"131":[2,43],"133":[2,43],"134":[2,43],"136":[2,43],"137":[2,43],"140":[2,43],"141":[2,43],"142":[2,43],"143":[2,43],"144":[2,43],"145":[2,43],"146":[2,43],"147":[2,43],"148":[2,43],"149":[2,43],"150":[2,43],"151":[2,43],"152":[2,43],"153":[2,43],"154":[2,43],"155":[2,43],"156":[2,43],"157":[2,43],"158":[2,43],"159":[2,43],"160":[2,43],"161":[2,43],"162":[2,43],"163":[2,43],"164":[2,43],"165":[2,43]},{"7":187,"8":7,"9":8,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"4":[2,120],"8":188,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"29":[2,120],"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"59":[2,120],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"94":189,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"100":[2,120],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"1":[2,112],"4":[2,112],"29":[2,112],"30":[2,112],"51":[2,112],"59":[2,112],"62":[2,112],"73":[2,112],"74":[2,112],"75":[2,112],"76":[2,112],"79":[2,112],"80":[2,112],"81":[2,112],"82":[2,112],"85":[2,112],"93":[2,112],"95":[2,112],"100":[2,112],"108":[2,112],"110":[2,112],"111":[2,112],"112":[2,112],"115":[2,112],"119":[2,112],"120":[2,112],"121":[2,112],"128":[2,112],"129":[2,112],"131":[2,112],"133":[2,112],"134":[2,112],"136":[2,112],"137":[2,112],"140":[2,112],"141":[2,112],"142":[2,112],"143":[2,112],"144":[2,112],"145":[2,112],"146":[2,112],"147":[2,112],"148":[2,112],"149":[2,112],"150":[2,112],"151":[2,112],"152":[2,112],"153":[2,112],"154":[2,112],"155":[2,112],"156":[2,112],"157":[2,112],"158":[2,112],"159":[2,112],"160":[2,112],"161":[2,112],"162":[2,112],"163":[2,112],"164":[2,112],"165":[2,112]},{"1":[2,113],"4":[2,113],"29":[2,113],"30":[2,113],"31":190,"32":[1,89],"51":[2,113],"59":[2,113],"62":[2,113],"73":[2,113],"74":[2,113],"75":[2,113],"76":[2,113],"79":[2,113],"80":[2,113],"81":[2,113],"82":[2,113],"85":[2,113],"93":[2,113],"95":[2,113],"100":[2,113],"108":[2,113],"110":[2,113],"111":[2,113],"112":[2,113],"115":[2,113],"119":[2,113],"120":[2,113],"121":[2,113],"128":[2,113],"129":[2,113],"131":[2,113],"133":[2,113],"134":[2,113],"136":[2,113],"137":[2,113],"140":[2,113],"141":[2,113],"142":[2,113],"143":[2,113],"144":[2,113],"145":[2,113],"146":[2,113],"147":[2,113],"148":[2,113],"149":[2,113],"150":[2,113],"151":[2,113],"152":[2,113],"153":[2,113],"154":[2,113],"155":[2,113],"156":[2,113],"157":[2,113],"158":[2,113],"159":[2,113],"160":[2,113],"161":[2,113],"162":[2,113],"163":[2,113],"164":[2,113],"165":[2,113]},{"93":[1,191]},{"4":[2,57],"29":[2,57]},{"4":[2,58],"29":[2,58]},{"1":[2,170],"4":[2,170],"29":[2,170],"30":[2,170],"51":[2,170],"59":[2,170],"62":[2,170],"80":[2,170],"85":[2,170],"95":[2,170],"100":[2,170],"108":[2,170],"110":[2,170],"111":[2,170],"112":[2,170],"115":[2,170],"119":[2,170],"120":[2,170],"121":[2,170],"124":[1,192],"128":[2,170],"129":[2,170],"131":[2,170],"133":[2,170],"134":[2,170],"136":[2,170],"137":[2,170],"140":[2,170],"141":[2,170],"142":[2,170],"143":[2,170],"144":[2,170],"145":[2,170],"146":[2,170],"147":[2,170],"148":[2,170],"149":[2,170],"150":[2,170],"151":[2,170],"152":[2,170],"153":[2,170],"154":[2,170],"155":[2,170],"156":[2,170],"157":[2,170],"158":[2,170],"159":[2,170],"160":[2,170],"161":[2,170],"162":[2,170],"163":[2,170],"164":[2,170],"165":[2,170]},{"8":193,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":194,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"4":[1,161],"6":195,"8":196,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"29":[1,6],"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"1":[2,67],"4":[2,67],"29":[2,67],"30":[2,67],"46":[2,67],"51":[2,67],"59":[2,67],"62":[2,67],"73":[2,67],"74":[2,67],"75":[2,67],"76":[2,67],"79":[2,67],"80":[2,67],"81":[2,67],"82":[2,67],"85":[2,67],"87":[2,67],"93":[2,67],"95":[2,67],"100":[2,67],"108":[2,67],"110":[2,67],"111":[2,67],"112":[2,67],"115":[2,67],"119":[2,67],"120":[2,67],"121":[2,67],"128":[2,67],"129":[2,67],"131":[2,67],"133":[2,67],"134":[2,67],"136":[2,67],"137":[2,67],"140":[2,67],"141":[2,67],"142":[2,67],"143":[2,67],"144":[2,67],"145":[2,67],"146":[2,67],"147":[2,67],"148":[2,67],"149":[2,67],"150":[2,67],"151":[2,67],"152":[2,67],"153":[2,67],"154":[2,67],"155":[2,67],"156":[2,67],"157":[2,67],"158":[2,67],"159":[2,67],"160":[2,67],"161":[2,67],"162":[2,67],"163":[2,67],"164":[2,67],"165":[2,67]},{"1":[2,70],"4":[2,70],"29":[2,70],"30":[2,70],"46":[2,70],"51":[2,70],"59":[2,70],"62":[2,70],"73":[2,70],"74":[2,70],"75":[2,70],"76":[2,70],"79":[2,70],"80":[2,70],"81":[2,70],"82":[2,70],"85":[2,70],"87":[2,70],"93":[2,70],"95":[2,70],"100":[2,70],"108":[2,70],"110":[2,70],"111":[2,70],"112":[2,70],"115":[2,70],"119":[2,70],"120":[2,70],"121":[2,70],"128":[2,70],"129":[2,70],"131":[2,70],"133":[2,70],"134":[2,70],"136":[2,70],"137":[2,70],"140":[2,70],"141":[2,70],"142":[2,70],"143":[2,70],"144":[2,70],"145":[2,70],"146":[2,70],"147":[2,70],"148":[2,70],"149":[2,70],"150":[2,70],"151":[2,70],"152":[2,70],"153":[2,70],"154":[2,70],"155":[2,70],"156":[2,70],"157":[2,70],"158":[2,70],"159":[2,70],"160":[2,70],"161":[2,70],"162":[2,70],"163":[2,70],"164":[2,70],"165":[2,70]},{"4":[2,90],"28":201,"29":[2,90],"31":199,"32":[1,89],"33":200,"34":[1,85],"35":[1,86],"47":198,"49":[1,56],"50":[1,57],"59":[2,90],"84":197,"85":[2,90]},{"1":[2,33],"4":[2,33],"29":[2,33],"30":[2,33],"46":[2,33],"51":[2,33],"59":[2,33],"62":[2,33],"73":[2,33],"74":[2,33],"75":[2,33],"76":[2,33],"79":[2,33],"80":[2,33],"81":[2,33],"82":[2,33],"85":[2,33],"93":[2,33],"95":[2,33],"100":[2,33],"108":[2,33],"110":[2,33],"111":[2,33],"112":[2,33],"115":[2,33],"119":[2,33],"120":[2,33],"121":[2,33],"128":[2,33],"129":[2,33],"131":[2,33],"133":[2,33],"134":[2,33],"136":[2,33],"137":[2,33],"140":[2,33],"141":[2,33],"142":[2,33],"143":[2,33],"144":[2,33],"145":[2,33],"146":[2,33],"147":[2,33],"148":[2,33],"149":[2,33],"150":[2,33],"151":[2,33],"152":[2,33],"153":[2,33],"154":[2,33],"155":[2,33],"156":[2,33],"157":[2,33],"158":[2,33],"159":[2,33],"160":[2,33],"161":[2,33],"162":[2,33],"163":[2,33],"164":[2,33],"165":[2,33]},{"1":[2,34],"4":[2,34],"29":[2,34],"30":[2,34],"46":[2,34],"51":[2,34],"59":[2,34],"62":[2,34],"73":[2,34],"74":[2,34],"75":[2,34],"76":[2,34],"79":[2,34],"80":[2,34],"81":[2,34],"82":[2,34],"85":[2,34],"93":[2,34],"95":[2,34],"100":[2,34],"108":[2,34],"110":[2,34],"111":[2,34],"112":[2,34],"115":[2,34],"119":[2,34],"120":[2,34],"121":[2,34],"128":[2,34],"129":[2,34],"131":[2,34],"133":[2,34],"134":[2,34],"136":[2,34],"137":[2,34],"140":[2,34],"141":[2,34],"142":[2,34],"143":[2,34],"144":[2,34],"145":[2,34],"146":[2,34],"147":[2,34],"148":[2,34],"149":[2,34],"150":[2,34],"151":[2,34],"152":[2,34],"153":[2,34],"154":[2,34],"155":[2,34],"156":[2,34],"157":[2,34],"158":[2,34],"159":[2,34],"160":[2,34],"161":[2,34],"162":[2,34],"163":[2,34],"164":[2,34],"165":[2,34]},{"8":202,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":203,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"1":[2,32],"4":[2,32],"29":[2,32],"30":[2,32],"46":[2,32],"51":[2,32],"59":[2,32],"62":[2,32],"73":[2,32],"74":[2,32],"75":[2,32],"76":[2,32],"79":[2,32],"80":[2,32],"81":[2,32],"82":[2,32],"85":[2,32],"87":[2,32],"93":[2,32],"95":[2,32],"100":[2,32],"108":[2,32],"110":[2,32],"111":[2,32],"112":[2,32],"115":[2,32],"119":[2,32],"120":[2,32],"121":[2,32],"128":[2,32],"129":[2,32],"131":[2,32],"133":[2,32],"134":[2,32],"136":[2,32],"137":[2,32],"140":[2,32],"141":[2,32],"142":[2,32],"143":[2,32],"144":[2,32],"145":[2,32],"146":[2,32],"147":[2,32],"148":[2,32],"149":[2,32],"150":[2,32],"151":[2,32],"152":[2,32],"153":[2,32],"154":[2,32],"155":[2,32],"156":[2,32],"157":[2,32],"158":[2,32],"159":[2,32],"160":[2,32],"161":[2,32],"162":[2,32],"163":[2,32],"164":[2,32],"165":[2,32]},{"1":[2,31],"4":[2,31],"29":[2,31],"30":[2,31],"49":[2,31],"50":[2,31],"51":[2,31],"59":[2,31],"62":[2,31],"80":[2,31],"85":[2,31],"95":[2,31],"100":[2,31],"104":[2,31],"105":[2,31],"108":[2,31],"110":[2,31],"111":[2,31],"112":[2,31],"115":[2,31],"119":[2,31],"120":[2,31],"121":[2,31],"124":[2,31],"126":[2,31],"128":[2,31],"129":[2,31],"131":[2,31],"133":[2,31],"134":[2,31],"136":[2,31],"137":[2,31],"140":[2,31],"141":[2,31],"142":[2,31],"143":[2,31],"144":[2,31],"145":[2,31],"146":[2,31],"147":[2,31],"148":[2,31],"149":[2,31],"150":[2,31],"151":[2,31],"152":[2,31],"153":[2,31],"154":[2,31],"155":[2,31],"156":[2,31],"157":[2,31],"158":[2,31],"159":[2,31],"160":[2,31],"161":[2,31],"162":[2,31],"163":[2,31],"164":[2,31],"165":[2,31]},{"1":[2,7],"4":[2,7],"7":204,"8":7,"9":8,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"30":[2,7],"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"1":[2,4]},{"4":[1,91],"30":[1,205]},{"1":[2,30],"4":[2,30],"29":[2,30],"30":[2,30],"49":[2,30],"50":[2,30],"51":[2,30],"59":[2,30],"62":[2,30],"80":[2,30],"85":[2,30],"95":[2,30],"100":[2,30],"104":[2,30],"105":[2,30],"108":[2,30],"110":[2,30],"111":[2,30],"112":[2,30],"115":[2,30],"119":[2,30],"120":[2,30],"121":[2,30],"124":[2,30],"126":[2,30],"128":[2,30],"129":[2,30],"131":[2,30],"133":[2,30],"134":[2,30],"136":[2,30],"137":[2,30],"140":[2,30],"141":[2,30],"142":[2,30],"143":[2,30],"144":[2,30],"145":[2,30],"146":[2,30],"147":[2,30],"148":[2,30],"149":[2,30],"150":[2,30],"151":[2,30],"152":[2,30],"153":[2,30],"154":[2,30],"155":[2,30],"156":[2,30],"157":[2,30],"158":[2,30],"159":[2,30],"160":[2,30],"161":[2,30],"162":[2,30],"163":[2,30],"164":[2,30],"165":[2,30]},{"1":[2,186],"4":[2,186],"29":[2,186],"30":[2,186],"51":[2,186],"59":[2,186],"62":[2,186],"80":[2,186],"85":[2,186],"95":[2,186],"100":[2,186],"108":[2,186],"110":[2,186],"111":[2,186],"112":[2,186],"115":[2,186],"119":[2,186],"120":[2,186],"121":[2,186],"128":[2,186],"129":[2,186],"131":[2,186],"133":[2,186],"134":[2,186],"136":[2,186],"137":[2,186],"140":[2,186],"141":[2,186],"142":[2,186],"143":[2,186],"144":[2,186],"145":[2,186],"146":[2,186],"147":[2,186],"148":[2,186],"149":[2,186],"150":[2,186],"151":[2,186],"152":[2,186],"153":[2,186],"154":[2,186],"155":[2,186],"156":[2,186],"157":[2,186],"158":[2,186],"159":[2,186],"160":[2,186],"161":[2,186],"162":[2,186],"163":[2,186],"164":[2,186],"165":[2,186]},{"1":[2,187],"4":[2,187],"29":[2,187],"30":[2,187],"51":[2,187],"59":[2,187],"62":[2,187],"80":[2,187],"85":[2,187],"95":[2,187],"100":[2,187],"108":[2,187],"110":[2,187],"111":[2,187],"112":[2,187],"115":[2,187],"119":[2,187],"120":[2,187],"121":[2,187],"128":[2,187],"129":[2,187],"131":[2,187],"133":[2,187],"134":[2,187],"136":[2,187],"137":[2,187],"140":[2,187],"141":[2,187],"142":[2,187],"143":[2,187],"144":[2,187],"145":[2,187],"146":[2,187],"147":[2,187],"148":[2,187],"149":[2,187],"150":[2,187],"151":[2,187],"152":[2,187],"153":[2,187],"154":[2,187],"155":[2,187],"156":[2,187],"157":[2,187],"158":[2,187],"159":[2,187],"160":[2,187],"161":[2,187],"162":[2,187],"163":[2,187],"164":[2,187],"165":[2,187]},{"8":206,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":207,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":208,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":209,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":210,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":211,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":212,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":213,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":214,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":215,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":216,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":217,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":218,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":219,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":220,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":221,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":222,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":223,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":224,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"1":[2,54],"4":[2,54],"8":225,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"29":[2,54],"30":[2,54],"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"51":[2,54],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"59":[2,54],"62":[2,54],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"80":[2,54],"83":[1,84],"85":[2,54],"86":[1,55],"90":[1,35],"91":36,"95":[2,54],"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"100":[2,54],"102":[1,49],"106":[1,59],"107":[1,71],"108":[2,54],"109":50,"110":[2,54],"111":[2,54],"112":[2,54],"113":51,"114":[1,81],"115":[2,54],"119":[2,54],"120":[2,54],"121":[2,54],"122":[1,53],"127":78,"128":[2,54],"129":[2,54],"130":48,"131":[2,54],"132":[1,40],"133":[2,54],"134":[2,54],"135":[1,43],"136":[2,54],"137":[2,54],"138":[1,46],"139":[1,47],"140":[2,54],"141":[2,54],"142":[2,54],"143":[2,54],"144":[2,54],"145":[2,54],"146":[2,54],"147":[2,54],"148":[2,54],"149":[2,54],"150":[2,54],"151":[2,54],"152":[2,54],"153":[2,54],"154":[2,54],"155":[2,54],"156":[2,54],"157":[2,54],"158":[2,54],"159":[2,54],"160":[2,54],"161":[2,54],"162":[2,54],"163":[2,54],"164":[2,54],"165":[2,54]},{"8":226,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":227,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":228,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":229,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":230,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":231,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":232,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":233,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":234,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":235,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":236,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"119":[1,237],"120":[1,238]},{"8":239,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":240,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"1":[2,139],"4":[2,139],"29":[2,139],"30":[2,139],"51":[2,139],"59":[2,139],"62":[2,139],"80":[2,139],"85":[2,139],"95":[2,139],"100":[2,139],"108":[2,139],"110":[2,139],"111":[2,139],"112":[2,139],"115":[2,139],"119":[2,139],"120":[2,139],"121":[2,139],"128":[2,139],"129":[2,139],"131":[2,139],"133":[2,139],"134":[2,139],"136":[2,139],"137":[2,139],"140":[2,139],"141":[2,139],"142":[2,139],"143":[2,139],"144":[2,139],"145":[2,139],"146":[2,139],"147":[2,139],"148":[2,139],"149":[2,139],"150":[2,139],"151":[2,139],"152":[2,139],"153":[2,139],"154":[2,139],"155":[2,139],"156":[2,139],"157":[2,139],"158":[2,139],"159":[2,139],"160":[2,139],"161":[2,139],"162":[2,139],"163":[2,139],"164":[2,139],"165":[2,139]},{"31":176,"32":[1,89],"67":177,"68":178,"83":[1,84],"99":[1,179],"116":241,"118":175},{"62":[1,242]},{"8":243,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":244,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"1":[2,138],"4":[2,138],"29":[2,138],"30":[2,138],"51":[2,138],"59":[2,138],"62":[2,138],"80":[2,138],"85":[2,138],"95":[2,138],"100":[2,138],"108":[2,138],"110":[2,138],"111":[2,138],"112":[2,138],"115":[2,138],"119":[2,138],"120":[2,138],"121":[2,138],"128":[2,138],"129":[2,138],"131":[2,138],"133":[2,138],"134":[2,138],"136":[2,138],"137":[2,138],"140":[2,138],"141":[2,138],"142":[2,138],"143":[2,138],"144":[2,138],"145":[2,138],"146":[2,138],"147":[2,138],"148":[2,138],"149":[2,138],"150":[2,138],"151":[2,138],"152":[2,138],"153":[2,138],"154":[2,138],"155":[2,138],"156":[2,138],"157":[2,138],"158":[2,138],"159":[2,138],"160":[2,138],"161":[2,138],"162":[2,138],"163":[2,138],"164":[2,138],"165":[2,138]},{"31":176,"32":[1,89],"67":177,"68":178,"83":[1,84],"99":[1,179],"116":245,"118":175},{"1":[2,108],"4":[2,108],"29":[2,108],"30":[2,108],"51":[2,108],"59":[2,108],"62":[2,108],"73":[2,108],"74":[2,108],"75":[2,108],"76":[2,108],"79":[2,108],"80":[2,108],"81":[2,108],"82":[2,108],"85":[2,108],"93":[2,108],"95":[2,108],"100":[2,108],"108":[2,108],"110":[2,108],"111":[2,108],"112":[2,108],"115":[2,108],"119":[2,108],"120":[2,108],"121":[2,108],"128":[2,108],"129":[2,108],"131":[2,108],"133":[2,108],"134":[2,108],"136":[2,108],"137":[2,108],"140":[2,108],"141":[2,108],"142":[2,108],"143":[2,108],"144":[2,108],"145":[2,108],"146":[2,108],"147":[2,108],"148":[2,108],"149":[2,108],"150":[2,108],"151":[2,108],"152":[2,108],"153":[2,108],"154":[2,108],"155":[2,108],"156":[2,108],"157":[2,108],"158":[2,108],"159":[2,108],"160":[2,108],"161":[2,108],"162":[2,108],"163":[2,108],"164":[2,108],"165":[2,108]},{"1":[2,68],"4":[2,68],"29":[2,68],"30":[2,68],"46":[2,68],"51":[2,68],"59":[2,68],"62":[2,68],"73":[2,68],"74":[2,68],"75":[2,68],"76":[2,68],"79":[2,68],"80":[2,68],"81":[2,68],"82":[2,68],"85":[2,68],"87":[2,68],"93":[2,68],"95":[2,68],"100":[2,68],"108":[2,68],"110":[2,68],"111":[2,68],"112":[2,68],"115":[2,68],"119":[2,68],"120":[2,68],"121":[2,68],"128":[2,68],"129":[2,68],"131":[2,68],"133":[2,68],"134":[2,68],"136":[2,68],"137":[2,68],"140":[2,68],"141":[2,68],"142":[2,68],"143":[2,68],"144":[2,68],"145":[2,68],"146":[2,68],"147":[2,68],"148":[2,68],"149":[2,68],"150":[2,68],"151":[2,68],"152":[2,68],"153":[2,68],"154":[2,68],"155":[2,68],"156":[2,68],"157":[2,68],"158":[2,68],"159":[2,68],"160":[2,68],"161":[2,68],"162":[2,68],"163":[2,68],"164":[2,68],"165":[2,68]},{"4":[2,120],"8":247,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"29":[2,120],"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"59":[2,120],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"94":246,"95":[2,120],"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"31":248,"32":[1,89]},{"31":249,"32":[1,89]},{"1":[2,82],"4":[2,82],"29":[2,82],"30":[2,82],"46":[2,82],"51":[2,82],"59":[2,82],"62":[2,82],"73":[2,82],"74":[2,82],"75":[2,82],"76":[2,82],"79":[2,82],"80":[2,82],"81":[2,82],"82":[2,82],"85":[2,82],"87":[2,82],"93":[2,82],"95":[2,82],"100":[2,82],"108":[2,82],"110":[2,82],"111":[2,82],"112":[2,82],"115":[2,82],"119":[2,82],"120":[2,82],"121":[2,82],"128":[2,82],"129":[2,82],"131":[2,82],"133":[2,82],"134":[2,82],"136":[2,82],"137":[2,82],"140":[2,82],"141":[2,82],"142":[2,82],"143":[2,82],"144":[2,82],"145":[2,82],"146":[2,82],"147":[2,82],"148":[2,82],"149":[2,82],"150":[2,82],"151":[2,82],"152":[2,82],"153":[2,82],"154":[2,82],"155":[2,82],"156":[2,82],"157":[2,82],"158":[2,82],"159":[2,82],"160":[2,82],"161":[2,82],"162":[2,82],"163":[2,82],"164":[2,82],"165":[2,82]},{"31":250,"32":[1,89]},{"1":[2,84],"4":[2,84],"29":[2,84],"30":[2,84],"46":[2,84],"51":[2,84],"59":[2,84],"62":[2,84],"73":[2,84],"74":[2,84],"75":[2,84],"76":[2,84],"79":[2,84],"80":[2,84],"81":[2,84],"82":[2,84],"85":[2,84],"87":[2,84],"93":[2,84],"95":[2,84],"100":[2,84],"108":[2,84],"110":[2,84],"111":[2,84],"112":[2,84],"115":[2,84],"119":[2,84],"120":[2,84],"121":[2,84],"128":[2,84],"129":[2,84],"131":[2,84],"133":[2,84],"134":[2,84],"136":[2,84],"137":[2,84],"140":[2,84],"141":[2,84],"142":[2,84],"143":[2,84],"144":[2,84],"145":[2,84],"146":[2,84],"147":[2,84],"148":[2,84],"149":[2,84],"150":[2,84],"151":[2,84],"152":[2,84],"153":[2,84],"154":[2,84],"155":[2,84],"156":[2,84],"157":[2,84],"158":[2,84],"159":[2,84],"160":[2,84],"161":[2,84],"162":[2,84],"163":[2,84],"164":[2,84],"165":[2,84]},{"1":[2,85],"4":[2,85],"29":[2,85],"30":[2,85],"46":[2,85],"51":[2,85],"59":[2,85],"62":[2,85],"73":[2,85],"74":[2,85],"75":[2,85],"76":[2,85],"79":[2,85],"80":[2,85],"81":[2,85],"82":[2,85],"85":[2,85],"87":[2,85],"93":[2,85],"95":[2,85],"100":[2,85],"108":[2,85],"110":[2,85],"111":[2,85],"112":[2,85],"115":[2,85],"119":[2,85],"120":[2,85],"121":[2,85],"128":[2,85],"129":[2,85],"131":[2,85],"133":[2,85],"134":[2,85],"136":[2,85],"137":[2,85],"140":[2,85],"141":[2,85],"142":[2,85],"143":[2,85],"144":[2,85],"145":[2,85],"146":[2,85],"147":[2,85],"148":[2,85],"149":[2,85],"150":[2,85],"151":[2,85],"152":[2,85],"153":[2,85],"154":[2,85],"155":[2,85],"156":[2,85],"157":[2,85],"158":[2,85],"159":[2,85],"160":[2,85],"161":[2,85],"162":[2,85],"163":[2,85],"164":[2,85],"165":[2,85]},{"8":251,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"77":252,"79":[1,253],"81":[1,148],"82":[1,149]},{"77":254,"79":[1,253],"81":[1,148],"82":[1,149]},{"8":255,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"1":[2,109],"4":[2,109],"29":[2,109],"30":[2,109],"51":[2,109],"59":[2,109],"62":[2,109],"73":[2,109],"74":[2,109],"75":[2,109],"76":[2,109],"79":[2,109],"80":[2,109],"81":[2,109],"82":[2,109],"85":[2,109],"93":[2,109],"95":[2,109],"100":[2,109],"108":[2,109],"110":[2,109],"111":[2,109],"112":[2,109],"115":[2,109],"119":[2,109],"120":[2,109],"121":[2,109],"128":[2,109],"129":[2,109],"131":[2,109],"133":[2,109],"134":[2,109],"136":[2,109],"137":[2,109],"140":[2,109],"141":[2,109],"142":[2,109],"143":[2,109],"144":[2,109],"145":[2,109],"146":[2,109],"147":[2,109],"148":[2,109],"149":[2,109],"150":[2,109],"151":[2,109],"152":[2,109],"153":[2,109],"154":[2,109],"155":[2,109],"156":[2,109],"157":[2,109],"158":[2,109],"159":[2,109],"160":[2,109],"161":[2,109],"162":[2,109],"163":[2,109],"164":[2,109],"165":[2,109]},{"1":[2,69],"4":[2,69],"29":[2,69],"30":[2,69],"46":[2,69],"51":[2,69],"59":[2,69],"62":[2,69],"73":[2,69],"74":[2,69],"75":[2,69],"76":[2,69],"79":[2,69],"80":[2,69],"81":[2,69],"82":[2,69],"85":[2,69],"87":[2,69],"93":[2,69],"95":[2,69],"100":[2,69],"108":[2,69],"110":[2,69],"111":[2,69],"112":[2,69],"115":[2,69],"119":[2,69],"120":[2,69],"121":[2,69],"128":[2,69],"129":[2,69],"131":[2,69],"133":[2,69],"134":[2,69],"136":[2,69],"137":[2,69],"140":[2,69],"141":[2,69],"142":[2,69],"143":[2,69],"144":[2,69],"145":[2,69],"146":[2,69],"147":[2,69],"148":[2,69],"149":[2,69],"150":[2,69],"151":[2,69],"152":[2,69],"153":[2,69],"154":[2,69],"155":[2,69],"156":[2,69],"157":[2,69],"158":[2,69],"159":[2,69],"160":[2,69],"161":[2,69],"162":[2,69],"163":[2,69],"164":[2,69],"165":[2,69]},{"1":[2,105],"4":[2,105],"29":[2,105],"30":[2,105],"51":[2,105],"59":[2,105],"62":[2,105],"64":152,"73":[1,141],"74":[1,142],"75":[1,143],"76":[1,144],"77":145,"78":146,"79":[1,147],"80":[2,105],"81":[1,148],"82":[1,149],"85":[2,105],"92":151,"93":[1,140],"95":[2,105],"100":[2,105],"108":[2,105],"110":[2,105],"111":[2,105],"112":[2,105],"115":[2,105],"119":[2,105],"120":[2,105],"121":[2,105],"128":[2,105],"129":[2,105],"131":[2,105],"133":[2,105],"134":[2,105],"136":[2,105],"137":[2,105],"140":[2,105],"141":[2,105],"142":[2,105],"143":[2,105],"144":[2,105],"145":[2,105],"146":[2,105],"147":[2,105],"148":[2,105],"149":[2,105],"150":[2,105],"151":[2,105],"152":[2,105],"153":[2,105],"154":[2,105],"155":[2,105],"156":[2,105],"157":[2,105],"158":[2,105],"159":[2,105],"160":[2,105],"161":[2,105],"162":[2,105],"163":[2,105],"164":[2,105],"165":[2,105]},{"64":139,"73":[1,141],"74":[1,142],"75":[1,143],"76":[1,144],"77":145,"78":146,"79":[1,147],"81":[1,148],"82":[1,149],"92":138,"93":[1,140]},{"1":[2,74],"4":[2,74],"29":[2,74],"30":[2,74],"51":[2,74],"59":[2,74],"62":[2,74],"73":[2,74],"74":[2,74],"75":[2,74],"76":[2,74],"79":[2,74],"80":[2,74],"81":[2,74],"82":[2,74],"85":[2,74],"93":[2,74],"95":[2,74],"100":[2,74],"108":[2,74],"110":[2,74],"111":[2,74],"112":[2,74],"115":[2,74],"119":[2,74],"120":[2,74],"121":[2,74],"128":[2,74],"129":[2,74],"131":[2,74],"133":[2,74],"134":[2,74],"136":[2,74],"137":[2,74],"140":[2,74],"141":[2,74],"142":[2,74],"143":[2,74],"144":[2,74],"145":[2,74],"146":[2,74],"147":[2,74],"148":[2,74],"149":[2,74],"150":[2,74],"151":[2,74],"152":[2,74],"153":[2,74],"154":[2,74],"155":[2,74],"156":[2,74],"157":[2,74],"158":[2,74],"159":[2,74],"160":[2,74],"161":[2,74],"162":[2,74],"163":[2,74],"164":[2,74],"165":[2,74]},{"1":[2,71],"4":[2,71],"29":[2,71],"30":[2,71],"51":[2,71],"59":[2,71],"62":[2,71],"73":[2,71],"74":[2,71],"75":[2,71],"76":[2,71],"79":[2,71],"80":[2,71],"81":[2,71],"82":[2,71],"85":[2,71],"93":[2,71],"95":[2,71],"100":[2,71],"108":[2,71],"110":[2,71],"111":[2,71],"112":[2,71],"115":[2,71],"119":[2,71],"120":[2,71],"121":[2,71],"128":[2,71],"129":[2,71],"131":[2,71],"133":[2,71],"134":[2,71],"136":[2,71],"137":[2,71],"140":[2,71],"141":[2,71],"142":[2,71],"143":[2,71],"144":[2,71],"145":[2,71],"146":[2,71],"147":[2,71],"148":[2,71],"149":[2,71],"150":[2,71],"151":[2,71],"152":[2,71],"153":[2,71],"154":[2,71],"155":[2,71],"156":[2,71],"157":[2,71],"158":[2,71],"159":[2,71],"160":[2,71],"161":[2,71],"162":[2,71],"163":[2,71],"164":[2,71],"165":[2,71]},{"54":[1,256],"59":[1,257]},{"54":[2,62],"59":[2,62],"62":[1,258]},{"54":[2,64],"59":[2,64],"62":[2,64]},{"1":[2,56],"4":[2,56],"29":[2,56],"30":[2,56],"51":[2,56],"59":[2,56],"62":[2,56],"80":[2,56],"85":[2,56],"95":[2,56],"100":[2,56],"108":[2,56],"110":[2,56],"111":[2,56],"112":[2,56],"115":[2,56],"119":[2,56],"120":[2,56],"121":[2,56],"128":[2,56],"129":[2,56],"131":[2,56],"133":[2,56],"134":[2,56],"136":[2,56],"137":[2,56],"140":[2,56],"141":[2,56],"142":[2,56],"143":[2,56],"144":[2,56],"145":[2,56],"146":[2,56],"147":[2,56],"148":[2,56],"149":[2,56],"150":[2,56],"151":[2,56],"152":[2,56],"153":[2,56],"154":[2,56],"155":[2,56],"156":[2,56],"157":[2,56],"158":[2,56],"159":[2,56],"160":[2,56],"161":[2,56],"162":[2,56],"163":[2,56],"164":[2,56],"165":[2,56]},{"28":90,"49":[1,56],"50":[1,57]},{"1":[2,177],"4":[2,177],"29":[2,177],"30":[2,177],"51":[1,116],"59":[2,177],"62":[2,177],"80":[2,177],"85":[2,177],"95":[2,177],"100":[2,177],"108":[2,177],"109":131,"110":[2,177],"111":[2,177],"112":[2,177],"115":[2,177],"119":[2,177],"120":[2,177],"121":[2,177],"128":[2,177],"129":[2,177],"133":[2,177],"134":[2,177],"140":[2,177],"141":[2,177],"142":[2,177],"143":[2,177],"144":[2,177],"145":[2,177],"146":[2,177],"147":[2,177],"148":[2,177],"149":[2,177],"150":[2,177],"151":[2,177],"152":[2,177],"153":[2,177],"154":[2,177],"155":[2,177],"156":[2,177],"157":[2,177],"158":[2,177],"159":[2,177],"160":[2,177],"161":[2,177],"162":[2,177],"163":[2,177],"164":[2,177],"165":[2,177]},{"109":136,"110":[1,79],"112":[1,80],"115":[1,137],"128":[1,134],"129":[1,135]},{"1":[2,178],"4":[2,178],"29":[2,178],"30":[2,178],"51":[1,116],"59":[2,178],"62":[2,178],"80":[2,178],"85":[2,178],"95":[2,178],"100":[2,178],"108":[2,178],"109":131,"110":[2,178],"111":[2,178],"112":[2,178],"115":[2,178],"119":[2,178],"120":[2,178],"121":[2,178],"128":[2,178],"129":[2,178],"133":[2,178],"134":[2,178],"140":[2,178],"141":[2,178],"142":[2,178],"143":[2,178],"144":[2,178],"145":[2,178],"146":[2,178],"147":[2,178],"148":[2,178],"149":[2,178],"150":[2,178],"151":[2,178],"152":[2,178],"153":[2,178],"154":[2,178],"155":[2,178],"156":[2,178],"157":[2,178],"158":[2,178],"159":[2,178],"160":[2,178],"161":[2,178],"162":[2,178],"163":[2,178],"164":[2,178],"165":[2,178]},{"1":[2,179],"4":[2,179],"29":[2,179],"30":[2,179],"51":[1,116],"59":[2,179],"62":[2,179],"80":[2,179],"85":[2,179],"95":[2,179],"100":[2,179],"108":[2,179],"109":131,"110":[2,179],"111":[2,179],"112":[2,179],"115":[2,179],"119":[2,179],"120":[2,179],"121":[2,179],"128":[2,179],"129":[2,179],"133":[2,179],"134":[2,179],"140":[2,179],"141":[2,179],"142":[2,179],"143":[2,179],"144":[2,179],"145":[2,179],"146":[2,179],"147":[2,179],"148":[2,179],"149":[2,179],"150":[2,179],"151":[2,179],"152":[2,179],"153":[2,179],"154":[2,179],"155":[2,179],"156":[2,179],"157":[2,179],"158":[2,179],"159":[2,179],"160":[2,179],"161":[2,179],"162":[2,179],"163":[2,179],"164":[2,179],"165":[2,179]},{"1":[2,180],"4":[2,180],"29":[2,180],"30":[2,180],"51":[1,116],"59":[2,180],"62":[2,180],"80":[2,180],"85":[2,180],"95":[2,180],"100":[2,180],"108":[2,180],"109":131,"110":[2,180],"111":[2,180],"112":[2,180],"115":[2,180],"119":[2,180],"120":[2,180],"121":[2,180],"128":[2,180],"129":[2,180],"133":[2,180],"134":[2,180],"140":[2,180],"141":[2,180],"142":[2,180],"143":[2,180],"144":[2,180],"145":[2,180],"146":[2,180],"147":[2,180],"148":[2,180],"149":[2,180],"150":[2,180],"151":[2,180],"152":[2,180],"153":[2,180],"154":[2,180],"155":[2,180],"156":[2,180],"157":[2,180],"158":[2,180],"159":[2,180],"160":[2,180],"161":[2,180],"162":[2,180],"163":[2,180],"164":[2,180],"165":[2,180]},{"1":[2,181],"4":[2,181],"29":[2,181],"30":[2,181],"51":[1,116],"59":[2,181],"62":[2,181],"80":[2,181],"85":[2,181],"95":[2,181],"100":[2,181],"108":[2,181],"109":131,"110":[2,181],"111":[2,181],"112":[2,181],"115":[2,181],"119":[2,181],"120":[2,181],"121":[2,181],"128":[2,181],"129":[2,181],"133":[2,181],"134":[2,181],"140":[2,181],"141":[2,181],"142":[2,181],"143":[2,181],"144":[2,181],"145":[2,181],"146":[2,181],"147":[2,181],"148":[2,181],"149":[2,181],"150":[2,181],"151":[2,181],"152":[2,181],"153":[2,181],"154":[2,181],"155":[2,181],"156":[2,181],"157":[2,181],"158":[2,181],"159":[2,181],"160":[2,181],"161":[2,181],"162":[2,181],"163":[2,181],"164":[2,181],"165":[2,181]},{"1":[2,182],"4":[2,182],"29":[2,182],"30":[2,182],"51":[1,116],"59":[2,182],"62":[2,182],"80":[2,182],"85":[2,182],"95":[2,182],"100":[2,182],"108":[2,182],"109":131,"110":[2,182],"111":[2,182],"112":[2,182],"115":[2,182],"119":[2,182],"120":[2,182],"121":[2,182],"128":[2,182],"129":[2,182],"133":[2,182],"134":[2,182],"140":[2,182],"141":[2,182],"142":[2,182],"143":[2,182],"144":[2,182],"145":[2,182],"146":[2,182],"147":[2,182],"148":[2,182],"149":[2,182],"150":[2,182],"151":[2,182],"152":[2,182],"153":[2,182],"154":[2,182],"155":[2,182],"156":[2,182],"157":[2,182],"158":[2,182],"159":[2,182],"160":[2,182],"161":[2,182],"162":[2,182],"163":[2,182],"164":[2,182],"165":[2,182]},{"1":[2,183],"4":[2,183],"29":[2,183],"30":[2,183],"51":[1,116],"59":[2,183],"62":[2,183],"80":[2,183],"85":[2,183],"95":[2,183],"100":[2,183],"108":[2,183],"109":131,"110":[2,183],"111":[2,183],"112":[2,183],"115":[2,183],"119":[2,183],"120":[2,183],"121":[2,183],"128":[2,183],"129":[2,183],"133":[2,183],"134":[2,183],"140":[2,183],"141":[2,183],"142":[2,183],"143":[2,183],"144":[2,183],"145":[2,183],"146":[2,183],"147":[2,183],"148":[2,183],"149":[2,183],"150":[2,183],"151":[2,183],"152":[2,183],"153":[2,183],"154":[2,183],"155":[2,183],"156":[2,183],"157":[2,183],"158":[2,183],"159":[2,183],"160":[2,183],"161":[2,183],"162":[2,183],"163":[2,183],"164":[2,183],"165":[2,183]},{"1":[2,184],"4":[2,184],"29":[2,184],"30":[2,184],"51":[1,116],"59":[2,184],"62":[2,184],"80":[2,184],"85":[2,184],"95":[2,184],"100":[2,184],"108":[2,184],"109":131,"110":[2,184],"111":[2,184],"112":[2,184],"115":[2,184],"119":[2,184],"120":[2,184],"121":[2,184],"128":[2,184],"129":[2,184],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[2,184],"154":[2,184],"155":[2,184],"156":[2,184],"157":[2,184],"158":[2,184],"159":[2,184],"160":[2,184],"161":[2,184],"162":[2,184],"163":[2,184],"164":[2,184],"165":[1,125]},{"1":[2,185],"4":[2,185],"29":[2,185],"30":[2,185],"51":[1,116],"59":[2,185],"62":[2,185],"80":[2,185],"85":[2,185],"95":[2,185],"100":[2,185],"108":[2,185],"109":131,"110":[2,185],"111":[2,185],"112":[2,185],"115":[2,185],"119":[2,185],"120":[2,185],"121":[2,185],"128":[2,185],"129":[2,185],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[2,185],"154":[2,185],"155":[2,185],"156":[2,185],"157":[2,185],"158":[2,185],"159":[2,185],"160":[2,185],"161":[2,185],"162":[2,185],"163":[2,185],"164":[2,185],"165":[1,125]},{"103":259,"104":[1,260],"105":[1,261]},{"1":[2,137],"4":[2,137],"29":[2,137],"30":[2,137],"51":[2,137],"59":[2,137],"62":[2,137],"80":[2,137],"85":[2,137],"95":[2,137],"100":[2,137],"108":[2,137],"110":[2,137],"111":[2,137],"112":[2,137],"115":[2,137],"119":[2,137],"120":[2,137],"121":[2,137],"128":[2,137],"129":[2,137],"131":[2,137],"133":[2,137],"134":[2,137],"136":[2,137],"137":[2,137],"140":[2,137],"141":[2,137],"142":[2,137],"143":[2,137],"144":[2,137],"145":[2,137],"146":[2,137],"147":[2,137],"148":[2,137],"149":[2,137],"150":[2,137],"151":[2,137],"152":[2,137],"153":[2,137],"154":[2,137],"155":[2,137],"156":[2,137],"157":[2,137],"158":[2,137],"159":[2,137],"160":[2,137],"161":[2,137],"162":[2,137],"163":[2,137],"164":[2,137],"165":[2,137]},{"117":262,"119":[1,263],"120":[1,264]},{"59":[1,265],"119":[2,149],"120":[2,149]},{"59":[2,146],"119":[2,146],"120":[2,146]},{"59":[2,147],"119":[2,147],"120":[2,147]},{"59":[2,148],"119":[2,148],"120":[2,148]},{"4":[2,120],"8":247,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"29":[2,120],"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"59":[2,120],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"94":189,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"100":[2,120],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"29":[1,266],"51":[1,116],"62":[1,133],"109":131,"110":[1,79],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"128":[1,129],"129":[1,130],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"28":270,"49":[1,56],"50":[1,57],"123":267,"125":268,"126":[1,269]},{"14":271,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":155,"63":156,"65":184,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"97":[1,73],"98":[1,74],"99":[1,72],"107":[1,71]},{"1":[2,95],"4":[2,95],"29":[1,273],"30":[2,95],"51":[2,95],"59":[2,95],"62":[2,95],"73":[2,71],"74":[2,71],"75":[2,71],"76":[2,71],"79":[2,71],"80":[2,95],"81":[2,71],"82":[2,71],"85":[2,95],"87":[1,272],"93":[2,71],"95":[2,95],"100":[2,95],"108":[2,95],"110":[2,95],"111":[2,95],"112":[2,95],"115":[2,95],"119":[2,95],"120":[2,95],"121":[2,95],"128":[2,95],"129":[2,95],"131":[2,95],"133":[2,95],"134":[2,95],"136":[2,95],"137":[2,95],"140":[2,95],"141":[2,95],"142":[2,95],"143":[2,95],"144":[2,95],"145":[2,95],"146":[2,95],"147":[2,95],"148":[2,95],"149":[2,95],"150":[2,95],"151":[2,95],"152":[2,95],"153":[2,95],"154":[2,95],"155":[2,95],"156":[2,95],"157":[2,95],"158":[2,95],"159":[2,95],"160":[2,95],"161":[2,95],"162":[2,95],"163":[2,95],"164":[2,95],"165":[2,95]},{"64":152,"73":[1,141],"74":[1,142],"75":[1,143],"76":[1,144],"77":145,"78":146,"79":[1,147],"81":[1,148],"82":[1,149],"92":151,"93":[1,140]},{"1":[2,50],"4":[2,50],"30":[2,50],"51":[1,116],"62":[1,133],"108":[2,50],"109":131,"110":[1,79],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"128":[2,50],"129":[2,50],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"1":[2,131],"4":[2,131],"30":[2,131],"51":[1,116],"62":[1,133],"108":[2,131],"109":131,"110":[2,131],"112":[2,131],"115":[2,131],"119":[1,126],"120":[1,127],"128":[2,131],"129":[2,131],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"108":[1,274]},{"4":[2,121],"29":[2,121],"51":[1,116],"59":[2,121],"62":[1,275],"100":[2,121],"109":131,"110":[1,79],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"128":[1,129],"129":[1,130],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"4":[2,59],"29":[2,59],"58":276,"59":[1,277],"100":[2,59]},{"1":[2,114],"4":[2,114],"29":[2,114],"30":[2,114],"46":[2,114],"51":[2,114],"59":[2,114],"62":[2,114],"73":[2,114],"74":[2,114],"75":[2,114],"76":[2,114],"79":[2,114],"80":[2,114],"81":[2,114],"82":[2,114],"85":[2,114],"87":[2,114],"93":[2,114],"95":[2,114],"100":[2,114],"108":[2,114],"110":[2,114],"111":[2,114],"112":[2,114],"115":[2,114],"119":[2,114],"120":[2,114],"121":[2,114],"128":[2,114],"129":[2,114],"131":[2,114],"133":[2,114],"134":[2,114],"136":[2,114],"137":[2,114],"140":[2,114],"141":[2,114],"142":[2,114],"143":[2,114],"144":[2,114],"145":[2,114],"146":[2,114],"147":[2,114],"148":[2,114],"149":[2,114],"150":[2,114],"151":[2,114],"152":[2,114],"153":[2,114],"154":[2,114],"155":[2,114],"156":[2,114],"157":[2,114],"158":[2,114],"159":[2,114],"160":[2,114],"161":[2,114],"162":[2,114],"163":[2,114],"164":[2,114],"165":[2,114]},{"4":[2,120],"8":247,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"29":[2,120],"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"59":[2,120],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"94":278,"95":[2,120],"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"4":[1,161],"6":279,"29":[1,6],"128":[1,280]},{"1":[2,133],"4":[2,133],"29":[2,133],"30":[2,133],"51":[1,116],"59":[2,133],"62":[1,133],"80":[2,133],"85":[2,133],"95":[2,133],"100":[2,133],"108":[2,133],"109":131,"110":[1,79],"111":[1,281],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"121":[2,133],"128":[2,133],"129":[2,133],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"1":[2,135],"4":[2,135],"29":[2,135],"30":[2,135],"51":[1,116],"59":[2,135],"62":[1,133],"80":[2,135],"85":[2,135],"95":[2,135],"100":[2,135],"108":[2,135],"109":131,"110":[1,79],"111":[1,282],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"121":[2,135],"128":[2,135],"129":[2,135],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"1":[2,141],"4":[2,141],"29":[2,141],"30":[2,141],"51":[2,141],"59":[2,141],"62":[2,141],"80":[2,141],"85":[2,141],"95":[2,141],"100":[2,141],"108":[2,141],"110":[2,141],"111":[2,141],"112":[2,141],"115":[2,141],"119":[2,141],"120":[2,141],"121":[2,141],"128":[2,141],"129":[2,141],"131":[2,141],"133":[2,141],"134":[2,141],"136":[2,141],"137":[2,141],"140":[2,141],"141":[2,141],"142":[2,141],"143":[2,141],"144":[2,141],"145":[2,141],"146":[2,141],"147":[2,141],"148":[2,141],"149":[2,141],"150":[2,141],"151":[2,141],"152":[2,141],"153":[2,141],"154":[2,141],"155":[2,141],"156":[2,141],"157":[2,141],"158":[2,141],"159":[2,141],"160":[2,141],"161":[2,141],"162":[2,141],"163":[2,141],"164":[2,141],"165":[2,141]},{"1":[2,142],"4":[2,142],"29":[2,142],"30":[2,142],"51":[1,116],"59":[2,142],"62":[1,133],"80":[2,142],"85":[2,142],"95":[2,142],"100":[2,142],"108":[2,142],"109":131,"110":[1,79],"111":[2,142],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"121":[2,142],"128":[2,142],"129":[2,142],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"4":[2,59],"29":[2,59],"58":283,"59":[1,284],"85":[2,59]},{"4":[2,91],"29":[2,91],"30":[2,91],"59":[2,91],"85":[2,91]},{"4":[2,45],"29":[2,45],"30":[2,45],"46":[1,285],"59":[2,45],"85":[2,45]},{"4":[2,46],"29":[2,46],"30":[2,46],"46":[1,286],"59":[2,46],"85":[2,46]},{"4":[2,49],"29":[2,49],"30":[2,49],"59":[2,49],"85":[2,49]},{"4":[1,161],"6":287,"29":[1,6],"51":[1,116],"62":[1,133],"109":131,"110":[1,79],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"128":[1,129],"129":[1,130],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"4":[1,161],"6":288,"29":[1,6],"51":[1,116],"62":[1,133],"109":131,"110":[1,79],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"128":[1,129],"129":[1,130],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"1":[2,6],"4":[2,6],"30":[2,6]},{"1":[2,29],"4":[2,29],"29":[2,29],"30":[2,29],"49":[2,29],"50":[2,29],"51":[2,29],"59":[2,29],"62":[2,29],"80":[2,29],"85":[2,29],"95":[2,29],"100":[2,29],"104":[2,29],"105":[2,29],"108":[2,29],"110":[2,29],"111":[2,29],"112":[2,29],"115":[2,29],"119":[2,29],"120":[2,29],"121":[2,29],"124":[2,29],"126":[2,29],"128":[2,29],"129":[2,29],"131":[2,29],"133":[2,29],"134":[2,29],"136":[2,29],"137":[2,29],"140":[2,29],"141":[2,29],"142":[2,29],"143":[2,29],"144":[2,29],"145":[2,29],"146":[2,29],"147":[2,29],"148":[2,29],"149":[2,29],"150":[2,29],"151":[2,29],"152":[2,29],"153":[2,29],"154":[2,29],"155":[2,29],"156":[2,29],"157":[2,29],"158":[2,29],"159":[2,29],"160":[2,29],"161":[2,29],"162":[2,29],"163":[2,29],"164":[2,29],"165":[2,29]},{"1":[2,188],"4":[2,188],"29":[2,188],"30":[2,188],"51":[1,116],"59":[2,188],"62":[2,188],"80":[2,188],"85":[2,188],"95":[2,188],"100":[2,188],"108":[2,188],"109":131,"110":[2,188],"111":[2,188],"112":[2,188],"115":[2,188],"119":[2,188],"120":[2,188],"121":[2,188],"128":[2,188],"129":[2,188],"131":[1,128],"133":[2,188],"134":[2,188],"136":[1,95],"137":[1,96],"140":[2,188],"141":[2,188],"142":[2,188],"143":[2,188],"144":[2,188],"145":[2,188],"146":[2,188],"147":[2,188],"148":[2,188],"149":[2,188],"150":[2,188],"151":[2,188],"152":[2,188],"153":[2,188],"154":[2,188],"155":[2,188],"156":[2,188],"157":[2,188],"158":[2,188],"159":[2,188],"160":[2,188],"161":[2,188],"162":[2,188],"163":[2,188],"164":[2,188],"165":[2,188]},{"1":[2,189],"4":[2,189],"29":[2,189],"30":[2,189],"51":[1,116],"59":[2,189],"62":[2,189],"80":[2,189],"85":[2,189],"95":[2,189],"100":[2,189],"108":[2,189],"109":131,"110":[2,189],"111":[2,189],"112":[2,189],"115":[2,189],"119":[2,189],"120":[2,189],"121":[2,189],"128":[2,189],"129":[2,189],"131":[1,128],"133":[2,189],"134":[2,189],"136":[1,95],"137":[1,96],"140":[2,189],"141":[2,189],"142":[2,189],"143":[2,189],"144":[2,189],"145":[2,189],"146":[2,189],"147":[2,189],"148":[2,189],"149":[2,189],"150":[2,189],"151":[2,189],"152":[2,189],"153":[2,189],"154":[2,189],"155":[2,189],"156":[2,189],"157":[2,189],"158":[2,189],"159":[2,189],"160":[2,189],"161":[2,189],"162":[2,189],"163":[2,189],"164":[2,189],"165":[2,189]},{"1":[2,190],"4":[2,190],"29":[2,190],"30":[2,190],"51":[1,116],"59":[2,190],"62":[2,190],"80":[2,190],"85":[2,190],"95":[2,190],"100":[2,190],"108":[2,190],"109":131,"110":[2,190],"111":[2,190],"112":[2,190],"115":[2,190],"119":[2,190],"120":[2,190],"121":[2,190],"128":[2,190],"129":[2,190],"131":[1,128],"133":[2,190],"134":[2,190],"136":[1,95],"137":[1,96],"140":[2,190],"141":[2,190],"142":[2,190],"143":[2,190],"144":[2,190],"145":[2,190],"146":[2,190],"147":[2,190],"148":[2,190],"149":[2,190],"150":[2,190],"151":[2,190],"152":[2,190],"153":[2,190],"154":[2,190],"155":[2,190],"156":[2,190],"157":[2,190],"158":[2,190],"159":[2,190],"160":[2,190],"161":[2,190],"162":[2,190],"163":[2,190],"164":[2,190],"165":[2,190]},{"1":[2,191],"4":[2,191],"29":[2,191],"30":[2,191],"51":[1,116],"59":[2,191],"62":[2,191],"80":[2,191],"85":[2,191],"95":[2,191],"100":[2,191],"108":[2,191],"109":131,"110":[2,191],"111":[2,191],"112":[2,191],"115":[2,191],"119":[2,191],"120":[2,191],"121":[2,191],"128":[2,191],"129":[2,191],"131":[1,128],"133":[2,191],"134":[2,191],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[2,191],"144":[2,191],"145":[2,191],"146":[2,191],"147":[2,191],"148":[2,191],"149":[2,191],"150":[2,191],"151":[2,191],"152":[2,191],"153":[2,191],"154":[2,191],"155":[2,191],"156":[2,191],"157":[2,191],"158":[2,191],"159":[2,191],"160":[2,191],"161":[2,191],"162":[2,191],"163":[2,191],"164":[2,191],"165":[2,191]},{"1":[2,192],"4":[2,192],"29":[2,192],"30":[2,192],"51":[1,116],"59":[2,192],"62":[2,192],"80":[2,192],"85":[2,192],"95":[2,192],"100":[2,192],"108":[2,192],"109":131,"110":[2,192],"111":[2,192],"112":[2,192],"115":[2,192],"119":[2,192],"120":[2,192],"121":[2,192],"128":[2,192],"129":[2,192],"131":[1,128],"133":[2,192],"134":[2,192],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[2,192],"144":[2,192],"145":[2,192],"146":[2,192],"147":[2,192],"148":[2,192],"149":[2,192],"150":[2,192],"151":[2,192],"152":[2,192],"153":[2,192],"154":[2,192],"155":[2,192],"156":[2,192],"157":[2,192],"158":[2,192],"159":[2,192],"160":[2,192],"161":[2,192],"162":[2,192],"163":[2,192],"164":[2,192],"165":[2,192]},{"1":[2,193],"4":[2,193],"29":[2,193],"30":[2,193],"51":[1,116],"59":[2,193],"62":[2,193],"80":[2,193],"85":[2,193],"95":[2,193],"100":[2,193],"108":[2,193],"109":131,"110":[2,193],"111":[2,193],"112":[2,193],"115":[2,193],"119":[2,193],"120":[2,193],"121":[2,193],"128":[2,193],"129":[2,193],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[2,193],"144":[2,193],"145":[2,193],"146":[2,193],"147":[2,193],"148":[2,193],"149":[2,193],"150":[2,193],"151":[2,193],"152":[2,193],"153":[2,193],"154":[2,193],"155":[2,193],"156":[2,193],"157":[2,193],"158":[2,193],"159":[2,193],"160":[2,193],"161":[2,193],"162":[2,193],"163":[2,193],"164":[2,193],"165":[2,193]},{"1":[2,194],"4":[2,194],"29":[2,194],"30":[2,194],"51":[1,116],"59":[2,194],"62":[2,194],"80":[2,194],"85":[2,194],"95":[2,194],"100":[2,194],"108":[2,194],"109":131,"110":[2,194],"111":[2,194],"112":[2,194],"115":[2,194],"119":[2,194],"120":[2,194],"121":[2,194],"128":[2,194],"129":[2,194],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[2,194],"144":[2,194],"145":[2,194],"146":[2,194],"147":[2,194],"148":[2,194],"149":[2,194],"150":[2,194],"151":[2,194],"152":[2,194],"153":[2,194],"154":[2,194],"155":[2,194],"156":[2,194],"157":[2,194],"158":[2,194],"159":[2,194],"160":[2,194],"161":[2,194],"162":[2,194],"163":[2,194],"164":[2,194],"165":[2,194]},{"1":[2,195],"4":[2,195],"29":[2,195],"30":[2,195],"51":[1,116],"59":[2,195],"62":[2,195],"80":[2,195],"85":[2,195],"95":[2,195],"100":[2,195],"108":[2,195],"109":131,"110":[2,195],"111":[2,195],"112":[2,195],"115":[2,195],"119":[2,195],"120":[2,195],"121":[2,195],"128":[2,195],"129":[2,195],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[2,195],"144":[2,195],"145":[2,195],"146":[2,195],"147":[2,195],"148":[2,195],"149":[2,195],"150":[2,195],"151":[2,195],"152":[2,195],"153":[2,195],"154":[2,195],"155":[2,195],"156":[2,195],"157":[2,195],"158":[2,195],"159":[2,195],"160":[2,195],"161":[2,195],"162":[2,195],"163":[2,195],"164":[2,195],"165":[2,195]},{"1":[2,196],"4":[2,196],"29":[2,196],"30":[2,196],"51":[1,116],"59":[2,196],"62":[2,196],"80":[2,196],"85":[2,196],"95":[2,196],"100":[2,196],"108":[2,196],"109":131,"110":[2,196],"111":[2,196],"112":[2,196],"115":[2,196],"119":[2,196],"120":[2,196],"121":[2,196],"128":[2,196],"129":[2,196],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[2,196],"147":[2,196],"148":[2,196],"149":[2,196],"150":[2,196],"151":[2,196],"152":[2,196],"153":[2,196],"154":[2,196],"155":[2,196],"156":[2,196],"157":[2,196],"158":[2,196],"159":[2,196],"160":[2,196],"161":[2,196],"162":[2,196],"163":[2,196],"164":[2,196],"165":[2,196]},{"1":[2,197],"4":[2,197],"29":[2,197],"30":[2,197],"51":[1,116],"59":[2,197],"62":[2,197],"80":[2,197],"85":[2,197],"95":[2,197],"100":[2,197],"108":[2,197],"109":131,"110":[2,197],"111":[2,197],"112":[2,197],"115":[2,197],"119":[2,197],"120":[2,197],"121":[2,197],"128":[2,197],"129":[2,197],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[2,197],"147":[2,197],"148":[2,197],"149":[2,197],"150":[2,197],"151":[2,197],"152":[2,197],"153":[2,197],"154":[2,197],"155":[2,197],"156":[2,197],"157":[2,197],"158":[2,197],"159":[2,197],"160":[2,197],"161":[2,197],"162":[2,197],"163":[2,197],"164":[2,197],"165":[2,197]},{"1":[2,198],"4":[2,198],"29":[2,198],"30":[2,198],"51":[1,116],"59":[2,198],"62":[2,198],"80":[2,198],"85":[2,198],"95":[2,198],"100":[2,198],"108":[2,198],"109":131,"110":[2,198],"111":[2,198],"112":[2,198],"115":[2,198],"119":[2,198],"120":[2,198],"121":[2,198],"128":[2,198],"129":[2,198],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[2,198],"147":[2,198],"148":[2,198],"149":[2,198],"150":[2,198],"151":[2,198],"152":[2,198],"153":[2,198],"154":[2,198],"155":[2,198],"156":[2,198],"157":[2,198],"158":[2,198],"159":[2,198],"160":[2,198],"161":[2,198],"162":[2,198],"163":[2,198],"164":[2,198],"165":[2,198]},{"1":[2,199],"4":[2,199],"29":[2,199],"30":[2,199],"51":[1,116],"59":[2,199],"62":[2,199],"80":[2,199],"85":[2,199],"95":[2,199],"100":[2,199],"108":[2,199],"109":131,"110":[2,199],"111":[2,199],"112":[2,199],"115":[2,199],"119":[2,199],"120":[2,199],"121":[2,199],"128":[2,199],"129":[2,199],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[2,199],"150":[2,199],"151":[2,199],"152":[2,199],"153":[2,199],"154":[2,199],"155":[2,199],"156":[2,199],"157":[2,199],"158":[2,199],"159":[2,199],"160":[2,199],"161":[2,199],"162":[2,199],"163":[2,199],"164":[2,199],"165":[2,199]},{"1":[2,200],"4":[2,200],"29":[2,200],"30":[2,200],"51":[1,116],"59":[2,200],"62":[2,200],"80":[2,200],"85":[2,200],"95":[2,200],"100":[2,200],"108":[2,200],"109":131,"110":[2,200],"111":[2,200],"112":[2,200],"115":[2,200],"119":[2,200],"120":[2,200],"121":[2,200],"128":[2,200],"129":[2,200],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[2,200],"150":[2,200],"151":[2,200],"152":[2,200],"153":[2,200],"154":[2,200],"155":[2,200],"156":[2,200],"157":[2,200],"158":[2,200],"159":[2,200],"160":[2,200],"161":[2,200],"162":[2,200],"163":[2,200],"164":[2,200],"165":[2,200]},{"1":[2,201],"4":[2,201],"29":[2,201],"30":[2,201],"51":[1,116],"59":[2,201],"62":[2,201],"80":[2,201],"85":[2,201],"95":[2,201],"100":[2,201],"108":[2,201],"109":131,"110":[2,201],"111":[2,201],"112":[2,201],"115":[2,201],"119":[2,201],"120":[2,201],"121":[2,201],"128":[2,201],"129":[2,201],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[2,201],"150":[2,201],"151":[2,201],"152":[2,201],"153":[2,201],"154":[2,201],"155":[2,201],"156":[2,201],"157":[2,201],"158":[2,201],"159":[2,201],"160":[2,201],"161":[2,201],"162":[2,201],"163":[2,201],"164":[2,201],"165":[2,201]},{"1":[2,202],"4":[2,202],"29":[2,202],"30":[2,202],"51":[1,116],"59":[2,202],"62":[2,202],"80":[2,202],"85":[2,202],"95":[2,202],"100":[2,202],"108":[2,202],"109":131,"110":[2,202],"111":[2,202],"112":[2,202],"115":[2,202],"119":[2,202],"120":[2,202],"121":[2,202],"128":[2,202],"129":[2,202],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[2,202],"150":[2,202],"151":[2,202],"152":[2,202],"153":[2,202],"154":[2,202],"155":[2,202],"156":[2,202],"157":[2,202],"158":[2,202],"159":[2,202],"160":[2,202],"161":[2,202],"162":[2,202],"163":[2,202],"164":[2,202],"165":[2,202]},{"1":[2,203],"4":[2,203],"29":[2,203],"30":[2,203],"51":[1,116],"59":[2,203],"62":[2,203],"80":[2,203],"85":[2,203],"95":[2,203],"100":[2,203],"108":[2,203],"109":131,"110":[2,203],"111":[2,203],"112":[2,203],"115":[2,203],"119":[2,203],"120":[2,203],"121":[2,203],"128":[2,203],"129":[2,203],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[2,203],"154":[2,203],"155":[2,203],"156":[2,203],"157":[2,203],"158":[2,203],"159":[2,203],"160":[2,203],"161":[2,203],"162":[2,203],"163":[2,203],"164":[2,203],"165":[1,125]},{"1":[2,204],"4":[2,204],"29":[2,204],"30":[2,204],"51":[1,116],"59":[2,204],"62":[2,204],"80":[2,204],"85":[2,204],"95":[2,204],"100":[2,204],"108":[2,204],"109":131,"110":[2,204],"111":[2,204],"112":[2,204],"115":[2,204],"119":[2,204],"120":[2,204],"121":[2,204],"128":[2,204],"129":[2,204],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[2,204],"154":[2,204],"155":[2,204],"156":[2,204],"157":[2,204],"158":[2,204],"159":[2,204],"160":[2,204],"161":[2,204],"162":[2,204],"163":[2,204],"164":[2,204],"165":[1,125]},{"1":[2,205],"4":[2,205],"29":[2,205],"30":[2,205],"51":[1,116],"59":[2,205],"62":[2,205],"80":[2,205],"85":[2,205],"95":[2,205],"100":[2,205],"108":[2,205],"109":131,"110":[2,205],"111":[2,205],"112":[2,205],"115":[2,205],"119":[2,205],"120":[2,205],"121":[2,205],"128":[2,205],"129":[2,205],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[2,205],"156":[2,205],"157":[2,205],"158":[2,205],"159":[2,205],"160":[2,205],"161":[2,205],"162":[2,205],"163":[2,205],"164":[2,205],"165":[1,125]},{"1":[2,206],"4":[2,206],"29":[2,206],"30":[2,206],"51":[1,116],"59":[2,206],"62":[2,206],"80":[2,206],"85":[2,206],"95":[2,206],"100":[2,206],"108":[2,206],"109":131,"110":[2,206],"111":[2,206],"112":[2,206],"115":[2,206],"119":[2,206],"120":[2,206],"121":[2,206],"128":[2,206],"129":[2,206],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[2,206],"156":[2,206],"157":[2,206],"158":[2,206],"159":[2,206],"160":[2,206],"161":[2,206],"162":[2,206],"163":[2,206],"164":[2,206],"165":[1,125]},{"1":[2,207],"4":[2,207],"29":[2,207],"30":[2,207],"51":[2,207],"59":[2,207],"62":[2,207],"80":[2,207],"85":[2,207],"95":[2,207],"100":[2,207],"108":[2,207],"109":131,"110":[2,207],"111":[2,207],"112":[2,207],"115":[2,207],"119":[2,207],"120":[2,207],"121":[2,207],"128":[2,207],"129":[2,207],"131":[2,207],"133":[2,207],"134":[2,207],"136":[2,207],"137":[2,207],"140":[2,207],"141":[2,207],"142":[2,207],"143":[2,207],"144":[2,207],"145":[2,207],"146":[2,207],"147":[2,207],"148":[2,207],"149":[2,207],"150":[2,207],"151":[2,207],"152":[2,207],"153":[2,207],"154":[2,207],"155":[2,207],"156":[2,207],"157":[2,207],"158":[2,207],"159":[2,207],"160":[2,207],"161":[2,207],"162":[2,207],"163":[2,207],"164":[2,207],"165":[2,207]},{"1":[2,208],"4":[2,208],"29":[2,208],"30":[2,208],"51":[1,116],"59":[2,208],"62":[2,208],"80":[2,208],"85":[2,208],"95":[2,208],"100":[2,208],"108":[2,208],"109":131,"110":[2,208],"111":[2,208],"112":[2,208],"115":[2,208],"119":[2,208],"120":[2,208],"121":[2,208],"128":[2,208],"129":[2,208],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"1":[2,209],"4":[2,209],"29":[2,209],"30":[2,209],"51":[1,116],"59":[2,209],"62":[2,209],"80":[2,209],"85":[2,209],"95":[2,209],"100":[2,209],"108":[2,209],"109":131,"110":[2,209],"111":[2,209],"112":[2,209],"115":[2,209],"119":[2,209],"120":[2,209],"121":[2,209],"128":[2,209],"129":[2,209],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"1":[2,210],"4":[2,210],"29":[2,210],"30":[2,210],"51":[1,116],"59":[2,210],"62":[2,210],"80":[2,210],"85":[2,210],"95":[2,210],"100":[2,210],"108":[2,210],"109":131,"110":[2,210],"111":[2,210],"112":[2,210],"115":[2,210],"119":[2,210],"120":[2,210],"121":[2,210],"128":[2,210],"129":[2,210],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"1":[2,211],"4":[2,211],"29":[2,211],"30":[2,211],"51":[1,116],"59":[2,211],"62":[2,211],"80":[2,211],"85":[2,211],"95":[2,211],"100":[2,211],"108":[2,211],"109":131,"110":[2,211],"111":[2,211],"112":[2,211],"115":[2,211],"119":[2,211],"120":[2,211],"121":[2,211],"128":[2,211],"129":[2,211],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"1":[2,212],"4":[2,212],"29":[2,212],"30":[2,212],"51":[1,116],"59":[2,212],"62":[2,212],"80":[2,212],"85":[2,212],"95":[2,212],"100":[2,212],"108":[2,212],"109":131,"110":[2,212],"111":[2,212],"112":[2,212],"115":[2,212],"119":[2,212],"120":[2,212],"121":[2,212],"128":[2,212],"129":[2,212],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"1":[2,213],"4":[2,213],"29":[2,213],"30":[2,213],"51":[1,116],"59":[2,213],"62":[2,213],"80":[2,213],"85":[2,213],"95":[2,213],"100":[2,213],"108":[2,213],"109":131,"110":[2,213],"111":[2,213],"112":[2,213],"115":[2,213],"119":[2,213],"120":[2,213],"121":[2,213],"128":[2,213],"129":[2,213],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"1":[2,214],"4":[2,214],"29":[2,214],"30":[2,214],"51":[1,116],"59":[2,214],"62":[2,214],"80":[2,214],"85":[2,214],"95":[2,214],"100":[2,214],"108":[2,214],"109":131,"110":[2,214],"111":[2,214],"112":[2,214],"115":[2,214],"119":[2,214],"120":[2,214],"121":[2,214],"128":[2,214],"129":[2,214],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"1":[2,215],"4":[2,215],"29":[2,215],"30":[2,215],"51":[1,116],"59":[2,215],"62":[2,215],"80":[2,215],"85":[2,215],"95":[2,215],"100":[2,215],"108":[2,215],"109":131,"110":[2,215],"111":[2,215],"112":[2,215],"115":[2,215],"119":[2,215],"120":[2,215],"121":[2,215],"128":[2,215],"129":[2,215],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"1":[2,216],"4":[2,216],"29":[2,216],"30":[2,216],"51":[1,116],"59":[2,216],"62":[2,216],"80":[2,216],"85":[2,216],"95":[2,216],"100":[2,216],"108":[2,216],"109":131,"110":[2,216],"111":[2,216],"112":[2,216],"115":[2,216],"119":[2,216],"120":[2,216],"121":[2,216],"128":[2,216],"129":[2,216],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[2,216],"154":[2,216],"155":[2,216],"156":[2,216],"157":[2,216],"158":[2,216],"159":[2,216],"160":[2,216],"161":[2,216],"162":[2,216],"163":[2,216],"164":[2,216],"165":[1,125]},{"1":[2,217],"4":[2,217],"29":[2,217],"30":[2,217],"51":[1,116],"59":[2,217],"62":[1,133],"80":[2,217],"85":[2,217],"95":[2,217],"100":[2,217],"108":[2,217],"109":131,"110":[2,217],"111":[2,217],"112":[2,217],"115":[2,217],"119":[1,126],"120":[1,127],"121":[2,217],"128":[2,217],"129":[2,217],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"1":[2,218],"4":[2,218],"29":[2,218],"30":[2,218],"51":[1,116],"59":[2,218],"62":[1,133],"80":[2,218],"85":[2,218],"95":[2,218],"100":[2,218],"108":[2,218],"109":131,"110":[2,218],"111":[2,218],"112":[2,218],"115":[2,218],"119":[1,126],"120":[1,127],"121":[2,218],"128":[2,218],"129":[2,218],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"8":289,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":290,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"1":[2,174],"4":[2,174],"29":[2,174],"30":[2,174],"51":[1,116],"59":[2,174],"62":[1,133],"80":[2,174],"85":[2,174],"95":[2,174],"100":[2,174],"108":[2,174],"109":131,"110":[1,79],"111":[2,174],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"121":[2,174],"128":[1,129],"129":[1,130],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"1":[2,176],"4":[2,176],"29":[2,176],"30":[2,176],"51":[1,116],"59":[2,176],"62":[1,133],"80":[2,176],"85":[2,176],"95":[2,176],"100":[2,176],"108":[2,176],"109":131,"110":[1,79],"111":[2,176],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"121":[2,176],"128":[1,129],"129":[1,130],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"117":291,"119":[1,263],"120":[1,264]},{"62":[1,292]},{"1":[2,173],"4":[2,173],"29":[2,173],"30":[2,173],"51":[1,116],"59":[2,173],"62":[1,133],"80":[2,173],"85":[2,173],"95":[2,173],"100":[2,173],"108":[2,173],"109":131,"110":[1,79],"111":[2,173],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"121":[2,173],"128":[1,129],"129":[1,130],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"1":[2,175],"4":[2,175],"29":[2,175],"30":[2,175],"51":[1,116],"59":[2,175],"62":[1,133],"80":[2,175],"85":[2,175],"95":[2,175],"100":[2,175],"108":[2,175],"109":131,"110":[1,79],"111":[2,175],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"121":[2,175],"128":[1,129],"129":[1,130],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"117":293,"119":[1,263],"120":[1,264]},{"4":[2,59],"29":[2,59],"58":294,"59":[1,277],"95":[2,59]},{"4":[2,121],"29":[2,121],"30":[2,121],"51":[1,116],"59":[2,121],"62":[1,133],"95":[2,121],"100":[2,121],"109":131,"110":[1,79],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"128":[1,129],"129":[1,130],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"1":[2,80],"4":[2,80],"29":[2,80],"30":[2,80],"46":[2,80],"51":[2,80],"59":[2,80],"62":[2,80],"73":[2,80],"74":[2,80],"75":[2,80],"76":[2,80],"79":[2,80],"80":[2,80],"81":[2,80],"82":[2,80],"85":[2,80],"87":[2,80],"93":[2,80],"95":[2,80],"100":[2,80],"108":[2,80],"110":[2,80],"111":[2,80],"112":[2,80],"115":[2,80],"119":[2,80],"120":[2,80],"121":[2,80],"128":[2,80],"129":[2,80],"131":[2,80],"133":[2,80],"134":[2,80],"136":[2,80],"137":[2,80],"140":[2,80],"141":[2,80],"142":[2,80],"143":[2,80],"144":[2,80],"145":[2,80],"146":[2,80],"147":[2,80],"148":[2,80],"149":[2,80],"150":[2,80],"151":[2,80],"152":[2,80],"153":[2,80],"154":[2,80],"155":[2,80],"156":[2,80],"157":[2,80],"158":[2,80],"159":[2,80],"160":[2,80],"161":[2,80],"162":[2,80],"163":[2,80],"164":[2,80],"165":[2,80]},{"1":[2,81],"4":[2,81],"29":[2,81],"30":[2,81],"46":[2,81],"51":[2,81],"59":[2,81],"62":[2,81],"73":[2,81],"74":[2,81],"75":[2,81],"76":[2,81],"79":[2,81],"80":[2,81],"81":[2,81],"82":[2,81],"85":[2,81],"87":[2,81],"93":[2,81],"95":[2,81],"100":[2,81],"108":[2,81],"110":[2,81],"111":[2,81],"112":[2,81],"115":[2,81],"119":[2,81],"120":[2,81],"121":[2,81],"128":[2,81],"129":[2,81],"131":[2,81],"133":[2,81],"134":[2,81],"136":[2,81],"137":[2,81],"140":[2,81],"141":[2,81],"142":[2,81],"143":[2,81],"144":[2,81],"145":[2,81],"146":[2,81],"147":[2,81],"148":[2,81],"149":[2,81],"150":[2,81],"151":[2,81],"152":[2,81],"153":[2,81],"154":[2,81],"155":[2,81],"156":[2,81],"157":[2,81],"158":[2,81],"159":[2,81],"160":[2,81],"161":[2,81],"162":[2,81],"163":[2,81],"164":[2,81],"165":[2,81]},{"1":[2,83],"4":[2,83],"29":[2,83],"30":[2,83],"46":[2,83],"51":[2,83],"59":[2,83],"62":[2,83],"73":[2,83],"74":[2,83],"75":[2,83],"76":[2,83],"79":[2,83],"80":[2,83],"81":[2,83],"82":[2,83],"85":[2,83],"87":[2,83],"93":[2,83],"95":[2,83],"100":[2,83],"108":[2,83],"110":[2,83],"111":[2,83],"112":[2,83],"115":[2,83],"119":[2,83],"120":[2,83],"121":[2,83],"128":[2,83],"129":[2,83],"131":[2,83],"133":[2,83],"134":[2,83],"136":[2,83],"137":[2,83],"140":[2,83],"141":[2,83],"142":[2,83],"143":[2,83],"144":[2,83],"145":[2,83],"146":[2,83],"147":[2,83],"148":[2,83],"149":[2,83],"150":[2,83],"151":[2,83],"152":[2,83],"153":[2,83],"154":[2,83],"155":[2,83],"156":[2,83],"157":[2,83],"158":[2,83],"159":[2,83],"160":[2,83],"161":[2,83],"162":[2,83],"163":[2,83],"164":[2,83],"165":[2,83]},{"51":[1,116],"62":[1,296],"80":[1,295],"109":131,"110":[1,79],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"128":[1,129],"129":[1,130],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"1":[2,87],"4":[2,87],"29":[2,87],"30":[2,87],"46":[2,87],"51":[2,87],"59":[2,87],"62":[2,87],"73":[2,87],"74":[2,87],"75":[2,87],"76":[2,87],"79":[2,87],"80":[2,87],"81":[2,87],"82":[2,87],"85":[2,87],"87":[2,87],"93":[2,87],"95":[2,87],"100":[2,87],"108":[2,87],"110":[2,87],"111":[2,87],"112":[2,87],"115":[2,87],"119":[2,87],"120":[2,87],"121":[2,87],"128":[2,87],"129":[2,87],"131":[2,87],"133":[2,87],"134":[2,87],"136":[2,87],"137":[2,87],"140":[2,87],"141":[2,87],"142":[2,87],"143":[2,87],"144":[2,87],"145":[2,87],"146":[2,87],"147":[2,87],"148":[2,87],"149":[2,87],"150":[2,87],"151":[2,87],"152":[2,87],"153":[2,87],"154":[2,87],"155":[2,87],"156":[2,87],"157":[2,87],"158":[2,87],"159":[2,87],"160":[2,87],"161":[2,87],"162":[2,87],"163":[2,87],"164":[2,87],"165":[2,87]},{"8":297,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"1":[2,88],"4":[2,88],"29":[2,88],"30":[2,88],"46":[2,88],"51":[2,88],"59":[2,88],"62":[2,88],"73":[2,88],"74":[2,88],"75":[2,88],"76":[2,88],"79":[2,88],"80":[2,88],"81":[2,88],"82":[2,88],"85":[2,88],"87":[2,88],"93":[2,88],"95":[2,88],"100":[2,88],"108":[2,88],"110":[2,88],"111":[2,88],"112":[2,88],"115":[2,88],"119":[2,88],"120":[2,88],"121":[2,88],"128":[2,88],"129":[2,88],"131":[2,88],"133":[2,88],"134":[2,88],"136":[2,88],"137":[2,88],"140":[2,88],"141":[2,88],"142":[2,88],"143":[2,88],"144":[2,88],"145":[2,88],"146":[2,88],"147":[2,88],"148":[2,88],"149":[2,88],"150":[2,88],"151":[2,88],"152":[2,88],"153":[2,88],"154":[2,88],"155":[2,88],"156":[2,88],"157":[2,88],"158":[2,88],"159":[2,88],"160":[2,88],"161":[2,88],"162":[2,88],"163":[2,88],"164":[2,88],"165":[2,88]},{"1":[2,44],"4":[2,44],"29":[2,44],"30":[2,44],"51":[1,116],"59":[2,44],"62":[1,133],"80":[2,44],"85":[2,44],"95":[2,44],"100":[2,44],"108":[2,44],"109":131,"110":[1,79],"111":[2,44],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"121":[2,44],"128":[2,44],"129":[2,44],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"55":298,"56":[1,76],"57":[1,77]},{"60":299,"61":[1,159]},{"62":[1,300]},{"1":[2,127],"4":[2,127],"29":[2,127],"30":[2,127],"51":[2,127],"59":[2,127],"62":[2,127],"80":[2,127],"85":[2,127],"95":[2,127],"100":[2,127],"104":[1,301],"108":[2,127],"110":[2,127],"111":[2,127],"112":[2,127],"115":[2,127],"119":[2,127],"120":[2,127],"121":[2,127],"128":[2,127],"129":[2,127],"131":[2,127],"133":[2,127],"134":[2,127],"136":[2,127],"137":[2,127],"140":[2,127],"141":[2,127],"142":[2,127],"143":[2,127],"144":[2,127],"145":[2,127],"146":[2,127],"147":[2,127],"148":[2,127],"149":[2,127],"150":[2,127],"151":[2,127],"152":[2,127],"153":[2,127],"154":[2,127],"155":[2,127],"156":[2,127],"157":[2,127],"158":[2,127],"159":[2,127],"160":[2,127],"161":[2,127],"162":[2,127],"163":[2,127],"164":[2,127],"165":[2,127]},{"4":[1,161],"6":302,"29":[1,6]},{"31":303,"32":[1,89]},{"4":[1,161],"6":304,"29":[1,6]},{"8":305,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":306,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"31":176,"32":[1,89],"67":177,"68":178,"83":[1,84],"99":[1,179],"118":307},{"28":270,"49":[1,56],"50":[1,57],"123":308,"125":268,"126":[1,269]},{"28":270,"30":[1,309],"49":[1,56],"50":[1,57],"124":[1,310],"125":311,"126":[1,269]},{"30":[2,162],"49":[2,162],"50":[2,162],"124":[2,162],"126":[2,162]},{"8":313,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"101":312,"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"4":[1,314]},{"1":[2,107],"4":[2,107],"29":[2,107],"30":[2,107],"51":[2,107],"59":[2,107],"62":[2,107],"64":139,"73":[1,141],"74":[1,142],"75":[1,143],"76":[1,144],"77":145,"78":146,"79":[1,147],"80":[2,107],"81":[1,148],"82":[1,149],"85":[2,107],"92":138,"93":[1,140],"95":[2,107],"100":[2,107],"108":[2,107],"110":[2,107],"111":[2,107],"112":[2,107],"115":[2,107],"119":[2,107],"120":[2,107],"121":[2,107],"128":[2,107],"129":[2,107],"131":[2,107],"133":[2,107],"134":[2,107],"136":[2,107],"137":[2,107],"140":[2,107],"141":[2,107],"142":[2,107],"143":[2,107],"144":[2,107],"145":[2,107],"146":[2,107],"147":[2,107],"148":[2,107],"149":[2,107],"150":[2,107],"151":[2,107],"152":[2,107],"153":[2,107],"154":[2,107],"155":[2,107],"156":[2,107],"157":[2,107],"158":[2,107],"159":[2,107],"160":[2,107],"161":[2,107],"162":[2,107],"163":[2,107],"164":[2,107],"165":[2,107]},{"14":315,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":155,"63":156,"65":184,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"97":[1,73],"98":[1,74],"99":[1,72],"107":[1,71]},{"4":[2,101],"28":201,"30":[2,101],"31":199,"32":[1,89],"33":200,"34":[1,85],"35":[1,86],"47":318,"49":[1,56],"50":[1,57],"66":319,"88":316,"89":317,"98":[1,320]},{"1":[2,132],"4":[2,132],"29":[2,132],"30":[2,132],"51":[2,132],"59":[2,132],"62":[2,132],"73":[2,132],"74":[2,132],"75":[2,132],"76":[2,132],"79":[2,132],"80":[2,132],"81":[2,132],"82":[2,132],"85":[2,132],"93":[2,132],"95":[2,132],"100":[2,132],"108":[2,132],"110":[2,132],"111":[2,132],"112":[2,132],"115":[2,132],"119":[2,132],"120":[2,132],"121":[2,132],"128":[2,132],"129":[2,132],"131":[2,132],"133":[2,132],"134":[2,132],"136":[2,132],"137":[2,132],"140":[2,132],"141":[2,132],"142":[2,132],"143":[2,132],"144":[2,132],"145":[2,132],"146":[2,132],"147":[2,132],"148":[2,132],"149":[2,132],"150":[2,132],"151":[2,132],"152":[2,132],"153":[2,132],"154":[2,132],"155":[2,132],"156":[2,132],"157":[2,132],"158":[2,132],"159":[2,132],"160":[2,132],"161":[2,132],"162":[2,132],"163":[2,132],"164":[2,132],"165":[2,132]},{"62":[1,321]},{"4":[1,323],"29":[1,324],"100":[1,322]},{"4":[2,60],"8":325,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"29":[2,60],"30":[2,60],"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"95":[2,60],"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"100":[2,60],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"4":[2,59],"29":[2,59],"58":326,"59":[1,277],"95":[2,59]},{"1":[2,171],"4":[2,171],"29":[2,171],"30":[2,171],"51":[2,171],"59":[2,171],"62":[2,171],"80":[2,171],"85":[2,171],"95":[2,171],"100":[2,171],"108":[2,171],"110":[2,171],"111":[2,171],"112":[2,171],"115":[2,171],"119":[2,171],"120":[2,171],"121":[2,171],"128":[2,171],"129":[2,171],"131":[2,171],"133":[2,171],"134":[2,171],"136":[2,171],"137":[2,171],"140":[2,171],"141":[2,171],"142":[2,171],"143":[2,171],"144":[2,171],"145":[2,171],"146":[2,171],"147":[2,171],"148":[2,171],"149":[2,171],"150":[2,171],"151":[2,171],"152":[2,171],"153":[2,171],"154":[2,171],"155":[2,171],"156":[2,171],"157":[2,171],"158":[2,171],"159":[2,171],"160":[2,171],"161":[2,171],"162":[2,171],"163":[2,171],"164":[2,171],"165":[2,171]},{"8":327,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":328,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":329,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"4":[1,331],"29":[1,332],"85":[1,330]},{"4":[2,60],"28":201,"29":[2,60],"30":[2,60],"31":199,"32":[1,89],"33":200,"34":[1,85],"35":[1,86],"47":333,"49":[1,56],"50":[1,57],"85":[2,60]},{"8":334,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":335,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"1":[2,167],"4":[2,167],"29":[2,167],"30":[2,167],"51":[2,167],"59":[2,167],"62":[2,167],"80":[2,167],"85":[2,167],"95":[2,167],"100":[2,167],"108":[2,167],"110":[2,167],"111":[2,167],"112":[2,167],"115":[2,167],"119":[2,167],"120":[2,167],"121":[2,167],"124":[2,167],"128":[2,167],"129":[2,167],"131":[2,167],"133":[2,167],"134":[2,167],"136":[2,167],"137":[2,167],"140":[2,167],"141":[2,167],"142":[2,167],"143":[2,167],"144":[2,167],"145":[2,167],"146":[2,167],"147":[2,167],"148":[2,167],"149":[2,167],"150":[2,167],"151":[2,167],"152":[2,167],"153":[2,167],"154":[2,167],"155":[2,167],"156":[2,167],"157":[2,167],"158":[2,167],"159":[2,167],"160":[2,167],"161":[2,167],"162":[2,167],"163":[2,167],"164":[2,167],"165":[2,167]},{"1":[2,168],"4":[2,168],"29":[2,168],"30":[2,168],"51":[2,168],"59":[2,168],"62":[2,168],"80":[2,168],"85":[2,168],"95":[2,168],"100":[2,168],"108":[2,168],"110":[2,168],"111":[2,168],"112":[2,168],"115":[2,168],"119":[2,168],"120":[2,168],"121":[2,168],"124":[2,168],"128":[2,168],"129":[2,168],"131":[2,168],"133":[2,168],"134":[2,168],"136":[2,168],"137":[2,168],"140":[2,168],"141":[2,168],"142":[2,168],"143":[2,168],"144":[2,168],"145":[2,168],"146":[2,168],"147":[2,168],"148":[2,168],"149":[2,168],"150":[2,168],"151":[2,168],"152":[2,168],"153":[2,168],"154":[2,168],"155":[2,168],"156":[2,168],"157":[2,168],"158":[2,168],"159":[2,168],"160":[2,168],"161":[2,168],"162":[2,168],"163":[2,168],"164":[2,168],"165":[2,168]},{"1":[2,219],"4":[2,219],"29":[2,219],"30":[2,219],"51":[1,116],"59":[2,219],"62":[2,219],"80":[2,219],"85":[2,219],"95":[2,219],"100":[2,219],"108":[2,219],"109":131,"110":[2,219],"111":[2,219],"112":[2,219],"115":[2,219],"119":[2,219],"120":[2,219],"121":[2,219],"128":[2,219],"129":[2,219],"133":[2,219],"134":[2,219],"140":[2,219],"141":[2,219],"142":[2,219],"143":[2,219],"144":[2,219],"145":[2,219],"146":[2,219],"147":[2,219],"148":[2,219],"149":[2,219],"150":[2,219],"151":[2,219],"152":[2,219],"153":[2,219],"154":[2,219],"155":[2,219],"156":[2,219],"157":[2,219],"158":[2,219],"159":[2,219],"160":[2,219],"161":[2,219],"162":[2,219],"163":[2,219],"164":[2,219],"165":[2,219]},{"1":[2,220],"4":[2,220],"29":[2,220],"30":[2,220],"51":[1,116],"59":[2,220],"62":[2,220],"80":[2,220],"85":[2,220],"95":[2,220],"100":[2,220],"108":[2,220],"109":131,"110":[2,220],"111":[2,220],"112":[2,220],"115":[2,220],"119":[2,220],"120":[2,220],"121":[2,220],"128":[2,220],"129":[2,220],"133":[2,220],"134":[2,220],"140":[2,220],"141":[2,220],"142":[2,220],"143":[2,220],"144":[2,220],"145":[2,220],"146":[2,220],"147":[2,220],"148":[2,220],"149":[2,220],"150":[2,220],"151":[2,220],"152":[2,220],"153":[2,220],"154":[2,220],"155":[2,220],"156":[2,220],"157":[2,220],"158":[2,220],"159":[2,220],"160":[2,220],"161":[2,220],"162":[2,220],"163":[2,220],"164":[2,220],"165":[2,220]},{"1":[2,144],"4":[2,144],"29":[2,144],"30":[2,144],"51":[2,144],"59":[2,144],"62":[2,144],"80":[2,144],"85":[2,144],"95":[2,144],"100":[2,144],"108":[2,144],"110":[2,144],"111":[2,144],"112":[2,144],"115":[2,144],"119":[2,144],"120":[2,144],"121":[2,144],"128":[2,144],"129":[2,144],"131":[2,144],"133":[2,144],"134":[2,144],"136":[2,144],"137":[2,144],"140":[2,144],"141":[2,144],"142":[2,144],"143":[2,144],"144":[2,144],"145":[2,144],"146":[2,144],"147":[2,144],"148":[2,144],"149":[2,144],"150":[2,144],"151":[2,144],"152":[2,144],"153":[2,144],"154":[2,144],"155":[2,144],"156":[2,144],"157":[2,144],"158":[2,144],"159":[2,144],"160":[2,144],"161":[2,144],"162":[2,144],"163":[2,144],"164":[2,144],"165":[2,144]},{"1":[2,66],"4":[2,66],"29":[2,66],"30":[2,66],"51":[2,66],"59":[2,66],"62":[2,66],"80":[2,66],"85":[2,66],"95":[2,66],"100":[2,66],"108":[2,66],"110":[2,66],"111":[2,66],"112":[2,66],"115":[2,66],"119":[2,66],"120":[2,66],"121":[2,66],"128":[2,66],"129":[2,66],"131":[2,66],"133":[2,66],"134":[2,66],"136":[2,66],"137":[2,66],"140":[2,66],"141":[2,66],"142":[2,66],"143":[2,66],"144":[2,66],"145":[2,66],"146":[2,66],"147":[2,66],"148":[2,66],"149":[2,66],"150":[2,66],"151":[2,66],"152":[2,66],"153":[2,66],"154":[2,66],"155":[2,66],"156":[2,66],"157":[2,66],"158":[2,66],"159":[2,66],"160":[2,66],"161":[2,66],"162":[2,66],"163":[2,66],"164":[2,66],"165":[2,66]},{"1":[2,143],"4":[2,143],"29":[2,143],"30":[2,143],"51":[2,143],"59":[2,143],"62":[2,143],"80":[2,143],"85":[2,143],"95":[2,143],"100":[2,143],"108":[2,143],"110":[2,143],"111":[2,143],"112":[2,143],"115":[2,143],"119":[2,143],"120":[2,143],"121":[2,143],"128":[2,143],"129":[2,143],"131":[2,143],"133":[2,143],"134":[2,143],"136":[2,143],"137":[2,143],"140":[2,143],"141":[2,143],"142":[2,143],"143":[2,143],"144":[2,143],"145":[2,143],"146":[2,143],"147":[2,143],"148":[2,143],"149":[2,143],"150":[2,143],"151":[2,143],"152":[2,143],"153":[2,143],"154":[2,143],"155":[2,143],"156":[2,143],"157":[2,143],"158":[2,143],"159":[2,143],"160":[2,143],"161":[2,143],"162":[2,143],"163":[2,143],"164":[2,143],"165":[2,143]},{"4":[1,323],"29":[1,324],"95":[1,336]},{"1":[2,86],"4":[2,86],"29":[2,86],"30":[2,86],"46":[2,86],"51":[2,86],"59":[2,86],"62":[2,86],"73":[2,86],"74":[2,86],"75":[2,86],"76":[2,86],"79":[2,86],"80":[2,86],"81":[2,86],"82":[2,86],"85":[2,86],"87":[2,86],"93":[2,86],"95":[2,86],"100":[2,86],"108":[2,86],"110":[2,86],"111":[2,86],"112":[2,86],"115":[2,86],"119":[2,86],"120":[2,86],"121":[2,86],"128":[2,86],"129":[2,86],"131":[2,86],"133":[2,86],"134":[2,86],"136":[2,86],"137":[2,86],"140":[2,86],"141":[2,86],"142":[2,86],"143":[2,86],"144":[2,86],"145":[2,86],"146":[2,86],"147":[2,86],"148":[2,86],"149":[2,86],"150":[2,86],"151":[2,86],"152":[2,86],"153":[2,86],"154":[2,86],"155":[2,86],"156":[2,86],"157":[2,86],"158":[2,86],"159":[2,86],"160":[2,86],"161":[2,86],"162":[2,86],"163":[2,86],"164":[2,86],"165":[2,86]},{"62":[1,337]},{"51":[1,116],"62":[1,133],"80":[1,295],"109":131,"110":[1,79],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"128":[1,129],"129":[1,130],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"4":[1,161],"6":338,"29":[1,6]},{"54":[2,63],"59":[2,63],"62":[1,258]},{"62":[1,339]},{"4":[1,161],"6":340,"29":[1,6]},{"1":[2,128],"4":[2,128],"29":[2,128],"30":[2,128],"51":[2,128],"59":[2,128],"62":[2,128],"80":[2,128],"85":[2,128],"95":[2,128],"100":[2,128],"108":[2,128],"110":[2,128],"111":[2,128],"112":[2,128],"115":[2,128],"119":[2,128],"120":[2,128],"121":[2,128],"128":[2,128],"129":[2,128],"131":[2,128],"133":[2,128],"134":[2,128],"136":[2,128],"137":[2,128],"140":[2,128],"141":[2,128],"142":[2,128],"143":[2,128],"144":[2,128],"145":[2,128],"146":[2,128],"147":[2,128],"148":[2,128],"149":[2,128],"150":[2,128],"151":[2,128],"152":[2,128],"153":[2,128],"154":[2,128],"155":[2,128],"156":[2,128],"157":[2,128],"158":[2,128],"159":[2,128],"160":[2,128],"161":[2,128],"162":[2,128],"163":[2,128],"164":[2,128],"165":[2,128]},{"4":[1,161],"6":341,"29":[1,6]},{"1":[2,145],"4":[2,145],"29":[2,145],"30":[2,145],"51":[2,145],"59":[2,145],"62":[2,145],"80":[2,145],"85":[2,145],"95":[2,145],"100":[2,145],"108":[2,145],"110":[2,145],"111":[2,145],"112":[2,145],"115":[2,145],"119":[2,145],"120":[2,145],"121":[2,145],"128":[2,145],"129":[2,145],"131":[2,145],"133":[2,145],"134":[2,145],"136":[2,145],"137":[2,145],"140":[2,145],"141":[2,145],"142":[2,145],"143":[2,145],"144":[2,145],"145":[2,145],"146":[2,145],"147":[2,145],"148":[2,145],"149":[2,145],"150":[2,145],"151":[2,145],"152":[2,145],"153":[2,145],"154":[2,145],"155":[2,145],"156":[2,145],"157":[2,145],"158":[2,145],"159":[2,145],"160":[2,145],"161":[2,145],"162":[2,145],"163":[2,145],"164":[2,145],"165":[2,145]},{"1":[2,151],"4":[2,151],"29":[2,151],"30":[2,151],"51":[1,116],"59":[2,151],"62":[1,133],"80":[2,151],"85":[2,151],"95":[2,151],"100":[2,151],"108":[2,151],"109":131,"110":[2,151],"111":[1,342],"112":[2,151],"115":[2,151],"119":[1,126],"120":[1,127],"121":[1,343],"128":[2,151],"129":[2,151],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"1":[2,152],"4":[2,152],"29":[2,152],"30":[2,152],"51":[1,116],"59":[2,152],"62":[1,133],"80":[2,152],"85":[2,152],"95":[2,152],"100":[2,152],"108":[2,152],"109":131,"110":[2,152],"111":[1,344],"112":[2,152],"115":[2,152],"119":[1,126],"120":[1,127],"121":[2,152],"128":[2,152],"129":[2,152],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"119":[2,150],"120":[2,150]},{"28":270,"30":[1,345],"49":[1,56],"50":[1,57],"124":[1,346],"125":311,"126":[1,269]},{"1":[2,160],"4":[2,160],"29":[2,160],"30":[2,160],"51":[2,160],"59":[2,160],"62":[2,160],"80":[2,160],"85":[2,160],"95":[2,160],"100":[2,160],"108":[2,160],"110":[2,160],"111":[2,160],"112":[2,160],"115":[2,160],"119":[2,160],"120":[2,160],"121":[2,160],"128":[2,160],"129":[2,160],"131":[2,160],"133":[2,160],"134":[2,160],"136":[2,160],"137":[2,160],"140":[2,160],"141":[2,160],"142":[2,160],"143":[2,160],"144":[2,160],"145":[2,160],"146":[2,160],"147":[2,160],"148":[2,160],"149":[2,160],"150":[2,160],"151":[2,160],"152":[2,160],"153":[2,160],"154":[2,160],"155":[2,160],"156":[2,160],"157":[2,160],"158":[2,160],"159":[2,160],"160":[2,160],"161":[2,160],"162":[2,160],"163":[2,160],"164":[2,160],"165":[2,160]},{"4":[1,161],"6":347,"29":[1,6]},{"30":[2,163],"49":[2,163],"50":[2,163],"124":[2,163],"126":[2,163]},{"4":[1,161],"6":348,"29":[1,6],"59":[1,349]},{"4":[2,125],"29":[2,125],"51":[1,116],"59":[2,125],"62":[1,133],"109":131,"110":[1,79],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"128":[1,129],"129":[1,130],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"28":270,"49":[1,56],"50":[1,57],"125":350,"126":[1,269]},{"1":[2,96],"4":[2,96],"29":[1,351],"30":[2,96],"51":[2,96],"59":[2,96],"62":[2,96],"64":139,"73":[1,141],"74":[1,142],"75":[1,143],"76":[1,144],"77":145,"78":146,"79":[1,147],"80":[2,96],"81":[1,148],"82":[1,149],"85":[2,96],"92":138,"93":[1,140],"95":[2,96],"100":[2,96],"108":[2,96],"110":[2,96],"111":[2,96],"112":[2,96],"115":[2,96],"119":[2,96],"120":[2,96],"121":[2,96],"128":[2,96],"129":[2,96],"131":[2,96],"133":[2,96],"134":[2,96],"136":[2,96],"137":[2,96],"140":[2,96],"141":[2,96],"142":[2,96],"143":[2,96],"144":[2,96],"145":[2,96],"146":[2,96],"147":[2,96],"148":[2,96],"149":[2,96],"150":[2,96],"151":[2,96],"152":[2,96],"153":[2,96],"154":[2,96],"155":[2,96],"156":[2,96],"157":[2,96],"158":[2,96],"159":[2,96],"160":[2,96],"161":[2,96],"162":[2,96],"163":[2,96],"164":[2,96],"165":[2,96]},{"4":[1,353],"30":[1,352]},{"4":[2,102],"30":[2,102]},{"4":[2,99],"30":[2,99]},{"46":[1,354]},{"31":190,"32":[1,89]},{"8":355,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"62":[1,356],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"1":[2,119],"4":[2,119],"29":[2,119],"30":[2,119],"46":[2,119],"51":[2,119],"59":[2,119],"62":[2,119],"73":[2,119],"74":[2,119],"75":[2,119],"76":[2,119],"79":[2,119],"80":[2,119],"81":[2,119],"82":[2,119],"85":[2,119],"93":[2,119],"95":[2,119],"100":[2,119],"108":[2,119],"110":[2,119],"111":[2,119],"112":[2,119],"115":[2,119],"119":[2,119],"120":[2,119],"121":[2,119],"128":[2,119],"129":[2,119],"131":[2,119],"133":[2,119],"134":[2,119],"136":[2,119],"137":[2,119],"140":[2,119],"141":[2,119],"142":[2,119],"143":[2,119],"144":[2,119],"145":[2,119],"146":[2,119],"147":[2,119],"148":[2,119],"149":[2,119],"150":[2,119],"151":[2,119],"152":[2,119],"153":[2,119],"154":[2,119],"155":[2,119],"156":[2,119],"157":[2,119],"158":[2,119],"159":[2,119],"160":[2,119],"161":[2,119],"162":[2,119],"163":[2,119],"164":[2,119],"165":[2,119]},{"8":357,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"4":[2,120],"8":247,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"29":[2,120],"30":[2,120],"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"59":[2,120],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"94":358,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"4":[2,122],"29":[2,122],"30":[2,122],"51":[1,116],"59":[2,122],"62":[1,133],"95":[2,122],"100":[2,122],"109":131,"110":[1,79],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"128":[1,129],"129":[1,130],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"4":[1,323],"29":[1,324],"95":[1,359]},{"4":[1,161],"6":360,"29":[1,6],"51":[1,116],"62":[1,133],"109":131,"110":[1,79],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"128":[1,129],"129":[1,130],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"1":[2,134],"4":[2,134],"29":[2,134],"30":[2,134],"51":[1,116],"59":[2,134],"62":[1,133],"80":[2,134],"85":[2,134],"95":[2,134],"100":[2,134],"108":[2,134],"109":131,"110":[1,79],"111":[2,134],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"121":[2,134],"128":[2,134],"129":[2,134],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"1":[2,136],"4":[2,136],"29":[2,136],"30":[2,136],"51":[1,116],"59":[2,136],"62":[1,133],"80":[2,136],"85":[2,136],"95":[2,136],"100":[2,136],"108":[2,136],"109":131,"110":[1,79],"111":[2,136],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"121":[2,136],"128":[2,136],"129":[2,136],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"1":[2,89],"4":[2,89],"29":[2,89],"30":[2,89],"46":[2,89],"51":[2,89],"59":[2,89],"62":[2,89],"73":[2,89],"74":[2,89],"75":[2,89],"76":[2,89],"79":[2,89],"80":[2,89],"81":[2,89],"82":[2,89],"85":[2,89],"93":[2,89],"95":[2,89],"100":[2,89],"108":[2,89],"110":[2,89],"111":[2,89],"112":[2,89],"115":[2,89],"119":[2,89],"120":[2,89],"121":[2,89],"128":[2,89],"129":[2,89],"131":[2,89],"133":[2,89],"134":[2,89],"136":[2,89],"137":[2,89],"140":[2,89],"141":[2,89],"142":[2,89],"143":[2,89],"144":[2,89],"145":[2,89],"146":[2,89],"147":[2,89],"148":[2,89],"149":[2,89],"150":[2,89],"151":[2,89],"152":[2,89],"153":[2,89],"154":[2,89],"155":[2,89],"156":[2,89],"157":[2,89],"158":[2,89],"159":[2,89],"160":[2,89],"161":[2,89],"162":[2,89],"163":[2,89],"164":[2,89],"165":[2,89]},{"28":201,"31":199,"32":[1,89],"33":200,"34":[1,85],"35":[1,86],"47":361,"49":[1,56],"50":[1,57]},{"4":[2,90],"28":201,"29":[2,90],"30":[2,90],"31":199,"32":[1,89],"33":200,"34":[1,85],"35":[1,86],"47":198,"49":[1,56],"50":[1,57],"59":[2,90],"84":362},{"4":[2,92],"29":[2,92],"30":[2,92],"59":[2,92],"85":[2,92]},{"4":[2,47],"29":[2,47],"30":[2,47],"51":[1,116],"59":[2,47],"62":[1,133],"85":[2,47],"109":131,"110":[1,79],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"128":[1,129],"129":[1,130],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"4":[2,48],"29":[2,48],"30":[2,48],"51":[1,116],"59":[2,48],"62":[1,133],"85":[2,48],"109":131,"110":[1,79],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"128":[1,129],"129":[1,130],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"1":[2,110],"4":[2,110],"29":[2,110],"30":[2,110],"51":[2,110],"59":[2,110],"62":[2,110],"73":[2,110],"74":[2,110],"75":[2,110],"76":[2,110],"79":[2,110],"80":[2,110],"81":[2,110],"82":[2,110],"85":[2,110],"93":[2,110],"95":[2,110],"100":[2,110],"108":[2,110],"110":[2,110],"111":[2,110],"112":[2,110],"115":[2,110],"119":[2,110],"120":[2,110],"121":[2,110],"128":[2,110],"129":[2,110],"131":[2,110],"133":[2,110],"134":[2,110],"136":[2,110],"137":[2,110],"140":[2,110],"141":[2,110],"142":[2,110],"143":[2,110],"144":[2,110],"145":[2,110],"146":[2,110],"147":[2,110],"148":[2,110],"149":[2,110],"150":[2,110],"151":[2,110],"152":[2,110],"153":[2,110],"154":[2,110],"155":[2,110],"156":[2,110],"157":[2,110],"158":[2,110],"159":[2,110],"160":[2,110],"161":[2,110],"162":[2,110],"163":[2,110],"164":[2,110],"165":[2,110]},{"8":363,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"62":[1,364],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"1":[2,55],"4":[2,55],"29":[2,55],"30":[2,55],"51":[2,55],"59":[2,55],"62":[2,55],"80":[2,55],"85":[2,55],"95":[2,55],"100":[2,55],"108":[2,55],"110":[2,55],"111":[2,55],"112":[2,55],"115":[2,55],"119":[2,55],"120":[2,55],"121":[2,55],"128":[2,55],"129":[2,55],"131":[2,55],"133":[2,55],"134":[2,55],"136":[2,55],"137":[2,55],"140":[2,55],"141":[2,55],"142":[2,55],"143":[2,55],"144":[2,55],"145":[2,55],"146":[2,55],"147":[2,55],"148":[2,55],"149":[2,55],"150":[2,55],"151":[2,55],"152":[2,55],"153":[2,55],"154":[2,55],"155":[2,55],"156":[2,55],"157":[2,55],"158":[2,55],"159":[2,55],"160":[2,55],"161":[2,55],"162":[2,55],"163":[2,55],"164":[2,55],"165":[2,55]},{"54":[2,65],"59":[2,65],"62":[2,65]},{"1":[2,129],"4":[2,129],"29":[2,129],"30":[2,129],"51":[2,129],"59":[2,129],"62":[2,129],"80":[2,129],"85":[2,129],"95":[2,129],"100":[2,129],"108":[2,129],"110":[2,129],"111":[2,129],"112":[2,129],"115":[2,129],"119":[2,129],"120":[2,129],"121":[2,129],"128":[2,129],"129":[2,129],"131":[2,129],"133":[2,129],"134":[2,129],"136":[2,129],"137":[2,129],"140":[2,129],"141":[2,129],"142":[2,129],"143":[2,129],"144":[2,129],"145":[2,129],"146":[2,129],"147":[2,129],"148":[2,129],"149":[2,129],"150":[2,129],"151":[2,129],"152":[2,129],"153":[2,129],"154":[2,129],"155":[2,129],"156":[2,129],"157":[2,129],"158":[2,129],"159":[2,129],"160":[2,129],"161":[2,129],"162":[2,129],"163":[2,129],"164":[2,129],"165":[2,129]},{"1":[2,130],"4":[2,130],"29":[2,130],"30":[2,130],"51":[2,130],"59":[2,130],"62":[2,130],"80":[2,130],"85":[2,130],"95":[2,130],"100":[2,130],"104":[2,130],"108":[2,130],"110":[2,130],"111":[2,130],"112":[2,130],"115":[2,130],"119":[2,130],"120":[2,130],"121":[2,130],"128":[2,130],"129":[2,130],"131":[2,130],"133":[2,130],"134":[2,130],"136":[2,130],"137":[2,130],"140":[2,130],"141":[2,130],"142":[2,130],"143":[2,130],"144":[2,130],"145":[2,130],"146":[2,130],"147":[2,130],"148":[2,130],"149":[2,130],"150":[2,130],"151":[2,130],"152":[2,130],"153":[2,130],"154":[2,130],"155":[2,130],"156":[2,130],"157":[2,130],"158":[2,130],"159":[2,130],"160":[2,130],"161":[2,130],"162":[2,130],"163":[2,130],"164":[2,130],"165":[2,130]},{"8":365,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":366,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":367,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"1":[2,158],"4":[2,158],"29":[2,158],"30":[2,158],"51":[2,158],"59":[2,158],"62":[2,158],"80":[2,158],"85":[2,158],"95":[2,158],"100":[2,158],"108":[2,158],"110":[2,158],"111":[2,158],"112":[2,158],"115":[2,158],"119":[2,158],"120":[2,158],"121":[2,158],"128":[2,158],"129":[2,158],"131":[2,158],"133":[2,158],"134":[2,158],"136":[2,158],"137":[2,158],"140":[2,158],"141":[2,158],"142":[2,158],"143":[2,158],"144":[2,158],"145":[2,158],"146":[2,158],"147":[2,158],"148":[2,158],"149":[2,158],"150":[2,158],"151":[2,158],"152":[2,158],"153":[2,158],"154":[2,158],"155":[2,158],"156":[2,158],"157":[2,158],"158":[2,158],"159":[2,158],"160":[2,158],"161":[2,158],"162":[2,158],"163":[2,158],"164":[2,158],"165":[2,158]},{"4":[1,161],"6":368,"29":[1,6]},{"30":[1,369]},{"4":[1,370],"30":[2,164],"49":[2,164],"50":[2,164],"124":[2,164],"126":[2,164]},{"8":371,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"30":[2,166],"49":[2,166],"50":[2,166],"124":[2,166],"126":[2,166]},{"4":[2,101],"28":201,"30":[2,101],"31":199,"32":[1,89],"33":200,"34":[1,85],"35":[1,86],"47":318,"49":[1,56],"50":[1,57],"66":319,"88":372,"89":317,"98":[1,320]},{"1":[2,97],"4":[2,97],"29":[2,97],"30":[2,97],"51":[2,97],"59":[2,97],"62":[2,97],"80":[2,97],"85":[2,97],"95":[2,97],"100":[2,97],"108":[2,97],"110":[2,97],"111":[2,97],"112":[2,97],"115":[2,97],"119":[2,97],"120":[2,97],"121":[2,97],"128":[2,97],"129":[2,97],"131":[2,97],"133":[2,97],"134":[2,97],"136":[2,97],"137":[2,97],"140":[2,97],"141":[2,97],"142":[2,97],"143":[2,97],"144":[2,97],"145":[2,97],"146":[2,97],"147":[2,97],"148":[2,97],"149":[2,97],"150":[2,97],"151":[2,97],"152":[2,97],"153":[2,97],"154":[2,97],"155":[2,97],"156":[2,97],"157":[2,97],"158":[2,97],"159":[2,97],"160":[2,97],"161":[2,97],"162":[2,97],"163":[2,97],"164":[2,97],"165":[2,97]},{"28":201,"31":199,"32":[1,89],"33":200,"34":[1,85],"35":[1,86],"47":318,"49":[1,56],"50":[1,57],"66":319,"89":373,"98":[1,320]},{"8":374,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"51":[1,116],"62":[1,133],"100":[1,375],"109":131,"110":[1,79],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"128":[1,129],"129":[1,130],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"4":[2,66],"8":376,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"29":[2,66],"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"51":[2,66],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"59":[2,66],"62":[2,66],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"100":[2,66],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[2,66],"112":[2,66],"113":51,"114":[1,81],"115":[2,66],"119":[2,66],"120":[2,66],"122":[1,53],"127":78,"128":[2,66],"129":[2,66],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47],"140":[2,66],"141":[2,66],"142":[2,66],"143":[2,66],"144":[2,66],"145":[2,66],"146":[2,66],"147":[2,66],"148":[2,66],"149":[2,66],"150":[2,66],"151":[2,66],"152":[2,66],"153":[2,66],"154":[2,66],"155":[2,66],"156":[2,66],"157":[2,66],"158":[2,66],"159":[2,66],"160":[2,66],"161":[2,66],"162":[2,66],"163":[2,66],"164":[2,66],"165":[2,66]},{"4":[2,123],"29":[2,123],"30":[2,123],"51":[1,116],"59":[2,123],"62":[1,133],"95":[2,123],"100":[2,123],"109":131,"110":[1,79],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"128":[1,129],"129":[1,130],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"4":[2,59],"29":[2,59],"30":[2,59],"58":377,"59":[1,277]},{"1":[2,111],"4":[2,111],"29":[2,111],"30":[2,111],"51":[2,111],"59":[2,111],"62":[2,111],"80":[2,111],"85":[2,111],"95":[2,111],"100":[2,111],"108":[2,111],"110":[2,111],"111":[2,111],"112":[2,111],"115":[2,111],"119":[2,111],"120":[2,111],"121":[2,111],"128":[2,111],"129":[2,111],"131":[2,111],"133":[2,111],"134":[2,111],"136":[2,111],"137":[2,111],"140":[2,111],"141":[2,111],"142":[2,111],"143":[2,111],"144":[2,111],"145":[2,111],"146":[2,111],"147":[2,111],"148":[2,111],"149":[2,111],"150":[2,111],"151":[2,111],"152":[2,111],"153":[2,111],"154":[2,111],"155":[2,111],"156":[2,111],"157":[2,111],"158":[2,111],"159":[2,111],"160":[2,111],"161":[2,111],"162":[2,111],"163":[2,111],"164":[2,111],"165":[2,111]},{"1":[2,169],"4":[2,169],"29":[2,169],"30":[2,169],"51":[2,169],"59":[2,169],"62":[2,169],"80":[2,169],"85":[2,169],"95":[2,169],"100":[2,169],"108":[2,169],"110":[2,169],"111":[2,169],"112":[2,169],"115":[2,169],"119":[2,169],"120":[2,169],"121":[2,169],"124":[2,169],"128":[2,169],"129":[2,169],"131":[2,169],"133":[2,169],"134":[2,169],"136":[2,169],"137":[2,169],"140":[2,169],"141":[2,169],"142":[2,169],"143":[2,169],"144":[2,169],"145":[2,169],"146":[2,169],"147":[2,169],"148":[2,169],"149":[2,169],"150":[2,169],"151":[2,169],"152":[2,169],"153":[2,169],"154":[2,169],"155":[2,169],"156":[2,169],"157":[2,169],"158":[2,169],"159":[2,169],"160":[2,169],"161":[2,169],"162":[2,169],"163":[2,169],"164":[2,169],"165":[2,169]},{"4":[2,93],"29":[2,93],"30":[2,93],"59":[2,93],"85":[2,93]},{"4":[2,59],"29":[2,59],"30":[2,59],"58":378,"59":[1,284]},{"51":[1,116],"62":[1,133],"80":[1,379],"109":131,"110":[1,79],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"128":[1,129],"129":[1,130],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"8":380,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"51":[2,66],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"62":[2,66],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"80":[2,66],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[2,66],"112":[2,66],"113":51,"114":[1,81],"115":[2,66],"119":[2,66],"120":[2,66],"122":[1,53],"127":78,"128":[2,66],"129":[2,66],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47],"140":[2,66],"141":[2,66],"142":[2,66],"143":[2,66],"144":[2,66],"145":[2,66],"146":[2,66],"147":[2,66],"148":[2,66],"149":[2,66],"150":[2,66],"151":[2,66],"152":[2,66],"153":[2,66],"154":[2,66],"155":[2,66],"156":[2,66],"157":[2,66],"158":[2,66],"159":[2,66],"160":[2,66],"161":[2,66],"162":[2,66],"163":[2,66],"164":[2,66],"165":[2,66]},{"1":[2,153],"4":[2,153],"29":[2,153],"30":[2,153],"51":[1,116],"59":[2,153],"62":[1,133],"80":[2,153],"85":[2,153],"95":[2,153],"100":[2,153],"108":[2,153],"109":131,"110":[2,153],"111":[2,153],"112":[2,153],"115":[2,153],"119":[1,126],"120":[1,127],"121":[1,381],"128":[2,153],"129":[2,153],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"1":[2,155],"4":[2,155],"29":[2,155],"30":[2,155],"51":[1,116],"59":[2,155],"62":[1,133],"80":[2,155],"85":[2,155],"95":[2,155],"100":[2,155],"108":[2,155],"109":131,"110":[2,155],"111":[1,382],"112":[2,155],"115":[2,155],"119":[1,126],"120":[1,127],"121":[2,155],"128":[2,155],"129":[2,155],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"1":[2,154],"4":[2,154],"29":[2,154],"30":[2,154],"51":[1,116],"59":[2,154],"62":[1,133],"80":[2,154],"85":[2,154],"95":[2,154],"100":[2,154],"108":[2,154],"109":131,"110":[2,154],"111":[2,154],"112":[2,154],"115":[2,154],"119":[1,126],"120":[1,127],"121":[2,154],"128":[2,154],"129":[2,154],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"30":[1,383]},{"1":[2,161],"4":[2,161],"29":[2,161],"30":[2,161],"51":[2,161],"59":[2,161],"62":[2,161],"80":[2,161],"85":[2,161],"95":[2,161],"100":[2,161],"108":[2,161],"110":[2,161],"111":[2,161],"112":[2,161],"115":[2,161],"119":[2,161],"120":[2,161],"121":[2,161],"128":[2,161],"129":[2,161],"131":[2,161],"133":[2,161],"134":[2,161],"136":[2,161],"137":[2,161],"140":[2,161],"141":[2,161],"142":[2,161],"143":[2,161],"144":[2,161],"145":[2,161],"146":[2,161],"147":[2,161],"148":[2,161],"149":[2,161],"150":[2,161],"151":[2,161],"152":[2,161],"153":[2,161],"154":[2,161],"155":[2,161],"156":[2,161],"157":[2,161],"158":[2,161],"159":[2,161],"160":[2,161],"161":[2,161],"162":[2,161],"163":[2,161],"164":[2,161],"165":[2,161]},{"30":[2,165],"49":[2,165],"50":[2,165],"124":[2,165],"126":[2,165]},{"4":[2,126],"29":[2,126],"51":[1,116],"59":[2,126],"62":[1,133],"109":131,"110":[1,79],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"128":[1,129],"129":[1,130],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"4":[1,353],"30":[1,384]},{"4":[2,103],"30":[2,103]},{"4":[2,100],"30":[2,100],"51":[1,116],"62":[1,133],"109":131,"110":[1,79],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"128":[1,129],"129":[1,130],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"1":[2,115],"4":[2,115],"29":[2,115],"30":[2,115],"51":[2,115],"59":[2,115],"62":[2,115],"73":[2,115],"74":[2,115],"75":[2,115],"76":[2,115],"79":[2,115],"80":[2,115],"81":[2,115],"82":[2,115],"85":[2,115],"93":[2,115],"95":[2,115],"100":[2,115],"108":[2,115],"110":[2,115],"111":[2,115],"112":[2,115],"115":[2,115],"119":[2,115],"120":[2,115],"121":[2,115],"128":[2,115],"129":[2,115],"131":[2,115],"133":[2,115],"134":[2,115],"136":[2,115],"137":[2,115],"140":[2,115],"141":[2,115],"142":[2,115],"143":[2,115],"144":[2,115],"145":[2,115],"146":[2,115],"147":[2,115],"148":[2,115],"149":[2,115],"150":[2,115],"151":[2,115],"152":[2,115],"153":[2,115],"154":[2,115],"155":[2,115],"156":[2,115],"157":[2,115],"158":[2,115],"159":[2,115],"160":[2,115],"161":[2,115],"162":[2,115],"163":[2,115],"164":[2,115],"165":[2,115]},{"51":[1,116],"62":[1,133],"100":[1,385],"109":131,"110":[1,79],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"128":[1,129],"129":[1,130],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"4":[1,323],"29":[1,324],"30":[1,386]},{"4":[1,331],"29":[1,332],"30":[1,387]},{"1":[2,117],"4":[2,117],"29":[2,117],"30":[2,117],"46":[2,117],"51":[2,117],"59":[2,117],"62":[2,117],"73":[2,117],"74":[2,117],"75":[2,117],"76":[2,117],"79":[2,117],"80":[2,117],"81":[2,117],"82":[2,117],"85":[2,117],"87":[2,117],"93":[2,117],"95":[2,117],"100":[2,117],"108":[2,117],"110":[2,117],"111":[2,117],"112":[2,117],"115":[2,117],"119":[2,117],"120":[2,117],"121":[2,117],"128":[2,117],"129":[2,117],"131":[2,117],"133":[2,117],"134":[2,117],"136":[2,117],"137":[2,117],"140":[2,117],"141":[2,117],"142":[2,117],"143":[2,117],"144":[2,117],"145":[2,117],"146":[2,117],"147":[2,117],"148":[2,117],"149":[2,117],"150":[2,117],"151":[2,117],"152":[2,117],"153":[2,117],"154":[2,117],"155":[2,117],"156":[2,117],"157":[2,117],"158":[2,117],"159":[2,117],"160":[2,117],"161":[2,117],"162":[2,117],"163":[2,117],"164":[2,117],"165":[2,117]},{"51":[1,116],"62":[1,133],"80":[1,388],"109":131,"110":[1,79],"112":[1,80],"115":[1,132],"119":[1,126],"120":[1,127],"128":[1,129],"129":[1,130],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"8":389,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"8":390,"9":163,"10":24,"11":25,"12":[1,26],"13":[1,27],"14":9,"15":10,"16":11,"17":12,"18":13,"19":14,"20":15,"21":16,"22":17,"23":18,"24":19,"25":20,"26":21,"27":22,"28":23,"31":82,"32":[1,89],"33":62,"34":[1,85],"35":[1,86],"36":29,"37":[1,63],"38":[1,64],"39":[1,65],"40":[1,66],"41":[1,67],"42":[1,68],"43":[1,69],"44":[1,70],"45":28,"48":[1,58],"49":[1,56],"50":[1,57],"52":[1,37],"55":38,"56":[1,76],"57":[1,77],"63":54,"65":34,"66":83,"67":60,"68":61,"69":30,"70":31,"71":32,"72":[1,33],"83":[1,84],"86":[1,55],"90":[1,35],"91":36,"96":[1,75],"97":[1,73],"98":[1,74],"99":[1,72],"102":[1,49],"106":[1,59],"107":[1,71],"109":50,"110":[1,79],"112":[1,80],"113":51,"114":[1,81],"115":[1,52],"122":[1,53],"127":78,"128":[1,87],"129":[1,88],"130":48,"131":[1,39],"132":[1,40],"133":[1,41],"134":[1,42],"135":[1,43],"136":[1,44],"137":[1,45],"138":[1,46],"139":[1,47]},{"1":[2,159],"4":[2,159],"29":[2,159],"30":[2,159],"51":[2,159],"59":[2,159],"62":[2,159],"80":[2,159],"85":[2,159],"95":[2,159],"100":[2,159],"108":[2,159],"110":[2,159],"111":[2,159],"112":[2,159],"115":[2,159],"119":[2,159],"120":[2,159],"121":[2,159],"128":[2,159],"129":[2,159],"131":[2,159],"133":[2,159],"134":[2,159],"136":[2,159],"137":[2,159],"140":[2,159],"141":[2,159],"142":[2,159],"143":[2,159],"144":[2,159],"145":[2,159],"146":[2,159],"147":[2,159],"148":[2,159],"149":[2,159],"150":[2,159],"151":[2,159],"152":[2,159],"153":[2,159],"154":[2,159],"155":[2,159],"156":[2,159],"157":[2,159],"158":[2,159],"159":[2,159],"160":[2,159],"161":[2,159],"162":[2,159],"163":[2,159],"164":[2,159],"165":[2,159]},{"1":[2,98],"4":[2,98],"29":[2,98],"30":[2,98],"51":[2,98],"59":[2,98],"62":[2,98],"80":[2,98],"85":[2,98],"95":[2,98],"100":[2,98],"108":[2,98],"110":[2,98],"111":[2,98],"112":[2,98],"115":[2,98],"119":[2,98],"120":[2,98],"121":[2,98],"128":[2,98],"129":[2,98],"131":[2,98],"133":[2,98],"134":[2,98],"136":[2,98],"137":[2,98],"140":[2,98],"141":[2,98],"142":[2,98],"143":[2,98],"144":[2,98],"145":[2,98],"146":[2,98],"147":[2,98],"148":[2,98],"149":[2,98],"150":[2,98],"151":[2,98],"152":[2,98],"153":[2,98],"154":[2,98],"155":[2,98],"156":[2,98],"157":[2,98],"158":[2,98],"159":[2,98],"160":[2,98],"161":[2,98],"162":[2,98],"163":[2,98],"164":[2,98],"165":[2,98]},{"1":[2,116],"4":[2,116],"29":[2,116],"30":[2,116],"51":[2,116],"59":[2,116],"62":[2,116],"73":[2,116],"74":[2,116],"75":[2,116],"76":[2,116],"79":[2,116],"80":[2,116],"81":[2,116],"82":[2,116],"85":[2,116],"93":[2,116],"95":[2,116],"100":[2,116],"108":[2,116],"110":[2,116],"111":[2,116],"112":[2,116],"115":[2,116],"119":[2,116],"120":[2,116],"121":[2,116],"128":[2,116],"129":[2,116],"131":[2,116],"133":[2,116],"134":[2,116],"136":[2,116],"137":[2,116],"140":[2,116],"141":[2,116],"142":[2,116],"143":[2,116],"144":[2,116],"145":[2,116],"146":[2,116],"147":[2,116],"148":[2,116],"149":[2,116],"150":[2,116],"151":[2,116],"152":[2,116],"153":[2,116],"154":[2,116],"155":[2,116],"156":[2,116],"157":[2,116],"158":[2,116],"159":[2,116],"160":[2,116],"161":[2,116],"162":[2,116],"163":[2,116],"164":[2,116],"165":[2,116]},{"4":[2,124],"29":[2,124],"30":[2,124],"59":[2,124],"95":[2,124],"100":[2,124]},{"4":[2,94],"29":[2,94],"30":[2,94],"59":[2,94],"85":[2,94]},{"1":[2,118],"4":[2,118],"29":[2,118],"30":[2,118],"46":[2,118],"51":[2,118],"59":[2,118],"62":[2,118],"73":[2,118],"74":[2,118],"75":[2,118],"76":[2,118],"79":[2,118],"80":[2,118],"81":[2,118],"82":[2,118],"85":[2,118],"87":[2,118],"93":[2,118],"95":[2,118],"100":[2,118],"108":[2,118],"110":[2,118],"111":[2,118],"112":[2,118],"115":[2,118],"119":[2,118],"120":[2,118],"121":[2,118],"128":[2,118],"129":[2,118],"131":[2,118],"133":[2,118],"134":[2,118],"136":[2,118],"137":[2,118],"140":[2,118],"141":[2,118],"142":[2,118],"143":[2,118],"144":[2,118],"145":[2,118],"146":[2,118],"147":[2,118],"148":[2,118],"149":[2,118],"150":[2,118],"151":[2,118],"152":[2,118],"153":[2,118],"154":[2,118],"155":[2,118],"156":[2,118],"157":[2,118],"158":[2,118],"159":[2,118],"160":[2,118],"161":[2,118],"162":[2,118],"163":[2,118],"164":[2,118],"165":[2,118]},{"1":[2,156],"4":[2,156],"29":[2,156],"30":[2,156],"51":[1,116],"59":[2,156],"62":[1,133],"80":[2,156],"85":[2,156],"95":[2,156],"100":[2,156],"108":[2,156],"109":131,"110":[2,156],"111":[2,156],"112":[2,156],"115":[2,156],"119":[1,126],"120":[1,127],"121":[2,156],"128":[2,156],"129":[2,156],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]},{"1":[2,157],"4":[2,157],"29":[2,157],"30":[2,157],"51":[1,116],"59":[2,157],"62":[1,133],"80":[2,157],"85":[2,157],"95":[2,157],"100":[2,157],"108":[2,157],"109":131,"110":[2,157],"111":[2,157],"112":[2,157],"115":[2,157],"119":[1,126],"120":[1,127],"121":[2,157],"128":[2,157],"129":[2,157],"131":[1,128],"133":[1,101],"134":[1,100],"136":[1,95],"137":[1,96],"140":[1,97],"141":[1,98],"142":[1,99],"143":[1,102],"144":[1,103],"145":[1,104],"146":[1,105],"147":[1,106],"148":[1,107],"149":[1,108],"150":[1,109],"151":[1,110],"152":[1,111],"153":[1,112],"154":[1,113],"155":[1,114],"156":[1,115],"157":[1,117],"158":[1,118],"159":[1,119],"160":[1,120],"161":[1,121],"162":[1,122],"163":[1,123],"164":[1,124],"165":[1,125]}],
defaultActions: {"92":[2,4]},
parseError: function parseError(str, hash) {
    throw new Error(str);
},
parse: function parse(input) {
    var self = this,
        stack = [0],
        vstack = [null], // semantic value stack
        table = this.table,
        yytext = '',
        yylineno = 0,
        yyleng = 0,
        shifts = 0,
        reductions = 0,
        recovering = 0,
        TERROR = 2,
        EOF = 1;

    this.lexer.setInput(input);
    this.lexer.yy = this.yy;
    this.yy.lexer = this.lexer;

    var parseError = this.yy.parseError = typeof this.yy.parseError == 'function' ? this.yy.parseError : this.parseError;

    function popStack (n) {
        stack.length = stack.length - 2*n;
        vstack.length = vstack.length - n;
    }

    function checkRecover (st) {
        for (var p in table[st]) if (p == TERROR) {
            return true;
        }
        return false;
    }

    function lex() {
        var token;
        token = self.lexer.lex() || 1; // $end = 1
        // if token isn't its numeric value, convert
        if (typeof token !== 'number') {
            token = self.symbols_[token];
        }
        return token;
    };

    var symbol, preErrorSymbol, state, action, a, r, yyval={},p,len,newState, expected, recovered = false;
    while (true) {
        // retreive state number from top of stack
        state = stack[stack.length-1];

        // use default actions if available
        if (this.defaultActions[state]) {
            action = this.defaultActions[state];
        } else {
            if (symbol == null)
                symbol = lex();
            // read action for current state and first input
            action = table[state] && table[state][symbol];
        }

        // handle parse error
        if (typeof action === 'undefined' || !action.length || !action[0]) {

            if (!recovering) {
                // Report error
                expected = [];
                for (p in table[state]) if (this.terminals_[p] && p > 2) {
                    expected.push("'"+this.terminals_[p]+"'");
                }
                if (this.lexer.showPosition) {
                    parseError.call(this, 'Parse error on line '+(yylineno+1)+":\n"+this.lexer.showPosition()+'\nExpecting '+expected.join(', '),
                        {text: this.lexer.match, token: this.terminals_[symbol] || symbol, line: this.lexer.yylineno, expected: expected});
                } else {
                    parseError.call(this, 'Parse error on line '+(yylineno+1)+": Unexpected '"+this.terminals_[symbol]+"'",
                        {text: this.lexer.match, token: this.terminals_[symbol] || symbol, line: this.lexer.yylineno, expected: expected});
                }
            }

            // just recovered from another error
            if (recovering == 3) {
                if (symbol == EOF) {
                    throw 'Parsing halted.'
                }

                // discard current lookahead and grab another
                yyleng = this.lexer.yyleng;
                yytext = this.lexer.yytext;
                yylineno = this.lexer.yylineno;
                symbol = lex();
            }

            // try to recover from error
            while (1) {
                // check for error recovery rule in this state
                if (checkRecover(state)) {
                    break;
                }
                if (state == 0) {
                    throw 'Parsing halted.'
                }
                popStack(1);
                state = stack[stack.length-1];
            }
            
            preErrorSymbol = symbol; // save the lookahead token
            symbol = TERROR;         // insert generic error symbol as new lookahead
            state = stack[stack.length-1];
            action = table[state] && table[state][TERROR];
            recovering = 3; // allow 3 real symbols to be shifted before reporting a new error
        }

        // this shouldn't happen, unless resolve defaults are off
        if (action[0] instanceof Array && action.length > 1) {
            throw new Error('Parse Error: multiple actions possible at state: '+state+', token: '+symbol);
        }

        a = action; 

        switch (a[0]) {

            case 1: // shift
                shifts++;

                stack.push(symbol);
                vstack.push(this.lexer.yytext); // semantic values or junk only, no terminals
                stack.push(a[1]); // push state
                symbol = null;
                if (!preErrorSymbol) { // normal execution/no error
                    yyleng = this.lexer.yyleng;
                    yytext = this.lexer.yytext;
                    yylineno = this.lexer.yylineno;
                    if (recovering > 0)
                        recovering--;
                } else { // error just occurred, resume old lookahead f/ before error
                    symbol = preErrorSymbol;
                    preErrorSymbol = null;
                }
                break;

            case 2: // reduce
                reductions++;

                len = this.productions_[a[1]][1];

                // perform semantic action
                yyval.$ = vstack[vstack.length-len]; // default to $$ = $1
                r = this.performAction.call(yyval, yytext, yyleng, yylineno, this.yy, a[1], vstack);

                if (typeof r !== 'undefined') {
                    return r;
                }

                // pop off stack
                if (len) {
                    stack = stack.slice(0,-1*len*2);
                    vstack = vstack.slice(0, -1*len);
                }

                stack.push(this.productions_[a[1]][0]);    // push nonterminal (reduce)
                vstack.push(yyval.$);
                // goto new state = table[STATE][NONTERMINAL]
                newState = table[stack[stack.length-2]][stack[stack.length-1]];
                stack.push(newState);
                break;

            case 3: // accept

                this.reductionCount = reductions;
                this.shiftCount = shifts;
                return true;
        }

    }

    return true;
}};
return parser;
})();
if (typeof require !== 'undefined') {
exports.parser = parser;
exports.parse = function () { return parser.parse.apply(parser, arguments); }
exports.main = function commonjsMain(args) {
    var cwd = require("file").path(require("file").cwd());
    if (!args[1])
        throw new Error('Usage: '+args[0]+' FILE');
    var source = cwd.join(args[1]).read({charset: "utf-8"});
    exports.parser.parse(source);
}
if (require.main === module) {
	exports.main(require("system").args);
}
}(function(){
  var Scope;
  var __hasProp = Object.prototype.hasOwnProperty;
  // The **Scope** class regulates lexical scoping within CoffeeScript. As you
  // generate code, you create a tree of scopes in the same shape as the nested
  // function bodies. Each scope knows about the variables declared within it,
  // and has a reference to its parent enclosing scope. In this way, we know which
  // variables are new and need to be declared with `var`, and which are shared
  // with the outside.
  // Set up exported variables for both **Node.js** and the browser.
  if (!((typeof process !== "undefined" && process !== null))) {
    this.exports = this;
  }
  exports.Scope = (function() {
    Scope = function(parent, expressions, method) {
      var _a;
      _a = [parent, expressions, method];
      this.parent = _a[0];
      this.expressions = _a[1];
      this.method = _a[2];
      this.variables = {};
      if (this.parent) {
        this.tempVar = this.parent.tempVar;
      } else {
        Scope.root = this;
        this.tempVar = '_a';
      }
      return this;
    };
    // The top-level **Scope** object.
    Scope.root = null;
    // Initialize a scope with its parent, for lookups up the chain,
    // as well as a reference to the **Expressions** node is belongs to, which is
    // where it should declare its variables, and a reference to the function that
    // it wraps.
    // Look up a variable name in lexical scope, and declare it if it does not
    // already exist.
    Scope.prototype.find = function(name) {
      if (this.check(name)) {
        return true;
      }
      this.variables[name] = 'var';
      return false;
    };
    // Test variables and return true the first time fn(v, k) returns true
    Scope.prototype.any = function(fn) {
      var _a, k, v;
      _a = this.variables;
      for (v in _a) { if (__hasProp.call(_a, v)) {
        k = _a[v];
        if (fn(v, k)) {
          return true;
        }
      }}
      return false;
    };
    // Reserve a variable name as originating from a function parameter for this
    // scope. No `var` required for internal references.
    Scope.prototype.parameter = function(name) {
      this.variables[name] = 'param';
      return this.variables[name];
    };
    // Just check to see if a variable has already been declared, without reserving.
    Scope.prototype.check = function(name) {
      if (this.variables.hasOwnProperty(name)) {
        return true;
      }
      return !!(this.parent && this.parent.check(name));
    };
    // If we need to store an intermediate result, find an available name for a
    // compiler-generated variable. `_a`, `_b`, and so on...
    Scope.prototype.freeVariable = function() {
      var ordinal;
      while (this.check(this.tempVar)) {
        ordinal = 1 + parseInt(this.tempVar.substr(1), 36);
        this.tempVar = '_' + ordinal.toString(36).replace(/\d/g, 'a');
      }
      this.variables[this.tempVar] = 'var';
      return this.tempVar;
    };
    // Ensure that an assignment is made at the top of this scope
    // (or at the top-level scope, if requested).
    Scope.prototype.assign = function(name, value) {
      this.variables[name] = {
        value: value,
        assigned: true
      };
      return this.variables[name];
    };
    // Does this scope reference any variables that need to be declared in the
    // given function body?
    Scope.prototype.hasDeclarations = function(body) {
      return body === this.expressions && this.any(function(k, val) {
        return val === 'var';
      });
    };
    // Does this scope reference any assignments that need to be declared at the
    // top of the given function body?
    Scope.prototype.hasAssignments = function(body) {
      return body === this.expressions && this.any(function(k, val) {
        return val.assigned;
      });
    };
    // Return the list of variables first declared in this scope.
    Scope.prototype.declaredVariables = function() {
      var _a, _b, key, val;
      return (function() {
        _a = []; _b = this.variables;
        for (key in _b) { if (__hasProp.call(_b, key)) {
          val = _b[key];
          val === 'var' ? _a.push(key) : null;
        }}
        return _a;
      }).call(this).sort();
    };
    // Return the list of assignments that are supposed to be made at the top
    // of this scope.
    Scope.prototype.assignedVariables = function() {
      var _a, _b, key, val;
      _a = []; _b = this.variables;
      for (key in _b) { if (__hasProp.call(_b, key)) {
        val = _b[key];
        val.assigned ? _a.push(("" + key + " = " + val.value)) : null;
      }}
      return _a;
    };
    // Compile the JavaScript for all of the variable declarations in this scope.
    Scope.prototype.compiledDeclarations = function() {
      return this.declaredVariables().join(', ');
    };
    // Compile the JavaScript for all of the variable assignments in this scope.
    Scope.prototype.compiledAssignments = function() {
      return this.assignedVariables().join(', ');
    };
    return Scope;
  }).call(this);
})();
(function(){
  var AccessorNode, ArrayNode, AssignNode, BaseNode, CallNode, ClassNode, ClosureNode, CodeNode, CommentNode, ExistenceNode, Expressions, ExtendsNode, ForNode, IDENTIFIER, IS_STRING, IfNode, InNode, IndexNode, LiteralNode, NUMBER, ObjectNode, OpNode, ParentheticalNode, PushNode, RangeNode, ReturnNode, Scope, SliceNode, SplatNode, TAB, TRAILING_WHITESPACE, ThrowNode, TryNode, UTILITIES, ValueNode, WhileNode, _a, compact, del, flatten, helpers, include, indexOf, literal, merge, starts, utility;
  var __extends = function(child, parent) {
    var ctor = function(){ };
    ctor.prototype = parent.prototype;
    child.__superClass__ = parent.prototype;
    child.prototype = new ctor();
    child.prototype.constructor = child;
  };
  // `nodes.coffee` contains all of the node classes for the syntax tree. Most
  // nodes are created as the result of actions in the [grammar](grammar.html),
  // but some are created by other nodes as a method of code generation. To convert
  // the syntax tree into a string of JavaScript code, call `compile()` on the root.
  // Set up for both **Node.js** and the browser, by
  // including the [Scope](scope.html) class and the [helper](helpers.html) functions.
  if ((typeof process !== "undefined" && process !== null)) {
    Scope = require('./scope').Scope;
    helpers = require('./helpers').helpers;
  } else {
    this.exports = this;
    helpers = this.helpers;
    Scope = this.Scope;
  }
  // Import the helpers we plan to use.
  _a = helpers;
  compact = _a.compact;
  flatten = _a.flatten;
  merge = _a.merge;
  del = _a.del;
  include = _a.include;
  indexOf = _a.indexOf;
  starts = _a.starts;
  //### BaseNode
  // The **BaseNode** is the abstract base class for all nodes in the syntax tree.
  // Each subclass implements the `compileNode` method, which performs the
  // code generation for that node. To compile a node to JavaScript,
  // call `compile` on it, which wraps `compileNode` in some generic extra smarts,
  // to know when the generated code needs to be wrapped up in a closure.
  // An options hash is passed and cloned throughout, containing information about
  // the environment from higher in the tree (such as if a returned value is
  // being requested by the surrounding function), information about the current
  // scope, and indentation level.
  exports.BaseNode = (function() {
    BaseNode = function() {    };
    // Common logic for determining whether to wrap this node in a closure before
    // compiling it, or to compile directly. We need to wrap if this node is a
    // *statement*, and it's not a *pureStatement*, and we're not at
    // the top level of a block (which would be unnecessary), and we haven't
    // already been asked to return the result (because statements know how to
    // return results).
    // If a Node is *topSensitive*, that means that it needs to compile differently
    // depending on whether it's being used as part of a larger expression, or is a
    // top-level statement within the function body.
    BaseNode.prototype.compile = function(o) {
      var closure, top;
      this.options = merge(o || {});
      this.tab = o.indent;
      if (!(this instanceof ValueNode || this instanceof CallNode)) {
        del(this.options, 'operation');
        if (!(this instanceof AccessorNode || this instanceof IndexNode)) {
          del(this.options, 'chainRoot');
        }
      }
      top = this.topSensitive() ? this.options.top : del(this.options, 'top');
      closure = this.isStatement() && !this.isPureStatement() && !top && !this.options.asStatement && !(this instanceof CommentNode) && !this.containsPureStatement();
      if (closure) {
        return this.compileClosure(this.options);
      } else {
        return this.compileNode(this.options);
      }
    };
    // Statements converted into expressions via closure-wrapping share a scope
    // object with their parent closure, to preserve the expected lexical scope.
    BaseNode.prototype.compileClosure = function(o) {
      this.tab = o.indent;
      o.sharedScope = o.scope;
      return ClosureNode.wrap(this).compile(o);
    };
    // If the code generation wishes to use the result of a complex expression
    // in multiple places, ensure that the expression is only ever evaluated once,
    // by assigning it to a temporary variable.
    BaseNode.prototype.compileReference = function(o, options) {
      var compiled, pair, reference;
      pair = (function() {
        if (!(this instanceof CallNode || this instanceof ValueNode && (!(this.base instanceof LiteralNode) || this.hasProperties()))) {
          return [this, this];
        } else {
          reference = literal(o.scope.freeVariable());
          compiled = new AssignNode(reference, this);
          return [compiled, reference];
        }
      }).call(this);
      if (!(options && options.precompile)) {
        return pair;
      }
      return [pair[0].compile(o), pair[1].compile(o)];
    };
    // Convenience method to grab the current indentation level, plus tabbing in.
    BaseNode.prototype.idt = function(tabs) {
      var idt, num;
      idt = this.tab || '';
      num = (tabs || 0) + 1;
      while (num -= 1) {
        idt += TAB;
      }
      return idt;
    };
    // Construct a node that returns the current node's result.
    // Note that this is overridden for smarter behavior for
    // many statement nodes (eg IfNode, ForNode)...
    BaseNode.prototype.makeReturn = function() {
      return new ReturnNode(this);
    };
    // Does this node, or any of its children, contain a node of a certain kind?
    // Recursively traverses down the *children* of the nodes, yielding to a block
    // and returning true when the block finds a match. `contains` does not cross
    // scope boundaries.
    BaseNode.prototype.contains = function(block) {
      var contains;
      contains = false;
      this.traverseChildren(false, function(node) {
        if (block(node)) {
          contains = true;
          return false;
        }
      });
      return contains;
    };
    // Is this node of a certain type, or does it contain the type?
    BaseNode.prototype.containsType = function(type) {
      return this instanceof type || this.contains(function(n) {
        return n instanceof type;
      });
    };
    // Convenience for the most common use of contains. Does the node contain
    // a pure statement?
    BaseNode.prototype.containsPureStatement = function() {
      return this.isPureStatement() || this.contains(function(n) {
        return n.isPureStatement();
      });
    };
    // Perform an in-order traversal of the AST. Crosses scope boundaries.
    BaseNode.prototype.traverse = function(block) {
      return this.traverseChildren(true, block);
    };
    // `toString` representation of the node, for inspecting the parse tree.
    // This is what `coffee --nodes` prints out.
    BaseNode.prototype.toString = function(idt) {
      var _b, _c, _d, _e, child;
      idt = idt || '';
      return '\n' + idt + this['class'] + (function() {
        _b = []; _d = this.collectChildren();
        for (_c = 0, _e = _d.length; _c < _e; _c++) {
          child = _d[_c];
          _b.push(child.toString(idt + TAB));
        }
        return _b;
      }).call(this).join('');
    };
    BaseNode.prototype.eachChild = function(func) {
      var _b, _c, _d, _e, _f, _g, _h, attr, child;
      if (!(this.children)) {
        return null;
      }
      _b = []; _d = this.children;
      for (_c = 0, _e = _d.length; _c < _e; _c++) {
        attr = _d[_c];
        if (this[attr]) {
          _g = flatten([this[attr]]);
          for (_f = 0, _h = _g.length; _f < _h; _f++) {
            child = _g[_f];
            if (func(child) === false) {
              return null;
            }
          }
        }
      }
      return _b;
    };
    BaseNode.prototype.collectChildren = function() {
      var nodes;
      nodes = [];
      this.eachChild(function(node) {
        return nodes.push(node);
      });
      return nodes;
    };
    BaseNode.prototype.traverseChildren = function(crossScope, func) {
      return this.eachChild(function(child) {
        func.apply(this, arguments);
        if (child instanceof BaseNode) {
          return child.traverseChildren(crossScope, func);
        }
      });
    };
    // Default implementations of the common node properties and methods. Nodes
    // will override these with custom logic, if needed.
    BaseNode.prototype['class'] = 'BaseNode';
    BaseNode.prototype.children = [];
    BaseNode.prototype.unwrap = function() {
      return this;
    };
    BaseNode.prototype.isStatement = function() {
      return false;
    };
    BaseNode.prototype.isPureStatement = function() {
      return false;
    };
    BaseNode.prototype.topSensitive = function() {
      return false;
    };
    return BaseNode;
  })();
  //### Expressions
  // The expressions body is the list of expressions that forms the body of an
  // indented block of code -- the implementation of a function, a clause in an
  // `if`, `switch`, or `try`, and so on...
  exports.Expressions = (function() {
    Expressions = function(nodes) {
      this.expressions = compact(flatten(nodes || []));
      return this;
    };
    __extends(Expressions, BaseNode);
    Expressions.prototype['class'] = 'Expressions';
    Expressions.prototype.children = ['expressions'];
    Expressions.prototype.isStatement = function() {
      return true;
    };
    // Tack an expression on to the end of this expression list.
    Expressions.prototype.push = function(node) {
      this.expressions.push(node);
      return this;
    };
    // Add an expression at the beginning of this expression list.
    Expressions.prototype.unshift = function(node) {
      this.expressions.unshift(node);
      return this;
    };
    // If this Expressions consists of just a single node, unwrap it by pulling
    // it back out.
    Expressions.prototype.unwrap = function() {
      if (this.expressions.length === 1) {
        return this.expressions[0];
      } else {
        return this;
      }
    };
    // Is this an empty block of code?
    Expressions.prototype.empty = function() {
      return this.expressions.length === 0;
    };
    // An Expressions node does not return its entire body, rather it
    // ensures that the final expression is returned.
    Expressions.prototype.makeReturn = function() {
      var idx, last;
      idx = this.expressions.length - 1;
      last = this.expressions[idx];
      if (last instanceof CommentNode) {
        last = this.expressions[idx -= 1];
      }
      if (!last || last instanceof ReturnNode) {
        return this;
      }
      this.expressions[idx] = last.makeReturn();
      return this;
    };
    // An **Expressions** is the only node that can serve as the root.
    Expressions.prototype.compile = function(o) {
      o = o || {};
      if (o.scope) {
        return Expressions.__superClass__.compile.call(this, o);
      } else {
        return this.compileRoot(o);
      }
    };
    Expressions.prototype.compileNode = function(o) {
      var _b, _c, _d, _e, node;
      return (function() {
        _b = []; _d = this.expressions;
        for (_c = 0, _e = _d.length; _c < _e; _c++) {
          node = _d[_c];
          _b.push(this.compileExpression(node, merge(o)));
        }
        return _b;
      }).call(this).join("\n");
    };
    // If we happen to be the top-level **Expressions**, wrap everything in
    // a safety closure, unless requested not to.
    Expressions.prototype.compileRoot = function(o) {
      var code;
      o.indent = (this.tab = o.noWrap ? '' : TAB);
      o.scope = new Scope(null, this, null);
      code = o.globals ? this.compileNode(o) : this.compileWithDeclarations(o);
      code = code.replace(TRAILING_WHITESPACE, '');
      if (o.noWrap) {
        return code;
      } else {
        return "(function(){\n" + code + "\n})();\n";
      }
    };
    // Compile the expressions body for the contents of a function, with
    // declarations of all inner variables pushed up to the top.
    Expressions.prototype.compileWithDeclarations = function(o) {
      var code;
      code = this.compileNode(o);
      if (o.scope.hasAssignments(this)) {
        code = ("" + (this.tab) + "var " + (o.scope.compiledAssignments()) + ";\n" + code);
      }
      if (o.scope.hasDeclarations(this)) {
        code = ("" + (this.tab) + "var " + (o.scope.compiledDeclarations()) + ";\n" + code);
      }
      return code;
    };
    // Compiles a single expression within the expressions body. If we need to
    // return the result, and it's an expression, simply return it. If it's a
    // statement, ask the statement to do so.
    Expressions.prototype.compileExpression = function(node, o) {
      var compiledNode;
      this.tab = o.indent;
      compiledNode = node.compile(merge(o, {
        top: true
      }));
      if (node.isStatement()) {
        return compiledNode;
      } else {
        return "" + (this.idt()) + compiledNode + ";";
      }
    };
    return Expressions;
  })();
  // Wrap up the given nodes as an **Expressions**, unless it already happens
  // to be one.
  Expressions.wrap = function(nodes) {
    if (nodes.length === 1 && nodes[0] instanceof Expressions) {
      return nodes[0];
    }
    return new Expressions(nodes);
  };
  //### LiteralNode
  // Literals are static values that can be passed through directly into
  // JavaScript without translation, such as: strings, numbers,
  // `true`, `false`, `null`...
  exports.LiteralNode = (function() {
    LiteralNode = function(value) {
      this.value = value;
      return this;
    };
    __extends(LiteralNode, BaseNode);
    LiteralNode.prototype['class'] = 'LiteralNode';
    // Break and continue must be treated as pure statements -- they lose their
    // meaning when wrapped in a closure.
    LiteralNode.prototype.isStatement = function() {
      return this.value === 'break' || this.value === 'continue';
    };
    LiteralNode.prototype.isPureStatement = LiteralNode.prototype.isStatement;
    LiteralNode.prototype.compileNode = function(o) {
      var end, idt;
      idt = this.isStatement() ? this.idt() : '';
      end = this.isStatement() ? ';' : '';
      return "" + idt + this.value + end;
    };
    LiteralNode.prototype.toString = function(idt) {
      return " \"" + this.value + "\"";
    };
    return LiteralNode;
  })();
  //### ReturnNode
  // A `return` is a *pureStatement* -- wrapping it in a closure wouldn't
  // make sense.
  exports.ReturnNode = (function() {
    ReturnNode = function(expression) {
      this.expression = expression;
      return this;
    };
    __extends(ReturnNode, BaseNode);
    ReturnNode.prototype['class'] = 'ReturnNode';
    ReturnNode.prototype.isStatement = function() {
      return true;
    };
    ReturnNode.prototype.isPureStatement = function() {
      return true;
    };
    ReturnNode.prototype.children = ['expression'];
    ReturnNode.prototype.topSensitive = function() {
      return true;
    };
    ReturnNode.prototype.makeReturn = function() {
      return this;
    };
    ReturnNode.prototype.compileNode = function(o) {
      var expr;
      expr = this.expression.makeReturn();
      if (!(expr instanceof ReturnNode)) {
        return expr.compile(o);
      }
      del(o, 'top');
      if (this.expression.isStatement()) {
        o.asStatement = true;
      }
      return "" + (this.tab) + "return " + (this.expression.compile(o)) + ";";
    };
    return ReturnNode;
  })();
  //### ValueNode
  // A value, variable or literal or parenthesized, indexed or dotted into,
  // or vanilla.
  exports.ValueNode = (function() {
    ValueNode = function(base, properties) {
      this.base = base;
      this.properties = (properties || []);
      return this;
    };
    __extends(ValueNode, BaseNode);
    ValueNode.prototype.SOAK = " == undefined ? undefined : ";
    ValueNode.prototype['class'] = 'ValueNode';
    ValueNode.prototype.children = ['base', 'properties'];
    // A **ValueNode** has a base and a list of property accesses.
    // Add a property access to the list.
    ValueNode.prototype.push = function(prop) {
      this.properties.push(prop);
      return this;
    };
    ValueNode.prototype.hasProperties = function() {
      return !!this.properties.length;
    };
    // Some boolean checks for the benefit of other nodes.
    ValueNode.prototype.isArray = function() {
      return this.base instanceof ArrayNode && !this.hasProperties();
    };
    ValueNode.prototype.isObject = function() {
      return this.base instanceof ObjectNode && !this.hasProperties();
    };
    ValueNode.prototype.isSplice = function() {
      return this.hasProperties() && this.properties[this.properties.length - 1] instanceof SliceNode;
    };
    ValueNode.prototype.makeReturn = function() {
      if (this.hasProperties()) {
        return ValueNode.__superClass__.makeReturn.call(this);
      } else {
        return this.base.makeReturn();
      }
    };
    // The value can be unwrapped as its inner node, if there are no attached
    // properties.
    ValueNode.prototype.unwrap = function() {
      if (this.properties.length) {
        return this;
      } else {
        return this.base;
      }
    };
    // Values are considered to be statements if their base is a statement.
    ValueNode.prototype.isStatement = function() {
      return this.base.isStatement && this.base.isStatement() && !this.hasProperties();
    };
    ValueNode.prototype.isNumber = function() {
      return this.base instanceof LiteralNode && this.base.value.match(NUMBER);
    };
    // Works out if the value is the start of a chain.
    ValueNode.prototype.isStart = function(o) {
      var node;
      if (this === o.chainRoot && this.properties[0] instanceof AccessorNode) {
        return true;
      }
      node = o.chainRoot.base || o.chainRoot.variable;
      while (node instanceof CallNode) {
        node = node.variable;
      }
      return node === this;
    };
    // We compile a value to JavaScript by compiling and joining each property.
    // Things get much more insteresting if the chain of properties has *soak*
    // operators `?.` interspersed. Then we have to take care not to accidentally
    // evaluate a anything twice when building the soak chain.
    ValueNode.prototype.compileNode = function(o) {
      var _b, _c, baseline, complete, i, only, op, part, prop, props, temp;
      only = del(o, 'onlyFirst');
      op = del(o, 'operation');
      props = only ? this.properties.slice(0, this.properties.length - 1) : this.properties;
      o.chainRoot = o.chainRoot || this;
      baseline = this.base.compile(o);
      if (this.hasProperties() && (this.base instanceof ObjectNode || this.isNumber())) {
        baseline = ("(" + baseline + ")");
      }
      complete = (this.last = baseline);
      _b = props;
      for (i = 0, _c = _b.length; i < _c; i++) {
        prop = _b[i];
        this.source = baseline;
        if (prop.soakNode) {
          if (this.base instanceof CallNode && i === 0) {
            temp = o.scope.freeVariable();
            complete = ("(" + (baseline = temp) + " = (" + complete + "))");
          }
          if (i === 0 && this.isStart(o)) {
            complete = ("typeof " + complete + " === \"undefined\" || " + baseline);
          }
          complete += this.SOAK + (baseline += prop.compile(o));
        } else {
          part = prop.compile(o);
          baseline += part;
          complete += part;
          this.last = part;
        }
      }
      if (op && this.wrapped) {
        return "(" + complete + ")";
      } else {
        return complete;
      }
    };
    return ValueNode;
  })();
  //### CommentNode
  // CoffeeScript passes through comments as JavaScript comments at the
  // same position.
  exports.CommentNode = (function() {
    CommentNode = function(lines, kind) {
      this.lines = lines;
      this.kind = kind;
      return this;
    };
    __extends(CommentNode, BaseNode);
    CommentNode.prototype['class'] = 'CommentNode';
    CommentNode.prototype.isStatement = function() {
      return true;
    };
    CommentNode.prototype.makeReturn = function() {
      return this;
    };
    CommentNode.prototype.compileNode = function(o) {
      var sep;
      if (this.kind === 'herecomment') {
        sep = '\n' + this.tab;
        return "" + this.tab + "/*" + sep + (this.lines.join(sep)) + "\n" + this.tab + "*/";
      } else {
        return ("" + this.tab + "//") + this.lines.join(("\n" + this.tab + "//"));
      }
    };
    return CommentNode;
  })();
  //### CallNode
  // Node for a function invocation. Takes care of converting `super()` calls into
  // calls against the prototype's function of the same name.
  exports.CallNode = (function() {
    CallNode = function(variable, args) {
      this.isNew = false;
      this.isSuper = variable === 'super';
      this.variable = this.isSuper ? null : variable;
      this.args = (args || []);
      this.compileSplatArguments = function(o) {
        return SplatNode.compileMixedArray.call(this, this.args, o);
      };
      return this;
    };
    __extends(CallNode, BaseNode);
    CallNode.prototype['class'] = 'CallNode';
    CallNode.prototype.children = ['variable', 'args'];
    // Tag this invocation as creating a new instance.
    CallNode.prototype.newInstance = function() {
      this.isNew = true;
      return this;
    };
    CallNode.prototype.prefix = function() {
      if (this.isNew) {
        return 'new ';
      } else {
        return '';
      }
    };
    // Grab the reference to the superclass' implementation of the current method.
    CallNode.prototype.superReference = function(o) {
      var meth, methname;
      methname = o.scope.method.name;
      meth = (function() {
        if (o.scope.method.proto) {
          return "" + (o.scope.method.proto) + ".__superClass__." + methname;
        } else if (methname) {
          return "" + (methname) + ".__superClass__.constructor";
        } else {
          throw new Error("cannot call super on an anonymous function.");
        }
      })();
      return meth;
    };
    // Compile a vanilla function call.
    CallNode.prototype.compileNode = function(o) {
      var _b, _c, _d, _e, _f, _g, _h, arg, args, compilation;
      if (!(o.chainRoot)) {
        o.chainRoot = this;
      }
      _c = this.args;
      for (_b = 0, _d = _c.length; _b < _d; _b++) {
        arg = _c[_b];
        arg instanceof SplatNode ? (compilation = this.compileSplat(o)) : null;
      }
      if (!(compilation)) {
        args = (function() {
          _e = []; _g = this.args;
          for (_f = 0, _h = _g.length; _f < _h; _f++) {
            arg = _g[_f];
            _e.push(arg.compile(o));
          }
          return _e;
        }).call(this).join(', ');
        compilation = this.isSuper ? this.compileSuper(args, o) : ("" + (this.prefix()) + (this.variable.compile(o)) + "(" + args + ")");
      }
      if (o.operation && this.wrapped) {
        return "(" + compilation + ")";
      } else {
        return compilation;
      }
    };
    // `super()` is converted into a call against the superclass's implementation
    // of the current function.
    CallNode.prototype.compileSuper = function(args, o) {
      return "" + (this.superReference(o)) + ".call(this" + (args.length ? ', ' : '') + args + ")";
    };
    // If you call a function with a splat, it's converted into a JavaScript
    // `.apply()` call to allow an array of arguments to be passed.
    CallNode.prototype.compileSplat = function(o) {
      var meth, obj, temp;
      meth = this.variable ? this.variable.compile(o) : this.superReference(o);
      obj = this.variable && this.variable.source || 'this';
      if (obj.match(/\(/)) {
        temp = o.scope.freeVariable();
        obj = temp;
        meth = ("(" + temp + " = " + (this.variable.source) + ")" + (this.variable.last));
      }
      return "" + (this.prefix()) + (meth) + ".apply(" + obj + ", " + (this.compileSplatArguments(o)) + ")";
    };
    return CallNode;
  })();
  //### ExtendsNode
  // Node to extend an object's prototype with an ancestor object.
  // After `goog.inherits` from the
  // [Closure Library](http://closure-library.googlecode.com/svn/docs/closureGoogBase.js.html).
  exports.ExtendsNode = (function() {
    ExtendsNode = function(child, parent) {
      this.child = child;
      this.parent = parent;
      return this;
    };
    __extends(ExtendsNode, BaseNode);
    ExtendsNode.prototype['class'] = 'ExtendsNode';
    ExtendsNode.prototype.children = ['child', 'parent'];
    // Hooks one constructor into another's prototype chain.
    ExtendsNode.prototype.compileNode = function(o) {
      var ref;
      ref = new ValueNode(literal(utility('extends')));
      return (new CallNode(ref, [this.child, this.parent])).compile(o);
    };
    return ExtendsNode;
  })();
  //### AccessorNode
  // A `.` accessor into a property of a value, or the `::` shorthand for
  // an accessor into the object's prototype.
  exports.AccessorNode = (function() {
    AccessorNode = function(name, tag) {
      this.name = name;
      this.prototype = tag === 'prototype' ? '.prototype' : '';
      this.soakNode = tag === 'soak';
      return this;
    };
    __extends(AccessorNode, BaseNode);
    AccessorNode.prototype['class'] = 'AccessorNode';
    AccessorNode.prototype.children = ['name'];
    AccessorNode.prototype.compileNode = function(o) {
      var name, namePart;
      name = this.name.compile(o);
      o.chainRoot.wrapped = o.chainRoot.wrapped || this.soakNode;
      namePart = name.match(IS_STRING) ? ("[" + name + "]") : ("." + name);
      return this.prototype + namePart;
    };
    return AccessorNode;
  })();
  //### IndexNode
  // A `[ ... ]` indexed accessor into an array or object.
  exports.IndexNode = (function() {
    IndexNode = function(index) {
      this.index = index;
      return this;
    };
    __extends(IndexNode, BaseNode);
    IndexNode.prototype['class'] = 'IndexNode';
    IndexNode.prototype.children = ['index'];
    IndexNode.prototype.compileNode = function(o) {
      var idx, prefix;
      o.chainRoot.wrapped = o.chainRoot.wrapped || this.soakNode;
      idx = this.index.compile(o);
      prefix = this.proto ? '.prototype' : '';
      return "" + prefix + "[" + idx + "]";
    };
    return IndexNode;
  })();
  //### RangeNode
  // A range literal. Ranges can be used to extract portions (slices) of arrays,
  // to specify a range for comprehensions, or as a value, to be expanded into the
  // corresponding array of integers at runtime.
  exports.RangeNode = (function() {
    RangeNode = function(from, to, exclusive) {
      this.from = from;
      this.to = to;
      this.exclusive = !!exclusive;
      return this;
    };
    __extends(RangeNode, BaseNode);
    RangeNode.prototype['class'] = 'RangeNode';
    RangeNode.prototype.children = ['from', 'to'];
    // Compiles the range's source variables -- where it starts and where it ends.
    // But only if they need to be cached to avoid double evaluation.
    RangeNode.prototype.compileVariables = function(o) {
      var _b, _c, parts;
      _b = this.from.compileReference(o);
      this.from = _b[0];
      this.fromVar = _b[1];
      _c = this.to.compileReference(o);
      this.to = _c[0];
      this.toVar = _c[1];
      parts = [];
      if (this.from !== this.fromVar) {
        parts.push(this.from.compile(o));
      }
      if (this.to !== this.toVar) {
        parts.push(this.to.compile(o));
      }
      if (parts.length) {
        return "" + (parts.join('; ')) + ";\n" + o.indent;
      } else {
        return '';
      }
    };
    // When compiled normally, the range returns the contents of the *for loop*
    // needed to iterate over the values in the range. Used by comprehensions.
    RangeNode.prototype.compileNode = function(o) {
      var equals, idx, op, step, vars;
      if (!(o.index)) {
        return this.compileArray(o);
      }
      idx = del(o, 'index');
      step = del(o, 'step');
      vars = ("" + idx + " = " + (this.fromVar.compile(o)));
      step = step ? step.compile(o) : '1';
      equals = this.exclusive ? '' : '=';
      op = starts(step, '-') ? (">" + equals) : ("<" + equals);
      return "" + vars + "; " + (idx) + " " + op + " " + (this.toVar.compile(o)) + "; " + idx + " += " + step;
    };
    // When used as a value, expand the range into the equivalent array.
    RangeNode.prototype.compileArray = function(o) {
      var body, clause, equals, from, idt, post, pre, to, vars;
      idt = this.idt(1);
      vars = this.compileVariables(merge(o, {
        indent: idt
      }));
      equals = this.exclusive ? '' : '=';
      from = this.fromVar.compile(o);
      to = this.toVar.compile(o);
      clause = ("" + from + " <= " + to + " ?");
      pre = ("\n" + (idt) + "a = [];" + (vars));
      body = ("var i = " + from + "; (" + clause + " i <" + equals + " " + to + " : i >" + equals + " " + to + "); (" + clause + " i += 1 : i -= 1)");
      post = ("a.push(i);\n" + (idt) + "return a;\n" + o.indent);
      return "(function(){" + (pre) + "for (" + body + ") " + post + "}).call(this)";
    };
    return RangeNode;
  })();
  //### SliceNode
  // An array slice literal. Unlike JavaScript's `Array#slice`, the second parameter
  // specifies the index of the end of the slice, just as the first parameter
  // is the index of the beginning.
  exports.SliceNode = (function() {
    SliceNode = function(range) {
      this.range = range;
      return this;
    };
    __extends(SliceNode, BaseNode);
    SliceNode.prototype['class'] = 'SliceNode';
    SliceNode.prototype.children = ['range'];
    SliceNode.prototype.compileNode = function(o) {
      var from, plusPart, to;
      from = this.range.from.compile(o);
      to = this.range.to.compile(o);
      plusPart = this.range.exclusive ? '' : ' + 1';
      return ".slice(" + from + ", " + to + plusPart + ")";
    };
    return SliceNode;
  })();
  //### ObjectNode
  // An object literal, nothing fancy.
  exports.ObjectNode = (function() {
    ObjectNode = function(props) {
      this.objects = (this.properties = props || []);
      return this;
    };
    __extends(ObjectNode, BaseNode);
    ObjectNode.prototype['class'] = 'ObjectNode';
    ObjectNode.prototype.children = ['properties'];
    // All the mucking about with commas is to make sure that CommentNodes and
    // AssignNodes get interleaved correctly, with no trailing commas or
    // commas affixed to comments.
    ObjectNode.prototype.compileNode = function(o) {
      var _b, _c, _d, _e, _f, _g, _h, i, indent, inner, join, lastNoncom, nonComments, prop, props;
      o.indent = this.idt(1);
      nonComments = (function() {
        _b = []; _d = this.properties;
        for (_c = 0, _e = _d.length; _c < _e; _c++) {
          prop = _d[_c];
          !(prop instanceof CommentNode) ? _b.push(prop) : null;
        }
        return _b;
      }).call(this);
      lastNoncom = nonComments[nonComments.length - 1];
      props = (function() {
        _f = []; _g = this.properties;
        for (i = 0, _h = _g.length; i < _h; i++) {
          prop = _g[i];
          _f.push((function() {
            join = ",\n";
            if ((prop === lastNoncom) || (prop instanceof CommentNode)) {
              join = "\n";
            }
            if (i === this.properties.length - 1) {
              join = '';
            }
            indent = prop instanceof CommentNode ? '' : this.idt(1);
            if (!(prop instanceof AssignNode || prop instanceof CommentNode)) {
              prop = new AssignNode(prop, prop, 'object');
            }
            return indent + prop.compile(o) + join;
          }).call(this));
        }
        return _f;
      }).call(this);
      props = props.join('');
      inner = props ? '\n' + props + '\n' + this.idt() : '';
      return "{" + inner + "}";
    };
    return ObjectNode;
  })();
  //### ArrayNode
  // An array literal.
  exports.ArrayNode = (function() {
    ArrayNode = function(objects) {
      this.objects = objects || [];
      this.compileSplatLiteral = function(o) {
        return SplatNode.compileMixedArray.call(this, this.objects, o);
      };
      return this;
    };
    __extends(ArrayNode, BaseNode);
    ArrayNode.prototype['class'] = 'ArrayNode';
    ArrayNode.prototype.children = ['objects'];
    ArrayNode.prototype.compileNode = function(o) {
      var _b, _c, code, i, obj, objects;
      o.indent = this.idt(1);
      objects = [];
      _b = this.objects;
      for (i = 0, _c = _b.length; i < _c; i++) {
        obj = _b[i];
        code = obj.compile(o);
        if (obj instanceof SplatNode) {
          return this.compileSplatLiteral(this.objects, o);
        } else if (obj instanceof CommentNode) {
          objects.push(("\n" + code + "\n" + o.indent));
        } else if (i === this.objects.length - 1) {
          objects.push(code);
        } else {
          objects.push(("" + code + ", "));
        }
      }
      objects = objects.join('');
      if (indexOf(objects, '\n') >= 0) {
        return "[\n" + (this.idt(1)) + objects + "\n" + this.tab + "]";
      } else {
        return "[" + objects + "]";
      }
    };
    return ArrayNode;
  })();
  //### ClassNode
  // The CoffeeScript class definition.
  exports.ClassNode = (function() {
    ClassNode = function(variable, parent, props) {
      this.variable = variable;
      this.parent = parent;
      this.properties = props || [];
      this.returns = false;
      return this;
    };
    __extends(ClassNode, BaseNode);
    ClassNode.prototype['class'] = 'ClassNode';
    ClassNode.prototype.children = ['variable', 'parent', 'properties'];
    ClassNode.prototype.isStatement = function() {
      return true;
    };
    // Initialize a **ClassNode** with its name, an optional superclass, and a
    // list of prototype property assignments.
    ClassNode.prototype.makeReturn = function() {
      this.returns = true;
      return this;
    };
    // Instead of generating the JavaScript string directly, we build up the
    // equivalent syntax tree and compile that, in pieces. You can see the
    // constructor, property assignments, and inheritance getting built out below.
    ClassNode.prototype.compileNode = function(o) {
      var _b, _c, _d, _e, access, applied, className, constScope, construct, constructor, extension, func, me, pname, prop, props, pvar, returns, val;
      extension = this.parent && new ExtendsNode(this.variable, this.parent);
      props = new Expressions();
      o.top = true;
      me = null;
      className = this.variable.compile(o);
      constScope = null;
      if (this.parent) {
        applied = new ValueNode(this.parent, [new AccessorNode(literal('apply'))]);
        constructor = new CodeNode([], new Expressions([new CallNode(applied, [literal('this'), literal('arguments')])]));
      } else {
        constructor = new CodeNode();
      }
      _c = this.properties;
      for (_b = 0, _d = _c.length; _b < _d; _b++) {
        prop = _c[_b];
        _e = [prop.variable, prop.value];
        pvar = _e[0];
        func = _e[1];
        if (pvar && pvar.base.value === 'constructor' && func instanceof CodeNode) {
          func.name = className;
          func.body.push(new ReturnNode(literal('this')));
          this.variable = new ValueNode(this.variable);
          this.variable.namespaced = include(func.name, '.');
          constructor = func;
          continue;
        }
        if (func instanceof CodeNode && func.bound) {
          func.bound = false;
          constScope = constScope || new Scope(o.scope, constructor.body, constructor);
          me = me || constScope.freeVariable();
          pname = pvar.compile(o);
          if (constructor.body.empty()) {
            constructor.body.push(new ReturnNode(literal('this')));
          }
          constructor.body.unshift(literal(("this." + (pname) + " = function(){ return " + (className) + ".prototype." + (pname) + ".apply(" + me + ", arguments); }")));
        }
        if (pvar) {
          access = prop.context === 'this' ? pvar.base.properties[0] : new AccessorNode(pvar, 'prototype');
          val = new ValueNode(this.variable, [access]);
          prop = new AssignNode(val, func);
        }
        props.push(prop);
      }
      if (me) {
        constructor.body.unshift(literal(("" + me + " = this")));
      }
      construct = this.idt() + (new AssignNode(this.variable, constructor)).compile(merge(o, {
        sharedScope: constScope
      })) + ';\n';
      props = props.empty() ? '' : props.compile(o) + '\n';
      extension = extension ? this.idt() + extension.compile(o) + ';\n' : '';
      returns = this.returns ? new ReturnNode(this.variable).compile(o) : '';
      return "" + construct + extension + props + returns;
    };
    return ClassNode;
  })();
  //### AssignNode
  // The **AssignNode** is used to assign a local variable to value, or to set the
  // property of an object -- including within object literals.
  exports.AssignNode = (function() {
    AssignNode = function(variable, value, context) {
      this.variable = variable;
      this.value = value;
      this.context = context;
      return this;
    };
    __extends(AssignNode, BaseNode);
    // Matchers for detecting prototype assignments.
    AssignNode.prototype.PROTO_ASSIGN = /^(\S+)\.prototype/;
    AssignNode.prototype.LEADING_DOT = /^\.(prototype\.)?/;
    AssignNode.prototype['class'] = 'AssignNode';
    AssignNode.prototype.children = ['variable', 'value'];
    AssignNode.prototype.topSensitive = function() {
      return true;
    };
    AssignNode.prototype.isValue = function() {
      return this.variable instanceof ValueNode;
    };
    AssignNode.prototype.makeReturn = function() {
      return new Expressions([this, new ReturnNode(this.variable)]);
    };
    AssignNode.prototype.isStatement = function() {
      return this.isValue() && (this.variable.isArray() || this.variable.isObject());
    };
    // Compile an assignment, delegating to `compilePatternMatch` or
    // `compileSplice` if appropriate. Keep track of the name of the base object
    // we've been assigned to, for correct internal references. If the variable
    // has not been seen yet within the current scope, declare it.
    AssignNode.prototype.compileNode = function(o) {
      var last, match, name, proto, stmt, top, val;
      top = del(o, 'top');
      if (this.isStatement()) {
        return this.compilePatternMatch(o);
      }
      if (this.isValue() && this.variable.isSplice()) {
        return this.compileSplice(o);
      }
      stmt = del(o, 'asStatement');
      name = this.variable.compile(o);
      last = this.isValue() ? this.variable.last.replace(this.LEADING_DOT, '') : name;
      match = name.match(this.PROTO_ASSIGN);
      proto = match && match[1];
      if (this.value instanceof CodeNode) {
        if (last.match(IDENTIFIER)) {
          this.value.name = last;
        }
        if (proto) {
          this.value.proto = proto;
        }
      }
      val = this.value.compile(o);
      if (this.context === 'object') {
        return ("" + name + ": " + val);
      }
      if (!(this.isValue() && (this.variable.hasProperties() || this.variable.namespaced))) {
        o.scope.find(name);
      }
      val = ("" + name + " = " + val);
      if (stmt) {
        return ("" + this.tab + val + ";");
      }
      if (top) {
        return val;
      } else {
        return "(" + val + ")";
      }
    };
    // Brief implementation of recursive pattern matching, when assigning array or
    // object literals to a value. Peeks at their properties to assign inner names.
    // See the [ECMAScript Harmony Wiki](http://wiki.ecmascript.org/doku.php?id=harmony:destructuring)
    // for details.
    AssignNode.prototype.compilePatternMatch = function(o) {
      var _b, _c, _d, accessClass, assigns, code, i, idx, isString, obj, oindex, olength, splat, val, valVar, value;
      valVar = o.scope.freeVariable();
      value = this.value.isStatement() ? ClosureNode.wrap(this.value) : this.value;
      assigns = [("" + this.tab + valVar + " = " + (value.compile(o)) + ";")];
      o.top = true;
      o.asStatement = true;
      splat = false;
      _b = this.variable.base.objects;
      for (i = 0, _c = _b.length; i < _c; i++) {
        obj = _b[i];
        // A regular array pattern-match.
        idx = i;
        if (this.variable.isObject()) {
          if (obj instanceof AssignNode) {
            // A regular object pattern-match.
            _d = [obj.value, obj.variable.base];
            obj = _d[0];
            idx = _d[1];
          } else {
            // A shorthand `{a, b, c}: val` pattern-match.
            idx = obj;
          }
        }
        if (!(obj instanceof ValueNode || obj instanceof SplatNode)) {
          throw new Error('pattern matching must use only identifiers on the left-hand side.');
        }
        isString = idx.value && idx.value.match(IS_STRING);
        accessClass = isString || this.variable.isArray() ? IndexNode : AccessorNode;
        if (obj instanceof SplatNode && !splat) {
          val = literal(obj.compileValue(o, valVar, (oindex = indexOf(this.variable.base.objects, obj)), (olength = this.variable.base.objects.length) - oindex - 1));
          splat = true;
        } else {
          if (typeof idx !== 'object') {
            idx = literal(splat ? ("" + (valVar) + ".length - " + (olength - idx)) : idx);
          }
          val = new ValueNode(literal(valVar), [new accessClass(idx)]);
        }
        assigns.push(new AssignNode(obj, val).compile(o));
      }
      code = assigns.join("\n");
      return code;
    };
    // Compile the assignment from an array splice literal, using JavaScript's
    // `Array#splice` method.
    AssignNode.prototype.compileSplice = function(o) {
      var from, l, name, plus, range, to, val;
      name = this.variable.compile(merge(o, {
        onlyFirst: true
      }));
      l = this.variable.properties.length;
      range = this.variable.properties[l - 1].range;
      plus = range.exclusive ? '' : ' + 1';
      from = range.from.compile(o);
      to = range.to.compile(o) + ' - ' + from + plus;
      val = this.value.compile(o);
      return "" + (name) + ".splice.apply(" + name + ", [" + from + ", " + to + "].concat(" + val + "))";
    };
    return AssignNode;
  })();
  //### CodeNode
  // A function definition. This is the only node that creates a new Scope.
  // When for the purposes of walking the contents of a function body, the CodeNode
  // has no *children* -- they're within the inner scope.
  exports.CodeNode = (function() {
    CodeNode = function(params, body, tag) {
      this.params = params || [];
      this.body = body || new Expressions();
      this.bound = tag === 'boundfunc';
      return this;
    };
    __extends(CodeNode, BaseNode);
    CodeNode.prototype['class'] = 'CodeNode';
    CodeNode.prototype.children = ['params', 'body'];
    // Compilation creates a new scope unless explicitly asked to share with the
    // outer scope. Handles splat parameters in the parameter list by peeking at
    // the JavaScript `arguments` objects. If the function is bound with the `=>`
    // arrow, generates a wrapper that saves the current value of `this` through
    // a closure.
    CodeNode.prototype.compileNode = function(o) {
      var _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, code, func, i, inner, param, params, sharedScope, splat, top;
      sharedScope = del(o, 'sharedScope');
      top = del(o, 'top');
      o.scope = sharedScope || new Scope(o.scope, this.body, this);
      o.top = true;
      o.indent = this.idt(this.bound ? 2 : 1);
      del(o, 'noWrap');
      del(o, 'globals');
      i = 0;
      splat = undefined;
      params = [];
      _c = this.params;
      for (_b = 0, _d = _c.length; _b < _d; _b++) {
        param = _c[_b];
        if (param instanceof SplatNode && !(typeof splat !== "undefined" && splat !== null)) {
          splat = param;
          splat.index = i;
          splat.trailings = [];
          splat.arglength = this.params.length;
          this.body.unshift(splat);
        } else if ((typeof splat !== "undefined" && splat !== null)) {
          splat.trailings.push(param);
        } else {
          params.push(param);
        }
        i += 1;
      }
      params = (function() {
        _e = []; _g = params;
        for (_f = 0, _h = _g.length; _f < _h; _f++) {
          param = _g[_f];
          _e.push(param.compile(o));
        }
        return _e;
      })();
      this.body.makeReturn();
      _j = params;
      for (_i = 0, _k = _j.length; _i < _k; _i++) {
        param = _j[_i];
        (o.scope.parameter(param));
      }
      code = this.body.expressions.length ? ("\n" + (this.body.compileWithDeclarations(o)) + "\n") : '';
      func = ("function(" + (params.join(', ')) + ") {" + code + (this.idt(this.bound ? 1 : 0)) + "}");
      if (top && !this.bound) {
        func = ("(" + func + ")");
      }
      if (!(this.bound)) {
        return func;
      }
      inner = ("(function() {\n" + (this.idt(2)) + "return __func.apply(__this, arguments);\n" + (this.idt(1)) + "});");
      return "(function(__this) {\n" + (this.idt(1)) + "var __func = " + func + ";\n" + (this.idt(1)) + "return " + inner + "\n" + this.tab + "})(this)";
    };
    CodeNode.prototype.topSensitive = function() {
      return true;
    };
    // Short-circuit traverseChildren method to prevent it from crossing scope boundaries
    // unless crossScope is true
    CodeNode.prototype.traverseChildren = function(crossScope, func) {
      if (crossScope) {
        return CodeNode.__superClass__.traverseChildren.call(this, crossScope, func);
      }
    };
    CodeNode.prototype.toString = function(idt) {
      var _b, _c, _d, _e, child, children;
      idt = idt || '';
      children = (function() {
        _b = []; _d = this.collectChildren();
        for (_c = 0, _e = _d.length; _c < _e; _c++) {
          child = _d[_c];
          _b.push(child.toString(idt + TAB));
        }
        return _b;
      }).call(this).join('');
      return "\n" + idt + children;
    };
    return CodeNode;
  })();
  //### SplatNode
  // A splat, either as a parameter to a function, an argument to a call,
  // or as part of a destructuring assignment.
  exports.SplatNode = (function() {
    SplatNode = function(name) {
      if (!(name.compile)) {
        name = literal(name);
      }
      this.name = name;
      return this;
    };
    __extends(SplatNode, BaseNode);
    SplatNode.prototype['class'] = 'SplatNode';
    SplatNode.prototype.children = ['name'];
    SplatNode.prototype.compileNode = function(o) {
      var _b;
      if ((typeof (_b = this.index) !== "undefined" && _b !== null)) {
        return this.compileParam(o);
      } else {
        return this.name.compile(o);
      }
    };
    // Compiling a parameter splat means recovering the parameters that succeed
    // the splat in the parameter list, by slicing the arguments object.
    SplatNode.prototype.compileParam = function(o) {
      var _b, _c, idx, len, name, pos, trailing, variadic;
      name = this.name.compile(o);
      o.scope.find(name);
      len = o.scope.freeVariable();
      o.scope.assign(len, "arguments.length");
      variadic = o.scope.freeVariable();
      o.scope.assign(variadic, ("" + len + " >= " + this.arglength));
      _b = this.trailings;
      for (idx = 0, _c = _b.length; idx < _c; idx++) {
        trailing = _b[idx];
        pos = this.trailings.length - idx;
        o.scope.assign(trailing.compile(o), ("arguments[" + variadic + " ? " + len + " - " + pos + " : " + (this.index + idx) + "]"));
      }
      return "" + name + " = " + (utility('slice')) + ".call(arguments, " + this.index + ", " + len + " - " + (this.trailings.length) + ")";
    };
    // A compiling a splat as a destructuring assignment means slicing arguments
    // from the right-hand-side's corresponding array.
    SplatNode.prototype.compileValue = function(o, name, index, trailings) {
      var trail;
      trail = trailings ? (", " + (name) + ".length - " + trailings) : '';
      return "" + (utility('slice')) + ".call(" + name + ", " + index + trail + ")";
    };
    // Utility function that converts arbitrary number of elements, mixed with
    // splats, to a proper array
    SplatNode.compileMixedArray = function(list, o) {
      var _b, _c, _d, arg, args, code, i, prev;
      args = [];
      i = 0;
      _c = list;
      for (_b = 0, _d = _c.length; _b < _d; _b++) {
        arg = _c[_b];
        code = arg.compile(o);
        if (!(arg instanceof SplatNode)) {
          prev = args[i - 1];
          if (i === 1 && prev.substr(0, 1) === '[' && prev.substr(prev.length - 1, 1) === ']') {
            args[i - 1] = ("" + (prev.substr(0, prev.length - 1)) + ", " + code + "]");
            continue;
          } else if (i > 1 && prev.substr(0, 9) === '.concat([' && prev.substr(prev.length - 2, 2) === '])') {
            args[i - 1] = ("" + (prev.substr(0, prev.length - 2)) + ", " + code + "])");
            continue;
          } else {
            code = ("[" + code + "]");
          }
        }
        args.push(i === 0 ? code : (".concat(" + code + ")"));
        i += 1;
      }
      return args.join('');
    };
    return SplatNode;
  }).call(this);
  //### WhileNode
  // A while loop, the only sort of low-level loop exposed by CoffeeScript. From
  // it, all other loops can be manufactured. Useful in cases where you need more
  // flexibility or more speed than a comprehension can provide.
  exports.WhileNode = (function() {
    WhileNode = function(condition, opts) {
      if (opts && opts.invert) {
        if (condition instanceof OpNode) {
          condition = new ParentheticalNode(condition);
        }
        condition = new OpNode('!', condition);
      }
      this.condition = condition;
      this.guard = opts && opts.guard;
      return this;
    };
    __extends(WhileNode, BaseNode);
    WhileNode.prototype['class'] = 'WhileNode';
    WhileNode.prototype.children = ['condition', 'guard', 'body'];
    WhileNode.prototype.isStatement = function() {
      return true;
    };
    WhileNode.prototype.addBody = function(body) {
      this.body = body;
      return this;
    };
    WhileNode.prototype.makeReturn = function() {
      this.returns = true;
      return this;
    };
    WhileNode.prototype.topSensitive = function() {
      return true;
    };
    // The main difference from a JavaScript *while* is that the CoffeeScript
    // *while* can be used as a part of a larger expression -- while loops may
    // return an array containing the computed result of each iteration.
    WhileNode.prototype.compileNode = function(o) {
      var cond, post, pre, rvar, set, top;
      top = del(o, 'top') && !this.returns;
      o.indent = this.idt(1);
      o.top = true;
      cond = this.condition.compile(o);
      set = '';
      if (!(top)) {
        rvar = o.scope.freeVariable();
        set = ("" + this.tab + rvar + " = [];\n");
        if (this.body) {
          this.body = PushNode.wrap(rvar, this.body);
        }
      }
      pre = ("" + set + (this.tab) + "while (" + cond + ")");
      if (this.guard) {
        this.body = Expressions.wrap([new IfNode(this.guard, this.body)]);
      }
      this.returns ? (post = '\n' + new ReturnNode(literal(rvar)).compile(merge(o, {
        indent: this.idt()
      }))) : (post = '');
      return "" + pre + " {\n" + (this.body.compile(o)) + "\n" + this.tab + "}" + post;
    };
    return WhileNode;
  })();
  //### OpNode
  // Simple Arithmetic and logical operations. Performs some conversion from
  // CoffeeScript operations into their JavaScript equivalents.
  exports.OpNode = (function() {
    OpNode = function(operator, first, second, flip) {
      this.first = first;
      this.second = second;
      this.operator = this.CONVERSIONS[operator] || operator;
      this.flip = !!flip;
      return this;
    };
    __extends(OpNode, BaseNode);
    // The map of conversions from CoffeeScript to JavaScript symbols.
    OpNode.prototype.CONVERSIONS = {
      '==': '===',
      '!=': '!=='
    };
    // The list of operators for which we perform
    // [Python-style comparison chaining](http://docs.python.org/reference/expressions.html#notin).
    OpNode.prototype.CHAINABLE = ['<', '>', '>=', '<=', '===', '!=='];
    // Our assignment operators that have no JavaScript equivalent.
    OpNode.prototype.ASSIGNMENT = ['||=', '&&=', '?='];
    // Operators must come before their operands with a space.
    OpNode.prototype.PREFIX_OPERATORS = ['typeof', 'delete'];
    OpNode.prototype['class'] = 'OpNode';
    OpNode.prototype.children = ['first', 'second'];
    OpNode.prototype.isUnary = function() {
      return !this.second;
    };
    OpNode.prototype.isChainable = function() {
      return indexOf(this.CHAINABLE, this.operator) >= 0;
    };
    OpNode.prototype.compileNode = function(o) {
      o.operation = true;
      if (this.isChainable() && this.first.unwrap() instanceof OpNode && this.first.unwrap().isChainable()) {
        return this.compileChain(o);
      }
      if (indexOf(this.ASSIGNMENT, this.operator) >= 0) {
        return this.compileAssignment(o);
      }
      if (this.isUnary()) {
        return this.compileUnary(o);
      }
      if (this.operator === '?') {
        return this.compileExistence(o);
      }
      return [this.first.compile(o), this.operator, this.second.compile(o)].join(' ');
    };
    // Mimic Python's chained comparisons when multiple comparison operators are
    // used sequentially. For example:
    //     bin/coffee -e "puts 50 < 65 > 10"
    //     true
    OpNode.prototype.compileChain = function(o) {
      var _b, _c, first, second, shared;
      shared = this.first.unwrap().second;
      if (shared.containsType(CallNode)) {
        _b = shared.compileReference(o);
        this.first.second = _b[0];
        shared = _b[1];
      }
      _c = [this.first.compile(o), this.second.compile(o), shared.compile(o)];
      first = _c[0];
      second = _c[1];
      shared = _c[2];
      return "(" + first + ") && (" + shared + " " + this.operator + " " + second + ")";
    };
    // When compiling a conditional assignment, take care to ensure that the
    // operands are only evaluated once, even though we have to reference them
    // more than once.
    OpNode.prototype.compileAssignment = function(o) {
      var _b, first, second;
      _b = [this.first.compile(o), this.second.compile(o)];
      first = _b[0];
      second = _b[1];
      if (first.match(IDENTIFIER)) {
        o.scope.find(first);
      }
      if (this.operator === '?=') {
        return ("" + first + " = " + (ExistenceNode.compileTest(o, this.first)) + " ? " + first + " : " + second);
      }
      return "" + first + " = " + first + " " + (this.operator.substr(0, 2)) + " " + second;
    };
    // If this is an existence operator, we delegate to `ExistenceNode.compileTest`
    // to give us the safe references for the variables.
    OpNode.prototype.compileExistence = function(o) {
      var _b, first, second, test;
      _b = [this.first.compile(o), this.second.compile(o)];
      first = _b[0];
      second = _b[1];
      test = ExistenceNode.compileTest(o, this.first);
      return "" + test + " ? " + first + " : " + second;
    };
    // Compile a unary **OpNode**.
    OpNode.prototype.compileUnary = function(o) {
      var parts, space;
      space = indexOf(this.PREFIX_OPERATORS, this.operator) >= 0 ? ' ' : '';
      parts = [this.operator, space, this.first.compile(o)];
      if (this.flip) {
        parts = parts.reverse();
      }
      return parts.join('');
    };
    return OpNode;
  })();
  //### InNode
  exports.InNode = (function() {
    InNode = function(object, array) {
      this.object = object;
      this.array = array;
      return this;
    };
    __extends(InNode, BaseNode);
    InNode.prototype['class'] = 'InNode';
    InNode.prototype.children = ['object', 'array'];
    InNode.prototype.isArray = function() {
      return this.array instanceof ValueNode && this.array.isArray();
    };
    InNode.prototype.compileNode = function(o) {
      var _b;
      _b = this.object.compileReference(o, {
        precompile: true
      });
      this.obj1 = _b[0];
      this.obj2 = _b[1];
      if (this.isArray()) {
        return this.compileOrTest(o);
      } else {
        return this.compileLoopTest(o);
      }
    };
    InNode.prototype.compileOrTest = function(o) {
      var _b, _c, _d, i, item, tests;
      tests = (function() {
        _b = []; _c = this.array.base.objects;
        for (i = 0, _d = _c.length; i < _d; i++) {
          item = _c[i];
          _b.push(("" + (item.compile(o)) + " === " + (i ? this.obj2 : this.obj1)));
        }
        return _b;
      }).call(this);
      return "(" + (tests.join(' || ')) + ")";
    };
    InNode.prototype.compileLoopTest = function(o) {
      var _b, _c, body, i, l;
      _b = this.array.compileReference(o, {
        precompile: true
      });
      this.arr1 = _b[0];
      this.arr2 = _b[1];
      _c = [o.scope.freeVariable(), o.scope.freeVariable()];
      i = _c[0];
      l = _c[1];
      body = ("!!(function(){ for (var " + i + "=0, " + l + "=" + (this.arr1) + ".length; " + i + "<" + l + "; " + i + "++) if (" + (this.arr2) + "[" + i + "] === " + this.obj2 + ") return true; })()");
      if (this.obj1 !== this.obj2) {
        return "" + this.obj1 + ";\n" + this.tab + body;
      } else {
        return body;
      }
    };
    return InNode;
  })();
  //### TryNode
  // A classic *try/catch/finally* block.
  exports.TryNode = (function() {
    TryNode = function(attempt, error, recovery, ensure) {
      this.attempt = attempt;
      this.recovery = recovery;
      this.ensure = ensure;
      this.error = error;
      return this;
    };
    __extends(TryNode, BaseNode);
    TryNode.prototype['class'] = 'TryNode';
    TryNode.prototype.children = ['attempt', 'recovery', 'ensure'];
    TryNode.prototype.isStatement = function() {
      return true;
    };
    TryNode.prototype.makeReturn = function() {
      if (this.attempt) {
        this.attempt = this.attempt.makeReturn();
      }
      if (this.recovery) {
        this.recovery = this.recovery.makeReturn();
      }
      return this;
    };
    // Compilation is more or less as you would expect -- the *finally* clause
    // is optional, the *catch* is not.
    TryNode.prototype.compileNode = function(o) {
      var attemptPart, catchPart, errorPart, finallyPart;
      o.indent = this.idt(1);
      o.top = true;
      attemptPart = this.attempt.compile(o);
      errorPart = this.error ? (" (" + (this.error.compile(o)) + ") ") : ' ';
      catchPart = this.recovery ? (" catch" + errorPart + "{\n" + (this.recovery.compile(o)) + "\n" + this.tab + "}") : '';
      finallyPart = (this.ensure || '') && ' finally {\n' + this.ensure.compile(merge(o)) + ("\n" + this.tab + "}");
      return "" + (this.tab) + "try {\n" + attemptPart + "\n" + this.tab + "}" + catchPart + finallyPart;
    };
    return TryNode;
  })();
  //### ThrowNode
  // Simple node to throw an exception.
  exports.ThrowNode = (function() {
    ThrowNode = function(expression) {
      this.expression = expression;
      return this;
    };
    __extends(ThrowNode, BaseNode);
    ThrowNode.prototype['class'] = 'ThrowNode';
    ThrowNode.prototype.children = ['expression'];
    ThrowNode.prototype.isStatement = function() {
      return true;
    };
    // A **ThrowNode** is already a return, of sorts...
    ThrowNode.prototype.makeReturn = function() {
      return this;
    };
    ThrowNode.prototype.compileNode = function(o) {
      return "" + (this.tab) + "throw " + (this.expression.compile(o)) + ";";
    };
    return ThrowNode;
  })();
  //### ExistenceNode
  // Checks a variable for existence -- not *null* and not *undefined*. This is
  // similar to `.nil?` in Ruby, and avoids having to consult a JavaScript truth
  // table.
  exports.ExistenceNode = (function() {
    ExistenceNode = function(expression) {
      this.expression = expression;
      return this;
    };
    __extends(ExistenceNode, BaseNode);
    ExistenceNode.prototype['class'] = 'ExistenceNode';
    ExistenceNode.prototype.children = ['expression'];
    ExistenceNode.prototype.compileNode = function(o) {
      return ExistenceNode.compileTest(o, this.expression);
    };
    // The meat of the **ExistenceNode** is in this static `compileTest` method
    // because other nodes like to check the existence of their variables as well.
    // Be careful not to double-evaluate anything.
    ExistenceNode.compileTest = function(o, variable) {
      var _b, first, second;
      _b = variable.compileReference(o);
      first = _b[0];
      second = _b[1];
      return "(typeof " + (first.compile(o)) + " !== \"undefined\" && " + (second.compile(o)) + " !== null)";
    };
    return ExistenceNode;
  }).call(this);
  //### ParentheticalNode
  // An extra set of parentheses, specified explicitly in the source. At one time
  // we tried to clean up the results by detecting and removing redundant
  // parentheses, but no longer -- you can put in as many as you please.
  // Parentheses are a good way to force any statement to become an expression.
  exports.ParentheticalNode = (function() {
    ParentheticalNode = function(expression) {
      this.expression = expression;
      return this;
    };
    __extends(ParentheticalNode, BaseNode);
    ParentheticalNode.prototype['class'] = 'ParentheticalNode';
    ParentheticalNode.prototype.children = ['expression'];
    ParentheticalNode.prototype.isStatement = function() {
      return this.expression.isStatement();
    };
    ParentheticalNode.prototype.makeReturn = function() {
      return this.expression.makeReturn();
    };
    ParentheticalNode.prototype.compileNode = function(o) {
      var code, l;
      code = this.expression.compile(o);
      if (this.isStatement()) {
        return code;
      }
      l = code.length;
      if (code.substr(l - 1, 1) === ';') {
        code = code.substr(o, l - 1);
      }
      if (this.expression instanceof AssignNode) {
        return code;
      } else {
        return "(" + code + ")";
      }
    };
    return ParentheticalNode;
  })();
  //### ForNode
  // CoffeeScript's replacement for the *for* loop is our array and object
  // comprehensions, that compile into *for* loops here. They also act as an
  // expression, able to return the result of each filtered iteration.
  // Unlike Python array comprehensions, they can be multi-line, and you can pass
  // the current index of the loop as a second parameter. Unlike Ruby blocks,
  // you can map and filter in a single pass.
  exports.ForNode = (function() {
    ForNode = function(body, source, name, index) {
      var _b;
      this.body = body;
      this.name = name;
      this.index = index || null;
      this.source = source.source;
      this.guard = source.guard;
      this.step = source.step;
      this.object = !!source.object;
      if (this.object) {
        _b = [this.index, this.name];
        this.name = _b[0];
        this.index = _b[1];
      }
      this.pattern = this.name instanceof ValueNode;
      if (this.index instanceof ValueNode) {
        throw new Error('index cannot be a pattern matching expression');
      }
      this.returns = false;
      return this;
    };
    __extends(ForNode, BaseNode);
    ForNode.prototype['class'] = 'ForNode';
    ForNode.prototype.children = ['body', 'source', 'guard'];
    ForNode.prototype.isStatement = function() {
      return true;
    };
    ForNode.prototype.topSensitive = function() {
      return true;
    };
    ForNode.prototype.makeReturn = function() {
      this.returns = true;
      return this;
    };
    ForNode.prototype.compileReturnValue = function(val, o) {
      if (this.returns) {
        return '\n' + new ReturnNode(literal(val)).compile(o);
      }
      if (val) {
        return '\n' + val;
      }
      return '';
    };
    // Welcome to the hairiest method in all of CoffeeScript. Handles the inner
    // loop, filtering, stepping, and result saving for array, object, and range
    // comprehensions. Some of the generated code can be shared in common, and
    // some cannot.
    ForNode.prototype.compileNode = function(o) {
      var body, close, codeInBody, forPart, index, ivar, lvar, name, namePart, range, returnResult, rvar, scope, source, sourcePart, stepPart, svar, topLevel, varPart, vars;
      topLevel = del(o, 'top') && !this.returns;
      range = this.source instanceof ValueNode && this.source.base instanceof RangeNode && !this.source.properties.length;
      source = range ? this.source.base : this.source;
      codeInBody = this.body.contains(function(n) {
        return n instanceof CodeNode;
      });
      scope = o.scope;
      name = this.name && this.name.compile(o);
      index = this.index && this.index.compile(o);
      if (name && !this.pattern && !codeInBody) {
        scope.find(name);
      }
      if (index) {
        scope.find(index);
      }
      if (!(topLevel)) {
        rvar = scope.freeVariable();
      }
      ivar = (function() {
        if (range) {
          return name;
        } else if (codeInBody) {
          return scope.freeVariable();
        } else {
          return index || scope.freeVariable();
        }
      })();
      varPart = '';
      body = Expressions.wrap([this.body]);
      if (range) {
        sourcePart = source.compileVariables(o);
        forPart = source.compile(merge(o, {
          index: ivar,
          step: this.step
        }));
      } else {
        svar = scope.freeVariable();
        sourcePart = ("" + svar + " = " + (this.source.compile(o)) + ";");
        if (this.pattern) {
          namePart = new AssignNode(this.name, literal(("" + svar + "[" + ivar + "]"))).compile(merge(o, {
            indent: this.idt(1),
            top: true
          })) + "\n";
        } else {
          if (name) {
            namePart = ("" + name + " = " + svar + "[" + ivar + "]");
          }
        }
        if (!(this.object)) {
          lvar = scope.freeVariable();
          stepPart = this.step ? ("" + ivar + " += " + (this.step.compile(o))) : ("" + ivar + "++");
          forPart = ("" + ivar + " = 0, " + lvar + " = " + (svar) + ".length; " + ivar + " < " + lvar + "; " + stepPart);
        }
      }
      sourcePart = (rvar ? ("" + rvar + " = []; ") : '') + sourcePart;
      sourcePart = sourcePart ? ("" + this.tab + sourcePart + "\n" + this.tab) : this.tab;
      returnResult = this.compileReturnValue(rvar, o);
      if (!(topLevel)) {
        body = PushNode.wrap(rvar, body);
      }
      this.guard ? (body = Expressions.wrap([new IfNode(this.guard, body)])) : null;
      if (codeInBody) {
        if (namePart) {
          body.unshift(literal(("var " + namePart)));
        }
        if (index) {
          body.unshift(literal(("var " + index + " = " + ivar)));
        }
        body = ClosureNode.wrap(body, true);
      } else {
        if (namePart) {
          varPart = ("" + (this.idt(1)) + namePart + ";\n");
        }
      }
      this.object ? (forPart = ("" + ivar + " in " + svar + ") { if (" + (utility('hasProp')) + ".call(" + svar + ", " + ivar + ")")) : null;
      body = body.compile(merge(o, {
        indent: this.idt(1),
        top: true
      }));
      vars = range ? name : ("" + name + ", " + ivar);
      close = this.object ? '}}' : '}';
      return "" + (sourcePart) + "for (" + forPart + ") {\n" + varPart + body + "\n" + this.tab + close + returnResult;
    };
    return ForNode;
  })();
  //### IfNode
  // *If/else* statements. Our *switch/when* will be compiled into this. Acts as an
  // expression by pushing down requested returns to the last line of each clause.
  // Single-expression **IfNodes** are compiled into ternary operators if possible,
  // because ternaries are already proper expressions, and don't need conversion.
  exports.IfNode = (function() {
    IfNode = function(condition, body, tags) {
      this.condition = condition;
      this.body = body;
      this.elseBody = null;
      this.tags = tags || {};
      if (this.tags.invert) {
        this.condition = new OpNode('!', new ParentheticalNode(this.condition));
      }
      this.isChain = false;
      return this;
    };
    __extends(IfNode, BaseNode);
    IfNode.prototype['class'] = 'IfNode';
    IfNode.prototype.children = ['condition', 'switchSubject', 'body', 'elseBody', 'assigner'];
    IfNode.prototype.bodyNode = function() {
      return this.body == undefined ? undefined : this.body.unwrap();
    };
    IfNode.prototype.elseBodyNode = function() {
      return this.elseBody == undefined ? undefined : this.elseBody.unwrap();
    };
    IfNode.prototype.forceStatement = function() {
      this.tags.statement = true;
      return this;
    };
    // Tag a chain of **IfNodes** with their object(s) to switch on for equality
    // tests. `rewriteSwitch` will perform the actual change at compile time.
    IfNode.prototype.switchesOver = function(expression) {
      this.switchSubject = expression;
      return this;
    };
    // Rewrite a chain of **IfNodes** with their switch condition for equality.
    // Ensure that the switch expression isn't evaluated more than once.
    IfNode.prototype.rewriteSwitch = function(o) {
      var _b, _c, _d, cond, i, variable;
      this.assigner = this.switchSubject;
      if (!((this.switchSubject.unwrap() instanceof LiteralNode))) {
        variable = literal(o.scope.freeVariable());
        this.assigner = new AssignNode(variable, this.switchSubject);
        this.switchSubject = variable;
      }
      this.condition = (function() {
        _b = []; _c = flatten([this.condition]);
        for (i = 0, _d = _c.length; i < _d; i++) {
          cond = _c[i];
          _b.push((function() {
            if (cond instanceof OpNode) {
              cond = new ParentheticalNode(cond);
            }
            return new OpNode('==', (i === 0 ? this.assigner : this.switchSubject), cond);
          }).call(this));
        }
        return _b;
      }).call(this);
      if (this.isChain) {
        this.elseBodyNode().switchesOver(this.switchSubject);
      }
      // prevent this rewrite from happening again
      this.switchSubject = undefined;
      return this;
    };
    // Rewrite a chain of **IfNodes** to add a default case as the final *else*.
    IfNode.prototype.addElse = function(elseBody, statement) {
      if (this.isChain) {
        this.elseBodyNode().addElse(elseBody, statement);
      } else {
        this.isChain = elseBody instanceof IfNode;
        this.elseBody = this.ensureExpressions(elseBody);
      }
      return this;
    };
    // The **IfNode** only compiles into a statement if either of its bodies needs
    // to be a statement. Otherwise a ternary is safe.
    IfNode.prototype.isStatement = function() {
      return this.statement = this.statement || !!(this.comment || this.tags.statement || this.bodyNode().isStatement() || (this.elseBody && this.elseBodyNode().isStatement()));
    };
    IfNode.prototype.compileCondition = function(o) {
      var _b, _c, _d, _e, cond;
      return (function() {
        _b = []; _d = flatten([this.condition]);
        for (_c = 0, _e = _d.length; _c < _e; _c++) {
          cond = _d[_c];
          _b.push(cond.compile(o));
        }
        return _b;
      }).call(this).join(' || ');
    };
    IfNode.prototype.compileNode = function(o) {
      if (this.isStatement()) {
        return this.compileStatement(o);
      } else {
        return this.compileTernary(o);
      }
    };
    IfNode.prototype.makeReturn = function() {
      this.body = this.body && this.ensureExpressions(this.body.makeReturn());
      this.elseBody = this.elseBody && this.ensureExpressions(this.elseBody.makeReturn());
      return this;
    };
    IfNode.prototype.ensureExpressions = function(node) {
      if (node instanceof Expressions) {
        return node;
      } else {
        return new Expressions([node]);
      }
    };
    // Compile the **IfNode** as a regular *if-else* statement. Flattened chains
    // force inner *else* bodies into statement form.
    IfNode.prototype.compileStatement = function(o) {
      var body, child, comDent, condO, elsePart, ifDent, ifPart, prefix;
      if (this.switchSubject) {
        this.rewriteSwitch(o);
      }
      child = del(o, 'chainChild');
      condO = merge(o);
      o.indent = this.idt(1);
      o.top = true;
      ifDent = child ? '' : this.idt();
      comDent = child ? this.idt() : '';
      prefix = this.comment ? ("" + (this.comment.compile(condO)) + "\n" + comDent) : '';
      body = this.body.compile(o);
      ifPart = ("" + prefix + (ifDent) + "if (" + (this.compileCondition(condO)) + ") {\n" + body + "\n" + this.tab + "}");
      if (!(this.elseBody)) {
        return ifPart;
      }
      elsePart = this.isChain ? ' else ' + this.elseBodyNode().compile(merge(o, {
        indent: this.idt(),
        chainChild: true
      })) : (" else {\n" + (this.elseBody.compile(o)) + "\n" + this.tab + "}");
      return "" + ifPart + elsePart;
    };
    // Compile the IfNode as a ternary operator.
    IfNode.prototype.compileTernary = function(o) {
      var elsePart, ifPart;
      ifPart = this.condition.compile(o) + ' ? ' + this.bodyNode().compile(o);
      elsePart = this.elseBody ? this.elseBodyNode().compile(o) : 'null';
      return "" + ifPart + " : " + elsePart;
    };
    return IfNode;
  })();
  // Faux-Nodes
  // ----------
  //### PushNode
  // Faux-nodes are never created by the grammar, but are used during code
  // generation to generate other combinations of nodes. The **PushNode** creates
  // the tree for `array.push(value)`, which is helpful for recording the result
  // arrays from comprehensions.
  PushNode = (exports.PushNode = {
    wrap: function(array, expressions) {
      var expr;
      expr = expressions.unwrap();
      if (expr.isPureStatement() || expr.containsPureStatement()) {
        return expressions;
      }
      return Expressions.wrap([new CallNode(new ValueNode(literal(array), [new AccessorNode(literal('push'))]), [expr])]);
    }
  });
  //### ClosureNode
  // A faux-node used to wrap an expressions body in a closure.
  ClosureNode = (exports.ClosureNode = {
    // Wrap the expressions body, unless it contains a pure statement,
    // in which case, no dice. If the body mentions `this` or `arguments`,
    // then make sure that the closure wrapper preserves the original values.
    wrap: function(expressions, statement) {
      var args, call, func, mentionsArgs, mentionsThis, meth;
      if (expressions.containsPureStatement()) {
        return expressions;
      }
      func = new ParentheticalNode(new CodeNode([], Expressions.wrap([expressions])));
      args = [];
      mentionsArgs = expressions.contains(function(n) {
        return (n instanceof LiteralNode) && (n.value === 'arguments');
      });
      mentionsThis = expressions.contains(function(n) {
        return (n instanceof LiteralNode) && (n.value === 'this');
      });
      if (mentionsArgs || mentionsThis) {
        meth = literal(mentionsArgs ? 'apply' : 'call');
        args = [literal('this')];
        if (mentionsArgs) {
          args.push(literal('arguments'));
        }
        func = new ValueNode(func, [new AccessorNode(meth)]);
      }
      call = new CallNode(func, args);
      if (statement) {
        return Expressions.wrap([call]);
      } else {
        return call;
      }
    }
  });
  // Utility Functions
  // -----------------
  UTILITIES = {
    // Correctly set up a prototype chain for inheritance, including a reference
    // to the superclass for `super()` calls. See:
    // [goog.inherits](http://closure-library.googlecode.com/svn/docs/closureGoogBase.js.source.html#line1206).
    __extends: "function(child, parent) {\n    var ctor = function(){ };\n    ctor.prototype = parent.prototype;\n    child.__superClass__ = parent.prototype;\n    child.prototype = new ctor();\n    child.prototype.constructor = child;\n  }",
    // Shortcuts to speed up the lookup time for native functions.
    __hasProp: 'Object.prototype.hasOwnProperty',
    __slice: 'Array.prototype.slice'
  };
  // Constants
  // ---------
  // Tabs are two spaces for pretty printing.
  TAB = '  ';
  // Trim out all trailing whitespace, so that the generated code plays nice
  // with Git.
  TRAILING_WHITESPACE = /[ \t]+$/gm;
  // Keep these identifier regexes in sync with the Lexer.
  IDENTIFIER = /^[a-zA-Z\$_](\w|\$)*$/;
  NUMBER = /^(((\b0(x|X)[0-9a-fA-F]+)|((\b[0-9]+(\.[0-9]+)?|\.[0-9]+)(e[+\-]?[0-9]+)?)))\b$/i;
  // Is a literal value a string?
  IS_STRING = /^['"]/;
  // Utility Functions
  // -----------------
  // Handy helper for a generating LiteralNode.
  literal = function(name) {
    return new LiteralNode(name);
  };
  // Helper for ensuring that utility functions are assigned at the top level.
  utility = function(name) {
    var ref;
    ref = ("__" + name);
    Scope.root.assign(ref, UTILITIES[ref]);
    return ref;
  };
})();
(function(){
  var Lexer, compile, helpers, lexer, parser, path, processScripts;
  // CoffeeScript can be used both on the server, as a command-line compiler based
  // on Node.js/V8, or to run CoffeeScripts directly in the browser. This module
  // contains the main entry functions for tokenzing, parsing, and compiling source
  // CoffeeScript into JavaScript.
  // If included on a webpage, it will automatically sniff out, compile, and
  // execute all scripts present in `text/coffeescript` tags.
  // Set up dependencies correctly for both the server and the browser.
  if ((typeof process !== "undefined" && process !== null)) {
    path = require('path');
    Lexer = require('./lexer').Lexer;
    parser = require('./parser').parser;
    helpers = require('./helpers').helpers;
    helpers.extend(global, require('./nodes'));
    require.registerExtension ? require.registerExtension('.coffee', function(content) {
      return compile(content);
    }) : null;
  } else {
    this.exports = (this.CoffeeScript = {});
    Lexer = this.Lexer;
    parser = this.parser;
    helpers = this.helpers;
  }
  // The current CoffeeScript version number.
  exports.VERSION = '0.6.2';
  // Instantiate a Lexer for our use here.
  lexer = new Lexer();
  // Compile a string of CoffeeScript code to JavaScript, using the Coffee/Jison
  // compiler.
  exports.compile = (compile = function(code, options) {
    options = options || {};
    try {
      return (parser.parse(lexer.tokenize(code))).compile(options);
    } catch (err) {
      if (options.source) {
        err.message = ("In " + options.source + ", " + err.message);
      }
      throw err;
    }
  });
  // Tokenize a string of CoffeeScript code, and return the array of tokens.
  exports.tokens = function(code) {
    return lexer.tokenize(code);
  };
  // Tokenize and parse a string of CoffeeScript code, and return the AST. You can
  // then compile it by calling `.compile()` on the root, or traverse it by using
  // `.traverse()` with a callback.
  exports.nodes = function(code) {
    return parser.parse(lexer.tokenize(code));
  };
  // Compile and execute a string of CoffeeScript (on the server), correctly
  // setting `__filename`, `__dirname`, and relative `require()`.
  exports.run = (function(code, options) {
    var __dirname, __filename;
    module.filename = (__filename = options.source);
    __dirname = path.dirname(__filename);
    return eval(exports.compile(code, options));
  });
  // The real Lexer produces a generic stream of tokens. This object provides a
  // thin wrapper around it, compatible with the Jison API. We can then pass it
  // directly as a "Jison lexer".
  parser.lexer = {
    lex: function() {
      var token;
      token = this.tokens[this.pos] || [""];
      this.pos += 1;
      this.yylineno = token[2];
      this.yytext = token[1];
      return token[0];
    },
    setInput: function(tokens) {
      this.tokens = tokens;
      this.pos = 0;
      return this.pos;
    },
    upcomingInput: function() {
      return "";
    }
  };
  // Activate CoffeeScript in the browser by having it compile and evaluate
  // all script tags with a content-type of `text/coffeescript`. This happens
  // on page load. Unfortunately, the text contents of remote scripts cannot be
  // accessed from the browser, so only inline script tags will work.
  if ((typeof document !== "undefined" && document !== null) && document.getElementsByTagName) {
    processScripts = function() {
      var _a, _b, _c, _d, tag;
      _a = []; _c = document.getElementsByTagName('script');
      for (_b = 0, _d = _c.length; _b < _d; _b++) {
        tag = _c[_b];
        tag.type === 'text/coffeescript' ? _a.push(eval(exports.compile(tag.innerHTML))) : null;
      }
      return _a;
    };
    if (window.addEventListener) {
      window.addEventListener('load', processScripts, false);
    } else if (window.attachEvent) {
      window.attachEvent('onload', processScripts);
    }
  }
})();
