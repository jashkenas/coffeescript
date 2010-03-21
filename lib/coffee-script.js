(function(){
  var Lexer, compile, helpers, lexer, parser, path, process_scripts;
  // CoffeeScript can be used both on the server, as a command-line compiler based
  // on Node.js/V8, or to run CoffeeScripts directly in the browser. This module
  // contains the main entry functions for tokenzing, parsing, and compiling source
  // CoffeeScript into JavaScript.
  // If included on a webpage, it will automatically sniff out, compile, and
  // execute all scripts present in `text/coffeescript` tags.
  // Set up dependencies correctly for both the server and the browser.
  if ((typeof process !== "undefined" && process !== null)) {
    path = require('path');
    Lexer = require('./lexer').Lexer;
    parser = require('./parser').parser;
    helpers = require('./helpers').helpers;
    helpers.extend(global, require('./nodes'));
    require.registerExtension ? require.registerExtension('.coffee', function(content) {
      return compile(content);
    }) : null;
  } else {
    this.exports = (this.CoffeeScript = {});
    Lexer = this.Lexer;
    parser = this.parser;
    helpers = this.helpers;
  }
  // The current CoffeeScript version number.
  exports.VERSION = '0.5.5';
  // Instantiate a Lexer for our use here.
  lexer = new Lexer();
  // Compile a string of CoffeeScript code to JavaScript, using the Coffee/Jison
  // compiler.
  exports.compile = (compile = function compile(code, options) {
    options = options || {};
    try {
      return (parser.parse(lexer.tokenize(code))).compile(options);
    } catch (err) {
      if (options.source) {
        err.message = "In " + (options.source) + ", " + (err.message);
      }
      throw err;
      return null;
    }
    return null;
  });
  // Tokenize a string of CoffeeScript code, and return the array of tokens.
  exports.tokens = function tokens(code) {
    return lexer.tokenize(code);
  };
  // Tokenize and parse a string of CoffeeScript code, and return the AST. You can
  // then compile it by calling `.compile()` on the root, or traverse it by using
  // `.traverse()` with a callback.
  exports.nodes = function nodes(code) {
    return parser.parse(lexer.tokenize(code));
  };
  // Compile and execute a string of CoffeeScript (on the server), correctly
  // setting `__filename`, `__dirname`, and relative `require()`.
  exports.run = function run(code, options) {
    var __dirname, __filename;
    module.filename = (__filename = options.source);
    __dirname = path.dirname(__filename);
    return eval(exports.compile(code, options));
  };
  // Extend CoffeeScript with a custom language extension. It should hook in to
  // the **Lexer** (as a peer of any of the lexer's tokenizing methods), and
  // push a token on to the stack that contains a **Node** as the value (as a
  // peer of the nodes in [nodes.coffee](nodes.html)).
  exports.extend = function extend(func) {
    return Lexer.extensions.push(func);
  };
  // The real Lexer produces a generic stream of tokens. This object provides a
  // thin wrapper around it, compatible with the Jison API. We can then pass it
  // directly as a "Jison lexer".
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
      this.pos = 0;
      return this.pos;
    },
    upcomingInput: function upcomingInput() {
      return "";
    },
    showPosition: function showPosition() {
      return this.pos;
    }
  };
  // Activate CoffeeScript in the browser by having it compile and evaluate
  // all script tags with a content-type of `text/coffeescript`. This happens
  // on page load. Unfortunately, the text contents of remote scripts cannot be
  // accessed from the browser, so only inline script tags will work.
  if ((typeof document !== "undefined" && document !== null) && document.getElementsByTagName) {
    process_scripts = function process_scripts() {
      var _a, _b, _c, _d, tag;
      _a = []; _b = document.getElementsByTagName('script');
      for (_c = 0, _d = _b.length; _c < _d; _c++) {
        tag = _b[_c];
        tag.type === 'text/coffeescript' ? _a.push(eval(exports.compile(tag.innerHTML))) : null;
      }
      return _a;
      return null;
    };
    if (window.addEventListener) {
      window.addEventListener('load', process_scripts, false);
    } else if (window.attachEvent) {
      window.attachEvent('onload', process_scripts);
    }
  }
})();
