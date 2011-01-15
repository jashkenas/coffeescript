(function() {
  var ACCESSOR, CoffeeScript, SIMPLEVAR, Script, autocomplete, backlog, completeAttribute, completeVariable, error, getCompletions, getPropertyNames, readline, repl, run, stdio;
  var __hasProp = Object.prototype.hasOwnProperty;
  CoffeeScript = require('./coffee-script');
  readline = require('readline');
  Script = process.binding('evals').Script;
  stdio = process.openStdin();
  error = function(err) {
    return stdio.write((err.stack || err.toString()) + '\n\n');
  };
  backlog = '';
  run = function(buffer) {
    var code, val;
    code = backlog += '\n' + buffer.toString();
    if (code[code.length - 1] === '\\') {
      return backlog = backlog.slice(0, backlog.length - 1);
    }
    backlog = '';
    try {
      val = CoffeeScript.eval(code, {
        bare: true,
        globals: true,
        filename: 'repl'
      });
      if (val !== void 0) {
        console.log(val);
      }
    } catch (err) {
      error(err);
    }
    return repl.prompt();
  };
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
  repl = readline.createInterface(stdio, autocomplete);
  repl.setPrompt('coffee> ');
  stdio.on('data', function(buffer) {
    return repl.write(buffer);
  });
  repl.on('close', function() {
    return stdio.destroy();
  });
  repl.on('line', run);
  repl.prompt();
}).call(this);
