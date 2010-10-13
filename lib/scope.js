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
    Scope.prototype.add = function(name, type) {
      if (this.positions.hasOwnProperty(name)) {
        this.variables[this.positions[name]].type = type;
      } else {
        this.positions[name] = this.variables.push({
          name: name,
          type: type
        }) - 1;
      }
      return this;
    };
    Scope.prototype.startLevel = function() {
      this.garbage.push([]);
      return this;
    };
    Scope.prototype.endLevel = function() {
      var _i, _len, _ref2, name;
      for (_i = 0, _len = (_ref2 = this.garbage.pop()).length; _i < _len; _i++) {
        name = _ref2[_i];
        if (this.type(name) === 'var') {
          this.add(name, 'reuse');
        }
      }
      return this;
    };
    Scope.prototype.find = function(name, options) {
      if (this.check(name, options)) {
        return true;
      }
      this.add(name, 'var');
      return false;
    };
    Scope.prototype.any = function(fn) {
      var _i, _len, _ref2, v;
      for (_i = 0, _len = (_ref2 = this.variables).length; _i < _len; _i++) {
        v = _ref2[_i];
        if (fn(v)) {
          return true;
        }
      }
      return false;
    };
    Scope.prototype.parameter = function(name) {
      return this.add(name, 'param');
    };
    Scope.prototype.check = function(name, options) {
      var _ref2, immediate;
      immediate = !!this.type(name);
      if (immediate || ((options != null) ? options.immediate : undefined)) {
        return immediate;
      }
      return !!(((_ref2 = this.parent) != null) ? _ref2.check(name) : undefined);
    };
    Scope.prototype.temporary = function(name, index) {
      return name.length > 1 ? '_' + name + (index > 1 ? index : '') : '_' + (index + parseInt(name, 36)).toString(36).replace(/\d/g, 'a');
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
      var _ref2, index, temp;
      index = 0;
      while (this.check(temp = this.temporary(type, index)) && this.type(temp) !== 'reuse') {
        index++;
      }
      this.add(temp, 'var');
      (((_ref2 = last(this.garbage)) != null) ? _ref2.push(temp) : undefined);
      return temp;
    };
    Scope.prototype.assign = function(name, value) {
      return this.add(name, {
        value: value,
        assigned: true
      });
    };
    Scope.prototype.hasDeclarations = function(body) {
      return body === this.expressions && this.any(function(v) {
        var _ref2;
        return ((_ref2 = v.type) === 'var' || _ref2 === 'reuse');
      });
    };
    Scope.prototype.hasAssignments = function(body) {
      return body === this.expressions && this.any(function(v) {
        return v.type.assigned;
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
