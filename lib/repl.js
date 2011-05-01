(function() {
  var ACCESSOR, CoffeeScript, SIMPLEVAR, Script, autocomplete, backlog, completeAttribute, completeVariable, enableColours, error, getCompletions, getPropertyNames, inspect, readline, repl, run, stdin, stdout;
  var __hasProp = Object.prototype.hasOwnProperty;
  CoffeeScript = require('./coffee-script');
  readline = require('readline');
  inspect = require('util').inspect;
  Script = require('vm').Script;
  enableColours = false;
  if (process.platform !== 'win32') {
    enableColours = !process.env.NODE_DISABLE_COLORS;
  }
  stdin = process.openStdin();
  stdout = process.stdout;
  error = function(err) {
    return stdout.write((err.stack || err.toString()) + '\n\n');
  };
  backlog = '';
  run = (function() {
    var g, sandbox;
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
    return function(buffer) {
      var code, val;
      code = backlog += '\n' + buffer.toString();
      if (code[code.length - 1] === '\\') {
        return backlog = backlog.slice(0, backlog.length - 1);
      }
      backlog = '';
      try {
        val = CoffeeScript.eval(code, {
          sandbox: sandbox,
          bare: true,
          filename: 'repl'
        });
        if (val !== void 0) {
          process.stdout.write(inspect(val, false, 2, enableColours) + '\n');
        }
      } catch (err) {
        error(err);
      }
      return repl.prompt();
    };
  })();
  ACCESSOR = /\s*([\w\.]+)(?:\.(\w*))$/;
  SIMPLEVAR = /\s*(\w*)$/i;
  autocomplete = function(text) {
    return completeAttribute(text) || completeVariable(text) || [[], text];
  };
  completeAttribute = function(text) {
    var all, completions, match, obj, prefix, val;
    if (match = text.match(ACCESSOR)) {
      all = match[0], obj = match[1], prefix = match[2];
      try {
        val = Script.runInThisContext(obj);
      } catch (error) {
        return [[], text];
      }
      completions = getCompletions(prefix, getPropertyNames(val));
      return [completions, prefix];
    }
  };
  completeVariable = function(text) {
    var completions, free, scope, _ref;
    if (free = (_ref = text.match(SIMPLEVAR)) != null ? _ref[1] : void 0) {
      scope = Script.runInThisContext('this');
      completions = getCompletions(free, CoffeeScript.RESERVED.concat(getPropertyNames(scope)));
      return [completions, free];
    }
  };
  getCompletions = function(prefix, candidates) {
    var el, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = candidates.length; _i < _len; _i++) {
      el = candidates[_i];
      if (el.indexOf(prefix) === 0) {
        _results.push(el);
      }
    }
    return _results;
  };
  getPropertyNames = function(obj) {
    var name, _results;
    _results = [];
    for (name in obj) {
      if (!__hasProp.call(obj, name)) continue;
      _results.push(name);
    }
    return _results;
  };
  process.on('uncaughtException', error);
  if (readline.createInterface.length < 3) {
    repl = readline.createInterface(stdin, autocomplete);
    stdin.on('data', function(buffer) {
      return repl.write(buffer);
    });
  } else {
    repl = readline.createInterface(stdin, stdout, autocomplete);
  }
  repl.setPrompt('coffee> ');
  repl.on('close', function() {
    return stdin.destroy();
  });
  repl.on('line', run);
  repl.prompt();
}).call(this);
