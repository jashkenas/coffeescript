var __tame_deferrals, __tame_k,
  _this = this;

__tame_k = function() {};

window.slowAlert = function(w, s, cb) {
  var __tame_deferrals,
    _this = this;
  (function(__tame_k) {
    __tame_deferrals = new tame.Deferrals(__tame_k);
    setTimeout(__tame_deferrals.defer({}), w);
    __tame_deferrals._fulfill();
  })(function() {
    alert(s);
    return cb();
  });
};

(function(__tame_k) {
  __tame_deferrals = new tame.Deferrals(__tame_k);
  slowAlert(500, "hello", __tame_deferrals.defer({}));
  slowAlert(1000, "friend", __tame_deferrals.defer({}));
  __tame_deferrals._fulfill();
})(function() {
  __tame_deferrals = new tame.Deferrals(__tame_k);
  slowAlert(500, "back after a delay", __tame_deferrals.defer({}));
  __tame_deferrals._fulfill();
});
