(function() {
  var BANNER, CoffeeScript, EventEmitter, SWITCHES, _ref, compileOptions, compileScript, compileScripts, compileStdio, exec, fs, helpers, lint, optionParser, optparse, opts, parseOptions, path, printTokens, sources, spawn, usage, version, watch, writeJs;
  fs = require('fs');
  path = require('path');
  optparse = require('./optparse');
  CoffeeScript = require('./coffee-script');
  helpers = require('./helpers');
  _ref = require('child_process'), spawn = _ref.spawn, exec = _ref.exec;
  EventEmitter = require('events').EventEmitter;
  helpers.extend(CoffeeScript, new EventEmitter);
  global.CoffeeScript = CoffeeScript;
  BANNER = 'coffee compiles CoffeeScript source files into JavaScript.\n\nUsage:\n  coffee path/to/script.coffee';
  SWITCHES = [['-c', '--compile', 'compile to JavaScript and save as .js files'], ['-i', '--interactive', 'run an interactive CoffeeScript REPL'], ['-o', '--output [DIR]', 'set the directory for compiled JavaScript'], ['-w', '--watch', 'watch scripts for changes, and recompile'], ['-p', '--print', 'print the compiled JavaScript to stdout'], ['-l', '--lint', 'pipe the compiled JavaScript through JSLint'], ['-s', '--stdio', 'listen for and compile scripts over stdio'], ['-e', '--eval', 'compile a string from the command line'], ['-r', '--require [FILE*]', 'require a library before executing your script'], ['-b', '--bare', 'compile without the top-level function wrapper'], ['-t', '--tokens', 'print the tokens that the lexer produces'], ['-n', '--nodes', 'print the parse tree that Jison produces'], ['-v', '--version', 'display CoffeeScript version'], ['-h', '--help', 'display this help message']];
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
    process.ARGV = (process.argv = flags);
    return compileScripts();
  };
  compileScripts = function() {
    var _i, _j, _len, _ref2, _result, base, compile, source;
    _result = [];
    for (_i = 0, _len = (_ref2 = sources).length; _i < _len; _i++) {
      (function() {
        var source = _ref2[_i];
        _j = source;
        return _result.push((function() {
          base = source;
          compile = function(source, topLevel) {
            return path.exists(source, function(exists) {
              if (!exists) {
                throw new Error("File not found: " + source);
              }
              return fs.stat(source, function(err, stats) {
                if (stats.isDirectory()) {
                  return fs.readdir(source, function(err, files) {
                    var _k, _len2, _result2, file;
                    _result2 = [];
                    for (_k = 0, _len2 = files.length; _k < _len2; _k++) {
                      file = files[_k];
                      _result2.push(compile(path.join(source, file)));
                    }
                    return _result2;
                  });
                } else if (topLevel || path.extname(source) === '.coffee') {
                  fs.readFile(source, function(err, code) {
                    return compileScript(source, code.toString(), base);
                  });
                  return opts.watch ? watch(source, base) : undefined;
                }
              });
            });
          };
          return compile(source, true);
        })());
      })();
      source = _j;
    }
    return _result;
  };
  compileScript = function(file, input, base) {
    var _i, _len, _ref2, o, options, req, t, task;
    o = opts;
    options = compileOptions(file);
    if (o.require) {
      for (_i = 0, _len = (_ref2 = o.require).length; _i < _len; _i++) {
        req = _ref2[_i];
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
        return puts(CoffeeScript.nodes(t.input).toString().trim());
      } else if (o.run) {
        return CoffeeScript.run(t.input, t.options);
      } else {
        t.output = CoffeeScript.compile(t.input, t.options);
        CoffeeScript.emit('success', task);
        return o.print ? print(t.output) : (o.compile ? writeJs(t.file, t.output, base) : (o.lint ? lint(t.output) : undefined));
      }
    } catch (err) {
      CoffeeScript.emit('failure', err, task);
      if (CoffeeScript.listeners('failure').length) {
        return;
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
      return buffer ? code += buffer.toString() : undefined;
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
        return opts.compile && opts.watch ? puts("Compiled " + source) : undefined;
      });
    };
    return path.exists(dir, function(exists) {
      return exists ? compile() : exec("mkdir -p " + dir, compile);
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
    var _i, _len, _ref2, _result, strings, tag, token, value;
    strings = (function() {
      _result = [];
      for (_i = 0, _len = tokens.length; _i < _len; _i++) {
        token = tokens[_i];
        _result.push((function() {
          _ref2 = [token[0], token[1].toString().replace(/\n/, '\\n')], tag = _ref2[0], value = _ref2[1];
          return "[" + tag + " " + value + "]";
        })());
      }
      return _result;
    })();
    return puts(strings.join(' '));
  };
  parseOptions = function() {
    var o;
    optionParser = new optparse.OptionParser(SWITCHES, BANNER);
    o = (opts = optionParser.parse(process.argv.slice(2)));
    o.compile || (o.compile = !!o.output);
    o.run = !(o.compile || o.print || o.lint);
    o.print = !!(o.print || (o.eval || o.stdio && o.compile));
    return (sources = o.arguments);
  };
  compileOptions = function(fileName) {
    return {
      fileName: fileName,
      bare: opts.bare
    };
  };
  usage = function() {
    puts(optionParser.help());
    return process.exit(0);
  };
  version = function() {
    puts("CoffeeScript version " + (CoffeeScript.VERSION));
    return process.exit(0);
  };
}).call(this);
