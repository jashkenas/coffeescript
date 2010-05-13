(function(){
  var ACCESSORS, ASSIGNMENT, CALLABLE, CODE, COFFEE_ALIASES, COFFEE_KEYWORDS, COMMENT, COMMENT_CLEANER, CONVERSIONS, HALF_ASSIGNMENTS, HEREDOC, HEREDOC_INDENT, IDENTIFIER, INTERPOLATION, JS_CLEANER, JS_FORBIDDEN, JS_KEYWORDS, KEYWORDS, LAST_DENT, LAST_DENTS, LINE_BREAK, Lexer, MULTILINER, MULTI_DENT, NOT_REGEX, NO_NEWLINE, NUMBER, OPERATOR, REGEX_ESCAPE, REGEX_FLAGS, REGEX_INTERPOLATION, REGEX_START, RESERVED, Rewriter, STRING_NEWLINES, WHITESPACE, _a, _b, _c, balanced_string, compact, count, helpers, include, starts;
  var __slice = Array.prototype.slice;
  // The CoffeeScript Lexer. Uses a series of token-matching regexes to attempt
  // matches against the beginning of the source code. When a match is found,
  // a token is produced, we consume the match, and start again. Tokens are in the
  // form:
  //     [tag, value, line_number]
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
  balanced_string = _c.balanced_string;
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
      if (this.extension_token()) {
        return null;
      }
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
    // Language extensions get the highest priority, first chance to tag tokens
    // as something else.
    Lexer.prototype.extension_token = function extension_token() {
      var _d, _e, _f, extension;
      _e = Lexer.extensions;
      for (_d = 0, _f = _e.length; _d < _f; _d++) {
        extension = _e[_d];
        if (extension.call(this)) {
          return true;
        }
      }
      return false;
    };
    // Matches identifying literals: variables, keywords, method names, etc.
    // Check to ensure that JavaScript reserved words aren't being used as
    // identifiers. Because CoffeeScript reserves a handful of keywords that are
    // allowed in JavaScript, we're careful not to tag them as keywords when
    // referenced as property names here, so you can still do `jQuery.is()` even
    // though `is` means `===` otherwise.
    Lexer.prototype.identifier_token = function identifier_token() {
      var accessed, id, tag;
      if (!(id = this.match(IDENTIFIER, 1))) {
        return false;
      }
      this.name_access_type();
      accessed = include(ACCESSORS, this.tag(0));
      tag = 'IDENTIFIER';
      if (!accessed && include(KEYWORDS, id)) {
        tag = id.toUpperCase();
      }
      if (include(RESERVED, id)) {
        this.identifier_error(id);
      }
      if (tag === 'WHEN' && include(LINE_BREAK, this.tag())) {
        tag = 'LEADING_WHEN';
      }
      this.i += id.length;
      if (!(accessed)) {
        if (include(COFFEE_ALIASES, id)) {
          tag = (id = CONVERSIONS[id]);
        }
        if (this.prev() && this.prev()[0] === 'ASSIGN' && include(HALF_ASSIGNMENTS, tag)) {
          return this.tag_half_assignment(tag);
        }
      }
      this.token(tag, id);
      return true;
    };
    // Matches numbers, including decimals, hex, and exponential notation.
    Lexer.prototype.number_token = function number_token() {
      var number;
      if (!(number = this.match(NUMBER, 1))) {
        return false;
      }
      this.token('NUMBER', number);
      this.i += number.length;
      return true;
    };
    // Matches strings, including multi-line strings. Ensures that quotation marks
    // are balanced within the string's contents, and within nested interpolations.
    Lexer.prototype.string_token = function string_token() {
      var string;
      if (!(starts(this.chunk, '"') || starts(this.chunk, "'"))) {
        return false;
      }
      if (!(string = this.balanced_token(['"', '"'], ['${', '}']) || this.balanced_token(["'", "'"]))) {
        return false;
      }
      this.interpolate_string(string.replace(STRING_NEWLINES, " \\\n"));
      this.line += count(string, "\n");
      this.i += string.length;
      return true;
    };
    // Matches heredocs, adjusting indentation to the correct level, as heredocs
    // preserve whitespace, but ignore indentation to the left.
    Lexer.prototype.heredoc_token = function heredoc_token() {
      var doc, match, quote;
      if (!(match = this.chunk.match(HEREDOC))) {
        return false;
      }
      quote = match[1].substr(0, 1);
      doc = this.sanitize_heredoc(match[2] || match[4], {
        quote: quote
      });
      this.interpolate_string(("" + quote + doc + quote));
      this.line += count(match[1], "\n");
      this.i += match[1].length;
      return true;
    };
    // Matches and conumes comments. We pass through comments into JavaScript,
    // so they're treated as real tokens, like any other part of the language.
    Lexer.prototype.comment_token = function comment_token() {
      var comment, i, lines, match;
      if (!(match = this.chunk.match(COMMENT))) {
        return false;
      }
      if (match[3]) {
        comment = this.sanitize_heredoc(match[3], {
          herecomment: true
        });
        this.token('HERECOMMENT', compact(comment.split(MULTILINER)));
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
    Lexer.prototype.js_token = function js_token() {
      var script;
      if (!(starts(this.chunk, '`'))) {
        return false;
      }
      if (!(script = this.balanced_token(['`', '`']))) {
        return false;
      }
      this.token('JS', script.replace(JS_CLEANER, ''));
      this.i += script.length;
      return true;
    };
    // Matches regular expression literals. Lexing regular expressions is difficult
    // to distinguish from division, so we borrow some basic heuristics from
    // JavaScript and Ruby, borrow slash balancing from `@balanced_token`, and
    // borrow interpolation from `@interpolate_string`.
    Lexer.prototype.regex_token = function regex_token() {
      var flags, regex, str;
      if (!(this.chunk.match(REGEX_START))) {
        return false;
      }
      if (include(NOT_REGEX, this.tag())) {
        return false;
      }
      if (!(regex = this.balanced_token(['/', '/']))) {
        return false;
      }
      regex += (flags = this.chunk.substr(regex.length).match(REGEX_FLAGS));
      if (regex.match(REGEX_INTERPOLATION)) {
        str = regex.substring(1).split('/')[0];
        str = str.replace(REGEX_ESCAPE, function(escaped) {
          return '\\' + escaped;
        });
        this.tokens = this.tokens.concat([['(', '('], ['NEW', 'new'], ['IDENTIFIER', 'RegExp'], ['CALL_START', '(']]);
        this.interpolate_string(("\"" + str + "\""), true);
        this.tokens = this.tokens.concat([[',', ','], ['STRING', ("\"" + flags + "\"")], [')', ')'], [')', ')']]);
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
      var _d = arguments.length, _e = _d >= 1;
      delimited = __slice.call(arguments, 0, _d - 0);
      return balanced_string(this.chunk, delimited);
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
      if (!(indent = this.match(MULTI_DENT, 1))) {
        return false;
      }
      this.line += count(indent, "\n");
      this.i += indent.length;
      prev = this.prev(2);
      size = indent.match(LAST_DENTS).reverse()[0].match(LAST_DENT)[1].length;
      next_character = this.chunk.match(MULTI_DENT)[4];
      no_newlines = next_character === '.' || this.unfinished();
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
      var match, prev_spaced, space, tag, value;
      match = this.chunk.match(OPERATOR);
      value = match && match[1];
      space = match && match[2];
      if (value && value.match(CODE)) {
        this.tag_parameters();
      }
      value = value || this.chunk.substr(0, 1);
      prev_spaced = this.prev() && this.prev().spaced;
      tag = value;
      if (value.match(ASSIGNMENT)) {
        tag = 'ASSIGN';
        if (include(JS_FORBIDDEN, this.value)) {
          this.assignment_error();
        }
      } else if (value === ';') {
        tag = 'TERMINATOR';
      } else if (value === '[' && this.tag() === '?' && !prev_spaced) {
        tag = 'SOAKED_INDEX_START';
        this.soaked_index = true;
        this.tokens.pop();
      } else if (value === ']' && this.soaked_index) {
        tag = 'SOAKED_INDEX_END';
        this.soaked_index = false;
      } else if (include(CALLABLE, this.tag()) && !prev_spaced) {
        if (value === '(') {
          tag = 'CALL_START';
        }
        if (value === '[') {
          tag = 'INDEX_START';
        }
      }
      this.i += value.length;
      if (space && prev_spaced && this.prev()[0] === 'ASSIGN' && include(HALF_ASSIGNMENTS, tag)) {
        return this.tag_half_assignment(tag);
      }
      this.token(tag, value);
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
    // Sanitize a heredoc or herecomment by escaping internal double quotes and
    // erasing all external indentation on the left-hand side.
    Lexer.prototype.sanitize_heredoc = function sanitize_heredoc(doc, options) {
      var indent;
      indent = (doc.match(HEREDOC_INDENT) || ['']).sort()[0];
      doc = doc.replace(new RegExp("^" + indent, 'gm'), '');
      if (options.herecomment) {
        return doc;
      }
      return doc.replace(MULTILINER, "\\n").replace(new RegExp(options.quote, 'g'), '\\"');
    };
    // Tag a half assignment.
    Lexer.prototype.tag_half_assignment = function tag_half_assignment(tag) {
      var last;
      last = this.tokens.pop();
      this.tokens.push([("" + tag + "="), ("" + tag + "="), last[2]]);
      return true;
    };
    // A source of ambiguity in our grammar used to be parameter lists in function
    // definitions versus argument lists in function calls. Walk backwards, tagging
    // parameters specially in order to make things easier for the parser.
    Lexer.prototype.tag_parameters = function tag_parameters() {
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
    Lexer.prototype.close_indentation = function close_indentation() {
      return this.outdent_token(this.indent);
    };
    // The error for when you try to use a forbidden word in JavaScript as
    // an identifier.
    Lexer.prototype.identifier_error = function identifier_error(word) {
      throw new Error(("SyntaxError: Reserved word \"" + word + "\" on line " + (this.line + 1)));
    };
    // The error for when you try to assign to a reserved word in JavaScript,
    // like "function" or "default".
    Lexer.prototype.assignment_error = function assignment_error() {
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
    Lexer.prototype.interpolate_string = function interpolate_string(str, escape_quotes) {
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
          } else if ((expr = balanced_string(str.substring(i), [['${', '}']]))) {
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
          } else if (tag === 'STRING' && escape_quotes) {
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
    Lexer.prototype.token = function token(tag, value) {
      return this.tokens.push([tag, value, this.line]);
    };
    // Peek at a tag in the current token stream.
    Lexer.prototype.tag = function tag(index, new_tag) {
      var tok;
      if (!(tok = this.prev(index))) {
        return null;
      }
      if ((typeof new_tag !== "undefined" && new_tag !== null)) {
        tok[0] = new_tag;
        return tok[0];
      }
      return tok[0];
    };
    // Peek at a value in the current token stream.
    Lexer.prototype.value = function value(index, val) {
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
    Lexer.prototype.prev = function prev(index) {
      return this.tokens[this.tokens.length - (index || 1)];
    };
    // Attempt to match a string against the current chunk, returning the indexed
    // match if successful, and `false` otherwise.
    Lexer.prototype.match = function match(regex, index) {
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
    Lexer.prototype.unfinished = function unfinished() {
      var prev;
      prev = this.prev(2);
      return this.value() && this.value().match && this.value().match(NO_NEWLINE) && prev && (prev[0] !== '.') && !this.value().match(CODE);
    };
    // Lexer Properties
    // ----------------
    // There are no exensions to the core lexer by default.
    Lexer.extensions = [];
    return Lexer;
  }).call(this);
  // Constants
  // ---------
  // Keywords that CoffeeScript shares in common with JavaScript.
  JS_KEYWORDS = ["if", "else", "true", "false", "new", "return", "try", "catch", "finally", "throw", "break", "continue", "for", "in", "while", "delete", "instanceof", "typeof", "switch", "super", "extends", "class", "this", "null"];
  // CoffeeScript-only keywords, which we're more relaxed about allowing. They can't
  // be used standalone, but you can reference them as an attached property.
  COFFEE_ALIASES = ["and", "or", "is", "isnt", "not"];
  COFFEE_KEYWORDS = COFFEE_ALIASES.concat(["then", "unless", "until", "yes", "no", "on", "off", "of", "by", "where", "when"]);
  // The combined list of keywords is the superset that gets passed verbatim to
  // the parser.
  KEYWORDS = JS_KEYWORDS.concat(COFFEE_KEYWORDS);
  // The list of keywords that are reserved by JavaScript, but not used, or are
  // used by CoffeeScript internally. We throw an error when these are encountered,
  // to avoid having a JavaScript error at runtime.
  RESERVED = ["case", "default", "do", "function", "var", "void", "with", "const", "let", "enum", "export", "import", "native"];
  // The superset of both JavaScript keywords and reserved words, none of which may
  // be used as identifiers or properties.
  JS_FORBIDDEN = JS_KEYWORDS.concat(RESERVED);
  // Token matching regexes.
  IDENTIFIER = /^([a-zA-Z\$_](\w|\$)*)/;
  NUMBER = /^(\b((0(x|X)[0-9a-fA-F]+)|([0-9]+(\.[0-9]+)?(e[+\-]?[0-9]+)?)))\b/i;
  HEREDOC = /^("{6}|'{6}|"{3}\n?([\s\S]*?)\n?([ \t]*)"{3}|'{3}\n?([\s\S]*?)\n?([ \t]*)'{3})/;
  INTERPOLATION = /^\$([a-zA-Z_@]\w*(\.\w+)*)/;
  OPERATOR = /^([+\*&|\/\-%=<>:!?]+)([ \t]*)/;
  WHITESPACE = /^([ \t]+)/;
  COMMENT = /^((\n?[ \t]*)?#{3}(?!#)\n*([\s\S]*?)\n*([ \t]*)#{3}|((\n?[ \t]*)?#[^\n]*)+)/;
  CODE = /^((-|=)>)/;
  MULTI_DENT = /^((\n([ \t]*))+)(\.)?/;
  LAST_DENTS = /\n([ \t]*)/g;
  LAST_DENT = /\n([ \t]*)/;
  ASSIGNMENT = /^(:|=)$/;
  // Regex-matching-regexes.
  REGEX_START = /^\/[^\/ ]/;
  REGEX_INTERPOLATION = /([^\\]\$[a-zA-Z_@]|[^\\]\$\{.*[^\\]\})/;
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
  NOT_REGEX = ['NUMBER', 'REGEX', '++', '--', 'FALSE', 'NULL', 'TRUE', ']'];
  // Tokens which could legitimately be invoked or indexed. A opening
  // parentheses or bracket following these tokens will be recorded as the start
  // of a function invocation or indexing operation.
  CALLABLE = ['IDENTIFIER', 'SUPER', ')', ']', '}', 'STRING', '@', 'THIS'];
  // Tokens that indicate an access -- keywords immediately following will be
  // treated as identifiers.
  ACCESSORS = ['PROPERTY_ACCESS', 'PROTOTYPE_ACCESS', 'SOAK_ACCESS', '@'];
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
