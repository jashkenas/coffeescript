(function(){
  var ACCESSORS, ASSIGNMENT, BEFORE_WHEN, CALLABLE, CODE, COMMENT, COMMENT_CLEANER, HEREDOC, HEREDOC_INDENT, IDENTIFIER, JS, JS_CLEANER, KEYWORDS, LAST_DENT, LAST_DENTS, MULTILINER, MULTI_DENT, NOT_REGEX, NO_NEWLINE, NUMBER, OPERATOR, REGEX, RESERVED, Rewriter, STRING, STRING_NEWLINES, WHITESPACE, lex;
  if ((typeof process !== "undefined" && process !== null)) {
    Rewriter = require('./rewriter').Rewriter;
  } else {
    this.exports = this;
    Rewriter = this.Rewriter;
  }
  // The lexer reads a stream of CoffeeScript and divvys it up into tagged
  // tokens. A minor bit of the ambiguity in the grammar has been avoided by
  // pushing some extra smarts into the Lexer.
  exports.Lexer = (lex = function lex() {  });
  // Constants ============================================================
  // The list of keywords passed verbatim to the parser.
  KEYWORDS = ["if", "else", "then", "unless", "true", "false", "yes", "no", "on", "off", "and", "or", "is", "isnt", "not", "new", "return", "try", "catch", "finally", "throw", "break", "continue", "for", "in", "of", "by", "where", "while", "delete", "instanceof", "typeof", "switch", "when", "super", "extends"];
  // The list of keywords that are reserved by JavaScript, but not used, and aren't
  // used by CoffeeScript. Using these will throw an error at compile time.
  RESERVED = ["case", "default", "do", "function", "var", "void", "with", "class", "const", "let", "debugger", "enum", "export", "import", "native"];
  // Token matching regexes. (keep the IDENTIFIER regex in sync with AssignNode.)
  IDENTIFIER = /^([a-zA-Z$_](\w|\$)*)/;
  NUMBER = /^(\b((0(x|X)[0-9a-fA-F]+)|([0-9]+(\.[0-9]+)?(e[+\-]?[0-9]+)?)))\b/i;
  STRING = /^(""|''|"([\s\S]*?)([^\\]|\\\\)"|'([\s\S]*?)([^\\]|\\\\)')/;
  HEREDOC = /^("{6}|'{6}|"{3}\n?([\s\S]*?)\n?([ \t]*)"{3}|'{3}\n?([\s\S]*?)\n?([ \t]*)'{3})/;
  JS = /^(``|`([\s\S]*?)([^\\]|\\\\)`)/;
  OPERATOR = /^([+\*&|\/\-%=<>:!?]+)/;
  WHITESPACE = /^([ \t]+)/;
  COMMENT = /^(((\n?[ \t]*)?#[^\n]*)+)/;
  CODE = /^((-|=)>)/;
  REGEX = /^(\/(.*?)([^\\]|\\\\)\/[imgy]{0,4})/;
  MULTI_DENT = /^((\n([ \t]*))+)(\.)?/;
  LAST_DENTS = /\n([ \t]*)/g;
  LAST_DENT = /\n([ \t]*)/;
  ASSIGNMENT = /^(:|=)$/;
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
  NOT_REGEX = ['IDENTIFIER', 'NUMBER', 'REGEX', 'STRING', ')', '++', '--', ']', '}', 'FALSE', 'NULL', 'TRUE'];
  // Tokens which could legitimately be invoked or indexed.
  CALLABLE = ['IDENTIFIER', 'SUPER', ')', ']', '}', 'STRING'];
  // Tokens that indicate an access -- keywords immediately following will be
  // treated as identifiers.
  ACCESSORS = ['PROPERTY_ACCESS', 'PROTOTYPE_ACCESS', 'SOAK_ACCESS', '@'];
  // Tokens that, when immediately preceding a 'WHEN', indicate that its leading.
  BEFORE_WHEN = ['INDENT', 'OUTDENT', 'TERMINATOR'];
  // Scan by attempting to match tokens one character at a time. Slow and steady.
  lex.prototype.tokenize = function tokenize(code) {
    this.code = code;
    // Cleanup code by remove extra line breaks, TODO: chomp
    this.i = 0;
    // Current character position we're parsing
    this.line = 1;
    // The current line.
    this.indent = 0;
    // The current indent level.
    this.indents = [];
    // The stack of all indent levels we are currently within.
    this.tokens = [];
    // Collection of all parsed tokens in the form [:TOKEN_TYPE, value]
    while (this.i < this.code.length) {
      this.chunk = this.code.slice(this.i);
      this.extract_next_token();
    }
    this.close_indentation();
    return (new Rewriter()).rewrite(this.tokens);
  };
  // At every position, run through this list of attempted matches,
  // short-circuiting if any of them succeed.
  lex.prototype.extract_next_token = function extract_next_token() {
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
    if (this.indent_token()) {
      return null;
    }
    if (this.comment_token()) {
      return null;
    }
    if (this.whitespace_token()) {
      return null;
    }
    return this.literal_token();
  };
  // Tokenizers ==========================================================
  // Matches identifying literals: variables, keywords, method names, etc.
  lex.prototype.identifier_token = function identifier_token() {
    var id, tag;
    if (!((id = this.match(IDENTIFIER, 1)))) {
      return false;
    }
    if (this.value() === '::') {
      this.tag(1, 'PROTOTYPE_ACCESS');
    }
    if (this.value() === '.' && !(this.value(2) === '.')) {
      if (this.tag(2) === '?') {
        this.tag(1, 'SOAK_ACCESS');
        this.tokens.splice(-2, 1);
      } else {
        this.tag(1, 'PROPERTY_ACCESS');
      }
    }
    tag = 'IDENTIFIER';
    if (KEYWORDS.indexOf(id) >= 0 && !(ACCESSORS.indexOf(this.tag()) >= 0)) {
      tag = id.toUpperCase();
    }
    if (RESERVED.indexOf(id) >= 0) {
      throw new Error('SyntaxError: Reserved word "' + id + '" on line ' + this.line);
    }
    if (tag === 'WHEN' && BEFORE_WHEN.indexOf(this.tag()) >= 0) {
      tag = 'LEADING_WHEN';
    }
    this.token(tag, id);
    this.i += id.length;
    return true;
  };
  // Matches numbers, including decimals, hex, and exponential notation.
  lex.prototype.number_token = function number_token() {
    var number;
    if (!((number = this.match(NUMBER, 1)))) {
      return false;
    }
    this.token('NUMBER', number);
    this.i += number.length;
    return true;
  };
  // Matches strings, including multi-line strings.
  lex.prototype.string_token = function string_token() {
    var escaped, string;
    if (!((string = this.match(STRING, 1)))) {
      return false;
    }
    escaped = string.replace(STRING_NEWLINES, " \\\n");
    this.token('STRING', escaped);
    this.line += this.count(string, "\n");
    this.i += string.length;
    return true;
  };
  // Matches heredocs, adjusting indentation to the correct level.
  lex.prototype.heredoc_token = function heredoc_token() {
    var doc, indent, match;
    if (!((match = this.chunk.match(HEREDOC)))) {
      return false;
    }
    doc = match[2] || match[4];
    indent = (doc.match(HEREDOC_INDENT) || ['']).sort()[0];
    doc = doc.replace(new RegExp("^" + indent, 'gm'), '').replace(MULTILINER, "\\n").replace('"', '\\"');
    this.token('STRING', '"' + doc + '"');
    this.line += this.count(match[1], "\n");
    this.i += match[1].length;
    return true;
  };
  // Matches interpolated JavaScript.
  lex.prototype.js_token = function js_token() {
    var script;
    if (!((script = this.match(JS, 1)))) {
      return false;
    }
    this.token('JS', script.replace(JS_CLEANER, ''));
    this.i += script.length;
    return true;
  };
  // Matches regular expression literals.
  lex.prototype.regex_token = function regex_token() {
    var regex;
    if (!((regex = this.match(REGEX, 1)))) {
      return false;
    }
    if (NOT_REGEX.indexOf(this.tag()) >= 0) {
      return false;
    }
    this.token('REGEX', regex);
    this.i += regex.length;
    return true;
  };
  // Matches and conumes comments.
  lex.prototype.comment_token = function comment_token() {
    var comment;
    if (!((comment = this.match(COMMENT, 1)))) {
      return false;
    }
    this.line += (comment.match(MULTILINER) || []).length;
    this.token('COMMENT', comment.replace(COMMENT_CLEANER, '').split(MULTILINER));
    this.token('TERMINATOR', "\n");
    this.i += comment.length;
    return true;
  };
  // Record tokens for indentation differing from the previous line.
  lex.prototype.indent_token = function indent_token() {
    var diff, indent, next_character, no_newlines, prev, size;
    if (!((indent = this.match(MULTI_DENT, 1)))) {
      return false;
    }
    this.line += indent.match(MULTILINER).length;
    this.i += indent.length;
    next_character = this.chunk.match(MULTI_DENT)[4];
    prev = this.tokens[this.tokens.length - 2];
    no_newlines = next_character === '.' || (this.value() && this.value().match(NO_NEWLINE) && prev && (prev[0] !== '.') && !this.value().match(CODE));
    if (no_newlines) {
      return this.suppress_newlines(indent);
    }
    size = indent.match(LAST_DENTS).reverse()[0].match(LAST_DENT)[1].length;
    if (size === this.indent) {
      return this.newline_token(indent);
    }
    if (size > this.indent) {
      diff = size - this.indent;
      this.token('INDENT', diff);
      this.indents.push(diff);
    } else {
      this.outdent_token(this.indent - size);
    }
    this.indent = size;
    return true;
  };
  // Record an oudent token or tokens, if we're moving back inwards past
  // multiple recorded indents.
  lex.prototype.outdent_token = function outdent_token(move_out) {
    var last_indent;
    while (move_out > 0 && this.indents.length) {
      last_indent = this.indents.pop();
      this.token('OUTDENT', last_indent);
      move_out -= last_indent;
    }
    if (!(this.tag() === 'TERMINATOR')) {
      this.token('TERMINATOR', "\n");
    }
    return true;
  };
  // Matches and consumes non-meaningful whitespace.
  lex.prototype.whitespace_token = function whitespace_token() {
    var space;
    if (!((space = this.match(WHITESPACE, 1)))) {
      return false;
    }
    this.tokens[this.tokens.length - 1].spaced = true;
    this.i += space.length;
    return true;
  };
  // Multiple newlines get merged together.
  // Use a trailing \ to escape newlines.
  lex.prototype.newline_token = function newline_token(newlines) {
    if (!(this.tag() === 'TERMINATOR')) {
      this.token('TERMINATOR', "\n");
    }
    return true;
  };
  // Tokens to explicitly escape newlines are removed once their job is done.
  lex.prototype.suppress_newlines = function suppress_newlines(newlines) {
    if (this.value() === "\\") {
      this.tokens.pop();
    }
    return true;
  };
  // We treat all other single characters as a token. Eg.: ( ) , . !
  // Multi-character operators are also literal tokens, so that Racc can assign
  // the proper order of operations.
  lex.prototype.literal_token = function literal_token() {
    var match, tag, value;
    match = this.chunk.match(OPERATOR);
    value = match && match[1];
    if (value && value.match(CODE)) {
      this.tag_parameters();
    }
    value = value || this.chunk.substr(0, 1);
    tag = value.match(ASSIGNMENT) ? 'ASSIGN' : value;
    if (value === ';') {
      tag = 'TERMINATOR';
    }
    if (!this.tokens[this.tokens.length - 1].spaced && CALLABLE.indexOf(this.tag()) >= 0) {
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
  // Helpers =============================================================
  // Add a token to the results, taking note of the line number.
  lex.prototype.token = function token(tag, value) {
    return this.tokens.push([tag, value, this.line]);
  };
  // Look at a tag in the current token stream.
  lex.prototype.tag = function tag(index, tag) {
    var tok;
    if (!((tok = this.tokens[this.tokens.length - (index || 1)]))) {
      return null;
    }
    if ((typeof tag !== "undefined" && tag !== null)) {
      return (tok[0] = tag);
    }
    return tok[0];
  };
  // Look at a value in the current token stream.
  lex.prototype.value = function value(index, val) {
    var tok;
    if (!((tok = this.tokens[this.tokens.length - (index || 1)]))) {
      return null;
    }
    if ((typeof val !== "undefined" && val !== null)) {
      return (tok[1] = val);
    }
    return tok[1];
  };
  // Count the occurences of a character in a string.
  lex.prototype.count = function count(string, letter) {
    var num, pos;
    num = 0;
    pos = string.indexOf(letter);
    while (pos !== -1) {
      num += 1;
      pos = string.indexOf(letter, pos + 1);
    }
    return num;
  };
  // Attempt to match a string against the current chunk, returning the indexed
  // match.
  lex.prototype.match = function match(regex, index) {
    var m;
    if (!((m = this.chunk.match(regex)))) {
      return false;
    }
    return m ? m[index] : false;
  };
  // A source of ambiguity in our grammar was parameter lists in function
  // definitions (as opposed to argument lists in function calls). Tag
  // parameter identifiers in order to avoid this. Also, parameter lists can
  // make use of splats.
  lex.prototype.tag_parameters = function tag_parameters() {
    var i, tok;
    if (this.tag() !== ')') {
      return null;
    }
    i = 0;
    while (true) {
      i += 1;
      tok = this.tokens[this.tokens.length - i];
      if (!tok) {
        return null;
      }
      if (tok[0] === 'IDENTIFIER') {
        tok[0] = 'PARAM';
      } else if (tok[0] === ')') {
        tok[0] = 'PARAM_END';
      } else if (tok[0] === '(') {
        return (tok[0] = 'PARAM_START');
      }
    }
    return true;
  };
  // Close up all remaining open blocks. IF the first token is an indent,
  // axe it.
  lex.prototype.close_indentation = function close_indentation() {
    return this.outdent_token(this.indent);
  };
})();