(function(){
  var __a, __b, globals, name;
  var __hasProp = Object.prototype.hasOwnProperty;
  // The first ten global properties.
  globals = ((function() {
    __a = []; __b = window;
    for (name in __b) {
      if (__hasProp.call(__b, name)) {
        __a.push(name);
      }
    }
    return __a;
  }).call(this)).slice(0, 10);
})();