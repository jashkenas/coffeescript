(function() {
  var Scope, extend;
  var __hasProp = Object.prototype.hasOwnProperty;
  extend = require('./helpers').extend;
  exports.Scope = (function() {
    Scope = function(parent, expressions, method) {
      var _ref;
      _ref = [parent, expressions, method], this.parent = _ref[0], this.expressions = _ref[1], this.method = _ref[2];
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
      var _i, _len, _ref, _result, name;
      _result = []; _ref = this.garbage.pop();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        name = _ref[_i];
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
      var _ref, k, v;
      _ref = this.variables;
      for (v in _ref) {
        if (!__hasProp.call(_ref, v)) continue;
        k = _ref[v];
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
      var _ref, _result, key, val;
      return (function() {
        _result = []; _ref = this.variables;
        for (key in _ref) {
          if (!__hasProp.call(_ref, key)) continue;
          val = _ref[key];
          if (val === 'var' || val === 'reuse') {
            _result.push(key);
          }
        }
        return _result;
      }).call(this).sort();
    };
    Scope.prototype.assignedVariables = function() {
      var _ref, _result, key, val;
      _result = []; _ref = this.variables;
      for (key in _ref) {
        if (!__hasProp.call(_ref, key)) continue;
        val = _ref[key];
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
}).call(this);
