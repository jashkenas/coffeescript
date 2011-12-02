(function() {
  var AstTamer, Deferrals, DeferralsMin, makeDeferReturn;
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

  makeDeferReturn = function(obj, defer_args, id) {
    var k, ret, _i, _len, _ref;
    ret = function() {
      var inner_args, _ref;
      inner_args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (defer_args != null) {
        if ((_ref = defer_args.assign_fn) != null) _ref.apply(null, inner_args);
      }
      return obj._fulfill(id);
    };
    if (defer_args) {
      ret.__tame_trace = {};
      _ref = ["parent_cb", "file", "line", "func_name"];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        k = _ref[_i];
        ret.__tame_trace[k] = defer_args[k];
      }
    }
    return ret;
  };

  Deferrals = (function() {

    function Deferrals(k) {
      this.continuation = k;
      this.count = 1;
    }

    Deferrals.prototype._fulfill = function() {
      if (--this.count === 0) return this.continuation();
    };

    Deferrals.prototype.defer = function(args) {
      var self;
      this.count++;
      self = this;
      return makeDeferReturn(self, args, null);
    };

    return Deferrals;

  })();

  DeferralsMin = (function() {

    function DeferralsMin(continuation) {
      this.continuation = continuation;
      this.count = 1;
    }

    DeferralsMin.prototype.defer = function(defer_args) {
      var _this = this;
      this.count++;
      return function() {
        var inner_args, _ref;
        inner_args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        if (defer_args != null) {
          if ((_ref = defer_args.assign_fn) != null) _ref.apply(null, inner_args);
        }
        if (--_this.count === 0) return _this.continuation();
      };
    };

    return DeferralsMin;

  })();

  exports.runtime = {
    Deferrals: Deferrals
  };

}).call(this);
