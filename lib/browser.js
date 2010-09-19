(function() {
  var grind, grindRemote, processScripts;
  if ((typeof document === "undefined" || document === null) ? undefined : document.getElementsByTagName) {
    grind = function(coffee) {
      return setTimeout(exports.compile(coffee));
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
      var _cache, _cache2, _index, script;
      _cache = document.getElementsByTagName('script');
      for (_index = 0, _cache2 = _cache.length; _index < _cache2; _index++) {
        script = _cache[_index];
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
