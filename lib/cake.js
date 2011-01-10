(function() {
  var CoffeeScript, fs, helpers, missingTask, oparse, options, optparse, path, printTasks, switches, tasks, timeout, timeoutTask;
  fs = require('fs');
  path = require('path');
  helpers = require('./helpers');
  optparse = require('./optparse');
  CoffeeScript = require('./coffee-script');
  tasks = {};
  options = {};
  switches = [];
  oparse = null;
  timeout = 15000;
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
    invoke: function() {
      var finished, name, names, next, _i, _len;
      names = [];
      for (_i = 0, _len = arguments.length; _i < _len; _i++) {
        name = arguments[_i];
        if (typeof name === 'function') {
          finished = name;
        } else {
          if (!tasks[name]) {
            missingTask(name);
          }
          names.push(name);
        }
      }
      return (next = function() {
        var id, task;
        if (names.length) {
          name = names.shift();
          task = tasks[name].action;
          if (task.length < 2) {
            task(options);
            return setTimeout((function() {
              return next();
            }), 0);
          } else {
            id = setTimeout((function() {
              return timeoutTask(name);
            }), timeout);
            return task(options, function() {
              clearTimeout(id);
              return setTimeout((function() {
                return next();
              }), 0);
            });
          }
        } else {
          if (finished != null) {
            return finished();
          }
        }
      })();
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
      if (options.timeout != null) {
        timeout = parseInt(options.timeout);
      }
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
  timeoutTask = function(task) {
    console.log("Task timed out: \"" + task + "\"\nTry increasing default option `--timeout 15000` ms");
    return process.exit(1);
  };
}).call(this);
