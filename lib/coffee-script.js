(function() {
  var Lexer, RESERVED, compile, fs, lexer, parser, path, _ref;
  fs = require('fs');
  path = require('path');
  _ref = require('./lexer'), Lexer = _ref.Lexer, RESERVED = _ref.RESERVED;
  parser = require('./parser').parser;
  if (require.extensions) {
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
  exports.VERSION = '1.0.1';
  exports.RESERVED = RESERVED;
  exports.helpers = require('./helpers');
  exports.compile = compile = function(code, options) {
    if (options == null) {
      options = {};
    }
    try {
      return (parser.parse(lexer.tokenize(code))).compile(options);
    } catch (err) {
      if (options.filename) {
        err.message = "In " + options.filename + ", " + err.message;
      }
      throw err;
    }
  };
  exports.tokens = function(code, options) {
    return lexer.tokenize(code, options);
  };
  exports.nodes = function(source, options) {
    if (typeof source === 'string') {
      return parser.parse(lexer.tokenize(source, options));
    } else {
      return parser.parse(source);
    }
  };
  exports.run = function(code, options) {
    var root;
    root = module;
    while (root.parent) {
      root = root.parent;
    }
    root.filename = options.filename ? fs.realpathSync(options.filename) : '.';
    if (root.moduleCache) {
      root.moduleCache = {};
    }
    if (path.extname(root.filename) !== '.coffee' || require.extensions) {
      return root._compile(compile(code, options), root.filename);
    } else {
      return root._compile(code, root.filename);
    }
  };
  exports.eval = function(code, options) {
    var __dirname, __filename;
    __filename = module.filename = options.filename;
    __dirname = path.dirname(__filename);
    return eval(compile(code, options));
  };
  lexer = new Lexer;
  parser.lexer = {
    lex: function() {
      var tag, _ref;
      _ref = this.tokens[this.pos++] || [''], tag = _ref[0], this.yytext = _ref[1], this.yylineno = _ref[2];
      return tag;
    },
    setInput: function(tokens) {
      this.tokens = tokens;
      return this.pos = 0;
    },
    upcomingInput: function() {
      return "";
    }
  };
  parser.yy = require('./nodes');
}).call(this);
