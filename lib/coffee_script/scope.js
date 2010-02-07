(function(){
  var dup;
  var __hasProp = Object.prototype.hasOwnProperty;
  dup = function dup(input) {
    var __a, __b, __c, key, output, val;
    output = null;
    if (input instanceof Array) {
      output = [];
      __a = input;
      for (__b = 0; __b < __a.length; __b++) {
        val = __a[__b];
        output.push(val);
      }
    } else {
      output = {
      };
      __c = input;
      for (key in __c) {
        val = __c[key];
        if (__hasProp.call(__c, key)) {
          output.key = val;
        }
      }
      output;
    }
    return output;
  };
  // scope objects form a tree corresponding to the shape of the function
  // definitions present in the script. They provide lexical scope, to determine
  // whether a variable has been seen before or if it needs to be declared.
  exports.Scope = function Scope(parent, expressions, func) {
    var __a;
    // Initialize a scope with its parent, for lookups up the chain,
    // as well as the Expressions body where it should declare its variables,
    // and the function that it wraps.
    this.parent = parent;
    this.expressions = expressions;
    this.function = func;
    this.variables = {
    };
    __a = this.temp_variable = this.parent ? dup(this.parent.temp_variable) : '__a';
    return Scope === this.constructor ? this : __a;
  };
  // Look up a variable in lexical scope, or declare it if not found.
  exports.Scope.prototype.find = function find(name, rem) {
    var found, remote;
    remote = (typeof rem !== "undefined" && rem !== null) ? rem : false;
    found = this.check(name);
    if (found || remote) {
      return found;
    }
    this.variables[name] = 'var';
    return found;
  };
  // Define a local variable as originating from a parameter in current scope
  // -- no var required.
  exports.Scope.prototype.parameter = function parameter(name) {
    return this.variables[name] = 'param';
  };
  // Just check to see if a variable has already been declared.
  exports.Scope.prototype.check = function check(name) {
    if ((typeof this.variables[name] !== "undefined" && this.variables[name] !== null)) {
      return true;
    }
    // TODO: what does that ruby !! mean..? need to follow up
    // .. this next line is prolly wrong ..
    return !!(this.parent && this.parent.check(name));
  };
  // You can reset a found variable on the immediate scope.
  exports.Scope.prototype.reset = function reset(name) {
    return this.variables[name] = undefined;
  };
})();