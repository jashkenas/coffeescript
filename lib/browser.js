(function() {
  var CoffeeScript, create, document, global, runScripts;
  CoffeeScript = require('./coffee-script');
  CoffeeScript.require = require;
  global = (function() {
    return this;
  })();
  CoffeeScript.eval = function(code, options) {
    return eval(CoffeeScript.compile(code, options));
  };
  CoffeeScript.run = function(code, options) {
    if (options == null) {
      options = {};
    }
    options.bare = true;
    return Function(CoffeeScript.compile(code, options))();
  };
  document = 'document' in global ? global.document : null;
  create = function() {
    throw new Error('`XMLHttpRequest` is not supported.');
  };
  if ('ActiveXObject' in global) {
    create = function() {
      return new global.ActiveXObject('Microsoft.XMLHTTP');
    };
  } else if ('XMLHttpRequest' in global) {
    create = function() {
      return new global.XMLHttpRequest;
    };
  }
  CoffeeScript.load = function(url, options, callback) {
    var xhr;
    xhr = create();
    xhr.open('GET', url, true);
    if ('overrideMimeType' in xhr) {
      xhr.overrideMimeType('text/plain');
    }
    xhr.onreadystatechange = function() {
      var error, result;
      if (xhr.readyState === 4) {
        error = result = null;
        if (xhr.status === 200) {
          try {
            result = CoffeeScript.run(xhr.responseText);
          } catch (exception) {
            error = exception;
          }
        } else {
          error = new Error("An error occurred while loading the script `" + url + "`.");
        }
        return typeof callback === "function" ? callback(error, result) : void 0;
      }
    };
    return xhr.send(null);
  };
  runScripts = function() {
    var execute, index, length, scripts;
    scripts = document.getElementsByTagName('script');
    index = 0;
    length = scripts.length;
    (execute = function(error) {
      var script;
      if (error) {
        throw error;
      }
      script = scripts[index++];
      if (script.type !== 'text/coffeescript') {
        return execute();
      } else {
        if (script.src) {
          return CoffeeScript.load(script.src, null, execute);
        } else {
          CoffeeScript.run(script.innerHTML);
          return execute();
        }
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
