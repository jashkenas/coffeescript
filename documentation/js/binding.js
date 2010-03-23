(function(){
  var get_source, url;
  url = "documentation/coffee/binding.coffee";
  get_source = (function(func, obj, args) {
    return function() {
      return func.apply(obj, args.concat(Array.prototype.slice.call(arguments, 0)));
    };
  }(jQuery.get, jQuery, [url]));
  get_source(function(response) {
    return alert(response);
  });
})();
