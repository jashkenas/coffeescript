(function(){
  var Scope, utilities;
  var __hasProp = Object.prototype.hasOwnProperty;
  // The **Scope** class regulates lexical scoping within CoffeeScript. As you
  // generate code, you create a tree of scopes in the same shape as the nested
  // function bodies. Each scope knows about the variables declared within it,
  // and has a reference to its parent enclosing scope. In this way, we know which
  // variables are new and need to be declared with `var`, and which are shared
  // with the outside.
  // Set up exported variables for both **Node.js** and the browser.
  if (!((typeof process !== "undefined" && process !== null))) {
    this.exports = this;
  }
  utilities = (typeof process !== "undefined" && process !== null) ? require('./utilities').utilities : this.utilities;
  exports.Scope = (function() {
    Scope = function Scope(parent, expressions, method) {
      var _a;
      _a = [parent, expressions, method];
      this.parent = _a[0];
      this.expressions = _a[1];
      this.method = _a[2];
      this.variables = {};
      this.temp_var = this.parent ? this.parent.temp_var : '_a';
      return this;
    };
    // Initialize a scope with its parent, for lookups up the chain,
    // as well as a reference to the **Expressions** node is belongs to, which is
    // where it should declare its variables, and a reference to the function that
    // it wraps.
    // Find the top-most scope object, used for defined global variables
    Scope.prototype.topmost = function topmost() {
      if (this.parent) {
        return this.parent.topmost();
      } else {
        return this;
      }
    };
    // Look up a variable name in lexical scope, and declare it if it does not
    // already exist.
    Scope.prototype.find = function find(name) {
      if (this.check(name)) {
        return true;
      }
      this.variables[name] = 'var';
      return false;
    };
    // Test variables and return true the first time fn(v, k) returns true
    Scope.prototype.any = function any(fn) {
      var _a, k, v;
      _a = this.variables;
      for (v in _a) { if (__hasProp.call(_a, v)) {
        k = _a[v];
        if (fn(v, k)) {
          return true;
        }
      }}
      return false;
    };
    // Reserve a variable name as originating from a function parameter for this
    // scope. No `var` required for internal references.
    Scope.prototype.parameter = function parameter(name) {
      this.variables[name] = 'param';
      return this.variables[name];
    };
    // Just check to see if a variable has already been declared, without reserving.
    Scope.prototype.check = function check(name) {
      if (this.variables[name]) {
        return true;
      }
      return !!(this.parent && this.parent.check(name));
    };
    // If we need to store an intermediate result, find an available name for a
    // compiler-generated variable. `_a`, `_b`, and so on...
    Scope.prototype.free_variable = function free_variable() {
      var ordinal;
      while (this.check(this.temp_var)) {
        ordinal = 1 + parseInt(this.temp_var.substr(1), 36);
        this.temp_var = '_' + ordinal.toString(36).replace(/\d/g, 'a');
      }
      this.variables[this.temp_var] = 'var';
      return this.temp_var;
    };
    // Ensure that an assignment is made at the top of this scope
    // (or at the top-level scope, if requested).
    Scope.prototype.assign = function assign(name, value, top_level) {
      if (top_level) {
        return this.topmost().assign(name, value);
      }
      this.variables[name] = {
        value: value,
        assigned: true
      };
      return this.variables[name];
    };
    // Ensure the CoffeeScript utility object is included in the top level
    // then return a CallNode curried constructor bound to the utility function
    Scope.prototype.utility = function utility(name) {
      var _a, _b, _c, _d, dep;
      if (this.parent) {
        return this.topmost().utility(name);
      }
      if ((typeof (_d = utilities.functions[name]) !== "undefined" && _d !== null)) {
        this.utilities = this.utilities || {};
        this.utilities[name] = utilities.functions[name];
        _b = (utilities.dependencies[name] || []);
        for (_a = 0, _c = _b.length; _a < _c; _a++) {
          dep = _b[_a];
          !this.utilities[dep] ? this.utility(dep) : null;
        }
      }
      return "__" + name;
    };
    // Formats an javascript object containing the utility methods required
    // in the scope
    Scope.prototype.included_utilities = function included_utilities(tab) {
      var _a, _b, _c, key;
      if ((typeof (_c = this.utilities) !== "undefined" && _c !== null)) {
        _a = []; _b = this.utilities;
        for (key in _b) { if (__hasProp.call(_b, key)) {
          _a.push(utilities.format(key, tab));
        }}
        return _a;
      } else {
        return [];
      }
    };
    // Does this scope reference any variables that need to be declared in the
    // given function body?
    Scope.prototype.has_declarations = function has_declarations(body) {
      return body === this.expressions && this.any(function(k, val) {
        return val === 'var';
      });
    };
    // Does this scope reference any assignments that need to be declared at the
    // top of the given function body?
    Scope.prototype.has_assignments = function has_assignments(body) {
      var _a;
      return body === this.expressions && ((typeof (_a = this.utilities) !== "undefined" && _a !== null) || this.any(function(k, val) {
        return val.assigned;
      }));
    };
    // Return the list of variables first declared in this scope.
    Scope.prototype.declared_variables = function declared_variables() {
      var _a, _b, key, val;
      return (function() {
        _a = []; _b = this.variables;
        for (key in _b) { if (__hasProp.call(_b, key)) {
          val = _b[key];
          val === 'var' ? _a.push(key) : null;
        }}
        return _a;
      }).call(this).sort();
    };
    // Return the list of assignments that are supposed to be made at the top
    // of this scope.
    Scope.prototype.assigned_variables = function assigned_variables() {
      var _a, _b, key, val;
      _a = []; _b = this.variables;
      for (key in _b) { if (__hasProp.call(_b, key)) {
        val = _b[key];
        val.assigned ? _a.push("" + key + " = " + (val.value)) : null;
      }}
      return _a;
    };
    // Compile the JavaScript for all of the variable declarations in this scope.
    Scope.prototype.compiled_declarations = function compiled_declarations() {
      return this.declared_variables().join(', ');
    };
    // Compile the JavaScript for all of the variable assignments in this scope.
    Scope.prototype.compiled_assignments = function compiled_assignments(tab) {
      return this.assigned_variables().concat(this.included_utilities(tab)).join(', ');
    };
    return Scope;
  }).call(this);
})();
