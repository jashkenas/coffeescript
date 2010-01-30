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
  lex.JS_CLEANER = /(^`|`$)/;
  lex.MULTILINER = /\n/;
  lex.STRING_NEWLINES = /\n[ \t]*/;
  lex.COMMENT_CLEANER = /(^[ \t]*#|\n[ \t]*$)/;
  lex.NO_NEWLINE = /^([+\*&|\/\-%=<>:!.\\][<>=&|]*|and|or|is|isnt|not|delete|typeof|instanceof)$/;
  lex.HEREDOC_INDENT = /^[ \t]+/;
  // Tokens which a regular expression will never immediately follow, but which
  // a division operator might.
  // See: http://www.mozilla.org/js/language/js20-2002-04/rationale/syntax.html#regular-expressions
  lex.NOT_REGEX = ['IDENTIFIER', 'NUMBER', 'REGEX', 'STRING', ')', '++', '--', ']', '}', 'FALSE', 'NULL', 'TRUE'];
  // Tokens which could legitimately be invoked or indexed.
  lex.CALLABLE = ['IDENTIFIER', 'SUPER', ')', ']', '}', 'STRING'];
  // Scan by attempting to match tokens one character at a time. Slow and steady.
  lex.prototype.tokenize = function tokenize(code) {
    this.code = code.chomp;
    // Cleanup code by remove extra line breaks
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
    this.spaced = nil;
    // The last value that has a space following it.
    while (this.i < this.code.length) {
      this.chunk = this.code.slice(this.i, -1 + 1);
      this.extract_next_token();
    }
    if (process.ENV['VERBOSE']) {
      sys.puts("original stream: #{@tokens.inspect}");
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
  // Look at a tag in the current token stream.
  lex.prototype.tag = function tag(index, tag) {
    var tok;
    if (!((tok = this.tokens[index || -1]))) {
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
    if (!((tok = this.tokens[index || -1]))) {
      return null;
    }
    if ((typeof val !== "undefined" && val !== null)) {
      return (tok[1] = val);
    }
    return tok[1];
  };
  // Tokenizers ==========================================================
  // Matches identifying literals: variables, keywords, method names, etc.
  lex.prototype.identifier_token = function identifier_token() {
    var id, match, tag;
    match = this.chunk.match(lex.IDENTIFIER);
    if (!(match && (id = match[1]))) {
      return false;
    }
    // Keywords are special identifiers tagged with their own name,
    // 'if' will result in an ['IF', "if"] token.
    tag = this.KEYWORDS.indexOf(id) >= 0 ? id.toUpperCase() : 'IDENTIFIER';
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
})();