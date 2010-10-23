(function() {
  var Accessor, ArrayLiteral, Assign, Base, Call, Class, Closure, Code, Comment, Existence, Expressions, Extends, For, IDENTIFIER, IS_STRING, If, In, Index, LVL_ACCESS, LVL_COND, LVL_LIST, LVL_OP, LVL_PAREN, LVL_TOP, Literal, NO, NUMBER, ObjectLiteral, Op, Param, Parens, Push, Return, SIMPLENUM, Scope, Splat, Switch, TAB, THIS, TRAILING_WHITESPACE, Throw, Try, UTILITIES, Value, While, YES, _ref, compact, del, ends, extend, flatten, last, merge, multident, starts, utility;
  var __extends = function(child, parent) {
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    if (typeof parent.extended === "function") parent.extended(child);
    child.__super__ = parent.prototype;
  }, __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) if (this[i] === item) return i;
    return -1;
  };
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
  exports.Base = (function() {
    Base = (function() {
      function Base() {
        this.tags = {};
        return this;
      };
      return Base;
    })();
    Base.prototype.compile = function(o, lvl) {
      var node;
      o = o ? extend({}, o) : {};
      if (lvl != null) {
        o.level = lvl;
      }
      node = this.unfoldSoak(o) || this;
      node.tab = o.indent;
      return o.level === LVL_TOP || node.isPureStatement() || !node.isStatement(o) ? node.compileNode(o) : node.compileClosure(o);
    };
    Base.prototype.compileClosure = function(o) {
      if (this.containsPureStatement()) {
        throw SyntaxError('cannot include a pure statement in an expression.');
      }
      o.sharedScope = o.scope;
      return Closure.wrap(this).compileNode(o);
    };
    Base.prototype.cache = function(o, lvl) {
      var ref, sub;
      if (!this.isComplex()) {
        ref = lvl ? this.compile(o, lvl) : this;
        return [ref, ref];
      } else {
        ref = new Literal(o.scope.freeVariable('ref'));
        sub = new Assign(ref, this);
        return lvl ? [sub.compile(o, lvl), ref.value] : [sub, ref];
      }
    };
    Base.prototype.compileLoopReference = function(o, name) {
      var src, tmp;
      src = tmp = this.compile(o, LVL_LIST);
      if (!(NUMBER.test(src) || IDENTIFIER.test(src) && o.scope.check(src, {
        immediate: true
      }))) {
        src = "" + (tmp = o.scope.freeVariable(name)) + " = " + src;
      }
      return [src, tmp];
    };
    Base.prototype.idt = function(tabs) {
      return (this.tab || '') + Array((tabs || 0) + 1).join(TAB);
    };
    Base.prototype.makeReturn = function() {
      return new Return(this);
    };
    Base.prototype.contains = function(block) {
      var contains;
      contains = false;
      this.traverseChildren(false, function(node) {
        if (block(node)) {
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
    Base.prototype.toString = function(idt, override) {
      var _i, _len, _ref2, _result, child, children, klass;
      idt || (idt = '');
      children = ((function() {
        _ref2 = this.collectChildren();
        _result = [];
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          child = _ref2[_i];
          _result.push(child.toString(idt + TAB));
        }
        return _result;
      }).call(this)).join('');
      klass = override || this.constructor.name + (this.soakNode ? '?' : '');
      return '\n' + idt + klass + children;
    };
    Base.prototype.eachChild = function(func) {
      var _i, _j, _len, _len2, _ref2, _ref3, attr, child;
      if (!this.children) {
        return this;
      }
      _ref2 = this.children;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        attr = _ref2[_i];
        if (this[attr]) {
          _ref3 = flatten([this[attr]]);
          for (_j = 0, _len2 = _ref3.length; _j < _len2; _j++) {
            child = _ref3[_j];
            if (func(child) === false) {
              return this;
            }
          }
        }
      }
      return this;
    };
    Base.prototype.collectChildren = function() {
      var nodes;
      nodes = [];
      this.eachChild(function(node) {
        return nodes.push(node);
      });
      return nodes;
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
    Base.prototype.children = [];
    Base.prototype.unwrap = THIS;
    Base.prototype.isStatement = NO;
    Base.prototype.isPureStatement = NO;
    Base.prototype.isComplex = YES;
    Base.prototype.isChainable = NO;
    Base.prototype.unfoldSoak = NO;
    Base.prototype.assigns = NO;
    return Base;
  })();
  exports.Expressions = (function() {
    Expressions = (function() {
      function Expressions(nodes) {
        Expressions.__super__.constructor.call(this);
        this.expressions = compact(flatten(nodes || []));
        return this;
      };
      return Expressions;
    })();
    __extends(Expressions, Base);
    Expressions.prototype.children = ['expressions'];
    Expressions.prototype.isStatement = YES;
    Expressions.prototype.push = function(node) {
      this.expressions.push(node);
      return this;
    };
    Expressions.prototype.unshift = function(node) {
      this.expressions.unshift(node);
      return this;
    };
    Expressions.prototype.unwrap = function() {
      return this.expressions.length === 1 ? this.expressions[0] : this;
    };
    Expressions.prototype.empty = function() {
      return this.expressions.length === 0;
    };
    Expressions.prototype.makeReturn = function() {
      var _ref2, end, idx;
      _ref2 = this.expressions;
      for (idx = _ref2.length - 1; idx >= 0; idx--) {
        end = _ref2[idx];
        if (!(end instanceof Comment)) {
          this.expressions[idx] = end.makeReturn();
          break;
        }
      }
      return this;
    };
    Expressions.prototype.compile = function(o, lvl) {
      o || (o = {});
      return o.scope ? Expressions.__super__.compile.call(this, o, lvl) : this.compileRoot(o);
    };
    Expressions.prototype.compileNode = function(o) {
      var _i, _len, _ref2, _result, node;
      this.tab = o.indent;
      return ((function() {
        _ref2 = this.expressions;
        _result = [];
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          node = _ref2[_i];
          _result.push(this.compileExpression(node, o));
        }
        return _result;
      }).call(this)).join('\n');
    };
    Expressions.prototype.compileRoot = function(o) {
      var code;
      o.indent = this.tab = o.bare ? '' : TAB;
      o.scope = new Scope(null, this, null);
      o.level = LVL_TOP;
      code = this.compileWithDeclarations(o);
      code = code.replace(TRAILING_WHITESPACE, '');
      return o.bare ? code : "(function() {\n" + code + "\n}).call(this);\n";
    };
    Expressions.prototype.compileWithDeclarations = function(o) {
      var code, scope;
      code = this.compileNode(o);
      scope = o.scope;
      if (scope.hasAssignments(this)) {
        code = "" + this.tab + "var " + (multident(scope.compiledAssignments(), this.tab)) + ";\n" + code;
      }
      if (!o.globals && o.scope.hasDeclarations(this)) {
        code = "" + this.tab + "var " + (scope.compiledDeclarations()) + ";\n" + code;
      }
      return code;
    };
    Expressions.prototype.compileExpression = function(node, o) {
      var code;
      while (node !== (node = node.unwrap())) {

      }
      node = node.unfoldSoak(o) || node;
      node.tags.front = true;
      o.level = LVL_TOP;
      code = node.compile(o);
      return node.isStatement(o) ? code : this.tab + code + ';';
    };
    Expressions.wrap = function(nodes) {
      if (nodes.length === 1 && nodes[0] instanceof Expressions) {
        return nodes[0];
      }
      return new Expressions(nodes);
    };
    return Expressions;
  }).call(this);
  exports.Literal = (function() {
    Literal = (function() {
      function Literal(_arg) {
        this.value = _arg;
        Literal.__super__.constructor.call(this);
        return this;
      };
      return Literal;
    })();
    __extends(Literal, Base);
    Literal.prototype.makeReturn = function() {
      return this.isStatement() ? this : Literal.__super__.makeReturn.call(this);
    };
    Literal.prototype.isPureStatement = function() {
      var _ref2;
      return (_ref2 = this.value) === 'break' || _ref2 === 'continue' || _ref2 === 'debugger';
    };
    Literal.prototype.isComplex = NO;
    Literal.prototype.assigns = function(name) {
      return name === this.value;
    };
    Literal.prototype.compile = function() {
      return this.value.reserved ? "\"" + this.value + "\"" : this.value;
    };
    Literal.prototype.toString = function() {
      return ' "' + this.value + '"';
    };
    return Literal;
  })();
  exports.Return = (function() {
    Return = (function() {
      function Return(_arg) {
        this.expression = _arg;
        Return.__super__.constructor.call(this);
        return this;
      };
      return Return;
    })();
    __extends(Return, Base);
    Return.prototype.children = ['expression'];
    Return.prototype.isStatement = YES;
    Return.prototype.isPureStatement = YES;
    Return.prototype.makeReturn = THIS;
    Return.prototype.compile = function(o, lvl) {
      var _ref2, expr;
      expr = (_ref2 = this.expression) != null ? _ref2.makeReturn() : undefined;
      return expr && !(expr instanceof Return) ? expr.compile(o, lvl) : Return.__super__.compile.call(this, o, lvl);
    };
    Return.prototype.compileNode = function(o) {
      o.level = LVL_PAREN;
      return this.tab + ("return" + (this.expression ? ' ' + this.expression.compile(o) : '') + ";");
    };
    return Return;
  })();
  exports.Value = (function() {
    Value = (function() {
      function Value(_arg, props, tag) {
        this.base = _arg;
        Value.__super__.constructor.call(this);
        this.properties = props || [];
        if (tag) {
          this.tags[tag] = true;
        }
        return this;
      };
      return Value;
    })();
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
      return this.base instanceof ArrayLiteral && !this.properties.length;
    };
    Value.prototype.isObject = function() {
      return this.base instanceof ObjectLiteral && !this.properties.length;
    };
    Value.prototype.isComplex = function() {
      return this.base.isComplex() || this.hasProperties();
    };
    Value.prototype.isAtomic = function() {
      var _i, _len, _ref2, node;
      _ref2 = this.properties.concat(this.base);
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        node = _ref2[_i];
        if (node.soakNode || node instanceof Call) {
          return false;
        }
      }
      return true;
    };
    Value.prototype.assigns = function(name) {
      return !this.properties.length && this.base.assigns(name);
    };
    Value.prototype.makeReturn = function() {
      return this.properties.length ? Value.__super__.makeReturn.call(this) : this.base.makeReturn();
    };
    Value.prototype.unwrap = function() {
      return this.properties.length ? this : this.base;
    };
    Value.prototype.isStatement = function(o) {
      return !this.properties.length && this.base.isStatement(o);
    };
    Value.prototype.isSimpleNumber = function() {
      return this.base instanceof Literal && SIMPLENUM.test(this.base.value);
    };
    Value.prototype.cacheReference = function(o) {
      var base, bref, name, nref;
      name = last(this.properties);
      if (this.properties.length < 2 && !this.base.isComplex() && !(name != null ? name.isComplex() : undefined)) {
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
      var _i, _len, code, prop, props;
      this.base.tags.front = this.tags.front;
      props = this.properties;
      code = this.base.compile(o, props.length ? LVL_ACCESS : null);
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
      var _len, _ref2, fst, i, ifn, prop, ref, snd;
      if (ifn = this.base.unfoldSoak(o)) {
        Array.prototype.push.apply(ifn.body.properties, this.properties);
        return ifn;
      }
      _ref2 = this.properties;
      for (i = 0, _len = _ref2.length; i < _len; i++) {
        prop = _ref2[i];
        if (prop.soakNode) {
          prop.soakNode = false;
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
    Value.wrap = function(node) {
      return node instanceof Value ? node : new Value(node);
    };
    return Value;
  }).call(this);
  exports.Comment = (function() {
    Comment = (function() {
      function Comment(_arg) {
        this.comment = _arg;
        Comment.__super__.constructor.call(this);
        return this;
      };
      return Comment;
    })();
    __extends(Comment, Base);
    Comment.prototype.isPureStatement = YES;
    Comment.prototype.makeReturn = THIS;
    Comment.prototype.compileNode = function(o) {
      return this.tab + '/*' + multident(this.comment, this.tab) + '*/';
    };
    return Comment;
  })();
  exports.Call = (function() {
    Call = (function() {
      function Call(variable, _arg, _arg2) {
        this.soakNode = _arg2;
        this.args = _arg;
        Call.__super__.constructor.call(this);
        this.isNew = false;
        this.isSuper = variable === 'super';
        this.variable = this.isSuper ? null : variable;
        this.args || (this.args = []);
        return this;
      };
      return Call;
    })();
    __extends(Call, Base);
    Call.prototype.children = ['variable', 'args'];
    Call.prototype.compileSplatArguments = function(o) {
      return Splat.compileSplattedArray(this.args, o);
    };
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
      return method.klass ? "" + method.klass + ".__super__." + name : "" + name + ".__super__.constructor";
    };
    Call.prototype.unfoldSoak = function(o) {
      var _i, _len, _ref2, _ref3, call, ifn, left, list, rite;
      if (this.soakNode) {
        if (this.variable) {
          if (ifn = If.unfoldSoak(o, this, 'variable')) {
            return ifn;
          }
          _ref2 = Value.wrap(this.variable).cacheReference(o), left = _ref2[0], rite = _ref2[1];
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
      _ref3 = list.reverse();
      for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
        call = _ref3[_i];
        if (ifn) {
          if (call.variable instanceof Call) {
            call.variable = ifn;
          } else {
            call.variable.base = ifn;
          }
        }
        ifn = If.unfoldSoak(o, call, 'variable');
      }
      return ifn;
    };
    Call.prototype.compileNode = function(o) {
      var _i, _j, _len, _len2, _ref2, _ref3, _ref4, _result, arg, args;
      if ((_ref2 = this.variable) != null) {
        _ref2.tags.front = this.tags.front;
      }
      _ref3 = this.args;
      for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
        arg = _ref3[_i];
        if (arg instanceof Splat) {
          return this.compileSplat(o);
        }
      }
      args = ((function() {
        _ref4 = this.args;
        _result = [];
        for (_j = 0, _len2 = _ref4.length; _j < _len2; _j++) {
          arg = _ref4[_j];
          _result.push(arg.compile(o, LVL_LIST));
        }
        return _result;
      }).call(this)).join(', ');
      return this.isSuper ? this.compileSuper(args, o) : (this.isNew ? 'new ' : '') + this.variable.compile(o, LVL_ACCESS) + ("(" + args + ")");
    };
    Call.prototype.compileSuper = function(args, o) {
      return "" + (this.superReference(o)) + ".call(this" + (args.length ? ', ' : '') + args + ")";
    };
    Call.prototype.compileSplat = function(o) {
      var base, fun, idt, name, ref, splatargs;
      splatargs = this.compileSplatArguments(o);
      if (this.isSuper) {
        return "" + (this.superReference(o)) + ".apply(this, " + splatargs + ")";
      }
      if (!this.isNew) {
        base = Value.wrap(this.variable);
        if ((name = base.properties.pop()) && base.isComplex()) {
          ref = o.scope.freeVariable('this');
          fun = "(" + ref + " = " + (base.compile(o, LVL_LIST)) + ")" + (name.compile(o));
        } else {
          fun = ref = base.compile(o, LVL_ACCESS);
          if (name) {
            fun += name.compile(o);
          }
        }
        return "" + fun + ".apply(" + ref + ", " + splatargs + ")";
      }
      idt = this.idt(1);
      return "(function(func, args, ctor) {\n" + idt + "ctor.prototype = func.prototype;\n" + idt + "var child = new ctor, result = func.apply(child, args);\n" + idt + "return typeof result === \"object\" ? result : child;\n" + this.tab + "})(" + (this.variable.compile(o, LVL_LIST)) + ", " + splatargs + ", function() {})";
    };
    return Call;
  })();
  exports.Extends = (function() {
    Extends = (function() {
      function Extends(_arg, _arg2) {
        this.parent = _arg2;
        this.child = _arg;
        Extends.__super__.constructor.call(this);
        return this;
      };
      return Extends;
    })();
    __extends(Extends, Base);
    Extends.prototype.children = ['child', 'parent'];
    Extends.prototype.compile = function(o) {
      return new Call(new Value(new Literal(utility('extends'))), [this.child, this.parent]).compile(o);
    };
    return Extends;
  })();
  exports.Accessor = (function() {
    Accessor = (function() {
      function Accessor(_arg, tag) {
        this.name = _arg;
        Accessor.__super__.constructor.call(this);
        this.proto = tag === 'prototype' ? '.prototype' : '';
        this.soakNode = tag === 'soak';
        return this;
      };
      return Accessor;
    })();
    __extends(Accessor, Base);
    Accessor.prototype.children = ['name'];
    Accessor.prototype.compile = function(o) {
      var name;
      name = this.name.compile(o);
      return this.proto + (IS_STRING.test(name) ? "[" + name + "]" : "." + name);
    };
    Accessor.prototype.isComplex = NO;
    return Accessor;
  })();
  exports.Index = (function() {
    Index = (function() {
      function Index(_arg) {
        this.index = _arg;
        Index.__super__.constructor.call(this);
        return this;
      };
      return Index;
    })();
    __extends(Index, Base);
    Index.prototype.children = ['index'];
    Index.prototype.compile = function(o) {
      return (this.proto ? '.prototype' : '') + ("[" + (this.index.compile(o, LVL_PAREN)) + "]");
    };
    Index.prototype.isComplex = function() {
      return this.index.isComplex();
    };
    return Index;
  })();
  exports.ObjectLiteral = (function() {
    ObjectLiteral = (function() {
      function ObjectLiteral(props) {
        ObjectLiteral.__super__.constructor.call(this);
        this.objects = this.properties = props || [];
        return this;
      };
      return ObjectLiteral;
    })();
    __extends(ObjectLiteral, Base);
    ObjectLiteral.prototype.children = ['properties'];
    ObjectLiteral.prototype.compileNode = function(o) {
      var _i, _len, _ref2, _result, i, indent, join, lastNoncom, nonComments, obj, prop, props;
      o.indent = this.idt(1);
      nonComments = (function() {
        _ref2 = this.properties;
        _result = [];
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          prop = _ref2[_i];
          if (!(prop instanceof Comment)) {
            _result.push(prop);
          }
        }
        return _result;
      }).call(this);
      lastNoncom = last(nonComments);
      props = (function() {
        _ref2 = this.properties;
        _result = [];
        for (i = 0, _len = _ref2.length; i < _len; i++) {
          prop = _ref2[i];
          _result.push((function() {
            join = i === this.properties.length - 1 ? '' : prop === lastNoncom || prop instanceof Comment ? '\n' : ',\n';
            indent = prop instanceof Comment ? '' : this.idt(1);
            if (prop instanceof Value && prop.tags["this"]) {
              prop = new Assign(prop.properties[0].name, prop, 'object');
            } else if (!(prop instanceof Assign) && !(prop instanceof Comment)) {
              prop = new Assign(prop, prop, 'object');
            }
            return indent + prop.compile(o) + join;
          }).call(this));
        }
        return _result;
      }).call(this);
      props = props.join('');
      obj = "{" + (props ? '\n' + props + '\n' + this.idt() : '') + "}";
      return this.tags.front ? "(" + obj + ")" : obj;
    };
    ObjectLiteral.prototype.assigns = function(name) {
      var _i, _len, _ref2, prop;
      _ref2 = this.properties;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        prop = _ref2[_i];
        if (prop.assigns(name)) {
          return true;
        }
      }
      return false;
    };
    return ObjectLiteral;
  })();
  exports.ArrayLiteral = (function() {
    ArrayLiteral = (function() {
      function ArrayLiteral(objs) {
        ArrayLiteral.__super__.constructor.call(this);
        this.objects = objs || [];
        return this;
      };
      return ArrayLiteral;
    })();
    __extends(ArrayLiteral, Base);
    ArrayLiteral.prototype.children = ['objects'];
    ArrayLiteral.prototype.compileSplatLiteral = function(o) {
      return Splat.compileSplattedArray(this.objects, o);
    };
    ArrayLiteral.prototype.compileNode = function(o) {
      var _i, _len, _len2, _ref2, _ref3, code, i, obj, objects;
      o.indent = this.idt(1);
      _ref2 = this.objects;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        obj = _ref2[_i];
        if (obj instanceof Splat) {
          return this.compileSplatLiteral(o);
        }
      }
      objects = [];
      _ref3 = this.objects;
      for (i = 0, _len2 = _ref3.length; i < _len2; i++) {
        obj = _ref3[i];
        code = obj.compile(o, LVL_LIST);
        objects.push((obj instanceof Comment ? "\n" + code + "\n" + o.indent : i === this.objects.length - 1 ? code : code + ', '));
      }
      objects = objects.join('');
      return 0 < objects.indexOf('\n') ? "[\n" + o.indent + objects + "\n" + this.tab + "]" : "[" + objects + "]";
    };
    ArrayLiteral.prototype.assigns = function(name) {
      var _i, _len, _ref2, obj;
      _ref2 = this.objects;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        obj = _ref2[_i];
        if (obj.assigns(name)) {
          return true;
        }
      }
      return false;
    };
    return ArrayLiteral;
  })();
  exports.Class = (function() {
    Class = (function() {
      function Class(variable, _arg, props) {
        this.parent = _arg;
        Class.__super__.constructor.call(this);
        this.variable = variable === '__temp__' ? new Literal(variable) : variable;
        this.properties = props || [];
        this.returns = false;
        return this;
      };
      return Class;
    })();
    __extends(Class, Base);
    Class.prototype.children = ['variable', 'parent', 'properties'];
    Class.prototype.isStatement = YES;
    Class.prototype.makeReturn = function() {
      this.returns = true;
      return this;
    };
    Class.prototype.compileNode = function(o) {
      var _i, _len, _ref2, _ref3, access, applied, apply, className, constScope, construct, constructor, extension, func, me, pname, prop, props, pvar, ref, val, variable;
      variable = this.variable;
      if (variable.value === '__temp__') {
        variable = new Literal(o.scope.freeVariable('ctor'));
      }
      extension = this.parent && new Extends(variable, this.parent);
      props = new Expressions;
      me = null;
      className = variable.compile(o);
      constScope = null;
      if (this.parent) {
        applied = new Value(this.parent, [new Accessor(new Literal('apply'))]);
        constructor = new Code([], new Expressions([new Call(applied, [new Literal('this'), new Literal('arguments')])]));
      } else {
        constructor = new Code([], new Expressions([new Return(new Literal('this'))]));
      }
      _ref2 = this.properties;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        prop = _ref2[_i];
        pvar = prop.variable, func = prop.value;
        if (pvar && pvar.base.value === 'constructor') {
          if (!(func instanceof Code)) {
            _ref3 = func.cache(o), func = _ref3[0], ref = _ref3[1];
            if (func !== ref) {
              props.push(func);
            }
            apply = new Call(new Value(ref, [new Accessor(new Literal('apply'))]), [new Literal('this'), new Literal('arguments')]);
            func = new Code([], new Expressions([apply]));
          }
          if (func.bound) {
            throw SyntaxError('cannot define a constructor as a bound function.');
          }
          func.name = className;
          func.body.push(new Return(new Literal('this')));
          variable = new Value(variable);
          variable.namespaced = 0 < className.indexOf('.');
          constructor = func;
          if (last(props.expressions) instanceof Comment) {
            constructor.comment = props.expressions.pop();
          }
          continue;
        }
        if (func instanceof Code && func.bound) {
          if (prop.context === 'this') {
            func.context = className;
          } else {
            func.bound = false;
            constScope || (constScope = new Scope(o.scope, constructor.body, constructor));
            me || (me = constScope.freeVariable('this'));
            pname = pvar.compile(o);
            if (constructor.body.empty()) {
              constructor.body.push(new Return(new Literal('this')));
            }
            constructor.body.unshift(new Literal("this." + pname + " = function(){ return " + className + ".prototype." + pname + ".apply(" + me + ", arguments); }"));
          }
        }
        if (pvar) {
          access = prop.context === 'this' ? pvar.base.properties[0] : new Accessor(pvar, 'prototype');
          val = new Value(variable, [access]);
          prop = new Assign(val, func);
        }
        props.push(prop);
      }
      constructor.className = className.match(/[$\w]+$/);
      if (me) {
        constructor.body.unshift(new Literal("" + me + " = this"));
      }
      o.sharedScope = constScope;
      construct = this.tab + new Assign(variable, constructor).compile(o) + ';';
      if (extension) {
        construct += '\n' + this.tab + extension.compile(o) + ';';
      }
      if (!props.empty()) {
        construct += '\n' + props.compile(o);
      }
      if (this.returns) {
        construct += '\n' + new Return(variable).compile(o);
      }
      return construct;
    };
    return Class;
  })();
  exports.Assign = (function() {
    Assign = (function() {
      function Assign(_arg, _arg2, _arg3) {
        this.context = _arg3;
        this.value = _arg2;
        this.variable = _arg;
        Assign.__super__.constructor.call(this);
        return this;
      };
      return Assign;
    })();
    __extends(Assign, Base);
    Assign.prototype.METHOD_DEF = /^(?:(\S+)\.prototype\.)?([$A-Za-z_][$\w]*)$/;
    Assign.prototype.CONDITIONAL = ['||=', '&&=', '?='];
    Assign.prototype.children = ['variable', 'value'];
    Assign.prototype.assigns = function(name) {
      return this[this.context === 'object' ? 'value' : 'variable'].assigns(name);
    };
    Assign.prototype.unfoldSoak = function(o) {
      return If.unfoldSoak(o, this, 'variable');
    };
    Assign.prototype.compileNode = function(o) {
      var _ref2, isValue, match, name, val;
      if (isValue = this.variable instanceof Value) {
        if (this.variable.isArray() || this.variable.isObject()) {
          return this.compilePatternMatch(o);
        }
        if (_ref2 = this.context, __indexOf.call(this.CONDITIONAL, _ref2) >= 0) {
          return this.compileConditional(o);
        }
      }
      name = this.variable.compile(o, LVL_LIST);
      if (this.value instanceof Code && (match = this.METHOD_DEF.exec(name))) {
        this.value.name = match[2];
        this.value.klass = match[1];
      }
      val = this.value.compile(o, LVL_LIST);
      if (this.context === 'object') {
        return "" + name + ": " + val;
      }
      if (!(isValue && (this.variable.hasProperties() || this.variable.namespaced))) {
        o.scope.find(name);
      }
      val = name + (" " + (this.context || '=') + " ") + val;
      return o.level <= LVL_LIST ? val : "(" + val + ")";
    };
    Assign.prototype.compilePatternMatch = function(o) {
      var _len, _ref2, _ref3, _ref4, _ref5, accessClass, assigns, code, i, idx, isObject, obj, objects, olength, ref, splat, top, val, valVar, value;
      top = o.level === LVL_TOP;
      value = this.value;
      objects = this.variable.base.objects;
      if (!(olength = objects.length)) {
        return value.compile(o);
      }
      isObject = this.variable.isObject();
      if (top && olength === 1 && !((obj = objects[0]) instanceof Splat)) {
        if (obj instanceof Assign) {
          _ref2 = obj, (_ref3 = _ref2.variable, idx = _ref3.base, _ref3), obj = _ref2.value;
        } else {
          idx = isObject ? obj.tags["this"] ? obj.properties[0].name : obj : new Literal(0);
        }
        accessClass = IDENTIFIER.test(idx.value) ? Accessor : Index;
        (value = Value.wrap(value)).properties.push(new accessClass(idx));
        return new Assign(obj, value).compile(o);
      }
      valVar = value.compile(o, LVL_LIST);
      assigns = [];
      splat = false;
      if (!IDENTIFIER.test(valVar) || this.variable.assigns(valVar)) {
        assigns.push("" + (ref = o.scope.freeVariable('ref')) + " = " + valVar);
        valVar = ref;
      }
      for (i = 0, _len = objects.length; i < _len; i++) {
        obj = objects[i];
        idx = i;
        if (isObject) {
          if (obj instanceof Assign) {
            _ref4 = obj, (_ref5 = _ref4.variable, idx = _ref5.base, _ref5), obj = _ref4.value;
          } else {
            idx = obj.tags["this"] ? obj.properties[0].name : obj;
          }
        }
        if (!(obj instanceof Value || obj instanceof Splat)) {
          throw SyntaxError('pattern matching must use only identifiers on the left-hand side.');
        }
        accessClass = isObject && IDENTIFIER.test(idx.value) ? Accessor : Index;
        if (!splat && obj instanceof Splat) {
          val = new Literal(obj.compileValue(o, valVar, i, olength - i - 1));
          splat = true;
        } else {
          if (typeof idx !== 'object') {
            idx = new Literal(splat ? "" + valVar + ".length - " + (olength - idx) : idx);
          }
          val = new Value(new Literal(valVar), [new accessClass(idx)]);
        }
        assigns.push(new Assign(obj, val).compile(o, LVL_LIST));
      }
      if (!top) {
        assigns.push(valVar);
      }
      code = assigns.join(', ');
      return o.level < LVL_LIST ? code : "(" + code + ")";
    };
    Assign.prototype.compileConditional = function(o) {
      var _ref2, left, rite;
      _ref2 = this.variable.cacheReference(o), left = _ref2[0], rite = _ref2[1];
      return new Op(this.context.slice(0, -1), left, new Assign(rite, this.value)).compile(o);
    };
    return Assign;
  })();
  exports.Code = (function() {
    Code = (function() {
      function Code(_arg, _arg2, tag) {
        this.body = _arg2;
        this.params = _arg;
        Code.__super__.constructor.call(this);
        this.params || (this.params = []);
        this.body || (this.body = new Expressions);
        this.bound = tag === 'boundfunc';
        if (this.bound) {
          this.context = 'this';
        }
        return this;
      };
      return Code;
    })();
    __extends(Code, Base);
    Code.prototype.children = ['params', 'body'];
    Code.prototype.compileNode = function(o) {
      var _i, _len, _len2, _ref2, _ref3, _result, close, code, comm, empty, func, i, idt, open, param, params, scope, sharedScope, splat, value;
      sharedScope = del(o, 'sharedScope');
      o.scope = scope = sharedScope || new Scope(o.scope, this.body, this);
      o.indent = this.idt(1);
      empty = this.body.expressions.length === 0;
      delete o.bare;
      delete o.globals;
      splat = undefined;
      params = [];
      _ref2 = this.params;
      for (i = 0, _len = _ref2.length; i < _len; i++) {
        param = _ref2[i];
        if (splat) {
          if (param.attach) {
            param.assign = new Assign(new Value(new Literal('this'), [new Accessor(param.value)]));
            this.body.expressions.splice(splat.index + 1, 0, param.assign);
          }
          splat.trailings.push(param);
        } else {
          if (param.attach) {
            value = param.value;
            _ref3 = [new Literal(scope.freeVariable('arg')), param.splat], param = _ref3[0], param.splat = _ref3[1];
            this.body.unshift(new Assign(new Value(new Literal('this'), [new Accessor(value)]), param));
          }
          if (param.splat) {
            splat = new Splat(param.value);
            splat.index = i;
            splat.trailings = [];
            splat.arglength = this.params.length;
            this.body.unshift(splat);
          } else {
            params.push(param);
          }
        }
      }
      scope.startLevel();
      if (!(empty || this.noReturn)) {
        this.body.makeReturn();
      }
      params = (function() {
        _result = [];
        for (_i = 0, _len2 = params.length; _i < _len2; _i++) {
          param = params[_i];
          _result.push((function() {
            scope.parameter(param = param.compile(o));
            return param;
          })());
        }
        return _result;
      })();
      comm = this.comment ? this.comment.compile(o) + '\n' : '';
      if (this.className) {
        o.indent = this.idt(2);
      }
      idt = this.idt(1);
      code = this.body.expressions.length ? "\n" + (this.body.compileWithDeclarations(o)) + "\n" : '';
      if (this.className) {
        open = "(function() {\n" + comm + idt + "function " + this.className + "(";
        close = "" + (code && idt) + "};\n" + idt + "return " + this.className + ";\n" + this.tab + "})()";
      } else {
        open = "function(";
        close = "" + (code && this.tab) + "}";
      }
      func = "" + open + (params.join(', ')) + ") {" + code + close;
      scope.endLevel();
      if (this.bound) {
        return "" + (utility('bind')) + "(" + func + ", " + this.context + ")";
      }
      return this.tags.front ? "(" + func + ")" : func;
    };
    Code.prototype.traverseChildren = function(crossScope, func) {
      return crossScope ? Code.__super__.traverseChildren.call(this, crossScope, func) : undefined;
    };
    return Code;
  })();
  exports.Param = (function() {
    Param = (function() {
      function Param(_arg, _arg2, _arg3) {
        this.splat = _arg3;
        this.attach = _arg2;
        this.name = _arg;
        Param.__super__.constructor.call(this);
        this.value = new Literal(this.name);
        return this;
      };
      return Param;
    })();
    __extends(Param, Base);
    Param.prototype.children = ['name'];
    Param.prototype.compile = function(o) {
      return this.value.compile(o, LVL_LIST);
    };
    Param.prototype.toString = function() {
      var name;
      name = this.name;
      if (this.attach) {
        name = '@' + name;
      }
      if (this.splat) {
        name += '...';
      }
      return new Literal(name).toString();
    };
    return Param;
  })();
  exports.Splat = (function() {
    Splat = (function() {
      function Splat(name) {
        Splat.__super__.constructor.call(this);
        this.name = name.compile ? name : new Literal(name);
        return this;
      };
      return Splat;
    })();
    __extends(Splat, Base);
    Splat.prototype.children = ['name'];
    Splat.prototype.assigns = function(name) {
      return this.name.assigns(name);
    };
    Splat.prototype.compile = function(o) {
      return this.index != null ? this.compileParam(o) : this.name.compile(o);
    };
    Splat.prototype.compileParam = function(o) {
      var _len, _ref2, assign, end, idx, len, name, pos, trailing, variadic;
      name = this.name.compile(o);
      o.scope.find(name);
      end = '';
      if (this.trailings.length) {
        len = o.scope.freeVariable('len');
        o.scope.assign(len, 'arguments.length');
        variadic = o.scope.freeVariable('result');
        o.scope.assign(variadic, len + ' >= ' + this.arglength);
        end = this.trailings.length ? ", " + len + " - " + this.trailings.length : undefined;
        _ref2 = this.trailings;
        for (idx = 0, _len = _ref2.length; idx < _len; idx++) {
          trailing = _ref2[idx];
          if (trailing.attach) {
            assign = trailing.assign;
            trailing = new Literal(o.scope.freeVariable('arg'));
            assign.value = trailing;
          }
          pos = this.trailings.length - idx;
          o.scope.assign(trailing.compile(o), "arguments[" + variadic + " ? " + len + " - " + pos + " : " + (this.index + idx) + "]");
        }
      }
      return "" + name + " = " + (utility('slice')) + ".call(arguments, " + this.index + end + ")";
    };
    Splat.prototype.compileValue = function(o, name, index, trailings) {
      var trail;
      trail = trailings ? ", " + name + ".length - " + trailings : '';
      return "" + (utility('slice')) + ".call(" + name + ", " + index + trail + ")";
    };
    Splat.compileSplattedArray = function(list, o) {
      var _len, arg, args, code, end, i, prev;
      args = [];
      end = -1;
      for (i = 0, _len = list.length; i < _len; i++) {
        arg = list[i];
        code = arg.compile(o, LVL_LIST);
        prev = args[end];
        if (!(arg instanceof Splat)) {
          if (prev && starts(prev, '[') && ends(prev, ']')) {
            args[end] = "" + (prev.slice(0, -1)) + ", " + code + "]";
            continue;
          }
          if (prev && starts(prev, '.concat([') && ends(prev, '])')) {
            args[end] = "" + (prev.slice(0, -2)) + ", " + code + "])";
            continue;
          }
          code = "[" + code + "]";
        }
        args[++end] = i === 0 ? code : ".concat(" + code + ")";
      }
      return args.join('');
    };
    return Splat;
  }).call(this);
  exports.While = (function() {
    While = (function() {
      function While(condition, opts) {
        While.__super__.constructor.call(this);
        this.condition = (opts != null ? opts.invert : undefined) ? condition.invert() : condition;
        this.guard = opts != null ? opts.guard : undefined;
        return this;
      };
      return While;
    })();
    __extends(While, Base);
    While.prototype.children = ['condition', 'guard', 'body'];
    While.prototype.isStatement = YES;
    While.prototype.addBody = function(body) {
      this.body = body;
      return this;
    };
    While.prototype.makeReturn = function() {
      this.returns = true;
      return this;
    };
    While.prototype.compileNode = function(o) {
      var body, code, rvar, set;
      o.indent = this.idt(1);
      set = '';
      body = this.body;
      if (o.level > LVL_TOP || this.returns) {
        rvar = o.scope.freeVariable('result');
        set = "" + this.tab + rvar + " = [];\n";
        if (body) {
          body = Push.wrap(rvar, body);
        }
      }
      if (this.guard) {
        body = Expressions.wrap([new If(this.guard, body)]);
      }
      code = set + this.tab + ("while (" + (this.condition.compile(o, LVL_PAREN)) + ") {\n" + (body.compile(o, LVL_TOP)) + "\n" + this.tab + "}");
      if (this.returns) {
        o.indent = this.tab;
        code += '\n' + new Return(new Literal(rvar)).compile(o);
      }
      return code;
    };
    return While;
  })();
  exports.Op = (function() {
    Op = (function() {
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
        Op.__super__.constructor.call(this);
        this.operator = this.CONVERSIONS[op] || op;
        this.first = first;
        this.second = second;
        this.flip = !!flip;
        return this;
      };
      return Op;
    })();
    __extends(Op, Base);
    Op.prototype.CONVERSIONS = {
      '==': '===',
      '!=': '!==',
      'of': 'in'
    };
    Op.prototype.INVERSIONS = {
      '!==': '===',
      '===': '!=='
    };
    Op.prototype.CHAINABLE = ['<', '>', '>=', '<=', '===', '!=='];
    Op.prototype.PREFIX_OPERATORS = ['new', 'typeof', 'delete'];
    Op.prototype.MUTATORS = ['++', '--', 'delete'];
    Op.prototype.children = ['first', 'second'];
    Op.prototype.isUnary = function() {
      return !this.second;
    };
    Op.prototype.isComplex = function() {
      return this.operator !== '!' || this.first.isComplex();
    };
    Op.prototype.isChainable = function() {
      var _ref2;
      return _ref2 = this.operator, __indexOf.call(this.CHAINABLE, _ref2) >= 0;
    };
    Op.prototype.invert = function() {
      var op;
      if (op = this.INVERSIONS[this.operator]) {
        this.operator = op;
        return this;
      } else       return this.second ? new Parens(this).invert() : Op.__super__.invert.call(this);
    };
    Op.prototype.toString = function(idt) {
      return Op.__super__.toString.call(this, idt, this.constructor.name + ' ' + this.operator);
    };
    Op.prototype.unfoldSoak = function(o) {
      var _ref2;
      return (_ref2 = this.operator, __indexOf.call(this.MUTATORS, _ref2) >= 0) && If.unfoldSoak(o, this, 'first');
    };
    Op.prototype.compileNode = function(o) {
      if (this.isUnary()) {
        return this.compileUnary(o);
      }
      if (this.isChainable() && this.first.unwrap().isChainable()) {
        return this.compileChain(o);
      }
      if (this.operator === '?') {
        return this.compileExistence(o);
      }
      this.first.tags.front = this.tags.front;
      return "" + (this.first.compile(o, LVL_OP)) + " " + this.operator + " " + (this.second.compile(o, LVL_OP));
    };
    Op.prototype.compileChain = function(o) {
      var _ref2, shared;
      _ref2 = this.first.unwrap().second.cache(o), this.first.second = _ref2[0], shared = _ref2[1];
      return "" + (this.first.compile(o, LVL_OP)) + " && " + (shared.compile(o)) + " " + this.operator + " " + (this.second.compile(o, LVL_OP));
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
      return new Existence(fst).compile(o) + (" ? " + ref + " : " + (this.second.compile(o, LVL_LIST)));
    };
    Op.prototype.compileUnary = function(o) {
      var _ref2, parts, space;
      space = (_ref2 = this.operator, __indexOf.call(this.PREFIX_OPERATORS, _ref2) >= 0) || this.first instanceof Op ? ' ' : '';
      parts = [this.operator, space, this.first.compile(o, LVL_OP)];
      return (this.flip ? parts.reverse() : parts).join('');
    };
    return Op;
  })();
  exports.In = (function() {
    In = (function() {
      function In(_arg, _arg2) {
        this.array = _arg2;
        this.object = _arg;
        In.__super__.constructor.call(this);
        return this;
      };
      return In;
    })();
    __extends(In, Base);
    In.prototype.children = ['object', 'array'];
    In.prototype.invert = function() {
      this.negated = !this.negated;
      return this;
    };
    In.prototype.compileNode = function(o) {
      return this.array instanceof Value && this.array.isArray() ? this.compileOrTest(o) : this.compileLoopTest(o);
    };
    In.prototype.compileOrTest = function(o) {
      var _len, _ref2, _ref3, _ref4, _result, cmp, cnj, i, item, ref, sub, tests;
      _ref2 = this.object.cache(o, LVL_OP), sub = _ref2[0], ref = _ref2[1];
      _ref3 = this.negated ? [' !== ', ' && '] : [' === ', ' || '], cmp = _ref3[0], cnj = _ref3[1];
      tests = (function() {
        _ref4 = this.array.base.objects;
        _result = [];
        for (i = 0, _len = _ref4.length; i < _len; i++) {
          item = _ref4[i];
          _result.push((i ? ref : sub) + cmp + item.compile(o));
        }
        return _result;
      }).call(this);
      tests = tests.join(cnj);
      return o.level < LVL_OP ? tests : "(" + tests + ")";
    };
    In.prototype.compileLoopTest = function(o) {
      var _ref2, code, ref, sub;
      _ref2 = this.object.cache(o, LVL_LIST), sub = _ref2[0], ref = _ref2[1];
      code = utility('indexOf') + (".call(" + (this.array.compile(o)) + ", " + ref + ") ") + (this.negated ? '< 0' : '>= 0');
      if (sub === ref) {
        return code;
      }
      code = sub + ', ' + code;
      return o.level < LVL_LIST ? code : "(" + code + ")";
    };
    In.prototype.toString = function(idt) {
      return In.__super__.toString.call(this, idt, this.constructor.name + (this.negated ? '!' : ''));
    };
    return In;
  })();
  exports.Try = (function() {
    Try = (function() {
      function Try(_arg, _arg2, _arg3, _arg4) {
        this.ensure = _arg4;
        this.recovery = _arg3;
        this.error = _arg2;
        this.attempt = _arg;
        Try.__super__.constructor.call(this);
        return this;
      };
      return Try;
    })();
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
      o.indent = this.idt(1);
      errorPart = this.error ? " (" + (this.error.compile(o)) + ") " : ' ';
      catchPart = this.recovery ? " catch" + errorPart + "{\n" + (this.recovery.compile(o, LVL_TOP)) + "\n" + this.tab + "}" : !(this.ensure || this.recovery) ? ' catch (_e) {}' : undefined;
      return ("" + this.tab + "try {\n" + (this.attempt.compile(o, LVL_TOP)) + "\n" + this.tab + "}" + (catchPart || '')) + (this.ensure ? " finally {\n" + (this.ensure.compile(o, LVL_TOP)) + "\n" + this.tab + "}" : '');
    };
    return Try;
  })();
  exports.Throw = (function() {
    Throw = (function() {
      function Throw(_arg) {
        this.expression = _arg;
        Throw.__super__.constructor.call(this);
        return this;
      };
      return Throw;
    })();
    __extends(Throw, Base);
    Throw.prototype.children = ['expression'];
    Throw.prototype.isStatement = YES;
    Throw.prototype.makeReturn = THIS;
    Throw.prototype.compileNode = function(o) {
      return this.tab + ("throw " + (this.expression.compile(o)) + ";");
    };
    return Throw;
  })();
  exports.Existence = (function() {
    Existence = (function() {
      function Existence(_arg) {
        this.expression = _arg;
        Existence.__super__.constructor.call(this);
        return this;
      };
      return Existence;
    })();
    __extends(Existence, Base);
    Existence.prototype.children = ['expression'];
    Existence.prototype.compileNode = function(o) {
      var code;
      code = this.expression.compile(o);
      code = IDENTIFIER.test(code) && !o.scope.check(code) ? "typeof " + code + " !== \"undefined\" && " + code + " !== null" : "" + code + " != null";
      return o.level <= LVL_COND ? code : "(" + code + ")";
    };
    return Existence;
  })();
  exports.Parens = (function() {
    Parens = (function() {
      function Parens(_arg) {
        this.expression = _arg;
        Parens.__super__.constructor.call(this);
        return this;
      };
      return Parens;
    })();
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
        expr.tags.front = this.tags.front;
        return expr.compile(o);
      }
      bare = o.level < LVL_OP && (expr instanceof Op || expr instanceof Call);
      code = expr.compile(o, LVL_PAREN);
      return bare ? code : "(" + code + ")";
    };
    return Parens;
  })();
  exports.For = (function() {
    For = (function() {
      function For(_arg, head) {
        this.body = _arg;
        if (head.index instanceof Value) {
          throw SyntaxError('index cannot be a pattern matching expression');
        }
        For.__super__.constructor.call(this);
        extend(this, head);
        if (!this.object) {
          this.step || (this.step = new Literal(1));
        }
        this.pattern = this.name instanceof Value;
        if (this.range && this.pattern) {
          throw SyntaxError('cannot pattern match a range loop');
        }
        this.returns = false;
        return this;
      };
      return For;
    })();
    __extends(For, Base);
    For.prototype.children = ['body', 'source', 'guard', 'step', 'from', 'to'];
    For.prototype.isStatement = YES;
    For.prototype.makeReturn = function() {
      this.returns = true;
      return this;
    };
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
      var _ref2, _ref3, _ref4, _ref5, _ref6, body, cond, defPart, forPart, guardPart, idt, index, ivar, lvar, name, namePart, pvar, resultRet, rvar, scope, sourcePart, step, svar, tail, tvar, varPart, vars;
      scope = o.scope;
      name = !this.pattern && ((_ref2 = this.name) != null ? _ref2.compile(o) : undefined);
      index = (_ref3 = this.index) != null ? _ref3.compile(o) : undefined;
      ivar = !index ? scope.freeVariable('i') : index;
      varPart = '';
      body = Expressions.wrap([this.body]);
      idt = this.idt(1);
      if (name) {
        scope.find(name, {
          immediate: true
        });
      }
      if (index) {
        scope.find(index, {
          immediate: true
        });
      }
      if (this.step) {
        _ref4 = this.step.compileLoopReference(o, 'step'), step = _ref4[0], pvar = _ref4[1];
      }
      if (this.from) {
        _ref5 = this.to.compileLoopReference(o, 'to'), tail = _ref5[0], tvar = _ref5[1];
        vars = "" + ivar + " = " + (this.from.compile(o));
        if (tail !== tvar) {
          vars += ", " + tail;
        }
        cond = +pvar ? "" + ivar + " " + (pvar < 0 ? '>' : '<') + "= " + tvar : "" + pvar + " < 0 ? " + ivar + " >= " + tvar + " : " + ivar + " <= " + tvar;
      } else {
        if (name) {
          _ref6 = this.source.compileLoopReference(o, 'ref'), sourcePart = _ref6[0], svar = _ref6[1];
        } else {
          sourcePart = svar = this.source.compile(o, LVL_PAREN);
        }
        namePart = this.pattern ? new Assign(this.name, new Literal("" + svar + "[" + ivar + "]")).compile(o, LVL_TOP) : name ? "" + name + " = " + svar + "[" + ivar + "]" : undefined;
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
      defPart = '';
      if (this.object) {
        forPart = "" + ivar + " in " + sourcePart;
        guardPart = !this.raw && ("" + idt + "if (!" + (utility('hasProp')) + ".call(" + svar + ", " + ivar + ")) continue;\n");
      } else {
        if (step !== pvar) {
          vars += ", " + step;
        }
        if (svar !== sourcePart) {
          defPart = "" + this.tab + sourcePart + ";\n";
        }
        forPart = ("" + vars + "; " + cond + "; ") + ivar + (function() {
          switch (+pvar) {
            case 1:
              return '++';
            case -1:
              return '--';
            default:
              return pvar < 0 ? ' -= ' + pvar.slice(1) : ' += ' + pvar;
          }
        })();
      }
      if (o.level > LVL_TOP || this.returns) {
        rvar = scope.freeVariable('result');
        defPart += "" + this.tab + rvar + " = [];\n";
        resultRet = this.compileReturnValue(rvar, o);
        body = Push.wrap(rvar, body);
      }
      if (this.guard) {
        body = Expressions.wrap([new If(this.guard, body)]);
      }
      if (namePart) {
        varPart = "" + idt + namePart + ";\n";
      }
      o.indent = idt;
      return "" + (defPart || '') + this.tab + "for (" + forPart + ") {\n" + (guardPart || '') + varPart + (body.compile(o, LVL_TOP)) + "\n" + this.tab + "}" + (resultRet || '');
    };
    return For;
  })();
  exports.Switch = (function() {
    Switch = (function() {
      function Switch(_arg, _arg2, _arg3) {
        this.otherwise = _arg3;
        this.cases = _arg2;
        this.subject = _arg;
        Switch.__super__.constructor.call(this);
        return this;
      };
      return Switch;
    })();
    __extends(Switch, Base);
    Switch.prototype.children = ['subject', 'cases', 'otherwise'];
    Switch.prototype.isStatement = YES;
    Switch.prototype.makeReturn = function() {
      var _i, _len, _ref2, _ref3, pair;
      _ref2 = this.cases;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        pair = _ref2[_i];
        pair[1].makeReturn();
      }
      if ((_ref3 = this.otherwise) != null) {
        _ref3.makeReturn();
      }
      return this;
    };
    Switch.prototype.compileNode = function(o) {
      var _i, _j, _len, _len2, _ref2, _ref3, _ref4, _ref5, block, code, cond, conditions, expr, i, idt1, idt2;
      idt1 = this.idt(1);
      idt2 = o.indent = this.idt(2);
      code = this.tab + ("switch (" + (((_ref2 = this.subject) != null ? _ref2.compile(o, LVL_PAREN) : undefined) || true) + ") {\n");
      for (i = 0, _len = this.cases.length; i < _len; i++) {
        _ref3 = this.cases[i], conditions = _ref3[0], block = _ref3[1];
        _ref4 = flatten([conditions]);
        for (_i = 0, _len2 = _ref4.length; _i < _len2; _i++) {
          cond = _ref4[_i];
          if (!this.subject) {
            cond = cond.invert().invert();
          }
          code += idt1 + ("case " + (cond.compile(o, LVL_PAREN)) + ":\n");
        }
        code += block.compile(o, LVL_TOP) + '\n';
        if (i === this.cases.length - 1 && !this.otherwise) {
          break;
        }
        _ref5 = block.expressions;
        for (_j = _ref5.length - 1; _j >= 0; _j--) {
          expr = _ref5[_j];
          if (!(expr instanceof Comment)) {
            if (!(expr instanceof Return)) {
              code += idt2 + 'break;\n';
            }
            break;
          }
        }
      }
      if (this.otherwise) {
        code += idt1 + ("default:\n" + (this.otherwise.compile(o, LVL_TOP)) + "\n");
      }
      return code + this.tab + '}';
    };
    return Switch;
  })();
  exports.If = (function() {
    If = (function() {
      function If(condition, _arg, tags) {
        this.body = _arg;
        this.tags = tags || (tags = {});
        this.condition = tags.invert ? condition.invert() : condition;
        this.soakNode = tags.soak;
        this.elseBody = null;
        this.isChain = false;
        return this;
      };
      return If;
    })();
    __extends(If, Base);
    If.prototype.children = ['condition', 'body', 'elseBody'];
    If.prototype.bodyNode = function() {
      var _ref2;
      return (_ref2 = this.body) != null ? _ref2.unwrap() : undefined;
    };
    If.prototype.elseBodyNode = function() {
      var _ref2;
      return (_ref2 = this.elseBody) != null ? _ref2.unwrap() : undefined;
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
      var _ref2;
      return (o != null ? o.level : undefined) === LVL_TOP || this.bodyNode().isStatement(o) || ((_ref2 = this.elseBodyNode()) != null ? _ref2.isStatement(o) : undefined);
    };
    If.prototype.compileNode = function(o) {
      return this.isStatement(o) ? this.compileStatement(o) : this.compileExpression(o);
    };
    If.prototype.makeReturn = function() {
      if (this.isStatement()) {
        this.body && (this.body = this.ensureExpressions(this.body.makeReturn()));
        this.elseBody && (this.elseBody = this.ensureExpressions(this.elseBody.makeReturn()));
        return this;
      } else {
        return new Return(this);
      }
    };
    If.prototype.ensureExpressions = function(node) {
      return node instanceof Expressions ? node : new Expressions([node]);
    };
    If.prototype.compileStatement = function(o) {
      var body, child, cond, ifPart;
      child = del(o, 'chainChild');
      cond = this.condition.compile(o, LVL_PAREN);
      o.indent = this.idt(1);
      body = this.ensureExpressions(this.body).compile(o);
      ifPart = "if (" + cond + ") {\n" + body + "\n" + this.tab + "}";
      if (!child) {
        ifPart = this.tab + ifPart;
      }
      if (!this.elseBody) {
        return ifPart;
      }
      return ifPart + ' else ' + (this.isChain ? this.elseBodyNode().compile(merge(o, {
        indent: this.tab,
        chainChild: true
      })) : "{\n" + (this.elseBody.compile(o, LVL_TOP)) + "\n" + this.tab + "}");
    };
    If.prototype.compileExpression = function(o) {
      var _ref2, code;
      code = this.condition.compile(o, LVL_COND) + ' ? ' + this.bodyNode().compile(o, LVL_LIST) + ' : ' + ((_ref2 = this.elseBodyNode()) != null ? _ref2.compile(o, LVL_LIST) : undefined);
      return o.level >= LVL_COND ? "(" + code + ")" : code;
    };
    If.prototype.unfoldSoak = function() {
      return this.soakNode && this;
    };
    If.unfoldSoak = function(o, parent, name) {
      var ifn;
      if (!(ifn = parent[name].unfoldSoak(o))) {
        return;
      }
      parent[name] = ifn.body;
      ifn.body = new Value(parent);
      return ifn;
    };
    return If;
  }).call(this);
  Push = {
    wrap: function(name, expressions) {
      if (expressions.empty() || expressions.containsPureStatement()) {
        return expressions;
      }
      return Expressions.wrap([new Call(new Value(new Literal(name), [new Accessor(new Literal('push'))]), [expressions.unwrap()])]);
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
      return statement ? Expressions.wrap([call]) : call;
    },
    literalArgs: function(node) {
      return node instanceof Literal && node.value === 'arguments';
    },
    literalThis: function(node) {
      return node instanceof Literal && node.value === 'this' || node instanceof Code && node.bound;
    }
  };
  UTILITIES = {
    "extends": 'function(child, parent) {\n  function ctor() { this.constructor = child; }\n  ctor.prototype = parent.prototype;\n  child.prototype = new ctor;\n  if (typeof parent.extended === "function") parent.extended(child);\n  child.__super__ = parent.prototype;\n}',
    bind: 'function(func, context) {\n  return function() { return func.apply(context, arguments); };\n}',
    indexOf: 'Array.prototype.indexOf || function(item) {\n  for (var i = 0, l = this.length; i < l; i++) if (this[i] === item) return i;\n  return -1;\n}',
    hasProp: 'Object.prototype.hasOwnProperty',
    slice: 'Array.prototype.slice'
  };
  LVL_TOP = 0;
  LVL_PAREN = 1;
  LVL_LIST = 2;
  LVL_COND = 3;
  LVL_OP = 4;
  LVL_ACCESS = 5;
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
