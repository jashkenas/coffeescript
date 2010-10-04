(function() {
  var ASSIGNED, CALLABLE, CODE, COFFEE_ALIASES, COFFEE_KEYWORDS, COMMENT, COMPARE, COMPOUND_ASSIGN, CONVERSIONS, HEREDOC, HEREDOC_INDENT, HEREGEX, HEREGEX_OMIT, IDENTIFIER, JSTOKEN, JS_FORBIDDEN, JS_KEYWORDS, LEADING_SPACES, LINE_BREAK, LOGIC, Lexer, MATH, MULTILINER, MULTI_DENT, NEXT_CHARACTER, NOT_REGEX, NO_NEWLINE, NUMBER, OPERATOR, REGEX_END, REGEX_ESCAPE, REGEX_START, RESERVED, Rewriter, SHIFT, SIMPLESTR, TRAILING_SPACES, UNARY, WHITESPACE, _ref, compact, count, include, last, starts;
  Rewriter = require('./rewriter').Rewriter;
  _ref = require('./helpers'), include = _ref.include, count = _ref.count, starts = _ref.starts, compact = _ref.compact, last = _ref.last;
  exports.Lexer = (function() {
    Lexer = function() {};
    Lexer.prototype.tokenize = function(code, options) {
      var o;
      code = code.replace(/\r/g, '').replace(TRAILING_SPACES, '');
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
      return (new Rewriter).rewrite(this.tokens);
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
          if (!(string = this.balancedString(this.chunk, [['"', '"'], ['#{', '}']]))) {
            return false;
          }
          if (~string.indexOf('#{')) {
            this.interpolateString(string);
          } else {
            this.token('STRING', this.escapeLines(string));
          }
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
      if (!(match = HEREDOC.exec(this.chunk))) {
        return false;
      }
      heredoc = match[0];
      quote = heredoc.charAt(0);
      doc = this.sanitizeHeredoc(match[2], {
        quote: quote,
        indent: null
      });
      if (quote === '"' && ~doc.indexOf('#{')) {
        this.interpolateString(quote + doc + quote, {
          heredoc: true
        });
      } else {
        this.token('STRING', quote + this.escapeLines(doc, true) + quote);
      }
      this.line += count(heredoc, '\n');
      this.i += heredoc.length;
      return true;
    };
    Lexer.prototype.commentToken = function() {
      var _ref2, comment, here, match;
      if (!(match = this.chunk.match(COMMENT))) {
        return false;
      }
      _ref2 = match, comment = _ref2[0], here = _ref2[1];
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
      var _ref2, end, first, flags, match, regex, str;
      if (this.chunk.charAt(0) !== '/') {
        return false;
      }
      if (match = HEREGEX.exec(this.chunk)) {
        return this.heregexToken(match);
      }
      if (!(first = REGEX_START.exec(this.chunk))) {
        return false;
      }
      if (first[1] === ' ' && !('CALL_START' === (_ref2 = this.tag()) || '=' === _ref2)) {
        return false;
      }
      if (include(NOT_REGEX, this.tag())) {
        return false;
      }
      if (!(regex = this.balancedString(this.chunk, [['/', '/']]))) {
        return false;
      }
      if (!(end = this.chunk.slice(regex.length).match(REGEX_END))) {
        return false;
      }
      flags = end[0];
      if (~regex.indexOf('#{')) {
        str = regex.slice(1, -1);
        this.tokens.push(['IDENTIFIER', 'RegExp'], ['CALL_START', '(']);
        this.interpolateString("\"" + (str) + "\"", {
          regex: true
        });
        if (flags) {
          this.tokens.push([',', ','], ['STRING', ("\"" + (flags) + "\"")]);
        }
        this.tokens.push(['CALL_END', ')']);
      } else {
        this.token('REGEX', regex + flags);
      }
      this.i += regex.length + flags.length;
      return true;
    };
    Lexer.prototype.heregexToken = function(match) {
      var _ref2, body, flags, heregex, re;
      _ref2 = match, heregex = _ref2[0], body = _ref2[1], flags = _ref2[2];
      this.i += heregex.length;
      if (!(~body.indexOf('#{'))) {
        re = body.replace(HEREGEX_OMIT, '').replace(/\//g, '\\/');
        this.token('REGEX', "/" + (re || '(?:)') + "/" + (flags));
        return true;
      }
      this.token('IDENTIFIER', 'RegExp');
      this.tokens.push(['CALL_START', '(']);
      this.interpolateString("\"" + (body) + "\"", {
        regex: true,
        heregex: true
      });
      if (flags) {
        this.tokens.push([',', ','], ['STRING', '"' + flags + '"']);
      }
      this.tokens.push(['CALL_END', ')']);
      return true;
    };
    Lexer.prototype.lineToken = function() {
      var diff, indent, match, nextCharacter, noNewlines, prev, size;
      if (!(match = MULTI_DENT.exec(this.chunk))) {
        return false;
      }
      indent = match[0];
      this.line += count(indent, '\n');
      this.i += indent.length;
      prev = last(this.tokens, 1);
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
      prev = last(this.tokens);
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
      var _ref2, match, prev, space, spaced, tag, val, value;
      if (match = this.chunk.match(OPERATOR)) {
        _ref2 = match, value = _ref2[0], space = _ref2[1];
        if (CODE.test(value)) {
          this.tagParameters();
        }
      } else {
        value = this.chunk.charAt(0);
      }
      this.i += value.length;
      prev = last(this.tokens);
      spaced = ((prev != null) ? prev.spaced : undefined);
      tag = value;
      if (value === '=') {
        if (include(JS_FORBIDDEN, val = this.value())) {
          this.assignmentError();
        }
        if (('or' === val || 'and' === val)) {
          this.tokens.splice(-1, 1, ['COMPOUND_ASSIGN', CONVERSIONS[val] + '=', prev[2]]);
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
              this.tag(0, 'INDEX_SOAK');
              break;
            case '::':
              this.tag(0, 'INDEX_PROTO');
              break;
          }
        }
      }
      this.token(tag, value);
      return true;
    };
    Lexer.prototype.tagAccessor = function() {
      var accessor, prev;
      if (!(prev = last(this.tokens)) || prev.spaced) {
        return false;
      }
      accessor = (function() {
        if (prev[1] === '::') {
          return this.tag(0, 'PROTOTYPE_ACCESS');
        } else if (prev[1] === '.' && this.value(1) !== '.') {
          if (this.tag(1) === '?') {
            this.tag(0, 'SOAK_ACCESS');
            return this.tokens.splice(-2, 1);
          } else {
            return this.tag(0, 'PROPERTY_ACCESS');
          }
        } else {
          return prev[0] === '@';
        }
      }).call(this);
      return accessor ? 'accessor' : false;
    };
    Lexer.prototype.sanitizeHeredoc = function(doc, options) {
      var _ref2, attempt, herecomment, indent, match, quote;
      _ref2 = options, indent = _ref2.indent, herecomment = _ref2.herecomment;
      if (herecomment && !include(doc, '\n')) {
        return doc;
      }
      if (!(herecomment)) {
        while ((match = HEREDOC_INDENT.exec(doc))) {
          attempt = match[1];
          if (indent === null || (0 < (_ref2 = attempt.length)) && (_ref2 < indent.length)) {
            indent = attempt;
          }
        }
      }
      if (indent) {
        doc = doc.replace(RegExp("\\n" + (indent), "g"), '\n');
      }
      if (herecomment) {
        return doc;
      }
      quote = options.quote;
      doc = doc.replace(/^\n/, '');
      doc = doc.replace(/\\([\s\S])/g, function(m, c) {
        return ('\n' === c || quote === c) ? c : m;
      });
      doc = doc.replace(RegExp("" + (quote), "g"), '\\$&');
      if (quote === "'") {
        doc = this.escapeLines(doc, true);
      }
      return doc;
    };
    Lexer.prototype.tagParameters = function() {
      var i, tok;
      if (this.tag() !== ')') {
        return null;
      }
      i = this.tokens.length;
      while (true) {
        if (!(tok = this.tokens[--i])) {
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
      var _i, _len, _ref2, close, i, levels, open, pair, slash, slen;
      options || (options = {});
      slash = delimited[0][0] === '/';
      levels = [];
      i = 0;
      slen = str.length;
      while (i < slen) {
        if (levels.length && str.charAt(i) === '\\') {
          i += 1;
        } else {
          for (_i = 0, _len = delimited.length; _i < _len; _i++) {
            pair = delimited[_i];
            _ref2 = pair, open = _ref2[0], close = _ref2[1];
            if (levels.length && starts(str, close, i) && last(levels) === pair) {
              levels.pop();
              i += close.length - 1;
              if (!(levels.length)) {
                i += 1;
              }
              break;
            }
            if (starts(str, open, i)) {
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
      var _i, _len, _ref2, char, expr, heredoc, i, inner, interpolated, lexer, nested, pi, push, regex, s, tag, tok, tokens, value;
      if (str.length < 5) {
        return this.token('STRING', this.escapeLines(str, heredoc));
      }
      _ref2 = options || (options = {}), heredoc = _ref2.heredoc, regex = _ref2.regex;
      lexer = new Lexer;
      tokens = [];
      pi = 1;
      i = 0;
      while (char = str.charAt(i += 1)) {
        if (char === '\\') {
          i += 1;
          continue;
        }
        if (!(char === '#' && str.charAt(i + 1) === '{' && (expr = this.balancedString(str.slice(i + 1), [['{', '}']])))) {
          continue;
        }
        if (pi < i) {
          tokens.push(['STRING', '"' + this.escapeLines(str.slice(pi, i), heredoc) + '"']);
        }
        inner = expr.slice(1, -1).replace(LEADING_SPACES, '').replace(TRAILING_SPACES, '');
        if (inner.length) {
          if (heredoc) {
            inner = inner.replace(/\\\"/g, '"');
          }
          nested = lexer.tokenize("(" + (inner) + ")", {
            line: this.line
          });
          for (_i = 0, _len = nested.length; _i < _len; _i++) {
            tok = nested[_i];
            if (tok[0] === 'CALL_END') {
              (tok[0] = ')');
            }
          }
          nested.pop();
          tokens.push(['TOKENS', nested]);
        } else {
          tokens.push(['STRING', '""']);
        }
        i += expr.length;
        pi = i + 1;
      }
      if ((i > pi) && (pi < str.length - 1)) {
        s = this.escapeLines(str.slice(pi, -1), heredoc);
        tokens.push(['STRING', '"' + s + '"']);
      }
      if (tokens[0][0] !== 'STRING') {
        tokens.unshift(['STRING', '""']);
      }
      interpolated = !regex && tokens.length > 1;
      if (interpolated) {
        this.token('(', '(');
      }
      push = tokens.push;
      for (i = 0, _len = tokens.length; i < _len; i++) {
        _ref2 = tokens[i], tag = _ref2[0], value = _ref2[1];
        if (i) {
          this.token('+', '+');
        }
        if (tag === 'TOKENS') {
          push.apply(this.tokens, value);
          continue;
        }
        if (regex) {
          value = value.slice(1, -1);
          value = value.replace(/[\\\"]/g, '\\$&');
          if (options.heregex) {
            value = value.replace(HEREGEX_OMIT, '');
          }
          value = '"' + value + '"';
        }
        this.token(tag, value);
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
      if (!(tok = last(this.tokens, index))) {
        return null;
      }
      return (tok[0] = (newTag != null) ? newTag : tok[0]);
    };
    Lexer.prototype.value = function(index, val) {
      var tok;
      if (!(tok = last(this.tokens, index))) {
        return null;
      }
      return (tok[1] = (val != null) ? val : tok[1]);
    };
    Lexer.prototype.unfinished = function() {
      var prev, value;
      return (prev = last(this.tokens, 1)) && prev[0] !== '.' && (value = this.value()) && NO_NEWLINE.test(value) && !CODE.test(value) && !ASSIGNED.test(this.chunk);
    };
    Lexer.prototype.escapeLines = function(str, heredoc) {
      return str.replace(MULTILINER, heredoc ? '\\n' : '');
    };
    return Lexer;
  })();
  JS_KEYWORDS = ['if', 'else', 'true', 'false', 'new', 'return', 'try', 'catch', 'finally', 'throw', 'break', 'continue', 'for', 'in', 'while', 'delete', 'instanceof', 'typeof', 'switch', 'super', 'extends', 'class', 'this', 'null', 'debugger'];
  COFFEE_ALIASES = ['and', 'or', 'is', 'isnt', 'not'];
  COFFEE_KEYWORDS = COFFEE_ALIASES.concat(['then', 'unless', 'until', 'loop', 'yes', 'no', 'on', 'off', 'of', 'by', 'when']);
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
  REGEX_END = /^[imgy]{0,4}(?![a-zA-Z])/;
  REGEX_ESCAPE = /\\[^#]/g;
  HEREGEX = /^\/{3}([\s\S]+?)\/{3}([imgy]{0,4})(?![A-Za-z])/;
  HEREGEX_OMIT = /\s+(?:#.*)?/g;
  MULTILINER = /\n/g;
  NO_NEWLINE = /^(?:[-+*&|\/%=<>!.\\][<>=&|]*|and|or|is(?:nt)?|n(?:ot|ew)|delete|typeof|instanceof)$/;
  HEREDOC_INDENT = /\n+([ \t]*)/g;
  ASSIGNED = /^\s*@?[$A-Za-z_][$\w]*[ \t]*?[:=][^:=>]/;
  NEXT_CHARACTER = /^\s*(\S?)/;
  LEADING_SPACES = /^\s+/;
  TRAILING_SPACES = /\s+$/;
  COMPOUND_ASSIGN = ['-=', '+=', '/=', '*=', '%=', '||=', '&&=', '?=', '<<=', '>>=', '>>>=', '&=', '^=', '|='];
  UNARY = ['UMINUS', 'UPLUS', '!', '!!', '~', 'NEW', 'TYPEOF', 'DELETE'];
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
