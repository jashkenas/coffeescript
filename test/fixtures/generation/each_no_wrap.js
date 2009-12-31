
// The cornerstone, an each implementation.
// Handles objects implementing forEach, arrays, and raw objects.
_.each = function each(obj, iterator, context) {
  var __a, __b, __c, __d, __e, i, index, item, key;
  index = 0;
  try {
    if (obj.forEach) {
      obj.forEach(iterator, context);
    } else if (_.isArray(obj) || _.isArguments(obj)) {
      __a = obj;
      __b = [];
      for (i in __a) {
        if (__a.hasOwnProperty(i)) {
          item = __a[i];
          __b.push(iterator.call(context, item, i, obj));
        }
      }
      __b;
    } else {
      __c = _.keys(obj);
      __e = [];
      for (__d in __c) {
        if (__c.hasOwnProperty(__d)) {
          key = __c[__d];
          __e.push(iterator.call(context, obj[key], key, obj));
        }
      }
      __e;
    }
  } catch (e) {
    if (e !== breaker) {
      throw e;
    }
  }
  return obj;
};