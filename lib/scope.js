(function() {
  var Scope;
  var __hasProp = Object.prototype.hasOwnProperty;
  if (!(typeof process !== "undefined" && process !== null)) {
    this.exports = this;
  }
  exports.Scope = (function() {
    Scope = function(parent, expressions, method) {
      var _a;
      _a = [parent, expressions, method];
      this.parent = _a[0];
      this.expressions = _a[1];
      this.method = _a[2];
      this.variables = {};
      if (this.parent) {
        this.tempVar = this.parent.tempVar;
      } else {
        Scope.root = this;
        this.tempVar = '_a';
      }
      return this;
    };
    Scope.root = null;
    Scope.prototype.find = function(name, options) {
      if (this.check(name, options)) {
        return true;
      }
      this.variables[name] = 'var';
      return false;
    };
    Scope.prototype.any = function(fn) {
      var _a, k, v;
      _a = this.variables;
      for (v in _a) {
        if (!__hasProp.call(_a, v)) continue;
        k = _a[v];
        if (fn(v, k)) {
          return true;
        }
      }
      return false;
    };
    Scope.prototype.parameter = function(name) {
      return (this.variables[name] = 'param');
    };
    Scope.prototype.check = function(name, options) {
      var immediate;
      immediate = Object.prototype.hasOwnProperty.call(this.variables, name);
      if (immediate || (options && options.immediate)) {
        return immediate;
      }
      return !!(this.parent && this.parent.check(name));
    };
    Scope.prototype.freeVariable = function() {
      var ordinal;
      while (this.check(this.tempVar)) {
        ordinal = 1 + parseInt(this.tempVar.substr(1), 36);
        this.tempVar = '_' + ordinal.toString(36).replace(/\d/g, 'a');
      }
      this.variables[this.tempVar] = 'var';
      return this.tempVar;
    };
    Scope.prototype.assign = function(name, value) {
      return (this.variables[name] = {
        value: value,
        assigned: true
      });
    };
    Scope.prototype.hasDeclarations = function(body) {
      return body === this.expressions && this.any(function(k, val) {
        return val === 'var';
      });
    };
    Scope.prototype.hasAssignments = function(body) {
      return body === this.expressions && this.any(function(k, val) {
        return val.assigned;
      });
    };
    Scope.prototype.declaredVariables = function() {
      var _a, _b, key, val;
      return (function() {
        _a = []; _b = this.variables;
        for (key in _b) {
          if (!__hasProp.call(_b, key)) continue;
          val = _b[key];
          if (val === 'var') {
            _a.push(key);
          }
        }
        return _a;
      }).call(this).sort();
    };
    Scope.prototype.assignedVariables = function() {
      var _a, _b, key, val;
      _a = []; _b = this.variables;
      for (key in _b) {
        if (!__hasProp.call(_b, key)) continue;
        val = _b[key];
        if (val.assigned) {
          _a.push("" + (key) + " = " + (val.value));
        }
      }
      return _a;
    };
    Scope.prototype.compiledDeclarations = function() {
      return this.declaredVariables().join(', ');
    };
    Scope.prototype.compiledAssignments = function() {
      return this.assignedVariables().join(', ');
    };
    return Scope;
  }).call(this);
})();
