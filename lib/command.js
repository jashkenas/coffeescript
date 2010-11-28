(function() {
  var ALL_SWITCHES, BANNER, CoffeeScript, DEPRECATED_SWITCHES, EventEmitter, SWITCHES, compileOptions, compileScript, compileScripts, compileStdio, exec, fs, helpers, lint, optionParser, optparse, opts, parseOptions, path, printLine, printTokens, printWarn, sources, spawn, usage, version, watch, writeJs, _ref;
  fs = require('fs');
  path = require('path');
  helpers = require('./helpers');
  optparse = require('./optparse');
  CoffeeScript = require('./coffee-script');
  _ref = require('child_process'), spawn = _ref.spawn, exec = _ref.exec;
  EventEmitter = require('events').EventEmitter;
  helpers.extend(CoffeeScript, new EventEmitter);
  printLine = function(line) {
    return process.stdout.write(line + '\n');
  };
  printWarn = function(line) {
    return process.binding('stdio').writeError(line + '\n');
  };
  BANNER = 'Usage: coffee [options] path/to/script.coffee';
  SWITCHES = [['-c', '--compile', 'compile to JavaScript and save as .js files'], ['-i', '--interactive', 'run an interactive CoffeeScript REPL'], ['-o', '--output [DIR]', 'set the directory for compiled JavaScript'], ['-w', '--watch', 'watch scripts for changes, and recompile'], ['-p', '--print', 'print the compiled JavaScript to stdout'], ['-l', '--lint', 'pipe the compiled JavaScript through JSLint'], ['-s', '--stdio', 'listen for and compile scripts over stdio'], ['-e', '--eval', 'compile a string from the command line'], ['-r', '--require [FILE*]', 'require a library before executing your script'], ['-b', '--bare', 'compile without the top-level function wrapper'], ['-t', '--tokens', 'print the tokens that the lexer produces'], ['-n', '--nodes', 'print the parse tree that Jison produces'], ['-v', '--version', 'display CoffeeScript version'], ['-h', '--help', 'display this help message']];
  DEPRECATED_SWITCHES = [['--no-wrap', 'compile without the top-level function wrapper']];
  ALL_SWITCHES = SWITCHES.concat(DEPRECATED_SWITCHES);
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
      return compileScript(null, sources[0]);
    }
    if (!sources.length) {
      return require('./repl');
    }
    separator = sources.indexOf('--');
    flags = [];
    if (separator >= 0) {
      flags = sources.splice(separator + 1);
      sources.pop();
    }
    if (opts.run) {
      flags = sources.splice(1).concat(flags);
    }
    process.ARGV = process.argv = flags;
    return compileScripts();
  };
  compileScripts = function() {
    var base, compile, _fn, _i, _len, _results;
    _fn = function(source) {
      base = path.join(source);
      compile = function(source, topLevel) {
        return path.exists(source, function(exists) {
          if (!exists) {
            throw new Error("File not found: " + source);
          }
          return fs.stat(source, function(err, stats) {
            if (stats.isDirectory()) {
              return fs.readdir(source, function(err, files) {
                var file, _i, _len, _results;
                _results = [];
                for (_i = 0, _len = files.length; _i < _len; _i++) {
                  file = files[_i];
                  _results.push(compile(path.join(source, file)));
                }
                return _results;
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
      return _results.push(compile(source, true));
    };
    _results = [];
    for (_i = 0, _len = sources.length; _i < _len; _i++) {
      source = sources[_i];
      _fn(source);
    }
    return _results;
  };
  compileScript = function(file, input, base) {
    var o, options, req, t, task, _i, _len, _ref;
    o = opts;
    options = compileOptions(file);
    if (o.require) {
      _ref = o.require;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        req = _ref[_i];
        require(helpers.starts(req, '.') ? fs.realpathSync(req) : req);
      }
    }
    try {
      t = task = {
        file: file,
        input: input,
        options: options
      };
      CoffeeScript.emit('compile', task);
      if (o.tokens) {
        return printTokens(CoffeeScript.tokens(t.input));
      } else if (o.nodes) {
        return printLine(CoffeeScript.nodes(t.input).toString().trim());
      } else if (o.run) {
        return CoffeeScript.run(t.input, t.options);
      } else {
        t.output = CoffeeScript.compile(t.input, t.options);
        CoffeeScript.emit('success', task);
        if (o.print) {
          return printLine(t.output.trim());
        } else if (o.compile) {
          return writeJs(t.file, t.output, base);
        } else if (o.lint) {
          return lint(t.file, t.output);
        }
      }
    } catch (err) {
      CoffeeScript.emit('failure', err, task);
      if (CoffeeScript.listeners('failure').length) {
        return;
      }
      if (o.watch) {
        return printLine(err.message);
      }
      printWarn(err.stack);
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
      return compileScript(null, code);
    });
  };
  watch = function(source, base) {
    return fs.watchFile(source, {
      persistent: true,
      interval: 500
    }, function(curr, prev) {
      if (curr.size === prev.size && curr.mtime.getTime() === prev.mtime.getTime()) {
        return;
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
        if (err) {
          return printLine(err.message);
        } else if (opts.compile && opts.watch) {
          return printLine("Compiled " + source);
        }
      });
    };
    return path.exists(dir, function(exists) {
      if (exists) {
        return compile();
      } else {
        return exec("mkdir -p " + dir, compile);
      }
    });
  };
  lint = function(file, js) {
    var conf, jsl, printIt;
    printIt = function(buffer) {
      return printLine(file + ':\t' + buffer.toString().trim());
    };
    conf = __dirname + '/../extras/jsl.conf';
    jsl = spawn('jsl', ['-nologo', '-stdin', '-conf', conf]);
    jsl.stdout.on('data', printIt);
    jsl.stderr.on('data', printIt);
    jsl.stdin.write(js);
    return jsl.stdin.end();
  };
  printTokens = function(tokens) {
    var strings, tag, token, value, _i, _len, _ref, _results;
    strings = function() {
      _results = [];
      for (_i = 0, _len = tokens.length; _i < _len; _i++) {
        token = tokens[_i];
        _ref = [token[0], token[1].toString().replace(/\n/, '\\n')], tag = _ref[0], value = _ref[1];
        _results.push("[" + tag + " " + value + "]");
      }
      return _results;
    }();
    return printLine(strings.join(' '));
  };
  parseOptions = function() {
    var o;
    optionParser = new optparse.OptionParser(ALL_SWITCHES, BANNER);
    o = opts = optionParser.parse(process.argv.slice(2));
    o.compile || (o.compile = !!o.output);
    o.run = !(o.compile || o.print || o.lint);
    o.print = !!(o.print || (o.eval || o.stdio && o.compile));
    sources = o.arguments;
    if (opts['no-wrap']) {
      return printWarn('--no-wrap is deprecated; please use --bare instead.');
    }
  };
  compileOptions = function(fileName) {
    return {
      fileName: fileName,
      bare: opts.bare || opts['no-wrap']
    };
  };
  usage = function() {
    printLine((new optparse.OptionParser(SWITCHES, BANNER)).help());
    return process.exit(0);
  };
  version = function() {
    printLine("CoffeeScript version " + CoffeeScript.VERSION);
    return process.exit(0);
  };
}).call(this);
