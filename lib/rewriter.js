(function(){
  var BALANCED_PAIRS, EXPRESSION_CLOSE, EXPRESSION_END, EXPRESSION_START, IMPLICIT_BLOCK, IMPLICIT_CALL, IMPLICIT_END, IMPLICIT_FUNC, INVERSES, Rewriter, SINGLE_CLOSERS, SINGLE_LINERS, _a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, helpers, include, pair;
  var __bind = function(func, obj, args) {
    return function() {
      return func.apply(obj || {}, args ? args.concat(__slice.call(arguments, 0)) : arguments);
    };
  }, __slice = Array.prototype.slice, __hasProp = Object.prototype.hasOwnProperty;
  // The CoffeeScript language has a good deal of optional syntax, implicit syntax,
  // and shorthand syntax. This can greatly complicate a grammar and bloat
  // the resulting parse table. Instead of making the parser handle it all, we take
  // a series of passes over the token stream, using this **Rewriter** to convert
  // shorthand into the unambiguous long form, add implicit indentation and
  // parentheses, balance incorrect nestings, and generally clean things up.
  // Set up exported variables for both Node.js and the browser.
  if ((typeof process !== "undefined" && process !== null)) {
    helpers = require('./helpers').helpers;
  } else {
    this.exports = this;
    helpers = this.helpers;
  }
  // Import the helpers we need.
  include = helpers.include;
  // The **Rewriter** class is used by the [Lexer](lexer.html), directly against
  // its internal array of tokens.
  exports.Rewriter = (function() {
    Rewriter = function Rewriter() {    };
    // Rewrite the token stream in multiple passes, one logical filter at
    // a time. This could certainly be changed into a single pass through the
    // stream, with a big ol' efficient switch, but it's much nicer to work with
    // like this. The order of these passes matters -- indentation must be
    // corrected before implicit parentheses can be wrapped around blocks of code.
    Rewriter.prototype.rewrite = function rewrite(tokens) {
      this.tokens = tokens;
      this.adjust_comments();
      this.remove_leading_newlines();
      this.remove_mid_expression_newlines();
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
    // as tokens are inserted and removed, and the stream changes length under
    // our feet.
    Rewriter.prototype.scan_tokens = function scan_tokens(block) {
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
    Rewriter.prototype.adjust_comments = function adjust_comments() {
      return this.scan_tokens(__bind(function(prev, token, post, i) {
          var after;
          if (!(token[0] === 'COMMENT')) {
            return 1;
          }
          after = this.tokens[i + 2];
          if (after && after[0] === 'INDENT') {
            this.tokens.splice(i + 2, 1);
            this.tokens.splice(i, 0, after);
            return 1;
          } else if (prev && prev[0] !== 'TERMINATOR' && prev[0] !== 'INDENT' && prev[0] !== 'OUTDENT') {
            this.tokens.splice(i, 0, ['TERMINATOR', "\n", prev[2]]);
            return 2;
          } else {
            return 1;
          }
        }, this));
    };
    // Leading newlines would introduce an ambiguity in the grammar, so we
    // dispatch them here.
    Rewriter.prototype.remove_leading_newlines = function remove_leading_newlines() {
      var _a;
      _a = [];
      while (this.tokens[0] && this.tokens[0][0] === 'TERMINATOR') {
        _a.push(this.tokens.shift());
      }
      return _a;
    };
    // Some blocks occur in the middle of expressions -- when we're expecting
    // this, remove their trailing newlines.
    Rewriter.prototype.remove_mid_expression_newlines = function remove_mid_expression_newlines() {
      return this.scan_tokens(__bind(function(prev, token, post, i) {
          if (!(post && include(EXPRESSION_CLOSE, post[0]) && token[0] === 'TERMINATOR')) {
            return 1;
          }
          this.tokens.splice(i, 1);
          return 0;
        }, this));
    };
    // The lexer has tagged the opening parenthesis of a method call, and the
    // opening bracket of an indexing operation. Match them with their paired
    // close.
    Rewriter.prototype.close_open_calls_and_indexes = function close_open_calls_and_indexes() {
      var brackets, parens;
      parens = [0];
      brackets = [0];
      return this.scan_tokens(__bind(function(prev, token, post, i) {
          var _a;
          if ((_a = token[0]) === 'CALL_START') {
            parens.push(0);
          } else if (_a === 'INDEX_START') {
            brackets.push(0);
          } else if (_a === '(') {
            parens[parens.length - 1] += 1;
          } else if (_a === '[') {
            brackets[brackets.length - 1] += 1;
          } else if (_a === ')') {
            if (parens[parens.length - 1] === 0) {
              parens.pop();
              token[0] = 'CALL_END';
            } else {
              parens[parens.length - 1] -= 1;
            }
          } else if (_a === ']') {
            if (brackets[brackets.length - 1] === 0) {
              brackets.pop();
              token[0] = 'INDEX_END';
            } else {
              brackets[brackets.length - 1] -= 1;
            }
          }
          return 1;
        }, this));
    };
    // Methods may be optionally called without parentheses, for simple cases.
    // Insert the implicit parentheses here, so that the parser doesn't have to
    // deal with them.
    Rewriter.prototype.add_implicit_parentheses = function add_implicit_parentheses() {
      var calls, parens, stack;
      stack = [0];
      calls = 0;
      parens = 0;
      return this.scan_tokens(__bind(function(prev, token, post, i) {
          var _a, _b, _c, idx, last, open, size, stack_pointer, tag, tmp;
          tag = token[0];
          if (tag === 'CALL_START') {
            calls += 1;
          } else if (tag === 'CALL_END') {
            calls -= 1;
          } else if (tag === '(') {
            parens += 1;
          } else if (tag === ')') {
            parens -= 1;
          } else if (tag === 'INDENT') {
            stack.push(0);
          } else if (tag === 'OUTDENT') {
            last = stack.pop();
            stack[stack.length - 1] += last;
          }
          open = stack[stack.length - 1] > 0;
          if (!(typeof post !== "undefined" && post !== null) || (parens === 0 && include(IMPLICIT_END, tag))) {
            if (tag === 'INDENT' && prev && include(IMPLICIT_BLOCK, prev[0])) {
              return 1;
            }
            if (tag === 'OUTDENT' && token.generated) {
              return 1;
            }
            if (open || tag === 'INDENT') {
              idx = tag === 'OUTDENT' ? i + 1 : i;
              stack_pointer = tag === 'INDENT' ? 2 : 1;
              _b = 0; _c = stack[stack.length - stack_pointer];
              for (_a = 0, tmp = _b; (_b <= _c ? tmp < _c : tmp > _c); (_b <= _c ? tmp += 1 : tmp -= 1), _a++) {
                this.tokens.splice(idx, 0, ['CALL_END', ')', token[2]]);
              }
              size = stack[stack.length - stack_pointer] + 1;
              stack[stack.length - stack_pointer] = 0;
              return size;
            }
          }
          if (!(prev && include(IMPLICIT_FUNC, prev[0]) && include(IMPLICIT_CALL, tag))) {
            return 1;
          }
          calls = 0;
          this.tokens.splice(i, 0, ['CALL_START', '(', token[2]]);
          stack[stack.length - 1] += 1;
          return 2;
        }, this));
    };
    // Because our grammar is LALR(1), it can't handle some single-line
    // expressions that lack ending delimiters. The **Rewriter** adds the implicit
    // blocks, so it doesn't need to. ')' can close a single-line block,
    // but we need to make sure it's balanced.
    Rewriter.prototype.add_implicit_indentation = function add_implicit_indentation() {
      return this.scan_tokens(__bind(function(prev, token, post, i) {
          var idx, insertion, outdent, parens, pre, starter, tok;
          if (!(include(SINGLE_LINERS, token[0]) && post[0] !== 'INDENT' && !(token[0] === 'ELSE' && post[0] === 'IF'))) {
            return 1;
          }
          starter = token[0];
          this.tokens.splice(i + 1, 0, ['INDENT', 2, token[2]]);
          idx = i + 1;
          parens = 0;
          while (true) {
            idx += 1;
            tok = this.tokens[idx];
            pre = this.tokens[idx - 1];
            if ((!tok || (include(SINGLE_CLOSERS, tok[0]) && tok[1] !== ';') || (tok[0] === ')' && parens === 0)) && !(starter === 'ELSE' && tok[0] === 'ELSE')) {
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
        }, this));
    };
    // Ensure that all listed pairs of tokens are correctly balanced throughout
    // the course of the token stream.
    Rewriter.prototype.ensure_balance = function ensure_balance(pairs) {
      var _a, _b, key, levels, line, open, open_line, unclosed, value;
      levels = {};
      open_line = {};
      this.scan_tokens(__bind(function(prev, token, post, i) {
          var _a, _b, _c, _d, close, open, pair;
          _b = pairs;
          for (_a = 0, _c = _b.length; _a < _c; _a++) {
            pair = _b[_a];
            _d = pair;
            open = _d[0];
            close = _d[1];
            levels[open] = levels[open] || 0;
            if (token[0] === open) {
              if (levels[open] === 0) {
                open_line[open] = token[2];
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
        }, this));
      unclosed = (function() {
        _a = []; _b = levels;
        for (key in _b) { if (__hasProp.call(_b, key)) {
          value = _b[key];
          value > 0 ? _a.push(key) : null;
        }}
        return _a;
      }).call(this);
      if (unclosed.length) {
        open = unclosed[0];
        line = open_line[open] + 1;
        throw new Error("unclosed " + open + " on line " + line);
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
    Rewriter.prototype.rewrite_closing_parens = function rewrite_closing_parens() {
      var _a, debt, key, stack, val;
      stack = [];
      debt = {};
      _a = INVERSES;
      for (key in _a) { if (__hasProp.call(_a, key)) {
        val = _a[key];
        (debt[key] = 0);
      }}
      return this.scan_tokens(__bind(function(prev, token, post, i) {
          var inv, match, mtag, tag;
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
              if (tag === INVERSES[mtag]) {
                return 1;
              }
              debt[mtag] += 1;
              val = mtag === 'INDENT' ? match[1] : INVERSES[mtag];
              this.tokens.splice(i, 0, [INVERSES[mtag], val]);
              return 1;
            }
          } else {
            return 1;
          }
        }, this));
    };
    return Rewriter;
  }).call(this);
  // Constants
  // ---------
  // List of the token pairs that must be balanced.
  BALANCED_PAIRS = [['(', ')'], ['[', ']'], ['{', '}'], ['INDENT', 'OUTDENT'], ['PARAM_START', 'PARAM_END'], ['CALL_START', 'CALL_END'], ['INDEX_START', 'INDEX_END'], ['SOAKED_INDEX_START', 'SOAKED_INDEX_END']];
  // The inverse mappings of `BALANCED_PAIRS` we're trying to fix up, so we can
  // look things up from either end.
  INVERSES = {};
  _b = BALANCED_PAIRS;
  for (_a = 0, _c = _b.length; _a < _c; _a++) {
    pair = _b[_a];
    INVERSES[pair[0]] = pair[1];
    INVERSES[pair[1]] = pair[0];
  }
  // The tokens that signal the start of a balanced pair.
  EXPRESSION_START = (function() {
    _d = []; _f = BALANCED_PAIRS;
    for (_e = 0, _g = _f.length; _e < _g; _e++) {
      pair = _f[_e];
      _d.push(pair[0]);
    }
    return _d;
  }).call(this);
  // The tokens that signal the end of a balanced pair.
  EXPRESSION_END = (function() {
    _h = []; _j = BALANCED_PAIRS;
    for (_i = 0, _k = _j.length; _i < _k; _i++) {
      pair = _j[_i];
      _h.push(pair[1]);
    }
    return _h;
  }).call(this);
  // Tokens that indicate the close of a clause of an expression.
  EXPRESSION_CLOSE = ['CATCH', 'WHEN', 'ELSE', 'FINALLY'].concat(EXPRESSION_END);
  // Tokens that, if followed by an `IMPLICIT_CALL`, indicate a function invocation.
  IMPLICIT_FUNC = ['IDENTIFIER', 'SUPER', ')', 'CALL_END', ']', 'INDEX_END', '<-'];
  // If preceded by an `IMPLICIT_FUNC`, indicates a function invocation.
  IMPLICIT_CALL = ['IDENTIFIER', 'NUMBER', 'STRING', 'JS', 'REGEX', 'NEW', 'PARAM_START', 'TRY', 'DELETE', 'TYPEOF', 'SWITCH', 'EXTENSION', 'TRUE', 'FALSE', 'YES', 'NO', 'ON', 'OFF', '!', '!!', 'NOT', 'THIS', 'NULL', '@', '->', '=>', '[', '(', '{'];
  // Tokens indicating that the implicit call must enclose a block of expressions.
  IMPLICIT_BLOCK = ['->', '=>', '{', '[', ','];
  // Tokens that always mark the end of an implicit call for single-liners.
  IMPLICIT_END = ['IF', 'UNLESS', 'FOR', 'WHILE', 'TERMINATOR', 'INDENT', 'OUTDENT'];
  // Single-line flavors of block expressions that have unclosed endings.
  // The grammar can't disambiguate them, so we insert the implicit indentation.
  SINGLE_LINERS = ['ELSE', "->", "=>", 'TRY', 'FINALLY', 'THEN'];
  SINGLE_CLOSERS = ['TERMINATOR', 'CATCH', 'FINALLY', 'ELSE', 'OUTDENT', 'LEADING_WHEN'];
})();
