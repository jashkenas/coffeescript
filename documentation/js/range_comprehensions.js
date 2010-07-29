var _a, countdown, deliverEggs, num;
countdown = (function() {
  _a = [];
  for (num = 10; num >= 1; num--) {
    _a.push(num);
  }
  return _a;
})();
deliverEggs = function() {
  var _b, _c, dozen, i;
  _b = []; _c = eggs.length;
  for (i = 0; (0 <= _c ? i < _c : i > _c); i += 12) {
    _b.push((function() {
      dozen = eggs.slice(i, i + 12);
      return deliver(new eggCarton(dozen));
    })());
  }
  return _b;
};