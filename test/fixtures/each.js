(function(){
  _.each = function(obj, iterator, context) {
    var index = 0;
    try {
      if (obj.forEach) {
        return obj.forEach(iterator, context);
      }
      if (_.isArray(obj) || _.isArguments(obj)) {
        var a = obj;
        var d = [];
        for (var b=0, c=a.length; b<c; b++) {
          var item = a[b];
          var i = b;
          d[b] = iterator.call(context, item, i, obj);
        }
        return d;
      }
      var e = _.keys(obj);
      for (var f=0, g=e.length; f<g; f++) {
        var key = e[f];
        iterator.call(context, obj[key], key, obj);
      }
    } catch (e) {
      if (e !== breaker) {
        throw e;
      }
    }
    return obj;
  };
})();