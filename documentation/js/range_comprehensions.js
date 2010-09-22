var _result, countdown, deliverEggs, num;
countdown = (function() {
  _result = [];
  for (num = 10; num >= 1; num--) {
    _result.push(num);
  }
  return _result;
})();
deliverEggs = function() {
  var _ref, _result2, dozen, i;
  _result2 = []; _ref = eggs.length;
  for (i = 0; (0 <= _ref ? i < _ref : i > _ref); i += 12) {
    _result2.push((function() {
      dozen = eggs.slice(i, i + 12);
      return deliver(new eggCarton(dozen));
    })());
  }
  return _result2;
};