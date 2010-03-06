(function(){
  var ACCESSORS, ASSIGNMENT, BEFORE_WHEN, CALLABLE, CODE, COFFEE_KEYWORDS, COMMENT, COMMENT_CLEANER, HEREDOC, HEREDOC_INDENT, IDENTIFIER, INTERPOLATED_EXPRESSION, INTERPOLATED_IDENTIFIER, JS, JS_CLEANER, JS_FORBIDDEN, JS_KEYWORDS, KEYWORDS, LAST_DENT, LAST_DENTS, Lexer, MULTILINER, MULTI_DENT, NOT_REGEX, NO_NEWLINE, NUMBER, OPERATOR, REGEX, RESERVED, Rewriter, STRING, STRING_NEWLINES, WHITESPACE, compact, count, include;
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
  IDENTIFIER = /^([a-zA-Z$_](\w|\$)*)/;
  NUMBER = /^(\b((0(x|X)[0-9a-fA-F]+)|([0-9]+(\.[0-9]+)?(e[+\-]?[0-9]+)?)))\b/i;
  STRING = /^(""|''|"([\s\S]*?)([^\\]|\\\\)"|'([\s\S]*?)([^\\]|\\\\)')/;
  HEREDOC = /^("{6}|'{6}|"{3}\n?([\s\S]*?)\n?([ \t]*)"{3}|'{3}\n?([\s\S]*?)\n?([ \t]*)'{3})/;
  JS = /^(``|`([\s\S]*?)([^\\]|\\\\)`)/;
  OPERATOR = /^([+\*&|\/\-%=<>:!?]+)/;
  WHITESPACE = /^([ \t]+)/;
  COMMENT = /^(((\n?[ \t]*)?#[^\n]*)+)/;
  CODE = /^((-|=)>)/;
  REGEX = /^(\/(\S.*?)?([^\\]|\\\\)\/[imgy]{0,4})/;
  MULTI_DENT = /^((\n([ \t]*))+)(\.)?/;
  LAST_DENTS = /\n([ \t]*)/g;
  LAST_DENT = /\n([ \t]*)/;
  ASSIGNMENT = /^(:|=)$/;
  // Interpolation matching regexes.
  INTERPOLATED_EXPRESSION = /(^|[\s\S]*?(?:[\\]|\\\\)?)(\${[\s\S]*?(?:[^\\]|\\\\)})/;
  INTERPOLATED_IDENTIFIER = /(^|[\s\S]*?(?:[\\]|\\\\)?)(\$([a-zA-Z_@]\w*))/;
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
  // The Lexer Class
  // ---------------
  // The Lexer class reads a stream of CoffeeScript and divvys it up into tagged
  // tokens. A minor bit of the ambiguity in the grammar has been avoided by
  // pushing some extra smarts into the Lexer.
  exports.Lexer = (function() {
    Lexer = function Lexer() {    };
    // Scan by attempting to match tokens one at a time. Slow and steady.
    Lexer.prototype.tokenize = function tokenize(code, options) {
      options = options || {};
      this.code = code;
      // The remainder of the source code.
      this.i = 0;
      // Current character position we're parsing.
      this.line = 0;
      // The current line.
      this.indent = 0;
      // The current indent level.
      this.indents = [];
      // The stack of all indent levels we are currently within.
      this.tokens = [];
      // Collection of all parsed tokens in the form ['TOKEN_TYPE', value, line]
      while (this.i < this.code.length) {
        this.chunk = this.code.slice(this.i);
        this.extract_next_token();
      }
      this.close_indentation();
      if (options.rewrite === false) {
        return this.tokens;
      }
      return (new Rewriter()).rewrite(this.tokens);
    };
    // At every position, run through this list of attempted matches,
    // short-circuiting if any of them succeed.
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
      if (this.string_token()) {
        return null;
      }
      if (this.js_token()) {
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
      return this.literal_token();
    };
    // Tokenizers
    // ----------
    // Matches identifying literals: variables, keywords, method names, etc.
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
    // Matches strings, including multi-line strings.
    Lexer.prototype.string_token = function string_token() {
      var string;
      if (!((string = this.match(STRING, 1)))) {
        return false;
      }
      this.interpolate_string(string.replace(STRING_NEWLINES, " \\\n"));
      this.line += count(string, "\n");
      this.i += string.length;
      return true;
    };
    // Matches heredocs, adjusting indentation to the correct level.
    Lexer.prototype.heredoc_token = function heredoc_token() {
      var doc, match;
      if (!((match = this.chunk.match(HEREDOC)))) {
        return false;
      }
      doc = this.sanitize_heredoc(match[2] || match[4]);
      this.token('STRING', '"' + doc + '"');
      this.line += count(match[1], "\n");
      this.i += match[1].length;
      return true;
    };
    // Matches interpolated JavaScript.
    Lexer.prototype.js_token = function js_token() {
      var script;
      if (!((script = this.match(JS, 1)))) {
        return false;
      }
      this.token('JS', script.replace(JS_CLEANER, ''));
      this.i += script.length;
      return true;
    };
    // Matches regular expression literals.
    Lexer.prototype.regex_token = function regex_token() {
      var regex;
      if (!((regex = this.match(REGEX, 1)))) {
        return false;
      }
      if (include(NOT_REGEX, this.tag())) {
        return false;
      }
      this.token('REGEX', regex);
      this.i += regex.length;
      return true;
    };
    // Matches and conumes comments.
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
          return this.suppress_newlines(indent);
        }
        return this.newline_token(indent);
      } else if (size > this.indent) {
        if (no_newlines) {
          return this.suppress_newlines(indent);
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
    // Record an outdent token or tokens, if we happen to be moving back inwards
    // past multiple recorded indents.
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
    // Generate a newline token. Multiple newlines get merged together.
    Lexer.prototype.newline_token = function newline_token(newlines) {
      if (!(this.tag() === 'TERMINATOR')) {
        this.token('TERMINATOR', "\n");
      }
      return true;
    };
    // Use a `\` at a line-ending to suppress the newline.
    // The slash is removed here once its job is done.
    Lexer.prototype.suppress_newlines = function suppress_newlines(newlines) {
      if (this.value() === "\\") {
        this.tokens.pop();
      }
      return true;
    };
    // We treat all other single characters as a token. Eg.: `( ) , . !`
    // Multi-character operators are also literal tokens, so that Jison can assign
    // the proper order of operations.
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
    // Sanitize a heredoc by escaping double quotes and erasing all external
    // indentation on the left-hand side.
    Lexer.prototype.sanitize_heredoc = function sanitize_heredoc(doc) {
      var indent;
      indent = (doc.match(HEREDOC_INDENT) || ['']).sort()[0];
      return doc.replace(new RegExp("^" + indent, 'gm'), '').replace(MULTILINER, "\\n").replace(/"/g, '\\"');
    };
    // A source of ambiguity in our grammar was parameter lists in function
    // definitions (as opposed to argument lists in function calls). Tag
    // parameter identifiers in order to avoid this. Also, parameter lists can
    // make use of splats.
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
    // Error for when you try to use a forbidden word in JavaScript as
    // an identifier.
    Lexer.prototype.identifier_error = function identifier_error(word) {
      throw new Error('SyntaxError: Reserved word "' + word + '" on line ' + this.line);
    };
    // Error for when you try to assign to a reserved word in JavaScript,
    // like "function" or "default".
    Lexer.prototype.assignment_error = function assignment_error() {
      throw new Error('SyntaxError: Reserved word "' + this.value() + '" on line ' + this.line + ' can\'t be assigned');
    };
    // Expand variables and expressions inside double-quoted strings using
    // [ECMA Harmony's interpolation syntax](http://wiki.ecmascript.org/doku.php?id=strawman:string_interpolation).
    //     "Hello $name."
    //     "Hello ${name.capitalize()}."
    Lexer.prototype.interpolate_string = function interpolate_string(str) {
      var _a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, before, contents, each, expression, expression_match, group, i, id, identifier, identifier_match, lexer, nested, prev, quote, tok, tokens;
      if (str.length < 3 || str.substring(0, 1) !== '"') {
        return this.token('STRING', str);
      } else {
        lexer = new Lexer();
        tokens = [];
        quote = str.substring(0, 1);
        str = str.substring(1, str.length - 1);
        while (str.length) {
          expression_match = str.match(INTERPOLATED_EXPRESSION);
          if (expression_match) {
            _a = expression_match;
            group = _a[0];
            before = _a[1];
            expression = _a[2];
            if (before.substring(before.length - 1) === '\\') {
              if (before.length) {
                tokens.push(['STRING', quote + before.substring(0, before.length - 1) + expression + quote]);
              }
            } else {
              if (before.length) {
                tokens.push(['STRING', quote + before + quote]);
              }
              nested = lexer.tokenize(expression.substring(2, expression.length - 1), {
                rewrite: false
              });
              nested.pop();
              tokens.push(['TOKENS', nested]);
            }
            str = str.substring(group.length);
          } else {
            identifier_match = str.match(INTERPOLATED_IDENTIFIER);
            if (identifier_match) {
              _b = identifier_match;
              group = _b[0];
              before = _b[1];
              identifier = _b[2];
              if (before.substring(before.length - 1) === '\\') {
                if (before.length) {
                  tokens.push(['STRING', quote + before.substring(0, before.length - 1) + identifier + quote]);
                }
              } else {
                if (before.length) {
                  tokens.push(['STRING', quote + before + quote]);
                }
                id = identifier.substring(1);
                if (id.substring(0, 1) === '@') {
                  id = 'this.' + id.substring(1);
                }
                tokens.push(['IDENTIFIER', id]);
              }
              str = str.substring(group.length);
            } else {
              tokens.push(['STRING', quote + str + quote]);
              str = '';
            }
          }
        }
        if (tokens.length > 1) {
          _e = tokens.length - 1; _f = 1;
          for (_d = 0, i = _e; (_e <= _f ? i <= _f : i >= _f); (_e <= _f ? i += 1 : i -= 1), _d++) {
            _g = [tokens[i - 1], tokens[i]];
            prev = _g[0];
            tok = _g[1];
            if (tok[0] === 'STRING' && prev[0] === 'STRING') {
              contents = quote + prev[1].substring(1, prev[1].length - 1) + tok[1].substring(1, tok[1].length - 1) + quote;
              tokens.splice(i - 1, 2, ['STRING', contents]);
            }
          }
        }
        _h = []; _i = tokens;
        for (i = 0, _j = _i.length; i < _j; i++) {
          each = _i[i];
          _h.push((function() {
            if (each[0] === 'TOKENS') {
              _k = each[1];
              for (_l = 0, _m = _k.length; _l < _m; _l++) {
                nested = _k[_l];
                this.token(nested[0], nested[1]);
              }
            } else {
              this.token(each[0], each[1]);
            }
            if (i < tokens.length - 1) {
              return this.token('+', '+');
            }
          }).call(this));
        }
        return _h;
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
  // Utility Functions
  // -----------------
  // Does a list include a value?
  include = function include(list, value) {
    return list.indexOf(value) >= 0;
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
