(function() {
  var AccessorNode, ArrayNode, AssignNode, BaseNode, CallNode, ClassNode, ClosureNode, CodeNode, CommentNode, ExistenceNode, Expressions, ExtendsNode, ForNode, IDENTIFIER, IS_STRING, IfNode, InNode, IndexNode, LiteralNode, NO, NUMBER, ObjectNode, OpNode, ParamNode, ParentheticalNode, PushNode, RangeNode, ReturnNode, SIMPLENUM, Scope, SliceNode, SplatNode, SwitchNode, TAB, THIS, TRAILING_WHITESPACE, ThrowNode, TryNode, UTILITIES, ValueNode, WhileNode, YES, _ref, compact, del, ends, flatten, include, indexOf, last, literal, merge, starts, utility;
  var __extends = function(child, parent) {
    var ctor = function() {};
    ctor.prototype = parent.prototype;
    child.prototype = new ctor();
    child.prototype.constructor = child;
    if (typeof parent.extended === "function") parent.extended(child);
    child.__super__ = parent.prototype;
  };
  Scope = require('./scope').Scope;
  _ref = require('./helpers'), compact = _ref.compact, flatten = _ref.flatten, merge = _ref.merge, del = _ref.del, include = _ref.include, indexOf = _ref.indexOf, starts = _ref.starts, ends = _ref.ends, last = _ref.last;
  YES = function() {
    return true;
  };
  NO = function() {
    return false;
  };
  THIS = function() {
    return this;
  };
  exports.BaseNode = (function() {
    BaseNode = (function() {
      return function BaseNode() {
        this.tags = {};
        return this;
      };
    })();
    BaseNode.prototype.compile = function(o) {
      var closure, code, top;
      this.options = o ? merge(o) : {};
      this.tab = o.indent;
      top = this.topSensitive() ? this.options.top : del(this.options, 'top');
      closure = this.isStatement(o) && !this.isPureStatement() && !top && !this.options.asStatement && !(this instanceof CommentNode) && !this.containsPureStatement();
      if (!o.keepLevel) {
        o.scope.startLevel();
      }
      code = closure ? this.compileClosure(this.options) : this.compileNode(this.options);
      if (!o.keepLevel) {
        o.scope.endLevel();
      }
      return code;
    };
    BaseNode.prototype.compileClosure = function(o) {
      this.tab = o.indent;
      o.sharedScope = o.scope;
      return ClosureNode.wrap(this).compile(o);
    };
    BaseNode.prototype.compileReference = function(o, options) {
      var _len, compiled, i, node, pair, reference;
      pair = (function() {
        if (!(this.isComplex())) {
          return [this, this];
        } else {
          reference = literal(o.scope.freeVariable('ref'));
          compiled = new AssignNode(reference, this);
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
    BaseNode.prototype.idt = function(tabs) {
      var idt, num;
      idt = this.tab || '';
      num = (tabs || 0) + 1;
      while (num -= 1) {
        idt += TAB;
      }
      return idt;
    };
    BaseNode.prototype.makeReturn = function() {
      return new ReturnNode(this);
    };
    BaseNode.prototype.contains = function(block) {
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
    BaseNode.prototype.containsType = function(type) {
      return this instanceof type || this.contains(function(node) {
        return node instanceof type;
      });
    };
    BaseNode.prototype.containsPureStatement = function() {
      return this.isPureStatement() || this.contains(function(node) {
        return node.isPureStatement();
      });
    };
    BaseNode.prototype.traverse = function(block) {
      return this.traverseChildren(true, block);
    };
    BaseNode.prototype.toString = function(idt, override) {
      var _i, _len, _ref2, _result, child, children, klass;
      idt || (idt = '');
      children = (function() {
        _result = []; _ref2 = this.collectChildren();
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          child = _ref2[_i];
          _result.push(child.toString(idt + TAB));
        }
        return _result;
      }).call(this).join('');
      klass = override || this.constructor.name + (this.soakNode || this.exist ? '?' : '');
      return '\n' + idt + klass + children;
    };
    BaseNode.prototype.eachChild = function(func) {
      var _i, _j, _len, _len2, _ref2, _ref3, _result, attr, child;
      if (!(this.children)) {
        return null;
      }
      _result = []; _ref2 = this.children;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        attr = _ref2[_i];
        if (this[attr]) {
          _ref3 = flatten([this[attr]]);
          for (_j = 0, _len2 = _ref3.length; _j < _len2; _j++) {
            child = _ref3[_j];
            if (func(child) === false) {
              return null;
            }
          }
        }
      }
      return _result;
    };
    BaseNode.prototype.collectChildren = function() {
      var nodes;
      nodes = [];
      this.eachChild(function(node) {
        return nodes.push(node);
      });
      return nodes;
    };
    BaseNode.prototype.traverseChildren = function(crossScope, func) {
      return this.eachChild(function(child) {
        if (func(child) === false) {
          return false;
        }
        return child instanceof BaseNode && (crossScope || !(child instanceof CodeNode)) ? child.traverseChildren(crossScope, func) : undefined;
      });
    };
    BaseNode.prototype.children = [];
    BaseNode.prototype.unwrap = THIS;
    BaseNode.prototype.isStatement = NO;
    BaseNode.prototype.isPureStatement = NO;
    BaseNode.prototype.isComplex = YES;
    BaseNode.prototype.topSensitive = NO;
    return BaseNode;
  })();
  exports.Expressions = (function() {
    Expressions = (function() {
      return function Expressions(nodes) {
        Expressions.__super__.constructor.call(this);
        this.expressions = compact(flatten(nodes || []));
        return this;
      };
    })();
    __extends(Expressions, BaseNode);
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
      if (end instanceof CommentNode) {
        end = this.expressions[idx -= 1];
      }
      if (end && !(end instanceof ReturnNode)) {
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
        _result = []; _ref2 = this.expressions;
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          node = _ref2[_i];
          _result.push(this.compileExpression(node, merge(o)));
        }
        return _result;
      }).call(this).join("\n");
    };
    Expressions.prototype.compileRoot = function(o) {
      var code;
      o.indent = (this.tab = o.noWrap ? '' : TAB);
      o.scope = new Scope(null, this, null);
      code = this.compileWithDeclarations(o);
      code = code.replace(TRAILING_WHITESPACE, '');
      return o.noWrap ? code : ("(function() {\n" + code + "\n}).call(this);\n");
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
  exports.LiteralNode = (function() {
    LiteralNode = (function() {
      return function LiteralNode(_arg) {
        this.value = _arg;
        LiteralNode.__super__.constructor.call(this);
        return this;
      };
    })();
    __extends(LiteralNode, BaseNode);
    LiteralNode.prototype.makeReturn = function() {
      return this.isStatement() ? this : LiteralNode.__super__.makeReturn.call(this);
    };
    LiteralNode.prototype.isStatement = function() {
      var _ref2;
      return ('break' === (_ref2 = this.value) || 'continue' === _ref2 || 'debugger' === _ref2);
    };
    LiteralNode.prototype.isPureStatement = LiteralNode.prototype.isStatement;
    LiteralNode.prototype.isComplex = NO;
    LiteralNode.prototype.isReserved = function() {
      return !!this.value.reserved;
    };
    LiteralNode.prototype.compileNode = function(o) {
      var end, idt, val;
      idt = this.isStatement(o) ? this.idt() : '';
      end = this.isStatement(o) ? ';' : '';
      val = this.isReserved() ? ("\"" + (this.value) + "\"") : this.value;
      return idt + val + end;
    };
    LiteralNode.prototype.toString = function() {
      return ' "' + this.value + '"';
    };
    return LiteralNode;
  })();
  exports.ReturnNode = (function() {
    ReturnNode = (function() {
      return function ReturnNode(_arg) {
        this.expression = _arg;
        ReturnNode.__super__.constructor.call(this);
        return this;
      };
    })();
    __extends(ReturnNode, BaseNode);
    ReturnNode.prototype.isStatement = YES;
    ReturnNode.prototype.isPureStatement = YES;
    ReturnNode.prototype.children = ['expression'];
    ReturnNode.prototype.makeReturn = THIS;
    ReturnNode.prototype.compile = function(o) {
      var expr;
      expr = this.expression.makeReturn();
      if (!(expr instanceof ReturnNode)) {
        return expr.compile(o);
      }
      return ReturnNode.__super__.compile.call(this, o);
    };
    ReturnNode.prototype.compileNode = function(o) {
      if (this.expression.isStatement(o)) {
        o.asStatement = true;
      }
      return "" + (this.tab) + "return " + (this.expression.compile(o)) + ";";
    };
    return ReturnNode;
  })();
  exports.ValueNode = (function() {
    ValueNode = (function() {
      return function ValueNode(_arg, _arg2, tag) {
        this.properties = _arg2;
        this.base = _arg;
        ValueNode.__super__.constructor.call(this);
        this.properties || (this.properties = []);
        if (tag) {
          this.tags[tag] = true;
        }
        return this;
      };
    })();
    __extends(ValueNode, BaseNode);
    ValueNode.prototype.children = ['base', 'properties'];
    ValueNode.prototype.push = function(prop) {
      this.properties.push(prop);
      return this;
    };
    ValueNode.prototype.hasProperties = function() {
      return !!this.properties.length;
    };
    ValueNode.prototype.isArray = function() {
      return this.base instanceof ArrayNode && !this.properties.length;
    };
    ValueNode.prototype.isObject = function() {
      return this.base instanceof ObjectNode && !this.properties.length;
    };
    ValueNode.prototype.isSplice = function() {
      return last(this.properties) instanceof SliceNode;
    };
    ValueNode.prototype.isComplex = function() {
      return this.base.isComplex() || this.hasProperties();
    };
    ValueNode.prototype.makeReturn = function() {
      return this.properties.length ? ValueNode.__super__.makeReturn.call(this) : this.base.makeReturn();
    };
    ValueNode.prototype.unwrap = function() {
      return this.properties.length ? this : this.base;
    };
    ValueNode.prototype.isStatement = function(o) {
      return this.base.isStatement(o) && !this.properties.length;
    };
    ValueNode.prototype.isNumber = function() {
      return this.base instanceof LiteralNode && NUMBER.test(this.base.value);
    };
    ValueNode.prototype.cacheReference = function(o) {
      var base, bref, name, nref;
      name = last(this.properties);
      if (!this.base.isComplex() && this.properties.length < 2 && !((name != null) ? name.isComplex() : undefined)) {
        return [this, this];
      }
      base = new ValueNode(this.base, this.properties.slice(0, -1));
      if (base.isComplex()) {
        bref = literal(o.scope.freeVariable('base'));
        base = new ValueNode(new ParentheticalNode(new AssignNode(bref, base)));
      }
      if (!(name)) {
        return [base, bref];
      }
      if (name.isComplex()) {
        nref = literal(o.scope.freeVariable('name'));
        name = new IndexNode(new AssignNode(nref, name.index));
        nref = new IndexNode(nref);
      }
      return [base.push(name), new ValueNode(bref || base.base, [nref || name])];
    };
    ValueNode.prototype.compile = function(o) {
      return !o.top || this.properties.length ? ValueNode.__super__.compile.call(this, o) : this.base.compile(o);
    };
    ValueNode.prototype.compileNode = function(o) {
      var _i, _len, code, ex, prop, props;
      if (ex = this.unfoldSoak(o)) {
        return ex.compile(o);
      }
      props = this.properties;
      if (this.parenthetical && !props.length) {
        this.base.parenthetical = true;
      }
      code = this.base.compile(o);
      if (props[0] instanceof AccessorNode && this.isNumber() || o.top && this.base instanceof ObjectNode) {
        code = ("(" + code + ")");
      }
      for (_i = 0, _len = props.length; _i < _len; _i++) {
        prop = props[_i];
        (code += prop.compile(o));
      }
      return code;
    };
    ValueNode.prototype.unfoldSoak = function(o) {
      var _len, _ref2, fst, i, ifn, prop, ref, snd;
      if (this.base.soakNode) {
        Array.prototype.push.apply(this.base.body.properties, this.properties);
        return this.base;
      }
      _ref2 = this.properties;
      for (i = 0, _len = _ref2.length; i < _len; i++) {
        prop = _ref2[i];
        if (prop.soakNode) {
          prop.soakNode = false;
          fst = new ValueNode(this.base, this.properties.slice(0, i));
          snd = new ValueNode(this.base, this.properties.slice(i));
          if (fst.isComplex()) {
            ref = literal(o.scope.freeVariable('ref'));
            fst = new ParentheticalNode(new AssignNode(ref, fst));
            snd.base = ref;
          }
          ifn = new IfNode(new ExistenceNode(fst), snd, {
            operation: true
          });
          ifn.soakNode = true;
          return ifn;
        }
      }
      return null;
    };
    ValueNode.unfoldSoak = function(o, parent, name) {
      var ifnode, node;
      node = parent[name];
      if (node instanceof IfNode && node.soakNode) {
        ifnode = node;
      } else if (node instanceof ValueNode) {
        ifnode = node.unfoldSoak(o);
      }
      if (!(ifnode)) {
        return null;
      }
      parent[name] = ifnode.body;
      ifnode.body = new ValueNode(parent);
      return ifnode;
    };
    return ValueNode;
  }).call(this);
  exports.CommentNode = (function() {
    CommentNode = (function() {
      return function CommentNode(_arg) {
        this.comment = _arg;
        CommentNode.__super__.constructor.call(this);
        return this;
      };
    })();
    __extends(CommentNode, BaseNode);
    CommentNode.prototype.isStatement = YES;
    CommentNode.prototype.makeReturn = THIS;
    CommentNode.prototype.compileNode = function(o) {
      return this.tab + '/*' + this.comment.replace(/\n/g, '\n' + this.tab) + '*/';
    };
    return CommentNode;
  })();
  exports.CallNode = (function() {
    CallNode = (function() {
      return function CallNode(variable, _arg, _arg2) {
        this.exist = _arg2;
        this.args = _arg;
        CallNode.__super__.constructor.call(this);
        this.isNew = false;
        this.isSuper = variable === 'super';
        this.variable = this.isSuper ? null : variable;
        this.args || (this.args = []);
        return this;
      };
    })();
    __extends(CallNode, BaseNode);
    CallNode.prototype.children = ['variable', 'args'];
    CallNode.prototype.compileSplatArguments = function(o) {
      return SplatNode.compileSplattedArray(this.args, o);
    };
    CallNode.prototype.newInstance = function() {
      this.isNew = true;
      return this;
    };
    CallNode.prototype.prefix = function() {
      return this.isNew ? 'new ' : '';
    };
    CallNode.prototype.superReference = function(o) {
      var method, name;
      method = o.scope.method;
      if (!(method)) {
        throw Error("cannot call super outside of a function");
      }
      name = method.name;
      if (!(name)) {
        throw Error("cannot call super on an anonymous function.");
      }
      return method.klass ? ("" + (method.klass) + ".__super__." + name) : ("" + name + ".__super__.constructor");
    };
    CallNode.prototype.unfoldSoak = function(o) {
      var _i, _len, _ref2, call, list, node;
      call = this;
      list = [];
      while (true) {
        if (call.variable instanceof CallNode) {
          list.push(call);
          call = call.variable;
          continue;
        }
        if (!(call.variable instanceof ValueNode)) {
          break;
        }
        list.push(call);
        if (!((call = call.variable.base) instanceof CallNode)) {
          break;
        }
      }
      _ref2 = list.reverse();
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        call = _ref2[_i];
        if (node) {
          if (call.variable instanceof CallNode) {
            call.variable = node;
          } else {
            call.variable.base = node;
          }
        }
        node = ValueNode.unfoldSoak(o, call, 'variable');
      }
      return node;
    };
    CallNode.prototype.compileNode = function(o) {
      var _i, _len, _ref2, _result, arg, args, left, node, rite, val;
      if (node = this.unfoldSoak(o)) {
        return node.compile(o);
      }
      if (this.exist) {
        if (val = this.variable) {
          if (!(val instanceof ValueNode)) {
            val = new ValueNode(val);
          }
          _ref2 = val.cacheReference(o), left = _ref2[0], rite = _ref2[1];
          rite = new CallNode(rite, this.args);
        } else {
          left = literal(this.superReference(o));
          rite = new CallNode(new ValueNode(left), this.args);
          rite.isNew = this.isNew;
        }
        left = ("typeof " + (left.compile(o)) + " !== \"function\"");
        rite = rite.compile(o);
        return ("(" + left + " ? undefined : " + rite + ")");
      }
      _ref2 = this.args;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        arg = _ref2[_i];
        if (arg instanceof SplatNode) {
          return this.compileSplat(o);
        }
      }
      args = (function() {
        _result = []; _ref2 = this.args;
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          arg = _ref2[_i];
          _result.push((arg.parenthetical = true) && arg.compile(o));
        }
        return _result;
      }).call(this).join(', ');
      return this.isSuper ? this.compileSuper(args, o) : ("" + (this.prefix()) + (this.variable.compile(o)) + "(" + args + ")");
    };
    CallNode.prototype.compileSuper = function(args, o) {
      return "" + (this.superReference(o)) + ".call(this" + (args.length ? ', ' : '') + args + ")";
    };
    CallNode.prototype.compileSplat = function(o) {
      var _i, _len, _ref2, arg, argvar, base, call, ctor, fun, idt, name, ref, result, splatargs;
      splatargs = this.compileSplatArguments(o);
      if (this.isSuper) {
        return ("" + (this.superReference(o)) + ".apply(this, " + splatargs + ")");
      }
      if (!(this.isNew)) {
        if (!((base = this.variable) instanceof ValueNode)) {
          base = new ValueNode(base);
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
      call = 'call(this)';
      argvar = function(node) {
        return node instanceof LiteralNode && node.value === 'arguments';
      };
      _ref2 = this.args;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        arg = _ref2[_i];
        if (arg.contains(argvar)) {
          call = 'apply(this, arguments)';
          break;
        }
      }
      ctor = o.scope.freeVariable('ctor');
      ref = o.scope.freeVariable('ref');
      result = o.scope.freeVariable('result');
      return "(function() {\n" + (idt = this.idt(1)) + "var ctor = function() {};\n" + idt + (utility('extends')) + "(ctor, " + ctor + " = " + (this.variable.compile(o)) + ");\n" + idt + "return typeof (" + result + " = " + ctor + ".apply(" + ref + " = new ctor, " + splatargs + ")) === \"object\" ? " + result + " : " + ref + ";\n" + (this.tab) + "})." + call;
    };
    return CallNode;
  })();
  exports.ExtendsNode = (function() {
    ExtendsNode = (function() {
      return function ExtendsNode(_arg, _arg2) {
        this.parent = _arg2;
        this.child = _arg;
        ExtendsNode.__super__.constructor.call(this);
        return this;
      };
    })();
    __extends(ExtendsNode, BaseNode);
    ExtendsNode.prototype.children = ['child', 'parent'];
    ExtendsNode.prototype.compileNode = function(o) {
      var ref;
      ref = new ValueNode(literal(utility('extends')));
      return (new CallNode(ref, [this.child, this.parent])).compile(o);
    };
    return ExtendsNode;
  })();
  exports.AccessorNode = (function() {
    AccessorNode = (function() {
      return function AccessorNode(_arg, tag) {
        this.name = _arg;
        AccessorNode.__super__.constructor.call(this);
        this.prototype = tag === 'prototype' ? '.prototype' : '';
        this.soakNode = tag === 'soak';
        return this;
      };
    })();
    __extends(AccessorNode, BaseNode);
    AccessorNode.prototype.children = ['name'];
    AccessorNode.prototype.compileNode = function(o) {
      var name, namePart;
      name = this.name.compile(o);
      namePart = name.match(IS_STRING) ? ("[" + name + "]") : ("." + name);
      return this.prototype + namePart;
    };
    AccessorNode.prototype.isComplex = NO;
    return AccessorNode;
  })();
  exports.IndexNode = (function() {
    IndexNode = (function() {
      return function IndexNode(_arg) {
        this.index = _arg;
        IndexNode.__super__.constructor.call(this);
        return this;
      };
    })();
    __extends(IndexNode, BaseNode);
    IndexNode.prototype.children = ['index'];
    IndexNode.prototype.compileNode = function(o) {
      var idx, prefix;
      idx = this.index.compile(o);
      prefix = this.proto ? '.prototype' : '';
      return "" + prefix + "[" + idx + "]";
    };
    IndexNode.prototype.isComplex = function() {
      return this.index.isComplex();
    };
    return IndexNode;
  })();
  exports.RangeNode = (function() {
    RangeNode = (function() {
      return function RangeNode(_arg, _arg2, tag) {
        this.to = _arg2;
        this.from = _arg;
        RangeNode.__super__.constructor.call(this);
        this.exclusive = tag === 'exclusive';
        this.equals = this.exclusive ? '' : '=';
        return this;
      };
    })();
    __extends(RangeNode, BaseNode);
    RangeNode.prototype.children = ['from', 'to'];
    RangeNode.prototype.compileVariables = function(o) {
      var _ref2, parts;
      o = merge(o, {
        top: true
      });
      _ref2 = this.from.compileReference(o, {
        precompile: true
      }), this.from = _ref2[0], this.fromVar = _ref2[1];
      _ref2 = this.to.compileReference(o, {
        precompile: true
      }), this.to = _ref2[0], this.toVar = _ref2[1];
      _ref2 = [this.fromVar.match(SIMPLENUM), this.toVar.match(SIMPLENUM)], this.fromNum = _ref2[0], this.toNum = _ref2[1];
      parts = [];
      if (this.from !== this.fromVar) {
        parts.push(this.from);
      }
      if (this.to !== this.toVar) {
        parts.push(this.to);
      }
      return parts.length ? ("" + (parts.join('; ')) + "; ") : '';
    };
    RangeNode.prototype.compileNode = function(o) {
      var compare, idx, incr, intro, step, stepPart, vars;
      if (!(o.index)) {
        return this.compileArray(o);
      }
      if (this.fromNum && this.toNum) {
        return this.compileSimple(o);
      }
      idx = del(o, 'index');
      step = del(o, 'step');
      vars = ("" + idx + " = " + (this.fromVar));
      intro = ("(" + (this.fromVar) + " <= " + (this.toVar) + " ? " + idx);
      compare = ("" + intro + " <" + (this.equals) + " " + (this.toVar) + " : " + idx + " >" + (this.equals) + " " + (this.toVar) + ")");
      stepPart = step ? step.compile(o) : '1';
      incr = step ? ("" + idx + " += " + stepPart) : ("" + intro + " += " + stepPart + " : " + idx + " -= " + stepPart + ")");
      return "" + vars + "; " + compare + "; " + incr;
    };
    RangeNode.prototype.compileSimple = function(o) {
      var _ref2, from, idx, step, to;
      _ref2 = [+this.fromNum, +this.toNum], from = _ref2[0], to = _ref2[1];
      idx = del(o, 'index');
      step = del(o, 'step');
      step && (step = ("" + idx + " += " + (step.compile(o))));
      return from <= to ? ("" + idx + " = " + from + "; " + idx + " <" + (this.equals) + " " + to + "; " + (step || ("" + idx + "++"))) : ("" + idx + " = " + from + "; " + idx + " >" + (this.equals) + " " + to + "; " + (step || ("" + idx + "--")));
    };
    RangeNode.prototype.compileArray = function(o) {
      var _i, _ref2, _ref3, _result, body, clause, i, idt, post, pre, range, result, vars;
      idt = this.idt(1);
      vars = this.compileVariables(merge(o, {
        indent: idt
      }));
      if (this.fromNum && this.toNum && (Math.abs(this.fromNum - this.toNum) <= 20)) {
        range = (function() {
          _result = []; _ref2 = +this.fromNum; _ref3 = +this.toNum;
          for (var _i = _ref2; _ref2 <= _ref3 ? _i <= _ref3 : _i >= _ref3; _ref2 <= _ref3 ? _i += 1 : _i -= 1){ _result.push(_i); }
          return _result;
        }).call(this);
        if (this.exclusive) {
          range.pop();
        }
        return ("[" + (range.join(', ')) + "]");
      }
      i = o.scope.freeVariable('i');
      result = o.scope.freeVariable('result');
      pre = ("\n" + idt + result + " = []; " + vars);
      if (this.fromNum && this.toNum) {
        o.index = i;
        body = this.compileSimple(o);
      } else {
        clause = ("" + (this.fromVar) + " <= " + (this.toVar) + " ?");
        body = ("var " + i + " = " + (this.fromVar) + "; " + clause + " " + i + " <" + (this.equals) + " " + (this.toVar) + " : " + i + " >" + (this.equals) + " " + (this.toVar) + "; " + clause + " " + i + " += 1 : " + i + " -= 1");
      }
      post = ("{ " + result + ".push(" + i + "); }\n" + idt + "return " + result + ";\n" + (o.indent));
      return "(function() {" + pre + "\n" + idt + "for (" + body + ")" + post + "}).call(this)";
    };
    return RangeNode;
  })();
  exports.SliceNode = (function() {
    SliceNode = (function() {
      return function SliceNode(_arg) {
        this.range = _arg;
        SliceNode.__super__.constructor.call(this);
        return this;
      };
    })();
    __extends(SliceNode, BaseNode);
    SliceNode.prototype.children = ['range'];
    SliceNode.prototype.compileNode = function(o) {
      var from, to;
      from = this.range.from ? this.range.from.compile(o) : '0';
      to = this.range.to ? this.range.to.compile(o) : '';
      to += (!to || this.range.exclusive ? '' : ' + 1');
      if (to) {
        to = ', ' + to;
      }
      return ".slice(" + from + to + ")";
    };
    return SliceNode;
  })();
  exports.ObjectNode = (function() {
    ObjectNode = (function() {
      return function ObjectNode(props) {
        ObjectNode.__super__.constructor.call(this);
        this.objects = (this.properties = props || []);
        return this;
      };
    })();
    __extends(ObjectNode, BaseNode);
    ObjectNode.prototype.children = ['properties'];
    ObjectNode.prototype.topSensitive = YES;
    ObjectNode.prototype.compileNode = function(o) {
      var _i, _len, _ref2, _result, i, indent, join, lastNoncom, nonComments, obj, prop, props, top;
      top = del(o, 'top');
      o.indent = this.idt(1);
      nonComments = (function() {
        _result = []; _ref2 = this.properties;
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          prop = _ref2[_i];
          if (!(prop instanceof CommentNode)) {
            _result.push(prop);
          }
        }
        return _result;
      }).call(this);
      lastNoncom = last(nonComments);
      props = (function() {
        _result = []; _ref2 = this.properties;
        for (i = 0, _len = _ref2.length; i < _len; i++) {
          prop = _ref2[i];
          _result.push((function() {
            join = ",\n";
            if ((prop === lastNoncom) || (prop instanceof CommentNode)) {
              join = "\n";
            }
            if (i === this.properties.length - 1) {
              join = '';
            }
            indent = prop instanceof CommentNode ? '' : this.idt(1);
            if (prop instanceof ValueNode && prop.tags["this"]) {
              prop = new AssignNode(prop.properties[0].name, prop, 'object');
            } else if (!(prop instanceof AssignNode) && !(prop instanceof CommentNode)) {
              prop = new AssignNode(prop, prop, 'object');
            }
            return indent + prop.compile(o) + join;
          }).call(this));
        }
        return _result;
      }).call(this);
      props = props.join('');
      obj = '{' + (props ? '\n' + props + '\n' + this.idt() : '') + '}';
      return top ? ("(" + obj + ")") : obj;
    };
    return ObjectNode;
  })();
  exports.ArrayNode = (function() {
    ArrayNode = (function() {
      return function ArrayNode(_arg) {
        this.objects = _arg;
        ArrayNode.__super__.constructor.call(this);
        this.objects || (this.objects = []);
        return this;
      };
    })();
    __extends(ArrayNode, BaseNode);
    ArrayNode.prototype.children = ['objects'];
    ArrayNode.prototype.compileSplatLiteral = function(o) {
      return SplatNode.compileSplattedArray(this.objects, o);
    };
    ArrayNode.prototype.compileNode = function(o) {
      var _len, _ref2, code, i, obj, objects;
      o.indent = this.idt(1);
      objects = [];
      _ref2 = this.objects;
      for (i = 0, _len = _ref2.length; i < _len; i++) {
        obj = _ref2[i];
        code = obj.compile(o);
        if (obj instanceof SplatNode) {
          return this.compileSplatLiteral(o);
        } else if (obj instanceof CommentNode) {
          objects.push("\n" + code + "\n" + (o.indent));
        } else if (i === this.objects.length - 1) {
          objects.push(code);
        } else {
          objects.push("" + code + ", ");
        }
      }
      objects = objects.join('');
      return indexOf(objects, '\n') >= 0 ? ("[\n" + (this.idt(1)) + objects + "\n" + (this.tab) + "]") : ("[" + objects + "]");
    };
    return ArrayNode;
  })();
  exports.ClassNode = (function() {
    ClassNode = (function() {
      return function ClassNode(variable, _arg, _arg2) {
        this.properties = _arg2;
        this.parent = _arg;
        ClassNode.__super__.constructor.call(this);
        this.variable = variable === '__temp__' ? literal(variable) : variable;
        this.properties || (this.properties = []);
        this.returns = false;
        return this;
      };
    })();
    __extends(ClassNode, BaseNode);
    ClassNode.prototype.children = ['variable', 'parent', 'properties'];
    ClassNode.prototype.isStatement = YES;
    ClassNode.prototype.makeReturn = function() {
      this.returns = true;
      return this;
    };
    ClassNode.prototype.compileNode = function(o) {
      var _i, _len, _ref2, _ref3, access, applied, className, constScope, construct, constructor, extension, func, me, pname, prop, props, pvar, returns, val, variable;
      variable = this.variable;
      if (variable.value === '__temp__') {
        variable = literal(o.scope.freeVariable('ctor'));
      }
      extension = this.parent && new ExtendsNode(variable, this.parent);
      props = new Expressions;
      o.top = true;
      me = null;
      className = variable.compile(o);
      constScope = null;
      if (this.parent) {
        applied = new ValueNode(this.parent, [new AccessorNode(literal('apply'))]);
        constructor = new CodeNode([], new Expressions([new CallNode(applied, [literal('this'), literal('arguments')])]));
      } else {
        constructor = new CodeNode;
      }
      _ref2 = this.properties;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        prop = _ref2[_i];
        _ref3 = [prop.variable, prop.value], pvar = _ref3[0], func = _ref3[1];
        if (pvar && pvar.base.value === 'constructor' && func instanceof CodeNode) {
          if (func.bound) {
            throw new Error("cannot define a constructor as a bound function.");
          }
          func.name = className;
          func.body.push(new ReturnNode(literal('this')));
          variable = new ValueNode(variable);
          variable.namespaced = include(func.name, '.');
          constructor = func;
          continue;
        }
        if (func instanceof CodeNode && func.bound) {
          if (prop.context === 'this') {
            func.context = className;
          } else {
            func.bound = false;
            constScope || (constScope = new Scope(o.scope, constructor.body, constructor));
            me || (me = constScope.freeVariable('this'));
            pname = pvar.compile(o);
            if (constructor.body.empty()) {
              constructor.body.push(new ReturnNode(literal('this')));
            }
            constructor.body.unshift(literal("this." + pname + " = function(){ return " + className + ".prototype." + pname + ".apply(" + me + ", arguments); }"));
          }
        }
        if (pvar) {
          access = prop.context === 'this' ? pvar.base.properties[0] : new AccessorNode(pvar, 'prototype');
          val = new ValueNode(variable, [access]);
          prop = new AssignNode(val, func);
        }
        props.push(prop);
      }
      constructor.className = className.match(/[\w\d\$_]+$/);
      if (me) {
        constructor.body.unshift(literal("" + me + " = this"));
      }
      construct = this.idt() + new AssignNode(variable, constructor).compile(merge(o, {
        sharedScope: constScope
      })) + ';';
      props = !props.empty() ? '\n' + props.compile(o) : '';
      extension = extension ? '\n' + this.idt() + extension.compile(o) + ';' : '';
      returns = this.returns ? '\n' + new ReturnNode(variable).compile(o) : '';
      return construct + extension + props + returns;
    };
    return ClassNode;
  })();
  exports.AssignNode = (function() {
    AssignNode = (function() {
      return function AssignNode(_arg, _arg2, _arg3) {
        this.context = _arg3;
        this.value = _arg2;
        this.variable = _arg;
        AssignNode.__super__.constructor.call(this);
        return this;
      };
    })();
    __extends(AssignNode, BaseNode);
    AssignNode.prototype.METHOD_DEF = /^(?:(\S+)\.prototype\.)?([$A-Za-z_][$\w]*)$/;
    AssignNode.prototype.children = ['variable', 'value'];
    AssignNode.prototype.topSensitive = YES;
    AssignNode.prototype.isValue = function() {
      return this.variable instanceof ValueNode;
    };
    AssignNode.prototype.compileNode = function(o) {
      var isValue, match, name, node, stmt, top, val;
      if (isValue = this.isValue()) {
        if (this.variable.isArray() || this.variable.isObject()) {
          return this.compilePatternMatch(o);
        }
        if (this.variable.isSplice()) {
          return this.compileSplice(o);
        }
        if (node = ValueNode.unfoldSoak(o, this, 'variable')) {
          return node.compile(o);
        }
      }
      top = del(o, 'top');
      stmt = del(o, 'asStatement');
      name = this.variable.compile(o);
      if (this.value instanceof CodeNode && (match = this.METHOD_DEF.exec(name))) {
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
    AssignNode.prototype.compilePatternMatch = function(o) {
      var _len, _ref2, accessClass, assigns, code, i, idx, isObject, obj, objects, olength, otop, splat, top, val, valVar, value;
      if ((value = this.value).isStatement(o)) {
        value = ClosureNode.wrap(value);
      }
      objects = this.variable.base.objects;
      if (!(olength = objects.length)) {
        return value.compile(o);
      }
      isObject = this.variable.isObject();
      if (o.top && olength === 1 && !((obj = objects[0]) instanceof SplatNode)) {
        if (obj instanceof AssignNode) {
          _ref2 = obj, idx = _ref2.variable.base, obj = _ref2.value;
        } else {
          idx = isObject ? (obj.tags["this"] ? obj.properties[0].name : obj) : literal(0);
        }
        if (!(value instanceof ValueNode)) {
          value = new ValueNode(value);
        }
        accessClass = IDENTIFIER.test(idx.value) ? AccessorNode : IndexNode;
        value.properties.push(new accessClass(idx));
        return new AssignNode(obj, value).compile(o);
      }
      top = del(o, 'top');
      otop = merge(o, {
        top: true
      });
      valVar = o.scope.freeVariable('ref');
      assigns = [("" + valVar + " = " + (value.compile(o)))];
      splat = false;
      for (i = 0, _len = objects.length; i < _len; i++) {
        obj = objects[i];
        idx = i;
        if (isObject) {
          if (obj instanceof AssignNode) {
            _ref2 = [obj.value, obj.variable.base], obj = _ref2[0], idx = _ref2[1];
          } else {
            idx = obj.tags["this"] ? obj.properties[0].name : obj;
          }
        }
        if (!(obj instanceof ValueNode || obj instanceof SplatNode)) {
          throw new Error('pattern matching must use only identifiers on the left-hand side.');
        }
        accessClass = isObject && IDENTIFIER.test(idx.value) ? AccessorNode : IndexNode;
        if (!splat && obj instanceof SplatNode) {
          val = literal(obj.compileValue(o, valVar, i, olength - i - 1));
          splat = true;
        } else {
          if (typeof idx !== 'object') {
            idx = literal(splat ? ("" + valVar + ".length - " + (olength - idx)) : idx);
          }
          val = new ValueNode(literal(valVar), [new accessClass(idx)]);
        }
        assigns.push(new AssignNode(obj, val).compile(otop));
      }
      if (!(top)) {
        assigns.push(valVar);
      }
      code = assigns.join(', ');
      return top || this.parenthetical ? code : ("(" + code + ")");
    };
    AssignNode.prototype.compileSplice = function(o) {
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
    return AssignNode;
  })();
  exports.CodeNode = (function() {
    CodeNode = (function() {
      return function CodeNode(_arg, _arg2, tag) {
        this.body = _arg2;
        this.params = _arg;
        CodeNode.__super__.constructor.call(this);
        this.params || (this.params = []);
        this.body || (this.body = new Expressions);
        this.bound = tag === 'boundfunc';
        if (this.bound) {
          this.context = 'this';
        }
        return this;
      };
    })();
    __extends(CodeNode, BaseNode);
    CodeNode.prototype.children = ['params', 'body'];
    CodeNode.prototype.compileNode = function(o) {
      var _i, _len, _ref2, _ref3, _result, close, code, empty, func, i, open, param, params, sharedScope, splat, top, value;
      sharedScope = del(o, 'sharedScope');
      top = del(o, 'top');
      o.scope = sharedScope || new Scope(o.scope, this.body, this);
      o.top = true;
      o.indent = this.idt(1);
      empty = this.body.expressions.length === 0;
      del(o, 'noWrap');
      del(o, 'globals');
      splat = undefined;
      params = [];
      _ref2 = this.params;
      for (i = 0, _len = _ref2.length; i < _len; i++) {
        param = _ref2[i];
        if (splat) {
          if (param.attach) {
            param.assign = new AssignNode(new ValueNode(literal('this'), [new AccessorNode(param.value)]));
            this.body.expressions.splice(splat.index + 1, 0, param.assign);
          }
          splat.trailings.push(param);
        } else {
          if (param.attach) {
            value = param.value;
            _ref3 = [literal(o.scope.freeVariable('arg')), param.splat], param = _ref3[0], param.splat = _ref3[1];
            this.body.unshift(new AssignNode(new ValueNode(literal('this'), [new AccessorNode(value)]), param));
          }
          if (param.splat) {
            splat = new SplatNode(param.value);
            splat.index = i;
            splat.trailings = [];
            splat.arglength = this.params.length;
            this.body.unshift(splat);
          } else {
            params.push(param);
          }
        }
      }
      params = (function() {
        _result = [];
        for (_i = 0, _len = params.length; _i < _len; _i++) {
          param = params[_i];
          _result.push(param.compile(o));
        }
        return _result;
      })();
      if (!(empty)) {
        this.body.makeReturn();
      }
      for (_i = 0, _len = params.length; _i < _len; _i++) {
        param = params[_i];
        (o.scope.parameter(param));
      }
      if (this.className) {
        o.indent = this.idt(2);
      }
      code = this.body.expressions.length ? ("\n" + (this.body.compileWithDeclarations(o)) + "\n") : '';
      open = this.className ? ("(function() {\n" + (this.idt(1)) + "return function " + (this.className) + "(") : "function(";
      close = this.className ? ("" + (code && this.idt(1)) + "};\n" + (this.tab) + "})()") : ("" + (code && this.tab) + "}");
      func = ("" + open + (params.join(', ')) + ") {" + code + close);
      if (this.bound) {
        return ("" + (utility('bind')) + "(" + func + ", " + (this.context) + ")");
      }
      return top ? ("(" + func + ")") : func;
    };
    CodeNode.prototype.topSensitive = YES;
    CodeNode.prototype.traverseChildren = function(crossScope, func) {
      return crossScope ? CodeNode.__super__.traverseChildren.call(this, crossScope, func) : undefined;
    };
    return CodeNode;
  })();
  exports.ParamNode = (function() {
    ParamNode = (function() {
      return function ParamNode(_arg, _arg2, _arg3) {
        this.splat = _arg3;
        this.attach = _arg2;
        this.name = _arg;
        ParamNode.__super__.constructor.call(this);
        this.value = literal(this.name);
        return this;
      };
    })();
    __extends(ParamNode, BaseNode);
    ParamNode.prototype.children = ['name'];
    ParamNode.prototype.compileNode = function(o) {
      return this.value.compile(o);
    };
    ParamNode.prototype.toString = function() {
      var name;
      name = this.name;
      if (this.attach) {
        name = '@' + name;
      }
      if (this.splat) {
        name += '...';
      }
      return literal(name).toString();
    };
    return ParamNode;
  })();
  exports.SplatNode = (function() {
    SplatNode = (function() {
      return function SplatNode(name) {
        SplatNode.__super__.constructor.call(this);
        if (!(name.compile)) {
          name = literal(name);
        }
        this.name = name;
        return this;
      };
    })();
    __extends(SplatNode, BaseNode);
    SplatNode.prototype.children = ['name'];
    SplatNode.prototype.compileNode = function(o) {
      return (this.index != null) ? this.compileParam(o) : this.name.compile(o);
    };
    SplatNode.prototype.compileParam = function(o) {
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
        _ref2 = this.trailings;
        for (idx = 0, _len = _ref2.length; idx < _len; idx++) {
          trailing = _ref2[idx];
          if (trailing.attach) {
            assign = trailing.assign;
            trailing = literal(o.scope.freeVariable('arg'));
            assign.value = trailing;
          }
          pos = this.trailings.length - idx;
          o.scope.assign(trailing.compile(o), "arguments[" + variadic + " ? " + len + " - " + pos + " : " + (this.index + idx) + "]");
        }
      }
      return "" + name + " = " + (utility('slice')) + ".call(arguments, " + (this.index) + end + ")";
    };
    SplatNode.prototype.compileValue = function(o, name, index, trailings) {
      var trail;
      trail = trailings ? (", " + name + ".length - " + trailings) : '';
      return "" + (utility('slice')) + ".call(" + name + ", " + index + trail + ")";
    };
    SplatNode.compileSplattedArray = function(list, o) {
      var _len, arg, args, code, end, i, prev;
      args = [];
      end = -1;
      for (i = 0, _len = list.length; i < _len; i++) {
        arg = list[i];
        code = arg.compile(o);
        prev = args[end];
        if (!(arg instanceof SplatNode)) {
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
    return SplatNode;
  }).call(this);
  exports.WhileNode = (function() {
    WhileNode = (function() {
      return function WhileNode(condition, opts) {
        WhileNode.__super__.constructor.call(this);
        if (((opts != null) ? opts.invert : undefined)) {
          if (condition instanceof OpNode) {
            condition = new ParentheticalNode(condition);
          }
          condition = new OpNode('!', condition);
        }
        this.condition = condition;
        this.guard = ((opts != null) ? opts.guard : undefined);
        return this;
      };
    })();
    __extends(WhileNode, BaseNode);
    WhileNode.prototype.children = ['condition', 'guard', 'body'];
    WhileNode.prototype.isStatement = YES;
    WhileNode.prototype.addBody = function(body) {
      this.body = body;
      return this;
    };
    WhileNode.prototype.makeReturn = function() {
      this.returns = true;
      return this;
    };
    WhileNode.prototype.topSensitive = YES;
    WhileNode.prototype.compileNode = function(o) {
      var cond, post, pre, rvar, set, top;
      top = del(o, 'top') && !this.returns;
      o.indent = this.idt(1);
      o.top = true;
      this.condition.parenthetical = true;
      cond = this.condition.compile(o);
      set = '';
      if (!(top)) {
        rvar = o.scope.freeVariable('result');
        set = ("" + (this.tab) + rvar + " = [];\n");
        if (this.body) {
          this.body = PushNode.wrap(rvar, this.body);
        }
      }
      pre = ("" + set + (this.tab) + "while (" + cond + ")");
      if (this.guard) {
        this.body = Expressions.wrap([new IfNode(this.guard, this.body)]);
      }
      if (this.returns) {
        post = '\n' + new ReturnNode(literal(rvar)).compile(merge(o, {
          indent: this.idt()
        }));
      } else {
        post = '';
      }
      return "" + pre + " {\n" + (this.body.compile(o)) + "\n" + (this.tab) + "}" + post;
    };
    return WhileNode;
  })();
  exports.OpNode = (function() {
    OpNode = (function() {
      return function OpNode(_arg, _arg2, _arg3, flip) {
        this.second = _arg3;
        this.first = _arg2;
        this.operator = _arg;
        OpNode.__super__.constructor.call(this);
        this.operator = this.CONVERSIONS[this.operator] || this.operator;
        this.flip = !!flip;
        if (this.first instanceof ValueNode && this.first.base instanceof ObjectNode) {
          this.first = new ParentheticalNode(this.first);
        } else if (this.operator === 'new' && this.first instanceof CallNode) {
          return this.first.newInstance();
        }
        this.first.tags.operation = true;
        if (this.second) {
          this.second.tags.operation = true;
        }
        return this;
      };
    })();
    __extends(OpNode, BaseNode);
    OpNode.prototype.CONVERSIONS = {
      '==': '===',
      '!=': '!==',
      of: 'in'
    };
    OpNode.prototype.INVERSIONS = {
      '!==': '===',
      '===': '!=='
    };
    OpNode.prototype.CHAINABLE = ['<', '>', '>=', '<=', '===', '!=='];
    OpNode.prototype.ASSIGNMENT = ['||=', '&&=', '?='];
    OpNode.prototype.PREFIX_OPERATORS = ['new', 'typeof', 'delete'];
    OpNode.prototype.children = ['first', 'second'];
    OpNode.prototype.isUnary = function() {
      return !this.second;
    };
    OpNode.prototype.isInvertible = function() {
      var _ref2;
      return (('===' === (_ref2 = this.operator) || '!==' === _ref2)) && !(this.first instanceof OpNode) && !(this.second instanceof OpNode);
    };
    OpNode.prototype.isComplex = function() {
      return this.operator !== '!' || this.first.isComplex();
    };
    OpNode.prototype.isMutator = function() {
      var _ref2;
      return ends(this.operator, '=') && !('===' === (_ref2 = this.operator) || '!==' === _ref2);
    };
    OpNode.prototype.isChainable = function() {
      return include(this.CHAINABLE, this.operator);
    };
    OpNode.prototype.invert = function() {
      return (this.operator = this.INVERSIONS[this.operator]);
    };
    OpNode.prototype.toString = function(idt) {
      return OpNode.__super__.toString.call(this, idt, this.constructor.name + ' ' + this.operator);
    };
    OpNode.prototype.compileNode = function(o) {
      var node;
      if (node = ValueNode.unfoldSoak(o, this, 'first')) {
        return node.compile(o);
      }
      if (this.isChainable() && this.first.unwrap() instanceof OpNode && this.first.unwrap().isChainable()) {
        return this.compileChain(o);
      }
      if (indexOf(this.ASSIGNMENT, this.operator) >= 0) {
        return this.compileAssignment(o);
      }
      if (this.isUnary()) {
        return this.compileUnary(o);
      }
      if (this.operator === '?') {
        return this.compileExistence(o);
      }
      if (this.first instanceof OpNode && this.first.isMutator()) {
        this.first = new ParentheticalNode(this.first);
      }
      if (this.second instanceof OpNode && this.second.isMutator()) {
        this.second = new ParentheticalNode(this.second);
      }
      return [this.first.compile(o), this.operator, this.second.compile(o)].join(' ');
    };
    OpNode.prototype.compileChain = function(o) {
      var _ref2, first, second, shared;
      shared = this.first.unwrap().second;
      _ref2 = shared.compileReference(o), this.first.second = _ref2[0], shared = _ref2[1];
      _ref2 = [this.first.compile(o), this.second.compile(o), shared.compile(o)], first = _ref2[0], second = _ref2[1], shared = _ref2[2];
      return "(" + first + ") && (" + shared + " " + (this.operator) + " " + second + ")";
    };
    OpNode.prototype.compileAssignment = function(o) {
      var _ref2, left, rite;
      _ref2 = this.first.cacheReference(o), left = _ref2[0], rite = _ref2[1];
      rite = new AssignNode(rite, this.second);
      return new OpNode(this.operator.slice(0, -1), left, rite).compile(o);
    };
    OpNode.prototype.compileExistence = function(o) {
      var fst, ref;
      if (this.first.isComplex()) {
        ref = o.scope.freeVariable('ref');
        fst = new ParentheticalNode(new AssignNode(literal(ref), this.first));
      } else {
        fst = this.first;
        ref = fst.compile(o);
      }
      return new ExistenceNode(fst).compile(o) + (" ? " + ref + " : " + (this.second.compile(o)));
    };
    OpNode.prototype.compileUnary = function(o) {
      var parts, space;
      space = indexOf(this.PREFIX_OPERATORS, this.operator) >= 0 ? ' ' : '';
      parts = [this.operator, space, this.first.compile(o)];
      if (this.flip) {
        parts = parts.reverse();
      }
      return parts.join('');
    };
    return OpNode;
  })();
  exports.InNode = (function() {
    InNode = (function() {
      return function InNode(_arg, _arg2) {
        this.array = _arg2;
        this.object = _arg;
        InNode.__super__.constructor.call(this);
        return this;
      };
    })();
    __extends(InNode, BaseNode);
    InNode.prototype.children = ['object', 'array'];
    InNode.prototype.isArray = function() {
      return this.array instanceof ValueNode && this.array.isArray();
    };
    InNode.prototype.compileNode = function(o) {
      var _ref2;
      _ref2 = this.object.compileReference(o, {
        precompile: true
      }), this.obj1 = _ref2[0], this.obj2 = _ref2[1];
      return this.isArray() ? this.compileOrTest(o) : this.compileLoopTest(o);
    };
    InNode.prototype.compileOrTest = function(o) {
      var _len, _ref2, _result, i, item, tests;
      tests = (function() {
        _result = []; _ref2 = this.array.base.objects;
        for (i = 0, _len = _ref2.length; i < _len; i++) {
          item = _ref2[i];
          _result.push("" + (item.compile(o)) + " === " + (i ? this.obj2 : this.obj1));
        }
        return _result;
      }).call(this);
      return "(" + (tests.join(' || ')) + ")";
    };
    InNode.prototype.compileLoopTest = function(o) {
      var _ref2, i, l, prefix;
      _ref2 = this.array.compileReference(o, {
        precompile: true
      }), this.arr1 = _ref2[0], this.arr2 = _ref2[1];
      _ref2 = [o.scope.freeVariable('i'), o.scope.freeVariable('len')], i = _ref2[0], l = _ref2[1];
      prefix = this.obj1 !== this.obj2 ? this.obj1 + '; ' : '';
      return "(function(){ " + prefix + "for (var " + i + "=0, " + l + "=" + (this.arr1) + ".length; " + i + "<" + l + "; " + i + "++) { if (" + (this.arr2) + "[" + i + "] === " + (this.obj2) + ") return true; } return false; }).call(this)";
    };
    return InNode;
  })();
  exports.TryNode = (function() {
    TryNode = (function() {
      return function TryNode(_arg, _arg2, _arg3, _arg4) {
        this.ensure = _arg4;
        this.recovery = _arg3;
        this.error = _arg2;
        this.attempt = _arg;
        TryNode.__super__.constructor.call(this);
        return this;
      };
    })();
    __extends(TryNode, BaseNode);
    TryNode.prototype.children = ['attempt', 'recovery', 'ensure'];
    TryNode.prototype.isStatement = YES;
    TryNode.prototype.makeReturn = function() {
      if (this.attempt) {
        this.attempt = this.attempt.makeReturn();
      }
      if (this.recovery) {
        this.recovery = this.recovery.makeReturn();
      }
      return this;
    };
    TryNode.prototype.compileNode = function(o) {
      var attemptPart, catchPart, errorPart, finallyPart;
      o.indent = this.idt(1);
      o.top = true;
      attemptPart = this.attempt.compile(o);
      errorPart = this.error ? (" (" + (this.error.compile(o)) + ") ") : ' ';
      catchPart = this.recovery ? (" catch" + errorPart + "{\n" + (this.recovery.compile(o)) + "\n" + (this.tab) + "}") : (!(this.ensure || this.recovery) ? ' catch (_e) {}' : '');
      finallyPart = (this.ensure || '') && ' finally {\n' + this.ensure.compile(merge(o)) + ("\n" + (this.tab) + "}");
      return "" + (this.tab) + "try {\n" + attemptPart + "\n" + (this.tab) + "}" + catchPart + finallyPart;
    };
    return TryNode;
  })();
  exports.ThrowNode = (function() {
    ThrowNode = (function() {
      return function ThrowNode(_arg) {
        this.expression = _arg;
        ThrowNode.__super__.constructor.call(this);
        return this;
      };
    })();
    __extends(ThrowNode, BaseNode);
    ThrowNode.prototype.children = ['expression'];
    ThrowNode.prototype.isStatement = YES;
    ThrowNode.prototype.makeReturn = THIS;
    ThrowNode.prototype.compileNode = function(o) {
      return "" + (this.tab) + "throw " + (this.expression.compile(o)) + ";";
    };
    return ThrowNode;
  })();
  exports.ExistenceNode = (function() {
    ExistenceNode = (function() {
      return function ExistenceNode(_arg) {
        this.expression = _arg;
        ExistenceNode.__super__.constructor.call(this);
        return this;
      };
    })();
    __extends(ExistenceNode, BaseNode);
    ExistenceNode.prototype.children = ['expression'];
    ExistenceNode.prototype.compileNode = function(o) {
      var code;
      code = this.expression.compile(o);
      code = IDENTIFIER.test(code) && !o.scope.check(code) ? ("typeof " + code + " !== \"undefined\" && " + code + " !== null") : ("" + code + " != null");
      return this.parenthetical ? code : ("(" + code + ")");
    };
    return ExistenceNode;
  })();
  exports.ParentheticalNode = (function() {
    ParentheticalNode = (function() {
      return function ParentheticalNode(_arg) {
        this.expression = _arg;
        ParentheticalNode.__super__.constructor.call(this);
        return this;
      };
    })();
    __extends(ParentheticalNode, BaseNode);
    ParentheticalNode.prototype.children = ['expression'];
    ParentheticalNode.prototype.isStatement = function(o) {
      return this.expression.isStatement(o);
    };
    ParentheticalNode.prototype.isComplex = function() {
      return this.expression.isComplex();
    };
    ParentheticalNode.prototype.topSensitive = YES;
    ParentheticalNode.prototype.makeReturn = function() {
      return this.expression.makeReturn();
    };
    ParentheticalNode.prototype.compileNode = function(o) {
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
    return ParentheticalNode;
  })();
  exports.ForNode = (function() {
    ForNode = (function() {
      return function ForNode(_arg, source, _arg2, _arg3) {
        var _ref2;
        this.index = _arg3;
        this.name = _arg2;
        this.body = _arg;
        ForNode.__super__.constructor.call(this);
        this.index || (this.index = null);
        this.source = source.source;
        this.guard = source.guard;
        this.step = source.step;
        this.raw = !!source.raw;
        this.object = !!source.object;
        if (this.object) {
          _ref2 = [this.index, this.name], this.name = _ref2[0], this.index = _ref2[1];
        }
        this.pattern = this.name instanceof ValueNode;
        if (this.index instanceof ValueNode) {
          throw new Error('index cannot be a pattern matching expression');
        }
        this.returns = false;
        return this;
      };
    })();
    __extends(ForNode, BaseNode);
    ForNode.prototype.children = ['body', 'source', 'guard'];
    ForNode.prototype.isStatement = YES;
    ForNode.prototype.topSensitive = YES;
    ForNode.prototype.makeReturn = function() {
      this.returns = true;
      return this;
    };
    ForNode.prototype.compileReturnValue = function(val, o) {
      if (this.returns) {
        return '\n' + new ReturnNode(literal(val)).compile(o);
      }
      if (val) {
        return '\n' + val;
      }
      return '';
    };
    ForNode.prototype.compileNode = function(o) {
      var body, codeInBody, forPart, guardPart, idt1, index, ivar, lvar, name, namePart, range, ref, returnResult, rvar, scope, source, sourcePart, stepPart, svar, topLevel, varPart, vars;
      topLevel = del(o, 'top') && !this.returns;
      range = this.source instanceof ValueNode && this.source.base instanceof RangeNode && !this.source.properties.length;
      source = range ? this.source.base : this.source;
      codeInBody = this.body.contains(function(node) {
        return node instanceof CodeNode;
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
      if (!(topLevel)) {
        rvar = scope.freeVariable('result');
      }
      ivar = range ? name : index;
      if (!ivar || codeInBody) {
        ivar = scope.freeVariable('i');
      }
      varPart = '';
      guardPart = '';
      body = Expressions.wrap([this.body]);
      idt1 = this.idt(1);
      if (range) {
        sourcePart = source.compileVariables(o);
        forPart = source.compile(merge(o, {
          index: ivar,
          step: this.step
        }));
      } else {
        svar = this.source.compile(o);
        if (IDENTIFIER.test(svar) && scope.check(svar, {
          immediate: true
        })) {
          sourcePart = '';
        } else {
          ref = scope.freeVariable('ref');
          sourcePart = ("" + ref + " = " + svar + ";");
          svar = ref;
        }
        namePart = this.pattern ? new AssignNode(this.name, literal("" + svar + "[" + ivar + "]")).compile(merge(o, {
          top: true
        })) : (name ? ("" + name + " = " + svar + "[" + ivar + "]") : undefined);
        if (!(this.object)) {
          lvar = scope.freeVariable('len');
          stepPart = this.step ? ("" + ivar + " += " + (this.step.compile(o))) : ("" + ivar + "++");
          forPart = ("" + ivar + " = 0, " + lvar + " = " + svar + ".length; " + ivar + " < " + lvar + "; " + stepPart);
        }
      }
      sourcePart = (rvar ? ("" + rvar + " = []; ") : '') + sourcePart;
      sourcePart = sourcePart ? ("" + (this.tab) + sourcePart + "\n" + (this.tab)) : this.tab;
      returnResult = this.compileReturnValue(rvar, o);
      if (!(topLevel)) {
        body = PushNode.wrap(rvar, body);
      }
      if (this.guard) {
        body = Expressions.wrap([new IfNode(this.guard, body)]);
      }
      if (codeInBody) {
        if (range) {
          body.unshift(literal("var " + name + " = " + ivar));
        }
        if (namePart) {
          body.unshift(literal("var " + namePart));
        }
        if (index) {
          body.unshift(literal("var " + index + " = " + ivar));
        }
        body = ClosureNode.wrap(body, true);
      } else {
        if (namePart) {
          varPart = ("" + idt1 + namePart + ";\n");
        }
      }
      if (this.object) {
        forPart = ("" + ivar + " in " + svar);
        if (!(this.raw)) {
          guardPart = ("\n" + idt1 + "if (!" + (utility('hasProp')) + ".call(" + svar + ", " + ivar + ")) continue;");
        }
      }
      body = body.compile(merge(o, {
        indent: idt1,
        top: true
      }));
      vars = range ? name : ("" + name + ", " + ivar);
      return "" + sourcePart + "for (" + forPart + ") {" + guardPart + "\n" + varPart + body + "\n" + (this.tab) + "}" + returnResult;
    };
    return ForNode;
  })();
  exports.SwitchNode = (function() {
    SwitchNode = (function() {
      return function SwitchNode(_arg, _arg2, _arg3) {
        this.otherwise = _arg3;
        this.cases = _arg2;
        this.subject = _arg;
        SwitchNode.__super__.constructor.call(this);
        this.tags.subjectless = !this.subject;
        this.subject || (this.subject = literal('true'));
        return this;
      };
    })();
    __extends(SwitchNode, BaseNode);
    SwitchNode.prototype.children = ['subject', 'cases', 'otherwise'];
    SwitchNode.prototype.isStatement = YES;
    SwitchNode.prototype.makeReturn = function() {
      var _i, _len, _ref2, pair;
      _ref2 = this.cases;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        pair = _ref2[_i];
        pair[1].makeReturn();
      }
      if (this.otherwise) {
        this.otherwise.makeReturn();
      }
      return this;
    };
    SwitchNode.prototype.compileNode = function(o) {
      var _i, _j, _len, _len2, _ref2, _ref3, block, code, condition, conditions, exprs, idt, pair;
      idt = (o.indent = this.idt(2));
      o.top = true;
      code = ("" + (this.tab) + "switch (" + (this.subject.compile(o)) + ") {");
      _ref2 = this.cases;
      for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
        pair = _ref2[_i];
        _ref3 = pair, conditions = _ref3[0], block = _ref3[1];
        exprs = block.expressions;
        _ref3 = flatten([conditions]);
        for (_j = 0, _len2 = _ref3.length; _j < _len2; _j++) {
          condition = _ref3[_j];
          if (this.tags.subjectless) {
            condition = new OpNode('!!', new ParentheticalNode(condition));
          }
          code += ("\n" + (this.idt(1)) + "case " + (condition.compile(o)) + ":");
        }
        code += ("\n" + (block.compile(o)));
        if (!(last(exprs) instanceof ReturnNode)) {
          code += ("\n" + idt + "break;");
        }
      }
      if (this.otherwise) {
        code += ("\n" + (this.idt(1)) + "default:\n" + (this.otherwise.compile(o)));
      }
      code += ("\n" + (this.tab) + "}");
      return code;
    };
    return SwitchNode;
  })();
  exports.IfNode = (function() {
    IfNode = (function() {
      return function IfNode(_arg, _arg2, _arg3) {
        this.tags = _arg3;
        this.body = _arg2;
        this.condition = _arg;
        this.tags || (this.tags = {});
        if (this.tags.invert) {
          if (this.condition instanceof OpNode && this.condition.isInvertible()) {
            this.condition.invert();
          } else {
            this.condition = new OpNode('!', new ParentheticalNode(this.condition));
          }
        }
        this.elseBody = null;
        this.isChain = false;
        return this;
      };
    })();
    __extends(IfNode, BaseNode);
    IfNode.prototype.children = ['condition', 'body', 'elseBody', 'assigner'];
    IfNode.prototype.topSensitive = YES;
    IfNode.prototype.bodyNode = function() {
      var _ref2;
      return (((_ref2 = this.body) != null) ? _ref2.unwrap() : undefined);
    };
    IfNode.prototype.elseBodyNode = function() {
      var _ref2;
      return (((_ref2 = this.elseBody) != null) ? _ref2.unwrap() : undefined);
    };
    IfNode.prototype.addElse = function(elseBody, statement) {
      if (this.isChain) {
        this.elseBodyNode().addElse(elseBody, statement);
      } else {
        this.isChain = elseBody instanceof IfNode;
        this.elseBody = this.ensureExpressions(elseBody);
      }
      return this;
    };
    IfNode.prototype.isStatement = function(o) {
      return this.statement || (this.statement = !!((o && o.top) || this.bodyNode().isStatement(o) || (this.elseBody && this.elseBodyNode().isStatement(o))));
    };
    IfNode.prototype.compileCondition = function(o) {
      var _i, _len, _result, cond, conditions;
      conditions = flatten([this.condition]);
      if (conditions.length === 1) {
        conditions[0].parenthetical = true;
      }
      return (function() {
        _result = [];
        for (_i = 0, _len = conditions.length; _i < _len; _i++) {
          cond = conditions[_i];
          _result.push(cond.compile(o));
        }
        return _result;
      })().join(' || ');
    };
    IfNode.prototype.compileNode = function(o) {
      return this.isStatement(o) ? this.compileStatement(o) : this.compileExpression(o);
    };
    IfNode.prototype.makeReturn = function() {
      if (this.isStatement()) {
        this.body && (this.body = this.ensureExpressions(this.body.makeReturn()));
        this.elseBody && (this.elseBody = this.ensureExpressions(this.elseBody.makeReturn()));
        return this;
      } else {
        return new ReturnNode(this);
      }
    };
    IfNode.prototype.ensureExpressions = function(node) {
      return node instanceof Expressions ? node : new Expressions([node]);
    };
    IfNode.prototype.compileStatement = function(o) {
      var body, child, comDent, condO, elsePart, ifDent, ifPart, top;
      top = del(o, 'top');
      child = del(o, 'chainChild');
      condO = merge(o);
      o.indent = this.idt(1);
      o.top = true;
      ifDent = child || (top && !this.isStatement(o)) ? '' : this.idt();
      comDent = child ? this.idt() : '';
      body = this.body.compile(o);
      ifPart = ("" + ifDent + "if (" + (this.compileCondition(condO)) + ") {\n" + body + "\n" + (this.tab) + "}");
      if (!(this.elseBody)) {
        return ifPart;
      }
      elsePart = this.isChain ? ' else ' + this.elseBodyNode().compile(merge(o, {
        indent: this.idt(),
        chainChild: true
      })) : (" else {\n" + (this.elseBody.compile(o)) + "\n" + (this.tab) + "}");
      return "" + ifPart + elsePart;
    };
    IfNode.prototype.compileExpression = function(o) {
      var code, elsePart, ifPart;
      this.bodyNode().tags.operation = (this.condition.tags.operation = true);
      if (this.elseBody) {
        this.elseBodyNode().tags.operation = true;
      }
      ifPart = this.condition.compile(o) + ' ? ' + this.bodyNode().compile(o);
      elsePart = this.elseBody ? this.elseBodyNode().compile(o) : 'undefined';
      code = ("" + ifPart + " : " + elsePart);
      return this.tags.operation ? ("(" + code + ")") : code;
    };
    return IfNode;
  })();
  PushNode = {
    wrap: function(name, expressions) {
      if (expressions.empty() || expressions.containsPureStatement()) {
        return expressions;
      }
      return Expressions.wrap([new CallNode(new ValueNode(literal(name), [new AccessorNode(literal('push'))]), [expressions.unwrap()])]);
    }
  };
  ClosureNode = {
    wrap: function(expressions, statement) {
      var args, call, func, mentionsArgs, meth;
      if (expressions.containsPureStatement()) {
        return expressions;
      }
      func = new ParentheticalNode(new CodeNode([], Expressions.wrap([expressions])));
      args = [];
      if ((mentionsArgs = expressions.contains(this.literalArgs)) || (expressions.contains(this.literalThis))) {
        meth = literal(mentionsArgs ? 'apply' : 'call');
        args = [literal('this')];
        if (mentionsArgs) {
          args.push(literal('arguments'));
        }
        func = new ValueNode(func, [new AccessorNode(meth)]);
      }
      call = new CallNode(func, args);
      return statement ? Expressions.wrap([call]) : call;
    },
    literalArgs: function(node) {
      return node instanceof LiteralNode && node.value === 'arguments';
    },
    literalThis: function(node) {
      return node instanceof LiteralNode && node.value === 'this' || node instanceof CodeNode && node.bound;
    }
  };
  UTILITIES = {
    "extends": 'function(child, parent) {\n  var ctor = function() {};\n  ctor.prototype = parent.prototype;\n  child.prototype = new ctor();\n  child.prototype.constructor = child;\n  if (typeof parent.extended === "function") parent.extended(child);\n  child.__super__ = parent.prototype;\n}',
    bind: 'function(func, context) {\n  return function() { return func.apply(context, arguments); };\n}',
    hasProp: 'Object.prototype.hasOwnProperty',
    slice: 'Array.prototype.slice'
  };
  TAB = '  ';
  TRAILING_WHITESPACE = /[ \t]+$/gm;
  IDENTIFIER = /^[$A-Za-z_][$\w]*$/;
  NUMBER = /^0x[\da-f]+|^(?:\d+(\.\d+)?|\.\d+)(?:e[+-]?\d+)?$/i;
  SIMPLENUM = /^-?\d+$/;
  IS_STRING = /^['"]/;
  literal = function(name) {
    return new LiteralNode(name);
  };
  utility = function(name) {
    var ref;
    ref = ("__" + name);
    Scope.root.assign(ref, UTILITIES[name]);
    return ref;
  };
}).call(this);
