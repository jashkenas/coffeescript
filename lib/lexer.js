(function() {
  var ASSIGNED, CALLABLE, CODE, COFFEE_ALIASES, COFFEE_KEYWORDS, COMMENT, COMPARE, COMPOUND_ASSIGN, CONVERSIONS, HEREDOC, HEREDOC_INDENT, IDENTIFIER, JS_CLEANER, JS_FORBIDDEN, JS_KEYWORDS, LAST_DENT, LAST_DENTS, LINE_BREAK, LOGIC, Lexer, MATH, MULTILINER, MULTI_DENT, NEXT_CHARACTER, NOT_REGEX, NO_NEWLINE, NUMBER, OPERATOR, REGEX_END, REGEX_ESCAPE, REGEX_INTERPOLATION, REGEX_START, RESERVED, Rewriter, SHIFT, UNARY, WHITESPACE, _a, _b, _c, compact, count, helpers, include, starts;
  var __slice = Array.prototype.slice;
  if (typeof process !== "undefined" && process !== null) {
    _a = require('./rewriter');
    Rewriter = _a.Rewriter;
    _b = require('./helpers');
    helpers = _b.helpers;
  } else {
    this.exports = this;
    Rewriter = this.Rewriter;
    helpers = this.helpers;
  }
  _c = helpers;
  include = _c.include;
  count = _c.count;
  starts = _c.starts;
  compact = _c.compact;
  exports.Lexer = (function() {
    Lexer = function() {};
    Lexer.prototype.tokenize = function(code, options) {
      var o;
      code = code.replace(/(\r|\s+$)/g, '');
      o = options || {};
      this.code = code;
      this.i = 0;
      this.line = o.line || 0;
      this.indent = 0;
      this.indebt = 0;
      this.outdebt = 0;
      this.indents = [];
      this.tokens = [];
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
      if (id === 'all' && this.tag() === 'FOR') {
        tag = 'ALL';
      }
      if (include(UNARY, tag)) {
        tag = 'UNARY';
      }
      if (include(JS_FORBIDDEN, id)) {
        if (forcedIdentifier) {
          tag = 'STRING';
          id = ("\"" + (id) + "\"");
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
        if (include(LOGIC, id)) {
          tag = 'LOGIC';
        }
        if (id === '!') {
          tag = 'UNARY';
        }
      }
      this.token(tag, id);
      if (close_index) {
        this.token(']', ']');
      }
      return true;
    };
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
    Lexer.prototype.stringToken = function() {
      var string;
      if (!(starts(this.chunk, '"') || starts(this.chunk, "'"))) {
        return false;
      }
      if (!(string = this.balancedToken(['"', '"'], ['#{', '}']) || this.balancedToken(["'", "'"]))) {
        return false;
      }
      this.interpolateString(string.replace(/\n/g, '\\\n'));
      this.line += count(string, "\n");
      this.i += string.length;
      return true;
    };
    Lexer.prototype.heredocToken = function() {
      var doc, match, quote;
      if (!(match = this.chunk.match(HEREDOC))) {
        return false;
      }
      quote = match[1].substr(0, 1);
      doc = this.sanitizeHeredoc(match[2] || match[4] || '', {
        quote: quote
      });
      this.interpolateString(quote + doc + quote, {
        heredoc: true
      });
      this.line += count(match[1], "\n");
      this.i += match[1].length;
      return true;
    };
    Lexer.prototype.commentToken = function() {
      var match;
      if (!(match = this.chunk.match(COMMENT))) {
        return false;
      }
      this.line += count(match[1], "\n");
      this.i += match[1].length;
      if (match[4]) {
        this.token('HERECOMMENT', this.sanitizeHeredoc(match[4], {
          herecomment: true,
          indent: match[3]
        }));
        this.token('TERMINATOR', '\n');
      }
      return true;
    };
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
    Lexer.prototype.regexToken = function() {
      var _d, end, first, flags, regex, str;
      if (!(first = this.chunk.match(REGEX_START))) {
        return false;
      }
      if (first[1] === ' ' && !('CALL_START' === (_d = this.tag()) || '=' === _d)) {
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
        this.interpolateString("\"" + (str) + "\"", {
          escapeQuotes: true
        });
        if (flags) {
          this.tokens.splice(this.tokens.length, 0, [',', ','], ['STRING', ("\"" + (flags) + "\"")]);
        }
        this.tokens.splice(this.tokens.length, 0, [')', ')'], [')', ')']);
      } else {
        this.token('REGEX', regex);
      }
      this.i += regex.length;
      return true;
    };
    Lexer.prototype.balancedToken = function() {
      var delimited;
      delimited = __slice.call(arguments, 0);
      return this.balancedString(this.chunk, delimited);
    };
    Lexer.prototype.lineToken = function() {
      var diff, indent, nextCharacter, noNewlines, prev, size;
      if (!(indent = this.match(MULTI_DENT, 1))) {
        return false;
      }
      this.line += count(indent, "\n");
      this.i += indent.length;
      prev = this.prev(2);
      size = indent.match(LAST_DENTS).reverse()[0].match(LAST_DENT)[1].length;
      nextCharacter = this.match(NEXT_CHARACTER, 1);
      noNewlines = nextCharacter === '.' || nextCharacter === ',' || this.unfinished();
      if (size - this.indebt === this.indent) {
        if (noNewlines) {
          return this.suppressNewlines();
        }
        return this.newlineToken(indent);
      } else if (size > this.indent) {
        if (noNewlines) {
          this.indebt = size - this.indent;
          return this.suppressNewlines();
        }
        diff = size - this.indent + this.outdebt;
        this.token('INDENT', diff);
        this.indents.push(diff);
        this.outdebt = (this.indebt = 0);
      } else {
        this.indebt = 0;
        this.outdentToken(this.indent - size, noNewlines);
      }
      this.indent = size;
      return true;
    };
    Lexer.prototype.outdentToken = function(moveOut, noNewlines, close) {
      var dent, len;
      while (moveOut > 0) {
        len = this.indents.length - 1;
        if (this.indents[len] === undefined) {
          moveOut = 0;
        } else if (this.indents[len] === this.outdebt) {
          moveOut -= this.outdebt;
          this.outdebt = 0;
        } else if (this.indents[len] < this.outdebt) {
          this.outdebt -= this.indents[len];
          moveOut -= this.indents[len];
        } else {
          dent = this.indents.pop();
          dent -= this.outdebt;
          moveOut -= dent;
          this.outdebt = 0;
          this.token('OUTDENT', dent);
        }
      }
      if (dent) {
        this.outdebt -= moveOut;
      }
      if (!(this.tag() === 'TERMINATOR' || noNewlines)) {
        this.token('TERMINATOR', "\n");
      }
      return true;
    };
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
    Lexer.prototype.newlineToken = function(newlines) {
      if (this.tag() !== 'TERMINATOR') {
        this.token('TERMINATOR', "\n");
      }
      return true;
    };
    Lexer.prototype.suppressNewlines = function() {
      if (this.value() === "\\") {
        this.tokens.pop();
      }
      return true;
    };
    Lexer.prototype.literalToken = function() {
      var _d, match, prev, space, spaced, tag, value;
      match = this.chunk.match(OPERATOR);
      value = match && match[1];
      space = match && match[2];
      if (value && value.match(CODE)) {
        this.tagParameters();
      }
      value || (value = this.chunk.substr(0, 1));
      this.i += value.length;
      spaced = (prev = this.prev()) && prev.spaced;
      tag = value;
      if (value === '=') {
        if (include(JS_FORBIDDEN, this.value())) {
          this.assignmentError();
        }
        if (('or' === (_d = this.value()) || 'and' === _d)) {
          this.tokens.splice(this.tokens.length - 1, 1, ['COMPOUND_ASSIGN', CONVERSIONS[this.value()] + '=', prev[2]]);
          return true;
        }
      }
      if (value === ';') {
        tag = 'TERMINATOR';
      } else if (include(LOGIC, value)) {
        tag = 'LOGIC';
      } else if (include(MATH, value)) {
        tag = 'MATH';
      } else if (include(COMPARE, value)) {
        tag = 'COMPARE';
      } else if (include(COMPOUND_ASSIGN, value)) {
        tag = 'COMPOUND_ASSIGN';
      } else if (include(UNARY, value)) {
        tag = 'UNARY';
      } else if (include(SHIFT, value)) {
        tag = 'SHIFT';
      } else if (include(CALLABLE, this.tag()) && !spaced) {
        if (value === '(') {
          if (prev[0] === '?') {
            prev[0] = 'FUNC_EXIST';
          }
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
      this.token(tag, value);
      return true;
    };
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
      return accessor ? 'accessor' : false;
    };
    Lexer.prototype.sanitizeHeredoc = function(doc, options) {
      var _d, attempt, indent, match;
      indent = options.indent;
      if (options.herecomment && !include(doc, '\n')) {
        return doc;
      }
      if (!(options.herecomment)) {
        while ((match = HEREDOC_INDENT.exec(doc)) !== null) {
          attempt = (typeof (_d = match[2]) !== "undefined" && _d !== null) ? match[2] : match[3];
          if (!(typeof indent !== "undefined" && indent !== null) || attempt.length < indent.length) {
            indent = attempt;
          }
        }
      }
      indent || (indent = '');
      doc = doc.replace(new RegExp("^" + indent, 'gm'), '').replace(/^\n/, '');
      if (options.herecomment) {
        return doc;
      }
      return doc.replace(MULTILINER, "\\n").replace(new RegExp(options.quote, 'g'), "\\" + (options.quote));
    };
    Lexer.prototype.tagParameters = function() {
      var i, tok;
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
        switch (tok[0]) {
        case 'IDENTIFIER':
          tok[0] = 'PARAM';
          break;
        case ')':
          tok[0] = 'PARAM_END';
          break;
        case '(':
        case 'CALL_START':
          return (tok[0] = 'PARAM_START');
        }
      }
      return true;
    };
    Lexer.prototype.closeIndentation = function() {
      return this.outdentToken(this.indent);
    };
    Lexer.prototype.identifierError = function(word) {
      throw new Error("SyntaxError: Reserved word \"" + (word) + "\" on line " + (this.line + 1));
    };
    Lexer.prototype.assignmentError = function() {
      throw new Error("SyntaxError: Reserved word \"" + (this.value()) + "\" on line " + (this.line + 1) + " can't be assigned");
    };
    Lexer.prototype.balancedString = function(str, delimited, options) {
      var _d, _e, _f, _g, close, i, levels, open, pair, slash;
      options || (options = {});
      slash = delimited[0][0] === '/';
      levels = [];
      i = 0;
      while (i < str.length) {
        if (levels.length && starts(str, '\\', i)) {
          i += 1;
        } else {
          _e = delimited;
          for (_d = 0, _f = _e.length; _d < _f; _d++) {
            pair = _e[_d];
            _g = pair;
            open = _g[0];
            close = _g[1];
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
        throw new Error("SyntaxError: Unterminated " + (levels.pop()[0]) + " starting on line " + (this.line + 1));
      }
      return !i ? false : str.substring(0, i);
    };
    Lexer.prototype.interpolateString = function(str, options) {
      var _d, _e, _f, _g, _h, _i, escaped, expr, i, idx, inner, interpolated, lexer, nested, pi, quote, tag, tok, token, tokens, value;
      options || (options = {});
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
          } else if (expr = this.balancedString(str.substring(i), [['#{', '}']])) {
            if (pi < i) {
              tokens.push(['STRING', quote + str.substring(pi, i) + quote]);
            }
            inner = expr.substring(2, expr.length - 1);
            if (inner.length) {
              if (options.heredoc) {
                inner = inner.replace(new RegExp('\\\\' + quote, 'g'), quote);
              }
              nested = lexer.tokenize("(" + (inner) + ")", {
                line: this.line
              });
              _e = nested;
              for (idx = 0, _f = _e.length; idx < _f; idx++) {
                tok = _e[idx];
                if (tok[0] === 'CALL_END') {
                  (tok[0] = ')');
                }
              }
              nested.pop();
              tokens.push(['TOKENS', nested]);
            } else {
              tokens.push(['STRING', quote + quote]);
            }
            i += expr.length - 1;
            pi = i + 1;
          }
          i += 1;
        }
        if (pi < i && pi < str.length - 1) {
          tokens.push(['STRING', quote + str.substring(pi, i) + quote]);
        }
        if (tokens[0][0] !== 'STRING') {
          tokens.unshift(['STRING', '""']);
        }
        interpolated = tokens.length > 1;
        if (interpolated) {
          this.token('(', '(');
        }
        _g = tokens;
        for (i = 0, _h = _g.length; i < _h; i++) {
          token = _g[i];
          _i = token;
          tag = _i[0];
          value = _i[1];
          if (tag === 'TOKENS') {
            this.tokens = this.tokens.concat(value);
          } else if (tag === 'STRING' && options.escapeQuotes) {
            escaped = value.substring(1, value.length - 1).replace(/"/g, '\\"');
            this.token(tag, "\"" + (escaped) + "\"");
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
    Lexer.prototype.token = function(tag, value) {
      return this.tokens.push([tag, value, this.line]);
    };
    Lexer.prototype.tag = function(index, newTag) {
      var tok;
      if (!(tok = this.prev(index))) {
        return null;
      }
      if (typeof newTag !== "undefined" && newTag !== null) {
        return (tok[0] = newTag);
      }
      return tok[0];
    };
    Lexer.prototype.value = function(index, val) {
      var tok;
      if (!(tok = this.prev(index))) {
        return null;
      }
      if (typeof val !== "undefined" && val !== null) {
        return (tok[1] = val);
      }
      return tok[1];
    };
    Lexer.prototype.prev = function(index) {
      return this.tokens[this.tokens.length - (index || 1)];
    };
    Lexer.prototype.match = function(regex, index) {
      var m;
      if (!(m = this.chunk.match(regex))) {
        return false;
      }
      return m ? m[index] : false;
    };
    Lexer.prototype.unfinished = function() {
      var prev;
      prev = this.prev(2);
      return this.value() && this.value().match && this.value().match(NO_NEWLINE) && prev && (prev[0] !== '.') && !this.value().match(CODE) && !this.chunk.match(ASSIGNED);
    };
    return Lexer;
  })();
  JS_KEYWORDS = ["if", "else", "true", "false", "new", "return", "try", "catch", "finally", "throw", "break", "continue", "for", "in", "while", "delete", "instanceof", "typeof", "switch", "super", "extends", "class", "this", "null", "debugger"];
  COFFEE_ALIASES = ["and", "or", "is", "isnt", "not"];
  COFFEE_KEYWORDS = COFFEE_ALIASES.concat(["then", "unless", "until", "loop", "yes", "no", "on", "off", "of", "by", "where", "when"]);
  RESERVED = ["case", "default", "do", "function", "var", "void", "with", "const", "let", "enum", "export", "import", "native", "__hasProp", "__extends", "__slice"];
  JS_FORBIDDEN = JS_KEYWORDS.concat(RESERVED);
  IDENTIFIER = /^([a-zA-Z\$_](\w|\$)*)/;
  NUMBER = /^(((\b0(x|X)[0-9a-fA-F]+)|((\b[0-9]+(\.[0-9]+)?|\.[0-9]+)(e[+\-]?[0-9]+)?)))\b/i;
  HEREDOC = /^("{6}|'{6}|"{3}([\s\S]*?)\n?([ \t]*)"{3}|'{3}([\s\S]*?)\n?([ \t]*)'{3})/;
  OPERATOR = /^(-[\-=>]?|\+[+=]?|[*&|\/%=<>^:!?]+)([ \t]*)/;
  WHITESPACE = /^([ \t]+)/;
  COMMENT = /^(([ \t]*\n)*([ \t]*)###([^#][\s\S]*?)(###[ \t]*\n|(###)?$)|(\s*#(?!##[^#])[^\n]*)+)/;
  CODE = /^((-|=)>)/;
  MULTI_DENT = /^((\n([ \t]*))+)(\.)?/;
  LAST_DENTS = /\n([ \t]*)/g;
  LAST_DENT = /\n([ \t]*)/;
  REGEX_START = /^\/([^\/])/;
  REGEX_INTERPOLATION = /([^\\]#\{.*[^\\]\})/;
  REGEX_END = /^(([imgy]{1,4})\b|\W|$)/;
  REGEX_ESCAPE = /\\[^\$]/g;
  JS_CLEANER = /(^`|`$)/g;
  MULTILINER = /\n/g;
  NO_NEWLINE = /^([+\*&|\/\-%=<>!.\\][<>=&|]*|and|or|is|isnt|not|delete|typeof|instanceof)$/;
  HEREDOC_INDENT = /(\n+([ \t]*)|^([ \t]+))/g;
  ASSIGNED = /^\s*(([a-zA-Z\$_@]\w*|["'][^\r\n]+?["']|\d+)[ \t]*?[:=][^:=])/;
  NEXT_CHARACTER = /^\s*(\S)/;
  COMPOUND_ASSIGN = ['-=', '+=', '/=', '*=', '%=', '||=', '&&=', '?=', '<<=', '>>=', '>>>=', '&=', '^=', '|='];
  UNARY = ['UMINUS', 'UPLUS', '!', '!!', '~', 'TYPEOF', 'DELETE'];
  LOGIC = ['&', '|', '^', '&&', '||'];
  SHIFT = ['<<', '>>', '>>>'];
  COMPARE = ['<=', '<', '>', '>='];
  MATH = ['*', '/', '%'];
  NOT_REGEX = ['NUMBER', 'REGEX', '++', '--', 'FALSE', 'NULL', 'TRUE', ']'];
  CALLABLE = ['IDENTIFIER', 'SUPER', ')', ']', '}', 'STRING', '@', 'THIS', '?', '::'];
  LINE_BREAK = ['INDENT', 'OUTDENT', 'TERMINATOR'];
  CONVERSIONS = {
    'and': '&&',
    'or': '||',
    'is': '==',
    'isnt': '!=',
    'not': '!',
    '===': '=='
  };
})();
