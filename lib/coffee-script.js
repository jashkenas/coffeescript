(function() {
  var Lexer, compile, helpers, lexer, parser, path;
  if (typeof process !== "undefined" && process !== null) {
    path = require('path');
    Lexer = require('./lexer').Lexer;
    parser = require('./parser').parser;
    helpers = require('./helpers').helpers;
    helpers.extend(global, require('./nodes'));
    if (require.registerExtension) {
      require.registerExtension('.coffee', function(content) {
        return compile(content);
      });
    }
  } else {
    this.exports = (this.CoffeeScript = {});
    Lexer = this.Lexer;
    parser = this.parser;
    helpers = this.helpers;
  }
  exports.VERSION = '0.9.3';
  exports.compile = (compile = function(code, options) {
    options || (options = {});
    try {
      return (parser.parse(lexer.tokenize(code))).compile(options);
    } catch (err) {
      if (options.fileName) {
        err.message = ("In " + (options.fileName) + ", " + (err.message));
      }
      throw err;
    }
  });
  exports.tokens = function(code) {
    return lexer.tokenize(code);
  };
  exports.nodes = function(code) {
    return parser.parse(lexer.tokenize(code));
  };
  exports.run = function(code, options) {
    var __dirname, __filename;
    module.filename = (__filename = options.fileName);
    __dirname = path.dirname(__filename);
    return eval(exports.compile(code, options));
  };
  lexer = new Lexer();
  parser.lexer = {
    lex: function() {
      var token;
      token = this.tokens[this.pos] || [""];
      this.pos += 1;
      this.yylineno = token[2];
      this.yytext = token[1];
      return token[0];
    },
    setInput: function(tokens) {
      this.tokens = tokens;
      return (this.pos = 0);
    },
    upcomingInput: function() {
      return "";
    }
  };
})();
