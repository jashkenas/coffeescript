(function(){
  var lexer, parser, path;
  // Set up for both the browser and the server.
  if ((typeof process !== "undefined" && process !== null)) {
    process.mixin(require('nodes'));
    path = require('path');
    lexer = new (require('lexer').Lexer)();
    parser = require('parser').parser;
  } else {
    this.exports = this;
    lexer = new Lexer();
    parser = exports.parser;
  }
  // Thin wrapper for Jison compatibility around the real lexer.
  parser.lexer = {
    lex: function lex() {
      var token;
      token = this.tokens[this.pos] || [""];
      this.pos += 1;
      this.yylineno = token[2];
      this.yytext = token[1];
      return token[0];
    },
    setInput: function setInput(tokens) {
      this.tokens = tokens;
      return this.pos = 0;
    },
    upcomingInput: function upcomingInput() {
      return "";
    },
    showPosition: function showPosition() {
      return this.pos;
    }
  };
  // Improved error messages.
  // parser.parseError: (message, hash) ->
  //   throw new Error 'Unexpected ' + parser.terminals_[hash.token] + ' on line ' + hash.line
  exports.VERSION = '0.5.0';
  // Compile CoffeeScript to JavaScript, using the Coffee/Jison compiler.
  exports.compile = function compile(code, options) {
    return (parser.parse(lexer.tokenize(code))).compile(options);
  };
  // Just the tokens.
  exports.tokenize = function tokenize(code) {
    return lexer.tokenize(code);
  };
  // Just the nodes.
  exports.tree = function tree(code) {
    return parser.parse(lexer.tokenize(code));
  };
  // Pretty-print a token stream.
  exports.print_tokens = function print_tokens(tokens) {
    var _a, _b, _c, strings, token;
    strings = (function() {
      _a = []; _b = tokens;
      for (_c = 0; _c < _b.length; _c++) {
        token = _b[_c];
        _a.push('[' + token[0] + ' ' + token[1].toString().replace(/\n/, '\\n') + ']');
      }
      return _a;
    }).call(this);
    return puts(strings.join(' '));
  };
})();