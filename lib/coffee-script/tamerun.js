(function() {
  var Deferrals, makeDeferReturn;
  var __slice = Array.prototype.slice;

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

  exports.Deferrals = Deferrals = (function() {

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

}).call(this);
