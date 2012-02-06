var x, __tame_deferrals,
  _this = this;

__tame_k = function() {};

(function(__tame_k) {
  (function(__tame_k) {
    __tame_deferrals = new tame.Deferrals(__tame_k);
    add(1, 2, __tame_deferrals.defer({
      assign_fn: (function() {
        return function() {
          return __tame_deferrals.ret = arguments[0];
        };
      })()
    }));
    __tame_deferrals._fulfill();
  })(function(___tame_p__5) {
    return (function(__tame_k) {
      __tame_deferrals = new tame.Deferrals(__tame_k);
      add(3, 4, __tame_deferrals.defer({
        assign_fn: (function() {
          return function() {
            return __tame_deferrals.ret = arguments[0];
          };
        })()
      }));
      __tame_deferrals._fulfill();
    })(function(___tame_p__4) {
      __tame_deferrals = new tame.Deferrals(__tame_k);
      add(___tame_p__5, ___tame_p__4, __tame_deferrals.defer({
        assign_fn: (function() {
          return function() {
            return __tame_deferrals.ret = arguments[0];
          };
        })()
      }));
      __tame_deferrals._fulfill();
    });
  });
})(function(___tame_p__3) {
  return x = ___tame_p__3;
});;
