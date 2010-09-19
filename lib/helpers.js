(function() {
  var compact, count, del, ends, extend, flatten, helpers, include, indexOf, merge, starts;
  if (!(typeof process !== "undefined" && process !== null)) {
    this.exports = this;
  }
  helpers = (exports.helpers = {});
  helpers.indexOf = (indexOf = function(array, item, from) {
    var _cache, _cache2, index, other;
    if (array.indexOf) {
      return array.indexOf(item, from);
    }
    _cache = array;
    for (index = 0, _cache2 = _cache.length; index < _cache2; index++) {
      other = _cache[index];
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
    var _cache, _cache2, _index, _result, item;
    _result = []; _cache = array;
    for (_index = 0, _cache2 = _cache.length; _index < _cache2; _index++) {
      item = _cache[_index];
      if (item) {
        _result.push(item);
      }
    }
    return _result;
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
    var _cache, fresh, key, val;
    fresh = {};
    _cache = options;
    for (key in _cache) {
      val = _cache[key];
      (fresh[key] = val);
    }
    if (overrides) {
      _cache = overrides;
      for (key in _cache) {
        val = _cache[key];
        (fresh[key] = val);
      }
    }
    return fresh;
  });
  helpers.extend = (extend = function(object, properties) {
    var _cache, _result, key, val;
    _result = []; _cache = properties;
    for (key in _cache) {
      val = _cache[key];
      _result.push(object[key] = val);
    }
    return _result;
  });
  helpers.flatten = (flatten = function(array) {
    var _cache, _cache2, _index, item, memo;
    memo = [];
    _cache = array;
    for (_index = 0, _cache2 = _cache.length; _index < _cache2; _index++) {
      item = _cache[_index];
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
