(function() {
  var Scope, _ref, extend, last;
  _ref = require('./helpers'), extend = _ref.extend, last = _ref.last;
  exports.Scope = (function() {
    Scope = (function() {
      function Scope(_arg, _arg2, _arg3) {
        this.method = _arg3;
        this.expressions = _arg2;
        this.parent = _arg;
        this.variables = [
          {
            name: 'arguments',
            type: 'arguments'
          }
        ];
        this.positions = {};
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
    Scope.prototype.setVar = function(name, type) {
      if (this.positions.hasOwnProperty(name)) {
        return (this.variables[this.positions[name]].type = type);
      } else {
        this.positions[name] = this.variables.length;
        return this.variables.push({
          name: name,
          type: type
        });
      }
    };
    Scope.prototype.startLevel = function() {
      return this.garbage.push([]);
    };
    Scope.prototype.endLevel = function() {
      var _i, _len, _ref2, _result, garbage, vars;
      vars = this.variables;
      _result = [];
      for (_i = 0, _len = (_ref2 = this.garbage.pop()).length; _i < _len; _i++) {
        garbage = _ref2[_i];
        if (this.type(garbage) === 'var') {
          _result.push(this.setVar(garbage, 'reuse'));
        }
      }
      return _result;
    };
    Scope.prototype.find = function(name, options) {
      if (this.check(name, options)) {
        return true;
      }
      this.setVar(name, 'var');
      return false;
    };
    Scope.prototype.any = function(fn) {
      var _i, _len, _ref2, v;
      for (_i = 0, _len = (_ref2 = this.variables).length; _i < _len; _i++) {
        v = _ref2[_i];
        if (fn(v.name, v.type)) {
          return true;
        }
      }
      return false;
    };
    Scope.prototype.parameter = function(name) {
      return this.setVar(name, 'param');
    };
    Scope.prototype.check = function(name, options) {
      var _ref2, immediate;
      immediate = !!this.type(name);
      if (immediate || ((options != null) ? options.immediate : undefined)) {
        return immediate;
      }
      return !!(((_ref2 = this.parent) != null) ? _ref2.check(name) : undefined);
    };
    Scope.prototype.temporary = function(type, index) {
      return type.length > 1 ? '_' + type + (index > 1 ? index : '') : '_' + (index + parseInt(type, 36)).toString(36).replace(/\d/g, 'a');
    };
    Scope.prototype.type = function(name) {
      var _i, _len, _ref2, v;
      for (_i = 0, _len = (_ref2 = this.variables).length; _i < _len; _i++) {
        v = _ref2[_i];
        if (v.name === name) {
          return v.type;
        }
      }
      return null;
    };
    Scope.prototype.freeVariable = function(type) {
      var index, temp;
      index = 0;
      while (this.check(temp = this.temporary(type, index)) && this.type(temp) !== 'reuse') {
        index++;
      }
      this.setVar(temp, 'var');
      if (this.garbage.length) {
        last(this.garbage).push(temp);
      }
      return temp;
    };
    Scope.prototype.assign = function(name, value) {
      return this.setVar(name, {
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
      var _i, _len, _ref2, _ref3, _result, v;
      return (function() {
        _result = [];
        for (_i = 0, _len = (_ref2 = this.variables).length; _i < _len; _i++) {
          v = _ref2[_i];
          if (((_ref3 = v.type) === 'var' || _ref3 === 'reuse')) {
            _result.push(v.name);
          }
        }
        return _result;
      }).call(this).sort();
    };
    Scope.prototype.assignedVariables = function() {
      var _i, _len, _ref2, _result, v;
      _result = [];
      for (_i = 0, _len = (_ref2 = this.variables).length; _i < _len; _i++) {
        v = _ref2[_i];
        if (v.type.assigned) {
          _result.push("" + (v.name) + " = " + (v.type.value));
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
