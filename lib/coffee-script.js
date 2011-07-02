(function() {
  var DebugCSFile, DebugCSLine, Lexer, RESERVED, compile, debug, fs, lexer, parser, path, printLinenos, vm, _ref;
  fs = require('fs');
  path = require('path');
  vm = require('vm');
  _ref = require('./lexer'), Lexer = _ref.Lexer, RESERVED = _ref.RESERVED;
  parser = require('./parser').parser;
  printLinenos = require('./nodes').printLinenos;
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
    var Module, js, mainModule;
    mainModule = require.main;
    mainModule.filename = process.argv[1] = options.filename ? fs.realpathSync(options.filename) : '.';
    mainModule.moduleCache && (mainModule.moduleCache = {});
    if (process.binding('natives').module) {
      Module = require('module').Module;
      mainModule.paths = Module._nodeModulePaths(path.dirname(options.filename));
    }
    if (path.extname(mainModule.filename) !== '.coffee' || require.extensions) {
      js = compile(code, options);
    } else {
      js = code;
    }
    try {
      mainModule._compile(js, mainModule.filename);
    } catch (err) {
      if (options.debug) {
        err.debug = debug(code, err.stack.split('\n'), options, js);
      }
      err.stack = err.stack.replace(/\.coffee\:/g, '.js:');
      throw err;
    }
    return true;
  };
  debug = function(code, stack, options, ojs) {
    var all, comment, csfile, cslineno, csmsg, errline, errlinenos, file, inEval, js, jsline, jslines, jsmsg, lineno, match, msg, ojsline, stackline, _i, _j, _len, _len2, _ref2, _ref3;
    msg = "\n  " + stack[0] + "\n\n";
    printLinenos();
    js = compile(code, options);
    jslines = js.split('\n');
    csfile = new DebugCSFile(code);
    for (_i = 0, _len = stack.length; _i < _len; _i++) {
      stackline = stack[_i];
      if (stackline.indexOf('.coffee') > -1) {
        break;
      }
    }
    inEval = stack[1].match(/\(\.\:(\d*)\:\d*\)/);
    if (inEval) {
      stackline = "/__commandline__.coffee:" + inEval[1] + ":1";
    }
    _ref2 = stackline.match(/\/([A-Za-z0-9_\ \$\-\_\.]*\.(?:coffee|js))\:(\d*)\:\d/), match = _ref2[0], file = _ref2[1], lineno = _ref2[2];
    lineno = parseInt(lineno);
    ojsline = ojs.split('\n')[lineno - 1];
    jsmsg = "in " + (file.replace(/.coffee/, '.js')) + " on line " + lineno + "\n";
    msg += "  " + jsmsg + "  " + (new Array(jsmsg.length).join('-')) + "\n";
    msg += "  > " + lineno + " | " + ojsline + "\n\n";
    jsline = jslines[options.bare ? lineno - 2 : lineno - 3];
    errlinenos = jsline.match(/.*?\/\*\@line\:\ \d*\*\//g);
    for (_j = 0, _len2 = errlinenos.length; _j < _len2; _j++) {
      errline = errlinenos[_j];
      _ref3 = errline.match(/(.*?)(\/\*\@line\:\ (\d*)\*\/)/), all = _ref3[0], code = _ref3[1], comment = _ref3[2], cslineno = _ref3[3];
      csfile.error(cslineno);
    }
    csmsg = "in " + file + " on line " + cslineno + "\n";
    msg += "  " + csmsg + "  " + (new Array(csmsg.length).join('-')) + "\n";
    return msg += csfile.print() + '\n';
  };
  DebugCSFile = (function() {
    function DebugCSFile(code) {
      this.cslines = code.split('\n');
      this.lines = {};
    }
    DebugCSFile.prototype.error = function(lineno) {
      lineno = parseInt(lineno);
      this.lines[lineno] = new DebugCSLine(lineno, this.cslines[lineno - 1], true);
      return this.contextualize(lineno);
    };
    DebugCSFile.prototype.contextualize = function(errlineno) {
      var lineno, _ref2, _ref3, _results;
      _results = [];
      for (lineno = _ref2 = errlineno - 3, _ref3 = errlineno + 3; _ref2 <= _ref3 ? lineno < _ref3 : lineno > _ref3; _ref2 <= _ref3 ? lineno++ : lineno--) {
        if ((0 < lineno && lineno < this.cslines.length - 1)) {
          _results.push(!this.lines[lineno] ? this.lines[lineno] = new DebugCSLine(lineno, this.cslines[lineno - 1], false) : void 0);
        }
      }
      return _results;
    };
    DebugCSFile.prototype.numlines = function() {
      var lineno, max;
      max = 0;
      for (lineno in this.lines) {
        max = Math.max(parseInt(lineno), max);
      }
      return max;
    };
    DebugCSFile.prototype.print = function() {
      var length, line, lineno, out, _ref2;
      out = [];
      length = String(this.numlines()).length;
      _ref2 = this.lines;
      for (lineno in _ref2) {
        line = _ref2[lineno];
        out.push(line.print(length));
      }
      return out.join('\n');
    };
    return DebugCSFile;
  })();
  DebugCSLine = (function() {
    function DebugCSLine(lineno, line, isError) {
      this.line = line;
      this.isError = isError;
      this.lineno = String(lineno);
    }
    DebugCSLine.prototype.print = function(length) {
      var spaces;
      spaces = new Array(Math.max(length + 2, 4)).join(' ').slice(this.lineno.length);
      if (this.isError) {
        spaces = spaces.slice(1);
      }
      return "" + spaces + (this.isError ? '>' : '') + " " + this.lineno + " | " + this.line;
    };
    return DebugCSLine;
  })();
  exports.eval = function(code, options) {
    var g, js, k, o, sandbox, v, _i, _len, _ref2;
    if (options == null) {
      options = {};
    }
    if (!(code = code.trim())) {
      return;
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
    js = compile("_=(" + code + "\n)", o);
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
