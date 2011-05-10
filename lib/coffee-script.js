(function() {
  var Lexer, RESERVED, compile, fs, lexer, parser, path, vm, _ref;
  fs = require('fs');
  path = require('path');
  vm = require('vm');
  _ref = require('./lexer'), Lexer = _ref.Lexer, RESERVED = _ref.RESERVED;
  parser = require('./parser').parser;
  if (require.extensions) {
    require.extensions['.coffee'] = function(module, filename) {
      var content;
      content = compile(fs.readFileSync(filename, 'utf8'), {
        filename: filename
      });
      return module._compile(content, filename);
    };
  } else if (require.registerExtension) {
    require.registerExtension('.coffee', function(content) {
      return compile(content);
    });
  }
  exports.VERSION = '1.1.1';
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
    var Module, root;
    root = module;
    while (root.parent) {
      root = root.parent;
    }
    root.filename = process.argv[1] = options.filename ? fs.realpathSync(options.filename) : '.';
    if (root.moduleCache) {
      root.moduleCache = {};
    }
    if (process.binding('natives').module) {
      Module = require('module').Module;
      root.paths = Module._nodeModulePaths(path.dirname(options.filename));
    }
    if (path.extname(root.filename) !== '.coffee' || require.extensions) {
      return root._compile(compile(code, options), root.filename);
    } else {
      return root._compile(code, root.filename);
    }
  };
  exports.eval = function(code, options) {
    var g, js, sandbox;
    if (options == null) {
      options = {};
    }
    sandbox = options.sandbox;
    if (!sandbox) {
      sandbox = {
        require: require,
        module: {
          exports: {}
        }
      };
      for (g in global) {
        sandbox[g] = global[g];
      }
      sandbox.global = sandbox;
      sandbox.global.global = sandbox.global.root = sandbox.global.GLOBAL = sandbox;
    }
    sandbox.__filename = options.filename || 'eval';
    sandbox.__dirname = path.dirname(sandbox.__filename);
    js = compile("_=(" + (code.trim()) + ")", options);
    return vm.runInNewContext(js, sandbox, sandbox.__filename);
  };
  lexer = new Lexer;
  parser.lexer = {
    lex: function() {
      var tag, _ref2;
      _ref2 = this.tokens[this.pos++] || [''], tag = _ref2[0], this.yytext = _ref2[1], this.yylineno = _ref2[2];
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
