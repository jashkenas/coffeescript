this.exports: this unless process?

exports.utilities: class utilities
  @key: (name) ->
    "__$name"
  
  @format: (key, tab) ->
    "${utilities.key(key)} = ${utilities.functions[key].replace(/\n/g, "\n$tab") or 'undefined'}"
  
  @dependencies: {
    bind:   ['arraySlice']
    splice: ['range']
  }
  
  @functions: {
    extend:   """
              function(child, parent) {
                var ctor = function(){ };
                ctor.prototype = parent.prototype;
                child.__superClass__ = parent.prototype;
                child.prototype = new ctor();
                child.prototype.constructor = child;
              }
              """
    bind:     """
              function(func, obj, args) {
                obj = obj || {};
                return (typeof args !== 'undefined' && args !== null) ? function() {
                  return func.apply(obj, args.concat(${utilities.key('arraySlice')}.call(arguments, 0)));
                } : function() {
                  return func.apply(obj, arguments);
                };
              }
              """
    range:    """
              function(array, from, to, exclusive) {
                return [
                  (from < 0 ? from + array.length : from || 0),
                  (to < 0 ? to + array.length : to || array.length) + (exclusive ? 0 : 1)
                ];
              }
              """
    hasProp:  'Object.prototype.hasOwnProperty'
    arraySlice: 'Array.prototype.slice'
  }