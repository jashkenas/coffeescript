(function(){
  var ACCESSORS, ASSIGNMENT, BEFORE_WHEN, CALLABLE, CODE, COFFEE_KEYWORDS, COMMENT, COMMENT_CLEANER, HEREDOC, HEREDOC_INDENT, IDENTIFIER, INTERPOLATION, JS_CLEANER, JS_FORBIDDEN, JS_KEYWORDS, KEYWORDS, LAST_DENT, LAST_DENTS, Lexer, MULTILINER, MULTI_DENT, NOT_REGEX, NO_NEWLINE, NUMBER, OPERATOR, REGEX_ESCAPE, REGEX_FLAGS, REGEX_INTERPOLATION, REGEX_START, RESERVED, Rewriter, STRING_NEWLINES, WHITESPACE, compact, count, include, starts;
  // The CoffeeScript Lexer. Uses a series of token-matching regexes to attempt
  // matches against the beginning of the source code. When a match is found,
  // a token is produced, we consume the match, and start again. Tokens are in the
  // form:
  //     [tag, value, line_number]
  // Which is a format that can be fed directly into [Jison](http://github.com/zaach/jison).
  // Set up the Lexer for both Node.js and the browser, depending on where we are.
  if ((typeof process !== "undefined" && process !== null)) {
    Rewriter = require('./rewriter').Rewriter;
  } else {
    this.exports = this;
    Rewriter = this.Rewriter;
  }
  // The Lexer Class
  // ---------------
  // The Lexer class reads a stream of CoffeeScript and divvys it up into tagged
  // tokens. Some potential ambiguity in the grammar has been avoided by
  // pushing some extra smarts into the Lexer.
  exports.Lexer = (function() {
    Lexer = function Lexer() {    };
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
    Lexer.prototype.tokenize = function tokenize(code, options) {
      var o;
      o = options || {};
      this.code = code || '';
      // The remainder of the source code.
      this.i = 0;
      // Current character position we're parsing.
      this.line = o.line || 0;
      // The current line.
      this.indent = 0;
      // The current indentation level.
      this.indents = [];
      // The stack of all current indentation levels.
      this.tokens = [];
      // Stream of parsed tokens in the form ['TYPE', value, line]
      while (this.i < this.code.length) {
        this.chunk = this.code.slice(this.i);
        this.extract_next_token();
      }
      this.close_indentation();
      if (o.rewrite === false) {
        return this.tokens;
      }
      return (new Rewriter()).rewrite(this.tokens);
    };
    // At every position, run through this list of attempted matches,
    // short-circuiting if any of them succeed. Their order determines precedence:
    // `@literal_token` is the fallback catch-all.
    Lexer.prototype.extract_next_token = function extract_next_token() {
      if (this.identifier_token()) {
        return null;
      }
      if (this.number_token()) {
        return null;
      }
      if (this.heredoc_token()) {
        return null;
      }
      if (this.regex_token()) {
        return null;
      }
      if (this.comment_token()) {
        return null;
      }
      if (this.line_token()) {
        return null;
      }
      if (this.whitespace_token()) {
        return null;
      }
      if (this.js_token()) {
        return null;
      }
      if (this.string_token()) {
        return null;
      }
      return this.literal_token();
    };
    // Tokenizers
    // ----------
    // Matches identifying literals: variables, keywords, method names, etc.
    // Check to ensure that JavaScript reserved words aren't being used as
    // identifiers. Because CoffeeScript reserves a handful of keywords that are
    // allowed in JavaScript, we're careful not to tag them as keywords when
    // referenced as property names here, so you can still do `jQuery.is()` even
    // though `is` means `===` otherwise.
    Lexer.prototype.identifier_token = function identifier_token() {
      var id, tag;
      if (!((id = this.match(IDENTIFIER, 1)))) {
        return false;
      }
      this.name_access_type();
      tag = 'IDENTIFIER';
      if (include(KEYWORDS, id) && !(include(ACCESSORS, this.tag(0)) && !this.prev().spaced)) {
        tag = id.toUpperCase();
      }
      if (include(RESERVED, id)) {
        this.identifier_error(id);
      }
      if (tag === 'WHEN' && include(BEFORE_WHEN, this.tag())) {
        tag = 'LEADING_WHEN';
      }
      this.token(tag, id);
      this.i += id.length;
      return true;
    };
    // Matches numbers, including decimals, hex, and exponential notation.
    Lexer.prototype.number_token = function number_token() {
      var number;
      if (!((number = this.match(NUMBER, 1)))) {
        return false;
      }
      this.token('NUMBER', number);
      this.i += number.length;
      return true;
    };
    // Matches strings, including multi-line strings. Ensures that quotation marks
    // are balanced within the string's contents, and within nested interpolations.
    Lexer.prototype.string_token = function string_token() {
      var merge, string;
      if (!(starts(this.chunk, '"') || starts(this.chunk, "'"))) {
        return false;
      }
      if (!((string = this.balanced_token(['"', '"'], ['${', '}']) || this.balanced_token(["'", "'"])))) {
        return false;
      }
      this.interpolate_string(string.replace(STRING_NEWLINES, " \\\n"), (merge = true));
      this.line += count(string, "\n");
      this.i += string.length;
      return true;
    };
    // Matches heredocs, adjusting indentation to the correct level, as heredocs
    // preserve whitespace, but ignore indentation to the left.
    Lexer.prototype.heredoc_token = function heredoc_token() {
      var doc, match;
      if (!((match = this.chunk.match(HEREDOC)))) {
        return false;
      }
      doc = this.sanitize_heredoc(match[2] || match[4]);
      this.token('STRING', "\"" + doc + "\"");
      this.line += count(match[1], "\n");
      this.i += match[1].length;
      return true;
    };
    // Matches JavaScript interpolated directly into the source via backticks.
    Lexer.prototype.js_token = function js_token() {
      var script;
      if (!(starts(this.chunk, '`'))) {
        return false;
      }
      if (!((script = this.balanced_token(['`', '`'])))) {
        return false;
      }
      this.token('JS', script.replace(JS_CLEANER, ''));
      this.i += script.length;
      return true;
    };
    // Matches regular expression literals. Lexing regular expressions is difficult
    // to distinguish from division, so we borrow some basic heuristics from
    // JavaScript and Ruby.
    Lexer.prototype.regex_token = function regex_token() {
      var _a, _b, _c, _d, each, flags, i, interp_tokens, merge, regex, str;
      if (!(this.chunk.match(REGEX_START))) {
        return false;
      }
      if (include(NOT_REGEX, this.tag())) {
        return false;
      }
      if (!((regex = this.balanced_token(['/', '/'])))) {
        return false;
      }
      regex += ((flags = this.chunk.substr(regex.length).match(REGEX_FLAGS)));
      if (((0 < (_d = regex.indexOf('${'))) && (_d < regex.indexOf('}'))) || regex.match(REGEX_INTERPOLATION)) {
        str = regex.substring(1).split('/')[0];
        str = str.replace(REGEX_ESCAPE, function(escaped) {
          return '\\' + escaped;
        });
        this.tokens = this.tokens.concat([['(', '('], ['NEW', 'new'], ['IDENTIFIER', 'RegExp'], ['CALL_START', '(']]);
        interp_tokens = this.interpolate_string("\"" + str + "\"", (merge = false));
        _a = interp_tokens;
        for (i = 0, _b = _a.length; i < _b; i++) {
          each = _a[i];
          if ((_c = each[0]) === 'TOKENS') {
            this.tokens = this.tokens.concat(each[1]);
          } else if (_c === 'STRING') {
            this.token(each[0], each[1].substring(0, 1) + each[1].substring(1, each[1].length - 1).replace(/"/g, '\\"') + each[1].substring(0, 1));
          } else {
            this.token(each[0], each[1]);
          }
          if (i < interp_tokens.length - 1) {
            this.token('+', '+');
          }
        }
        this.tokens = this.tokens.concat([[',', ','], ['STRING', "'" + flags + "'"], [')', ')'], [')', ')']]);
      } else {
        this.token('REGEX', regex);
      }
      this.i += regex.length;
      return true;
    };
    // Matches a token in which which the passed delimiter pairs must be correctly
    // balanced (ie. strings, JS literals).
    Lexer.prototype.balanced_token = function balanced_token() {
      var delimited;
      delimited = Array.prototype.slice.call(arguments, 0);
      return this.balanced_string.apply(this, [this.chunk].concat(delimited));
    };
    // Matches and conumes comments. We pass through comments into JavaScript,
    // so they're treated as real tokens, like any other part of the language.
    Lexer.prototype.comment_token = function comment_token() {
      var comment, lines;
      if (!((comment = this.match(COMMENT, 1)))) {
        return false;
      }
      this.line += (comment.match(MULTILINER) || []).length;
      lines = comment.replace(COMMENT_CLEANER, '').split(MULTILINER);
      this.token('COMMENT', compact(lines));
      this.token('TERMINATOR', "\n");
      this.i += comment.length;
      return true;
    };
    // Matches newlines, indents, and outdents, and determines which is which.
    // If we can detect that the current line is continued onto the the next line,
    // then the newline is suppressed:
    //     elements
    //       .each( ... )
    //       .map( ... )
    // Keeps track of the level of indentation, because a single outdent token
    // can close multiple indents, so we need to know how far in we happen to be.
    Lexer.prototype.line_token = function line_token() {
      var diff, indent, next_character, no_newlines, prev, size;
      if (!((indent = this.match(MULTI_DENT, 1)))) {
        return false;
      }
      this.line += indent.match(MULTILINER).length;
      this.i += indent.length;
      prev = this.prev(2);
      size = indent.match(LAST_DENTS).reverse()[0].match(LAST_DENT)[1].length;
      next_character = this.chunk.match(MULTI_DENT)[4];
      no_newlines = next_character === '.' || (this.value() && this.value().match(NO_NEWLINE) && prev && (prev[0] !== '.') && !this.value().match(CODE));
      if (size === this.indent) {
        if (no_newlines) {
          return this.suppress_newlines();
        }
        return this.newline_token(indent);
      } else if (size > this.indent) {
        if (no_newlines) {
          return this.suppress_newlines();
        }
        diff = size - this.indent;
        this.token('INDENT', diff);
        this.indents.push(diff);
      } else {
        this.outdent_token(this.indent - size, no_newlines);
      }
      this.indent = size;
      return true;
    };
    // Record an outdent token or multiple tokens, if we happen to be moving back
    // inwards past several recorded indents.
    Lexer.prototype.outdent_token = function outdent_token(move_out, no_newlines) {
      var last_indent;
      while (move_out > 0 && this.indents.length) {
        last_indent = this.indents.pop();
        this.token('OUTDENT', last_indent);
        move_out -= last_indent;
      }
      if (!(this.tag() === 'TERMINATOR' || no_newlines)) {
        this.token('TERMINATOR', "\n");
      }
      return true;
    };
    // Matches and consumes non-meaningful whitespace. Tag the previous token
    // as being "spaced", because there are some cases where it makes a difference.
    Lexer.prototype.whitespace_token = function whitespace_token() {
      var prev, space;
      if (!((space = this.match(WHITESPACE, 1)))) {
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
    Lexer.prototype.newline_token = function newline_token(newlines) {
      if (!(this.tag() === 'TERMINATOR')) {
        this.token('TERMINATOR', "\n");
      }
      return true;
    };
    // Use a `\` at a line-ending to suppress the newline.
    // The slash is removed here once its job is done.
    Lexer.prototype.suppress_newlines = function suppress_newlines() {
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
    Lexer.prototype.literal_token = function literal_token() {
      var match, not_spaced, tag, value;
      match = this.chunk.match(OPERATOR);
      value = match && match[1];
      if (value && value.match(CODE)) {
        this.tag_parameters();
      }
      value = value || this.chunk.substr(0, 1);
      not_spaced = !this.prev() || !this.prev().spaced;
      tag = value;
      if (value.match(ASSIGNMENT)) {
        tag = 'ASSIGN';
        if (include(JS_FORBIDDEN, this.value)) {
          this.assignment_error();
        }
      } else if (value === ';') {
        tag = 'TERMINATOR';
      } else if (value === '[' && this.tag() === '?' && not_spaced) {
        tag = 'SOAKED_INDEX_START';
        this.soaked_index = true;
        this.tokens.pop();
      } else if (value === ']' && this.soaked_index) {
        tag = 'SOAKED_INDEX_END';
        this.soaked_index = false;
      } else if (include(CALLABLE, this.tag()) && not_spaced) {
        if (value === '(') {
          tag = 'CALL_START';
        }
        if (value === '[') {
          tag = 'INDEX_START';
        }
      }
      this.token(tag, value);
      this.i += value.length;
      return true;
    };
    // Token Manipulators
    // ------------------
    // As we consume a new `IDENTIFIER`, look at the previous token to determine
    // if it's a special kind of accessor.
    Lexer.prototype.name_access_type = function name_access_type() {
      if (this.value() === '::') {
        this.tag(1, 'PROTOTYPE_ACCESS');
      }
      if (this.value() === '.' && !(this.value(2) === '.')) {
        if (this.tag(2) === '?') {
          this.tag(1, 'SOAK_ACCESS');
          return this.tokens.splice(-2, 1);
        } else {
          return this.tag(1, 'PROPERTY_ACCESS');
        }
      }
    };
    // Sanitize a heredoc by escaping internal double quotes and erasing all
    // external indentation on the left-hand side.
    Lexer.prototype.sanitize_heredoc = function sanitize_heredoc(doc) {
      var indent;
      indent = (doc.match(HEREDOC_INDENT) || ['']).sort()[0];
      return doc.replace(new RegExp("^" + indent, 'gm'), '').replace(MULTILINER, "\\n").replace(/"/g, '\\"');
    };
    // A source of ambiguity in our grammar used to be parameter lists in function
    // definitions versus argument lists in function calls. Walk backwards, tagging
    // parameters specially in order to make things easier for the parser.
    Lexer.prototype.tag_parameters = function tag_parameters() {
      var _a, i, tok;
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
        if ((_a = tok[0]) === 'IDENTIFIER') {
          tok[0] = 'PARAM';
        } else if (_a === ')') {
          tok[0] = 'PARAM_END';
        } else if (_a === '(') {
          return (tok[0] = 'PARAM_START');
        }
      }
      return true;
    };
    // Close up all remaining open blocks at the end of the file.
    Lexer.prototype.close_indentation = function close_indentation() {
      return this.outdent_token(this.indent);
    };
    // The error for when you try to use a forbidden word in JavaScript as
    // an identifier.
    Lexer.prototype.identifier_error = function identifier_error(word) {
      throw new Error("SyntaxError: Reserved word \"" + word + "\" on line " + (this.line + 1));
    };
    // The error for when you try to assign to a reserved word in JavaScript,
    // like "function" or "default".
    Lexer.prototype.assignment_error = function assignment_error() {
      throw new Error("SyntaxError: Reserved word \"" + (this.value()) + "\" on line " + (this.line + 1) + " can't be assigned");
    };
    // Matches a balanced group such as a single or double-quoted string. Pass in
    // a series of delimiters, all of which must be nested correctly within the
    // contents of the string. This method allows us to have strings within
    // interpolations within strings etc...
    Lexer.prototype.balanced_string = function balanced_string(str) {
      var _a, _b, _c, _d, close, delimited, i, levels, open, pair;
      delimited = Array.prototype.slice.call(arguments, 1);
      levels = [];
      i = 0;
      while (i < str.length) {
        _a = delimited;
        for (_b = 0, _c = _a.length; _b < _c; _b++) {
          pair = _a[_b];
          _d = pair;
          open = _d[0];
          close = _d[1];
          if (levels.length && starts(str, '\\', i)) {
            i += 1;
            break;
          } else if (levels.length && starts(str, close, i) && levels[levels.length - 1] === pair) {
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
        if (!(levels.length)) {
          break;
        }
        i += 1;
      }
      if (levels.length) {
        if (delimited[0][0] === '/') {
          return false;
        }
        throw new Error("SyntaxError: Unterminated " + (levels.pop()[0]) + " starting on line " + (this.line + 1));
      }
      if (i === 0) {
        return false;
      }
      return str.substring(0, i);
    };
    // Expand variables and expressions inside double-quoted strings using
    // [ECMA Harmony's interpolation syntax](http://wiki.ecmascript.org/doku.php?id=strawman:string_interpolation)
    // for substitution of bare variables as well as arbitrary expressions.
    //     "Hello $name."
    //     "Hello ${name.capitalize()}."
    // If it encounters an interpolation, this method will recursively create a
    // new Lexer, tokenize the interpolated contents, and merge them into the
    // token stream.
    Lexer.prototype.interpolate_string = function interpolate_string(str, merge) {
      var _a, _b, _c, _d, each, expr, group, i, inner, interp, lexer, match, nested, pi, quote, tokens;
      if (str.length < 3 || !starts(str, '"')) {
        return this.token('STRING', str);
      } else {
        lexer = new Lexer();
        tokens = [];
        quote = str.substring(0, 1);
        _a = [1, 1];
        i = _a[0];
        pi = _a[1];
        while (i < str.length - 1) {
          if (starts(str, '\\', i)) {
            i += 1;
          } else if ((match = str.substring(i).match(INTERPOLATION))) {
            _b = match;
            group = _b[0];
            interp = _b[1];
            if (starts(interp, '@')) {
              interp = "this." + (interp.substring(1));
            }
            if (pi < i) {
              tokens.push(['STRING', '' + quote + (str.substring(pi, i)) + quote]);
            }
            tokens.push(['IDENTIFIER', interp]);
            i += group.length - 1;
            pi = i + 1;
          } else if (((expr = this.balanced_string(str.substring(i), ['${', '}'])))) {
            if (pi < i) {
              tokens.push(['STRING', '' + quote + (str.substring(pi, i)) + quote]);
            }
            inner = expr.substring(2, expr.length - 1);
            if (inner.length) {
              nested = lexer.tokenize("(" + inner + ")", {
                rewrite: false,
                line: this.line
              });
              nested.pop();
              tokens.push(['TOKENS', nested]);
            } else {
              tokens.push(['STRING', '' + quote + quote]);
            }
            i += expr.length - 1;
            pi = i + 1;
          }
          i += 1;
        }
        if (pi < i && pi < str.length - 1) {
          tokens.push(['STRING', '' + quote + (str.substring(pi, i)) + quote]);
        }
        if (!(tokens[0][0] === 'STRING')) {
          tokens.unshift(['STRING', "''"]);
        }
        if (((typeof merge !== "undefined" && merge !== null) ? merge : true)) {
          _c = tokens;
          for (i = 0, _d = _c.length; i < _d; i++) {
            each = _c[i];
            each[0] === 'TOKENS' ? (this.tokens = this.tokens.concat(each[1])) : this.token(each[0], each[1]);
            if (i < tokens.length - 1) {
              this.token('+', '+');
            }
          }
        }
        return tokens;
      }
    };
    // Helpers
    // -------
    // Add a token to the results, taking note of the line number.
    Lexer.prototype.token = function token(tag, value) {
      return this.tokens.push([tag, value, this.line]);
    };
    // Peek at a tag in the current token stream.
    Lexer.prototype.tag = function tag(index, tag) {
      var tok;
      if (!((tok = this.prev(index)))) {
        return null;
      }
      if ((typeof tag !== "undefined" && tag !== null)) {
        return (tok[0] = tag);
      }
      return tok[0];
    };
    // Peek at a value in the current token stream.
    Lexer.prototype.value = function value(index, val) {
      var tok;
      if (!((tok = this.prev(index)))) {
        return null;
      }
      if ((typeof val !== "undefined" && val !== null)) {
        return (tok[1] = val);
      }
      return tok[1];
    };
    // Peek at a previous token, entire.
    Lexer.prototype.prev = function prev(index) {
      return this.tokens[this.tokens.length - (index || 1)];
    };
    // Attempt to match a string against the current chunk, returning the indexed
    // match if successful, and `false` otherwise.
    Lexer.prototype.match = function match(regex, index) {
      var m;
      if (!((m = this.chunk.match(regex)))) {
        return false;
      }
      return m ? m[index] : false;
    };
    return Lexer;
  }).call(this);
  // Constants
  // ---------
  // Keywords that CoffeeScript shares in common with JavaScript.
  JS_KEYWORDS = ["if", "else", "true", "false", "new", "return", "try", "catch", "finally", "throw", "break", "continue", "for", "in", "while", "delete", "instanceof", "typeof", "switch", "super", "extends", "class"];
  // CoffeeScript-only keywords, which we're more relaxed about allowing. They can't
  // be used standalone, but you can reference them as an attached property.
  COFFEE_KEYWORDS = ["then", "unless", "yes", "no", "on", "off", "and", "or", "is", "isnt", "not", "of", "by", "where", "when"];
  // The combined list of keywords is the superset that gets passed verbatim to
  // the parser.
  KEYWORDS = JS_KEYWORDS.concat(COFFEE_KEYWORDS);
  // The list of keywords that are reserved by JavaScript, but not used, or are
  // used by CoffeeScript internally. We throw an error when these are encountered,
  // to avoid having a JavaScript error at runtime.
  RESERVED = ["case", "default", "do", "function", "var", "void", "with", "const", "let", "debugger", "enum", "export", "import", "native", "__extends", "__hasProp"];
  // The superset of both JavaScript keywords and reserved words, none of which may
  // be used as identifiers or properties.
  JS_FORBIDDEN = JS_KEYWORDS.concat(RESERVED);
  // Token matching regexes.
  IDENTIFIER = /^([a-zA-Z\$_](\w|\$)*)/;
  NUMBER = /^(\b((0(x|X)[0-9a-fA-F]+)|([0-9]+(\.[0-9]+)?(e[+\-]?[0-9]+)?)))\b/i;
  HEREDOC = /^("{6}|'{6}|"{3}\n?([\s\S]*?)\n?([ \t]*)"{3}|'{3}\n?([\s\S]*?)\n?([ \t]*)'{3})/;
  INTERPOLATION = /^\$([a-zA-Z_@]\w*(\.\w+)*)/;
  OPERATOR = /^([+\*&|\/\-%=<>:!?]+)/;
  WHITESPACE = /^([ \t]+)/;
  COMMENT = /^(((\n?[ \t]*)?#[^\n]*)+)/;
  CODE = /^((-|=)>)/;
  MULTI_DENT = /^((\n([ \t]*))+)(\.)?/;
  LAST_DENTS = /\n([ \t]*)/g;
  LAST_DENT = /\n([ \t]*)/;
  ASSIGNMENT = /^(:|=)$/;
  // Regex-matching-regexes.
  REGEX_START = /^\/[^\/ ]/;
  REGEX_INTERPOLATION = /[^\\]\$[a-zA-Z_@]/;
  REGEX_FLAGS = /^[imgy]{0,4}/;
  REGEX_ESCAPE = /\\[^\$]/g;
  // Token cleaning regexes.
  JS_CLEANER = /(^`|`$)/g;
  MULTILINER = /\n/g;
  STRING_NEWLINES = /\n[ \t]*/g;
  COMMENT_CLEANER = /(^[ \t]*#|\n[ \t]*$)/mg;
  NO_NEWLINE = /^([+\*&|\/\-%=<>:!.\\][<>=&|]*|and|or|is|isnt|not|delete|typeof|instanceof)$/;
  HEREDOC_INDENT = /^[ \t]+/mg;
  // Tokens which a regular expression will never immediately follow, but which
  // a division operator might.
  // See: http://www.mozilla.org/js/language/js20-2002-04/rationale/syntax.html#regular-expressions
  // Our list is shorter, due to sans-parentheses method calls.
  NOT_REGEX = ['NUMBER', 'REGEX', '++', '--', 'FALSE', 'NULL', 'TRUE'];
  // Tokens which could legitimately be invoked or indexed. A opening
  // parentheses or bracket following these tokens will be recorded as the start
  // of a function invocation or indexing operation.
  CALLABLE = ['IDENTIFIER', 'SUPER', ')', ']', '}', 'STRING', '@'];
  // Tokens that indicate an access -- keywords immediately following will be
  // treated as identifiers.
  ACCESSORS = ['PROPERTY_ACCESS', 'PROTOTYPE_ACCESS', 'SOAK_ACCESS', '@'];
  // Tokens that, when immediately preceding a `WHEN`, indicate that the `WHEN`
  // occurs at the start of a line. We disambiguate these from trailing whens to
  // avoid an ambiguity in the grammar.
  BEFORE_WHEN = ['INDENT', 'OUTDENT', 'TERMINATOR'];
  // Utility Functions
  // -----------------
  // Does a list include a value?
  include = function include(list, value) {
    return list.indexOf(value) >= 0;
  };
  // Peek at the beginning of a given string to see if it matches a sequence.
  starts = function starts(string, literal, start) {
    return string.substring(start, (start || 0) + literal.length) === literal;
  };
  // Trim out all falsy values from an array.
  compact = function compact(array) {
    var _a, _b, _c, _d, item;
    _a = []; _b = array;
    for (_c = 0, _d = _b.length; _c < _d; _c++) {
      item = _b[_c];
      if (item) {
        _a.push(item);
      }
    }
    return _a;
  };
  // Count the number of occurences of a character in a string.
  count = function count(string, letter) {
    var num, pos;
    num = 0;
    pos = string.indexOf(letter);
    while (pos !== -1) {
      num += 1;
      pos = string.indexOf(letter, pos + 1);
    }
    return num;
  };
})();
