(function() {
  var CoffeeScript, processScripts;
  CoffeeScript = require('./coffee-script');
  CoffeeScript.eval = function(code, options) {
    return eval(CoffeeScript.compile(code, options));
  };
  CoffeeScript.run = function(code, options) {
    return (Function(CoffeeScript.compile(code, options)))();
  };
  if (!(typeof window !== "undefined" && window !== null)) {
    return null;
  }
  CoffeeScript.load = function(url, options) {
    var xhr;
    xhr = new (window.ActiveXObject || XMLHttpRequest)('Microsoft.XMLHTTP');
    xhr.open('GET', url, true);
    if ('overrideMimeType' in xhr) {
      xhr.overrideMimeType('text/plain');
    }
    xhr.onreadystatechange = function() {
      return xhr.readyState === 4 ? CoffeeScript.run(xhr.responseText, options) : null;
    };
    return xhr.send(null);
  };
  processScripts = function() {
    var _i, _len, _ref;
    _ref = document.getElementsByTagName('script');
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      (function() {
        var script = _ref[_i];
        return script.type === 'text/coffeescript' ? (script.src ? CoffeeScript.load(script.src) : setTimeout(function() {
          return CoffeeScript.run(script.innerHTML);
        })) : null;
      })();
    }
    return null;
  };
  if (window.addEventListener) {
    addEventListener('DOMContentLoaded', processScripts, false);
  } else {
    attachEvent('onload', processScripts);
  }
}).call(this);
