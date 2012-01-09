var __tame_deferrals, __tame_k,
  _this = this;

__tame_k = function() {};

(function(__tame_k) {
  __tame_deferrals = new tame.Deferrals(__tame_k);
  setTimeout(__tame_deferrals.defer({}), 1000);
  __tame_deferrals._fulfill();
})(function() {
  return alert("back after a 1s delay");
});
