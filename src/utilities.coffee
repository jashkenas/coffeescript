this.exports: this unless process?
exports.utilities: utilities: {
  KEY:      "Coffeescript"
  FORMAT:   (key, tab) -> 
    "\n  $tab$key: ${utilities[key].replace(/\n/g, "\n$tab  ") or 'undefined'}"
  
  extend:   '''
            function(child, parent) {
              var ctor = function(){ };
              ctor.prototype = parent.prototype;
              child.__superClass__ = parent.prototype;
              child.prototype = new ctor();
              child.prototype.constructor = child;
            }
            '''
  bind:     '''
            function(func, obj, args) {
              obj = obj || {};
              return (typeof args !== "undefined" && args !== null) ? function() {
                return func.apply(obj, args.concat(Array.prototype.slice.call(arguments, 0)));
              } : function() {
                return func.apply(obj, arguments);
              };
            }
            '''
  hasProp:  "Object.prototype.hasOwnProperty"
}