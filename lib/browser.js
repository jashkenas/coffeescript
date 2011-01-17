(function() {
  var CoffeeScript, runScripts, scriptQueue, xhrFetchScript;
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
  if (typeof window == "undefined" || window === null) {
    return;
  }
  CoffeeScript.load = function(url, options) {
    return xhrFetchScript(url, function(xhr) {
      if (xhr.readyState === 4) {
        return CoffeeScript.run(xhr.responseText, options);
      }
    });
  };
  xhrFetchScript = function(url, callback) {
    var xhr;
    xhr = new (window.ActiveXObject || XMLHttpRequest)('Microsoft.XMLHTTP');
    xhr.open('GET', url, true);
    if ('overrideMimeType' in xhr) {
      xhr.overrideMimeType('text/plain');
    }
    xhr.onreadystatechange = function() {
      return callback(xhr);
    };
    return xhr.send(null);
  };
  runScripts = function() {
    var script, _i, _len, _ref;
    _ref = document.getElementsByTagName('script');
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      script = _ref[_i];
      if (script.type === 'text/coffeescript') {
        scriptQueue.add(script);
      }
    }
  };
  scriptQueue = {
    pending: [],
    next: 0,
    runReadyScripts: function() {
      var _results;
      _results = [];
      while (this.pending[this.next] != null) {
        _results.push(CoffeeScript.run(this.pending[this.next++]));
      }
      return _results;
    },
    add: function(script) {
      var index;
      if (script.src) {
        index = this.pending.push(null) - 1;
        return xhrFetchScript(script.src, __bind(function(xhr) {
          if (xhr.readyState === 4) {
            this.pending[index] = xhr.responseText;
            return this.runReadyScripts();
          }
        }, this));
      } else {
        this.pending.push(script.innerHTML);
        return this.runReadyScripts();
      }
    }
  };
  if (window.addEventListener) {
    addEventListener('DOMContentLoaded', runScripts, false);
  } else {
    attachEvent('onload', runScripts);
  }
}).call(this);
