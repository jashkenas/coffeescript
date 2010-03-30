(function(){
  var utilities;
  if (!((typeof process !== "undefined" && process !== null))) {
    this.exports = this;
  }
  exports.utilities = (function() {
    utilities = function utilities() {    };
    utilities.key = function key(name) {
      return "__" + name;
    };
    utilities.format = function format(key, tab) {
      return "" + (utilities.key(key)) + " = " + (utilities.functions[key].replace(/\n/g, "\n" + tab) || 'undefined');
    };
    utilities.dependencies = {
      bind: ['arraySlice'],
      splice: ['range']
    };
    utilities.functions = {
      extend: "function(child, parent) {\n  var ctor = function(){ };\n  ctor.prototype = parent.prototype;\n  child.__superClass__ = parent.prototype;\n  child.prototype = new ctor();\n  child.prototype.constructor = child;\n}",
      bind: "function(func, obj, args) {\n  obj = obj || {};\n  return (typeof args !== 'undefined' && args !== null) ? function() {\n    return func.apply(obj, args.concat(" + (utilities.key('arraySlice')) + ".call(arguments, 0)));\n  } : function() {\n    return func.apply(obj, arguments);\n  };\n}",
      range: "function(array, from, to, exclusive) {\n  return [\n    (from < 0 ? from + array.length : from || 0),\n    (to < 0 ? to + array.length : to || array.length) + (exclusive ? 0 : 1)\n  ];\n}",
      splice: "function(array, from, to, exclusive, replace) {\n  return array.splice.apply(array, [(_a = " + (utilities.key('range')) + "(array, from, to, exclusive))[0], \n    _a[1] - _a[0]].concat(replace));\n}",
      hasProp: 'Object.prototype.hasOwnProperty',
      arraySlice: 'Array.prototype.slice'
    };
    return utilities;
  }).call(this);
})();
