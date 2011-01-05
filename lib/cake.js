(function() {
  var CoffeeScript, EE, fs, helpers, missingTask, oparse, options, optparse, path, printTasks, switches, tasks;
  var __slice = Array.prototype.slice;
  fs = require('fs');
  path = require('path');
  helpers = require('./helpers');
  optparse = require('./optparse');
  CoffeeScript = require('./coffee-script');
  EE = require('events').EventEmitter;
  tasks = {};
  options = {};
  switches = [];
  oparse = null;
  helpers.extend(global, new EE());
  helpers.extend(global, {
    task: function(name, description, action) {
      var _ref;
      if (!action) {
        _ref = [description, action], action = _ref[0], description = _ref[1];
      }
      return tasks[name] = {
        name: name,
        description: description,
        action: action
      };
    },
    option: function(letter, flag, description) {
      return switches.push([letter, flag, description]);
    },
    invoke: function(name) {
      var result;
      if (!tasks[name]) {
        missingTask(name);
      }
      result = tasks[name].action(options);
      emit(name);
      return result;
    },
    dependsOn: function() {
      var action, dependables, _i;
      dependables = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), action = arguments[_i++];
      return function() {
        return (function(dependables, action) {
          var first, rest, thisFn;
          if (dependables.length === 0) {
            return action(options);
          }
          thisFn = arguments.callee;
          first = dependables[0], rest = 2 <= dependables.length ? __slice.call(dependables, 1) : [];
          addListener(first, function() {
            return thisFn(rest, action);
          });
          return invoke(first);
        })(dependables, action);
      };
    }
  });
  exports.run = function() {
    return path.exists('Cakefile', function(exists) {
      var arg, args, _i, _len, _ref, _results;
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
      _ref = options.arguments;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        arg = _ref[_i];
        _results.push(invoke(arg));
      }
      return _results;
    });
  };
  printTasks = function() {
    var desc, name, spaces, task;
    console.log('');
    for (name in tasks) {
      task = tasks[name];
      spaces = 20 - name.length;
      spaces = spaces > 0 ? Array(spaces + 1).join(' ') : '';
      desc = task.description ? "# " + task.description : '';
      console.log("cake " + name + spaces + " " + desc);
    }
    if (switches.length) {
      return console.log(oparse.help());
    }
  };
  missingTask = function(task) {
    console.log("No such task: \"" + task + "\"");
    return process.exit(1);
  };
}).call(this);
