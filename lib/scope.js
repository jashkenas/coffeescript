(function(){
  var Scope;
  var __hasProp = Object.prototype.hasOwnProperty;
  if (!((typeof process !== "undefined" && process !== null))) {
    this.exports = this;
  }
  // Scope objects form a tree corresponding to the shape of the function
  // definitions present in the script. They provide lexical scope, to determine
  // whether a variable has been seen before or if it needs to be declared.
  // Initialize a scope with its parent, for lookups up the chain,
  // as well as the Expressions body where it should declare its variables,
  // and the function that it wraps.
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
    // Look up a variable in lexical scope, or declare it if not found.
    Scope.prototype.find = function find(name) {
      if (this.check(name)) {
        return true;
      }
      this.variables[name] = 'var';
      return false;
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
      var ordinal;
      while (this.check(this.temp_var)) {
        ordinal = 1 + parseInt(this.temp_var.substr(1), 36);
        this.temp_var = '_' + ordinal.toString(36).replace(/\d/g, 'a');
      }
      this.variables[this.temp_var] = 'var';
      return this.temp_var;
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
      var _a, _b, key, val;
      return (function() {
        _a = []; _b = this.variables;
        for (key in _b) { if (__hasProp.call(_b, key)) {
          val = _b[key];
          if (val === 'var') {
            _a.push(key);
          }
        }}
        return _a;
      }).call(this).sort();
    };
    // Return the list of variables that are supposed to be assigned at the top
    // of scope.
    Scope.prototype.assigned_variables = function assigned_variables() {
      var _a, _b, key, val;
      _a = []; _b = this.variables;
      for (key in _b) { if (__hasProp.call(_b, key)) {
        val = _b[key];
        if (val.assigned) {
          _a.push(key + " = " + (val.value));
        }
      }}
      return _a;
    };
    // Compile the string representing all of the declared variables for this scope.
    Scope.prototype.compiled_declarations = function compiled_declarations() {
      return this.declared_variables().join(', ');
    };
    // Compile the string performing all of the variable assignments for this scope.
    Scope.prototype.compiled_assignments = function compiled_assignments() {
      return this.assigned_variables().join(', ');
    };
    return Scope;
  }).call(this);
})();
