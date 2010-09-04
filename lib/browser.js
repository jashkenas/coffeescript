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
