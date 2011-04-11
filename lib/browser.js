(function() {
  var CoffeeScript, create, document, runScripts;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  CoffeeScript = require('./coffee-script');
  CoffeeScript.require = require;
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
  document = typeof this.document !== 'undefined' ? document : null;
  create = function() {
    throw new Error('`XMLHttpRequest` is not supported.');
  };
  if (typeof this.ActiveXObject !== 'undefined') {
    create = __bind(function() {
      return new this.ActiveXObject('Microsoft.XMLHTTP');
    }, this);
  } else if (typeof this.XMLHttpRequest !== 'undefined') {
    create = __bind(function() {
      return new this.XMLHttpRequest;
    }, this);
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
          } catch (error) {
            error = exception;
          }
        } else {
          error = new Error("An error occurred while loading the script `" + url + "`.");
        }
        return typeof callback == "function" ? callback(error, result) : void 0;
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
      if (script.type === 'text/coffeescript' && script.src) {
        return CoffeeScript.load(script.src, null, execute);
      } else {
        CoffeeScript.run(script.innerHTML);
        return execute();
      }
    })();
    return null;
  };
  if (typeof this.addEventListener !== 'undefined') {
    this.addEventListener('DOMContentLoaded', runScripts, false);
  } else if (typeof this.attachEvent !== 'undefined') {
    this.attachEvent('onload', runScripts);
  }
}).call(this);
