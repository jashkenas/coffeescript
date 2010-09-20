(function() {
  var CoffeeScript, fs, helpers, missingTask, oparse, options, optparse, path, printTasks, switches, tasks;
  fs = require('fs');
  path = require('path');
  helpers = require('./helpers').helpers;
  optparse = require('./optparse');
  CoffeeScript = require('./coffee-script');
  tasks = {};
  options = {};
  switches = [];
  oparse = null;
  helpers.extend(global, {
    task: function(name, description, action) {
      var _cache;
      if (!(action)) {
        _cache = [description, action];
        action = _cache[0];
        description = _cache[1];
      }
      return (tasks[name] = {
        name: name,
        description: description,
        action: action
      });
    },
    option: function(letter, flag, description) {
      return switches.push([letter, flag, description]);
    },
    invoke: function(name) {
      if (!(tasks[name])) {
        missingTask(name);
      }
      return tasks[name].action(options);
    }
  });
  exports.run = function() {
    return path.exists('Cakefile', function(exists) {
      var _cache, _index, _length, _result, arg, args;
      if (!(exists)) {
        throw new Error("Cakefile not found in " + (process.cwd()));
      }
      args = process.argv.slice(2, process.argv.length);
      CoffeeScript.run(fs.readFileSync('Cakefile').toString(), {
        fileName: 'Cakefile'
      });
      oparse = new optparse.OptionParser(switches);
      if (!(args.length)) {
        return printTasks();
      }
      options = oparse.parse(args);
      _result = []; _cache = options.arguments;
      for (_index = 0, _length = _cache.length; _index < _length; _index++) {
        arg = _cache[_index];
        _result.push(invoke(arg));
      }
      return _result;
    });
  };
  printTasks = function() {
    var _cache, _result, desc, i, name, spaces, task;
    puts('');
    _cache = tasks;
    for (name in _cache) {
      task = _cache[name];
      spaces = 20 - name.length;
      spaces = spaces > 0 ? (function() {
        _result = [];
        for (i = 0; (0 <= spaces ? i <= spaces : i >= spaces); (0 <= spaces ? i += 1 : i -= 1)) {
          _result.push(' ');
        }
        return _result;
      })().join('') : '';
      desc = task.description ? ("# " + (task.description)) : '';
      puts("cake " + (name) + (spaces) + " " + (desc));
    }
    if (switches.length) {
      return puts(oparse.help());
    }
  };
  missingTask = function(task) {
    puts("No such task: \"" + (task) + "\"");
    return process.exit(1);
  };
})();
