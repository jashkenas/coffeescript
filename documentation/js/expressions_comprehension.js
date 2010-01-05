(function(){
  var __a, __b, __c, globals, name, property;
  // The first ten global properties.
  globals = ((function() {
    __a = window;
    __b = [];
    for (name in __a) {
      if (__a.hasOwnProperty(name)) {
        property = __a[name];
        __c = name;
        __b.push(__c);
      }
    }
    return __b;
  })()).slice(0, 10);
})();