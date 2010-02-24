(function(){
  var BANNER, SWITCHES, coffee, compile_options, compile_script, compile_scripts, compile_stdio, fs, lint, option_parser, options, optparse, parse_options, path, print_tokens, sources, usage, version, watch_scripts, write_js;
  fs = require('fs');
  path = require('path');
  coffee = require('coffee-script');
  optparse = require('optparse');
  BANNER = "coffee compiles CoffeeScript source files into JavaScript.\n\nUsage:\n  coffee path/to/script.coffee";
  SWITCHES = [['-i', '--interactive', 'run an interactive CoffeeScript REPL'], ['-r', '--run', 'compile and run a CoffeeScript'], ['-o', '--output [DIR]', 'set the directory for compiled JavaScript'], ['-w', '--watch', 'watch scripts for changes, and recompile'], ['-p', '--print', 'print the compiled JavaScript to stdout'], ['-l', '--lint', 'pipe the compiled JavaScript through JSLint'], ['-s', '--stdio', 'listen for and compile scripts over stdio'], ['-e', '--eval', 'compile a string from the command line'], ['-n', '--no-wrap', 'compile without the top-level function wrapper'], ['-t', '--tokens', 'print the tokens that the lexer produces'], ['-tr', '--tree', 'print the parse tree that Jison produces'], ['-v', '--version', 'display CoffeeScript version'], ['-h', '--help', 'display this help message']];
  options = {};
  sources = [];
  option_parser = null;
  // The CommandLine handles all of the functionality of the `coffee` utility.
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
      return require('repl');
    }
    if (options.stdio) {
      return compile_stdio();
    }
    if (options.eval) {
      return compile_script('unknown', sources[0]);
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
    process.ARGV = flags;
    if (options.watch) {
      watch_scripts();
    }
    compile_scripts();
    return this;
  };
  // The "--help" usage message.
  usage = function usage() {
    puts('\n' + option_parser.help() + '\n');
    return process.exit(0);
  };
  // The "--version" message.
  version = function version() {
    puts("CoffeeScript version " + coffee.VERSION);
    return process.exit(0);
  };
  // Compiles the source CoffeeScript, returning the desired JavaScript, tokens,
  // or JSLint results.
  compile_scripts = function compile_scripts() {
    var _a, _b, _c, compile, source;
    compile = function compile(source) {
      return fs.readFile(source, function(err, code) {
        return compile_script(source, code);
      });
    };
    _a = []; _b = sources;
    for (_c = 0; _c < _b.length; _c++) {
      source = _b[_c];
      _a.push(compile(source));
    }
    return _a;
  };
  // Compile a single source script, containing the given code, according to the
  // requested options. Both compile_scripts and watch_scripts share this method.
  compile_script = function compile_script(source, code) {
    var js, o;
    o = options;
    try {
      if (o.tokens) {
        return print_tokens(coffee.tokenize(code));
      } else if (o.tree) {
        return puts(coffee.tree(code).toString());
      } else {
        js = coffee.compile(code, compile_options());
        if (o.run) {
          return eval(js);
        } else if (o.lint) {
          return lint(js);
        } else if (o.print || o.eval) {
          return puts(js);
        } else {
          return write_js(source, js);
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
  // Listen for and compile scripts over stdio.
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
      return process.stdio.write(coffee.compile(code, compile_options()));
    });
  };
  // Watch a list of source CoffeeScript files, recompiling them every time the
  // files are updated.
  watch_scripts = function watch_scripts() {
    var _a, _b, _c, source, watch;
    watch = function watch(source) {
      return process.watchFile(source, {
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
    for (_c = 0; _c < _b.length; _c++) {
      source = _b[_c];
      _a.push(watch(source));
    }
    return _a;
  };
  // Write out a JavaScript source file with the compiled code.
  write_js = function write_js(source, js) {
    var dir, filename, js_path;
    filename = path.basename(source, path.extname(source)) + '.js';
    dir = options.output || path.dirname(source);
    js_path = path.join(dir, filename);
    return fs.writeFile(js_path, js);
  };
  // Pipe compiled JS through JSLint (requires a working 'jsl' command).
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
  // Pretty-print a token stream.
  print_tokens = function print_tokens(tokens) {
    var _a, _b, _c, strings, token;
    strings = (function() {
      _a = []; _b = tokens;
      for (_c = 0; _c < _b.length; _c++) {
        token = _b[_c];
        _a.push('[' + token[0] + ' ' + token[1].toString().replace(/\n/, '\\n') + ']');
      }
      return _a;
    }).call(this);
    return puts(strings.join(' '));
  };
  // Use OptionParser for all the options.
  parse_options = function parse_options() {
    option_parser = new optparse.OptionParser(SWITCHES, BANNER);
    options = option_parser.parse(process.ARGV);
    return sources = options.arguments.slice(2, options.arguments.length);
  };
  // The options to pass to the CoffeeScript compiler.
  compile_options = function compile_options() {
    return options['no-wrap'] ? {
      no_wrap: true
    } : {};
  };
})();
