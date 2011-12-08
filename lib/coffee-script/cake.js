(function() {
  var CoffeeScript, atasks, cakefileDirectory, fs, helpers, missingTask, oparse, options, optparse, path, printTasks, switches, tame, tasks;
  var __slice = Array.prototype.slice;

  tame = {
    Deferrals: (function() {

      function _Class(_arg) {
        this.continuation = _arg;
        this.count = 1;
      }

      _Class.prototype._fulfill = function() {
        if (!--this.count) return this.continuation();
      };

      _Class.prototype.defer = function(defer_params) {
        var _this = this;
        ++this.count;
        return function() {
          var inner_params, _ref;
          inner_params = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          if (defer_params != null) {
            if ((_ref = defer_params.assign_fn) != null) {
              _ref.apply(null, inner_params);
            }
          }
          return _this._fulfill();
        };
      };

      return _Class;

    })()
  };

   tame = {
    Deferrals: (function() {

      function _Class(_arg) {
        this.continuation = _arg;
        this.count = 1;
      }

      _Class.prototype._fulfill = function() {
        if (!--this.count) return this.continuation();
      };

      _Class.prototype.defer = function(defer_params) {
        var _this = this;
        ++this.count;
        return function() {
          var inner_params, _ref;
          inner_params = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          if (defer_params != null) {
            if ((_ref = defer_params.assign_fn) != null) {
              _ref.apply(null, inner_params);
            }
          }
          return _this._fulfill();
        };
      };

      return _Class;

    })()

    }; ;

  fs = require('fs');

  path = require('path');

  helpers = require('./helpers');

  optparse = require('./optparse');

  CoffeeScript = require('./coffee-script');

  tasks = {};

  atasks = {};

  options = {};

  switches = [];

  oparse = null;

  helpers.extend(global, {
    task: function(name, description, action, async) {
      var _ref;
      if (!action) {
        _ref = [description, action], action = _ref[0], description = _ref[1];
      }
      return tasks[name] = {
        name: name,
        description: description,
        action: action,
        async: async
      };
    },
    atask: function(name, description, action) {
      return task(name, description, action, true);
    },
    option: function(letter, flag, description) {
      return switches.push([letter, flag, description]);
    },
    invoke: function(name, cb) { /* TAMED */ 
      var t;
      if (!(t = tasks[name])) missingTask(name);
      (function(__tame_k) {
        if (t.async) {
          (function(__tame_k) {
            var __tame_deferrals;
              __tame_deferrals = new tame.Deferrals(__tame_k);
              t.action(options, __tame_deferrals.defer({
                assign_fn: (function() {
                  return function() {};
                })()
              }));
              __tame_deferrals._fulfill();
          })(function() {
            return __tame_k();
          });
        } else {
          t.action(options);
          return __tame_k();
        }
      })(function() {
        return cb();
      });
    }
  });

  exports.run = function(cb) { /* TAMED */ 
    var arg, args, __tame_k, _i, _len, _ref, _results, _while;
    global.__originalDirname = fs.realpathSync('.');
    process.chdir(cakefileDirectory(__originalDirname));
    args = process.argv.slice(2);
    CoffeeScript.run(fs.readFileSync('Cakefile').toString(), {
      filename: 'Cakefile'
    });
    oparse = new optparse.OptionParser(switches);
    if (!args.length) return printTasks();
    options = oparse.parse(args);
    __tame_k = function() {};
    _ref = options.arguments;
    _len = _ref.length;
    _i = 0;
    _while = function(__tame_k) {
      var _break, _continue;
      _break = __tame_k;
      _continue = function() {
        ++_i;
        return _while(__tame_k);
      };
      if (_i < _len) {
        arg = _ref[_i];
        (function(__tame_k) {
          var __tame_deferrals;
            __tame_deferrals = new tame.Deferrals(__tame_k);
            invoke(arg, __tame_deferrals.defer({
              assign_fn: (function() {
                return function() {};
              })()
            }));
            __tame_deferrals._fulfill();
        })(function() {
          return _continue();
        });
      } else {
        return _break();
      }
    };
    _while(__tame_k);
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
    if (switches.length) return console.log(oparse.help());
  };

  missingTask = function(task) {
    console.log("No such task: \"" + task + "\"");
    return process.exit(1);
  };

  cakefileDirectory = function(dir) {
    var parent;
    if (path.existsSync(path.join(dir, 'Cakefile'))) return dir;
    parent = path.normalize(path.join(dir, '..'));
    if (parent !== dir) return cakefileDirectory(parent);
    throw new Error("Cakefile not found in " + (process.cwd()));
  };

}).call(this);
