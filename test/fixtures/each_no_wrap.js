
// The cornerstone, an each implementation.
// Handles objects implementing forEach, arrays, and raw objects.
_.each = function(obj, iterator, context) {
  var index = 0;
  try {
    if (obj.forEach) {
      obj.forEach(iterator, context);
    } else if (_.isArray(obj) || _.isArguments(obj)) {
      var a = obj;
      for (var b=0, c=a.length; b<c; b++) {
        var item = a[b];
        var i = b;
        iterator.call(context, item, i, obj);
      }
    } else {
      var d = _.keys(obj);
      for (var e=0, f=d.length; e<f; e++) {
        var key = d[e];
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