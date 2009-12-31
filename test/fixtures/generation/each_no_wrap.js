
// The cornerstone, an each implementation.
// Handles objects implementing forEach, arrays, and raw objects.
_.each = function each(obj, iterator, context) {
  var __a, __b, __c, __d, __e, __f, __g, i, index, item, key;
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
          __c = iterator.call(context, item, i, obj);
          __b.push(__c);
        }
      }
      __b;
    } else {
      __d = _.keys(obj);
      __f = [];
      for (__e in __d) {
        if (__d.hasOwnProperty(__e)) {
          key = __d[__e];
          __g = iterator.call(context, obj[key], key, obj);
          __f.push(__g);
        }
      }
      __f;
    }
  } catch (e) {
    if (e !== breaker) {
      throw e;
    }
  }
  return obj;
};