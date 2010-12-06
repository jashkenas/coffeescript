(function() {
  var Scope, extend, last, _ref;
  _ref = require('./helpers'), extend = _ref.extend, last = _ref.last;
  exports.Scope = Scope = function() {
    Scope.root = null;
    function Scope(parent, expressions, method) {
      this.parent = parent;
      this.expressions = expressions;
      this.method = method;
      this.variables = [
        {
          name: 'arguments',
          type: 'arguments'
        }
      ];
      this.positions = {};
      if (!this.parent) {
        Scope.root = this;
      }
    }
    Scope.prototype.add = function(name, type) {
      var pos;
      if (typeof (pos = this.positions[name]) === 'number') {
        return this.variables[pos].type = type;
      } else {
        return this.positions[name] = this.variables.push({
          name: name,
          type: type
        }) - 1;
      }
    };
    Scope.prototype.find = function(name, options) {
      if (this.check(name, options)) {
        return true;
      }
      this.add(name, 'var');
      return false;
    };
    Scope.prototype.any = function(fn) {
      var v, _i, _len, _ref;
      _ref = this.variables;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        v = _ref[_i];
        if (fn(v)) {
          return true;
        }
      }
      return false;
    };
    Scope.prototype.parameter = function(name) {
      if (this.shared && this.check(name, true)) {
        return;
      }
      return this.add(name, 'param');
    };
    Scope.prototype.check = function(name, immediate) {
      var found, _ref;
      found = !!this.type(name);
      if (found || immediate) {
        return found;
      }
      return !!((_ref = this.parent) != null ? _ref.check(name) : void 0);
    };
    Scope.prototype.temporary = function(name, index) {
      if (name.length > 1) {
        return '_' + name + (index > 1 ? index : '');
      } else {
        return '_' + (index + parseInt(name, 36)).toString(36).replace(/\d/g, 'a');
      }
    };
    Scope.prototype.type = function(name) {
      var v, _i, _len, _ref;
      _ref = this.variables;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        v = _ref[_i];
        if (v.name === name) {
          return v.type;
        }
      }
      return null;
    };
    Scope.prototype.freeVariable = function(type) {
      var index, temp;
      index = 0;
      while (this.check((temp = this.temporary(type, index)), true)) {
        index++;
      }
      this.add(temp, 'var');
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
        return v.type === 'var';
      });
    };
    Scope.prototype.hasAssignments = function(body) {
      return body === this.expressions && this.any(function(v) {
        return v.type.assigned;
      });
    };
    Scope.prototype.declaredVariables = function() {
      var tmp, usr, v, _i, _len, _ref;
      usr = [];
      tmp = [];
      _ref = this.variables;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        v = _ref[_i];
        if (v.type === 'var') {
          (v.name.charAt(0) === '_' ? tmp : usr).push(v.name);
        }
      }
      return usr.sort().concat(tmp.sort());
    };
    Scope.prototype.assignedVariables = function() {
      var v, _i, _len, _ref, _results;
      _ref = this.variables;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        v = _ref[_i];
        if (v.type.assigned) {
          _results.push("" + v.name + " = " + v.type.value);
        }
      }
      return _results;
    };
    Scope.prototype.compiledDeclarations = function() {
      return this.declaredVariables().join(', ');
    };
    Scope.prototype.compiledAssignments = function() {
      return this.assignedVariables().join(', ');
    };
    return Scope;
  }();
}).call(this);
