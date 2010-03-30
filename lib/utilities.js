(function(){
  var utilities;
  if (!((typeof process !== "undefined" && process !== null))) {
    this.exports = this;
  }
  exports.utilities = (utilities = {
    KEY: "Coffeescript"
  });
  utilities.format = function format(key, tab) {
    return "\n  " + tab + key + ": " + (utilities.functions[key].replace(/\n/g, "\n" + tab + "  ") || 'undefined');
  };
  utilities.dependencies = {
    slice: ['range'],
    splice: ['range'],
    bind: ['aslice']
  };
  utilities.functions = {
    extend: "function(child, parent) {\n  var ctor = function(){ };\n  ctor.prototype = parent.prototype;\n  child.__superClass__ = parent.prototype;\n  child.prototype = new ctor();\n  child.prototype.constructor = child;\n}",
    bind: "function(func, obj, args) {\n  obj = obj || {};\n  return (typeof args !== 'undefined' && args !== null) ? function() {\n    return func.apply(obj, args.concat(" + (utilities.KEY) + ".aslice.call(arguments, 0)));\n  } : function() {\n    return func.apply(obj, arguments);\n  };\n}",
    range: "function(array, from, to, exclusive) {\n  return [\n    (from < 0 ? from + array.length : from || 0),\n    (to < 0 ? to + array.length : to || array.length) + (exclusive ? 0 : 1)\n  ];\n}",
    slice: "function(array, from, to, exclusive) {\n  return array.slice.apply(array, " + (utilities.KEY) + ".range(array, from, to, exclusive));\n}",
    splice: "function(array, from, to, exclusive, replace) {\n  var _a, _r = " + (utilities.KEY) + ".range(array, from, to, exclusive);\n  return array.splice.apply(array, [_a = _r[0], _r[1] - _a].concat(replace));\n}",
    hasProp: "Object.prototype.hasOwnProperty",
    aslice: "Array.prototype.slice"
  };
})();
