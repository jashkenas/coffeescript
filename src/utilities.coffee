this.exports: this unless process?
exports.utilities: utilities: { KEY: "Coffeescript" }

utilities.format: (key, tab) -> 
  "\n  $tab$key: ${utilities.functions[key].replace(/\n/g, "\n$tab  ") or 'undefined'}"

utilities.dependencies: {
  slice:  ['range']
  splice: ['range']
  bind:   ['aslice']
}

utilities.functions: {
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
                return func.apply(obj, args.concat(${utilities.KEY}.aslice.call(arguments, 0)));
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
              return array.slice.apply(array, ${utilities.KEY}.range(array, from, to, exclusive));
            }
            """
  splice:   """
            function(array, from, to, exclusive, replace) {
              var _a, _r = ${utilities.KEY}.range(array, from, to, exclusive);
              return array.splice.apply(array, [_a = _r[0], _r[1] - _a].concat(replace));
            }
            """
  
  hasProp:  "Object.prototype.hasOwnProperty"
  aslice:   "Array.prototype.slice"
}