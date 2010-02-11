(function(){
  var compiler, lexer, parser, path;
  process.mixin(require('./nodes'));
  lexer = new (require('./lexer').Lexer)();
  parser = require('./parser').parser;
  // Thin wrapper for Jison compatibility around the real lexer.
  parser.lexer = {
    lex: function lex() {
      var token;
      token = this.tokens[this.pos] || [""];
      this.pos += 1;
      this.yylineno = token[2];
      this.yytext = token[1];
      return token[0];
    },
    setInput: function setInput(tokens) {
      this.tokens = tokens;
      return this.pos = 0;
    },
    upcomingInput: function upcomingInput() {
      return "";
    },
    showPosition: function showPosition() {
      return this.pos;
    }
  };
  exports.VERSION = '0.5.0';
  // Compile CoffeeScript to JavaScript, using the Coffee/Jison compiler.
  exports.compile = function compile(code) {
    var nodes, tokens;
    tokens = lexer.tokenize(code);
    nodes = parser.parse(tokens);
    return nodes.compile();
  };
  //---------- Below this line is obsolete, for the Ruby compiler. ----------------
  // Executes the `coffee` Ruby program to convert from CoffeeScript to JavaScript.
  path = require('path');
  // The path to the CoffeeScript executable.
  compiler = path.normalize(path.dirname(__filename) + '/../../bin/coffee');
  // Compile a string over stdin, with global variables, for the REPL.
  exports.ruby_compile = function ruby_compile(code, callback) {
    var coffee, js;
    js = '';
    coffee = process.createChildProcess(compiler, ['--eval', '--no-wrap', '--globals']);
    coffee.addListener('output', function(results) {
      if ((typeof results !== "undefined" && results !== null)) {
        return js += results;
      }
    });
    coffee.addListener('exit', function() {
      return callback(js);
    });
    coffee.write(code);
    return coffee.close();
  };
  // Compile a list of CoffeeScript files on disk.
  exports.ruby_compile_files = function ruby_compile_files(paths, callback) {
    var coffee, exit_ran, js;
    js = '';
    coffee = process.createChildProcess(compiler, ['--print'].concat(paths));
    coffee.addListener('output', function(results) {
      if ((typeof results !== "undefined" && results !== null)) {
        return js += results;
      }
    });
    // NB: we have to add a mutex to make sure it doesn't get called twice.
    exit_ran = false;
    coffee.addListener('exit', function() {
      if (exit_ran) {
        return null;
      }
      exit_ran = true;
      return callback(js);
    });
    return coffee.addListener('error', function(message) {
      if (!(message)) {
        return null;
      }
      puts(message);
      throw new Error("CoffeeScript compile error");
    });
  };
})();