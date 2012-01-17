(function() {
  var Lexer, Location, RESERVED, compile, fs, getNode, hackTrace, lexer, makeStackTracesMonkeypatchable, parser, path, vm, _ref,
    __hasProp = Object.prototype.hasOwnProperty;

  fs = require('fs');

  path = require('path');

  _ref = require('./lexer'), Lexer = _ref.Lexer, RESERVED = _ref.RESERVED;

  Location = require('./nodes').Location;

  parser = require('./parser').parser;

  vm = require('vm');

  if (require.extensions) {
    require.extensions['.coffee'] = function(module, filename) {
      var content;
      Location.setCurrentFile(filename);
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

  exports.VERSION = '1.2.1-pre';

  exports.RESERVED = RESERVED;

  exports.helpers = require('./helpers');

  exports.compile = compile = function(code, options) {
    var merge;
    if (options == null) options = {};
    merge = exports.helpers.merge;
    try {
      return (parser.parse(lexer.tokenize(code))).compile(merge({}, options));
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
    var jscode, mainModule, _prepareStackTrace;
    mainModule = require.main;
    mainModule.filename = process.argv[1] = options.filename ? fs.realpathSync(options.filename) : '.';
    mainModule.moduleCache && (mainModule.moduleCache = {});
    mainModule.paths = require('module')._nodeModulePaths(path.dirname(options.filename));
    if (path.extname(mainModule.filename) !== '.coffee' || require.extensions) {
      jscode = compile(code, options);
      if (!(Error.prepareStackTrace != null)) makeStackTracesMonkeypatchable();
      _prepareStackTrace = Error.prepareStackTrace;
      Error.prepareStackTrace = function(error, structuredStackTrace) {
        var plainStack;
        plainStack = _prepareStackTrace(error, structuredStackTrace);
        return hackTrace(plainStack, jscode, mainModule.filename);
      };
      return mainModule._compile(jscode, mainModule.filename);
    } else {
      return mainModule._compile(code, mainModule.filename);
    }
  };

  exports.eval = function(code, options) {
    var Module, Script, js, k, o, r, sandbox, v, _i, _len, _module, _ref2, _ref3, _require;
    if (options == null) options = {};
    if (!(code = code.trim())) return;
    Script = vm.Script;
    if (Script) {
      if (options.sandbox != null) {
        if (options.sandbox instanceof Script.createContext().constructor) {
          sandbox = options.sandbox;
        } else {
          sandbox = Script.createContext();
          _ref2 = options.sandbox;
          for (k in _ref2) {
            if (!__hasProp.call(_ref2, k)) continue;
            v = _ref2[k];
            sandbox[k] = v;
          }
        }
        sandbox.global = sandbox.root = sandbox.GLOBAL = sandbox;
      } else {
        sandbox = global;
      }
      sandbox.__filename = options.filename || 'eval';
      sandbox.__dirname = path.dirname(sandbox.__filename);
      if (!(sandbox !== global || sandbox.module || sandbox.require)) {
        Module = require('module');
        sandbox.module = _module = new Module(options.modulename || 'eval');
        sandbox.require = _require = function(path) {
          return Module._load(path, _module, true);
        };
        _module.filename = sandbox.__filename;
        _ref3 = Object.getOwnPropertyNames(require);
        for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
          r = _ref3[_i];
          if (r !== 'paths') _require[r] = require[r];
        }
        _require.paths = _module.paths = Module._nodeModulePaths(process.cwd());
        _require.resolve = function(request) {
          return Module._resolveFilename(request, _module);
        };
      }
    }
    o = {};
    for (k in options) {
      if (!__hasProp.call(options, k)) continue;
      v = options[k];
      o[k] = v;
    }
    o.bare = true;
    js = compile(code, o);
    if (sandbox === global) {
      return vm.runInThisContext(js);
    } else {
      return vm.runInContext(js, sandbox);
    }
  };

  getNode = function(js, i) {
    var j;
    j = i;
    while (j > 0 && !(js.sources[j] != null)) {
      j--;
    }
    return js.sources[j];
  };

  hackTrace = function(stack, js, filename) {
    var col, end, firstnl, i, index, jscopy, length, lno, location, node, postfix, prefix, trace, traces, _i, _len, _ref2;
    traces = stack.split('\n');
    if (!(traces.length > 1)) return traces.join('\n');
    for (i = _i = 0, _len = traces.length; _i < _len; i = ++_i) {
      trace = traces[i];
      if (0 > (index = trace.indexOf("(" + filename + ":"))) continue;
      _ref2 = /^(.*):(\d+):(\d+)\)$/.exec(trace), prefix = _ref2[1], lno = _ref2[2], col = _ref2[3], postfix = _ref2[4];
      lno = +lno - 1;
      col = +col - 1;
      if (!((lno != null) && (col != null))) continue;
      length = ('' + (end = lno + 4)).length;
      jscopy = js.toString();
      while (lno > 0) {
        lno--;
        firstnl = jscopy.indexOf('\n');
        col += firstnl + 1;
        jscopy = jscopy.slice(firstnl + 1);
      }
      node = getNode(js, col);
      if (!((location = node != null ? node.location : void 0) != null)) continue;
      traces[i] = "" + prefix + " js:" + (lno + 1) + ":" + (col + 1) + " coffee:" + (location.firstLine + 1) + ":" + (location.firstColumn != null ? location.firstColumn + 1 : '?') + ")";
    }
    return traces.join('\n');
  };

  makeStackTracesMonkeypatchable = function() {
    return Error.prepareStackTrace = FormatStackTrace;
  };

  lexer = new Lexer;

  parser.lexer = {
    lex: function() {
      var tag, _ref2;
      _ref2 = this.tokens[this.pos++] || [''], tag = _ref2[0], this.yytext = _ref2[1], this.yylineno = _ref2[2], this.yycolumn = _ref2[3];
      this.yylloc.first_line = this.yylineno;
      this.yylloc.last_line = this.yylineno;
      this.yylloc.first_column = this.yycolumn;
      this.yylloc.last_column = this.yycolumn;
      return tag;
    },
    setInput: function(tokens) {
      this.tokens = tokens;
      return this.pos = 0;
    },
    upcomingInput: function() {
      return "";
    },
    yylloc: {
      first_line: 0,
      first_col: 0,
      last_line: 0,
      last_col: 0
    }
  };

  parser.yy = require('./nodes');

  
// from v8/src/messages.js
// The following applies to the rest of this file:
// Copyright 2011 the V8 project authors. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

function FormatSourcePosition(frame) {
  var fileName;
  var fileLocation = "";
  if (frame.isNative()) {
    fileLocation = "native";
  } else if (frame.isEval()) {
    fileName = frame.getScriptNameOrSourceURL();
    if (!fileName)
      fileLocation = frame.getEvalOrigin();
  } else {
    fileName = frame.getFileName();
  }

  if (fileName) {
    fileLocation += fileName;
    var lineNumber = frame.getLineNumber();
    if (lineNumber != null) {
      fileLocation += ":" + lineNumber;
      var columnNumber = frame.getColumnNumber();
      if (columnNumber) {
        fileLocation += ":" + columnNumber;
      }
    }
  }

  if (!fileLocation) {
    fileLocation = "unknown source";
  }
  var line = "";
  var functionName = frame.getFunction().name;
  var addPrefix = true;
  var isConstructor = frame.isConstructor();
  var isMethodCall = !(frame.isToplevel() || isConstructor);
  if (isMethodCall) {
    var methodName = frame.getMethodName();
    line += frame.getTypeName() + ".";
    if (functionName) {
      line += functionName;
      if (methodName && (methodName != functionName)) {
        line += " [as " + methodName + "]";
      }
    } else {
      line += methodName || "<anonymous>";
    }
  } else if (isConstructor) {
    line += "new " + (functionName || "<anonymous>");
  } else if (functionName) {
    line += functionName;
  } else {
    line += fileLocation;
    addPrefix = false;
  }
  if (addPrefix) {
    line += " (" + fileLocation + ")";
  }
  return line;
}

function FormatStackTrace(error, frames) {
  var lines = [];
  try {
    lines.push(error.toString());
  } catch (e) {
    try {
      lines.push("<error: " + e + ">");
    } catch (ee) {
      lines.push("<error>");
    }
  }
  for (var i = 0; i < frames.length; i++) {
    var frame = frames[i];
    var line;
    try {
      line = FormatSourcePosition(frame);
    } catch (e) {
      try {
        line = "<error: " + e + ">";
      } catch (ee) {
        // Any code that reaches this point is seriously nasty!
        line = "<error>";
      }
    }
    lines.push("    at " + line);
  }
  return lines.join("\n");
};


}).call(this);
