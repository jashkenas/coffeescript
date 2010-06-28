(function(){
  var BANNER, CoffeeScript, SWITCHES, _a, compileOptions, compileScript, compileScripts, compileStdio, exec, fs, lint, optionParser, options, optparse, parseOptions, path, printTokens, sources, spawn, usage, version, watch, writeJs;
  fs = require('fs');
  path = require('path');
  optparse = require('./optparse');
  CoffeeScript = require('./coffee-script');
  _a = require('child_process');
  spawn = _a.spawn;
  exec = _a.exec;
  BANNER = 'coffee compiles CoffeeScript source files into JavaScript.\n\nUsage:\n  coffee path/to/script.coffee';
  SWITCHES = [['-c', '--compile', 'compile to JavaScript and save as .js files'], ['-i', '--interactive', 'run an interactive CoffeeScript REPL'], ['-o', '--output [DIR]', 'set the directory for compiled JavaScript'], ['-w', '--watch', 'watch scripts for changes, and recompile'], ['-p', '--print', 'print the compiled JavaScript to stdout'], ['-l', '--lint', 'pipe the compiled JavaScript through JSLint'], ['-s', '--stdio', 'listen for and compile scripts over stdio'], ['-e', '--eval', 'compile a string from the command line'], ['--no-wrap', 'compile without the top-level function wrapper'], ['-t', '--tokens', 'print the tokens that the lexer produces'], ['-n', '--nodes', 'print the parse tree that Jison produces'], ['-v', '--version', 'display CoffeeScript version'], ['-h', '--help', 'display this help message']];
  options = {};
  sources = [];
  optionParser = null;
  exports.run = function() {
    var flags, separator;
    parseOptions();
    if (options.help) {
      return usage();
    }
    if (options.version) {
      return version();
    }
    if (options.interactive) {
      return require('./repl');
    }
    if (options.stdio) {
      return compileStdio();
    }
    if (options.eval) {
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
    process.ARGV = (process.argv = flags);
    return compileScripts();
  };
  compileScripts = function() {
    var _b, _c, _d, _e;
    _b = []; _d = sources;
    for (_c = 0, _e = _d.length; _c < _e; _c++) {
      (function() {
        var base, compile;
        var source = _d[_c];
        return _b.push((function() {
          base = source;
          compile = function(source, topLevel) {
            return path.exists(source, function(exists) {
              if (!(exists)) {
                throw new Error("File not found: " + source);
              }
              return fs.stat(source, function(err, stats) {
                if (stats.isDirectory()) {
                  return fs.readdir(source, function(err, files) {
                    var _f, _g, _h, _i, file;
                    _f = []; _h = files;
                    for (_g = 0, _i = _h.length; _g < _i; _g++) {
                      file = _h[_g];
                      _f.push(compile(path.join(source, file)));
                    }
                    return _f;
                  });
                } else if (topLevel || path.extname(source) === '.coffee') {
                  fs.readFile(source, function(err, code) {
                    return compileScript(source, code.toString(), base);
                  });
                  if (options.watch) {
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
    return _b;
  };
  compileScript = function(source, code, base) {
    var codeOpts, js, o;
    o = options;
    codeOpts = compileOptions(source);
    try {
      if (o.tokens) {
        return printTokens(CoffeeScript.tokens(code));
      } else if (o.nodes) {
        return puts(CoffeeScript.nodes(code).toString());
      } else if (o.run) {
        return CoffeeScript.run(code, codeOpts);
      } else {
        js = CoffeeScript.compile(code, codeOpts);
        if (o.print) {
          return print(js);
        } else if (o.compile) {
          return writeJs(source, js, base);
        } else if (o.lint) {
          return lint(js);
        }
      }
    } catch (err) {
      if (!(o.watch)) {
        error(err.stack) && process.exit(1);
      }
      return puts(err.message);
    }
  };
  compileStdio = function() {
    var code, stdin;
    code = '';
    stdin = process.openStdin();
    stdin.addListener('data', function(buffer) {
      if (buffer) {
        return code += buffer.toString();
      }
    });
    return stdin.addListener('end', function() {
      return compileScript('stdio', code);
    });
  };
  watch = function(source, base) {
    return fs.watchFile(source, {
      persistent: true,
      interval: 500
    }, function(curr, prev) {
      if (curr.mtime.getTime() === prev.mtime.getTime()) {
        return null;
      }
      return fs.readFile(source, function(err, code) {
        return compileScript(source, code.toString(), base);
      });
    });
  };
  writeJs = function(source, js, base) {
    var baseDir, compile, dir, filename, jsPath, srcDir;
    filename = path.basename(source, path.extname(source)) + '.js';
    srcDir = path.dirname(source);
    baseDir = srcDir.substring(base.length);
    dir = options.output ? path.join(options.output, baseDir) : srcDir;
    jsPath = path.join(dir, filename);
    compile = function() {
      return fs.writeFile(jsPath, js, function(err) {
        if (options.compile && options.watch) {
          return puts("Compiled " + source);
        }
      });
    };
    return path.exists(dir, function(exists) {
      if (exists) {
        return compile();
      } else {
        return exec(("mkdir -p " + dir), compile);
      }
    });
  };
  lint = function(js) {
    var jsl, printIt;
    printIt = function(buffer) {
      return print(buffer.toString());
    };
    jsl = spawn('jsl', ['-nologo', '-stdin']);
    jsl.stdout.addListener('data', printIt);
    jsl.stderr.addListener('data', printIt);
    jsl.stdin.write(js);
    return jsl.stdin.end();
  };
  printTokens = function(tokens) {
    var _b, _c, _d, _e, _f, strings, tag, token, value;
    strings = (function() {
      _b = []; _d = tokens;
      for (_c = 0, _e = _d.length; _c < _e; _c++) {
        token = _d[_c];
        _b.push((function() {
          _f = [token[0], token[1].toString().replace(/\n/, '\\n')];
          tag = _f[0];
          value = _f[1];
          return "[" + tag + " " + value + "]";
        })());
      }
      return _b;
    })();
    return puts(strings.join(' '));
  };
  parseOptions = function() {
    var o;
    optionParser = new optparse.OptionParser(SWITCHES, BANNER);
    o = (options = optionParser.parse(process.argv));
    options.run = !(o.compile || o.print || o.lint);
    options.print = !!(o.print || (o.eval || o.stdio && o.compile));
    sources = options.arguments.slice(2, options.arguments.length);
    return sources;
  };
  compileOptions = function(source) {
    var o;
    o = {
      source: source
    };
    o['no_wrap'] = options['no-wrap'];
    return o;
  };
  usage = function() {
    puts(optionParser.help());
    return process.exit(0);
  };
  version = function() {
    puts("CoffeeScript version " + CoffeeScript.VERSION);
    return process.exit(0);
  };
})();
