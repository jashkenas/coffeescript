(function(){
  var BANNER, SWITCHES, coffee, compile, compile_script, compile_scripts, fs, lint, option_parser, options, optparse, parse_options, path, sources, usage, version, watch_scripts, write_js;
  fs = require('fs');
  path = require('path');
  coffee = require('coffee-script');
  optparse = require('optparse');
  BANNER = "coffee compiles CoffeeScript source files into JavaScript.\n\nUsage:\n  coffee path/to/script.coffee";
  SWITCHES = [['-i', '--interactive', 'run an interactive CoffeeScript REPL'], ['-r', '--run', 'compile and run a CoffeeScript'], ['-o', '--output [DIR]', 'set the directory for compiled JavaScript'], ['-w', '--watch', 'watch scripts for changes, and recompile'], ['-p', '--print', 'print the compiled JavaScript to stdout'], ['-l', '--lint', 'pipe the compiled JavaScript through JSLint'], ['-e', '--eval', 'compile a string from the command line'], ['-t', '--tokens', 'print the tokens that the lexer produces'], ['-tr', '--tree', 'print the parse tree that Jison produces'], ['-v', '--version', 'display CoffeeScript version'], ['-h', '--help', 'display this help message']];
  options = {};
  sources = [];
  option_parser = null;
  // The CommandLine handles all of the functionality of the `coffee` utility.
  exports.run = function run() {
    var flags, separator;
    parse_options();
    if (options.interactive) {
      return require('repl');
    }
    if (options.eval) {
      return puts(coffee.compile(sources[0]));
    }
    if (!(sources.length)) {
      usage();
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
  // Compile a single source file to JavaScript.
  compile = function compile(script, source) {
    source = source || 'error';
    options = {};
    if (options.no_wrap) {
      options.no_wrap = true;
    }
    if (options.globals) {
      options.globals = true;
    }
    try {
      return CoffeeScript.compile(script, options);
    } catch (error) {
      process.stdio.writeError(source + ': ' + error.toString());
      if (!(options.watch)) {
        process.exit(1);
      }
      return null;
    }
  };
  // Compiles the source CoffeeScript, returning the desired JavaScript, tokens,
  // or JSLint results.
  compile_scripts = function compile_scripts() {
    var source;
    if (!((source = sources.shift()))) {
      return null;
    }
    return fs.readFile(source).addCallback(function(code) {
      compile_script(source, code);
      return compile_scripts();
    });
  };
  // Compile a single source script, containing the given code, according to the
  // requested options. Both compile_scripts and watch_scripts share this method.
  compile_script = function compile_script(source, code) {
    var js, opts;
    opts = options;
    try {
      if (opts.tokens) {
        return coffee.print_tokens(coffee.tokenize(code));
      } else if (opts.tree) {
        return puts(coffee.tree(code).toString());
      } else {
        js = coffee.compile(code);
        if (opts.run) {
          return eval(js);
        } else if (opts.print) {
          return puts(js);
        } else if (opts.lint) {
          return lint(js);
        } else {
          return write_js(source, coffee.compile(code));
        }
      }
    } catch (err) {
      if (opts.watch) {
        return puts(err.message);
      } else {
        throw err;
      }
    }
  };
  // Watch a list of source CoffeeScript files, recompiling them every time the
  // files are updated.
  watch_scripts = function watch_scripts() {
    var _a, _b, _c, source;
    _a = []; _b = sources;
    for (_c = 0; _c < _b.length; _c++) {
      source = _b[_c];
      _a.push(process.watchFile(source, {
        persistent: true,
        interval: 500
      }, function(curr, prev) {
        if (curr.mtime.getTime() === prev.mtime.getTime()) {
          return null;
        }
        return fs.readFile(source).addCallback(function(code) {
          return compile_script(source, code);
        });
      }));
    }
    return _a;
  };
  // Write out a JavaScript source file with the compiled code.
  write_js = function write_js(source, js) {
    var dir, filename, js_path;
    filename = path.basename(source, path.extname(source)) + '.js';
    dir = options.output || path.dirname(source);
    js_path = path.join(dir, filename);
    return fs.open(js_path, 'w+', 0755).addCallback(function(fd) {
      return fs.write(fd, js);
    });
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
  // Use OptionParser for all the options.
  parse_options = function parse_options() {
    var oparser, opts, paths;
    opts = (options = {});
    oparser = (option_parser = new optparse.OptionParser(SWITCHES));
    oparser.banner = BANNER;
    oparser.add('interactive', function() {
      return opts.interactive = true;
    });
    oparser.add('run', function() {
      return opts.run = true;
    });
    oparser.add('output', function(dir) {
      return opts.output = dir;
    });
    oparser.add('watch', function() {
      return opts.watch = true;
    });
    oparser.add('print', function() {
      return opts.print = true;
    });
    oparser.add('lint', function() {
      return opts.lint = true;
    });
    oparser.add('eval', function() {
      return opts.eval = true;
    });
    oparser.add('tokens', function() {
      return opts.tokens = true;
    });
    oparser.add('tree', function() {
      return opts.tree = true;
    });
    oparser.add('help', (function(__this) {
      var __func = function() {
        return usage();
      };
      return (function() {
        return __func.apply(__this, arguments);
      });
    })(this));
    oparser.add('version', (function(__this) {
      var __func = function() {
        return version();
      };
      return (function() {
        return __func.apply(__this, arguments);
      });
    })(this));
    paths = oparser.parse(process.ARGV);
    return sources = paths.slice(2, paths.length);
  };
})();