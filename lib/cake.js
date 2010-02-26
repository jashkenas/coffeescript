(function(){
  var coffee, fs, no_such_task, oparse, options, optparse, path, print_tasks, switches, tasks;
  var __hasProp = Object.prototype.hasOwnProperty;
  // `cake` is a simplified version of Make (Rake, Jake) for CoffeeScript.
  // You define tasks with names and descriptions in a Cakefile, and can call them
  // from the command line, or invoke them from other tasks.
  fs = require('fs');
  path = require('path');
  coffee = require('coffee-script');
  optparse = require('optparse');
  tasks = {};
  options = {};
  switches = [];
  oparse = null;
  // Mixin the top-level Cake functions for Cakefiles to use.
  process.mixin({
    // Define a task with a name, a description, and the action itself.
    task: function task(name, description, action) {
      return tasks[name] = {
        name: name,
        description: description,
        action: action
      };
    },
    // Define an option that the Cakefile accepts.
    option: function option(letter, flag, description) {
      return switches.push([letter, flag, description]);
    },
    // Invoke another task in the Cakefile.
    invoke: function invoke(name) {
      if (!(tasks[name])) {
        no_such_task(name);
      }
      return tasks[name].action(options);
    }
  });
  // Running `cake` runs the tasks you pass asynchronously (node-style), or
  // prints them out, with no arguments.
  exports.run = function run() {
    return path.exists('Cakefile', function(exists) {
      var _a, _b, _c, _d, arg, args;
      if (!(exists)) {
        throw new Error('Cakefile not found in ' + process.cwd());
      }
      args = process.ARGV.slice(2, process.ARGV.length);
      eval(coffee.compile(fs.readFileSync('Cakefile')));
      oparse = new optparse.OptionParser(switches);
      if (!(args.length)) {
        return print_tasks();
      }
      options = oparse.parse(args);
      _a = []; _b = options.arguments;
      for (_c = 0, _d = _b.length; _c < _d; _c++) {
        arg = _b[_c];
        _a.push(invoke(arg));
      }
      return _a;
    });
  };
  // Display the list of Cake tasks.
  print_tasks = function print_tasks() {
    var _a, _b, _c, _d, _e, _f, i, name, spaces, task;
    puts('');
    _a = tasks;
    for (name in _a) { if (__hasProp.call(_a, name)) {
      task = _a[name];
      spaces = 20 - name.length;
      spaces = spaces > 0 ? (function() {
        _b = []; _e = 0; _f = spaces;
        for (_d = 0, i = _e; (_e <= _f ? i <= _f : i >= _f); (_e <= _f ? i += 1 : i -= 1), _d++) {
          _b.push(' ');
        }
        return _b;
      }).call(this).join('') : '';
      puts("cake " + name + spaces + ' # ' + task.description);
    }}
    if (switches.length) {
      return puts('\n' + oparse.help() + '\n');
    }
  };
  // Print an error and exit when attempting to all an undefined task.
  no_such_task = function no_such_task(task) {
    process.stdio.writeError('No such task: "' + task + '"\n');
    return process.exit(1);
  };
})();
