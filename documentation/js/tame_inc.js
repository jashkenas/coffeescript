var __slice = Array.prototype.slice;

window.tame = {
  Deferrals: (function() {

    function _Class(_arg) {
      this.continuation = _arg;
      this.count = 1;
      this.ret = null;
    }

    _Class.prototype._fulfill = function() {
      if (!--this.count) return this.continuation(this.ret);
    };

    _Class.prototype.defer = function(defer_params) {
      var _this = this;
      ++this.count;
      return function() {
        var inner_params, _ref;
        inner_params = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        if (defer_params != null) {
          if ((_ref = defer_params.assign_fn) != null) {
            _ref.apply(null, inner_params);
          }
        }
        return _this._fulfill();
      };
    };

    return _Class;

  })()
}
window.__tame_k = function() {};
