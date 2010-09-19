(function() {
  var Scope;
  var __hasProp = Object.prototype.hasOwnProperty;
  if (!(typeof process !== "undefined" && process !== null)) {
    this.exports = this;
  }
  exports.Scope = (function() {
    Scope = function(parent, expressions, method) {
      var _cache, _cache2, k, val;
      _cache = [parent, expressions, method];
      this.parent = _cache[0];
      this.expressions = _cache[1];
      this.method = _cache[2];
      this.variables = {};
      this.tempVars = {
        general: '_a'
      };
      if (this.parent) {
        _cache2 = this.parent.tempVars;
        for (k in _cache2) {
          if (!__hasProp.call(_cache2, k)) continue;
          val = _cache2[k];
          (this.tempVars[k] = val);
        }
      } else {
        Scope.root = this;
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
      var _cache, k, v;
      _cache = this.variables;
      for (v in _cache) {
        if (!__hasProp.call(_cache, v)) continue;
        k = _cache[v];
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
    Scope.prototype.freeVariable = function(type) {
      var next;
      if (type) {
        next = function(prev) {
          return '_' + type + ((prev && Number(prev.match(/\d+$/) || 1) + 1) || '');
        };
      } else {
        type = 'general';
        next = function(prev) {
          var ordinal;
          ordinal = 1 + parseInt(prev.substr(1), 36);
          return '_' + ordinal.toString(36).replace(/\d/g, 'a');
        };
      }
      while (this.check(this.tempVars[type] || (this.tempVars[type] = next()))) {
        this.tempVars[type] = next(this.tempVars[type]);
      }
      this.variables[this.tempVars[type]] = 'var';
      return this.tempVars[type];
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
      var _cache, _result, key, val;
      return (function() {
        _result = []; _cache = this.variables;
        for (key in _cache) {
          if (!__hasProp.call(_cache, key)) continue;
          val = _cache[key];
          if (val === 'var') {
            _result.push(key);
          }
        }
        return _result;
      }).call(this).sort();
    };
    Scope.prototype.assignedVariables = function() {
      var _cache, _result, key, val;
      _result = []; _cache = this.variables;
      for (key in _cache) {
        if (!__hasProp.call(_cache, key)) continue;
        val = _cache[key];
        if (val.assigned) {
          _result.push("" + (key) + " = " + (val.value));
        }
      }
      return _result;
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
