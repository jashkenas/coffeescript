(function() {
  var Lexer, compile, grind, grindRemote, helpers, lexer, parser, path, processScripts;
  if (typeof process !== "undefined" && process !== null) {
    path = require('path');
    Lexer = require('./lexer').Lexer;
    parser = require('./parser').parser;
    helpers = require('./helpers').helpers;
    helpers.extend(global, require('./nodes'));
    if (require.registerExtension) {
      require.registerExtension('.coffee', function(content) {
        return compile(content);
      });
    }
  } else {
    this.exports = (this.CoffeeScript = {});
    Lexer = this.Lexer;
    parser = this.parser;
    helpers = this.helpers;
  }
  exports.VERSION = '0.9.1';
  lexer = new Lexer();
  exports.compile = (compile = function(code, options) {
    options || (options = {});
    try {
      return (parser.parse(lexer.tokenize(code))).compile(options);
    } catch (err) {
      if (options.fileName) {
        err.message = ("In " + (options.fileName) + ", " + (err.message));
      }
      throw err;
    }
  });
  exports.tokens = function(code) {
    return lexer.tokenize(code);
  };
  exports.nodes = function(code) {
    return parser.parse(lexer.tokenize(code));
  };
  exports.run = (function(code, options) {
    var __dirname, __filename;
    module.filename = (__filename = options.fileName);
    __dirname = path.dirname(__filename);
    return eval(exports.compile(code, options));
  });
  parser.lexer = {
    lex: function() {
      var token;
      token = this.tokens[this.pos] || [""];
      this.pos += 1;
      this.yylineno = token[2];
      this.yytext = token[1];
      return token[0];
    },
    setInput: function(tokens) {
      this.tokens = tokens;
      return (this.pos = 0);
    },
    upcomingInput: function() {
      return "";
    }
  };
  if ((typeof document === "undefined" || document === null) ? undefined : document.getElementsByTagName) {
    grind = function(coffee) {
      return setTimeout(exports.compile(coffee, {
        noWrap: true
      }));
    };
    grindRemote = function(url) {
      var xhr;
      xhr = new (window.ActiveXObject || XMLHttpRequest)('Microsoft.XMLHTTP');
      xhr.open('GET', url, true);
      if ('overrideMimeType' in xhr) {
        xhr.overrideMimeType('text/plain');
      }
      xhr.onreadystatechange = function() {
        if (xhr.readyState === 4) {
          return grind(xhr.responseText);
        }
      };
      return xhr.send(null);
    };
    processScripts = function() {
      var _a, _b, _c, script;
      _b = document.getElementsByTagName('script');
      for (_a = 0, _c = _b.length; _a < _c; _a++) {
        script = _b[_a];
        if (script.type === 'text/coffeescript') {
          if (script.src) {
            grindRemote(script.src);
          } else {
            grind(script.innerHTML);
          }
        }
      }
      return null;
    };
    if (window.addEventListener) {
      addEventListener('DOMContentLoaded', processScripts, false);
    } else {
      attachEvent('onload', processScripts);
    }
  }
})();
