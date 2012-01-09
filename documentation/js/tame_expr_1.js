var x, __tame_deferrals,
  _this = this;

__tame_k = function() {};

window.add = function(a, b, cb) {
  var __tame_deferrals,
    _this = this;
  (function(__tame_k) {
    __tame_deferrals = new tame.Deferrals(__tame_k);
    setTimeout(__tame_deferrals.defer({}), 10);
    __tame_deferrals._fulfill();
  })(function() {
    return cb(a + b);
  });
};

(function(__tame_k) {
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
  })(function(___tame_p__2) {
    return (function(__tame_k) {
      __tame_deferrals = new tame.Deferrals(__tame_k);
      add(1, 2, __tame_deferrals.defer({
        assign_fn: (function() {
          return function() {
            return __tame_deferrals.ret = arguments[0];
          };
        })()
      }));
      __tame_deferrals._fulfill();
    })(function(___tame_p__1) {
      return __tame_k(___tame_p__2 + ___tame_p__1);
    });
  });
})(function(___tame_p__0) {
  x = ___tame_p__0;
  return alert("" + x + " is 10");
});;
