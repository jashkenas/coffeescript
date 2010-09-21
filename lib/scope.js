(function() {
  var Scope, _ref, extend, helpers;
  var __hasProp = Object.prototype.hasOwnProperty;
  if (typeof process !== "undefined" && process !== null) {
    helpers = require('./helpers').helpers;
  } else {
    this.exports = this;
  }
  _ref = helpers;
  extend = _ref.extend;
  exports.Scope = (function() {
    Scope = function(parent, expressions, method) {
      var _ref2;
      _ref2 = [parent, expressions, method];
      this.parent = _ref2[0];
      this.expressions = _ref2[1];
      this.method = _ref2[2];
      this.variables = {};
      if (this.parent) {
        this.garbage = this.parent.garbage;
      } else {
        this.garbage = [];
        Scope.root = this;
      }
      return this;
    };
    Scope.root = null;
    Scope.prototype.startLevel = function() {
      return this.garbage.push([]);
    };
    Scope.prototype.endLevel = function() {
      var _i, _len, _ref2, _result, name;
      _result = []; _ref2 = this.garbage.pop();
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        name = _ref2[_i];
        if (this.variables[name] === 'var') {
          _result.push(this.variables[name] = 'reuse');
        }
      }
      return _result;
    };
    Scope.prototype.find = function(name, options) {
      if (this.check(name, options)) {
        return true;
      }
      this.variables[name] = 'var';
      return false;
    };
    Scope.prototype.any = function(fn) {
      var _ref2, k, v;
      _ref2 = this.variables;
      for (v in _ref2) {
        if (!__hasProp.call(_ref2, v)) continue;
        k = _ref2[v];
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
    Scope.prototype.temporary = function(type, index) {
      return type.length > 1 ? '_' + type + (index > 1 ? index : '') : '_' + (index + parseInt(type, 36)).toString(36).replace(/\d/g, 'a');
    };
    Scope.prototype.freeVariable = function(type) {
      var index, temp;
      index = 0;
      while (this.check(temp = this.temporary(type, index)) && this.variables[temp] !== 'reuse') {
        index++;
      }
      this.variables[temp] = 'var';
      if (this.garbage.length) {
        this.garbage[this.garbage.length - 1].push(temp);
      }
      return temp;
    };
    Scope.prototype.assign = function(name, value) {
      return (this.variables[name] = {
        value: value,
        assigned: true
      });
    };
    Scope.prototype.hasDeclarations = function(body) {
      return body === this.expressions && this.any(function(k, val) {
        return val === 'var' || val === 'reuse';
      });
    };
    Scope.prototype.hasAssignments = function(body) {
      return body === this.expressions && this.any(function(k, val) {
        return val.assigned;
      });
    };
    Scope.prototype.declaredVariables = function() {
      var _ref2, _result, key, val;
      return (function() {
        _result = []; _ref2 = this.variables;
        for (key in _ref2) {
          if (!__hasProp.call(_ref2, key)) continue;
          val = _ref2[key];
          if (val === 'var' || val === 'reuse') {
            _result.push(key);
          }
        }
        return _result;
      }).call(this).sort();
    };
    Scope.prototype.assignedVariables = function() {
      var _ref2, _result, key, val;
      _result = []; _ref2 = this.variables;
      for (key in _ref2) {
        if (!__hasProp.call(_ref2, key)) continue;
        val = _ref2[key];
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
