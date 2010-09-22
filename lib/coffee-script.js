(function() {
  var Lexer, _ref, compile, fs, lexer, parser, path;
  path = require('path');
  _ref = require('./lexer');
  Lexer = _ref.Lexer;
  _ref = require('./parser');
  parser = _ref.parser;
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
    var root;
    root = module;
    while (root.parent) {
      root = root.parent;
    }
    root.filename = options.fileName;
    if (root.moduleCache) {
      root.moduleCache = {};
    }
    return root._compile(exports.compile(code, options), root.filename);
  };
  exports.eval = function(code, options) {
    var __dirname, __filename;
    __filename = options.fileName;
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
  parser.yy = require('./nodes');
}).call(this);
