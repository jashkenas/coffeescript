(function(){
  var __a, __b, globals, name;
  // The first ten global properties.
  globals = ((function() {
    __a = []; __b = window;
    for (name in __b) {
      if (__b.hasOwnProperty(name)) {
        __a.push(name);
      }
    }
    return __a;
  })()).slice(0, 10);
})();