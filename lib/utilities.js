(function(){
  if (!((typeof process !== "undefined" && process !== null))) {
    this.exports = this;
  }
  exports.utilities = {
    extend: "function(child, parent) {\n    var ctor = function(){ };\n    ctor.prototype = parent.prototype;\n    child.__superClass__ = parent.prototype;\n    child.prototype = new ctor();\n    child.prototype.constructor = child;\n  }",
    bind: "function(func, obj, args) {\n    return function() {\n      return func.apply(obj || {}, args ? args.concat(__slice.call(arguments, 0)) : arguments);\n    };\n  }",
    range: "function(array, from, to, exclusive) {\n    return [\n      (from < 0 ? from + array.length : from || 0),\n      (to < 0 ? to + array.length : to || array.length) + (exclusive ? 0 : 1)\n    ];\n  }",
    hasProp: 'Object.prototype.hasOwnProperty',
    slice: 'Array.prototype.slice'
  };
})();
