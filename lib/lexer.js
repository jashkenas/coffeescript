(function() {
  var ASSIGNED, CALLABLE, CODE, COFFEE_ALIASES, COFFEE_KEYWORDS, COMMENT, COMPARE, COMPOUND_ASSIGN, CONVERSIONS, HEREDOC, HEREDOC_INDENT, IDENTIFIER, JSTOKEN, JS_FORBIDDEN, JS_KEYWORDS, LINE_BREAK, LOGIC, Lexer, MATH, MULTILINER, MULTI_DENT, NEXT_CHARACTER, NOT_REGEX, NO_NEWLINE, NUMBER, OPERATOR, REGEX_END, REGEX_ESCAPE, REGEX_INTERPOLATION, REGEX_START, RESERVED, Rewriter, SHIFT, SIMPLESTR, UNARY, WHITESPACE, _ref, compact, count, include, starts;
  var __slice = Array.prototype.slice;
  _ref = require('./rewriter');
  Rewriter = _ref.Rewriter;
  _ref = require('./helpers');
  include = _ref.include;
  count = _ref.count;
  starts = _ref.starts;
  compact = _ref.compact;
  exports.Lexer = (function() {
    Lexer = function() {};
    Lexer.prototype.tokenize = function(code, options) {
      var o;
      code = code.replace(/\r/g, '').replace(/\s+$/, '');
      o = options || {};
      this.code = code;
      this.i = 0;
      this.line = o.line || 0;
      this.indent = 0;
      this.indebt = 0;
      this.outdebt = 0;
      this.indents = [];
      this.tokens = [];
      while ((this.chunk = code.slice(this.i))) {
        this.identifierToken() || this.commentToken() || this.whitespaceToken() || this.lineToken() || this.heredocToken() || this.stringToken() || this.numberToken() || this.regexToken() || this.jsToken() || this.literalToken();
      }
      this.closeIndentation();
      if (o.rewrite === false) {
        return this.tokens;
      }
      return (new Rewriter()).rewrite(this.tokens);
    };
    Lexer.prototype.identifierToken = function() {
      var closeIndex, forcedIdentifier, id, match, tag;
      if (!(match = IDENTIFIER.exec(this.chunk))) {
        return false;
      }
      id = match[0];
      this.i += id.length;
      if (id === 'all' && this.tag() === 'FOR') {
        this.token('ALL', id);
        return true;
      }
      forcedIdentifier = this.tagAccessor() || ASSIGNED.test(this.chunk);
      tag = 'IDENTIFIER';
      if (include(JS_KEYWORDS, id) || !forcedIdentifier && include(COFFEE_KEYWORDS, id)) {
        tag = id.toUpperCase();
        if (tag === 'WHEN' && include(LINE_BREAK, this.tag())) {
          tag = 'LEADING_WHEN';
        } else if (include(UNARY, tag)) {
          tag = 'UNARY';
        }
      }
      if (include(JS_FORBIDDEN, id)) {
        if (forcedIdentifier) {
          tag = 'STRING';
          id = ("\"" + (id) + "\"");
          if (forcedIdentifier === 'accessor') {
            closeIndex = true;
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
        if (id === '!') {
          tag = 'UNARY';
        } else if (include(LOGIC, id)) {
          tag = 'LOGIC';
        }
      }
      this.token(tag, id);
      if (closeIndex) {
        this.token(']', ']');
      }
      return true;
    };
    Lexer.prototype.numberToken = function() {
      var match, number;
      if (!(match = NUMBER.exec(this.chunk))) {
        return false;
      }
      number = match[0];
      if (this.tag() === '.' && number.charAt(0) === '.') {
        return false;
      }
      this.i += number.length;
      this.token('NUMBER', number);
      return true;
    };
    Lexer.prototype.stringToken = function() {
      var match, string;
      switch (this.chunk.charAt(0)) {
        case "'":
          if (!(match = SIMPLESTR.exec(this.chunk))) {
            return false;
          }
          this.token('STRING', (string = match[0]).replace(MULTILINER, '\\\n'));
          break;
        case '"':
          if (!(string = this.balancedToken(['"', '"'], ['#{', '}']))) {
            return false;
          }
          this.interpolateString(string);
          break;
        default:
          return false;
      }
      this.line += count(string, '\n');
      this.i += string.length;
      return true;
    };
    Lexer.prototype.heredocToken = function() {
      var doc, heredoc, match, quote;
      if (!(match = this.chunk.match(HEREDOC))) {
        return false;
      }
      heredoc = match[0];
      quote = heredoc.charAt(0);
      doc = this.sanitizeHeredoc(match[2], {
        quote: quote,
        indent: null
      });
      this.interpolateString(quote + doc + quote, {
        heredoc: true
      });
      this.line += count(heredoc, '\n');
      this.i += heredoc.length;
      return true;
    };
    Lexer.prototype.commentToken = function() {
      var _ref2, comment, here, match;
      if (!(match = this.chunk.match(COMMENT))) {
        return false;
      }
      _ref2 = match;
      comment = _ref2[0];
      here = _ref2[1];
      this.line += count(comment, '\n');
      this.i += comment.length;
      if (here) {
        this.token('HERECOMMENT', this.sanitizeHeredoc(here, {
          herecomment: true,
          indent: Array(this.indent + 1).join(' ')
        }));
        this.token('TERMINATOR', '\n');
      }
      return true;
    };
    Lexer.prototype.jsToken = function() {
      var match, script;
      if (!(this.chunk.charAt(0) === '`' && (match = JSTOKEN.exec(this.chunk)))) {
        return false;
      }
      this.token('JS', (script = match[0]).slice(1, -1));
      this.i += script.length;
      return true;
    };
    Lexer.prototype.regexToken = function() {
      var _ref2, end, first, flags, regex, str;
      if (!(first = this.chunk.match(REGEX_START))) {
        return false;
      }
      if (first[1] === ' ' && !('CALL_START' === (_ref2 = this.tag()) || '=' === _ref2)) {
        return false;
      }
      if (include(NOT_REGEX, this.tag())) {
        return false;
      }
      if (!(regex = this.balancedToken(['/', '/']))) {
        return false;
      }
      if (!(end = this.chunk.slice(regex.length).match(REGEX_END))) {
        return false;
      }
      flags = end[0];
      if (REGEX_INTERPOLATION.test(regex)) {
        str = regex.slice(1, -1);
        str = str.replace(REGEX_ESCAPE, '\\$&');
        this.tokens.push(['(', '('], ['NEW', 'new'], ['IDENTIFIER', 'RegExp'], ['CALL_START', '(']);
        this.interpolateString("\"" + (str) + "\"", {
          escapeQuotes: true
        });
        if (flags) {
          this.tokens.push([',', ','], ['STRING', ("\"" + (flags) + "\"")]);
        }
        this.tokens.push([')', ')'], [')', ')']);
      } else {
        this.token('REGEX', regex + flags);
      }
      this.i += regex.length + flags.length;
      return true;
    };
    Lexer.prototype.balancedToken = function() {
      var delimited;
      delimited = __slice.call(arguments, 0);
      return this.balancedString(this.chunk, delimited);
    };
    Lexer.prototype.lineToken = function() {
      var diff, indent, match, nextCharacter, noNewlines, prev, size;
      if (!(match = MULTI_DENT.exec(this.chunk))) {
        return false;
      }
      indent = match[0];
      this.line += count(indent, '\n');
      this.i += indent.length;
      prev = this.prev(2);
      size = indent.length - 1 - indent.lastIndexOf('\n');
      nextCharacter = NEXT_CHARACTER.exec(this.chunk)[1];
      noNewlines = (('.' === nextCharacter || ',' === nextCharacter)) || this.unfinished();
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
        this.token('TERMINATOR', '\n');
      }
      return true;
    };
    Lexer.prototype.whitespaceToken = function() {
      var match, prev;
      if (!(match = WHITESPACE.exec(this.chunk))) {
        return false;
      }
      prev = this.prev();
      if (prev) {
        prev.spaced = true;
      }
      this.i += match[0].length;
      return true;
    };
    Lexer.prototype.newlineToken = function(newlines) {
      if (this.tag() !== 'TERMINATOR') {
        this.token('TERMINATOR', '\n');
      }
      return true;
    };
    Lexer.prototype.suppressNewlines = function() {
      if (this.value() === '\\') {
        this.tokens.pop();
      }
      return true;
    };
    Lexer.prototype.literalToken = function() {
      var _ref2, match, prev, space, spaced, tag, value;
      if (match = this.chunk.match(OPERATOR)) {
        _ref2 = match;
        value = _ref2[0];
        space = _ref2[1];
        if (CODE.test(value)) {
          this.tagParameters();
        }
      } else {
        value = this.chunk.charAt(0);
      }
      this.i += value.length;
      spaced = (prev = this.prev()) && prev.spaced;
      tag = value;
      if (value === '=') {
        if (include(JS_FORBIDDEN, this.value())) {
          this.assignmentError();
        }
        if (('or' === (_ref2 = this.value()) || 'and' === _ref2)) {
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
          switch (this.tag()) {
            case '?':
              this.tag(1, 'INDEX_SOAK');
              break;
            case '::':
              this.tag(1, 'INDEX_PROTO');
              break;
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
        } else if (prev[1] === '.' && this.value(2) !== '.') {
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
      var _ref2, attempt, herecomment, indent, match;
      _ref2 = options;
      indent = _ref2.indent;
      herecomment = _ref2.herecomment;
      if (herecomment && !include(doc, '\n')) {
        return doc;
      }
      if (!(herecomment)) {
        while ((match = HEREDOC_INDENT.exec(doc))) {
          attempt = match[1];
          if (indent === null || (0 < attempt.length) && (attempt.length < indent.length)) {
            indent = attempt;
          }
        }
      }
      if (indent) {
        doc = doc.replace(new RegExp("\\n" + (indent), "g"), '\n');
      }
      if (herecomment) {
        return doc;
      }
      doc = doc.replace(/^\n/, '').replace(new RegExp("" + (options.quote), "g"), '\\$&');
      if (options.quote === "'") {
        doc = this.escapeLines(doc, true);
      }
      return doc;
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
      var _i, _len, _ref2, _ref3, close, i, levels, open, pair, slash, slen;
      options || (options = {});
      slash = delimited[0][0] === '/';
      levels = [];
      i = 0;
      slen = str.length;
      while (i < slen) {
        if (levels.length && str.charAt(i) === '\\') {
          i += 1;
        } else {
          _ref2 = delimited;
          for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
            pair = _ref2[_i];
            _ref3 = pair;
            open = _ref3[0];
            close = _ref3[1];
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
        if (!levels.length || slash && str.charAt(i) === '\n') {
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
      return !i ? false : str.slice(0, i);
    };
    Lexer.prototype.interpolateString = function(str, options) {
      var _len, _ref2, _ref3, end, escapeQuotes, escaped, expr, heredoc, i, idx, inner, interpolated, lexer, nested, pi, push, quote, s, tag, tok, token, tokens, value;
      _ref2 = options || {};
      heredoc = _ref2.heredoc;
      escapeQuotes = _ref2.escapeQuotes;
      quote = str.charAt(0);
      if (quote !== '"' || str.length < 3) {
        return this.token('STRING', str);
      }
      lexer = new Lexer();
      tokens = [];
      i = (pi = 1);
      end = str.length - 1;
      while (i < end) {
        if (str.charAt(i) === '\\') {
          i += 1;
        } else if (expr = this.balancedString(str.slice(i), [['#{', '}']])) {
          if (pi < i) {
            s = quote + this.escapeLines(str.slice(pi, i), heredoc) + quote;
            tokens.push(['STRING', s]);
          }
          inner = expr.slice(2, -1).replace(/^[ \t]*\n/, '');
          if (inner.length) {
            if (heredoc) {
              inner = inner.replace(RegExp('\\\\' + quote, 'g'), quote);
            }
            nested = lexer.tokenize("(" + (inner) + ")", {
              line: this.line
            });
            _ref2 = nested;
            for (idx = 0, _len = _ref2.length; idx < _len; idx++) {
              tok = _ref2[idx];
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
      if ((i > pi) && (pi < str.length - 1)) {
        s = str.slice(pi, i).replace(MULTILINER, heredoc ? '\\n' : '');
        tokens.push(['STRING', quote + s + quote]);
      }
      if (tokens[0][0] !== 'STRING') {
        tokens.unshift(['STRING', '""']);
      }
      interpolated = tokens.length > 1;
      if (interpolated) {
        this.token('(', '(');
      }
      _ref2 = tokens;
      push = _ref2.push;
      _ref2 = tokens;
      for (i = 0, _len = _ref2.length; i < _len; i++) {
        token = _ref2[i];
        _ref3 = token;
        tag = _ref3[0];
        value = _ref3[1];
        if (tag === 'TOKENS') {
          push.apply(this.tokens, value);
        } else if (tag === 'STRING' && escapeQuotes) {
          escaped = value.slice(1, -1).replace(/"/g, '\\"');
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
    Lexer.prototype.unfinished = function() {
      var prev, value;
      return (prev = this.prev(2)) && prev[0] !== '.' && (value = this.value()) && NO_NEWLINE.test(value) && !CODE.test(value) && !ASSIGNED.test(this.chunk);
    };
    Lexer.prototype.escapeLines = function(str, heredoc) {
      return str.replace(MULTILINER, heredoc ? '\\n' : '');
    };
    return Lexer;
  })();
  JS_KEYWORDS = ['if', 'else', 'true', 'false', 'new', 'return', 'try', 'catch', 'finally', 'throw', 'break', 'continue', 'for', 'in', 'while', 'delete', 'instanceof', 'typeof', 'switch', 'super', 'extends', 'class', 'this', 'null', 'debugger'];
  COFFEE_ALIASES = ['and', 'or', 'is', 'isnt', 'not'];
  COFFEE_KEYWORDS = COFFEE_ALIASES.concat(['then', 'unless', 'until', 'loop', 'yes', 'no', 'on', 'off', 'of', 'by', 'where', 'when']);
  RESERVED = ['case', 'default', 'do', 'function', 'var', 'void', 'with', 'const', 'let', 'enum', 'export', 'import', 'native', '__hasProp', '__extends', '__slice'];
  JS_FORBIDDEN = JS_KEYWORDS.concat(RESERVED);
  IDENTIFIER = /^[a-zA-Z_$][\w$]*/;
  NUMBER = /^0x[\da-f]+|^(?:\d+(\.\d+)?|\.\d+)(?:e[+-]?\d+)?/i;
  HEREDOC = /^("""|''')([\s\S]*?)\n?[ \t]*\1/;
  OPERATOR = /^(?:-[-=>]?|\+[+=]?|[*&|\/%=<>^:!?]+)(?=([ \t]*))/;
  WHITESPACE = /^[ \t]+/;
  COMMENT = /^###([^#][\s\S]*?)(?:###[ \t]*\n|(?:###)?$)|^(?:\s*#(?!##[^#]).*)+/;
  CODE = /^[-=]>/;
  MULTI_DENT = /^(?:\n[ \t]*)+/;
  SIMPLESTR = /^'[^\\']*(?:\\.[^\\']*)*'/;
  JSTOKEN = /^`[^\\`]*(?:\\.[^\\`]*)*`/;
  REGEX_START = /^\/([^\/])/;
  REGEX_INTERPOLATION = /[^\\]#\{.*[^\\]\}/;
  REGEX_END = /^[imgy]{0,4}(?![a-zA-Z])/;
  REGEX_ESCAPE = /\\[^#]/g;
  MULTILINER = /\n/g;
  NO_NEWLINE = /^(?:[-+*&|\/%=<>!.\\][<>=&|]*|and|or|is(?:nt)?|not|delete|typeof|instanceof)$/;
  HEREDOC_INDENT = /\n+([ \t]*)/g;
  ASSIGNED = /^\s*@?[$A-Za-z_][$\w]*[ \t]*?[:=][^:=>]/;
  NEXT_CHARACTER = /^\s*(\S?)/;
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
}).call(this);
