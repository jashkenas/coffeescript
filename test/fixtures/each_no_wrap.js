
// The cornerstone, an each implementation.
// Handles objects implementing forEach, arrays, and raw objects.
_.each = function(obj, iterator, context) {
  var index = 0;
  try {
    if (obj.forEach) {
      obj.forEach(iterator, context);
    } else if (_.isArray(obj) || _.isArguments(obj)) {
      var __a = obj;
      for (var __b=0, __c=__a.length; __b<__c; __b++) {
        var item = __a[__b];
        var i = __b;
        iterator.call(context, item, i, obj);
      }
    } else {
      var __d = _.keys(obj);
      for (var __e=0, __f=__d.length; __e<__f; __e++) {
        var key = __d[__e];
        iterator.call(context, obj[key], key, obj);
      }
    }
  } catch (e) {
    if (e !== breaker) {
      throw e;
    }
  }
  return obj;
};