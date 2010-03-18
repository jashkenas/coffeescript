(function(){
  var BANNER, CoffeeScript, SWITCHES, compile_options, compile_script, compile_scripts, compile_stdio, fs, lint, option_parser, options, optparse, parse_options, path, print_tokens, sources, usage, version, watch_scripts, write_js;
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
  // The help banner that is printed when `coffee` is called without arguments.
  BANNER = 'coffee compiles CoffeeScript source files into JavaScript.\n\nUsage:\n  coffee path/to/script.coffee';
  // The list of all the valid option flags that `coffee` knows how to handle.
  SWITCHES = [['-c', '--compile', 'compile to JavaScript and save as .js files'], ['-i', '--interactive', 'run an interactive CoffeeScript REPL'], ['-o', '--output [DIR]', 'set the directory for compiled JavaScript'], ['-w', '--watch', 'watch scripts for changes, and recompile'], ['-p', '--print', 'print the compiled JavaScript to stdout'], ['-l', '--lint', 'pipe the compiled JavaScript through JSLint'], ['-s', '--stdio', 'listen for and compile scripts over stdio'], ['-e', '--eval', 'compile a string from the command line'], ['--no-wrap', 'compile without the top-level function wrapper'], ['-t', '--tokens', 'print the tokens that the lexer produces'], ['-n', '--nodes', 'print the parse tree that Jison produces'], ['-v', '--version', 'display CoffeeScript version'], ['-h', '--help', 'display this help message']];
  // Top-level objects shared by all the functions.
  options = {};
  sources = [];
  option_parser = null;
  // Run `coffee` by parsing passed options and determining what action to take.
  // Many flags cause us to divert before compiling anything. Flags passed after
  // `--` will be passed verbatim to your script as arguments in `process.argv`
  exports.run = function run() {
    var flags, separator;
    parse_options();
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
      return compile_stdio();
    }
    if (options.eval) {
      return compile_script('console', sources[0]);
    }
    if (!(sources.length)) {
      return usage();
    }
    separator = sources.indexOf('--');
    flags = [];
    if (separator >= 0) {
      flags = sources.slice((separator + 1), sources.length);
      sources = sources.slice(0, separator);
    }
    process.ARGV = (process.argv = flags);
    if (options.watch) {
      watch_scripts();
    }
    return compile_scripts();
  };
  // Asynchronously read in each CoffeeScript in a list of source files and
  // compile them.
  compile_scripts = function compile_scripts() {
    var _a, _b, _c, _d, compile, source;
    compile = function compile(source) {
      return path.exists(source, function(exists) {
        if (!(exists)) {
          throw new Error("File not found: " + source);
        }
        return fs.readFile(source, function(err, code) {
          return compile_script(source, code);
        });
      });
    };
    _a = []; _b = sources;
    for (_c = 0, _d = _b.length; _c < _d; _c++) {
      source = _b[_c];
      _a.push(compile(source));
    }
    return _a;
  };
  // Compile a single source script, containing the given code, according to the
  // requested options. Both compile_scripts and watch_scripts share this method
  // in common. If evaluating the script directly sets `__filename`, `__dirname`
  // and `module.filename` to be correct relative to the script's path.
  compile_script = function compile_script(source, code) {
    var code_opts, js, o;
    o = options;
    code_opts = compile_options(source);
    try {
      if (o.tokens) {
        return print_tokens(CoffeeScript.tokens(code));
      } else if (o.nodes) {
        return puts(CoffeeScript.nodes(code).toString());
      } else if (o.run) {
        return CoffeeScript.run(code, code_opts);
      } else {
        js = CoffeeScript.compile(code, code_opts);
        if (o.print) {
          return process.stdio.write(js);
        } else if (o.compile) {
          return write_js(source, js);
        } else if (o.lint) {
          return lint(js);
        }
      }
    } catch (err) {
      if (o.watch) {
        return puts(err.message);
      } else {
        throw err;
      }
    }
  };
  // Attach the appropriate listeners to compile scripts incoming over **stdin**,
  // and write them back to **stdout**.
  compile_stdio = function compile_stdio() {
    var code;
    code = '';
    process.stdio.open();
    process.stdio.addListener('data', function(string) {
      if (string) {
        return code += string;
      }
    });
    return process.stdio.addListener('close', function() {
      return compile_script('stdio', code);
    });
  };
  // Watch a list of source CoffeeScript files using `fs.watchFile`, recompiling
  // them every time the files are updated. May be used in combination with other
  // options, such as `--lint` or `--print`.
  watch_scripts = function watch_scripts() {
    var _a, _b, _c, _d, source, watch;
    watch = function watch(source) {
      return fs.watchFile(source, {
        persistent: true,
        interval: 500
      }, function(curr, prev) {
        if (curr.mtime.getTime() === prev.mtime.getTime()) {
          return null;
        }
        return fs.readFile(source, function(err, code) {
          return compile_script(source, code);
        });
      });
    };
    _a = []; _b = sources;
    for (_c = 0, _d = _b.length; _c < _d; _c++) {
      source = _b[_c];
      _a.push(watch(source));
    }
    return _a;
  };
  // Write out a JavaScript source file with the compiled code. By default, files
  // are written out in `cwd` as `.js` files with the same name, but the output
  // directory can be customized with `--output`.
  write_js = function write_js(source, js) {
    var dir, filename, js_path;
    filename = path.basename(source, path.extname(source)) + '.js';
    dir = options.output || path.dirname(source);
    js_path = path.join(dir, filename);
    return fs.writeFile(js_path, js);
  };
  // Pipe compiled JS through JSLint (requires a working `jsl` command), printing
  // any errors or warnings that arise.
  lint = function lint(js) {
    var jsl;
    jsl = process.createChildProcess('jsl', ['-nologo', '-stdin']);
    jsl.addListener('output', function(result) {
      if (result) {
        return puts(result.replace(/\n/g, ''));
      }
    });
    jsl.addListener('error', function(result) {
      if (result) {
        return puts(result);
      }
    });
    jsl.write(js);
    return jsl.close();
  };
  // Pretty-print a stream of tokens.
  print_tokens = function print_tokens(tokens) {
    var _a, _b, _c, _d, _e, strings, tag, token, value;
    strings = (function() {
      _a = []; _b = tokens;
      for (_c = 0, _d = _b.length; _c < _d; _c++) {
        token = _b[_c];
        _a.push((function() {
          _e = [token[0], token[1].toString().replace(/\n/, '\\n')];
          tag = _e[0];
          value = _e[1];
          return "[" + tag + " " + value + "]";
        }).call(this));
      }
      return _a;
    }).call(this);
    return puts(strings.join(' '));
  };
  // Use the [OptionParser module](optparse.html) to extract all options from
  // `process.argv` that are specified in `SWITCHES`.
  parse_options = function parse_options() {
    var o;
    option_parser = new optparse.OptionParser(SWITCHES, BANNER);
    o = (options = option_parser.parse(process.argv));
    options.run = !(o.compile || o.print || o.lint);
    options.print = !!(o.print || (o.eval || o.stdio && o.compile));
    return sources = options.arguments.slice(2, options.arguments.length);
  };
  // The compile-time options to pass to the CoffeeScript compiler.
  compile_options = function compile_options(source) {
    var o;
    o = {
      source: source
    };
    o['no_wrap'] = options['no-wrap'];
    return o;
  };
  // Print the `--help` usage message and exit.
  usage = function usage() {
    puts(option_parser.help());
    return process.exit(0);
  };
  // Print the `--version` message and exit.
  version = function version() {
    puts("CoffeeScript version " + (CoffeeScript.VERSION));
    return process.exit(0);
  };
})();
