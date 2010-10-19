(function() {
  var extend, flatten, indexOf;
  indexOf = (exports.indexOf = Array.indexOf || (Array.prototype.indexOf ? function(array, item, from) {
    return array.indexOf(item, from);
  } : function(array, item, from) {
    var _len, index, other;
    for (index = 0, _len = array.length; index < _len; index++) {
      other = array[index];
      if (other === item && (!from || (from <= index))) {
        return index;
      }
    }
    return -1;
  }));
  exports.include = function(list, value) {
    return indexOf(list, value) >= 0;
  };
  exports.starts = function(string, literal, start) {
    return literal === string.substr(start, literal.length);
  };
  exports.ends = function(string, literal, back) {
    var len;
    len = literal.length;
    return literal === string.substr(string.length - len - (back || 0), len);
  };
  exports.compact = function(array) {
    var _i, _len, _result, item;
    _result = [];
    for (_i = 0, _len = array.length; _i < _len; _i++) {
      item = array[_i];
      if (item) {
        _result.push(item);
      }
    }
    return _result;
  };
  exports.count = function(string, letter) {
    var num, pos;
    num = (pos = 0);
    while (pos = 1 + string.indexOf(letter, pos)) {
      num++;
    }
    return num;
  };
  exports.merge = function(options, overrides) {
    return extend(extend({}, options), overrides);
  };
  extend = (exports.extend = function(object, properties) {
    var key, val;
    for (key in properties) {
      val = properties[key];
      object[key] = val;
    }
    return object;
  });
  exports.flatten = (flatten = function(array) {
    var _i, _len, element, flattened;
    flattened = [];
    for (_i = 0, _len = array.length; _i < _len; _i++) {
      element = array[_i];
      if (element instanceof Array) {
        flattened = flattened.concat(flatten(element));
      } else {
        flattened.push(element);
      }
    }
    return flattened;
  });
  exports.del = function(obj, key) {
    var val;
    val = obj[key];
    delete obj[key];
    return val;
  };
  exports.last = function(array, back) {
    return array[array.length - (back || 0) - 1];
  };
}).call(this);
