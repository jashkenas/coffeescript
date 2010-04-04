(function(){
  var get_source, url;
  var __slice = Array.prototype.slice, __bind = function(func, obj, args) {
    return function() {
      return func.apply(obj || {}, args ? args.concat(__slice.call(arguments, 0)) : arguments);
    };
  };
  url = "documentation/coffee/binding.coffee";
  get_source = __bind(jQuery.get, jQuery, [url]);
  get_source(function(response) {
    return alert(response);
  });
})();
