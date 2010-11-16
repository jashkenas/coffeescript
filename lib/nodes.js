(function() {
  var Accessor, Arr, Assign, Base, Call, Class, Closure, Code, Comment, Existence, Expressions, Extends, For, IDENTIFIER, IS_STRING, If, In, Index, LEVEL_ACCESS, LEVEL_COND, LEVEL_LIST, LEVEL_OP, LEVEL_PAREN, LEVEL_TOP, Literal, NEGATE, NO, NUMBER, Obj, Op, Param, Parens, Push, Return, SIMPLENUM, Scope, Splat, Switch, TAB, THIS, TRAILING_WHITESPACE, Throw, Try, UTILITIES, Value, While, YES, compact, del, ends, extend, flatten, last, merge, multident, starts, unfoldSoak, utility, _ref;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    for (var key in parent) if (__hasProp.call(parent, key)) child[key] = parent[key];
    child.__super__ = parent.prototype;
    return child;
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  Scope = require('./scope').Scope;
  _ref = require('./helpers'), compact = _ref.compact, flatten = _ref.flatten, extend = _ref.extend, merge = _ref.merge, del = _ref.del, starts = _ref.starts, ends = _ref.ends, last = _ref.last;
  exports.extend = extend;
  YES = function() {
    return true;
  };
  NO = function() {
    return false;
  };
  THIS = function() {
    return this;
  };
  NEGATE = function() {
    this.negated = !this.negated;
    return this;
  };
  exports.Base = Base = function() {
    function Base() {}
    Base.prototype.compile = function(o, lvl) {
      var node;
      o = extend({}, o);
      if (lvl) {
        o.level = lvl;
      }
      node = this.unfoldSoak(o) || this;
      node.tab = o.indent;
      if (o.level === LEVEL_TOP || node.isPureStatement() || !node.isStatement(o)) {
        return node.compileNode(o);
      } else {
        return node.compileClosure(o);
      }
    };
    Base.prototype.compileClosure = function(o) {
      if (this.containsPureStatement()) {
        throw SyntaxError('cannot include a pure statement in an expression.');
      }
      o.sharedScope = o.scope;
      return Closure.wrap(this).compileNode(o);
    };
    Base.prototype.cache = function(o, level, reused) {
      var ref, sub;
      if (!this.isComplex()) {
        ref = level ? this.compile(o, level) : this;
        return [ref, ref];
      } else {
        ref = new Literal(reused || o.scope.freeVariable('ref'));
        sub = new Assign(ref, this);
        if (level) {
          return [sub.compile(o, level), ref.value];
        } else {
          return [sub, ref];
        }
      }
    };
    Base.prototype.compileLoopReference = function(o, name) {
      var src, tmp;
      src = tmp = this.compile(o, LEVEL_LIST);
      if (!(NUMBER.test(src) || IDENTIFIER.test(src) && o.scope.check(src, true))) {
        src = "" + (tmp = o.scope.freeVariable(name)) + " = " + src;
      }
      return [src, tmp];
    };
    Base.prototype.makeReturn = function() {
      return new Return(this);
    };
    Base.prototype.contains = function(pred) {
      var contains;
      contains = false;
      this.traverseChildren(false, function(node) {
        if (pred(node)) {
          contains = true;
          return false;
        }
      });
      return contains;
    };
    Base.prototype.containsType = function(type) {
      return this instanceof type || this.contains(function(node) {
        return node instanceof type;
      });
    };
    Base.prototype.containsPureStatement = function() {
      return this.isPureStatement() || this.contains(function(node) {
        return node.isPureStatement();
      });
    };
    Base.prototype.toString = function(idt, name) {
      var tree;
      idt == null && (idt = '');
      name == null && (name = this.constructor.name);
      tree = '\n' + idt + name;
      if (this.soak) {
        tree += '?';
      }
      this.eachChild(function(node) {
        return tree += node.toString(idt + TAB);
      });
      return tree;
    };
    Base.prototype.eachChild = function(func) {
      var attr, child, _i, _j, _len, _len2, _ref, _ref2;
      if (!this.children) {
        return this;
      }
      _ref = this.children;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        attr = _ref[_i];
        if (this[attr]) {
          _ref2 = flatten([this[attr]]);
          for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
            child = _ref2[_j];
            if (func(child) === false) {
              return this;
            }
          }
        }
      }
      return this;
    };
    Base.prototype.traverseChildren = function(crossScope, func) {
      return this.eachChild(function(child) {
        if (func(child) === false) {
          return false;
        }
        return child.traverseChildren(crossScope, func);
      });
    };
    Base.prototype.invert = function() {
      return new Op('!', this);
    };
    Base.prototype.unwrapAll = function() {
      var node;
      node = this;
      while (node !== (node = node.unwrap())) {
        continue;
      }
      return node;
    };
    Base.prototype.children = [];
    Base.prototype.isStatement = NO;
    Base.prototype.isPureStatement = NO;
    Base.prototype.isComplex = YES;
    Base.prototype.isChainable = NO;
    Base.prototype.isAssignable = NO;
    Base.prototype.unwrap = THIS;
    Base.prototype.unfoldSoak = NO;
    Base.prototype.assigns = NO;
    return Base;
  }();
  exports.Expressions = Expressions = function() {
    function Expressions(nodes) {
      this.expressions = compact(flatten(nodes || []));
    }
    __extends(Expressions, Base);
    Expressions.prototype.children = ['expressions'];
    Expressions.prototype.push = function(node) {
      this.expressions.push(node);
      return this;
    };
    Expressions.prototype.pop = function() {
      return this.expressions.pop();
    };
    Expressions.prototype.unshift = function(node) {
      this.expressions.unshift(node);
      return this;
    };
    Expressions.prototype.unwrap = function() {
      if (this.expressions.length === 1) {
        return this.expressions[0];
      } else {
        return this;
      }
    };
    Expressions.prototype.isEmpty = function() {
      return !this.expressions.length;
    };
    Expressions.prototype.isStatement = function(o) {
      var exp, _i, _len, _ref;
      _ref = this.expressions;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        exp = _ref[_i];
        if (exp.isPureStatement() || exp.isStatement(o)) {
          return true;
        }
      }
      return false;
    };
    Expressions.prototype.makeReturn = function() {
      var end, idx, _ref;
      _ref = this.expressions;
      for (idx = _ref.length - 1; idx >= 0; idx--) {
        end = _ref[idx];
        if (!(end instanceof Comment)) {
          this.expressions[idx] = end.makeReturn();
          break;
        }
      }
      return this;
    };
    Expressions.prototype.compile = function(o, level) {
      o == null && (o = {});
      if (o.scope) {
        return Expressions.__super__.compile.call(this, o, level);
      } else {
        return this.compileRoot(o);
      }
    };
    Expressions.prototype.compileNode = function(o) {
      var code, codes, node, top, _i, _len, _ref;
      this.tab = o.indent;
      top = o.level === LEVEL_TOP;
      codes = [];
      _ref = this.expressions;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        node = _ref[_i];
        node = node.unwrapAll();
        node = node.unfoldSoak(o) || node;
        if (top) {
          node.front = true;
          code = node.compile(o);
          codes.push(node.isStatement(o) ? code : this.tab + code + ';');
        } else {
          codes.push(node.compile(o, LEVEL_LIST));
        }
      }
      if (top) {
        return codes.join('\n');
      }
      code = codes.join(', ') || 'void 0';
      if (codes.length > 1 && o.level >= LEVEL_LIST) {
        return "(" + code + ")";
      } else {
        return code;
      }
    };
    Expressions.prototype.compileRoot = function(o) {
      var code;
      o.indent = this.tab = o.bare ? '' : TAB;
      o.scope = new Scope(null, this, null);
      o.level = LEVEL_TOP;
      code = this.compileWithDeclarations(o);
      code = code.replace(TRAILING_WHITESPACE, '');
      if (o.bare) {
        return code;
      } else {
        return "(function() {\n" + code + "\n}).call(this);\n";
      }
    };
    Expressions.prototype.compileWithDeclarations = function(o) {
      var code, exp, i, post, rest, scope, _len, _ref;
      code = post = '';
      _ref = this.expressions;
      for (i = 0, _len = _ref.length; i < _len; i++) {
        exp = _ref[i];
        exp = exp.unwrap();
        if (!(exp instanceof Comment || exp instanceof Literal)) {
          break;
        }
      }
      o.level = LEVEL_TOP;
      if (i) {
        rest = this.expressions.splice(i, this.expressions.length);
        code = this.compileNode(o);
        this.expressions = rest;
      }
      post = this.compileNode(o);
      scope = o.scope;
      if (!o.globals && o.scope.hasDeclarations(this)) {
        code += "" + this.tab + "var " + (scope.compiledDeclarations()) + ";\n";
      }
      if (scope.hasAssignments(this)) {
        code += "" + this.tab + "var " + (multident(scope.compiledAssignments(), this.tab)) + ";\n";
      }
      return code + post;
    };
    Expressions.wrap = function(nodes) {
      if (nodes.length === 1 && nodes[0] instanceof Expressions) {
        return nodes[0];
      }
      return new Expressions(nodes);
    };
    return Expressions;
  }();
  exports.Literal = Literal = function() {
    function Literal(_arg) {
      this.value = _arg;
    }
    __extends(Literal, Base);
    Literal.prototype.makeReturn = function() {
      if (this.isPureStatement()) {
        return this;
      } else {
        return new Return(this);
      }
    };
    Literal.prototype.isPureStatement = function() {
      var _ref;
      return (_ref = this.value) === 'break' || _ref === 'continue' || _ref === 'debugger';
    };
    Literal.prototype.isAssignable = function() {
      return IDENTIFIER.test(this.value);
    };
    Literal.prototype.isComplex = NO;
    Literal.prototype.assigns = function(name) {
      return name === this.value;
    };
    Literal.prototype.compile = function() {
      if (this.value.reserved) {
        return "\"" + this.value + "\"";
      } else {
        return this.value;
      }
    };
    Literal.prototype.toString = function() {
      return ' "' + this.value + '"';
    };
    return Literal;
  }();
  exports.Return = Return = function() {
    function Return(_arg) {
      this.expression = _arg;
    }
    __extends(Return, Base);
    Return.prototype.children = ['expression'];
    Return.prototype.isStatement = YES;
    Return.prototype.isPureStatement = YES;
    Return.prototype.makeReturn = THIS;
    Return.prototype.compile = function(o, level) {
      var expr, _ref;
      expr = (_ref = this.expression) != null ? _ref.makeReturn() : void 0;
      if (expr && !(expr instanceof Return)) {
        return expr.compile(o, level);
      } else {
        return Return.__super__.compile.call(this, o, level);
      }
    };
    Return.prototype.compileNode = function(o) {
      o.level = LEVEL_PAREN;
      return this.tab + ("return" + (this.expression ? ' ' + this.expression.compile(o) : '') + ";");
    };
    return Return;
  }();
  exports.Value = Value = function() {
    function Value(base, props, tag) {
      if (!props && base instanceof Value) {
        return base;
      }
      this.base = base;
      this.properties = props || [];
      if (tag) {
        this[tag] = true;
      }
    }
    __extends(Value, Base);
    Value.prototype.children = ['base', 'properties'];
    Value.prototype.push = function(prop) {
      this.properties.push(prop);
      return this;
    };
    Value.prototype.hasProperties = function() {
      return !!this.properties.length;
    };
    Value.prototype.isArray = function() {
      return !this.properties.length && this.base instanceof Arr;
    };
    Value.prototype.isComplex = function() {
      return this.hasProperties() || this.base.isComplex();
    };
    Value.prototype.isAssignable = function() {
      return this.hasProperties() || this.base.isAssignable();
    };
    Value.prototype.isSimpleNumber = function() {
      return this.base instanceof Literal && SIMPLENUM.test(this.base.value);
    };
    Value.prototype.isAtomic = function() {
      var node, _i, _len, _ref;
      _ref = this.properties.concat(this.base);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        node = _ref[_i];
        if (node.soak || node instanceof Call) {
          return false;
        }
      }
      return true;
    };
    Value.prototype.isStatement = function(o) {
      return !this.properties.length && this.base.isStatement(o);
    };
    Value.prototype.assigns = function(name) {
      return !this.properties.length && this.base.assigns(name);
    };
    Value.prototype.isObject = function(onlyGenerated) {
      if (this.properties.length) {
        return false;
      }
      return (this.base instanceof Obj) && (!onlyGenerated || this.base.generated);
    };
    Value.prototype.makeReturn = function() {
      if (this.properties.length) {
        return Value.__super__.makeReturn.call(this);
      } else {
        return this.base.makeReturn();
      }
    };
    Value.prototype.unwrap = function() {
      if (this.properties.length) {
        return this;
      } else {
        return this.base;
      }
    };
    Value.prototype.cacheReference = function(o) {
      var base, bref, name, nref;
      name = last(this.properties);
      if (this.properties.length < 2 && !this.base.isComplex() && !(name != null ? name.isComplex() : void 0)) {
        return [this, this];
      }
      base = new Value(this.base, this.properties.slice(0, -1));
      if (base.isComplex()) {
        bref = new Literal(o.scope.freeVariable('base'));
        base = new Value(new Parens(new Assign(bref, base)));
      }
      if (!name) {
        return [base, bref];
      }
      if (name.isComplex()) {
        nref = new Literal(o.scope.freeVariable('name'));
        name = new Index(new Assign(nref, name.index));
        nref = new Index(nref);
      }
      return [base.push(name), new Value(bref || base.base, [nref || name])];
    };
    Value.prototype.compileNode = function(o) {
      var code, prop, props, _i, _len;
      this.base.front = this.front;
      props = this.properties;
      code = this.base.compile(o, props.length ? LEVEL_ACCESS : null);
      if (props[0] instanceof Accessor && this.isSimpleNumber()) {
        code = "(" + code + ")";
      }
      for (_i = 0, _len = props.length; _i < _len; _i++) {
        prop = props[_i];
        code += prop.compile(o);
      }
      return code;
    };
    Value.prototype.unfoldSoak = function(o) {
      var fst, i, ifn, prop, ref, snd, _len, _ref;
      if (ifn = this.base.unfoldSoak(o)) {
        Array.prototype.push.apply(ifn.body.properties, this.properties);
        return ifn;
      }
      _ref = this.properties;
      for (i = 0, _len = _ref.length; i < _len; i++) {
        prop = _ref[i];
        if (prop.soak) {
          prop.soak = false;
          fst = new Value(this.base, this.properties.slice(0, i));
          snd = new Value(this.base, this.properties.slice(i));
          if (fst.isComplex()) {
            ref = new Literal(o.scope.freeVariable('ref'));
            fst = new Parens(new Assign(ref, fst));
            snd.base = ref;
          }
          return new If(new Existence(fst), snd, {
            soak: true
          });
        }
      }
      return null;
    };
    return Value;
  }();
  exports.Comment = Comment = function() {
    function Comment(_arg) {
      this.comment = _arg;
    }
    __extends(Comment, Base);
    Comment.prototype.isPureStatement = YES;
    Comment.prototype.isStatement = YES;
    Comment.prototype.makeReturn = THIS;
    Comment.prototype.compileNode = function(o, level) {
      var code;
      code = '/*' + multident(this.comment, this.tab) + '*/';
      if ((level || o.level) === LEVEL_TOP) {
        code = o.indent + code;
      }
      return code;
    };
    return Comment;
  }();
  exports.Call = Call = function() {
    function Call(variable, _arg, _arg2) {
      this.args = _arg != null ? _arg : [];
      this.soak = _arg2;
      this.isNew = false;
      this.isSuper = variable === 'super';
      this.variable = this.isSuper ? null : variable;
    }
    __extends(Call, Base);
    Call.prototype.children = ['variable', 'args'];
    Call.prototype.newInstance = function() {
      this.isNew = true;
      return this;
    };
    Call.prototype.superReference = function(o) {
      var method, name;
      method = o.scope.method;
      if (!method) {
        throw SyntaxError('cannot call super outside of a function.');
      }
      name = method.name;
      if (!name) {
        throw SyntaxError('cannot call super on an anonymous function.');
      }
      if (method.klass) {
        return "" + method.klass + ".__super__." + name;
      } else {
        return "" + name + ".__super__.constructor";
      }
    };
    Call.prototype.unfoldSoak = function(o) {
      var call, ifn, left, list, rite, _i, _len, _ref, _ref2;
      if (this.soak) {
        if (this.variable) {
          if (ifn = unfoldSoak(o, this, 'variable')) {
            return ifn;
          }
          _ref = new Value(this.variable).cacheReference(o), left = _ref[0], rite = _ref[1];
        } else {
          left = new Literal(this.superReference(o));
          rite = new Value(left);
        }
        rite = new Call(rite, this.args);
        rite.isNew = this.isNew;
        left = new Literal("typeof " + (left.compile(o)) + " === \"function\"");
        return new If(left, new Value(rite), {
          soak: true
        });
      }
      call = this;
      list = [];
      while (true) {
        if (call.variable instanceof Call) {
          list.push(call);
          call = call.variable;
          continue;
        }
        if (!(call.variable instanceof Value)) {
          break;
        }
        list.push(call);
        if (!((call = call.variable.base) instanceof Call)) {
          break;
        }
      }
      _ref2 = list.reverse();
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        call = _ref2[_i];
        if (ifn) {
          if (call.variable instanceof Call) {
            call.variable = ifn;
          } else {
            call.variable.base = ifn;
          }
        }
        ifn = unfoldSoak(o, call, 'variable');
      }
      return ifn;
    };
    Call.prototype.compileNode = function(o) {
      var arg, args, code, _i, _len, _ref, _ref2, _results;
      if ((_ref = this.variable) != null) {
        _ref.front = this.front;
      }
      if (code = Splat.compileSplattedArray(o, this.args, true)) {
        return this.compileSplat(o, code);
      }
      args = ((function() {
        _ref2 = this.args;
        _results = [];
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          arg = _ref2[_i];
          _results.push(arg.compile(o, LEVEL_LIST));
        }
        return _results;
      }).call(this)).join(', ');
      if (this.isSuper) {
        return this.compileSuper(args, o);
      } else {
        return (this.isNew ? 'new ' : '') + this.variable.compile(o, LEVEL_ACCESS) + ("(" + args + ")");
      }
    };
    Call.prototype.compileSuper = function(args, o) {
      return "" + (this.superReference(o)) + ".call(this" + (args.length ? ', ' : '') + args + ")";
    };
    Call.prototype.compileSplat = function(o, splatArgs) {
      var base, fun, idt, name, ref;
      if (this.isSuper) {
        return "" + (this.superReference(o)) + ".apply(this, " + splatArgs + ")";
      }
      if (!this.isNew) {
        base = new Value(this.variable);
        if ((name = base.properties.pop()) && base.isComplex()) {
          ref = o.scope.freeVariable('this');
          fun = "(" + ref + " = " + (base.compile(o, LEVEL_LIST)) + ")" + (name.compile(o));
        } else {
          fun = ref = base.compile(o, LEVEL_ACCESS);
          if (name) {
            fun += name.compile(o);
          }
        }
        return "" + fun + ".apply(" + ref + ", " + splatArgs + ")";
      }
      idt = this.tab + TAB;
      return "(function(func, args, ctor) {\n" + idt + "ctor.prototype = func.prototype;\n" + idt + "var child = new ctor, result = func.apply(child, args);\n" + idt + "return typeof result === \"object\" ? result : child;\n" + this.tab + "})(" + (this.variable.compile(o, LEVEL_LIST)) + ", " + splatArgs + ", function() {})";
    };
    return Call;
  }();
  exports.Extends = Extends = function() {
    function Extends(_arg, _arg2) {
      this.child = _arg;
      this.parent = _arg2;
    }
    __extends(Extends, Base);
    Extends.prototype.children = ['child', 'parent'];
    Extends.prototype.compile = function(o) {
      utility('hasProp');
      return new Call(new Value(new Literal(utility('extends'))), [this.child, this.parent]).compile(o);
    };
    return Extends;
  }();
  exports.Accessor = Accessor = function() {
    function Accessor(_arg, tag) {
      this.name = _arg;
      this.proto = tag === 'proto' ? '.prototype' : '';
      this.soak = tag === 'soak';
    }
    __extends(Accessor, Base);
    Accessor.prototype.children = ['name'];
    Accessor.prototype.compile = function(o) {
      var name;
      name = this.name.compile(o);
      return this.proto + (IS_STRING.test(name) ? "[" + name + "]" : "." + name);
    };
    Accessor.prototype.isComplex = NO;
    return Accessor;
  }();
  exports.Index = Index = function() {
    function Index(_arg) {
      this.index = _arg;
    }
    __extends(Index, Base);
    Index.prototype.children = ['index'];
    Index.prototype.compile = function(o) {
      return (this.proto ? '.prototype' : '') + ("[" + (this.index.compile(o, LEVEL_PAREN)) + "]");
    };
    Index.prototype.isComplex = function() {
      return this.index.isComplex();
    };
    return Index;
  }();
  exports.Obj = Obj = function() {
    function Obj(props, _arg) {
      this.generated = _arg != null ? _arg : false;
      this.objects = this.properties = props || [];
    }
    __extends(Obj, Base);
    Obj.prototype.children = ['properties'];
    Obj.prototype.compileNode = function(o) {
      var i, idt, indent, join, lastNoncom, nonComments, obj, prop, props, rest, _i, _len, _len2, _len3, _ref, _results, _results2;
      props = this.properties;
      if (!props.length) {
        if (this.front) {
          return '({})';
        } else {
          return '{}';
        }
      }
      for (i = 0, _len = props.length; i < _len; i++) {
        prop = props[i];
        if (prop instanceof Splat || (prop.variable || prop).base instanceof Parens) {
          rest = props.splice(i, 1 / 0);
          break;
        }
      }
      idt = o.indent += TAB;
      nonComments = ((function() {
        _ref = this.properties;
        _results = [];
        for (_i = 0, _len2 = _ref.length; _i < _len2; _i++) {
          prop = _ref[_i];
          if (!(prop instanceof Comment)) {
            _results.push(prop);
          }
        }
        return _results;
      }).call(this));
      lastNoncom = last(nonComments);
      props = (function() {
        _results2 = [];
        for (i = 0, _len3 = props.length; i < _len3; i++) {
          prop = props[i];
          join = i === props.length - 1 ? '' : prop === lastNoncom || prop instanceof Comment ? '\n' : ',\n';
          indent = prop instanceof Comment ? '' : idt;
          if (prop instanceof Value && prop["this"]) {
            prop = new Assign(prop.properties[0].name, prop, 'object');
          } else if (!(prop instanceof Assign) && !(prop instanceof Comment)) {
            prop = new Assign(prop, prop, 'object');
          }
          _results2.push(indent + prop.compile(o, LEVEL_TOP) + join);
        }
        return _results2;
      })();
      props = props.join('');
      obj = "{" + (props && '\n' + props + '\n' + this.tab) + "}";
      if (rest) {
        return this.compileDynamic(o, obj, rest);
      }
      if (this.front) {
        return "(" + obj + ")";
      } else {
        return obj;
      }
    };
    Obj.prototype.compileDynamic = function(o, code, props) {
      var acc, i, key, oref, prop, ref, val, _len, _ref;
      code = "" + (oref = o.scope.freeVariable('obj')) + " = " + code + ", ";
      for (i = 0, _len = props.length; i < _len; i++) {
        prop = props[i];
        if (prop instanceof Comment) {
          code += prop.compile(o, LEVEL_LIST) + ' ';
          continue;
        }
        if (prop instanceof Assign) {
          acc = prop.variable.base;
          key = acc.compile(o, LEVEL_PAREN);
          val = prop.value.compile(o, LEVEL_LIST);
        } else {
          acc = prop.base;
          _ref = acc.cache(o, LEVEL_LIST, ref), key = _ref[0], val = _ref[1];
          if (key !== val) {
            ref = val;
          }
        }
        key = acc instanceof Literal && IDENTIFIER.test(key) ? '.' + key : '[' + key + ']';
        code += "" + oref + key + " = " + val + ", ";
      }
      code += oref;
      if (o.level <= LEVEL_PAREN) {
        return code;
      } else {
        return "(" + code + ")";
      }
    };
    Obj.prototype.assigns = function(name) {
      var prop, _i, _len, _ref;
      _ref = this.properties;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        prop = _ref[_i];
        if (prop.assigns(name)) {
          return true;
        }
      }
      return false;
    };
    return Obj;
  }();
  exports.Arr = Arr = function() {
    function Arr(objs) {
      this.objects = objs || [];
    }
    __extends(Arr, Base);
    Arr.prototype.children = ['objects'];
    Arr.prototype.compileNode = function(o) {
      var code, obj, _i, _len, _ref, _results;
      if (!this.objects.length) {
        return '[]';
      }
      o.indent += TAB;
      if (code = Splat.compileSplattedArray(o, this.objects)) {
        return code;
      }
      code = ((function() {
        _ref = this.objects;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          obj = _ref[_i];
          _results.push(obj.compile(o, LEVEL_LIST));
        }
        return _results;
      }).call(this)).join(', ');
      if (code.indexOf('\n') >= 0) {
        return "[\n" + o.indent + code + "\n" + this.tab + "]";
      } else {
        return "[" + code + "]";
      }
    };
    Arr.prototype.assigns = function(name) {
      var obj, _i, _len, _ref;
      _ref = this.objects;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        obj = _ref[_i];
        if (obj.assigns(name)) {
          return true;
        }
      }
      return false;
    };
    return Arr;
  }();
  exports.Class = Class = function() {
    function Class(_arg, _arg2, _arg3) {
      this.variable = _arg;
      this.parent = _arg2;
      this.body = _arg3 != null ? _arg3 : new Expressions;
      this.boundFuncs = [];
    }
    __extends(Class, Base);
    Class.prototype.children = ['variable', 'parent', 'body'];
    Class.prototype.determineName = function() {
      var decl, tail;
      if (!this.variable) {
        return null;
      }
      decl = (tail = last(this.variable.properties)) ? tail instanceof Accessor && tail.name.value : this.variable.base.value;
      return decl && (decl = IDENTIFIER.test(decl) && decl);
    };
    Class.prototype.setContext = function(name) {
      return this.body.traverseChildren(false, function(node) {
        if (node instanceof Literal && node.value === 'this') {
          return node.value = name;
        } else if (node instanceof Code) {
          node.klass = name;
          if (node.bound) {
            return node.context = name;
          }
        }
      });
    };
    Class.prototype.addBoundFunctions = function(o) {
      var bname, bvar, _i, _len, _ref, _results;
      if (this.boundFuncs.length) {
        _ref = this.boundFuncs;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          bvar = _ref[_i];
          bname = bvar.compile(o);
          _results.push(this.ctor.body.unshift(new Literal("this." + bname + " = " + (utility('bind')) + "(this." + bname + ", this);")));
        }
        return _results;
      }
    };
    Class.prototype.addProperties = function(node, name) {
      var assign, base, func, props, _results;
      props = node.base.properties.slice(0);
      _results = [];
      while (assign = props.shift()) {
        if (assign instanceof Assign) {
          base = assign.variable.base;
          delete assign.context;
          func = assign.value;
          if (base.value === 'constructor') {
            if (this.ctor) {
              throw new Error('cannot define more than one constructor in a class');
            }
            if (func.bound) {
              throw new Error('cannot define a constructor as a bound function');
            }
            if (func instanceof Code) {
              this.ctor = func;
            } else {
              this.ctor = new Assign(new Value(new Literal(name)), func);
            }
            assign = null;
          } else {
            if (!assign.variable["this"]) {
              assign.variable = new Value(new Literal(name), [new Accessor(base, 'proto')]);
            }
            if (func instanceof Code && func.bound) {
              this.boundFuncs.push(base);
              func.bound = false;
            }
          }
        }
        _results.push(assign);
      }
      return _results;
    };
    Class.prototype.walkBody = function(name) {
      return this.traverseChildren(false, __bind(function(child) {
        var exps, i, node, _len, _ref;
        if (child instanceof Expressions) {
          _ref = exps = child.expressions;
          for (i = 0, _len = _ref.length; i < _len; i++) {
            node = _ref[i];
            if (node instanceof Value && node.isObject(true)) {
              exps[i] = compact(this.addProperties(node, name));
            }
          }
          return child.expressions = exps = compact(flatten(exps));
        }
      }, this));
    };
    Class.prototype.ensureConstructor = function(name) {
      if (!this.ctor) {
        this.ctor = new Code;
        if (this.parent) {
          this.ctor.body.push(new Call('super', [new Splat(new Literal('arguments'))]));
        }
      }
      this.ctor.ctor = this.ctor.name = name;
      this.ctor.klass = null;
      return this.ctor.noReturn = true;
    };
    Class.prototype.compileNode = function(o) {
      var decl, klass, lname, name, _ref;
      decl = this.determineName();
      name = decl || this.name || '_Class';
      lname = new Literal(name);
      this.setContext(name);
      this.walkBody(name);
      this.ensureConstructor(name);
      if (this.parent) {
        this.body.expressions.unshift(new Extends(lname, this.parent));
      }
      this.body.expressions.unshift(this.ctor);
      this.body.expressions.push(lname);
      this.addBoundFunctions(o);
      klass = new Parens(new Call(new Code([], this.body)), true);
      if (decl && ((_ref = this.variable) != null ? _ref.isComplex() : void 0)) {
        klass = new Assign(new Value(lname), klass);
      }
      if (this.variable) {
        klass = new Assign(this.variable, klass);
      }
      return klass.compile(o);
    };
    return Class;
  }();
  exports.Assign = Assign = function() {
    function Assign(_arg, _arg2, _arg3) {
      this.variable = _arg;
      this.value = _arg2;
      this.context = _arg3;
    }
    __extends(Assign, Base);
    Assign.prototype.METHOD_DEF = /^(?:(\S+)\.prototype\.|\S+?)?\b([$A-Za-z_][$\w]*)$/;
    Assign.prototype.children = ['variable', 'value'];
    Assign.prototype.assigns = function(name) {
      return this[this.context === 'object' ? 'value' : 'variable'].assigns(name);
    };
    Assign.prototype.unfoldSoak = function(o) {
      return unfoldSoak(o, this, 'variable');
    };
    Assign.prototype.compileNode = function(o) {
      var isValue, match, name, val, _ref;
      if (isValue = this.variable instanceof Value) {
        if (this.variable.isArray() || this.variable.isObject()) {
          return this.compilePatternMatch(o);
        }
        if ((_ref = this.context) === '||=' || _ref === '&&=' || _ref === '?=') {
          return this.compileConditional(o);
        }
      }
      name = this.variable.compile(o, LEVEL_LIST);
      if (this.value instanceof Code && (match = this.METHOD_DEF.exec(name))) {
        this.value.name = match[2];
        if (match[1]) {
          this.value.klass = match[1];
        }
      }
      val = this.value.compile(o, LEVEL_LIST);
      if (this.context === 'object') {
        return "" + name + ": " + val;
      }
      if (!this.variable.isAssignable()) {
        throw SyntaxError("\"" + (this.variable.compile(o)) + "\" cannot be assigned.");
      }
      if (!(this.context || isValue && (this.variable.namespaced || this.variable.hasProperties()))) {
        o.scope.find(name);
      }
      val = name + (" " + (this.context || '=') + " ") + val;
      if (o.level <= LEVEL_LIST) {
        return val;
      } else {
        return "(" + val + ")";
      }
    };
    Assign.prototype.compilePatternMatch = function(o) {
      var acc, assigns, code, i, idx, isObject, ivar, obj, objects, olen, ref, rest, splat, top, val, value, vvar, _len, _ref, _ref2, _ref3, _ref4;
      top = o.level === LEVEL_TOP;
      value = this.value;
      objects = this.variable.base.objects;
      if (!(olen = objects.length)) {
        return value.compile(o);
      }
      isObject = this.variable.isObject();
      if (top && olen === 1 && !((obj = objects[0]) instanceof Splat)) {
        if (obj instanceof Assign) {
          _ref = obj, idx = _ref.variable.base, obj = _ref.value;
        } else {
          if (obj.base instanceof Parens) {
            _ref2 = new Value(obj.unwrapAll()).cacheReference(o), obj = _ref2[0], idx = _ref2[1];
          } else {
            idx = isObject ? obj["this"] ? obj.properties[0].name : obj : new Literal(0);
          }
        }
        acc = IDENTIFIER.test(idx.unwrap().value || 0);
        value = new Value(value);
        value.properties.push(new (acc ? Accessor : Index)(idx));
        return new Assign(obj, value).compile(o);
      }
      vvar = value.compile(o, LEVEL_LIST);
      assigns = [];
      splat = false;
      if (!IDENTIFIER.test(vvar) || this.variable.assigns(vvar)) {
        assigns.push("" + (ref = o.scope.freeVariable('ref')) + " = " + vvar);
        vvar = ref;
      }
      for (i = 0, _len = objects.length; i < _len; i++) {
        obj = objects[i];
        idx = i;
        if (isObject) {
          if (obj instanceof Assign) {
            _ref3 = obj, idx = _ref3.variable.base, obj = _ref3.value;
          } else {
            if (obj.base instanceof Parens) {
              _ref4 = new Value(obj.unwrapAll()).cacheReference(o), obj = _ref4[0], idx = _ref4[1];
            } else {
              idx = obj["this"] ? obj.properties[0].name : obj;
            }
          }
        }
        if (!splat && obj instanceof Splat) {
          val = "" + olen + " <= " + vvar + ".length ? " + (utility('slice')) + ".call(" + vvar + ", " + i;
          if (rest = olen - i - 1) {
            ivar = o.scope.freeVariable('i');
            val += ", " + ivar + " = " + vvar + ".length - " + rest + ") : (" + ivar + " = " + i + ", [])";
          } else {
            val += ") : []";
          }
          val = new Literal(val);
          splat = "" + ivar + "++";
        } else {
          if (obj instanceof Splat) {
            obj = obj.name.compile(o);
            throw SyntaxError("multiple splats are disallowed in an assignment: " + obj + " ...");
          }
          if (typeof idx === 'number') {
            idx = new Literal(splat || idx);
            acc = false;
          } else {
            acc = isObject && IDENTIFIER.test(idx.unwrap().value || 0);
          }
          val = new Value(new Literal(vvar), [new (acc ? Accessor : Index)(idx)]);
        }
        assigns.push(new Assign(obj, val).compile(o, LEVEL_TOP));
      }
      if (!top) {
        assigns.push(vvar);
      }
      code = assigns.join(', ');
      if (o.level < LEVEL_LIST) {
        return code;
      } else {
        return "(" + code + ")";
      }
    };
    Assign.prototype.compileConditional = function(o) {
      var left, rite, _ref;
      _ref = this.variable.cacheReference(o), left = _ref[0], rite = _ref[1];
      return new Op(this.context.slice(0, -1), left, new Assign(rite, this.value, '=')).compile(o);
    };
    return Assign;
  }();
  exports.Code = Code = function() {
    function Code(params, body, tag) {
      this.params = params || [];
      this.body = body || new Expressions;
      this.bound = tag === 'boundfunc';
      if (this.bound) {
        this.context = 'this';
      }
    }
    __extends(Code, Base);
    Code.prototype.children = ['params', 'body'];
    Code.prototype.isStatement = function() {
      return !!this.ctor;
    };
    Code.prototype.compileNode = function(o) {
      var code, exprs, i, idt, lit, p, param, ref, scope, sharedScope, splats, v, val, vars, wasEmpty, _i, _j, _k, _len, _len2, _len3, _len4, _ref, _ref2, _ref3, _results, _this;
      sharedScope = del(o, 'sharedScope');
      o.scope = scope = sharedScope || new Scope(o.scope, this.body, this);
      o.indent += TAB;
      delete o.bare;
      delete o.globals;
      vars = [];
      exprs = [];
      _ref = this.params;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        param = _ref[_i];
        if (param.splat) {
          splats = new Assign(new Value(new Arr((function() {
            _ref2 = this.params;
            _results = [];
            for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
              p = _ref2[_j];
              _results.push(p.asReference(o));
            }
            return _results;
          }).call(this))), new Value(new Literal('arguments')));
          break;
        }
      }
      _ref3 = this.params;
      for (_k = 0, _len3 = _ref3.length; _k < _len3; _k++) {
        param = _ref3[_k];
        if (param.isComplex()) {
          val = ref = param.asReference(o);
          if (param.value) {
            val = new Op('?', ref, param.value);
          }
          exprs.push(new Assign(new Value(param.name), val, '='));
        } else {
          ref = param;
          if (param.value) {
            lit = new Literal(ref.name.value + ' == null');
            val = new Assign(new Value(param.name), param.value, '=');
            exprs.push(new Op('&&', lit, val));
          }
        }
        if (!splats) {
          vars.push(ref);
        }
      }
      scope.startLevel();
      wasEmpty = this.body.isEmpty();
      if (splats) {
        exprs.unshift(splats);
      }
      if (exprs.length) {
        (_this = this.body.expressions).unshift.apply(_this, exprs);
      }
      if (!splats) {
        for (i = 0, _len4 = vars.length; i < _len4; i++) {
          v = vars[i];
          scope.parameter(vars[i] = v.compile(o));
        }
      }
      if (!(wasEmpty || this.noReturn)) {
        this.body.makeReturn();
      }
      idt = o.indent;
      code = 'function';
      if (this.ctor) {
        code += ' ' + this.name;
      }
      code += '(' + vars.join(', ') + ') {';
      if (!this.body.isEmpty()) {
        code += "\n" + (this.body.compileWithDeclarations(o)) + "\n" + this.tab;
      }
      code += '}';
      if (this.ctor) {
        return this.tab + code;
      }
      if (this.bound) {
        return utility('bind') + ("(" + code + ", " + this.context + ")");
      }
      if (this.front) {
        return "(" + code + ")";
      } else {
        return code;
      }
    };
    Code.prototype.traverseChildren = function(crossScope, func) {
      if (crossScope) {
        return Code.__super__.traverseChildren.call(this, crossScope, func);
      }
    };
    return Code;
  }();
  exports.Param = Param = function() {
    function Param(_arg, _arg2, _arg3) {
      this.name = _arg;
      this.value = _arg2;
      this.splat = _arg3;
    }
    __extends(Param, Base);
    Param.prototype.children = ['name', 'value'];
    Param.prototype.compile = function(o) {
      return this.name.compile(o, LEVEL_LIST);
    };
    Param.prototype.asReference = function(o) {
      var node;
      if (this.reference) {
        return this.reference;
      }
      node = this.isComplex() ? new Literal(o.scope.freeVariable('arg')) : this.name;
      node = new Value(node);
      if (this.splat) {
        node = new Splat(node);
      }
      return this.reference = node;
    };
    Param.prototype.isComplex = function() {
      return this.name.isComplex();
    };
    return Param;
  }();
  exports.Splat = Splat = function() {
    function Splat(name) {
      this.name = name.compile ? name : new Literal(name);
    }
    __extends(Splat, Base);
    Splat.prototype.children = ['name'];
    Splat.prototype.isAssignable = YES;
    Splat.prototype.assigns = function(name) {
      return this.name.assigns(name);
    };
    Splat.prototype.compile = function(o) {
      if (this.index != null) {
        return this.compileParam(o);
      } else {
        return this.name.compile(o);
      }
    };
    Splat.compileSplattedArray = function(o, list, apply) {
      var args, base, code, i, index, node, _i, _len, _len2, _ref, _results;
      index = -1;
      while ((node = list[++index]) && !(node instanceof Splat)) {
        continue;
      }
      if (index >= list.length) {
        return '';
      }
      if (list.length === 1) {
        code = list[0].compile(o, LEVEL_LIST);
        if (apply) {
          return code;
        }
        return "" + (utility('slice')) + ".call(" + code + ")";
      }
      args = list.slice(index);
      for (i = 0, _len = args.length; i < _len; i++) {
        node = args[i];
        code = node.compile(o, LEVEL_LIST);
        args[i] = node instanceof Splat ? "" + (utility('slice')) + ".call(" + code + ")" : "[" + code + "]";
      }
      if (index === 0) {
        return args[0] + (".concat(" + (args.slice(1).join(', ')) + ")");
      }
      base = ((function() {
        _ref = list.slice(0, index);
        _results = [];
        for (_i = 0, _len2 = _ref.length; _i < _len2; _i++) {
          node = _ref[_i];
          _results.push(node.compile(o, LEVEL_LIST));
        }
        return _results;
      })());
      return "[" + (base.join(', ')) + "].concat(" + (args.join(', ')) + ")";
    };
    return Splat;
  }();
  exports.While = While = function() {
    function While(condition, options) {
      this.condition = (options != null ? options.invert : void 0) ? condition.invert() : condition;
      this.guard = options != null ? options.guard : void 0;
    }
    __extends(While, Base);
    While.prototype.children = ['condition', 'guard', 'body'];
    While.prototype.isStatement = YES;
    While.prototype.makeReturn = function() {
      this.returns = true;
      return this;
    };
    While.prototype.addBody = function(_arg) {
      this.body = _arg;
      return this;
    };
    While.prototype.containsPureStatement = function() {
      var expressions, i, ret, _ref;
      expressions = this.body.expressions;
      i = expressions.length;
      if ((_ref = expressions[--i]) != null ? _ref.containsPureStatement() : void 0) {
        return true;
      }
      ret = function(node) {
        return node instanceof Return;
      };
      while (i--) {
        if (expressions[i].contains(ret)) {
          return true;
        }
      }
      return false;
    };
    While.prototype.compileNode = function(o) {
      var body, code, rvar, set;
      o.indent += TAB;
      set = '';
      body = this.body;
      if (body.isEmpty()) {
        body = '';
      } else {
        if (o.level > LEVEL_TOP || this.returns) {
          rvar = o.scope.freeVariable('results');
          set = "" + this.tab + rvar + " = [];\n";
          if (body) {
            body = Push.wrap(rvar, body);
          }
        }
        if (this.guard) {
          body = Expressions.wrap([new If(this.guard, body)]);
        }
        body = "\n" + (body.compile(o, LEVEL_TOP)) + "\n" + this.tab;
      }
      code = set + this.tab + ("while (" + (this.condition.compile(o, LEVEL_PAREN)) + ") {" + body + "}");
      if (this.returns) {
        o.indent = this.tab;
        code += '\n' + new Return(new Literal(rvar)).compile(o);
      }
      return code;
    };
    return While;
  }();
  exports.Op = Op = function() {
    var CONVERSIONS, INVERSIONS;
    function Op(op, first, second, flip) {
      if (op === 'in') {
        return new In(first, second);
      }
      if (op === 'new') {
        if (first instanceof Call) {
          return first.newInstance();
        }
        if (first instanceof Code && first.bound) {
          first = new Parens(first);
        }
      }
      this.operator = CONVERSIONS[op] || op;
      this.first = first;
      this.second = second;
      this.flip = !!flip;
    }
    __extends(Op, Base);
    CONVERSIONS = {
      '==': '===',
      '!=': '!==',
      'of': 'in'
    };
    INVERSIONS = {
      '!==': '===',
      '===': '!==',
      '>': '<=',
      '<=': '>',
      '<': '>=',
      '>=': '<'
    };
    Op.prototype.children = ['first', 'second'];
    Op.prototype.isUnary = function() {
      return !this.second;
    };
    Op.prototype.isChainable = function() {
      var _ref;
      return (_ref = this.operator) === '<' || _ref === '>' || _ref === '>=' || _ref === '<=' || _ref === '===' || _ref === '!==';
    };
    Op.prototype.invert = function() {
      var fst, op, _ref;
      if (op = INVERSIONS[this.operator]) {
        this.operator = op;
        return this;
      } else if (this.second) {
        return new Parens(this).invert();
      } else if (this.operator === '!' && (fst = this.first.unwrap()) instanceof Op && ((_ref = fst.operator) === '!' || _ref === 'in' || _ref === 'instanceof')) {
        return fst;
      } else {
        return new Op('!', this);
      }
    };
    Op.prototype.unfoldSoak = function(o) {
      var _ref;
      return ((_ref = this.operator) === '++' || _ref === '--' || _ref === 'delete') && unfoldSoak(o, this, 'first');
    };
    Op.prototype.compileNode = function(o) {
      var code;
      if (this.isUnary()) {
        return this.compileUnary(o);
      }
      if (this.isChainable() && this.first.isChainable()) {
        return this.compileChain(o);
      }
      if (this.operator === '?') {
        return this.compileExistence(o);
      }
      this.first.front = this.front;
      code = this.first.compile(o, LEVEL_OP) + ' ' + this.operator + ' ' + this.second.compile(o, LEVEL_OP);
      if (o.level <= LEVEL_OP) {
        return code;
      } else {
        return "(" + code + ")";
      }
    };
    Op.prototype.compileChain = function(o) {
      var code, fst, shared, _ref;
      _ref = this.first.second.cache(o), this.first.second = _ref[0], shared = _ref[1];
      fst = this.first.compile(o, LEVEL_OP);
      if (fst.charAt(0) === '(') {
        fst = fst.slice(1, -1);
      }
      code = "" + fst + " && " + (shared.compile(o)) + " " + this.operator + " " + (this.second.compile(o, LEVEL_OP));
      if (o.level < LEVEL_OP) {
        return code;
      } else {
        return "(" + code + ")";
      }
    };
    Op.prototype.compileExistence = function(o) {
      var fst, ref;
      if (this.first.isComplex()) {
        ref = o.scope.freeVariable('ref');
        fst = new Parens(new Assign(new Literal(ref), this.first));
      } else {
        fst = this.first;
        ref = fst.compile(o);
      }
      return new Existence(fst).compile(o) + (" ? " + ref + " : " + (this.second.compile(o, LEVEL_LIST)));
    };
    Op.prototype.compileUnary = function(o) {
      var op, parts;
      parts = [op = this.operator];
      if ((op === 'new' || op === 'typeof' || op === 'delete') || (op === '+' || op === '-') && this.first instanceof Op && this.first.operator === op) {
        parts.push(' ');
      }
      parts.push(this.first.compile(o, LEVEL_OP));
      if (this.flip) {
        parts.reverse();
      }
      return parts.join('');
    };
    Op.prototype.toString = function(idt) {
      return Op.__super__.toString.call(this, idt, this.constructor.name + ' ' + this.operator);
    };
    return Op;
  }();
  exports.In = In = function() {
    function In(_arg, _arg2) {
      this.object = _arg;
      this.array = _arg2;
    }
    __extends(In, Base);
    In.prototype.children = ['object', 'array'];
    In.prototype.invert = NEGATE;
    In.prototype.compileNode = function(o) {
      if (this.array instanceof Value && this.array.isArray()) {
        return this.compileOrTest(o);
      } else {
        return this.compileLoopTest(o);
      }
    };
    In.prototype.compileOrTest = function(o) {
      var cmp, cnj, i, item, ref, sub, tests, _len, _ref, _ref2, _ref3, _results;
      _ref = this.object.cache(o, LEVEL_OP), sub = _ref[0], ref = _ref[1];
      _ref2 = this.negated ? [' !== ', ' && '] : [' === ', ' || '], cmp = _ref2[0], cnj = _ref2[1];
      tests = (function() {
        _ref3 = this.array.base.objects;
        _results = [];
        for (i = 0, _len = _ref3.length; i < _len; i++) {
          item = _ref3[i];
          _results.push((i ? ref : sub) + cmp + item.compile(o, LEVEL_OP));
        }
        return _results;
      }).call(this);
      tests = tests.join(cnj);
      if (o.level < LEVEL_OP) {
        return tests;
      } else {
        return "(" + tests + ")";
      }
    };
    In.prototype.compileLoopTest = function(o) {
      var code, ref, sub, _ref;
      _ref = this.object.cache(o, LEVEL_LIST), sub = _ref[0], ref = _ref[1];
      code = utility('indexOf') + (".call(" + (this.array.compile(o, LEVEL_LIST)) + ", " + ref + ") ") + (this.negated ? '< 0' : '>= 0');
      if (sub === ref) {
        return code;
      }
      code = sub + ', ' + code;
      if (o.level < LEVEL_LIST) {
        return code;
      } else {
        return "(" + code + ")";
      }
    };
    In.prototype.toString = function(idt) {
      return In.__super__.toString.call(this, idt, this.constructor.name + (this.negated ? '!' : ''));
    };
    return In;
  }();
  exports.Try = Try = function() {
    function Try(_arg, _arg2, _arg3, _arg4) {
      this.attempt = _arg;
      this.error = _arg2;
      this.recovery = _arg3;
      this.ensure = _arg4;
    }
    __extends(Try, Base);
    Try.prototype.children = ['attempt', 'recovery', 'ensure'];
    Try.prototype.isStatement = YES;
    Try.prototype.makeReturn = function() {
      if (this.attempt) {
        this.attempt = this.attempt.makeReturn();
      }
      if (this.recovery) {
        this.recovery = this.recovery.makeReturn();
      }
      return this;
    };
    Try.prototype.compileNode = function(o) {
      var catchPart, errorPart;
      o.indent += TAB;
      errorPart = this.error ? " (" + (this.error.compile(o)) + ") " : ' ';
      catchPart = this.recovery ? " catch" + errorPart + "{\n" + (this.recovery.compile(o, LEVEL_TOP)) + "\n" + this.tab + "}" : !(this.ensure || this.recovery) ? ' catch (_e) {}' : void 0;
      return ("" + this.tab + "try {\n" + (this.attempt.compile(o, LEVEL_TOP)) + "\n" + this.tab + "}" + (catchPart || '')) + (this.ensure ? " finally {\n" + (this.ensure.compile(o, LEVEL_TOP)) + "\n" + this.tab + "}" : '');
    };
    return Try;
  }();
  exports.Throw = Throw = function() {
    function Throw(_arg) {
      this.expression = _arg;
    }
    __extends(Throw, Base);
    Throw.prototype.children = ['expression'];
    Throw.prototype.isStatement = YES;
    Throw.prototype.makeReturn = THIS;
    Throw.prototype.compileNode = function(o) {
      return this.tab + ("throw " + (this.expression.compile(o)) + ";");
    };
    return Throw;
  }();
  exports.Existence = Existence = function() {
    function Existence(_arg) {
      this.expression = _arg;
    }
    __extends(Existence, Base);
    Existence.prototype.children = ['expression'];
    Existence.prototype.invert = NEGATE;
    Existence.prototype.compileNode = function(o) {
      var code, sym;
      code = this.expression.compile(o, LEVEL_OP);
      code = IDENTIFIER.test(code) && !o.scope.check(code) ? this.negated ? "typeof " + code + " == \"undefined\" || " + code + " === null" : "typeof " + code + " != \"undefined\" && " + code + " !== null" : (sym = this.negated ? '==' : '!=', "" + code + " " + sym + " null");
      if (o.level <= LEVEL_COND) {
        return code;
      } else {
        return "(" + code + ")";
      }
    };
    return Existence;
  }();
  exports.Parens = Parens = function() {
    function Parens(_arg) {
      this.expression = _arg;
    }
    __extends(Parens, Base);
    Parens.prototype.children = ['expression'];
    Parens.prototype.unwrap = function() {
      return this.expression;
    };
    Parens.prototype.isComplex = function() {
      return this.expression.isComplex();
    };
    Parens.prototype.makeReturn = function() {
      return this.expression.makeReturn();
    };
    Parens.prototype.compileNode = function(o) {
      var bare, code, expr;
      expr = this.expression;
      if (expr instanceof Value && expr.isAtomic()) {
        expr.front = this.front;
        return expr.compile(o);
      }
      bare = o.level < LEVEL_OP && (expr instanceof Op || expr instanceof Call);
      code = expr.compile(o, LEVEL_PAREN);
      if (bare) {
        return code;
      } else {
        return "(" + code + ")";
      }
    };
    return Parens;
  }();
  exports.For = For = function() {
    function For(body, head) {
      if (head.index instanceof Value) {
        throw SyntaxError('index cannot be a pattern matching expression');
      }
      extend(this, head);
      this.body = Expressions.wrap([body]);
      this.pattern = this.name instanceof Value;
      this.returns = false;
    }
    __extends(For, Base);
    For.prototype.children = ['body', 'source', 'guard', 'step', 'from', 'to'];
    For.prototype.isStatement = YES;
    For.prototype.makeReturn = function() {
      this.returns = true;
      return this;
    };
    For.prototype.containsPureStatement = While.prototype.containsPureStatement;
    For.prototype.compileReturnValue = function(val, o) {
      if (this.returns) {
        return '\n' + new Return(new Literal(val)).compile(o);
      }
      if (val) {
        return '\n' + val;
      }
      return '';
    };
    For.prototype.compileNode = function(o) {
      var body, code, cond, defPart, forPart, fvar, guardPart, hasCode, head, idt, incr, index, intro, ivar, lvar, name, namePart, pvar, retPart, rvar, scope, sourcePart, step, svar, tail, tvar, varPart, vars, _ref, _ref2, _ref3, _ref4, _ref5, _ref6;
      scope = o.scope;
      body = this.body;
      hasCode = this.body.contains(function(node) {
        return node instanceof Code;
      });
      name = !this.pattern && ((_ref = this.name) != null ? _ref.compile(o) : void 0);
      index = (_ref2 = this.index) != null ? _ref2.compile(o) : void 0;
      ivar = !index ? scope.freeVariable('i') : index;
      varPart = guardPart = defPart = retPart = '';
      idt = o.indent + TAB;
      if (!hasCode) {
        if (name) {
          scope.find(name, true);
        }
        if (index) {
          scope.find(index, true);
        }
      }
      if (this.step) {
        _ref3 = this.step.compileLoopReference(o, 'step'), step = _ref3[0], pvar = _ref3[1];
      }
      if (this.from) {
        _ref4 = this.from.compileLoopReference(o, 'from'), head = _ref4[0], fvar = _ref4[1];
        _ref5 = this.to.compileLoopReference(o, 'to'), tail = _ref5[0], tvar = _ref5[1];
        vars = ivar + ' = ' + head;
        if (tail !== tvar) {
          vars += ', ' + tail;
        }
        if (SIMPLENUM.test(head) && SIMPLENUM.test(tail)) {
          if (+head <= +tail) {
            cond = "" + ivar + " <= " + tail;
          } else {
            pvar || (pvar = -1);
            cond = "" + ivar + " >= " + tail;
          }
        } else {
          if (+pvar) {
            cond = "" + ivar + " " + (pvar < 0 ? '>' : '<') + "= " + tvar;
          } else {
            intro = "" + fvar + " <= " + tvar + " ? " + ivar;
            cond = "" + intro + " <= " + tvar + " : " + ivar + " >= " + tvar;
            incr = pvar ? "" + ivar + " += " + pvar : "" + intro + "++ : " + ivar + "--";
          }
        }
      } else {
        if (name || this.object && !this.raw) {
          _ref6 = this.source.compileLoopReference(o, 'ref'), sourcePart = _ref6[0], svar = _ref6[1];
        } else {
          sourcePart = svar = this.source.compile(o, LEVEL_PAREN);
        }
        namePart = this.pattern ? new Assign(this.name, new Literal("" + svar + "[" + ivar + "]")).compile(o, LEVEL_TOP) : name ? "" + name + " = " + svar + "[" + ivar + "]" : void 0;
        if (!this.object) {
          if (0 > pvar && (pvar | 0) === +pvar) {
            vars = "" + ivar + " = " + svar + ".length - 1";
            cond = "" + ivar + " >= 0";
          } else {
            lvar = scope.freeVariable('len');
            vars = "" + ivar + " = 0, " + lvar + " = " + svar + ".length";
            cond = "" + ivar + " < " + lvar;
          }
        }
      }
      if (this.object) {
        forPart = ivar + ' in ' + sourcePart;
        guardPart = this.raw ? '' : idt + ("if (!" + (utility('hasProp')) + ".call(" + svar + ", " + ivar + ")) continue;\n");
      } else {
        pvar || (pvar = 1);
        if (step && (step !== pvar)) {
          vars += ', ' + step;
        }
        if (svar !== sourcePart) {
          defPart = this.tab + sourcePart + ';\n';
        }
        forPart = vars + ("; " + cond + "; ") + (incr || (ivar + (function() {
          switch (+pvar) {
            case 1:
              return '++';
            case -1:
              return '--';
            default:
              if (pvar < 0) {
                return ' -= ' + pvar.slice(1);
              } else {
                return ' += ' + pvar;
              }
          }
        })()));
      }
      if (hasCode) {
        body = Closure.wrap(body, true);
      }
      if (namePart) {
        varPart = idt + namePart + ';\n';
      }
      if (!this.pattern) {
        defPart += this.pluckDirectCall(o, body, name, index);
      }
      code = guardPart + varPart;
      if (!body.isEmpty()) {
        if (o.level > LEVEL_TOP || this.returns) {
          rvar = scope.freeVariable('results');
          defPart += this.tab + rvar + ' = [];\n';
          retPart = this.compileReturnValue(rvar, o);
          body = Push.wrap(rvar, body);
        }
        if (this.guard) {
          body = Expressions.wrap([new If(this.guard, body)]);
        }
        o.indent = idt;
        code += body.compile(o, LEVEL_TOP);
      }
      if (code) {
        code = '\n' + code + '\n' + this.tab;
      }
      return defPart + this.tab + ("for (" + forPart + ") {" + code + "}") + retPart;
    };
    For.prototype.pluckDirectCall = function(o, body, name, index) {
      var arg, args, base, defs, expr, fn, i, idx, ref, val, _len, _len2, _ref, _ref2, _ref3, _ref4, _ref5, _ref6;
      defs = '';
      _ref = body.expressions;
      for (idx = 0, _len = _ref.length; idx < _len; idx++) {
        expr = _ref[idx];
        expr = expr.unwrapAll();
        if (!(expr instanceof Call)) {
          continue;
        }
        val = expr.variable.unwrapAll();
        if (!((val instanceof Code) || (val instanceof Value && ((_ref2 = val.base) != null ? _ref2.unwrapAll() : void 0) instanceof Code && val.properties.length === 1 && ((_ref3 = (_ref4 = val.properties[0].name) != null ? _ref4.value : void 0) === 'call' || _ref3 === 'apply')))) {
          continue;
        }
        fn = ((_ref5 = val.base) != null ? _ref5.unwrapAll() : void 0) || val;
        ref = new Literal(o.scope.freeVariable('fn'));
        base = new Value(ref);
        args = compact([name, index]);
        if (this.object) {
          args.reverse();
        }
        for (i = 0, _len2 = args.length; i < _len2; i++) {
          arg = args[i];
          fn.params.push(new Param(args[i] = new Literal(arg)));
        }
        if (val.base) {
          _ref6 = [base, val], val.base = _ref6[0], base = _ref6[1];
          args.unshift(new Literal('this'));
        }
        body.expressions[idx] = new Call(base, args);
        defs += this.tab + new Assign(ref, fn).compile(o, LEVEL_TOP) + ';\n';
      }
      return defs;
    };
    return For;
  }();
  exports.Switch = Switch = function() {
    function Switch(_arg, _arg2, _arg3) {
      this.subject = _arg;
      this.cases = _arg2;
      this.otherwise = _arg3;
    }
    __extends(Switch, Base);
    Switch.prototype.children = ['subject', 'cases', 'otherwise'];
    Switch.prototype.isStatement = YES;
    Switch.prototype.makeReturn = function() {
      var pair, _i, _len, _ref, _ref2;
      _ref = this.cases;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        pair = _ref[_i];
        pair[1].makeReturn();
      }
      if ((_ref2 = this.otherwise) != null) {
        _ref2.makeReturn();
      }
      return this;
    };
    Switch.prototype.compileNode = function(o) {
      var block, body, code, cond, conditions, expr, i, idt1, idt2, _i, _j, _len, _len2, _ref, _ref2, _ref3, _ref4;
      idt1 = o.indent + TAB;
      idt2 = o.indent = idt1 + TAB;
      code = this.tab + ("switch (" + (((_ref = this.subject) != null ? _ref.compile(o, LEVEL_PAREN) : void 0) || false) + ") {\n");
      for (i = 0, _len = this.cases.length; i < _len; i++) {
        _ref2 = this.cases[i], conditions = _ref2[0], block = _ref2[1];
        _ref3 = flatten([conditions]);
        for (_i = 0, _len2 = _ref3.length; _i < _len2; _i++) {
          cond = _ref3[_i];
          if (!this.subject) {
            cond = cond.invert();
          }
          code += idt1 + ("case " + (cond.compile(o, LEVEL_PAREN)) + ":\n");
        }
        if (body = block.compile(o, LEVEL_TOP)) {
          code += body + '\n';
        }
        if (i === this.cases.length - 1 && !this.otherwise) {
          break;
        }
        _ref4 = block.expressions;
        for (_j = _ref4.length - 1; _j >= 0; _j--) {
          expr = _ref4[_j];
          if (!(expr instanceof Comment)) {
            if (!(expr instanceof Return)) {
              code += idt2 + 'break;\n';
            }
            break;
          }
        }
      }
      if (this.otherwise) {
        code += idt1 + ("default:\n" + (this.otherwise.compile(o, LEVEL_TOP)) + "\n");
      }
      return code + this.tab + '}';
    };
    return Switch;
  }();
  exports.If = If = function() {
    function If(condition, _arg, options) {
      this.body = _arg;
      options == null && (options = {});
      this.condition = options.invert ? condition.invert() : condition;
      this.elseBody = null;
      this.isChain = false;
      this.soak = options.soak;
    }
    __extends(If, Base);
    If.prototype.children = ['condition', 'body', 'elseBody'];
    If.prototype.bodyNode = function() {
      var _ref;
      return (_ref = this.body) != null ? _ref.unwrap() : void 0;
    };
    If.prototype.elseBodyNode = function() {
      var _ref;
      return (_ref = this.elseBody) != null ? _ref.unwrap() : void 0;
    };
    If.prototype.addElse = function(elseBody) {
      if (this.isChain) {
        this.elseBodyNode().addElse(elseBody);
      } else {
        this.isChain = elseBody instanceof If;
        this.elseBody = this.ensureExpressions(elseBody);
      }
      return this;
    };
    If.prototype.isStatement = function(o) {
      var _ref;
      return (o != null ? o.level : void 0) === LEVEL_TOP || this.bodyNode().isStatement(o) || ((_ref = this.elseBodyNode()) != null ? _ref.isStatement(o) : void 0);
    };
    If.prototype.compileNode = function(o) {
      if (this.isStatement(o)) {
        return this.compileStatement(o);
      } else {
        return this.compileExpression(o);
      }
    };
    If.prototype.makeReturn = function() {
      this.body && (this.body = new Expressions([this.body.makeReturn()]));
      this.elseBody && (this.elseBody = new Expressions([this.elseBody.makeReturn()]));
      return this;
    };
    If.prototype.ensureExpressions = function(node) {
      if (node instanceof Expressions) {
        return node;
      } else {
        return new Expressions([node]);
      }
    };
    If.prototype.compileStatement = function(o) {
      var body, child, cond, ifPart;
      child = del(o, 'chainChild');
      cond = this.condition.compile(o, LEVEL_PAREN);
      o.indent += TAB;
      body = this.ensureExpressions(this.body).compile(o);
      if (body) {
        body = "\n" + body + "\n" + this.tab;
      }
      ifPart = "if (" + cond + ") {" + body + "}";
      if (!child) {
        ifPart = this.tab + ifPart;
      }
      if (!this.elseBody) {
        return ifPart;
      }
      return ifPart + ' else ' + (this.isChain ? (o.indent = this.tab, o.chainChild = true, this.elseBody.unwrap().compile(o, LEVEL_TOP)) : "{\n" + (this.elseBody.compile(o, LEVEL_TOP)) + "\n" + this.tab + "}");
    };
    If.prototype.compileExpression = function(o) {
      var alt, body, code, cond;
      cond = this.condition.compile(o, LEVEL_COND);
      body = this.bodyNode().compile(o, LEVEL_LIST);
      alt = this.elseBodyNode() ? this.elseBodyNode().compile(o, LEVEL_LIST) : 'void 0';
      code = "" + cond + " ? " + body + " : " + alt;
      if (o.level >= LEVEL_COND) {
        return "(" + code + ")";
      } else {
        return code;
      }
    };
    If.prototype.unfoldSoak = function() {
      return this.soak && this;
    };
    return If;
  }();
  Push = {
    wrap: function(name, exps) {
      if (exps.isEmpty() || last(exps.expressions).containsPureStatement()) {
        return exps;
      }
      return exps.push(new Call(new Value(new Literal(name), [new Accessor(new Literal('push'))]), [exps.pop()]));
    }
  };
  Closure = {
    wrap: function(expressions, statement, noReturn) {
      var args, call, func, mentionsArgs, meth;
      if (expressions.containsPureStatement()) {
        return expressions;
      }
      func = new Parens(new Code([], Expressions.wrap([expressions])));
      args = [];
      if ((mentionsArgs = expressions.contains(this.literalArgs)) || (expressions.contains(this.literalThis))) {
        meth = new Literal(mentionsArgs ? 'apply' : 'call');
        args = [new Literal('this')];
        if (mentionsArgs) {
          args.push(new Literal('arguments'));
        }
        func = new Value(func, [new Accessor(meth)]);
        func.noReturn = noReturn;
      }
      call = new Call(func, args);
      if (statement) {
        return Expressions.wrap([call]);
      } else {
        return call;
      }
    },
    literalArgs: function(node) {
      return node instanceof Literal && node.value === 'arguments';
    },
    literalThis: function(node) {
      return node instanceof Literal && node.value === 'this' || node instanceof Code && node.bound;
    }
  };
  unfoldSoak = function(o, parent, name) {
    var ifn;
    if (!(ifn = parent[name].unfoldSoak(o))) {
      return;
    }
    parent[name] = ifn.body;
    ifn.body = new Value(parent);
    return ifn;
  };
  UTILITIES = {
    "extends": 'function(child, parent) {\n  function ctor() { this.constructor = child; }\n  ctor.prototype = parent.prototype;\n  child.prototype = new ctor;\n  for (var key in parent) if (__hasProp.call(parent, key)) child[key] = parent[key];\n  child.__super__ = parent.prototype;\n  return child;\n}',
    bind: 'function(fn, me){ return function(){ return fn.apply(me, arguments); }; }',
    indexOf: 'Array.prototype.indexOf || function(item) {\n  for (var i = 0, l = this.length; i < l; i++) {\n    if (this[i] === item) return i;\n  }\n  return -1;\n}',
    hasProp: 'Object.prototype.hasOwnProperty',
    slice: 'Array.prototype.slice'
  };
  LEVEL_TOP = 1;
  LEVEL_PAREN = 2;
  LEVEL_LIST = 3;
  LEVEL_COND = 4;
  LEVEL_OP = 5;
  LEVEL_ACCESS = 6;
  TAB = '  ';
  TRAILING_WHITESPACE = /[ \t]+$/gm;
  IDENTIFIER = /^[$A-Za-z_][$\w]*$/;
  NUMBER = /^-?(?:0x[\da-f]+|(?:\d+(\.\d+)?|\.\d+)(?:e[+-]?\d+)?)$/i;
  SIMPLENUM = /^[+-]?\d+$/;
  IS_STRING = /^['"]/;
  utility = function(name) {
    var ref;
    ref = "__" + name;
    Scope.root.assign(ref, UTILITIES[name]);
    return ref;
  };
  multident = function(code, tab) {
    return code.replace(/\n/g, '$&' + tab);
  };
}).call(this);
