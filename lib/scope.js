(function() {
  var Scope, extend, last, _ref;
  _ref = require('./helpers'), extend = _ref.extend, last = _ref.last;
  exports.Scope = (function() {
    Scope = (function() {
      function Scope(_arg, _arg2, _arg3) {
        this.parent = _arg;
        this.expressions = _arg2;
        this.method = _arg3;
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
      }
      return Scope;
    })();
    Scope.root = null;
    Scope.prototype.add = function(name, type) {
      var pos;
      return typeof (pos = this.positions[name]) === 'number' ? this.variables[pos].type = type : this.positions[name] = this.variables.push({
        name: name,
        type: type
      }) - 1;
    };
    Scope.prototype.startLevel = function() {
      this.garbage.push([]);
      return this;
    };
    Scope.prototype.endLevel = function() {
      var name, _i, _len, _ref;
      _ref = this.garbage.pop();
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        name = _ref[_i];
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
      return name.length > 1 ? '_' + name + (index > 1 ? index : '') : '_' + (index + parseInt(name, 36)).toString(36).replace(/\d/g, 'a');
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
      var index, temp, _ref;
      index = 0;
      while (this.check((temp = this.temporary(type, index)), true) && this.type(temp) !== 'reuse') {
        index++;
      }
      this.add(temp, 'var');
      if ((_ref = last(this.garbage)) != null) {
        _ref.push(temp);
      }
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
        var _ref;
        return (_ref = v.type) === 'var' || _ref === 'reuse';
      });
    };
    Scope.prototype.hasAssignments = function(body) {
      return body === this.expressions && this.any(function(v) {
        return v.type.assigned;
      });
    };
    Scope.prototype.declaredVariables = function() {
      var tmp, usr, v, _i, _len, _ref, _ref2;
      usr = [];
      tmp = [];
      _ref = this.variables;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        v = _ref[_i];
        if ((_ref2 = v.type) === 'var' || _ref2 === 'reuse') {
          (v.name.charAt(0) === '_' ? tmp : usr).push(v.name);
        }
      }
      return usr.sort().concat(tmp.sort());
    };
    Scope.prototype.assignedVariables = function() {
      var v, _i, _len, _ref, _result;
      _ref = this.variables;
      _result = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        v = _ref[_i];
        if (v.type.assigned) {
          _result.push("" + v.name + " = " + v.type.value);
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
