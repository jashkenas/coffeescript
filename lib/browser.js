(function() {
  var CoffeeScript, runScripts;
  CoffeeScript = require('./coffee-script');
  CoffeeScript.require = require;
  CoffeeScript.eval = function(code, options) {
    return eval(CoffeeScript.compile(code, options));
  };
  CoffeeScript.run = function(code, options) {
    ((options != null) ? (options.bare = true) : undefined);
    return Function(CoffeeScript.compile(code, options))();
  };
  if (!(typeof window !== "undefined" && window !== null)) {
    return;
  }
  CoffeeScript.load = function(url, options) {
    var xhr;
    xhr = new (window.ActiveXObject || XMLHttpRequest)('Microsoft.XMLHTTP');
    xhr.open('GET', url, true);
    if ('overrideMimeType' in xhr) {
      xhr.overrideMimeType('text/plain');
    }
    xhr.onreadystatechange = function() {
      return xhr.readyState === 4 ? CoffeeScript.run(xhr.responseText, options) : undefined;
    };
    return xhr.send(null);
  };
  runScripts = function() {
    var _i, _j, _len, _ref, script;
    for (_i = 0, _len = (_ref = document.getElementsByTagName('script')).length; _i < _len; _i++) {
      (function() {
        var script = _ref[_i];
        _j = script;
        return script.type === 'text/coffeescript' ? (script.src ? CoffeeScript.load(script.src) : setTimeout(function() {
          return CoffeeScript.run(script.innerHTML);
        })) : undefined;
      })();
      script = _j;
    }
    return null;
  };
  if (window.addEventListener) {
    addEventListener('DOMContentLoaded', runScripts, false);
  } else {
    attachEvent('onload', runScripts);
  }
}).call(this);
