
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
      for (i in __a) {
        if (__a.hasOwnProperty(i)) {
          item = __a[i];
          iterator.call(context, item, i, obj);
        }
      }
    } else {
      __c = _.keys(obj);
      for (__d in __c) {
        if (__c.hasOwnProperty(__d)) {
          key = __c[__d];
          iterator.call(context, obj[key], key, obj);
        }
      }
    }
  } catch (e) {
    if (e !== breaker) {
      throw e;
    }
  }
  return obj;
};