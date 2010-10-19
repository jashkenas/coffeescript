(function() {
  var Accessor, ArrayLiteral, Assign, Base, Call, Class, Closure, Code, Comment, Existence, Expressions, Extends, For, IDENTIFIER, IS_STRING, If, In, Index, Literal, NO, NUMBER, ObjectLiteral, Op, Param, Parens, Push, Range, Return, SIMPLENUM, Scope, Slice, Splat, Switch, TAB, THIS, TRAILING_WHITESPACE, Throw, Try, UTILITIES, Value, While, YES, _ref, compact, del, ends, flatten, include, last, merge, starts, utility;
  var __extends = function(child, parent) {
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    if (typeof parent.extended === "function") parent.extended(child);
    child.__super__ = parent.prototype;
  };
  Scope = require('./scope').Scope;
  _ref = require('./helpers'), compact = _ref.compact, flatten = _ref.flatten, merge = _ref.merge, del = _ref.del, include = _ref.include, starts = _ref.starts, ends = _ref.ends, last = _ref.last;
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
    Base.prototype.compile = function(o) {
      var closure, code, top;
      this.options = o ? merge(o) : {};
      this.tab = o.indent;
      top = this.topSensitive() ? this.options.top : del(this.options, 'top');
      closure = this.isStatement(o) && !this.isPureStatement() && !top && !this.options.asStatement && !(this instanceof Comment);
      code = closure ? this.compileClosure(this.options) : this.compileNode(this.options);
      return code;
    };
    Base.prototype.compileClosure = function(o) {
      o.sharedScope = o.scope;
      if (this.containsPureStatement()) {
        throw new Error('cannot include a pure statement in an expression.');
      }
      return Closure.wrap(this).compile(o);
    };
    Base.prototype.compileReference = function(o, options) {
      var _len, compiled, i, node, pair, reference;
      pair = (function() {
        if (!this.isComplex()) {
          return [this, this];
        } else {
          reference = new Literal(o.scope.freeVariable('ref'));
          compiled = new Assign(reference, this);
          return [compiled, reference];
        }
      }).call(this);
      if (((options != null) ? options.precompile : undefined)) {
        for (i = 0, _len = pair.length; i < _len; i++) {
          node = pair[i];
          (pair[i] = node.compile(o));
        }
      }
      return pair;
    };
    Base.prototype.idt = function(tabs) {
      var idt, num;
      idt = this.tab || '';
      num = (tabs || 0) + 1;
      while (num -= 1) {
        idt += TAB;
      }
      return idt;
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
    Base.prototype.traverse = function(block) {
      return this.traverseChildren(true, block);
    };
    Base.prototype.toString = function(idt, override) {
      var _i, _len, _ref2, _result, child, children, klass;
      idt || (idt = '');
      children = (function() {
        _result = [];
        for (_i = 0, _len = (_ref2 = this.collectChildren()).length; _i < _len; _i++) {
          child = _ref2[_i];
          _result.push(child.toString(idt + TAB));
        }
        return _result;
      }).call(this).join('');
      klass = override || this.constructor.name + (this.soakNode ? '?' : '');
      return '\n' + idt + klass + children;
    };
    Base.prototype.eachChild = function(func) {
      var _i, _j, _len, _len2, _ref2, _ref3, _result, attr, child;
      if (!this.children) {
        return;
      }
      _result = [];
      for (_i = 0, _len = (_ref2 = this.children).length; _i < _len; _i++) {
        attr = _ref2[_i];
        if (this[attr]) {
          for (_j = 0, _len2 = (_ref3 = flatten([this[attr]])).length; _j < _len2; _j++) {
            child = _ref3[_j];
            if (func(child) === false) {
              return;
            }
          }
        }
      }
      return _result;
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
        return crossScope || !(child instanceof Code) ? child.traverseChildren(crossScope, func) : undefined;
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
    Base.prototype.topSensitive = NO;
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
      var end, idx;
      end = this.expressions[(idx = this.expressions.length - 1)];
      if (end instanceof Comment) {
        end = this.expressions[idx -= 1];
      }
      if (end && !(end instanceof Return)) {
        this.expressions[idx] = end.makeReturn();
      }
      return this;
    };
    Expressions.prototype.compile = function(o) {
      o || (o = {});
      return o.scope ? Expressions.__super__.compile.call(this, o) : this.compileRoot(o);
    };
    Expressions.prototype.compileNode = function(o) {
      var _i, _len, _ref2, _result, node;
      return (function() {
        _result = [];
        for (_i = 0, _len = (_ref2 = this.expressions).length; _i < _len; _i++) {
          node = _ref2[_i];
          _result.push(this.compileExpression(node, merge(o)));
        }
        return _result;
      }).call(this).join('\n');
    };
    Expressions.prototype.compileRoot = function(o) {
      var code;
      o.indent = (this.tab = o.bare ? '' : TAB);
      o.scope = new Scope(null, this, null);
      code = this.compileWithDeclarations(o);
      code = code.replace(TRAILING_WHITESPACE, '');
      return o.bare ? code : ("(function() {\n" + code + "\n}).call(this);\n");
    };
    Expressions.prototype.compileWithDeclarations = function(o) {
      var code;
      code = this.compileNode(o);
      if (o.scope.hasAssignments(this)) {
        code = ("" + (this.tab) + "var " + (o.scope.compiledAssignments().replace(/\n/g, '$&' + this.tab)) + ";\n" + code);
      }
      if (!o.globals && o.scope.hasDeclarations(this)) {
        code = ("" + (this.tab) + "var " + (o.scope.compiledDeclarations()) + ";\n" + code);
      }
      return code;
    };
    Expressions.prototype.compileExpression = function(node, o) {
      var compiledNode;
      this.tab = o.indent;
      node.tags.front = true;
      compiledNode = node.compile(merge(o, {
        top: true
      }));
      return node.isStatement(o) ? compiledNode : ("" + (this.idt()) + compiledNode + ";");
    };
    return Expressions;
  })();
  Expressions.wrap = function(nodes) {
    if (nodes.length === 1 && nodes[0] instanceof Expressions) {
      return nodes[0];
    }
    return new Expressions(nodes);
  };
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
    Literal.prototype.isStatement = function() {
      var _ref2;
      return ((_ref2 = this.value) === 'break' || _ref2 === 'continue' || _ref2 === 'debugger');
    };
    Literal.prototype.isPureStatement = Literal.prototype.isStatement;
    Literal.prototype.isComplex = NO;
    Literal.prototype.isReserved = function() {
      return !!this.value.reserved;
    };
    Literal.prototype.assigns = function(name) {
      return name === this.value;
    };
    Literal.prototype.compileNode = function(o) {
      var end, idt, val;
      idt = this.isStatement(o) ? this.idt() : '';
      end = this.isStatement(o) ? ';' : '';
      val = this.isReserved() ? ("\"" + (this.value) + "\"") : this.value;
      return idt + val + end;
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
    Return.prototype.isStatement = YES;
    Return.prototype.isPureStatement = YES;
    Return.prototype.children = ['expression'];
    Return.prototype.makeReturn = THIS;
    Return.prototype.compile = function(o) {
      var _ref2, expr;
      expr = (((_ref2 = this.expression) != null) ? _ref2.makeReturn() : undefined);
      if (expr && (!(expr instanceof Return))) {
        return expr.compile(o);
      }
      return Return.__super__.compile.call(this, o);
    };
    Return.prototype.compileNode = function(o) {
      var expr;
      expr = '';
      if (this.expression) {
        if (this.expression.isStatement(o)) {
          o.asStatement = true;
        }
        expr = ' ' + this.expression.compile(o);
      }
      return "" + (this.tab) + "return" + expr + ";";
    };
    return Return;
  })();
  exports.Value = (function() {
    Value = (function() {
      function Value(_arg, _arg2, tag) {
        this.properties = _arg2;
        this.base = _arg;
        Value.__super__.constructor.call(this);
        this.properties || (this.properties = []);
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
    Value.prototype.isSplice = function() {
      return last(this.properties) instanceof Slice;
    };
    Value.prototype.isComplex = function() {
      return this.base.isComplex() || this.hasProperties();
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
      return this.base.isStatement(o) && !this.properties.length;
    };
    Value.prototype.isSimpleNumber = function() {
      return this.base instanceof Literal && SIMPLENUM.test(this.base.value);
    };
    Value.prototype.cacheReference = function(o) {
      var base, bref, name, nref;
      name = last(this.properties);
      if (!this.base.isComplex() && this.properties.length < 2 && !((name != null) ? name.isComplex() : undefined)) {
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
    Value.prototype.compile = function(o) {
      this.base.tags.front = this.tags.front;
      return !o.top || this.properties.length ? Value.__super__.compile.call(this, o) : this.base.compile(o);
    };
    Value.prototype.compileNode = function(o) {
      var _i, _len, code, ifn, prop, props;
      if (ifn = this.unfoldSoak(o)) {
        return ifn.compile(o);
      }
      props = this.properties;
      if (this.parenthetical && !props.length) {
        this.base.parenthetical = true;
      }
      code = this.base.compile(o);
      if (props[0] instanceof Accessor && this.isSimpleNumber()) {
        code = ("(" + code + ")");
      }
      for (_i = 0, _len = props.length; _i < _len; _i++) {
        prop = props[_i];
        (code += prop.compile(o));
      }
      return code;
    };
    Value.prototype.unfoldSoak = function(o) {
      var _len, _ref2, fst, i, ifn, prop, ref, snd;
      if (ifn = this.base.unfoldSoak(o)) {
        Array.prototype.push.apply(ifn.body.properties, this.properties);
        return ifn;
      }
      for (i = 0, _len = (_ref2 = this.properties).length; i < _len; i++) {
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
          ifn = new If(new Existence(fst), snd, {
            soak: true
          });
          return ifn;
        }
      }
      return null;
    };
    return Value;
  })();
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
    Comment.prototype.isStatement = YES;
    Comment.prototype.makeReturn = THIS;
    Comment.prototype.compileNode = function(o) {
      return this.tab + '/*' + this.comment.replace(/\n/g, '\n' + this.tab) + '*/';
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
    Call.prototype.prefix = function() {
      return this.isNew ? 'new ' : '';
    };
    Call.prototype.superReference = function(o) {
      var method, name;
      method = o.scope.method;
      if (!method) {
        throw Error("cannot call super outside of a function.");
      }
      name = method.name;
      if (!name) {
        throw Error("cannot call super on an anonymous function.");
      }
      return method.klass ? ("" + (method.klass) + ".__super__." + name) : ("" + name + ".__super__.constructor");
    };
    Call.prototype.unfoldSoak = function(o) {
      var _i, _len, _ref2, _ref3, call, ifn, left, list, rite, val;
      if (this.soakNode) {
        if (val = this.variable) {
          if (!(val instanceof Value)) {
            val = new Value(val);
          }
          _ref2 = val.cacheReference(o), left = _ref2[0], rite = _ref2[1];
        } else {
          left = new Literal(this.superReference(o));
          rite = new Value(left);
        }
        rite = new Call(rite, this.args);
        rite.isNew = this.isNew;
        left = new Literal("typeof " + (left.compile(o)) + " === \"function\"");
        ifn = new If(left, new Value(rite), {
          soak: true
        });
        return ifn;
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
      for (_i = 0, _len = (_ref3 = list.reverse()).length; _i < _len; _i++) {
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
      var _i, _j, _len, _len2, _ref2, _ref3, _ref4, _result, arg, args, ifn;
      if (ifn = this.unfoldSoak(o)) {
        return ifn.compile(o);
      }
      (((_ref2 = this.variable) != null) ? (_ref2.tags.front = this.tags.front) : undefined);
      for (_i = 0, _len = (_ref3 = this.args).length; _i < _len; _i++) {
        arg = _ref3[_i];
        if (arg instanceof Splat) {
          return this.compileSplat(o);
        }
      }
      args = (function() {
        _result = [];
        for (_j = 0, _len2 = (_ref4 = this.args).length; _j < _len2; _j++) {
          arg = _ref4[_j];
          _result.push((arg.parenthetical = true) && arg.compile(o));
        }
        return _result;
      }).call(this).join(', ');
      return this.isSuper ? this.compileSuper(args, o) : ("" + (this.prefix()) + (this.variable.compile(o)) + "(" + args + ")");
    };
    Call.prototype.compileSuper = function(args, o) {
      return "" + (this.superReference(o)) + ".call(this" + (args.length ? ', ' : '') + args + ")";
    };
    Call.prototype.compileSplat = function(o) {
      var base, fun, idt, name, ref, splatargs;
      splatargs = this.compileSplatArguments(o);
      if (this.isSuper) {
        return ("" + (this.superReference(o)) + ".apply(this, " + splatargs + ")");
      }
      if (!this.isNew) {
        if (!((base = this.variable) instanceof Value)) {
          base = new Value(base);
        }
        if ((name = base.properties.pop()) && base.isComplex()) {
          ref = o.scope.freeVariable('this');
          fun = ("(" + ref + " = " + (base.compile(o)) + ")" + (name.compile(o)));
        } else {
          fun = (ref = base.compile(o));
          if (name) {
            fun += name.compile(o);
          }
        }
        return ("" + fun + ".apply(" + ref + ", " + splatargs + ")");
      }
      idt = this.idt(1);
      return "(function(func, args, ctor) {\n" + idt + "ctor.prototype = func.prototype;\n" + idt + "var child = new ctor, result = func.apply(child, args);\n" + idt + "return typeof result === \"object\" ? result : child;\n" + (this.tab) + "})(" + (this.variable.compile(o)) + ", " + splatargs + ", function() {})";
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
    Extends.prototype.compileNode = function(o) {
      var ref;
      ref = new Value(new Literal(utility('extends')));
      return (new Call(ref, [this.child, this.parent])).compile(o);
    };
    return Extends;
  })();
  exports.Accessor = (function() {
    Accessor = (function() {
      function Accessor(_arg, tag) {
        this.name = _arg;
        Accessor.__super__.constructor.call(this);
        this.prototype = tag === 'prototype' ? '.prototype' : '';
        this.soakNode = tag === 'soak';
        return this;
      };
      return Accessor;
    })();
    __extends(Accessor, Base);
    Accessor.prototype.children = ['name'];
    Accessor.prototype.compileNode = function(o) {
      var name, namePart;
      name = this.name.compile(o);
      namePart = name.match(IS_STRING) ? ("[" + name + "]") : ("." + name);
      return this.prototype + namePart;
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
    Index.prototype.compileNode = function(o) {
      var idx, prefix;
      idx = this.index.compile(o);
      prefix = this.proto ? '.prototype' : '';
      return "" + prefix + "[" + idx + "]";
    };
    Index.prototype.isComplex = function() {
      return this.index.isComplex();
    };
    return Index;
  })();
  exports.Range = (function() {
    Range = (function() {
      function Range(_arg, _arg2, tag) {
        this.to = _arg2;
        this.from = _arg;
        Range.__super__.constructor.call(this);
        this.exclusive = tag === 'exclusive';
        this.equals = this.exclusive ? '' : '=';
        return this;
      };
      return Range;
    })();
    __extends(Range, Base);
    Range.prototype.children = ['from', 'to'];
    Range.prototype.compileVariables = function(o) {
      var _ref2, _ref3, _ref4, parts;
      o = merge(o, {
        top: true
      });
      _ref2 = this.from.compileReference(o, {
        precompile: true
      }), this.from = _ref2[0], this.fromVar = _ref2[1];
      _ref3 = this.to.compileReference(o, {
        precompile: true
      }), this.to = _ref3[0], this.toVar = _ref3[1];
      _ref4 = [this.fromVar.match(SIMPLENUM), this.toVar.match(SIMPLENUM)], this.fromNum = _ref4[0], this.toNum = _ref4[1];
      parts = [];
      if (this.from !== this.fromVar) {
        parts.push(this.from);
      }
      return this.to !== this.toVar ? parts.push(this.to) : undefined;
    };
    Range.prototype.compileNode = function(o) {
      var compare, idx, incr, intro, step, stepPart, vars;
      this.compileVariables(o);
      if (!o.index) {
        return this.compileArray(o);
      }
      if (this.fromNum && this.toNum) {
        return this.compileSimple(o);
      }
      idx = del(o, 'index');
      step = del(o, 'step');
      vars = ("" + idx + " = " + (this.from)) + (this.to !== this.toVar ? (", " + (this.to)) : '');
      intro = ("(" + (this.fromVar) + " <= " + (this.toVar) + " ? " + idx);
      compare = ("" + intro + " <" + (this.equals) + " " + (this.toVar) + " : " + idx + " >" + (this.equals) + " " + (this.toVar) + ")");
      stepPart = step ? step.compile(o) : '1';
      incr = step ? ("" + idx + " += " + stepPart) : ("" + intro + " += " + stepPart + " : " + idx + " -= " + stepPart + ")");
      return "" + vars + "; " + compare + "; " + incr;
    };
    Range.prototype.compileSimple = function(o) {
      var _ref2, from, idx, step, to;
      _ref2 = [+this.fromNum, +this.toNum], from = _ref2[0], to = _ref2[1];
      idx = del(o, 'index');
      step = del(o, 'step');
      step && (step = ("" + idx + " += " + (step.compile(o))));
      return from <= to ? ("" + idx + " = " + from + "; " + idx + " <" + (this.equals) + " " + to + "; " + (step || ("" + idx + "++"))) : ("" + idx + " = " + from + "; " + idx + " >" + (this.equals) + " " + to + "; " + (step || ("" + idx + "--")));
    };
    Range.prototype.compileArray = function(o) {
      var _i, _ref2, _ref3, _result, body, clause, i, idt, post, pre, range, result, vars;
      if (this.fromNum && this.toNum && (Math.abs(this.fromNum - this.toNum) <= 20)) {
        range = (function() {
          _result = [];
          for (var _i = _ref2 = +this.fromNum, _ref3 = +this.toNum; _ref2 <= _ref3 ? _i <= _ref3 : _i >= _ref3; _ref2 <= _ref3 ? _i += 1 : _i -= 1){ _result.push(_i); }
          return _result;
        }).call(this);
        if (this.exclusive) {
          range.pop();
        }
        return ("[" + (range.join(', ')) + "]");
      }
      idt = this.idt(1);
      i = o.scope.freeVariable('i');
      result = o.scope.freeVariable('result');
      pre = ("\n" + idt + result + " = [];");
      if (this.fromNum && this.toNum) {
        o.index = i;
        body = this.compileSimple(o);
      } else {
        vars = ("" + i + " = " + (this.from)) + (this.to !== this.toVar ? (", " + (this.to)) : '');
        clause = ("" + (this.fromVar) + " <= " + (this.toVar) + " ?");
        body = ("var " + vars + "; " + clause + " " + i + " <" + (this.equals) + " " + (this.toVar) + " : " + i + " >" + (this.equals) + " " + (this.toVar) + "; " + clause + " " + i + " += 1 : " + i + " -= 1");
      }
      post = ("{ " + result + ".push(" + i + "); }\n" + idt + "return " + result + ";\n" + (o.indent));
      return "(function() {" + pre + "\n" + idt + "for (" + body + ")" + post + "}).call(this)";
    };
    return Range;
  })();
  exports.Slice = (function() {
    Slice = (function() {
      function Slice(_arg) {
        this.range = _arg;
        Slice.__super__.constructor.call(this);
        return this;
      };
      return Slice;
    })();
    __extends(Slice, Base);
    Slice.prototype.children = ['range'];
    Slice.prototype.compileNode = function(o) {
      var from, to;
      from = this.range.from ? this.range.from.compile(o) : '0';
      to = this.range.to ? this.range.to.compile(o) : '';
      to += (!to || this.range.exclusive ? '' : ' + 1');
      if (to) {
        to = ', ' + to;
      }
      return ".slice(" + from + to + ")";
    };
    return Slice;
  })();
  exports.ObjectLiteral = (function() {
    ObjectLiteral = (function() {
      function ObjectLiteral(props) {
        ObjectLiteral.__super__.constructor.call(this);
        this.objects = (this.properties = props || []);
        return this;
      };
      return ObjectLiteral;
    })();
    __extends(ObjectLiteral, Base);
    ObjectLiteral.prototype.children = ['properties'];
    ObjectLiteral.prototype.compileNode = function(o) {
      var _i, _len, _ref2, _result, i, indent, join, lastNoncom, nonComments, obj, prop, props, top;
      top = del(o, 'top');
      o.indent = this.idt(1);
      nonComments = (function() {
        _result = [];
        for (_i = 0, _len = (_ref2 = this.properties).length; _i < _len; _i++) {
          prop = _ref2[_i];
          if (!(prop instanceof Comment)) {
            _result.push(prop);
          }
        }
        return _result;
      }).call(this);
      lastNoncom = last(nonComments);
      props = (function() {
        _result = [];
        for (i = 0, _len = (_ref2 = this.properties).length; i < _len; i++) {
          prop = _ref2[i];
          _result.push((function() {
            join = i === this.properties.length - 1 ? '' : (prop === lastNoncom || prop instanceof Comment ? '\n' : ',\n');
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
      obj = ("{" + (props ? '\n' + props + '\n' + this.idt() : '') + "}");
      return this.tags.front ? ("(" + obj + ")") : obj;
    };
    ObjectLiteral.prototype.assigns = function(name) {
      var _i, _len, _ref2, prop;
      for (_i = 0, _len = (_ref2 = this.properties).length; _i < _len; _i++) {
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
      function ArrayLiteral(_arg) {
        this.objects = _arg;
        ArrayLiteral.__super__.constructor.call(this);
        this.objects || (this.objects = []);
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
      for (_i = 0, _len = (_ref2 = this.objects).length; _i < _len; _i++) {
        obj = _ref2[_i];
        if (obj instanceof Splat) {
          return this.compileSplatLiteral(o);
        }
      }
      objects = [];
      for (i = 0, _len2 = (_ref3 = this.objects).length; i < _len2; i++) {
        obj = _ref3[i];
        code = obj.compile(o);
        objects.push(obj instanceof Comment ? ("\n" + code + "\n" + (o.indent)) : (i === this.objects.length - 1 ? code : code + ', '));
      }
      objects = objects.join('');
      return 0 < objects.indexOf('\n') ? ("[\n" + (o.indent) + objects + "\n" + (this.tab) + "]") : ("[" + objects + "]");
    };
    ArrayLiteral.prototype.assigns = function(name) {
      var _i, _len, _ref2, obj;
      for (_i = 0, _len = (_ref2 = this.objects).length; _i < _len; _i++) {
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
      function Class(variable, _arg, _arg2) {
        this.properties = _arg2;
        this.parent = _arg;
        Class.__super__.constructor.call(this);
        this.variable = variable === '__temp__' ? new Literal(variable) : variable;
        this.properties || (this.properties = []);
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
      var _i, _len, _ref2, _ref3, _ref4, access, applied, apply, className, constScope, construct, constructor, extension, func, me, pname, prop, props, pvar, ref, returns, val, variable;
      variable = this.variable;
      if (variable.value === '__temp__') {
        variable = new Literal(o.scope.freeVariable('ctor'));
      }
      extension = this.parent && new Extends(variable, this.parent);
      props = new Expressions;
      o.top = true;
      me = null;
      className = variable.compile(o);
      constScope = null;
      if (this.parent) {
        applied = new Value(this.parent, [new Accessor(new Literal('apply'))]);
        constructor = new Code([], new Expressions([new Call(applied, [new Literal('this'), new Literal('arguments')])]));
      } else {
        constructor = new Code([], new Expressions([new Return(new Literal('this'))]));
      }
      for (_i = 0, _len = (_ref2 = this.properties).length; _i < _len; _i++) {
        prop = _ref2[_i];
        _ref3 = [prop.variable, prop.value], pvar = _ref3[0], func = _ref3[1];
        if (pvar && pvar.base.value === 'constructor') {
          if (!(func instanceof Code)) {
            _ref4 = func.compileReference(o), func = _ref4[0], ref = _ref4[1];
            if (func !== ref) {
              props.push(func);
            }
            apply = new Call(new Value(ref, [new Accessor(new Literal('apply'))]), [new Literal('this'), new Literal('arguments')]);
            func = new Code([], new Expressions([apply]));
          }
          if (func.bound) {
            throw new Error("cannot define a constructor as a bound function.");
          }
          func.name = className;
          func.body.push(new Return(new Literal('this')));
          variable = new Value(variable);
          variable.namespaced = 0 < className.indexOf('.');
          constructor = func;
          if (props.expressions[props.expressions.length - 1] instanceof Comment) {
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
      constructor.className = className.match(/[\w\d\$_]+$/);
      if (me) {
        constructor.body.unshift(new Literal("" + me + " = this"));
      }
      construct = this.idt() + new Assign(variable, constructor).compile(merge(o, {
        sharedScope: constScope
      })) + ';';
      props = !props.empty() ? '\n' + props.compile(o) : '';
      extension = extension ? '\n' + this.idt() + extension.compile(o) + ';' : '';
      returns = this.returns ? '\n' + new Return(variable).compile(o) : '';
      return construct + extension + props + returns;
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
    Assign.prototype.children = ['variable', 'value'];
    Assign.prototype.topSensitive = YES;
    Assign.prototype.isValue = function() {
      return this.variable instanceof Value;
    };
    Assign.prototype.compileNode = function(o) {
      var ifn, isValue, match, name, stmt, top, val;
      if (isValue = this.isValue()) {
        if (this.variable.isArray() || this.variable.isObject()) {
          return this.compilePatternMatch(o);
        }
        if (this.variable.isSplice()) {
          return this.compileSplice(o);
        }
        if (ifn = If.unfoldSoak(o, this, 'variable')) {
          delete o.top;
          return ifn.compile(o);
        }
      }
      top = del(o, 'top');
      stmt = del(o, 'asStatement');
      name = this.variable.compile(o);
      if (this.value instanceof Code && (match = this.METHOD_DEF.exec(name))) {
        this.value.name = match[2];
        this.value.klass = match[1];
      }
      val = this.value.compile(o);
      if (this.context === 'object') {
        return ("" + name + ": " + val);
      }
      if (!(isValue && (this.variable.hasProperties() || this.variable.namespaced))) {
        o.scope.find(name);
      }
      val = ("" + name + " = " + val);
      if (stmt) {
        return ("" + (this.tab) + val + ";");
      }
      return top || this.parenthetical ? val : ("(" + val + ")");
    };
    Assign.prototype.compilePatternMatch = function(o) {
      var _len, _ref2, _ref3, accessClass, assigns, code, i, idx, isObject, obj, objects, olength, otop, ref, splat, top, val, valVar, value;
      if ((value = this.value).isStatement(o)) {
        value = Closure.wrap(value);
      }
      objects = this.variable.base.objects;
      if (!(olength = objects.length)) {
        return value.compile(o);
      }
      isObject = this.variable.isObject();
      if (o.top && olength === 1 && !((obj = objects[0]) instanceof Splat)) {
        if (obj instanceof Assign) {
          _ref2 = obj, idx = _ref2.variable.base, obj = _ref2.value;
        } else {
          idx = isObject ? (obj.tags["this"] ? obj.properties[0].name : obj) : new Literal(0);
        }
        if (!(value instanceof Value)) {
          value = new Value(value);
        }
        accessClass = IDENTIFIER.test(idx.value) ? Accessor : Index;
        value.properties.push(new accessClass(idx));
        return new Assign(obj, value).compile(o);
      }
      top = del(o, 'top');
      otop = merge(o, {
        top: true
      });
      valVar = value.compile(o);
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
            _ref3 = obj, idx = _ref3.variable.base, obj = _ref3.value;
          } else {
            idx = obj.tags["this"] ? obj.properties[0].name : obj;
          }
        }
        if (!(obj instanceof Value || obj instanceof Splat)) {
          throw new Error('pattern matching must use only identifiers on the left-hand side.');
        }
        accessClass = isObject && IDENTIFIER.test(idx.value) ? Accessor : Index;
        if (!splat && obj instanceof Splat) {
          val = new Literal(obj.compileValue(o, valVar, i, olength - i - 1));
          splat = true;
        } else {
          if (typeof idx !== 'object') {
            idx = new Literal(splat ? ("" + valVar + ".length - " + (olength - idx)) : idx);
          }
          val = new Value(new Literal(valVar), [new accessClass(idx)]);
        }
        assigns.push(new Assign(obj, val).compile(otop));
      }
      if (!top) {
        assigns.push(valVar);
      }
      code = assigns.join(', ');
      return top || this.parenthetical ? code : ("(" + code + ")");
    };
    Assign.prototype.compileSplice = function(o) {
      var from, name, plus, range, ref, to, val;
      range = this.variable.properties.pop().range;
      name = this.variable.compile(o);
      plus = range.exclusive ? '' : ' + 1';
      from = range.from ? range.from.compile(o) : '0';
      to = range.to ? range.to.compile(o) + ' - ' + from + plus : ("" + name + ".length");
      ref = o.scope.freeVariable('ref');
      val = this.value.compile(o);
      return "([].splice.apply(" + name + ", [" + from + ", " + to + "].concat(" + ref + " = " + val + ")), " + ref + ")";
    };
    Assign.prototype.assigns = function(name) {
      return this[this.context === 'object' ? 'value' : 'variable'].assigns(name);
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
      var _i, _len, _len2, _ref2, _ref3, _result, close, code, comm, empty, func, i, open, param, params, sharedScope, splat, top, value;
      sharedScope = del(o, 'sharedScope');
      top = del(o, 'top');
      o.scope = sharedScope || new Scope(o.scope, this.body, this);
      o.top = true;
      o.indent = this.idt(1);
      empty = this.body.expressions.length === 0;
      delete o.bare;
      delete o.globals;
      splat = undefined;
      params = [];
      for (i = 0, _len = (_ref2 = this.params).length; i < _len; i++) {
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
            _ref3 = [new Literal(o.scope.freeVariable('arg')), param.splat], param = _ref3[0], param.splat = _ref3[1];
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
      o.scope.startLevel();
      params = (function() {
        _result = [];
        for (_i = 0, _len2 = params.length; _i < _len2; _i++) {
          param = params[_i];
          _result.push(param.compile(o));
        }
        return _result;
      })();
      if (!(empty || this.noReturn)) {
        this.body.makeReturn();
      }
      for (_i = 0, _len2 = params.length; _i < _len2; _i++) {
        param = params[_i];
        (o.scope.parameter(param));
      }
      comm = this.comment ? this.comment.compile(o) + '\n' : '';
      if (this.className) {
        o.indent = this.idt(2);
      }
      code = this.body.expressions.length ? ("\n" + (this.body.compileWithDeclarations(o)) + "\n") : '';
      open = this.className ? ("(function() {\n" + comm + (this.idt(1)) + "function " + (this.className) + "(") : "function(";
      close = this.className ? ("" + (code && this.idt(1)) + "};\n" + (this.idt(1)) + "return " + (this.className) + ";\n" + (this.tab) + "})()") : ("" + (code && this.tab) + "}");
      func = ("" + open + (params.join(', ')) + ") {" + code + close);
      o.scope.endLevel();
      if (this.bound) {
        return ("" + (utility('bind')) + "(" + func + ", " + (this.context) + ")");
      }
      return this.tags.front ? ("(" + func + ")") : func;
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
    Param.prototype.compileNode = function(o) {
      return this.value.compile(o);
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
    Splat.prototype.compileNode = function(o) {
      return (this.index != null) ? this.compileParam(o) : this.name.compile(o);
    };
    Splat.prototype.compileParam = function(o) {
      var _len, _ref2, assign, end, idx, len, name, pos, trailing, variadic;
      name = this.name.compile(o);
      o.scope.find(name);
      end = '';
      if (this.trailings.length) {
        len = o.scope.freeVariable('len');
        o.scope.assign(len, "arguments.length");
        variadic = o.scope.freeVariable('result');
        o.scope.assign(variadic, len + ' >= ' + this.arglength);
        end = this.trailings.length ? (", " + len + " - " + (this.trailings.length)) : undefined;
        for (idx = 0, _len = (_ref2 = this.trailings).length; idx < _len; idx++) {
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
      return "" + name + " = " + (utility('slice')) + ".call(arguments, " + (this.index) + end + ")";
    };
    Splat.prototype.compileValue = function(o, name, index, trailings) {
      var trail;
      trail = trailings ? (", " + name + ".length - " + trailings) : '';
      return "" + (utility('slice')) + ".call(" + name + ", " + index + trail + ")";
    };
    Splat.compileSplattedArray = function(list, o) {
      var _len, arg, args, code, end, i, prev;
      args = [];
      end = -1;
      for (i = 0, _len = list.length; i < _len; i++) {
        arg = list[i];
        code = arg.compile(o);
        prev = args[end];
        if (!(arg instanceof Splat)) {
          if (prev && starts(prev, '[') && ends(prev, ']')) {
            args[end] = ("" + (prev.slice(0, -1)) + ", " + code + "]");
            continue;
          }
          if (prev && starts(prev, '.concat([') && ends(prev, '])')) {
            args[end] = ("" + (prev.slice(0, -2)) + ", " + code + "])");
            continue;
          }
          code = ("[" + code + "]");
        }
        args[++end] = i === 0 ? code : (".concat(" + code + ")");
      }
      return args.join('');
    };
    return Splat;
  }).call(this);
  exports.While = (function() {
    While = (function() {
      function While(condition, opts) {
        While.__super__.constructor.call(this);
        this.condition = ((opts != null) ? opts.invert : undefined) ? condition.invert() : condition;
        this.guard = ((opts != null) ? opts.guard : undefined);
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
    While.prototype.topSensitive = YES;
    While.prototype.compileNode = function(o) {
      var cond, post, pre, rvar, set, top;
      top = del(o, 'top') && !this.returns;
      o.indent = this.idt(1);
      this.condition.parenthetical = true;
      cond = this.condition.compile(o);
      o.top = true;
      set = '';
      if (!top) {
        rvar = o.scope.freeVariable('result');
        set = ("" + (this.tab) + rvar + " = [];\n");
        if (this.body) {
          this.body = Push.wrap(rvar, this.body);
        }
      }
      pre = ("" + set + (this.tab) + "while (" + cond + ")");
      if (this.guard) {
        this.body = Expressions.wrap([new If(this.guard, this.body)]);
      }
      if (this.returns) {
        post = '\n' + new Return(new Literal(rvar)).compile(merge(o, {
          indent: this.idt()
        }));
      } else {
        post = '';
      }
      return "" + pre + " {\n" + (this.body.compile(o)) + "\n" + (this.tab) + "}" + post;
    };
    return While;
  })();
  exports.Op = (function() {
    Op = (function() {
      function Op(op, first, second, flip) {
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
        (this.first = first).tags.operation = true;
        if (second) {
          (this.second = second).tags.operation = true;
        }
        this.flip = !!flip;
        return this;
      };
      return Op;
    })();
    __extends(Op, Base);
    Op.prototype.CONVERSIONS = {
      '==': '===',
      '!=': '!==',
      of: 'in'
    };
    Op.prototype.INVERSIONS = {
      '!==': '===',
      '===': '!=='
    };
    Op.prototype.CHAINABLE = ['<', '>', '>=', '<=', '===', '!=='];
    Op.prototype.ASSIGNMENT = ['||=', '&&=', '?='];
    Op.prototype.PREFIX_OPERATORS = ['new', 'typeof', 'delete'];
    Op.prototype.children = ['first', 'second'];
    Op.prototype.isUnary = function() {
      return !this.second;
    };
    Op.prototype.isComplex = function() {
      return this.operator !== '!' || this.first.isComplex();
    };
    Op.prototype.isMutator = function() {
      var _ref2;
      return ends(this.operator, '=') && !((_ref2 = this.operator) === '===' || _ref2 === '!==');
    };
    Op.prototype.isChainable = function() {
      return include(this.CHAINABLE, this.operator);
    };
    Op.prototype.invert = function() {
      var _ref2;
      if (((_ref2 = this.operator) === '===' || _ref2 === '!==')) {
        this.operator = this.INVERSIONS[this.operator];
        return this;
      } else       return this.second ? new Parens(this).invert() : Op.__super__.invert.call(this);
    };
    Op.prototype.toString = function(idt) {
      return Op.__super__.toString.call(this, idt, this.constructor.name + ' ' + this.operator);
    };
    Op.prototype.compileNode = function(o) {
      if (this.second) {
        this.first.tags.front = this.tags.front;
      }
      if (this.isChainable() && this.first.unwrap() instanceof Op && this.first.unwrap().isChainable()) {
        return this.compileChain(o);
      }
      if (include(this.ASSIGNMENT, this.operator)) {
        return this.compileAssignment(o);
      }
      if (this.isUnary()) {
        return this.compileUnary(o);
      }
      if (this.operator === '?') {
        return this.compileExistence(o);
      }
      if (this.first instanceof Op && this.first.isMutator()) {
        this.first = new Parens(this.first);
      }
      if (this.second instanceof Op && this.second.isMutator()) {
        this.second = new Parens(this.second);
      }
      return [this.first.compile(o), this.operator, this.second.compile(o)].join(' ');
    };
    Op.prototype.compileChain = function(o) {
      var _ref2, _ref3, first, second, shared;
      shared = this.first.unwrap().second;
      _ref2 = shared.compileReference(o), this.first.second = _ref2[0], shared = _ref2[1];
      _ref3 = [this.first.compile(o), this.second.compile(o), shared.compile(o)], first = _ref3[0], second = _ref3[1], shared = _ref3[2];
      return "(" + first + ") && (" + shared + " " + (this.operator) + " " + second + ")";
    };
    Op.prototype.compileAssignment = function(o) {
      var _ref2, left, rite;
      _ref2 = this.first.cacheReference(o), left = _ref2[0], rite = _ref2[1];
      rite = new Assign(rite, this.second);
      return new Op(this.operator.slice(0, -1), left, rite).compile(o);
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
      return new Existence(fst).compile(o) + (" ? " + ref + " : " + (this.second.compile(o)));
    };
    Op.prototype.compileUnary = function(o) {
      var parts, space;
      space = include(this.PREFIX_OPERATORS, this.operator) ? ' ' : '';
      parts = [this.operator, space, this.first.compile(o)];
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
    In.prototype.isArray = function() {
      return this.array instanceof Value && this.array.isArray();
    };
    In.prototype.compileNode = function(o) {
      return this.isArray() ? this.compileOrTest(o) : this.compileLoopTest(o);
    };
    In.prototype.compileOrTest = function(o) {
      var _len, _ref2, _ref3, _result, i, item, obj1, obj2, tests;
      _ref2 = this.object.compileReference(o, {
        precompile: true
      }), obj1 = _ref2[0], obj2 = _ref2[1];
      tests = (function() {
        _result = [];
        for (i = 0, _len = (_ref3 = this.array.base.objects).length; i < _len; i++) {
          item = _ref3[i];
          _result.push("" + (i ? obj2 : obj1) + " === " + (item.compile(o)));
        }
        return _result;
      }).call(this);
      return "(" + (tests.join(' || ')) + ")";
    };
    In.prototype.compileLoopTest = function(o) {
      return "" + (utility('inArray')) + "(" + (this.object.compile(o)) + ", " + (this.array.compile(o)) + ")";
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
      var attemptPart, catchPart, errorPart, finallyPart;
      o.indent = this.idt(1);
      o.top = true;
      attemptPart = this.attempt.compile(o);
      errorPart = this.error ? (" (" + (this.error.compile(o)) + ") ") : ' ';
      catchPart = this.recovery ? (" catch" + errorPart + "{\n" + (this.recovery.compile(o)) + "\n" + (this.tab) + "}") : (!(this.ensure || this.recovery) ? ' catch (_e) {}' : '');
      finallyPart = (this.ensure || '') && ' finally {\n' + this.ensure.compile(merge(o)) + ("\n" + (this.tab) + "}");
      return "" + (this.tab) + "try {\n" + attemptPart + "\n" + (this.tab) + "}" + catchPart + finallyPart;
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
      return "" + (this.tab) + "throw " + (this.expression.compile(o)) + ";";
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
      code = IDENTIFIER.test(code) && !o.scope.check(code) ? ("typeof " + code + " !== \"undefined\" && " + code + " !== null") : ("" + code + " != null");
      return this.parenthetical ? code : ("(" + code + ")");
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
    Parens.prototype.isStatement = function(o) {
      return this.expression.isStatement(o);
    };
    Parens.prototype.isComplex = function() {
      return this.expression.isComplex();
    };
    Parens.prototype.topSensitive = YES;
    Parens.prototype.makeReturn = function() {
      return this.expression.makeReturn();
    };
    Parens.prototype.compileNode = function(o) {
      var code, top;
      top = del(o, 'top');
      this.expression.parenthetical = true;
      code = this.expression.compile(o);
      if (top && this.expression.isPureStatement(o)) {
        return code;
      }
      if (this.parenthetical || this.isStatement(o)) {
        return top ? this.tab + code + ';' : code;
      }
      return "(" + code + ")";
    };
    return Parens;
  })();
  exports.For = (function() {
    For = (function() {
      function For(_arg, source, _arg2, _arg3) {
        var _ref2;
        this.index = _arg3;
        this.name = _arg2;
        this.body = _arg;
        For.__super__.constructor.call(this);
        this.source = source.source, this.guard = source.guard, this.step = source.step;
        this.raw = !!source.raw;
        this.object = !!source.object;
        if (this.object) {
          _ref2 = [this.index, this.name], this.name = _ref2[0], this.index = _ref2[1];
        }
        this.pattern = this.name instanceof Value;
        if (this.index instanceof Value) {
          throw new Error('index cannot be a pattern matching expression');
        }
        this.returns = false;
        return this;
      };
      return For;
    })();
    __extends(For, Base);
    For.prototype.children = ['body', 'source', 'guard'];
    For.prototype.isStatement = YES;
    For.prototype.topSensitive = YES;
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
      var body, codeInBody, forPart, guardPart, idt1, index, ivar, lastLine, lvar, name, namePart, nvar, range, ref, resultPart, returnResult, rvar, scope, source, sourcePart, stepPart, svar, topLevel, unstepPart, varPart, vars;
      topLevel = del(o, 'top') && !this.returns;
      range = this.source instanceof Value && this.source.base instanceof Range && !this.source.properties.length;
      source = range ? this.source.base : this.source;
      codeInBody = !this.body.containsPureStatement() && this.body.contains(function(node) {
        return node instanceof Code;
      });
      scope = o.scope;
      name = this.name && this.name.compile(o);
      index = this.index && this.index.compile(o);
      if (name && !this.pattern && (range || !codeInBody)) {
        scope.find(name, {
          immediate: true
        });
      }
      if (index) {
        scope.find(index, {
          immediate: true
        });
      }
      if (!topLevel) {
        rvar = scope.freeVariable('result');
      }
      ivar = range ? name : index;
      if (!ivar || codeInBody) {
        ivar = scope.freeVariable('i');
      }
      if (name && !range && codeInBody) {
        nvar = scope.freeVariable('i');
      }
      varPart = '';
      guardPart = '';
      unstepPart = '';
      body = Expressions.wrap([this.body]);
      idt1 = this.idt(1);
      if (range) {
        forPart = source.compile(merge(o, {
          index: ivar,
          step: this.step
        }));
      } else {
        svar = (sourcePart = this.source.compile(o));
        if ((name || !this.raw) && !(IDENTIFIER.test(svar) && scope.check(svar, {
          immediate: true
        }))) {
          sourcePart = ("" + (ref = scope.freeVariable('ref')) + " = " + svar);
          if (!this.object) {
            sourcePart = ("(" + sourcePart + ")");
          }
          svar = ref;
        }
        namePart = this.pattern ? new Assign(this.name, new Literal("" + svar + "[" + ivar + "]")).compile(merge(o, {
          top: true
        })) : (name ? ("" + name + " = " + svar + "[" + ivar + "]") : undefined);
        if (!this.object) {
          lvar = scope.freeVariable('len');
          stepPart = this.step ? ("" + ivar + " += " + (this.step.compile(o))) : ("" + ivar + "++");
          forPart = ("" + ivar + " = 0, " + lvar + " = " + sourcePart + ".length; " + ivar + " < " + lvar + "; " + stepPart);
        }
      }
      resultPart = rvar ? ("" + (this.tab) + rvar + " = [];\n") : '';
      returnResult = this.compileReturnValue(rvar, o);
      if (!topLevel) {
        body = Push.wrap(rvar, body);
      }
      if (this.guard) {
        body = Expressions.wrap([new If(this.guard, body)]);
      }
      if (codeInBody) {
        if (range) {
          body.unshift(new Literal("var " + name + " = " + ivar));
        }
        if (namePart) {
          body.unshift(new Literal("var " + namePart));
        }
        if (index) {
          body.unshift(new Literal("var " + index + " = " + ivar));
        }
        lastLine = body.expressions.pop();
        if (index) {
          body.push(new Assign(new Literal(ivar), new Literal(index)));
        }
        if (nvar) {
          body.push(new Assign(new Literal(nvar), new Literal(name)));
        }
        body.push(lastLine);
        o.indent = this.idt(1);
        body = Expressions.wrap([new Literal(body.compile(o))]);
        if (index) {
          body.push(new Assign(new Literal(index), new Literal(ivar)));
        }
        if (name) {
          body.push(new Assign(new Literal(name), new Literal(nvar || ivar)));
        }
      } else {
        if (namePart) {
          varPart = ("" + idt1 + namePart + ";\n");
        }
        if (forPart && name === ivar) {
          unstepPart = this.step ? ("" + name + " -= " + (this.step.compile(o)) + ";") : ("" + name + "--;");
          unstepPart = ("\n" + (this.tab)) + unstepPart;
        }
      }
      if (this.object) {
        forPart = ("" + ivar + " in " + sourcePart);
        if (!this.raw) {
          guardPart = ("\n" + idt1 + "if (!" + (utility('hasProp')) + ".call(" + svar + ", " + ivar + ")) continue;");
        }
      }
      body = body.compile(merge(o, {
        indent: idt1,
        top: true
      }));
      vars = range ? name : ("" + name + ", " + ivar);
      return "" + resultPart + (this.tab) + "for (" + forPart + ") {" + guardPart + "\n" + varPart + body + "\n" + (this.tab) + "}" + unstepPart + returnResult;
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
        this.tags.subjectless = !this.subject;
        this.subject || (this.subject = new Literal('true'));
        return this;
      };
      return Switch;
    })();
    __extends(Switch, Base);
    Switch.prototype.children = ['subject', 'cases', 'otherwise'];
    Switch.prototype.isStatement = YES;
    Switch.prototype.makeReturn = function() {
      var _i, _len, _ref2, pair;
      for (_i = 0, _len = (_ref2 = this.cases).length; _i < _len; _i++) {
        pair = _ref2[_i];
        pair[1].makeReturn();
      }
      if (this.otherwise) {
        this.otherwise.makeReturn();
      }
      return this;
    };
    Switch.prototype.compileNode = function(o) {
      var _i, _j, _len, _len2, _ref2, _ref3, block, code, condition, conditions, exprs, idt, pair;
      idt = (o.indent = this.idt(2));
      o.top = true;
      code = ("" + (this.tab) + "switch (" + (this.subject.compile(o)) + ") {");
      for (_i = 0, _len = (_ref2 = this.cases).length; _i < _len; _i++) {
        pair = _ref2[_i];
        conditions = pair[0], block = pair[1];
        exprs = block.expressions;
        for (_j = 0, _len2 = (_ref3 = flatten([conditions])).length; _j < _len2; _j++) {
          condition = _ref3[_j];
          if (this.tags.subjectless) {
            condition = new Op('!!', new Parens(condition));
          }
          code += ("\n" + (this.idt(1)) + "case " + (condition.compile(o)) + ":");
        }
        code += ("\n" + (block.compile(o)));
        if (!(last(exprs) instanceof Return)) {
          code += ("\n" + idt + "break;");
        }
      }
      if (this.otherwise) {
        code += ("\n" + (this.idt(1)) + "default:\n" + (this.otherwise.compile(o)));
      }
      code += ("\n" + (this.tab) + "}");
      return code;
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
    If.prototype.children = ['condition', 'body', 'elseBody', 'assigner'];
    If.prototype.topSensitive = YES;
    If.prototype.bodyNode = function() {
      var _ref2;
      return (((_ref2 = this.body) != null) ? _ref2.unwrap() : undefined);
    };
    If.prototype.elseBodyNode = function() {
      var _ref2;
      return (((_ref2 = this.elseBody) != null) ? _ref2.unwrap() : undefined);
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
      return this.statement || (this.statement = ((o != null) ? o.top : undefined) || this.bodyNode().isStatement(o) || (((_ref2 = this.elseBodyNode()) != null) ? _ref2.isStatement(o) : undefined));
    };
    If.prototype.compileCondition = function(o) {
      this.condition.parenthetical = true;
      return this.condition.compile(o);
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
      var child, condO, ifPart, top;
      top = del(o, 'top');
      child = del(o, 'chainChild');
      condO = merge(o);
      o.indent = this.idt(1);
      o.top = true;
      ifPart = ("if (" + (this.compileCondition(condO)) + ") {\n" + (this.body.compile(o)) + "\n" + (this.tab) + "}");
      if (!child) {
        ifPart = this.tab + ifPart;
      }
      if (!this.elseBody) {
        return ifPart;
      }
      return ifPart + (this.isChain ? ' else ' + this.elseBodyNode().compile(merge(o, {
        indent: this.tab,
        chainChild: true
      })) : (" else {\n" + (this.elseBody.compile(o)) + "\n" + (this.tab) + "}"));
    };
    If.prototype.compileExpression = function(o) {
      var code, elsePart, ifPart;
      this.bodyNode().tags.operation = (this.condition.tags.operation = true);
      if (this.elseBody) {
        this.elseBodyNode().tags.operation = true;
      }
      ifPart = this.condition.compile(o) + ' ? ' + this.bodyNode().compile(o);
      elsePart = this.elseBody ? this.elseBodyNode().compile(o) : 'undefined';
      code = ("" + ifPart + " : " + elsePart);
      return this.tags.operation || this.soakNode ? ("(" + code + ")") : code;
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
    inArray: '(function() {\n  var indexOf = Array.prototype.indexOf || function(item) {\n    var i = this.length; while (i--) if (this[i] === item) return i;\n    return -1;\n  };\n  return function(item, array) { return indexOf.call(array, item) > -1; };\n})();',
    hasProp: 'Object.prototype.hasOwnProperty',
    slice: 'Array.prototype.slice'
  };
  TAB = '  ';
  TRAILING_WHITESPACE = /[ \t]+$/gm;
  IDENTIFIER = /^[$A-Za-z_][$\w]*$/;
  NUMBER = /^0x[\da-f]+|^(?:\d+(\.\d+)?|\.\d+)(?:e[+-]?\d+)?$/i;
  SIMPLENUM = /^[+-]?\d+$/;
  IS_STRING = /^['"]/;
  utility = function(name) {
    var ref;
    ref = ("__" + name);
    Scope.root.assign(ref, UTILITIES[name]);
    return ref;
  };
}).call(this);
