(function() {
  var BANNER, CoffeeScript, EventEmitter, SWITCHES, _a, _b, _c, compileOptions, compileScript, compileScripts, compileStdio, exec, fs, helpers, lint, optionParser, optparse, opts, parseOptions, path, printTokens, sources, spawn, usage, version, watch, writeJs;
  fs = require('fs');
  path = require('path');
  optparse = require('./optparse');
  CoffeeScript = require('./coffee-script');
  _a = require('./helpers');
  helpers = _a.helpers;
  _b = require('child_process');
  spawn = _b.spawn;
  exec = _b.exec;
  _c = require('events');
  EventEmitter = _c.EventEmitter;
  helpers.extend(CoffeeScript, new EventEmitter());
  global.CoffeeScript = CoffeeScript;
  BANNER = 'coffee compiles CoffeeScript source files into JavaScript.\n\nUsage:\n  coffee path/to/script.coffee';
  SWITCHES = [['-c', '--compile', 'compile to JavaScript and save as .js files'], ['-i', '--interactive', 'run an interactive CoffeeScript REPL'], ['-o', '--output [DIR]', 'set the directory for compiled JavaScript'], ['-w', '--watch', 'watch scripts for changes, and recompile'], ['-p', '--print', 'print the compiled JavaScript to stdout'], ['-l', '--lint', 'pipe the compiled JavaScript through JSLint'], ['-s', '--stdio', 'listen for and compile scripts over stdio'], ['-e', '--eval', 'compile a string from the command line'], ['-r', '--require [FILE*]', 'require a library before executing your script'], ['--no-wrap', 'compile without the top-level function wrapper'], ['-t', '--tokens', 'print the tokens that the lexer produces'], ['-n', '--nodes', 'print the parse tree that Jison produces'], ['-v', '--version', 'display CoffeeScript version'], ['-h', '--help', 'display this help message']];
  opts = {};
  sources = [];
  optionParser = null;
  exports.run = function() {
    var flags, separator;
    parseOptions();
    if (opts.help) {
      return usage();
    }
    if (opts.version) {
      return version();
    }
    if (opts.interactive) {
      return require('./repl');
    }
    if (opts.stdio) {
      return compileStdio();
    }
    if (opts.eval) {
      return compileScript('console', sources[0]);
    }
    if (!(sources.length)) {
      return require('./repl');
    }
    separator = sources.indexOf('--');
    flags = [];
    if (separator >= 0) {
      flags = sources.slice((separator + 1), sources.length);
      sources = sources.slice(0, separator);
    }
    if (opts.run) {
      flags = sources.slice(1, sources.length + 1).concat(flags);
      sources = [sources[0]];
    }
    process.ARGV = (process.argv = flags);
    return compileScripts();
  };
  compileScripts = function() {
    var _d, _e, _f, _g;
    _d = []; _f = sources;
    for (_e = 0, _g = _f.length; _e < _g; _e++) {
      (function() {
        var base, compile;
        var source = _f[_e];
        return _d.push((function() {
          base = source;
          compile = function(source, topLevel) {
            return path.exists(source, function(exists) {
              if (!(exists)) {
                throw new Error("File not found: " + (source));
              }
              return fs.stat(source, function(err, stats) {
                if (stats.isDirectory()) {
                  return fs.readdir(source, function(err, files) {
                    var _h, _i, _j, _k, file;
                    _h = []; _j = files;
                    for (_i = 0, _k = _j.length; _i < _k; _i++) {
                      file = _j[_i];
                      _h.push(compile(path.join(source, file)));
                    }
                    return _h;
                  });
                } else if (topLevel || path.extname(source) === '.coffee') {
                  fs.readFile(source, function(err, code) {
                    return compileScript(source, code.toString(), base);
                  });
                  if (opts.watch) {
                    return watch(source, base);
                  }
                }
              });
            });
          };
          return compile(source, true);
        })());
      })();
    }
    return _d;
  };
  compileScript = function(file, input, base) {
    var _d, _e, _f, o, options, req, t, task;
    o = opts;
    options = compileOptions(file);
    if (o.require) {
      _e = o.require;
      for (_d = 0, _f = _e.length; _d < _f; _d++) {
        req = _e[_d];
        require(helpers.starts(req, '.') ? fs.realpathSync(req) : req);
      }
    }
    try {
      t = (task = {
        file: file,
        input: input,
        options: options
      });
      CoffeeScript.emit('compile', task);
      if (o.tokens) {
        return printTokens(CoffeeScript.tokens(t.input));
      } else if (o.nodes) {
        return puts(CoffeeScript.nodes(t.input).toString());
      } else if (o.run) {
        return CoffeeScript.run(t.input, t.options);
      } else {
        t.output = CoffeeScript.compile(t.input, t.options);
        CoffeeScript.emit('success', task);
        if (o.print) {
          return print(t.output);
        } else if (o.compile) {
          return writeJs(t.file, t.output, base);
        } else if (o.lint) {
          return lint(t.output);
        }
      }
    } catch (err) {
      CoffeeScript.emit('failure', err, task);
      if (CoffeeScript.listeners('failure').length) {
        return null;
      }
      if (o.watch) {
        return puts(err.message);
      }
      error(err.stack);
      return process.exit(1);
    }
  };
  compileStdio = function() {
    var code, stdin;
    code = '';
    stdin = process.openStdin();
    stdin.on('data', function(buffer) {
      if (buffer) {
        return code += buffer.toString();
      }
    });
    return stdin.on('end', function() {
      return compileScript('stdio', code);
    });
  };
  watch = function(source, base) {
    return fs.watchFile(source, {
      persistent: true,
      interval: 500
    }, function(curr, prev) {
      if (curr.size === prev.size && curr.mtime.getTime() === prev.mtime.getTime()) {
        return null;
      }
      return fs.readFile(source, function(err, code) {
        if (err) {
          throw err;
        }
        return compileScript(source, code.toString(), base);
      });
    });
  };
  writeJs = function(source, js, base) {
    var baseDir, compile, dir, filename, jsPath, srcDir;
    filename = path.basename(source, path.extname(source)) + '.js';
    srcDir = path.dirname(source);
    baseDir = srcDir.substring(base.length);
    dir = opts.output ? path.join(opts.output, baseDir) : srcDir;
    jsPath = path.join(dir, filename);
    compile = function() {
      if (js.length <= 0) {
        js = ' ';
      }
      return fs.writeFile(jsPath, js, function(err) {
        if (opts.compile && opts.watch) {
          return puts("Compiled " + (source));
        }
      });
    };
    return path.exists(dir, function(exists) {
      return exists ? compile() : exec("mkdir -p " + (dir), compile);
    });
  };
  lint = function(js) {
    var conf, jsl, printIt;
    printIt = function(buffer) {
      return puts(buffer.toString().trim());
    };
    conf = __dirname + '/../extras/jsl.conf';
    jsl = spawn('jsl', ['-nologo', '-stdin', '-conf', conf]);
    jsl.stdout.on('data', printIt);
    jsl.stderr.on('data', printIt);
    jsl.stdin.write(js);
    return jsl.stdin.end();
  };
  printTokens = function(tokens) {
    var _d, _e, _f, _g, _h, strings, tag, token, value;
    strings = (function() {
      _d = []; _f = tokens;
      for (_e = 0, _g = _f.length; _e < _g; _e++) {
        token = _f[_e];
        _d.push((function() {
          _h = [token[0], token[1].toString().replace(/\n/, '\\n')];
          tag = _h[0];
          value = _h[1];
          return "[" + (tag) + " " + (value) + "]";
        })());
      }
      return _d;
    })();
    return puts(strings.join(' '));
  };
  parseOptions = function() {
    var o;
    optionParser = new optparse.OptionParser(SWITCHES, BANNER);
    o = (opts = optionParser.parse(process.argv.slice(2, process.argv.length)));
    o.compile || (o.compile = (!!o.output));
    o.run = !(o.compile || o.print || o.lint);
    o.print = !!(o.print || (o.eval || o.stdio && o.compile));
    return (sources = o.arguments);
  };
  compileOptions = function(fileName) {
    var o;
    o = {
      fileName: fileName
    };
    o.noWrap = opts['no-wrap'];
    return o;
  };
  usage = function() {
    puts(optionParser.help());
    return process.exit(0);
  };
  version = function() {
    puts("CoffeeScript version " + (CoffeeScript.VERSION));
    return process.exit(0);
  };
})();
