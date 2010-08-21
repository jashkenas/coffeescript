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
      var _a;
      if (!(action)) {
        _a = [description, action];
        action = _a[0];
        description = _a[1];
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
      var _a, _b, _c, _d, arg, args;
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
      _a = []; _c = options.arguments;
      for (_b = 0, _d = _c.length; _b < _d; _b++) {
        arg = _c[_b];
        _a.push(invoke(arg));
      }
      return _a;
    });
  };
  printTasks = function() {
    var _a, _b, desc, i, name, spaces, task;
    puts('');
    _a = tasks;
    for (name in _a) {
      task = _a[name];
      spaces = 20 - name.length;
      spaces = spaces > 0 ? (function() {
        _b = [];
        for (i = 0; (0 <= spaces ? i <= spaces : i >= spaces); (0 <= spaces ? i += 1 : i -= 1)) {
          _b.push(' ');
        }
        return _b;
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
