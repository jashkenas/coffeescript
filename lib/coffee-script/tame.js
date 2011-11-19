(function() {
  var AstTamer;
  var __slice = Array.prototype.slice;

  exports.AstTamer = AstTamer = (function() {

    function AstTamer() {
      var rest;
      rest = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    }

    AstTamer.prototype.transform = function(x) {
      return x.tameTransform();
    };

    return AstTamer;

  })();

}).call(this);
