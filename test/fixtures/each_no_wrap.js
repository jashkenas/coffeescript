
// The cornerstone, an each implementation.
// Handles objects implementing forEach, arrays, and raw objects.
_.each = function(obj, iterator, context) {
  var index = 0;
  try {
    if (obj.forEach) {
      obj.forEach(iterator, context);
    } else if (_.isArray(obj) || _.isArguments(obj)) {
      var __a = obj;
      var __d = [];
      for (var __b=0, __c=__a.length; __b<__c; __b++) {
        var item = __a[__b];
        var i = __b;
        __d[__b] = iterator.call(context, item, i, obj);
      }
      __d;
    } else {
      var __e = _.keys(obj);
      var __h = [];
      for (var __f=0, __g=__e.length; __f<__g; __f++) {
        var key = __e[__f];
        __h[__f] = iterator.call(context, obj[key], key, obj);
      }
      __h;
    }
  } catch (e) {
    if (e !== breaker) {
      throw e;
    }
  }
  return obj;
};