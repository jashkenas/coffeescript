(function(){
  var _a, _b, _c, _d, _e, countdown, egg_delivery, num;
  countdown = (function() {
    _a = []; _d = 10; _e = 1;
    for (_c = 0, num=_d; (_d <= _e ? num <= _e : num >= _e); (_d <= _e ? num += 1 : num -= 1), _c++) {
      _a.push(num);
    }
    return _a;
  }).call(this);
  egg_delivery = function egg_delivery() {
    var _f, _g, _h, _i, _j, dozen_eggs, i;
    _f = []; _i = 0; _j = eggs.length;
    for (_h = 0, i=_i; (_i <= _j ? i < _j : i > _j); (_i <= _j ? i += 12 : i -= 12), _h++) {
      _f.push((function() {
        dozen_eggs = eggs.slice(i, i + 12);
        return deliver(new egg_carton(dozen));
      }).call(this));
    }
    return _f;
  };
})();