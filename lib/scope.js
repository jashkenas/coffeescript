(function() {
  var Scope, _ref, extend, last;
  var __hasProp = Object.prototype.hasOwnProperty;
  _ref = require('./helpers'), extend = _ref.extend, last = _ref.last;
  exports.Scope = (function() {
    Scope = (function() {
      function Scope(_arg, _arg2, _arg3) {
        this.method = _arg3;
        this.expressions = _arg2;
        this.parent = _arg;
        this.variables = {
          'arguments': 'arguments'
        };
        if (this.parent) {
          this.garbage = this.parent.garbage;
        } else {
          this.garbage = [];
          Scope.root = this;
        }
        return this;
      };
      return Scope;
    })();
    Scope.root = null;
    Scope.prototype.startLevel = function() {
      return this.garbage.push([]);
    };
    Scope.prototype.endLevel = function() {
      var _i, _len, _ref2, _result, name, vars;
      vars = this.variables;
      _result = [];
      for (_i = 0, _len = (_ref2 = this.garbage.pop()).length; _i < _len; _i++) {
        name = _ref2[_i];
        if (vars[name] === 'var') {
          _result.push(vars[name] = 'reuse');
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
      for (v in _ref2 = this.variables) {
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
      var _ref2, immediate;
      immediate = Object.prototype.hasOwnProperty.call(this.variables, name);
      if (immediate || ((options != null) ? options.immediate : undefined)) {
        return immediate;
      }
      return !!(((_ref2 = this.parent) != null) ? _ref2.check(name) : undefined);
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
        last(this.garbage).push(temp);
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
        return (val === 'var' || val === 'reuse');
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
        _result = [];
        for (key in _ref2 = this.variables) {
          if (!__hasProp.call(_ref2, key)) continue;
          val = _ref2[key];
          if ((val === 'var' || val === 'reuse')) {
            _result.push(key);
          }
        }
        return _result;
      }).call(this).sort();
    };
    Scope.prototype.assignedVariables = function() {
      var _ref2, _result, key, val;
      _result = [];
      for (key in _ref2 = this.variables) {
        if (!__hasProp.call(_ref2, key)) continue;
        val = _ref2[key];
        if (val.assigned) {
          _result.push("" + key + " = " + (val.value));
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
