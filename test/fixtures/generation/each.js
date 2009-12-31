(function(){

  // The cornerstone, an each implementation.
  // Handles objects implementing forEach, arrays, and raw objects.
  _.each = function each(obj, iterator, context) {
    var __a, __b, __c, __d, __e, __f, __g, __h, i, index, item, key;
    index = 0;
    try {
      if (obj.forEach) {
        obj.forEach(iterator, context);
      } else if (_.isArray(obj) || _.isArguments(obj)) {
        __a = obj;
        __d = [];
        for (__b=0, __c=__a.length; __b<__c; __b++) {
          item = __a[__b];
          i = __b;
          __d[__b] = iterator.call(context, item, i, obj);
        }
        __d;
      } else {
        __e = _.keys(obj);
        __h = [];
        for (__f=0, __g=__e.length; __f<__g; __f++) {
          key = __e[__f];
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
})();