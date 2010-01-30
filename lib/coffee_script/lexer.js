(function(){
  var lex, sys;
  sys = require('sys');
  // The lexer reads a stream of CoffeeScript and divvys it up into tagged
  // tokens. A minor bit of the ambiguity in the grammar has been avoided by
  // pushing some extra smarts into the Lexer.
  exports.Lexer = (lex = function lex() {  });
  // The list of keywords passed verbatim to the parser.
  lex.KEYWORDS = ["if", "else", "then", "unless", "true", "false", "yes", "no", "on", "off", "and", "or", "is", "isnt", "not", "new", "return", "arguments", "try", "catch", "finally", "throw", "break", "continue", "for", "in", "of", "by", "where", "while", "delete", "instanceof", "typeof", "switch", "when", "super", "extends"];
  // Token matching regexes.
  lex.IDENTIFIER = /^([a-zA-Z$_](\w|\$)*)/;
  lex.NUMBER = /^(\b((0(x|X)[0-9a-fA-F]+)|([0-9]+(\.[0-9]+)?(e[+\-]?[0-9]+)?)))\b/i;
  lex.STRING = /^(""|''|"([\s\S]*?)([^\\]|\\\\)"|'([\s\S]*?)([^\\]|\\\\)')/;
  lex.HEREDOC = /^("{6}|'{6}|"{3}\n?([\s\S]*?)\n?([ \t]*)"{3}|'{3}\n?([\s\S]*?)\n?([ \t]*)'{3})/;
  lex.JS = /^(``|`([\s\S]*?)([^\\]|\\\\)`)/;
  lex.OPERATOR = /^([+\*&|\/\-%=<>:!?]+)/;
  lex.WHITESPACE = /^([ \t]+)/;
  lex.COMMENT = /^(((\n?[ \t]*)?#.*$)+)/;
  lex.CODE = /^((-|=)>)/;
  lex.REGEX = /^(\/(.*?)([^\\]|\\\\)\/[imgy]{0,4})/;
  lex.MULTI_DENT = /^((\n([ \t]*))+)(\.)?/;
  lex.LAST_DENT = /\n([ \t]*)/;
  lex.ASSIGNMENT = /^(:|=)$/;
  // Token cleaning regexes.
  lex.JS_CLEANER = /(^`|`$)/g;
  lex.MULTILINER = /\n/g;
  lex.STRING_NEWLINES = /\n[ \t]*/g;
  lex.COMMENT_CLEANER = /(^[ \t]*#|\n[ \t]*$)/mg;
  lex.NO_NEWLINE = /^([+\*&|\/\-%=<>:!.\\][<>=&|]*|and|or|is|isnt|not|delete|typeof|instanceof)$/;
  lex.HEREDOC_INDENT = /^[ \t]+/g;
  // Tokens which a regular expression will never immediately follow, but which
  // a division operator might.
  // See: http://www.mozilla.org/js/language/js20-2002-04/rationale/syntax.html#regular-expressions
  lex.NOT_REGEX = ['IDENTIFIER', 'NUMBER', 'REGEX', 'STRING', ')', '++', '--', ']', '}', 'FALSE', 'NULL', 'TRUE'];
  // Tokens which could legitimately be invoked or indexed.
  lex.CALLABLE = ['IDENTIFIER', 'SUPER', ')', ']', '}', 'STRING'];
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
    // sys.puts "original stream: #{@tokens.inspect}" if process.ENV['VERBOSE']
    // this.close_indentation()
    // (new Rewriter()).rewrite(this.tokens)
    return this.tokens;
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
    // return if this.indent_token()
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
    if (!((id = this.match(lex.IDENTIFIER, 1)))) {
      return false;
    }
    // Keywords are special identifiers tagged with their own name,
    // 'if' will result in an ['IF', "if"] token.
    tag = lex.KEYWORDS.indexOf(id) >= 0 ? id.toUpperCase() : 'IDENTIFIER';
    if (tag === 'WHEN' && (this.tag() === 'OUTDENT' || this.tag() === 'INDENT')) {
      tag = 'LEADING_WHEN';
    }
    if (tag === 'IDENTIFIER' && this.value() === '::') {
      this.tag(-1, 'PROTOTYPE_ACCESS');
    }
    if (tag === 'IDENTIFIER' && this.value() === '.' && !(this.value(-2) === '.')) {
      if (this.tag(-2) === '?') {
        this.tag(-1, 'SOAK_ACCESS');
        this.tokens.splice(-2, 1);
      } else {
        this.tag(-1, 'PROPERTY_ACCESS');
      }
    }
    this.token(tag, id);
    return this.i += id.length;
  };
  // Matches numbers, including decimals, hex, and exponential notation.
  lex.prototype.number_token = function number_token() {
    var number;
    if (!((number = this.match(lex.NUMBER, 1)))) {
      return false;
    }
    this.token('NUMBER', number);
    return this.i += number.length;
  };
  // Matches strings, including multi-line strings.
  lex.prototype.string_token = function string_token() {
    var escaped, string;
    if (!((string = this.match(lex.STRING, 1)))) {
      return false;
    }
    escaped = string.replace(STRING_NEWLINES, " \\\n");
    this.token('STRING', escaped);
    this.line += this.count(string, "\n");
    return this.i += string.length;
  };
  // Matches heredocs, adjusting indentation to the correct level.
  lex.prototype.heredoc_token = function heredoc_token() {
    var doc, indent, match;
    if (!((match = this.chunk.match(lex.HEREDOC)))) {
      return false;
    }
    doc = match[2] || match[4];
    indent = doc.match(lex.HEREDOC_INDENT).sort()[0];
    doc = doc.replace(new RegExp("^" + indent, 'g'), '').replace(lex.MULTILINER, "\\n").replace('"', '\\"');
    this.token('STRING', '"' + doc + '"');
    this.line += this.count(match[1], "\n");
    return this.i += match[1].length;
  };
  // Matches interpolated JavaScript.
  lex.prototype.js_token = function js_token() {
    var script;
    if (!((script = this.match(lex.JS, 1)))) {
      return false;
    }
    this.token('JS', script.replace(lex.JS_CLEANER, ''));
    return this.i += script.length;
  };
  // Matches regular expression literals.
  lex.prototype.regex_token = function regex_token() {
    var regex;
    if (!((regex = this.match(lex.REGEX, 1)))) {
      return false;
    }
    if (lex.NOT_REGEX.indexOf(this.tag()) >= 0) {
      return false;
    }
    this.token('REGEX', regex);
    return this.i += regex.length;
  };
  // Matches and conumes comments.
  lex.prototype.comment_token = function comment_token() {
    var comment;
    if (!((comment = this.match(lex.COMMENT, 1)))) {
      return false;
    }
    this.line += comment.match(lex.MULTILINER).length;
    this.token('COMMENT', comment.replace(lex.COMMENT_CLEANER, '').split(lex.MULTILINER));
    this.token("\n", "\n");
    return this.i += comment.length;
  };
  // Matches and consumes non-meaningful whitespace.
  lex.prototype.whitespace_token = function whitespace_token() {
    var space;
    if (!((space = this.match(lex.WHITESPACE, 1)))) {
      return false;
    }
    this.value().spaced = true;
    return this.i += space.length;
  };
  // We treat all other single characters as a token. Eg.: ( ) , . !
  // Multi-character operators are also literal tokens, so that Racc can assign
  // the proper order of operations.
  lex.prototype.literal_token = function literal_token() {
    var match, tag, value;
    match = this.chunk.match(lex.OPERATOR);
    value = match && match[1];
    if (value && value.match(lex.CODE)) {
      tag_parameters();
    }
    value = value || this.chunk.substr(0, 1);
    tag = value.match(lex.ASSIGNMENT) ? 'ASSIGN' : value;
    if (this.value() && this.value().spaced && lex.CALLABLE.indexOf(this.tag() >= 0)) {
      if (value === '(') {
        tag = 'CALL_START';
      }
      if (value === '[') {
        tag = 'INDEX_START';
      }
    }
    this.token(tag, value);
    return this.i += value.length;
  };
  // Helpers =============================================================
  // Add a token to the results, taking note of the line number.
  lex.prototype.token = function token(tag, value) {
    return this.tokens.push([tag, value]);
    // this.tokens.push([tag, Value.new(value, @line)])
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
  lex.prototype.count = function count(string, char) {
    var num, pos;
    num = 0;
    pos = string.indexOf(char);
    while (pos !== -1) {
      count += 1;
      pos = string.indexOf(char, pos + 1);
    }
    return count;
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
})();