var i, __tame_deferrals, __tame_k, _i;

__tame_k = function() {};

__tame_deferrals = new tame.Deferrals(__tame_k);
for (i = _i = 0; _i <= 3; i = ++_i) {
  slowAlert(200, "loop iteration " + i, __tame_deferrals.defer({}));
}
__tame_deferrals._fulfill();
