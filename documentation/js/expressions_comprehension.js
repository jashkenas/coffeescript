(function(){
  var __a, __b, globals, name;
  // The first ten global properties.
  globals = ((function() {
    __b = []; __a = window;
    for (name in __a) {
      if (__a.hasOwnProperty(name)) {
        __b.push(name);
      }
    }
    return __b;
  })()).slice(0, 10);
})();