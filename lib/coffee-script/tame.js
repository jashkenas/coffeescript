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

  exports["const"] = {
    k: "__tame_k",
    ns: "tame",
    Deferrals: "Deferrals",
    deferrals: "__tame_deferrals",
    fulfill: "_fulfill",
    k_while: "_kw",
    b_while: "_break",
    t_while: "_while",
    c_while: "_continue",
    defer_method: "defer",
    slot: "__slot",
    assign_fn: "assign_fn",
    runtime: "tamerun"
  };

}).call(this);
