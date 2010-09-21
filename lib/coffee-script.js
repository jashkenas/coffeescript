(function() {
  var Lexer, compile, fs, helpers, lexer, parser, path;
  if (typeof process !== "undefined" && process !== null) {
    path = require('path');
    Lexer = require('./lexer').Lexer;
    parser = require('./parser').parser;
    helpers = require('./helpers').helpers;
    if (require.extensions) {
      fs = require('fs');
      require.extensions['.coffee'] = function(module, filename) {
        var content;
        content = compile(fs.readFileSync(filename, 'utf8'));
        module.filename = ("" + (filename) + " (compiled)");
        return module._compile(content, module.filename);
      };
    } else if (require.registerExtension) {
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
    var __filename, root;
    root = module;
    while (root.parent) {
      root = root.parent;
    }
    root.filename = (__filename = ("" + (options.fileName) + " (compiled)"));
    if (root.moduleCache) {
      root.moduleCache = {};
    }
    return root._compile(exports.compile(code, options), root.filename);
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
  parser.yy = require('./nodes');
})();
