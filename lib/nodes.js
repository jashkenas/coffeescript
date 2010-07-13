(function(){
  var AccessorNode, ArrayNode, AssignNode, BaseNode, CallNode, ClassNode, ClosureNode, CodeNode, CommentNode, DOUBLE_PARENS, ExistenceNode, Expressions, ExtendsNode, ForNode, IDENTIFIER, IS_STRING, IfNode, InNode, IndexNode, LiteralNode, NUMBER, ObjectNode, OpNode, ParentheticalNode, PushNode, RangeNode, ReturnNode, Scope, SliceNode, SplatNode, TAB, TRAILING_WHITESPACE, ThrowNode, TryNode, UTILITIES, ValueNode, WhileNode, _a, compact, del, flatten, helpers, include, indexOf, literal, merge, starts, utility;
  var __extends = function(child, parent) {
    var ctor = function(){ };
    ctor.prototype = parent.prototype;
    child.__superClass__ = parent.prototype;
    child.prototype = new ctor();
    child.prototype.constructor = child;
  };
  if (typeof process !== "undefined" && process !== null) {
    Scope = require('./scope').Scope;
    helpers = require('./helpers').helpers;
  } else {
    this.exports = this;
    helpers = this.helpers;
    Scope = this.Scope;
  }
  _a = helpers;
  compact = _a.compact;
  flatten = _a.flatten;
  merge = _a.merge;
  del = _a.del;
  include = _a.include;
  indexOf = _a.indexOf;
  starts = _a.starts;
  exports.BaseNode = (function() {
    BaseNode = function() {    };
    BaseNode.prototype.compile = function(o) {
      var closure, top;
      this.options = merge(o || {});
      this.tab = o.indent;
      if (!(this instanceof ValueNode || this instanceof CallNode)) {
        del(this.options, 'operation');
        if (!(this instanceof AccessorNode || this instanceof IndexNode)) {
          del(this.options, 'chainRoot');
        }
      }
      top = this.topSensitive() ? this.options.top : del(this.options, 'top');
      closure = this.isStatement() && !this.isPureStatement() && !top && !this.options.asStatement && !(this instanceof CommentNode) && !this.containsPureStatement();
      return closure ? this.compileClosure(this.options) : this.compileNode(this.options);
    };
    BaseNode.prototype.compileClosure = function(o) {
      this.tab = o.indent;
      o.sharedScope = o.scope;
      return ClosureNode.wrap(this).compile(o);
    };
    BaseNode.prototype.compileReference = function(o, options) {
      var compiled, pair, reference;
      pair = (function() {
        if (!(this instanceof CallNode || this instanceof ValueNode && (!(this.base instanceof LiteralNode) || this.hasProperties()))) {
          return [this, this];
        } else {
          reference = literal(o.scope.freeVariable());
          compiled = new AssignNode(reference, this);
          return [compiled, reference];
        }
      }).call(this);
      if (!(options && options.precompile)) {
        return pair;
      }
      return [pair[0].compile(o), pair[1].compile(o)];
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
      return this instanceof type || this.contains(function(n) {
        return n instanceof type;
      });
    };
    BaseNode.prototype.containsPureStatement = function() {
      return this.isPureStatement() || this.contains(function(n) {
        return n.isPureStatement();
      });
    };
    BaseNode.prototype.traverse = function(block) {
      return this.traverseChildren(true, block);
    };
    BaseNode.prototype.toString = function(idt, override) {
      var _b, _c, _d, _e, child, children;
      idt = idt || '';
      children = (function() {
        _b = []; _d = this.collectChildren();
        for (_c = 0, _e = _d.length; _c < _e; _c++) {
          child = _d[_c];
          _b.push(child.toString(idt + TAB));
        }
        return _b;
      }).call(this).join('');
      return '\n' + idt + (override || this['class']) + children;
    };
    BaseNode.prototype.eachChild = function(func) {
      var _b, _c, _d, _e, _f, _g, _h, attr, child;
      if (!(this.children)) {
        return null;
      }
      _b = []; _d = this.children;
      for (_c = 0, _e = _d.length; _c < _e; _c++) {
        attr = _d[_c];
        if (this[attr]) {
          _g = flatten([this[attr]]);
          for (_f = 0, _h = _g.length; _f < _h; _f++) {
            child = _g[_f];
            if (func(child) === false) {
              return null;
            }
          }
        }
      }
      return _b;
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
        func.apply(this, arguments);
        if (child instanceof BaseNode) {
          return child.traverseChildren(crossScope, func);
        }
      });
    };
    BaseNode.prototype['class'] = 'BaseNode';
    BaseNode.prototype.children = [];
    BaseNode.prototype.unwrap = function() {
      return this;
    };
    BaseNode.prototype.isStatement = function() {
      return false;
    };
    BaseNode.prototype.isPureStatement = function() {
      return false;
    };
    BaseNode.prototype.topSensitive = function() {
      return false;
    };
    return BaseNode;
  })();
  exports.Expressions = (function() {
    Expressions = function(nodes) {
      this.expressions = compact(flatten(nodes || []));
      return this;
    };
    __extends(Expressions, BaseNode);
    Expressions.prototype['class'] = 'Expressions';
    Expressions.prototype.children = ['expressions'];
    Expressions.prototype.isStatement = function() {
      return true;
    };
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
      var idx, last;
      idx = this.expressions.length - 1;
      last = this.expressions[idx];
      if (last instanceof CommentNode) {
        last = this.expressions[idx -= 1];
      }
      if (!last || last instanceof ReturnNode) {
        return this;
      }
      this.expressions[idx] = last.makeReturn();
      return this;
    };
    Expressions.prototype.compile = function(o) {
      o = o || {};
      return o.scope ? Expressions.__superClass__.compile.call(this, o) : this.compileRoot(o);
    };
    Expressions.prototype.compileNode = function(o) {
      var _b, _c, _d, _e, node;
      return (function() {
        _b = []; _d = this.expressions;
        for (_c = 0, _e = _d.length; _c < _e; _c++) {
          node = _d[_c];
          _b.push(this.compileExpression(node, merge(o)));
        }
        return _b;
      }).call(this).join("\n");
    };
    Expressions.prototype.compileRoot = function(o) {
      var code;
      o.indent = (this.tab = o.noWrap ? '' : TAB);
      o.scope = new Scope(null, this, null);
      code = this.compileWithDeclarations(o);
      code = code.replace(TRAILING_WHITESPACE, '');
      code = code.replace(DOUBLE_PARENS, '($1)');
      return o.noWrap ? code : ("(function(){\n" + code + "\n})();\n");
    };
    Expressions.prototype.compileWithDeclarations = function(o) {
      var code;
      code = this.compileNode(o);
      if (o.scope.hasAssignments(this)) {
        code = ("" + (this.tab) + "var " + (o.scope.compiledAssignments()) + ";\n" + code);
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
      return node.isStatement() ? compiledNode : ("" + (this.idt()) + compiledNode + ";");
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
    LiteralNode = function(value) {
      this.value = value;
      return this;
    };
    __extends(LiteralNode, BaseNode);
    LiteralNode.prototype['class'] = 'LiteralNode';
    LiteralNode.prototype.isStatement = function() {
      return this.value === 'break' || this.value === 'continue';
    };
    LiteralNode.prototype.isPureStatement = LiteralNode.prototype.isStatement;
    LiteralNode.prototype.compileNode = function(o) {
      var end, idt;
      idt = this.isStatement() ? this.idt() : '';
      end = this.isStatement() ? ';' : '';
      return "" + idt + this.value + end;
    };
    LiteralNode.prototype.toString = function(idt) {
      return " \"" + this.value + "\"";
    };
    return LiteralNode;
  })();
  exports.ReturnNode = (function() {
    ReturnNode = function(expression) {
      this.expression = expression;
      return this;
    };
    __extends(ReturnNode, BaseNode);
    ReturnNode.prototype['class'] = 'ReturnNode';
    ReturnNode.prototype.isStatement = function() {
      return true;
    };
    ReturnNode.prototype.isPureStatement = function() {
      return true;
    };
    ReturnNode.prototype.children = ['expression'];
    ReturnNode.prototype.makeReturn = function() {
      return this;
    };
    ReturnNode.prototype.compile = function(o) {
      var expr;
      expr = this.expression.makeReturn();
      if (!(expr instanceof ReturnNode)) {
        return expr.compile(o);
      }
      return ReturnNode.__superClass__.compile.call(this, o);
    };
    ReturnNode.prototype.compileNode = function(o) {
      if (this.expression.isStatement()) {
        o.asStatement = true;
      }
      return "" + (this.tab) + "return " + (this.expression.compile(o)) + ";";
    };
    return ReturnNode;
  })();
  exports.ValueNode = (function() {
    ValueNode = function(base, properties) {
      this.base = base;
      this.properties = (properties || []);
      return this;
    };
    __extends(ValueNode, BaseNode);
    ValueNode.prototype.SOAK = " == undefined ? undefined : ";
    ValueNode.prototype['class'] = 'ValueNode';
    ValueNode.prototype.children = ['base', 'properties'];
    ValueNode.prototype.push = function(prop) {
      this.properties.push(prop);
      return this;
    };
    ValueNode.prototype.hasProperties = function() {
      return !!this.properties.length;
    };
    ValueNode.prototype.isArray = function() {
      return this.base instanceof ArrayNode && !this.hasProperties();
    };
    ValueNode.prototype.isObject = function() {
      return this.base instanceof ObjectNode && !this.hasProperties();
    };
    ValueNode.prototype.isSplice = function() {
      return this.hasProperties() && this.properties[this.properties.length - 1] instanceof SliceNode;
    };
    ValueNode.prototype.makeReturn = function() {
      return this.hasProperties() ? ValueNode.__superClass__.makeReturn.call(this) : this.base.makeReturn();
    };
    ValueNode.prototype.unwrap = function() {
      return this.properties.length ? this : this.base;
    };
    ValueNode.prototype.isStatement = function() {
      return this.base.isStatement && this.base.isStatement() && !this.hasProperties();
    };
    ValueNode.prototype.isNumber = function() {
      return this.base instanceof LiteralNode && this.base.value.match(NUMBER);
    };
    ValueNode.prototype.isStart = function(o) {
      var node;
      if (this === o.chainRoot && this.properties[0] instanceof AccessorNode) {
        return true;
      }
      node = o.chainRoot.base || o.chainRoot.variable;
      while (node instanceof CallNode) {
        node = node.variable;
      }
      return node === this;
    };
    ValueNode.prototype.compile = function(o) {
      return !o.top || this.properties.length ? ValueNode.__superClass__.compile.call(this, o) : this.base.compile(o);
    };
    ValueNode.prototype.compileNode = function(o) {
      var _b, _c, baseline, complete, i, only, op, part, prop, props, temp;
      only = del(o, 'onlyFirst');
      op = del(o, 'operation');
      props = only ? this.properties.slice(0, this.properties.length - 1) : this.properties;
      o.chainRoot = o.chainRoot || this;
      baseline = this.base.compile(o);
      if (this.hasProperties() && (this.base instanceof ObjectNode || this.isNumber())) {
        baseline = ("(" + baseline + ")");
      }
      complete = (this.last = baseline);
      _b = props;
      for (i = 0, _c = _b.length; i < _c; i++) {
        prop = _b[i];
        this.source = baseline;
        if (prop.soakNode) {
          if (this.base instanceof CallNode && i === 0) {
            temp = o.scope.freeVariable();
            complete = ("(" + (baseline = temp) + " = (" + complete + "))");
          }
          if (i === 0 && this.isStart(o)) {
            complete = ("typeof " + complete + " === \"undefined\" || " + baseline);
          }
          complete += this.SOAK + (baseline += prop.compile(o));
        } else {
          part = prop.compile(o);
          baseline += part;
          complete += part;
          this.last = part;
        }
      }
      return op && this.wrapped ? ("(" + complete + ")") : complete;
    };
    return ValueNode;
  })();
  exports.CommentNode = (function() {
    CommentNode = function(lines) {
      this.lines = lines;
      return this;
    };
    __extends(CommentNode, BaseNode);
    CommentNode.prototype['class'] = 'CommentNode';
    CommentNode.prototype.isStatement = function() {
      return true;
    };
    CommentNode.prototype.makeReturn = function() {
      return this;
    };
    CommentNode.prototype.compileNode = function(o) {
      var sep;
      sep = ("\n" + this.tab);
      return "" + this.tab + "/*" + sep + (this.lines.join(sep)) + "\n" + this.tab + "*/";
    };
    return CommentNode;
  })();
  exports.CallNode = (function() {
    CallNode = function(variable, args) {
      this.isNew = false;
      this.isSuper = variable === 'super';
      this.variable = this.isSuper ? null : variable;
      this.args = (args || []);
      this.compileSplatArguments = function(o) {
        return SplatNode.compileMixedArray.call(this, this.args, o);
      };
      return this;
    };
    __extends(CallNode, BaseNode);
    CallNode.prototype['class'] = 'CallNode';
    CallNode.prototype.children = ['variable', 'args'];
    CallNode.prototype.newInstance = function() {
      this.isNew = true;
      return this;
    };
    CallNode.prototype.prefix = function() {
      return this.isNew ? 'new ' : '';
    };
    CallNode.prototype.superReference = function(o) {
      var meth, methname;
      methname = o.scope.method.name;
      meth = (function() {
        if (o.scope.method.proto) {
          return "" + (o.scope.method.proto) + ".__superClass__." + methname;
        } else if (methname) {
          return "" + (methname) + ".__superClass__.constructor";
        } else {
          throw new Error("cannot call super on an anonymous function.");
        }
      })();
      return meth;
    };
    CallNode.prototype.compileNode = function(o) {
      var _b, _c, _d, _e, _f, _g, _h, arg, args, compilation;
      if (!(o.chainRoot)) {
        o.chainRoot = this;
      }
      _c = this.args;
      for (_b = 0, _d = _c.length; _b < _d; _b++) {
        arg = _c[_b];
        arg instanceof SplatNode ? (compilation = this.compileSplat(o)) : null;
      }
      if (!(compilation)) {
        args = (function() {
          _e = []; _g = this.args;
          for (_f = 0, _h = _g.length; _f < _h; _f++) {
            arg = _g[_f];
            _e.push(arg.compile(o));
          }
          return _e;
        }).call(this).join(', ');
        compilation = this.isSuper ? this.compileSuper(args, o) : ("" + (this.prefix()) + (this.variable.compile(o)) + "(" + args + ")");
      }
      return o.operation && this.wrapped ? ("(" + compilation + ")") : compilation;
    };
    CallNode.prototype.compileSuper = function(args, o) {
      return "" + (this.superReference(o)) + ".call(this" + (args.length ? ', ' : '') + args + ")";
    };
    CallNode.prototype.compileSplat = function(o) {
      var meth, obj, temp;
      meth = this.variable ? this.variable.compile(o) : this.superReference(o);
      obj = this.variable && this.variable.source || 'this';
      if (obj.match(/\(/)) {
        temp = o.scope.freeVariable();
        obj = temp;
        meth = ("(" + temp + " = " + (this.variable.source) + ")" + (this.variable.last));
      }
      if (this.isNew) {
        utility('extends');
        return "(function() {\n" + (this.idt(1)) + "var ctor = function(){ };\n" + (this.idt(1)) + "__extends(ctor, " + meth + ");\n" + (this.idt(1)) + "return " + (meth) + ".apply(new ctor, " + (this.compileSplatArguments(o)) + ");\n" + this.tab + "}).call(this)";
      } else {
        return "" + (this.prefix()) + (meth) + ".apply(" + obj + ", " + (this.compileSplatArguments(o)) + ")";
      }
    };
    return CallNode;
  })();
  exports.ExtendsNode = (function() {
    ExtendsNode = function(child, parent) {
      this.child = child;
      this.parent = parent;
      return this;
    };
    __extends(ExtendsNode, BaseNode);
    ExtendsNode.prototype['class'] = 'ExtendsNode';
    ExtendsNode.prototype.children = ['child', 'parent'];
    ExtendsNode.prototype.compileNode = function(o) {
      var ref;
      ref = new ValueNode(literal(utility('extends')));
      return (new CallNode(ref, [this.child, this.parent])).compile(o);
    };
    return ExtendsNode;
  })();
  exports.AccessorNode = (function() {
    AccessorNode = function(name, tag) {
      this.name = name;
      this.prototype = tag === 'prototype' ? '.prototype' : '';
      this.soakNode = tag === 'soak';
      return this;
    };
    __extends(AccessorNode, BaseNode);
    AccessorNode.prototype['class'] = 'AccessorNode';
    AccessorNode.prototype.children = ['name'];
    AccessorNode.prototype.compileNode = function(o) {
      var name, namePart;
      name = this.name.compile(o);
      o.chainRoot.wrapped = o.chainRoot.wrapped || this.soakNode;
      namePart = name.match(IS_STRING) ? ("[" + name + "]") : ("." + name);
      return this.prototype + namePart;
    };
    return AccessorNode;
  })();
  exports.IndexNode = (function() {
    IndexNode = function(index) {
      this.index = index;
      return this;
    };
    __extends(IndexNode, BaseNode);
    IndexNode.prototype['class'] = 'IndexNode';
    IndexNode.prototype.children = ['index'];
    IndexNode.prototype.compileNode = function(o) {
      var idx, prefix;
      o.chainRoot.wrapped = o.chainRoot.wrapped || this.soakNode;
      idx = this.index.compile(o);
      prefix = this.proto ? '.prototype' : '';
      return "" + prefix + "[" + idx + "]";
    };
    return IndexNode;
  })();
  exports.RangeNode = (function() {
    RangeNode = function(from, to, exclusive) {
      this.from = from;
      this.to = to;
      this.exclusive = !!exclusive;
      return this;
    };
    __extends(RangeNode, BaseNode);
    RangeNode.prototype['class'] = 'RangeNode';
    RangeNode.prototype.children = ['from', 'to'];
    RangeNode.prototype.compileVariables = function(o) {
      var _b, _c, parts;
      _b = this.from.compileReference(o);
      this.from = _b[0];
      this.fromVar = _b[1];
      _c = this.to.compileReference(o);
      this.to = _c[0];
      this.toVar = _c[1];
      parts = [];
      if (this.from !== this.fromVar) {
        parts.push(this.from.compile(o));
      }
      if (this.to !== this.toVar) {
        parts.push(this.to.compile(o));
      }
      return parts.length ? ("" + (parts.join('; ')) + ";") : '';
    };
    RangeNode.prototype.compileNode = function(o) {
      var equals, idx, op, step, vars;
      if (!(o.index)) {
        return this.compileArray(o);
      }
      idx = del(o, 'index');
      step = del(o, 'step');
      vars = ("" + idx + " = " + (this.fromVar.compile(o)));
      step = step ? step.compile(o) : '1';
      equals = this.exclusive ? '' : '=';
      op = starts(step, '-') ? (">" + equals) : ("<" + equals);
      return "" + vars + "; " + (idx) + " " + op + " " + (this.toVar.compile(o)) + "; " + idx + " += " + step;
    };
    RangeNode.prototype.compileArray = function(o) {
      var body, clause, equals, from, i, idt, post, pre, result, to, vars;
      idt = this.idt(1);
      vars = this.compileVariables(merge(o, {
        indent: idt
      }));
      equals = this.exclusive ? '' : '=';
      from = this.fromVar.compile(o);
      to = this.toVar.compile(o);
      result = o.scope.freeVariable();
      i = o.scope.freeVariable();
      clause = ("" + from + " <= " + to + " ?");
      pre = ("\n" + (idt) + (result) + " = []; " + (vars));
      body = ("var " + i + " = " + from + "; " + clause + " " + i + " <" + equals + " " + to + " : " + i + " >" + equals + " " + to + "; " + clause + " " + i + " += 1 : " + i + " -= 1");
      post = ("{ " + (result) + ".push(" + i + ") };\n" + (idt) + "return " + result + ";\n" + o.indent);
      return "(function(){" + (pre) + "\n" + (idt) + "for (" + body + ")" + post + "}).call(this)";
    };
    return RangeNode;
  })();
  exports.SliceNode = (function() {
    SliceNode = function(range) {
      this.range = range;
      return this;
    };
    __extends(SliceNode, BaseNode);
    SliceNode.prototype['class'] = 'SliceNode';
    SliceNode.prototype.children = ['range'];
    SliceNode.prototype.compileNode = function(o) {
      var from, plusPart, to;
      from = this.range.from.compile(o);
      to = this.range.to.compile(o);
      plusPart = this.range.exclusive ? '' : ' + 1';
      return ".slice(" + from + ", " + to + plusPart + ")";
    };
    return SliceNode;
  })();
  exports.ObjectNode = (function() {
    ObjectNode = function(props) {
      this.objects = (this.properties = props || []);
      return this;
    };
    __extends(ObjectNode, BaseNode);
    ObjectNode.prototype['class'] = 'ObjectNode';
    ObjectNode.prototype.children = ['properties'];
    ObjectNode.prototype.compileNode = function(o) {
      var _b, _c, _d, _e, _f, _g, _h, i, indent, inner, join, lastNoncom, nonComments, prop, props;
      o.indent = this.idt(1);
      nonComments = (function() {
        _b = []; _d = this.properties;
        for (_c = 0, _e = _d.length; _c < _e; _c++) {
          prop = _d[_c];
          !(prop instanceof CommentNode) ? _b.push(prop) : null;
        }
        return _b;
      }).call(this);
      lastNoncom = nonComments[nonComments.length - 1];
      props = (function() {
        _f = []; _g = this.properties;
        for (i = 0, _h = _g.length; i < _h; i++) {
          prop = _g[i];
          _f.push((function() {
            join = ",\n";
            if ((prop === lastNoncom) || (prop instanceof CommentNode)) {
              join = "\n";
            }
            if (i === this.properties.length - 1) {
              join = '';
            }
            indent = prop instanceof CommentNode ? '' : this.idt(1);
            if (!(prop instanceof AssignNode || prop instanceof CommentNode)) {
              prop = new AssignNode(prop, prop, 'object');
            }
            return indent + prop.compile(o) + join;
          }).call(this));
        }
        return _f;
      }).call(this);
      props = props.join('');
      inner = props ? '\n' + props + '\n' + this.idt() : '';
      return "{" + inner + "}";
    };
    return ObjectNode;
  })();
  exports.ArrayNode = (function() {
    ArrayNode = function(objects) {
      this.objects = objects || [];
      this.compileSplatLiteral = function(o) {
        return SplatNode.compileMixedArray.call(this, this.objects, o);
      };
      return this;
    };
    __extends(ArrayNode, BaseNode);
    ArrayNode.prototype['class'] = 'ArrayNode';
    ArrayNode.prototype.children = ['objects'];
    ArrayNode.prototype.compileNode = function(o) {
      var _b, _c, code, i, obj, objects;
      o.indent = this.idt(1);
      objects = [];
      _b = this.objects;
      for (i = 0, _c = _b.length; i < _c; i++) {
        obj = _b[i];
        code = obj.compile(o);
        if (obj instanceof SplatNode) {
          return this.compileSplatLiteral(this.objects, o);
        } else if (obj instanceof CommentNode) {
          objects.push("\n" + code + "\n" + o.indent);
        } else if (i === this.objects.length - 1) {
          objects.push(code);
        } else {
          objects.push("" + code + ", ");
        }
      }
      objects = objects.join('');
      return indexOf(objects, '\n') >= 0 ? ("[\n" + (this.idt(1)) + objects + "\n" + this.tab + "]") : ("[" + objects + "]");
    };
    return ArrayNode;
  })();
  exports.ClassNode = (function() {
    ClassNode = function(variable, parent, props) {
      this.variable = variable;
      this.parent = parent;
      this.properties = props || [];
      this.returns = false;
      return this;
    };
    __extends(ClassNode, BaseNode);
    ClassNode.prototype['class'] = 'ClassNode';
    ClassNode.prototype.children = ['variable', 'parent', 'properties'];
    ClassNode.prototype.isStatement = function() {
      return true;
    };
    ClassNode.prototype.makeReturn = function() {
      this.returns = true;
      return this;
    };
    ClassNode.prototype.compileNode = function(o) {
      var _b, _c, _d, _e, access, applied, className, constScope, construct, constructor, extension, func, me, pname, prop, props, pvar, returns, val;
      extension = this.parent && new ExtendsNode(this.variable, this.parent);
      props = new Expressions();
      o.top = true;
      me = null;
      className = this.variable.compile(o);
      constScope = null;
      if (this.parent) {
        applied = new ValueNode(this.parent, [new AccessorNode(literal('apply'))]);
        constructor = new CodeNode([], new Expressions([new CallNode(applied, [literal('this'), literal('arguments')])]));
      } else {
        constructor = new CodeNode();
      }
      _c = this.properties;
      for (_b = 0, _d = _c.length; _b < _d; _b++) {
        prop = _c[_b];
        _e = [prop.variable, prop.value];
        pvar = _e[0];
        func = _e[1];
        if (pvar && pvar.base.value === 'constructor' && func instanceof CodeNode) {
          if (func.bound) {
            throw new Error("cannot define a constructor as a bound function.");
          }
          func.name = className;
          func.body.push(new ReturnNode(literal('this')));
          this.variable = new ValueNode(this.variable);
          this.variable.namespaced = include(func.name, '.');
          constructor = func;
          continue;
        }
        if (func instanceof CodeNode && func.bound) {
          func.bound = false;
          constScope = constScope || new Scope(o.scope, constructor.body, constructor);
          me = me || constScope.freeVariable();
          pname = pvar.compile(o);
          if (constructor.body.empty()) {
            constructor.body.push(new ReturnNode(literal('this')));
          }
          constructor.body.unshift(literal(("this." + (pname) + " = function(){ return " + (className) + ".prototype." + (pname) + ".apply(" + me + ", arguments); }")));
        }
        if (pvar) {
          access = prop.context === 'this' ? pvar.base.properties[0] : new AccessorNode(pvar, 'prototype');
          val = new ValueNode(this.variable, [access]);
          prop = new AssignNode(val, func);
        }
        props.push(prop);
      }
      if (me) {
        constructor.body.unshift(literal("" + me + " = this"));
      }
      construct = this.idt() + (new AssignNode(this.variable, constructor)).compile(merge(o, {
        sharedScope: constScope
      })) + ';\n';
      props = props.empty() ? '' : props.compile(o) + '\n';
      extension = extension ? this.idt() + extension.compile(o) + ';\n' : '';
      returns = this.returns ? new ReturnNode(this.variable).compile(o) : '';
      return "" + construct + extension + props + returns;
    };
    return ClassNode;
  })();
  exports.AssignNode = (function() {
    AssignNode = function(variable, value, context) {
      this.variable = variable;
      this.value = value;
      this.context = context;
      return this;
    };
    __extends(AssignNode, BaseNode);
    AssignNode.prototype.PROTO_ASSIGN = /^(\S+)\.prototype/;
    AssignNode.prototype.LEADING_DOT = /^\.(prototype\.)?/;
    AssignNode.prototype['class'] = 'AssignNode';
    AssignNode.prototype.children = ['variable', 'value'];
    AssignNode.prototype.topSensitive = function() {
      return true;
    };
    AssignNode.prototype.isValue = function() {
      return this.variable instanceof ValueNode;
    };
    AssignNode.prototype.makeReturn = function() {
      return new Expressions([this, new ReturnNode(this.variable)]);
    };
    AssignNode.prototype.isStatement = function() {
      return this.isValue() && (this.variable.isArray() || this.variable.isObject());
    };
    AssignNode.prototype.compileNode = function(o) {
      var last, match, name, proto, stmt, top, val;
      top = del(o, 'top');
      if (this.isStatement()) {
        return this.compilePatternMatch(o);
      }
      if (this.isValue() && this.variable.isSplice()) {
        return this.compileSplice(o);
      }
      stmt = del(o, 'asStatement');
      name = this.variable.compile(o);
      last = this.isValue() ? this.variable.last.replace(this.LEADING_DOT, '') : name;
      match = name.match(this.PROTO_ASSIGN);
      proto = match && match[1];
      if (this.value instanceof CodeNode) {
        if (last.match(IDENTIFIER)) {
          this.value.name = last;
        }
        if (proto) {
          this.value.proto = proto;
        }
      }
      val = this.value.compile(o);
      if (this.context === 'object') {
        return ("" + name + ": " + val);
      }
      if (!(this.isValue() && (this.variable.hasProperties() || this.variable.namespaced))) {
        o.scope.find(name);
      }
      val = ("" + name + " = " + val);
      if (stmt) {
        return ("" + this.tab + val + ";");
      }
      return top ? val : ("(" + val + ")");
    };
    AssignNode.prototype.compilePatternMatch = function(o) {
      var _b, _c, _d, accessClass, assigns, code, i, idx, isString, obj, oindex, olength, splat, val, valVar, value;
      valVar = o.scope.freeVariable();
      value = this.value.isStatement() ? ClosureNode.wrap(this.value) : this.value;
      assigns = [("" + this.tab + valVar + " = " + (value.compile(o)) + ";")];
      o.top = true;
      o.asStatement = true;
      splat = false;
      _b = this.variable.base.objects;
      for (i = 0, _c = _b.length; i < _c; i++) {
        obj = _b[i];
        idx = i;
        if (this.variable.isObject()) {
          if (obj instanceof AssignNode) {
            _d = [obj.value, obj.variable.base];
            obj = _d[0];
            idx = _d[1];
          } else {
            idx = obj;
          }
        }
        if (!(obj instanceof ValueNode || obj instanceof SplatNode)) {
          throw new Error('pattern matching must use only identifiers on the left-hand side.');
        }
        isString = idx.value && idx.value.match(IS_STRING);
        accessClass = isString || this.variable.isArray() ? IndexNode : AccessorNode;
        if (obj instanceof SplatNode && !splat) {
          val = literal(obj.compileValue(o, valVar, (oindex = indexOf(this.variable.base.objects, obj)), (olength = this.variable.base.objects.length) - oindex - 1));
          splat = true;
        } else {
          if (typeof idx !== 'object') {
            idx = literal(splat ? ("" + (valVar) + ".length - " + (olength - idx)) : idx);
          }
          val = new ValueNode(literal(valVar), [new accessClass(idx)]);
        }
        assigns.push(new AssignNode(obj, val).compile(o));
      }
      code = assigns.join("\n");
      return code;
    };
    AssignNode.prototype.compileSplice = function(o) {
      var from, l, name, plus, range, to, val;
      name = this.variable.compile(merge(o, {
        onlyFirst: true
      }));
      l = this.variable.properties.length;
      range = this.variable.properties[l - 1].range;
      plus = range.exclusive ? '' : ' + 1';
      from = range.from.compile(o);
      to = range.to.compile(o) + ' - ' + from + plus;
      val = this.value.compile(o);
      return "" + (name) + ".splice.apply(" + name + ", [" + from + ", " + to + "].concat(" + val + "))";
    };
    return AssignNode;
  })();
  exports.CodeNode = (function() {
    CodeNode = function(params, body, tag) {
      this.params = params || [];
      this.body = body || new Expressions();
      this.bound = tag === 'boundfunc';
      return this;
    };
    __extends(CodeNode, BaseNode);
    CodeNode.prototype['class'] = 'CodeNode';
    CodeNode.prototype.children = ['params', 'body'];
    CodeNode.prototype.compileNode = function(o) {
      var _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, code, func, i, inner, param, params, sharedScope, splat, top;
      sharedScope = del(o, 'sharedScope');
      top = del(o, 'top');
      o.scope = sharedScope || new Scope(o.scope, this.body, this);
      o.top = true;
      o.indent = this.idt(this.bound ? 2 : 1);
      del(o, 'noWrap');
      del(o, 'globals');
      i = 0;
      splat = undefined;
      params = [];
      _c = this.params;
      for (_b = 0, _d = _c.length; _b < _d; _b++) {
        param = _c[_b];
        if (param instanceof SplatNode && !(typeof splat !== "undefined" && splat !== null)) {
          splat = param;
          splat.index = i;
          splat.trailings = [];
          splat.arglength = this.params.length;
          this.body.unshift(splat);
        } else if (typeof splat !== "undefined" && splat !== null) {
          splat.trailings.push(param);
        } else {
          params.push(param);
        }
        i += 1;
      }
      params = (function() {
        _e = []; _g = params;
        for (_f = 0, _h = _g.length; _f < _h; _f++) {
          param = _g[_f];
          _e.push(param.compile(o));
        }
        return _e;
      })();
      this.body.makeReturn();
      _j = params;
      for (_i = 0, _k = _j.length; _i < _k; _i++) {
        param = _j[_i];
        (o.scope.parameter(param));
      }
      code = this.body.expressions.length ? ("\n" + (this.body.compileWithDeclarations(o)) + "\n") : '';
      func = ("function(" + (params.join(', ')) + ") {" + code + (this.idt(this.bound ? 1 : 0)) + "}");
      if (top && !this.bound) {
        func = ("(" + func + ")");
      }
      if (!(this.bound)) {
        return func;
      }
      inner = ("(function() {\n" + (this.idt(2)) + "return __func.apply(__this, arguments);\n" + (this.idt(1)) + "});");
      return "(function(__this) {\n" + (this.idt(1)) + "var __func = " + func + ";\n" + (this.idt(1)) + "return " + inner + "\n" + this.tab + "})(this)";
    };
    CodeNode.prototype.topSensitive = function() {
      return true;
    };
    CodeNode.prototype.traverseChildren = function(crossScope, func) {
      if (crossScope) {
        return CodeNode.__superClass__.traverseChildren.call(this, crossScope, func);
      }
    };
    CodeNode.prototype.toString = function(idt) {
      var _b, _c, _d, _e, child, children;
      idt = idt || '';
      children = (function() {
        _b = []; _d = this.collectChildren();
        for (_c = 0, _e = _d.length; _c < _e; _c++) {
          child = _d[_c];
          _b.push(child.toString(idt + TAB));
        }
        return _b;
      }).call(this).join('');
      return "\n" + idt + children;
    };
    return CodeNode;
  })();
  exports.SplatNode = (function() {
    SplatNode = function(name) {
      if (!(name.compile)) {
        name = literal(name);
      }
      this.name = name;
      return this;
    };
    __extends(SplatNode, BaseNode);
    SplatNode.prototype['class'] = 'SplatNode';
    SplatNode.prototype.children = ['name'];
    SplatNode.prototype.compileNode = function(o) {
      var _b;
      return (typeof (_b = this.index) !== "undefined" && _b !== null) ? this.compileParam(o) : this.name.compile(o);
    };
    SplatNode.prototype.compileParam = function(o) {
      var _b, _c, idx, len, name, pos, trailing, variadic;
      name = this.name.compile(o);
      o.scope.find(name);
      len = o.scope.freeVariable();
      o.scope.assign(len, "arguments.length");
      variadic = o.scope.freeVariable();
      o.scope.assign(variadic, ("" + len + " >= " + this.arglength));
      _b = this.trailings;
      for (idx = 0, _c = _b.length; idx < _c; idx++) {
        trailing = _b[idx];
        pos = this.trailings.length - idx;
        o.scope.assign(trailing.compile(o), ("arguments[" + variadic + " ? " + len + " - " + pos + " : " + (this.index + idx) + "]"));
      }
      return "" + name + " = " + (utility('slice')) + ".call(arguments, " + this.index + ", " + len + " - " + (this.trailings.length) + ")";
    };
    SplatNode.prototype.compileValue = function(o, name, index, trailings) {
      var trail;
      trail = trailings ? (", " + (name) + ".length - " + trailings) : '';
      return "" + (utility('slice')) + ".call(" + name + ", " + index + trail + ")";
    };
    SplatNode.compileMixedArray = function(list, o) {
      var _b, _c, _d, arg, args, code, i, prev;
      args = [];
      i = 0;
      _c = list;
      for (_b = 0, _d = _c.length; _b < _d; _b++) {
        arg = _c[_b];
        code = arg.compile(o);
        if (!(arg instanceof SplatNode)) {
          prev = args[i - 1];
          if (i === 1 && prev.substr(0, 1) === '[' && prev.substr(prev.length - 1, 1) === ']') {
            args[i - 1] = ("" + (prev.substr(0, prev.length - 1)) + ", " + code + "]");
            continue;
          } else if (i > 1 && prev.substr(0, 9) === '.concat([' && prev.substr(prev.length - 2, 2) === '])') {
            args[i - 1] = ("" + (prev.substr(0, prev.length - 2)) + ", " + code + "])");
            continue;
          } else {
            code = ("[" + code + "]");
          }
        }
        args.push(i === 0 ? code : (".concat(" + code + ")"));
        i += 1;
      }
      return args.join('');
    };
    return SplatNode;
  }).call(this);
  exports.WhileNode = (function() {
    WhileNode = function(condition, opts) {
      if (opts && opts.invert) {
        if (condition instanceof OpNode) {
          condition = new ParentheticalNode(condition);
        }
        condition = new OpNode('!', condition);
      }
      this.condition = condition;
      this.guard = opts && opts.guard;
      return this;
    };
    __extends(WhileNode, BaseNode);
    WhileNode.prototype['class'] = 'WhileNode';
    WhileNode.prototype.children = ['condition', 'guard', 'body'];
    WhileNode.prototype.isStatement = function() {
      return true;
    };
    WhileNode.prototype.addBody = function(body) {
      this.body = body;
      return this;
    };
    WhileNode.prototype.makeReturn = function() {
      this.returns = true;
      return this;
    };
    WhileNode.prototype.topSensitive = function() {
      return true;
    };
    WhileNode.prototype.compileNode = function(o) {
      var cond, post, pre, rvar, set, top;
      top = del(o, 'top') && !this.returns;
      o.indent = this.idt(1);
      o.top = true;
      cond = this.condition.compile(o);
      set = '';
      if (!(top)) {
        rvar = o.scope.freeVariable();
        set = ("" + this.tab + rvar + " = [];\n");
        if (this.body) {
          this.body = PushNode.wrap(rvar, this.body);
        }
      }
      pre = ("" + set + (this.tab) + "while (" + cond + ")");
      if (this.guard) {
        this.body = Expressions.wrap([new IfNode(this.guard, this.body)]);
      }
      this.returns ? (post = '\n' + new ReturnNode(literal(rvar)).compile(merge(o, {
        indent: this.idt()
      }))) : (post = '');
      return "" + pre + " {\n" + (this.body.compile(o)) + "\n" + this.tab + "}" + post;
    };
    return WhileNode;
  })();
  exports.OpNode = (function() {
    OpNode = function(operator, first, second, flip) {
      this.first = first;
      this.second = second;
      this.operator = this.CONVERSIONS[operator] || operator;
      this.flip = !!flip;
      return this;
    };
    __extends(OpNode, BaseNode);
    OpNode.prototype.CONVERSIONS = {
      '==': '===',
      '!=': '!=='
    };
    OpNode.prototype.CHAINABLE = ['<', '>', '>=', '<=', '===', '!=='];
    OpNode.prototype.ASSIGNMENT = ['||=', '&&=', '?='];
    OpNode.prototype.PREFIX_OPERATORS = ['typeof', 'delete'];
    OpNode.prototype['class'] = 'OpNode';
    OpNode.prototype.children = ['first', 'second'];
    OpNode.prototype.isUnary = function() {
      return !this.second;
    };
    OpNode.prototype.isChainable = function() {
      return indexOf(this.CHAINABLE, this.operator) >= 0;
    };
    OpNode.prototype.toString = function(idt) {
      return OpNode.__superClass__.toString.call(this, idt, this['class'] + ' ' + this.operator);
    };
    OpNode.prototype.compileNode = function(o) {
      o.operation = true;
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
      return [this.first.compile(o), this.operator, this.second.compile(o)].join(' ');
    };
    OpNode.prototype.compileChain = function(o) {
      var _b, _c, first, second, shared;
      shared = this.first.unwrap().second;
      if (shared.containsType(CallNode)) {
        _b = shared.compileReference(o);
        this.first.second = _b[0];
        shared = _b[1];
      }
      _c = [this.first.compile(o), this.second.compile(o), shared.compile(o)];
      first = _c[0];
      second = _c[1];
      shared = _c[2];
      return "(" + first + ") && (" + shared + " " + this.operator + " " + second + ")";
    };
    OpNode.prototype.compileAssignment = function(o) {
      var _b, first, second;
      _b = [this.first.compile(o), this.second.compile(o)];
      first = _b[0];
      second = _b[1];
      if (first.match(IDENTIFIER)) {
        o.scope.find(first);
      }
      if (this.operator === '?=') {
        return ("" + first + " = " + (ExistenceNode.compileTest(o, this.first)) + " ? " + first + " : " + second);
      }
      return "" + first + " = " + first + " " + (this.operator.substr(0, 2)) + " " + second;
    };
    OpNode.prototype.compileExistence = function(o) {
      var _b, first, second, test;
      _b = [this.first.compile(o), this.second.compile(o)];
      first = _b[0];
      second = _b[1];
      test = ExistenceNode.compileTest(o, this.first);
      return "" + test + " ? " + first + " : " + second;
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
    InNode = function(object, array) {
      this.object = object;
      this.array = array;
      return this;
    };
    __extends(InNode, BaseNode);
    InNode.prototype['class'] = 'InNode';
    InNode.prototype.children = ['object', 'array'];
    InNode.prototype.isArray = function() {
      return this.array instanceof ValueNode && this.array.isArray();
    };
    InNode.prototype.compileNode = function(o) {
      var _b;
      _b = this.object.compileReference(o, {
        precompile: true
      });
      this.obj1 = _b[0];
      this.obj2 = _b[1];
      return this.isArray() ? this.compileOrTest(o) : this.compileLoopTest(o);
    };
    InNode.prototype.compileOrTest = function(o) {
      var _b, _c, _d, i, item, tests;
      tests = (function() {
        _b = []; _c = this.array.base.objects;
        for (i = 0, _d = _c.length; i < _d; i++) {
          item = _c[i];
          _b.push(("" + (item.compile(o)) + " === " + (i ? this.obj2 : this.obj1)));
        }
        return _b;
      }).call(this);
      return "(" + (tests.join(' || ')) + ")";
    };
    InNode.prototype.compileLoopTest = function(o) {
      var _b, _c, i, l, prefix;
      _b = this.array.compileReference(o, {
        precompile: true
      });
      this.arr1 = _b[0];
      this.arr2 = _b[1];
      _c = [o.scope.freeVariable(), o.scope.freeVariable()];
      i = _c[0];
      l = _c[1];
      prefix = this.obj1 !== this.obj2 ? this.obj1 + '; ' : '';
      return "!!(function(){ " + (prefix) + "for (var " + i + "=0, " + l + "=" + (this.arr1) + ".length; " + i + "<" + l + "; " + i + "++) if (" + (this.arr2) + "[" + i + "] === " + this.obj2 + ") return true; }).call(this)";
    };
    return InNode;
  })();
  exports.TryNode = (function() {
    TryNode = function(attempt, error, recovery, ensure) {
      this.attempt = attempt;
      this.recovery = recovery;
      this.ensure = ensure;
      this.error = error;
      return this;
    };
    __extends(TryNode, BaseNode);
    TryNode.prototype['class'] = 'TryNode';
    TryNode.prototype.children = ['attempt', 'recovery', 'ensure'];
    TryNode.prototype.isStatement = function() {
      return true;
    };
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
      catchPart = this.recovery ? (" catch" + errorPart + "{\n" + (this.recovery.compile(o)) + "\n" + this.tab + "}") : '';
      finallyPart = (this.ensure || '') && ' finally {\n' + this.ensure.compile(merge(o)) + ("\n" + this.tab + "}");
      return "" + (this.tab) + "try {\n" + attemptPart + "\n" + this.tab + "}" + catchPart + finallyPart;
    };
    return TryNode;
  })();
  exports.ThrowNode = (function() {
    ThrowNode = function(expression) {
      this.expression = expression;
      return this;
    };
    __extends(ThrowNode, BaseNode);
    ThrowNode.prototype['class'] = 'ThrowNode';
    ThrowNode.prototype.children = ['expression'];
    ThrowNode.prototype.isStatement = function() {
      return true;
    };
    ThrowNode.prototype.makeReturn = function() {
      return this;
    };
    ThrowNode.prototype.compileNode = function(o) {
      return "" + (this.tab) + "throw " + (this.expression.compile(o)) + ";";
    };
    return ThrowNode;
  })();
  exports.ExistenceNode = (function() {
    ExistenceNode = function(expression) {
      this.expression = expression;
      return this;
    };
    __extends(ExistenceNode, BaseNode);
    ExistenceNode.prototype['class'] = 'ExistenceNode';
    ExistenceNode.prototype.children = ['expression'];
    ExistenceNode.prototype.compileNode = function(o) {
      return ExistenceNode.compileTest(o, this.expression);
    };
    ExistenceNode.compileTest = function(o, variable) {
      var _b, first, second;
      _b = variable.compileReference(o);
      first = _b[0];
      second = _b[1];
      return "(typeof " + (first.compile(o)) + " !== \"undefined\" && " + (second.compile(o)) + " !== null)";
    };
    return ExistenceNode;
  }).call(this);
  exports.ParentheticalNode = (function() {
    ParentheticalNode = function(expression) {
      this.expression = expression;
      return this;
    };
    __extends(ParentheticalNode, BaseNode);
    ParentheticalNode.prototype['class'] = 'ParentheticalNode';
    ParentheticalNode.prototype.children = ['expression'];
    ParentheticalNode.prototype.isStatement = function() {
      return this.expression.isStatement();
    };
    ParentheticalNode.prototype.makeReturn = function() {
      return this.expression.makeReturn();
    };
    ParentheticalNode.prototype.topSensitive = function() {
      return true;
    };
    ParentheticalNode.prototype.compileNode = function(o) {
      var code, l, top;
      top = del(o, 'top');
      code = this.expression.compile(o);
      if (this.isStatement()) {
        return (top ? ("" + this.tab + code + ";") : code);
      }
      l = code.length;
      if (code.substr(l - 1, 1) === ';') {
        code = code.substr(o, l - 1);
      }
      return this.expression instanceof AssignNode ? code : ("(" + code + ")");
    };
    return ParentheticalNode;
  })();
  exports.ForNode = (function() {
    ForNode = function(body, source, name, index) {
      var _b;
      this.body = body;
      this.name = name;
      this.index = index || null;
      this.source = source.source;
      this.guard = source.guard;
      this.step = source.step;
      this.object = !!source.object;
      if (this.object) {
        _b = [this.index, this.name];
        this.name = _b[0];
        this.index = _b[1];
      }
      this.pattern = this.name instanceof ValueNode;
      if (this.index instanceof ValueNode) {
        throw new Error('index cannot be a pattern matching expression');
      }
      this.returns = false;
      return this;
    };
    __extends(ForNode, BaseNode);
    ForNode.prototype['class'] = 'ForNode';
    ForNode.prototype.children = ['body', 'source', 'guard'];
    ForNode.prototype.isStatement = function() {
      return true;
    };
    ForNode.prototype.topSensitive = function() {
      return true;
    };
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
      var body, close, codeInBody, forPart, index, ivar, lvar, name, namePart, range, returnResult, rvar, scope, source, sourcePart, stepPart, svar, topLevel, varPart, vars;
      topLevel = del(o, 'top') && !this.returns;
      range = this.source instanceof ValueNode && this.source.base instanceof RangeNode && !this.source.properties.length;
      source = range ? this.source.base : this.source;
      codeInBody = this.body.contains(function(n) {
        return n instanceof CodeNode;
      });
      scope = o.scope;
      name = this.name && this.name.compile(o);
      index = this.index && this.index.compile(o);
      if (name && !this.pattern && !codeInBody) {
        scope.find(name);
      }
      if (index) {
        scope.find(index);
      }
      if (!(topLevel)) {
        rvar = scope.freeVariable();
      }
      ivar = (function() {
        if (range) {
          return name;
        } else if (codeInBody) {
          return scope.freeVariable();
        } else {
          return index || scope.freeVariable();
        }
      })();
      varPart = '';
      body = Expressions.wrap([this.body]);
      if (range) {
        sourcePart = source.compileVariables(o);
        if (sourcePart) {
          sourcePart += ("\n" + o.indent);
        }
        forPart = source.compile(merge(o, {
          index: ivar,
          step: this.step
        }));
      } else {
        svar = scope.freeVariable();
        sourcePart = ("" + svar + " = " + (this.source.compile(o)) + ";");
        if (this.pattern) {
          namePart = new AssignNode(this.name, literal("" + svar + "[" + ivar + "]")).compile(merge(o, {
            indent: this.idt(1),
            top: true
          })) + '\n';
        } else {
          if (name) {
            namePart = ("" + name + " = " + svar + "[" + ivar + "]");
          }
        }
        if (!(this.object)) {
          lvar = scope.freeVariable();
          stepPart = this.step ? ("" + ivar + " += " + (this.step.compile(o))) : ("" + ivar + "++");
          forPart = ("" + ivar + " = 0, " + lvar + " = " + (svar) + ".length; " + ivar + " < " + lvar + "; " + stepPart);
        }
      }
      sourcePart = (rvar ? ("" + rvar + " = []; ") : '') + sourcePart;
      sourcePart = sourcePart ? ("" + this.tab + sourcePart + "\n" + this.tab) : this.tab;
      returnResult = this.compileReturnValue(rvar, o);
      if (!(topLevel)) {
        body = PushNode.wrap(rvar, body);
      }
      this.guard ? (body = Expressions.wrap([new IfNode(this.guard, body)])) : null;
      if (codeInBody) {
        if (namePart) {
          body.unshift(literal("var " + namePart));
        }
        if (index) {
          body.unshift(literal("var " + index + " = " + ivar));
        }
        body = ClosureNode.wrap(body, true);
      } else {
        varPart = (namePart || '') && (this.pattern ? namePart : ("" + (this.idt(1)) + namePart + ";\n"));
      }
      this.object ? (forPart = ("" + ivar + " in " + svar + ") { if (" + (utility('hasProp')) + ".call(" + svar + ", " + ivar + ")")) : null;
      body = body.compile(merge(o, {
        indent: this.idt(1),
        top: true
      }));
      vars = range ? name : ("" + name + ", " + ivar);
      close = this.object ? '}}' : '}';
      return "" + (sourcePart) + "for (" + forPart + ") {\n" + varPart + body + "\n" + this.tab + close + returnResult;
    };
    return ForNode;
  })();
  exports.IfNode = (function() {
    IfNode = function(condition, body, tags) {
      this.condition = condition;
      this.body = body;
      this.elseBody = null;
      this.tags = tags || {};
      if (this.tags.invert) {
        this.condition = new OpNode('!', new ParentheticalNode(this.condition));
      }
      this.isChain = false;
      return this;
    };
    __extends(IfNode, BaseNode);
    IfNode.prototype['class'] = 'IfNode';
    IfNode.prototype.children = ['condition', 'switchSubject', 'body', 'elseBody', 'assigner'];
    IfNode.prototype.bodyNode = function() {
      return this.body == undefined ? undefined : this.body.unwrap();
    };
    IfNode.prototype.elseBodyNode = function() {
      return this.elseBody == undefined ? undefined : this.elseBody.unwrap();
    };
    IfNode.prototype.forceStatement = function() {
      this.tags.statement = true;
      return this;
    };
    IfNode.prototype.switchesOver = function(expression) {
      this.switchSubject = expression;
      return this;
    };
    IfNode.prototype.rewriteSwitch = function(o) {
      var _b, _c, _d, cond, i, variable;
      this.assigner = this.switchSubject;
      if (!((this.switchSubject.unwrap() instanceof LiteralNode))) {
        variable = literal(o.scope.freeVariable());
        this.assigner = new AssignNode(variable, this.switchSubject);
        this.switchSubject = variable;
      }
      this.condition = (function() {
        _b = []; _c = flatten([this.condition]);
        for (i = 0, _d = _c.length; i < _d; i++) {
          cond = _c[i];
          _b.push((function() {
            if (cond instanceof OpNode) {
              cond = new ParentheticalNode(cond);
            }
            return new OpNode('==', (i === 0 ? this.assigner : this.switchSubject), cond);
          }).call(this));
        }
        return _b;
      }).call(this);
      if (this.isChain) {
        this.elseBodyNode().switchesOver(this.switchSubject);
      }
      this.switchSubject = undefined;
      return this;
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
    IfNode.prototype.isStatement = function() {
      return this.statement = this.statement || !!(this.tags.statement || this.bodyNode().isStatement() || (this.elseBody && this.elseBodyNode().isStatement()));
    };
    IfNode.prototype.compileCondition = function(o) {
      var _b, _c, _d, _e, cond;
      return (function() {
        _b = []; _d = flatten([this.condition]);
        for (_c = 0, _e = _d.length; _c < _e; _c++) {
          cond = _d[_c];
          _b.push(cond.compile(o));
        }
        return _b;
      }).call(this).join(' || ');
    };
    IfNode.prototype.compileNode = function(o) {
      return this.isStatement() ? this.compileStatement(o) : this.compileTernary(o);
    };
    IfNode.prototype.makeReturn = function() {
      if (this.isStatement()) {
        this.body = this.body && this.ensureExpressions(this.body.makeReturn());
        this.elseBody = this.elseBody && this.ensureExpressions(this.elseBody.makeReturn());
        return this;
      } else {
        return new ReturnNode(this);
      }
    };
    IfNode.prototype.ensureExpressions = function(node) {
      return node instanceof Expressions ? node : new Expressions([node]);
    };
    IfNode.prototype.compileStatement = function(o) {
      var body, child, comDent, condO, elsePart, ifDent, ifPart;
      if (this.switchSubject) {
        this.rewriteSwitch(o);
      }
      child = del(o, 'chainChild');
      condO = merge(o);
      o.indent = this.idt(1);
      o.top = true;
      ifDent = child ? '' : this.idt();
      comDent = child ? this.idt() : '';
      body = this.body.compile(o);
      ifPart = ("" + (ifDent) + "if (" + (this.compileCondition(condO)) + ") {\n" + body + "\n" + this.tab + "}");
      if (!(this.elseBody)) {
        return ifPart;
      }
      elsePart = this.isChain ? ' else ' + this.elseBodyNode().compile(merge(o, {
        indent: this.idt(),
        chainChild: true
      })) : (" else {\n" + (this.elseBody.compile(o)) + "\n" + this.tab + "}");
      return "" + ifPart + elsePart;
    };
    IfNode.prototype.compileTernary = function(o) {
      var elsePart, ifPart;
      ifPart = this.condition.compile(o) + ' ? ' + this.bodyNode().compile(o);
      elsePart = this.elseBody ? this.elseBodyNode().compile(o) : 'null';
      return "" + ifPart + " : " + elsePart;
    };
    return IfNode;
  })();
  PushNode = (exports.PushNode = {
    wrap: function(array, expressions) {
      var expr;
      expr = expressions.unwrap();
      if (expr.isPureStatement() || expr.containsPureStatement()) {
        return expressions;
      }
      return Expressions.wrap([new CallNode(new ValueNode(literal(array), [new AccessorNode(literal('push'))]), [expr])]);
    }
  });
  ClosureNode = (exports.ClosureNode = {
    wrap: function(expressions, statement) {
      var args, call, func, mentionsArgs, mentionsThis, meth;
      if (expressions.containsPureStatement()) {
        return expressions;
      }
      func = new ParentheticalNode(new CodeNode([], Expressions.wrap([expressions])));
      args = [];
      mentionsArgs = expressions.contains(function(n) {
        return n instanceof LiteralNode && (n.value === 'arguments');
      });
      mentionsThis = expressions.contains(function(n) {
        return (n instanceof LiteralNode && (n.value === 'this')) || (n instanceof CodeNode && n.bound);
      });
      if (mentionsArgs || mentionsThis) {
        meth = literal(mentionsArgs ? 'apply' : 'call');
        args = [literal('this')];
        if (mentionsArgs) {
          args.push(literal('arguments'));
        }
        func = new ValueNode(func, [new AccessorNode(meth)]);
      }
      call = new CallNode(func, args);
      return statement ? Expressions.wrap([call]) : call;
    }
  });
  UTILITIES = {
    __extends: "function(child, parent) {\n    var ctor = function(){ };\n    ctor.prototype = parent.prototype;\n    child.__superClass__ = parent.prototype;\n    child.prototype = new ctor();\n    child.prototype.constructor = child;\n  }",
    __hasProp: 'Object.prototype.hasOwnProperty',
    __slice: 'Array.prototype.slice'
  };
  TAB = '  ';
  TRAILING_WHITESPACE = /[ \t]+$/gm;
  DOUBLE_PARENS = /\(\(([^\(\)\n]*)\)\)/g;
  IDENTIFIER = /^[a-zA-Z\$_](\w|\$)*$/;
  NUMBER = /^(((\b0(x|X)[0-9a-fA-F]+)|((\b[0-9]+(\.[0-9]+)?|\.[0-9]+)(e[+\-]?[0-9]+)?)))\b$/i;
  IS_STRING = /^['"]/;
  literal = function(name) {
    return new LiteralNode(name);
  };
  utility = function(name) {
    var ref;
    ref = ("__" + name);
    Scope.root.assign(ref, UTILITIES[ref]);
    return ref;
  };
})();
