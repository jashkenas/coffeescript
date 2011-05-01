(function() {
  var CoffeeScript, document, global, runScripts;
  CoffeeScript = require('./coffee-script');
  CoffeeScript.require = require;
  global = (function() {
    return this;
  })();
  CoffeeScript.eval = function(code, options) {
    if (options == null) {
      options = {};
    }
    return eval(CoffeeScript.compile(code, options));
  };
  CoffeeScript.run = function(code, options, callback) {
    var error;
    if (options == null) {
      options = {};
    }
    if (!('bare' in options)) {
      options.bare = true;
    }
    error = null;
    try {
      Function(CoffeeScript.compile(code, options))();
    } catch (exception) {
      error = exception;
    }
    return typeof callback === "function" ? callback(error) : void 0;
  };
  document = 'document' in global ? global.document : null;
  CoffeeScript.load = function(url, options, callback) {
    var xhr;
    if (options == null) {
      options = {};
    }
    xhr = 'ActiveXObject' in global ? new global.ActiveXObject('Microsoft.XMLHTTP') : 'XMLHttpRequest' in global ? new global.XMLHttpRequest : void 0;
    if (!xhr) {
      throw new Error('`XMLHttpRequest` is not supported.');
    }
    xhr.open('GET', url, true);
    if ('overrideMimeType' in xhr) {
      xhr.overrideMimeType('text/plain');
    }
    xhr.onreadystatechange = function() {
      var code, error, _ref;
      if (xhr.readyState === 4) {
        error = code = null;
        if ((200 <= (_ref = xhr.status) && _ref < 300) || xhr.status === 304) {
          try {
            code = CoffeeScript.compile(xhr.responseText, options);
          } catch (exception) {
            error = exception;
          }
        } else {
          error = new Error("An error occurred while loading the script `" + url + "`.");
        }
        return typeof callback === "function" ? callback(error, code) : void 0;
      }
    };
    return xhr.send(null);
  };
  runScripts = function() {
    var execute, index, length, scripts;
    scripts = document.getElementsByTagName('script');
    index = -1;
    length = scripts.length;
    (execute = function(error) {
      var script;
      if (error) {
        throw error;
      }
      index++;
      if (index === length) {
        return;
      }
      script = scripts[index];
      if (script.type === 'text/coffeescript') {
        if (script.src) {
          return CoffeeScript.load(script.src, null, function(exception, code) {
            if (code) {
              Function(code)();
            }
            return execute(exception);
          });
        } else {
          return CoffeeScript.run(script.innerHTML, null, execute);
        }
      } else {
        return execute();
      }
    })();
    return null;
  };
  if ('addEventListener' in global) {
    global.addEventListener('DOMContentLoaded', runScripts, false);
  } else if ('attachEvent' in global) {
    global.attachEvent('onload', runScripts);
  }
}).call(this);
