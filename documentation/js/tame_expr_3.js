var l, r, x, __tame_deferrals,
  _this = this;

__tame_k = function() {};

(function(__tame_k) {
  __tame_deferrals = new tame.Deferrals(__tame_k);
  add(1, 2, __tame_deferrals.defer({
    assign_fn: (function() {
      return function() {
        return l = arguments[0];
      };
    })()
  }));
  __tame_deferrals._fulfill();
})(function() {
  (function(__tame_k) {
    __tame_deferrals = new tame.Deferrals(__tame_k);
    add(3, 4, __tame_deferrals.defer({
      assign_fn: (function() {
        return function() {
          return r = arguments[0];
        };
      })()
    }));
    __tame_deferrals._fulfill();
  })(function() {
    __tame_deferrals = new tame.Deferrals(__tame_k);
    add(l, r, __tame_deferrals.defer({
      assign_fn: (function() {
        return function() {
          return x = arguments[0];
        };
      })()
    }));
    __tame_deferrals._fulfill();
  });
});
