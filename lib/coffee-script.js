(function(){
  var lexer, parser, path;
  // Set up for both the browser and the server.
  if ((typeof process !== "undefined" && process !== null)) {
    process.mixin(require('nodes'));
    path = require('path');
    lexer = new (require('lexer').Lexer)();
    parser = require('parser').parser;
  } else {
    lexer = new Lexer();
    parser = exports.parser;
    this.exports = (this.CoffeeScript = {});
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
  exports.VERSION = '0.5.1';
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
})();
