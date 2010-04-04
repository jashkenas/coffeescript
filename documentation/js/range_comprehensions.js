(function(){
  var _a, _b, _c, _d, countdown, egg_delivery, num;
  countdown = (function() {
    _a = []; _c = 10; _d = 1;
    for (_b = 0, num = _c; (_c <= _d ? num <= _d : num >= _d); (_c <= _d ? num += 1 : num -= 1), _b++) {
      _a.push(num);
    }
    return _a;
  }).call(this);
  egg_delivery = function egg_delivery() {
    var _e, _f, _g, _h, dozen_eggs, i;
    _e = []; _g = 0; _h = eggs.length;
    for (_f = 0, i = _g; (_g <= _h ? i < _h : i > _h); (_g <= _h ? i += 12 : i -= 12), _f++) {
      _e.push((function() {
        dozen_eggs = eggs.slice(i, i + 12);
        return deliver(new egg_carton(dozen));
      }).call(this));
    }
    return _e;
  };
})();
