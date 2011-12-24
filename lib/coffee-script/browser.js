(function() {
  var CoffeeScript, runScripts;

  CoffeeScript = require('./coffee-script');

  CoffeeScript.require = require;

  CoffeeScript.eval = function(code, options) {
    return eval(CoffeeScript.compile(code, options));
  };

  CoffeeScript.run = function(code, options) {
    if (options == null) options = {};
    options.bare = true;
    return Function(CoffeeScript.compile(code, options))();
  };

  if (typeof window === "undefined" || window === null) return;

  CoffeeScript.load = function(url, callback) {
    var xhr;
    xhr = new (window.ActiveXObject || XMLHttpRequest)('Microsoft.XMLHTTP');
    xhr.open('GET', url, true);
    if ('overrideMimeType' in xhr) xhr.overrideMimeType('text/plain');
    xhr.onreadystatechange = function() {
      var options, task, _ref;
      if (xhr.readyState === 4) {
        if ((_ref = xhr.status) === 0 || _ref === 200) {
          options = {};
          task = {
            url: url,
            input: xhr.responseText,
            options: options
          };
          CoffeeScript.run(xhr.responseText, task);
        } else {
          throw new Error("Could not load " + url);
        }
        if (callback) return callback();
      }
    };
    return xhr.send(null);
  };

  runScripts = function() {
    var coffees, execute, index, length, s, scripts;
    scripts = document.getElementsByTagName('script');
    coffees = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = scripts.length; _i < _len; _i++) {
        s = scripts[_i];
        if (s.type === 'text/coffeescript') _results.push(s);
      }
      return _results;
    })();
    index = 0;
    length = coffees.length;
    (execute = function() {
      var options, script, task;
      script = coffees[index++];
      if (script.src) {
        return CoffeeScript.load(script.src, execute);
      } else {
        options = {};
        task = {
          input: script.innerHTML,
          options: options
        };
        CoffeeScript.run(script.innerHTML, task);
        return execute();
      }
    })();
    return null;
  };

  if (window.addEventListener) {
    addEventListener('DOMContentLoaded', runScripts, false);
  } else {
    attachEvent('onload', runScripts);
  }

}).call(this);
