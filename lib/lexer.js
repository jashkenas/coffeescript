(function() {
  var ASSIGNED, BOOL, CALLABLE, CODE, COFFEE_ALIASES, COFFEE_KEYWORDS, COMMENT, COMPARE, COMPOUND_ASSIGN, HEREDOC, HEREDOC_INDENT, HEREGEX, HEREGEX_OMIT, IDENTIFIER, INDEXABLE, JSTOKEN, JS_FORBIDDEN, JS_KEYWORDS, LEADING_SPACES, LINE_BREAK, LOGIC, Lexer, MATH, MULTILINER, MULTI_DENT, NEXT_CHARACTER, NEXT_ELLIPSIS, NOT_REGEX, NO_NEWLINE, NUMBER, OPERATOR, REGEX, RELATION, RESERVED, Rewriter, SHIFT, SIMPLESTR, TRAILING_SPACES, UNARY, WHITESPACE, _ref, compact, count, include, last, op, starts;
  Rewriter = require('./rewriter').Rewriter;
  _ref = require('./helpers'), include = _ref.include, count = _ref.count, starts = _ref.starts, compact = _ref.compact, last = _ref.last;
  exports.Lexer = (function() {
    Lexer = (function() {
      function Lexer() {
        return this;
      };
      return Lexer;
    })();
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
      this.seenFor = false;
      this.indents = [];
      this.tokens = [];
      while (this.chunk = code.slice(this.i)) {
        this.identifierToken() || this.commentToken() || this.whitespaceToken() || this.lineToken() || this.heredocToken() || this.stringToken() || this.numberToken() || this.regexToken() || this.jsToken() || this.literalToken();
      }
      this.closeIndentation();
      if (o.rewrite === false) {
        return this.tokens;
      }
      return (new Rewriter).rewrite(this.tokens);
    };
    Lexer.prototype.identifierToken = function() {
      var colon, forcedIdentifier, id, input, match, tag;
      if (!(match = IDENTIFIER.exec(this.chunk))) {
        return false;
      }
      input = match[0], id = match[1], colon = match[2];
      this.i += input.length;
      if (id === 'all' && this.tag() === 'FOR') {
        this.token('ALL', id);
        return true;
      }
      forcedIdentifier = colon || this.tagAccessor();
      tag = 'IDENTIFIER';
      if (include(JS_KEYWORDS, id) || !forcedIdentifier && include(COFFEE_KEYWORDS, id)) {
        tag = id.toUpperCase();
        if (tag === 'WHEN' && include(LINE_BREAK, this.tag())) {
          tag = 'LEADING_WHEN';
        } else if (tag === 'FOR') {
          this.seenFor = true;
        } else if (include(UNARY, tag)) {
          tag = 'UNARY';
        } else if (include(RELATION, tag)) {
          if (tag !== 'INSTANCEOF' && this.seenFor) {
            this.seenFor = false;
            tag = 'FOR' + tag;
          } else {
            tag = 'RELATION';
            if (this.value() === '!') {
              this.tokens.pop();
              id = '!' + id;
            }
          }
        }
      }
      if (include(JS_FORBIDDEN, id)) {
        if (forcedIdentifier) {
          tag = 'IDENTIFIER';
          id = new String(id);
          id.reserved = true;
        } else if (include(RESERVED, id)) {
          this.identifierError(id);
        }
      }
      if (!forcedIdentifier) {
        if (COFFEE_ALIASES.hasOwnProperty(id)) {
          tag = (id = COFFEE_ALIASES[id]);
        }
        if (id === '!') {
          tag = 'UNARY';
        } else if (include(LOGIC, id)) {
          tag = 'LOGIC';
        } else if (include(BOOL, tag)) {
          id = tag.toLowerCase();
          tag = 'BOOL';
        }
      }
      this.token(tag, id);
      if (colon) {
        this.token(':', ':');
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
          if (0 < string.indexOf('#{', 1)) {
            this.interpolateString(string.slice(1, -1));
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
      if (quote === '"' && (0 <= doc.indexOf('#{'))) {
        this.interpolateString(doc, {
          heredoc: true
        });
      } else {
        this.token('STRING', this.makeString(doc, quote, true));
      }
      this.line += count(heredoc, '\n');
      this.i += heredoc.length;
      return true;
    };
    Lexer.prototype.commentToken = function() {
      var comment, here, match;
      if (!(match = this.chunk.match(COMMENT))) {
        return false;
      }
      comment = match[0], here = match[1];
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
      var match, regex;
      if (this.chunk.charAt(0) !== '/') {
        return false;
      }
      if (match = HEREGEX.exec(this.chunk)) {
        return this.heregexToken(match);
      }
      if (include(NOT_REGEX, this.tag())) {
        return false;
      }
      if (!(match = REGEX.exec(this.chunk))) {
        return false;
      }
      regex = match[0];
      this.token('REGEX', regex === '//' ? '/(?:)/' : regex);
      this.i += regex.length;
      return true;
    };
    Lexer.prototype.heregexToken = function(match) {
      var _i, _len, _ref2, _ref3, _ref4, _this, body, flags, heregex, re, tag, tokens, value;
      heregex = match[0], body = match[1], flags = match[2];
      this.i += heregex.length;
      if (0 > body.indexOf('#{')) {
        re = body.replace(HEREGEX_OMIT, '').replace(/\//g, '\\/');
        this.token('REGEX', "/" + (re || '(?:)') + "/" + flags);
        return true;
      }
      this.token('IDENTIFIER', 'RegExp');
      this.tokens.push(['CALL_START', '(']);
      tokens = [];
      for (_i = 0, _len = (_ref2 = this.interpolateString(body, {
        regex: true
      })).length; _i < _len; _i++) {
        _ref3 = _ref2[_i], tag = _ref3[0], value = _ref3[1];
        if (tag === 'TOKENS') {
          tokens.push.apply(tokens, value);
        } else {
          if (!(value = value.replace(HEREGEX_OMIT, ''))) {
            continue;
          }
          value = value.replace(/\\/g, '\\\\');
          tokens.push(['STRING', this.makeString(value, '"', true)]);
        }
        tokens.push(['+', '+']);
      }
      tokens.pop();
      if ((((_ref4 = tokens[0]) != null) ? _ref4[0] : undefined) !== 'STRING') {
        this.tokens.push(['STRING', '""'], ['+', '+']);
      }
      (_this = this.tokens).push.apply(_this, tokens);
      if (flags) {
        this.tokens.push([',', ','], ['STRING', '"' + flags + '"']);
      }
      this.token(')', ')');
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
      noNewlines = ((nextCharacter === '.' || nextCharacter === ',') && !NEXT_ELLIPSIS.test(this.chunk)) || this.unfinished();
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
          dent = this.indents.pop() - this.outdebt;
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
      var _ref2, match, prev, tag, value;
      if (match = OPERATOR.exec(this.chunk)) {
        value = match[0];
        if (CODE.test(value)) {
          this.tagParameters();
        }
      } else {
        value = this.chunk.charAt(0);
      }
      this.i += value.length;
      tag = value;
      prev = last(this.tokens);
      if (value === '=' && prev) {
        if (!prev[1].reserved && include(JS_FORBIDDEN, prev[1])) {
          this.assignmentError();
        }
        if (((_ref2 = prev[1]) === '||' || _ref2 === '&&')) {
          prev[0] = 'COMPOUND_ASSIGN';
          prev[1] += '=';
          return true;
        }
      }
      if (';' === value) {
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
      } else if (value === '?' && ((prev != null) ? prev.spaced : undefined)) {
        tag = 'LOGIC';
      } else if (prev && !prev.spaced) {
        if (value === '(' && include(CALLABLE, prev[0])) {
          if (prev[0] === '?') {
            prev[0] = 'FUNC_EXIST';
          }
          tag = 'CALL_START';
        } else if (value === '[' && include(INDEXABLE, prev[0])) {
          tag = 'INDEX_START';
          switch (prev[0]) {
            case '?':
              prev[0] = 'INDEX_SOAK';
              break;
            case '::':
              prev[0] = 'INDEX_PROTO';
              break;
          }
        }
      }
      this.token(tag, value);
      return true;
    };
    Lexer.prototype.tagAccessor = function() {
      var prev;
      if (!(prev = last(this.tokens)) || prev.spaced) {
        return false;
      }
      if (prev[1] === '::') {
        this.tag(0, 'PROTOTYPE_ACCESS');
      } else if (prev[1] === '.' && this.value(1) !== '.') {
        if (this.tag(1) === '?') {
          this.tag(0, 'SOAK_ACCESS');
          this.tokens.splice(-2, 1);
        } else {
          this.tag(0, 'PROPERTY_ACCESS');
        }
      } else {
        return prev[0] === '@';
      }
      return true;
    };
    Lexer.prototype.sanitizeHeredoc = function(doc, options) {
      var _ref2, attempt, herecomment, indent, match;
      indent = options.indent, herecomment = options.herecomment;
      if (herecomment && 0 > doc.indexOf('\n')) {
        return doc;
      }
      if (!herecomment) {
        while (match = HEREDOC_INDENT.exec(doc)) {
          attempt = match[1];
          if (indent === null || (0 < (_ref2 = attempt.length)) && (_ref2 < indent.length)) {
            indent = attempt;
          }
        }
      }
      if (indent) {
        doc = doc.replace(RegExp("\\n" + indent, "g"), '\n');
      }
      if (!herecomment) {
        doc = doc.replace(/^\n/, '');
      }
      return doc;
    };
    Lexer.prototype.tagParameters = function() {
      var i, tok;
      if (this.tag() !== ')') {
        return;
      }
      i = this.tokens.length;
      while (tok = this.tokens[--i]) {
        switch (tok[0]) {
          case 'IDENTIFIER':
            tok[0] = 'PARAM';
            break;
          case ')':
            tok[0] = 'PARAM_END';
            break;
          case '(':
          case 'CALL_START':
            tok[0] = 'PARAM_START';
            return true;
        }
      }
      return true;
    };
    Lexer.prototype.closeIndentation = function() {
      return this.outdentToken(this.indent);
    };
    Lexer.prototype.identifierError = function(word) {
      throw SyntaxError("Reserved word \"" + word + "\" on line " + (this.line + 1));
    };
    Lexer.prototype.assignmentError = function() {
      throw SyntaxError("Reserved word \"" + (this.value()) + "\" on line " + (this.line + 1) + " can't be assigned");
    };
    Lexer.prototype.balancedString = function(str, delimited, options) {
      var _i, _len, close, i, levels, open, pair, slen;
      options || (options = {});
      levels = [];
      i = 0;
      slen = str.length;
      while (i < slen) {
        if (levels.length && str.charAt(i) === '\\') {
          i += 1;
        } else {
          for (_i = 0, _len = delimited.length; _i < _len; _i++) {
            pair = delimited[_i];
            open = pair[0], close = pair[1];
            if (levels.length && starts(str, close, i) && last(levels) === pair) {
              levels.pop();
              i += close.length - 1;
              if (!levels.length) {
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
        if (!levels.length) {
          break;
        }
        i += 1;
      }
      if (levels.length) {
        throw SyntaxError("Unterminated " + (levels.pop()[0]) + " starting on line " + (this.line + 1));
      }
      return !i ? false : str.slice(0, i);
    };
    Lexer.prototype.interpolateString = function(str, options) {
      var _len, _ref2, _ref3, _this, expr, heredoc, i, inner, interpolated, letter, nested, pi, regex, tag, tokens, value;
      _ref2 = options || (options = {}), heredoc = _ref2.heredoc, regex = _ref2.regex;
      tokens = [];
      pi = 0;
      i = -1;
      while (letter = str.charAt(i += 1)) {
        if (letter === '\\') {
          i += 1;
          continue;
        }
        if (!(letter === '#' && str.charAt(i + 1) === '{' && (expr = this.balancedString(str.slice(i + 1), [['{', '}']])))) {
          continue;
        }
        if (pi < i) {
          tokens.push(['TO_BE_STRING', str.slice(pi, i)]);
        }
        inner = expr.slice(1, -1).replace(LEADING_SPACES, '').replace(TRAILING_SPACES, '');
        if (inner.length) {
          nested = new Lexer().tokenize(inner, {
            line: this.line,
            rewrite: false
          });
          nested.pop();
          if (nested.length > 1) {
            nested.unshift(['(', '(']);
            nested.push([')', ')']);
          }
          tokens.push(['TOKENS', nested]);
        }
        i += expr.length;
        pi = i + 1;
      }
      if ((i > pi) && (pi < str.length)) {
        tokens.push(['TO_BE_STRING', str.slice(pi)]);
      }
      if (regex) {
        return tokens;
      }
      if (!tokens.length) {
        return this.token('STRING', '""');
      }
      if (tokens[0][0] !== 'TO_BE_STRING') {
        tokens.unshift(['', '']);
      }
      if (interpolated = tokens.length > 1) {
        this.token('(', '(');
      }
      for (i = 0, _len = tokens.length; i < _len; i++) {
        _ref3 = tokens[i], tag = _ref3[0], value = _ref3[1];
        if (i) {
          this.token('+', '+');
        }
        if (tag === 'TOKENS') {
          (_this = this.tokens).push.apply(_this, value);
        } else {
          this.token('STRING', this.makeString(value, '"', heredoc));
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
    Lexer.prototype.tag = function(index, tag) {
      var tok;
      return (tok = last(this.tokens, index)) && ((tag != null) ? (tok[0] = tag) : tok[0]);
    };
    Lexer.prototype.value = function(index, val) {
      var tok;
      return (tok = last(this.tokens, index)) && ((val != null) ? (tok[1] = val) : tok[1]);
    };
    Lexer.prototype.unfinished = function() {
      var prev, value;
      return (prev = last(this.tokens, 1)) && prev[0] !== '.' && (value = this.value()) && !value.reserved && NO_NEWLINE.test(value) && !CODE.test(value) && !ASSIGNED.test(this.chunk);
    };
    Lexer.prototype.escapeLines = function(str, heredoc) {
      return str.replace(MULTILINER, heredoc ? '\\n' : '');
    };
    Lexer.prototype.makeString = function(body, quote, heredoc) {
      if (!body) {
        return quote + quote;
      }
      body = body.replace(/\\([\s\S])/g, function(match, contents) {
        return (contents === '\n' || contents === quote) ? contents : match;
      });
      body = body.replace(RegExp("" + quote, "g"), '\\$&');
      return quote + this.escapeLines(body, heredoc) + quote;
    };
    return Lexer;
  })();
  JS_KEYWORDS = ['true', 'false', 'null', 'this', 'new', 'delete', 'typeof', 'in', 'instanceof', 'return', 'throw', 'break', 'continue', 'debugger', 'if', 'else', 'switch', 'for', 'while', 'try', 'catch', 'finally', 'class', 'extends', 'super'];
  COFFEE_KEYWORDS = ['then', 'unless', 'until', 'loop', 'of', 'by', 'when'];
  for (op in (COFFEE_ALIASES = {
    and: '&&',
    or: '||',
    is: '==',
    isnt: '!=',
    not: '!',
    yes: 'TRUE',
    no: 'FALSE',
    on: 'TRUE',
    off: 'FALSE'
  })) {
    COFFEE_KEYWORDS.push(op);
  }
  RESERVED = ['case', 'default', 'do', 'function', 'var', 'void', 'with', 'const', 'let', 'enum', 'export', 'import', 'native', '__hasProp', '__extends', '__slice'];
  JS_FORBIDDEN = JS_KEYWORDS.concat(RESERVED);
  IDENTIFIER = /^([$A-Za-z_][$\w]*)([^\n\S]*:(?!:))?/;
  NUMBER = /^0x[\da-f]+|^(?:\d+(\.\d+)?|\.\d+)(?:e[+-]?\d+)?/i;
  HEREDOC = /^("""|''')([\s\S]*?)(?:\n[ \t]*)?\1/;
  OPERATOR = /^(?:-[-=>]?|\+[+=]?|\.\.\.?|[*&|\/%=<>^:!?]+)/;
  WHITESPACE = /^[ \t]+/;
  COMMENT = /^###([^#][\s\S]*?)(?:###[ \t]*\n|(?:###)?$)|^(?:\s*#(?!##[^#]).*)+/;
  CODE = /^[-=]>/;
  MULTI_DENT = /^(?:\n[ \t]*)+/;
  SIMPLESTR = /^'[^\\']*(?:\\.[^\\']*)*'/;
  JSTOKEN = /^`[^\\`]*(?:\\.[^\\`]*)*`/;
  REGEX = /^\/(?!\s)[^[\/\n\\]*(?:(?:\\[\s\S]|\[[^\]\n\\]*(?:\\[\s\S][^\]\n\\]*)*])[^[\/\n\\]*)*\/[imgy]{0,4}(?![A-Za-z])/;
  HEREGEX = /^\/{3}([\s\S]+?)\/{3}([imgy]{0,4})(?![A-Za-z])/;
  HEREGEX_OMIT = /\s+(?:#.*)?/g;
  MULTILINER = /\n/g;
  HEREDOC_INDENT = /\n+([ \t]*)/g;
  ASSIGNED = /^\s*@?[$A-Za-z_][$\w]*[ \t]*?[:=][^:=>]/;
  NEXT_CHARACTER = /^\s*(\S?)/;
  NEXT_ELLIPSIS = /^\s*\.\.\.?/;
  LEADING_SPACES = /^\s+/;
  TRAILING_SPACES = /\s+$/;
  NO_NEWLINE = /^(?:[-+*&|\/%=<>!.\\][<>=&|]*|and|or|is(?:nt)?|n(?:ot|ew)|delete|typeof|instanceof)$/;
  COMPOUND_ASSIGN = ['-=', '+=', '/=', '*=', '%=', '||=', '&&=', '?=', '<<=', '>>=', '>>>=', '&=', '^=', '|='];
  UNARY = ['UMINUS', 'UPLUS', '!', '!!', '~', 'NEW', 'TYPEOF', 'DELETE'];
  LOGIC = ['&', '|', '^', '&&', '||'];
  SHIFT = ['<<', '>>', '>>>'];
  COMPARE = ['<=', '<', '>', '>='];
  MATH = ['*', '/', '%'];
  RELATION = ['IN', 'OF', 'INSTANCEOF'];
  BOOL = ['TRUE', 'FALSE', 'NULL'];
  NOT_REGEX = ['NUMBER', 'REGEX', 'BOOL', '++', '--', ']'];
  CALLABLE = ['IDENTIFIER', 'STRING', 'REGEX', ')', ']', '}', '?', '::', '@', 'THIS', 'SUPER'];
  INDEXABLE = CALLABLE.concat('NUMBER', 'BOOL');
  LINE_BREAK = ['INDENT', 'OUTDENT', 'TERMINATOR'];
}).call(this);
