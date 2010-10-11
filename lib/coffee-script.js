(function() {
  var Lexer, compile, fs, lexer, parser, path;
  path = require('path');
  Lexer = require('./lexer').Lexer;
  parser = require('./parser').parser;
  if (require.extensions) {
    fs = require('fs');
    require.extensions['.coffee'] = function(module, filename) {
      var content;
      content = compile(fs.readFileSync(filename, 'utf8'));
      return module._compile(content, filename);
    };
  } else if (require.registerExtension) {
    require.registerExtension('.coffee', function(content) {
      return compile(content);
    });
  }
  exports.VERSION = '0.9.4';
  exports.helpers = require('./helpers');
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
  exports.tokens = function(code, options) {
    return lexer.tokenize(code, options);
  };
  exports.nodes = function(code, options) {
    return parser.parse(lexer.tokenize(code, options));
  };
  exports.run = function(code, options) {
    var root;
    root = module;
    while (root.parent) {
      root = root.parent;
    }
    root.filename = options.fileName;
    if (root.moduleCache) {
      root.moduleCache = {};
    }
    return path.extname(root.filename) !== '.coffee' || require.extensions ? root._compile(exports.compile(code, options), root.filename) : root._compile(code, root.filename);
  };
  exports.eval = function(code, options) {
    var __dirname, __filename;
    __filename = options.fileName;
    __dirname = path.dirname(__filename);
    return eval(exports.compile(code, options));
  };
  lexer = new Lexer;
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
}).call(this);
