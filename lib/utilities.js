(function(){
  var utilities;
  if (!((typeof process !== "undefined" && process !== null))) {
    this.exports = this;
  }
  exports.utilities = (utilities = {
    KEY: "Coffeescript",
    FORMAT: function FORMAT(key, tab) {
      return "\n  " + tab + key + ": " + (utilities[key].replace(/\n/g, "\n" + tab + "  ") || 'undefined');
    },
    extend: 'function(child, parent) {\n  var ctor = function(){ };\n  ctor.prototype = parent.prototype;\n  child.__superClass__ = parent.prototype;\n  child.prototype = new ctor();\n  child.prototype.constructor = child;\n}',
    bind: 'function(func, obj, args) {\n  obj = obj || {};\n  return (typeof args !== "undefined" && args !== null) ? function() {\n    return func.apply(obj, args.concat(Array.prototype.slice.call(arguments, 0)));\n  } : function() {\n    return func.apply(obj, arguments);\n  };\n}',
    hasProp: "Object.prototype.hasOwnProperty"
  });
})();
