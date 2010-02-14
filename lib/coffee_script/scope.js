(function(){
  var Scope, succ;
  var __hasProp = Object.prototype.hasOwnProperty;
  if (!((typeof process !== "undefined" && process !== null))) {
    this.exports = this;
  }
  // Scope objects form a tree corresponding to the shape of the function
  // definitions present in the script. They provide lexical scope, to determine
  // whether a variable has been seen before or if it needs to be declared.
  //
  // Initialize a scope with its parent, for lookups up the chain,
  // as well as the Expressions body where it should declare its variables,
  // and the function that it wraps.
  Scope = (exports.Scope = function Scope(parent, expressions, method) {
    this.parent = parent;
    this.expressions = expressions;
    this.method = method;
    this.variables = {};
    this.temp_variable = this.parent ? this.parent.temp_variable : '__a';
    return this;
  });
  // Look up a variable in lexical scope, or declare it if not found.
  Scope.prototype.find = function find(name, remote) {
    var found;
    found = this.check(name);
    if (found || remote) {
      return found;
    }
    this.variables[name] = 'var';
    return found;
  };
  // Define a local variable as originating from a parameter in current scope
  // -- no var required.
  Scope.prototype.parameter = function parameter(name) {
    return this.variables[name] = 'param';
  };
  // Just check to see if a variable has already been declared.
  Scope.prototype.check = function check(name) {
    if (this.variables[name]) {
      return true;
    }
    return !!(this.parent && this.parent.check(name));
  };
  // You can reset a found variable on the immediate scope.
  Scope.prototype.reset = function reset(name) {
    return delete this.variables[name];
  };
  // Find an available, short, name for a compiler-generated variable.
  Scope.prototype.free_variable = function free_variable() {
    while (this.check(this.temp_variable)) {
      ((this.temp_variable = succ(this.temp_variable)));
    }
    this.variables[this.temp_variable] = 'var';
    return this.temp_variable;
  };
  // Ensure that an assignment is made at the top of scope (or top-level
  // scope, if requested).
  Scope.prototype.assign = function assign(name, value, top_level) {
    if (top_level && this.parent) {
      return this.parent.assign(name, value, top_level);
    }
    return this.variables[name] = {
      value: value,
      assigned: true
    };
  };
  // Does this scope reference any variables that need to be declared in the
  // given function body?
  Scope.prototype.has_declarations = function has_declarations(body) {
    return body === this.expressions && this.declared_variables().length;
  };
  // Does this scope reference any assignments that need to be declared at the
  // top of the given function body?
  Scope.prototype.has_assignments = function has_assignments(body) {
    return body === this.expressions && this.assigned_variables().length;
  };
  // Return the list of variables first declared in current scope.
  Scope.prototype.declared_variables = function declared_variables() {
    var __a, __b, key, val;
    return ((function() {
      __a = []; __b = this.variables;
      for (key in __b) if (__hasProp.call(__b, key)) {
        val = __b[key];
        if (val === 'var') {
          __a.push(key);
        }
      }
      return __a;
    }).call(this)).sort();
  };
  // Return the list of variables that are supposed to be assigned at the top
  // of scope.
  Scope.prototype.assigned_variables = function assigned_variables() {
    var __a, __b, key, val;
    return ((function() {
      __a = []; __b = this.variables;
      for (key in __b) if (__hasProp.call(__b, key)) {
        val = __b[key];
        if (val.assigned) {
          __a.push([key, val.value]);
        }
      }
      return __a;
    }).call(this)).sort();
  };
  Scope.prototype.compiled_declarations = function compiled_declarations() {
    return this.declared_variables().join(', ');
  };
  Scope.prototype.compiled_assignments = function compiled_assignments() {
    var __a, __b, __c, t;
    return ((function() {
      __a = []; __b = this.assigned_variables();
      for (__c = 0; __c < __b.length; __c++) {
        t = __b[__c];
        __a.push(t[0] + ' = ' + t[1]);
      }
      return __a;
    }).call(this)).join(', ');
  };
  // Helper functions:
  // The next character alphabetically, to produce the following string.
  succ = function succ(str) {
    return str.slice(0, str.length - 1) + String.fromCharCode(str.charCodeAt(str.length - 1) + 1);
  };
})();