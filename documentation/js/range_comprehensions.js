(function(){
  var _a, _b, _c, countdown, egg_delivery, num;
  countdown = (function() {
    _a = []; _b = 10; _c = 1;
    for (num = _b; (_b <= _c ? num <= _c : num >= _c); (_b <= _c ? num += 1 : num -= 1)) {
      _a.push(num);
    }
    return _a;
  })();
  egg_delivery = function() {
    var _d, _e, _f, dozen_eggs, i;
    _d = []; _e = 0; _f = eggs.length;
    for (i = _e; (_e <= _f ? i < _f : i > _f); (_e <= _f ? i += 12 : i -= 12)) {
      _d.push((function() {
        dozen_eggs = eggs.slice(i, i + 12);
        return deliver(new egg_carton(dozen));
      })());
    }
    return _d;
  };
})();
