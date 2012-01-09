var i, __tame_deferrals, _i, _next, _while,
  _this = this;

__tame_k = function() {};

i = 0;
_while = function(__tame_k) {
  var _break, _continue;
  _break = __tame_k;
  _continue = function() {
    ++i;
    return _while(__tame_k);
  };
  _next = _continue;
  if (i <= 3) {
    (function(__tame_k) {
      __tame_deferrals = new tame.Deferrals(__tame_k);
      slowAlert(200, "loop iteration " + i, __tame_deferrals.defer({}));
      __tame_deferrals._fulfill();
    })(_next);
  } else {
    return _break();
  }
};
_while(__tame_k);
