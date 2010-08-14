(function() {
  var compact, count, del, ends, extend, flatten, helpers, include, indexOf, merge, starts;
  if (!(typeof process !== "undefined" && process !== null)) {
    this.exports = this;
  }
  helpers = (exports.helpers = {});
  helpers.indexOf = (indexOf = function(array, item, from) {
    var _a, _b, index, other;
    if (array.indexOf) {
      return array.indexOf(item, from);
    }
    _a = array;
    for (index = 0, _b = _a.length; index < _b; index++) {
      other = _a[index];
      if (other === item && (!from || (from <= index))) {
        return index;
      }
    }
    return -1;
  });
  helpers.include = (include = function(list, value) {
    return indexOf(list, value) >= 0;
  });
  helpers.starts = (starts = function(string, literal, start) {
    return string.substring(start, (start || 0) + literal.length) === literal;
  });
  helpers.ends = (ends = function(string, literal, back) {
    var start;
    start = string.length - literal.length - ((typeof back !== "undefined" && back !== null) ? back : 0);
    return string.substring(start, start + literal.length) === literal;
  });
  helpers.compact = (compact = function(array) {
    var _a, _b, _c, _d, item;
    _a = []; _c = array;
    for (_b = 0, _d = _c.length; _b < _d; _b++) {
      item = _c[_b];
      if (item) {
        _a.push(item);
      }
    }
    return _a;
  });
  helpers.count = (count = function(string, letter) {
    var num, pos;
    num = 0;
    pos = indexOf(string, letter);
    while (pos !== -1) {
      num += 1;
      pos = indexOf(string, letter, pos + 1);
    }
    return num;
  });
  helpers.merge = (merge = function(options, overrides) {
    var _a, _b, fresh, key, val;
    fresh = {};
    _a = options;
    for (key in _a) {
      val = _a[key];
      (fresh[key] = val);
    }
    if (overrides) {
      _b = overrides;
      for (key in _b) {
        val = _b[key];
        (fresh[key] = val);
      }
    }
    return fresh;
  });
  helpers.extend = (extend = function(object, properties) {
    var _a, _b, key, val;
    _a = []; _b = properties;
    for (key in _b) {
      val = _b[key];
      _a.push(object[key] = val);
    }
    return _a;
  });
  helpers.flatten = (flatten = function(array) {
    var _a, _b, _c, item, memo;
    memo = [];
    _b = array;
    for (_a = 0, _c = _b.length; _a < _c; _a++) {
      item = _b[_a];
      if (item instanceof Array) {
        memo = memo.concat(item);
      } else {
        memo.push(item);
      }
    }
    return memo;
  });
  helpers.del = (del = function(obj, key) {
    var val;
    val = obj[key];
    delete obj[key];
    return val;
  });
})();
