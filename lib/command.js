(function(){
  var BANNER, CoffeeScript, SWITCHES, _a, compileOptions, compileScript, compileScripts, compileStdio, exec, fs, lint, optionParser, options, optparse, parseOptions, path, printTokens, sources, spawn, usage, version, watch, writeJs;
  // The `coffee` utility. Handles command-line compilation of CoffeeScript
  // into various forms: saved into `.js` files or printed to stdout, piped to
  // [JSLint](http://javascriptlint.com/) or recompiled every time the source is
  // saved, printed as a token stream or as the syntax tree, or launch an
  // interactive REPL.
  // External dependencies.
  fs = require('fs');
  path = require('path');
  optparse = require('./optparse');
  CoffeeScript = require('./coffee-script');
  _a = require('child_process');
  spawn = _a.spawn;
  exec = _a.exec;
  // The help banner that is printed when `coffee` is called without arguments.
  BANNER = 'coffee compiles CoffeeScript source files into JavaScript.\n\nUsage:\n  coffee path/to/script.coffee';
  // The list of all the valid option flags that `coffee` knows how to handle.
  SWITCHES = [['-c', '--compile', 'compile to JavaScript and save as .js files'], ['-i', '--interactive', 'run an interactive CoffeeScript REPL'], ['-o', '--output [DIR]', 'set the directory for compiled JavaScript'], ['-w', '--watch', 'watch scripts for changes, and recompile'], ['-p', '--print', 'print the compiled JavaScript to stdout'], ['-l', '--lint', 'pipe the compiled JavaScript through JSLint'], ['-s', '--stdio', 'listen for and compile scripts over stdio'], ['-e', '--eval', 'compile a string from the command line'], ['--no-wrap', 'compile without the top-level function wrapper'], ['-t', '--tokens', 'print the tokens that the lexer produces'], ['-n', '--nodes', 'print the parse tree that Jison produces'], ['-v', '--version', 'display CoffeeScript version'], ['-h', '--help', 'display this help message']];
  // Top-level objects shared by all the functions.
  options = {};
  sources = [];
  optionParser = null;
  // Run `coffee` by parsing passed options and determining what action to take.
  // Many flags cause us to divert before compiling anything. Flags passed after
  // `--` will be passed verbatim to your script as arguments in `process.argv`
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
  // Asynchronously read in each CoffeeScript in a list of source files and
  // compile them. If a directory is passed, recursively compile all
  // '.coffee' extension source files in it and all subdirectories.
  compileScripts = function() {
    var _b, _c, _d, _e, base, compile, source;
    _b = []; _d = sources;
    for (_c = 0, _e = _d.length; _c < _e; _c++) {
      source = _d[_c];
      _b.push((function() {
        base = source;
        compile = function(source, topLevel) {
          return path.exists(source, function(exists) {
            if (!(exists)) {
              throw new Error(("File not found: " + source));
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
    }
    return _b;
  };
  // Compile a single source script, containing the given code, according to the
  // requested options. If evaluating the script directly sets `__filename`,
  // `__dirname` and `module.filename` to be correct relative to the script's path.
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
  // Attach the appropriate listeners to compile scripts incoming over **stdin**,
  // and write them back to **stdout**.
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
  // Watch a source CoffeeScript file using `fs.watchFile`, recompiling it every
  // time the file is updated. May be used in combination with other options,
  // such as `--lint` or `--print`.
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
  // Write out a JavaScript source file with the compiled code. By default, files
  // are written out in `cwd` as `.js` files with the same name, but the output
  // directory can be customized with `--output`.
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
          return puts(("Compiled " + source));
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
  // Pipe compiled JS through JSLint (requires a working `jsl` command), printing
  // any errors or warnings that arise.
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
  // Pretty-print a stream of tokens.
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
  // Use the [OptionParser module](optparse.html) to extract all options from
  // `process.argv` that are specified in `SWITCHES`.
  parseOptions = function() {
    var o;
    optionParser = new optparse.OptionParser(SWITCHES, BANNER);
    o = (options = optionParser.parse(process.argv));
    options.run = !(o.compile || o.print || o.lint);
    options.print = !!(o.print || (o.eval || o.stdio && o.compile));
    sources = options.arguments.slice(2, options.arguments.length);
    return sources;
  };
  // The compile-time options to pass to the CoffeeScript compiler.
  compileOptions = function(source) {
    var o;
    o = {
      source: source
    };
    o['no_wrap'] = options['no-wrap'];
    return o;
  };
  // Print the `--help` usage message and exit.
  usage = function() {
    puts(optionParser.help());
    return process.exit(0);
  };
  // Print the `--version` message and exit.
  version = function() {
    puts(("CoffeeScript version " + CoffeeScript.VERSION));
    return process.exit(0);
  };
})();
