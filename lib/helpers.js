(function() {
  var extend, helpers, indexOf;
  helpers = (exports.helpers = {});
  indexOf = (helpers.indexOf = Array.indexOf || (Array.prototype.indexOf ? function(array, item, from) {
    return array.indexOf(item, from);
  } : function(array, item, from) {
    var _len, _ref, index, other;
    _ref = array;
    for (index = 0, _len = _ref.length; index < _len; index++) {
      other = _ref[index];
      if (other === item && (!from || (from <= index))) {
        return index;
      }
    }
    return -1;
  }));
  helpers.include = function(list, value) {
    return 0 <= indexOf(list, value);
  };
  helpers.starts = function(string, literal, start) {
    return literal === string.substr(start, literal.length);
  };
  helpers.ends = function(string, literal, back) {
    var ll;
    ll = literal.length;
    return literal === string.substr(string.length - ll - (back || 0), ll);
  };
  helpers.compact = function(array) {
    var _i, _len, _ref, _result, item;
    _result = []; _ref = array;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      item = _ref[_i];
      if (item) {
        _result.push(item);
      }
    }
    return _result;
  };
  helpers.count = function(string, letter) {
    var num, pos;
    num = (pos = 0);
    while (0 < (pos = 1 + string.indexOf(letter, pos))) {
      num++;
    }
    return num;
  };
  helpers.merge = function(options, overrides) {
    return extend(extend({}, options), overrides);
  };
  extend = (helpers.extend = function(object, properties) {
    var _ref, key, val;
    _ref = properties;
    for (key in _ref) {
      val = _ref[key];
      (object[key] = val);
    }
    return object;
  });
  helpers.flatten = function(array) {
    return array.concat.apply([], array);
  };
  helpers.del = function(obj, key) {
    var val;
    val = obj[key];
    delete obj[key];
    return val;
  };
}).call(this);
