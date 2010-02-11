(function(){
  var BANNER, SWITCHES, WATCH_INTERVAL, coffee, optparse, posix;
  optparse = require('./../../vendor/optparse-js/src/optparse');
  posix = require('posix');
  coffee = require('coffee-script');
  BANNER = "coffee compiles CoffeeScript source files into JavaScript.\n\nUsage:\n  coffee path/to/script.coffee";
  SWITCHES = [['-i', '--interactive', 'run an interactive CoffeeScript REPL'], ['-r', '--run', 'compile and run a CoffeeScript'], ['-o', '--output [DIR]', 'set the directory for compiled JavaScript'], ['-w', '--watch', 'watch scripts for changes, and recompile'], ['-p', '--print', 'print the compiled JavaScript to stdout'], ['-l', '--lint', 'pipe the compiled JavaScript through JSLint'], ['-e', '--eval', 'compile a cli scriptlet or read from stdin'], ['-t', '--tokens', 'print the tokens that the lexer produces'], ['-n', '--no-wrap', 'raw output, no function safety wrapper'], ['-g', '--globals', 'attach all top-level variables as globals'], ['-v', '--version', 'display CoffeeScript version'], ['-h', '--help', 'display this help message']];
  WATCH_INTERVAL = 0.5;
  // The CommandLine handles all of the functionality of the `coffee` utility.
  exports.run = function run() {
    this.parse_options();
    this.compile_scripts();
    return this;
  };
  // The "--help" usage message.
  exports.usage = function usage() {
    puts('\n' + this.option_parser.toString() + '\n');
    return process.exit(0);
  };
  // The "--version" message.
  exports.version = function version() {
    puts("CoffeeScript version " + coffee.VERSION);
    return process.exit(0);
  };
  // Compile a single source file to JavaScript.
  exports.compile = function compile(script, source) {
    var options;
    source = source || 'error';
    options = {
    };
    if (this.options.no_wrap) {
      options.no_wrap = true;
    }
    if (this.options.globals) {
      options.globals = true;
    }
    try {
      return CoffeeScript.compile(script, options);
    } catch (error) {
      process.stdio.writeError(source + ': ' + error.toString());
      if (!(this.options.watch)) {
        process.exit(1);
      }
      return null;
    }
  };
  // Compiles the source CoffeeScript, returning the desired JavaScript, tokens,
  // or JSLint results.
  exports.compile_scripts = function compile_scripts() {
    var opts, source;
    if (!((source = this.sources.shift()))) {
      return null;
    }
    opts = this.options;
    return posix.cat(source).addCallback(function(code) {
      var js;
      if (opts.tokens) {
        return puts(coffee.tokenize(code).join(' '));
      }
      js = coffee.compile(code);
      if (opts.run) {
        return eval(js);
      }
      if (opts.print) {
        return puts(js);
      }
      return exports.compile_scripts();
    });
  };
  // Use OptionParser for all the options.
  exports.parse_options = function parse_options() {
    var oparser, opts, paths;
    opts = (this.options = {
    });
    oparser = (this.option_parser = new optparse.OptionParser(SWITCHES));
    oparser.add = oparser['on'];
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
    oparser.add('help', (function(__this) {
      var __func = function() {
        return this.usage();
      };
      return (function() {
        return __func.apply(__this, arguments);
      });
    })(this));
    oparser.add('version', (function(__this) {
      var __func = function() {
        return this.version();
      };
      return (function() {
        return __func.apply(__this, arguments);
      });
    })(this));
    paths = oparser.parse(process.ARGV);
    return this.sources = paths.slice(2, paths.length);
  };
})();