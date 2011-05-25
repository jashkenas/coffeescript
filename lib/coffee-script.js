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
    var Module, mainModule;
    mainModule = require.main;
    mainModule.filename = process.argv[1] = options.filename ? fs.realpathSync(options.filename) : '.';
    mainModule.moduleCache && (mainModule.moduleCache = {});
    if (process.binding('natives').module) {
      Module = require('module').Module;
      mainModule.paths = Module._nodeModulePaths(path.dirname(options.filename));
    }
    if (path.extname(mainModule.filename) !== '.coffee' || require.extensions) {
      return mainModule._compile(compile(code, options), mainModule.filename);
    } else {
      return mainModule._compile(code, mainModule.filename);
    }
  };
  exports.eval = function(code, options) {
    var g, js, k, o, sandbox, v, _i, _len, _ref2;
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
      _ref2 = Object.getOwnPropertyNames(global);
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        g = _ref2[_i];
        sandbox[g] = global[g];
      }
      sandbox.global = sandbox;
      sandbox.global.global = sandbox.global.root = sandbox.global.GLOBAL = sandbox;
    }
    sandbox.__filename = options.filename || 'eval';
    sandbox.__dirname = path.dirname(sandbox.__filename);
    o = {};
    for (k in options) {
      v = options[k];
      o[k] = v;
    }
    o.bare = true;
    js = compile("_=(" + (code.trim()) + ")", o);
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
