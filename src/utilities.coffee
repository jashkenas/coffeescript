this.exports: this unless process?

exports.utilities: class utilities
  @key: (name) ->
    "__$name"
  
  @format: (key, tab) ->
    "${utilities.key(key)} = ${utilities.functions[key].replace(/\n/g, "\n$tab") or 'undefined'}"
  
  @dependencies: {
    slice:  ['range']
    splice: ['range']
    bind:   ['arraySlice']
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
    slice:    """
              function(array, from, to, exclusive) {
                return array.slice.apply(array, ${utilities.key('range')}(array, from, to, exclusive));
              }
              """
    splice:   """
              function(array, from, to, exclusive, replace) {
                return array.splice.apply(array, [(_a = ${utilities.key('range')}(array, from, to, exclusive))[0], 
                  _a[1] - _a[0]].concat(replace));
              }
              """
    hasProp:  'Object.prototype.hasOwnProperty'
    arraySlice: 'Array.prototype.slice'
  }