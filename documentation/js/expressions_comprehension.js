(function(){
  var __a, __b, globals, name;
  // The first ten global properties.
  globals = ((function() {
    __b = []; __a = window;
    for (name=0; name<__a.length; name++) {
      property = __a[name];
      __b.push(name);
    }
    return __b;
  })()).slice(0, 10);
})();