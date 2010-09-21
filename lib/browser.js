(function() {
  var CoffeeScript, processScripts;
  CoffeeScript = require('./coffee-script');
  CoffeeScript.eval = function(code, options) {
    return eval(CoffeeScript.compile(code, options));
  };
  if (!(typeof window !== "undefined" && window !== null)) {
    CoffeeScript.run = function(code, options) {
      return (Function(CoffeeScript.compile(code, options)))();
    };
    return null;
  }
  CoffeeScript.run = function(code, options) {
    return setTimeout(CoffeeScript.compile(code, options));
  };
  CoffeeScript.load = function(url, options) {
    var xhr;
    xhr = new (window.ActiveXObject || XMLHttpRequest)('Microsoft.XMLHTTP');
    xhr.open('GET', url, true);
    if ('overrideMimeType' in xhr) {
      xhr.overrideMimeType('text/plain');
    }
    xhr.onreadystatechange = function() {
      if (xhr.readyState === 4) {
        return CoffeeScript.run(xhr.responseText, options);
      }
    };
    return xhr.send(null);
  };
  processScripts = function() {
    var _i, _len, _ref, script;
    _ref = document.getElementsByTagName('script');
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      script = _ref[_i];
      if (script.type === 'text/coffeescript') {
        if (script.src) {
          CoffeeScript.load(script.src);
        } else {
          CoffeeScript.run(script.innerHTML);
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
}).call(this);
