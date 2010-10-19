(function() {
  var CoffeeScript, fs, helpers, missingTask, oparse, options, optparse, path, printTasks, switches, tasks;
  fs = require('fs');
  path = require('path');
  helpers = require('./helpers');
  optparse = require('./optparse');
  CoffeeScript = require('./coffee-script');
  tasks = {};
  options = {};
  switches = [];
  oparse = null;
  helpers.extend(global, {
    task: function(name, description, action) {
      var _ref;
      if (!action) {
        _ref = [description, action], action = _ref[0], description = _ref[1];
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
      if (!tasks[name]) {
        missingTask(name);
      }
      return tasks[name].action(options);
    }
  });
  exports.run = function() {
    return path.exists('Cakefile', function(exists) {
      var _i, _len, _ref, _result, arg, args;
      if (!exists) {
        throw new Error("Cakefile not found in " + (process.cwd()));
      }
      args = process.argv.slice(2);
      CoffeeScript.run(fs.readFileSync('Cakefile').toString(), {
        fileName: 'Cakefile'
      });
      oparse = new optparse.OptionParser(switches);
      if (!args.length) {
        return printTasks();
      }
      options = oparse.parse(args);
      _result = [];
      for (_i = 0, _len = (_ref = options.arguments).length; _i < _len; _i++) {
        arg = _ref[_i];
        _result.push(invoke(arg));
      }
      return _result;
    });
  };
  printTasks = function() {
    var _ref, desc, name, spaces, task;
    puts('');
    for (name in _ref = tasks) {
      task = _ref[name];
      spaces = 20 - name.length;
      spaces = spaces > 0 ? Array(spaces + 1).join(' ') : '';
      desc = task.description ? ("# " + (task.description)) : '';
      puts("cake " + name + spaces + " " + desc);
    }
    return switches.length ? puts(oparse.help()) : undefined;
  };
  missingTask = function(task) {
    puts("No such task: \"" + task + "\"");
    return process.exit(1);
  };
}).call(this);
