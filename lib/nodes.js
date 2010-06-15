(function(){
  var AccessorNode, ArrayNode, AssignNode, BaseNode, CallNode, ClassNode, ClosureNode, CodeNode, CommentNode, ExistenceNode, Expressions, ExtendsNode, ForNode, IDENTIFIER, IS_STRING, IfNode, IndexNode, LiteralNode, NUMBER, ObjectNode, OpNode, ParentheticalNode, PushNode, RangeNode, ReturnNode, Scope, SliceNode, SplatNode, TAB, TRAILING_WHITESPACE, ThrowNode, TryNode, UTILITIES, ValueNode, WhileNode, _a, compact, del, flatten, helpers, include, indexOf, literal, merge, starts, utility;
  var __extends = function(child, parent) {
    var ctor = function(){ };
    ctor.prototype = parent.prototype;
    child.__superClass__ = parent.prototype;
    child.prototype = new ctor();
    child.prototype.constructor = child;
  };
  // `nodes.coffee` contains all of the node classes for the syntax tree. Most
  // nodes are created as the result of actions in the [grammar](grammar.html),
  // but some are created by other nodes as a method of code generation. To convert
  // the syntax tree into a string of JavaScript code, call `compile()` on the root.
  // Set up for both **Node.js** and the browser, by
  // including the [Scope](scope.html) class and the [helper](helpers.html) functions.
  if ((typeof process !== "undefined" && process !== null)) {
    Scope = require('./scope').Scope;
    helpers = require('./helpers').helpers;
  } else {
    this.exports = this;
    helpers = this.helpers;
    Scope = this.Scope;
  }
  // Import the helpers we plan to use.
  _a = helpers;
  compact = _a.compact;
  flatten = _a.flatten;
  merge = _a.merge;
  del = _a.del;
  include = _a.include;
  indexOf = _a.indexOf;
  starts = _a.starts;
  //### BaseNode
  // The **BaseNode** is the abstract base class for all nodes in the syntax tree.
  // Each subclass implements the `compileNode` method, which performs the
  // code generation for that node. To compile a node to JavaScript,
  // call `compile` on it, which wraps `compileNode` in some generic extra smarts,
  // to know when the generated code needs to be wrapped up in a closure.
  // An options hash is passed and cloned throughout, containing information about
  // the environment from higher in the tree (such as if a returned value is
  // being requested by the surrounding function), information about the current
  // scope, and indentation level.
  exports.BaseNode = (function() {
    BaseNode = function() {    };
    // Common logic for determining whether to wrap this node in a closure before
    // compiling it, or to compile directly. We need to wrap if this node is a
    // *statement*, and it's not a *pureStatement*, and we're not at
    // the top level of a block (which would be unnecessary), and we haven't
    // already been asked to return the result (because statements know how to
    // return results).
    // If a Node is *topSensitive*, that means that it needs to compile differently
    // depending on whether it's being used as part of a larger expression, or is a
    // top-level statement within the function body.
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
      if (closure) {
        return this.compileClosure(this.options);
      } else {
        return this.compileNode(this.options);
      }
    };
    // Statements converted into expressions via closure-wrapping share a scope
    // object with their parent closure, to preserve the expected lexical scope.
    BaseNode.prototype.compileClosure = function(o) {
      this.tab = o.indent;
      o.sharedScope = o.scope;
      return ClosureNode.wrap(this).compile(o);
    };
    // If the code generation wishes to use the result of a complex expression
    // in multiple places, ensure that the expression is only ever evaluated once,
    // by assigning it to a temporary variable.
    BaseNode.prototype.compileReference = function(o, onlyIfNecessary) {
      var compiled, reference;
      if (onlyIfNecessary && !(this instanceof CallNode || this instanceof ValueNode && (!(this.base instanceof LiteralNode) || this.hasProperties()))) {
        return [this, this];
      }
      reference = literal(o.scope.freeVariable());
      compiled = new AssignNode(reference, this);
      return [compiled, reference];
    };
    // Convenience method to grab the current indentation level, plus tabbing in.
    BaseNode.prototype.idt = function(tabs) {
      var idt, num;
      idt = this.tab || '';
      num = (tabs || 0) + 1;
      while (num -= 1) {
        idt += TAB;
      }
      return idt;
    };
    // Construct a node that returns the current node's result.
    // Note that this is overridden for smarter behavior for
    // many statement nodes (eg IfNode, ForNode)...
    BaseNode.prototype.makeReturn = function() {
      return new ReturnNode(this);
    };
    // Does this node, or any of its children, contain a node of a certain kind?
    // Recursively traverses down the *children* of the nodes, yielding to a block
    // and returning true when the block finds a match. `contains` does not cross
    // scope boundaries.
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
    // Is this node of a certain type, or does it contain the type?
    BaseNode.prototype.containsType = function(type) {
      return this instanceof type || this.contains(function(n) {
        return n instanceof type;
      });
    };
    // Convenience for the most common use of contains. Does the node contain
    // a pure statement?
    BaseNode.prototype.containsPureStatement = function() {
      return this.isPureStatement() || this.contains(function(n) {
        return n.isPureStatement();
      });
    };
    // Perform an in-order traversal of the AST. Crosses scope boundaries.
    BaseNode.prototype.traverse = function(block) {
      return this.traverseChildren(true, block);
    };
    // `toString` representation of the node, for inspecting the parse tree.
    // This is what `coffee --nodes` prints out.
    BaseNode.prototype.toString = function(idt) {
      var _b, _c, _d, _e, child;
      idt = idt || '';
      return '\n' + idt + this['class'] + (function() {
        _b = []; _d = this.collectChildren();
        for (_c = 0, _e = _d.length; _c < _e; _c++) {
          child = _d[_c];
          _b.push(child.toString(idt + TAB));
        }
        return _b;
      }).call(this).join('');
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
    // Default implementations of the common node properties and methods. Nodes
    // will override these with custom logic, if needed.
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
  //### Expressions
  // The expressions body is the list of expressions that forms the body of an
  // indented block of code -- the implementation of a function, a clause in an
  // `if`, `switch`, or `try`, and so on...
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
    // Tack an expression on to the end of this expression list.
    Expressions.prototype.push = function(node) {
      this.expressions.push(node);
      return this;
    };
    // Add an expression at the beginning of this expression list.
    Expressions.prototype.unshift = function(node) {
      this.expressions.unshift(node);
      return this;
    };
    // If this Expressions consists of just a single node, unwrap it by pulling
    // it back out.
    Expressions.prototype.unwrap = function() {
      if (this.expressions.length === 1) {
        return this.expressions[0];
      } else {
        return this;
      }
    };
    // Is this an empty block of code?
    Expressions.prototype.empty = function() {
      return this.expressions.length === 0;
    };
    // An Expressions node does not return its entire body, rather it
    // ensures that the final expression is returned.
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
    // An **Expressions** is the only node that can serve as the root.
    Expressions.prototype.compile = function(o) {
      o = o || {};
      if (o.scope) {
        return Expressions.__superClass__.compile.call(this, o);
      } else {
        return this.compileRoot(o);
      }
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
    // If we happen to be the top-level **Expressions**, wrap everything in
    // a safety closure, unless requested not to.
    Expressions.prototype.compileRoot = function(o) {
      var code;
      o.indent = (this.tab = o.noWrap ? '' : TAB);
      o.scope = new Scope(null, this, null);
      code = o.globals ? this.compileNode(o) : this.compileWithDeclarations(o);
      code = code.replace(TRAILING_WHITESPACE, '');
      if (o.noWrap) {
        return code;
      } else {
        return "(function(){\n" + code + "\n})();\n";
      }
    };
    // Compile the expressions body for the contents of a function, with
    // declarations of all inner variables pushed up to the top.
    Expressions.prototype.compileWithDeclarations = function(o) {
      var code;
      code = this.compileNode(o);
      if (o.scope.hasAssignments(this)) {
        code = ("" + (this.tab) + "var " + (o.scope.compiledAssignments()) + ";\n" + code);
      }
      if (o.scope.hasDeclarations(this)) {
        code = ("" + (this.tab) + "var " + (o.scope.compiledDeclarations()) + ";\n" + code);
      }
      return code;
    };
    // Compiles a single expression within the expressions body. If we need to
    // return the result, and it's an expression, simply return it. If it's a
    // statement, ask the statement to do so.
    Expressions.prototype.compileExpression = function(node, o) {
      var compiledNode;
      this.tab = o.indent;
      compiledNode = node.compile(merge(o, {
        top: true
      }));
      if (node.isStatement()) {
        return compiledNode;
      } else {
        return "" + (this.idt()) + compiledNode + ";";
      }
    };
    return Expressions;
  })();
  // Wrap up the given nodes as an **Expressions**, unless it already happens
  // to be one.
  Expressions.wrap = function(nodes) {
    if (nodes.length === 1 && nodes[0] instanceof Expressions) {
      return nodes[0];
    }
    return new Expressions(nodes);
  };
  //### LiteralNode
  // Literals are static values that can be passed through directly into
  // JavaScript without translation, such as: strings, numbers,
  // `true`, `false`, `null`...
  exports.LiteralNode = (function() {
    LiteralNode = function(value) {
      this.value = value;
      return this;
    };
    __extends(LiteralNode, BaseNode);
    LiteralNode.prototype['class'] = 'LiteralNode';
    // Break and continue must be treated as pure statements -- they lose their
    // meaning when wrapped in a closure.
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
  //### ReturnNode
  // A `return` is a *pureStatement* -- wrapping it in a closure wouldn't
  // make sense.
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
    ReturnNode.prototype.topSensitive = function() {
      return true;
    };
    ReturnNode.prototype.makeReturn = function() {
      return this;
    };
    ReturnNode.prototype.compileNode = function(o) {
      var expr;
      expr = this.expression.makeReturn();
      if (!(expr instanceof ReturnNode)) {
        return expr.compile(o);
      }
      del(o, 'top');
      if (this.expression.isStatement()) {
        o.asStatement = true;
      }
      return "" + (this.tab) + "return " + (this.expression.compile(o)) + ";";
    };
    return ReturnNode;
  })();
  //### ValueNode
  // A value, variable or literal or parenthesized, indexed or dotted into,
  // or vanilla.
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
    // A **ValueNode** has a base and a list of property accesses.
    // Add a property access to the list.
    ValueNode.prototype.push = function(prop) {
      this.properties.push(prop);
      return this;
    };
    ValueNode.prototype.hasProperties = function() {
      return !!this.properties.length;
    };
    // Some boolean checks for the benefit of other nodes.
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
      if (this.hasProperties()) {
        return ValueNode.__superClass__.makeReturn.call(this);
      } else {
        return this.base.makeReturn();
      }
    };
    // The value can be unwrapped as its inner node, if there are no attached
    // properties.
    ValueNode.prototype.unwrap = function() {
      if (this.properties.length) {
        return this;
      } else {
        return this.base;
      }
    };
    // Values are considered to be statements if their base is a statement.
    ValueNode.prototype.isStatement = function() {
      return this.base.isStatement && this.base.isStatement() && !this.hasProperties();
    };
    ValueNode.prototype.isNumber = function() {
      return this.base instanceof LiteralNode && this.base.value.match(NUMBER);
    };
    // Works out if the value is the start of a chain.
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
    // We compile a value to JavaScript by compiling and joining each property.
    // Things get much more insteresting if the chain of properties has *soak*
    // operators `?.` interspersed. Then we have to take care not to accidentally
    // evaluate a anything twice when building the soak chain.
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
      if (op && this.wrapped) {
        return "(" + complete + ")";
      } else {
        return complete;
      }
    };
    return ValueNode;
  })();
  //### CommentNode
  // CoffeeScript passes through comments as JavaScript comments at the
  // same position.
  exports.CommentNode = (function() {
    CommentNode = function(lines, kind) {
      this.lines = lines;
      this.kind = kind;
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
      if (this.kind === 'herecomment') {
        sep = '\n' + this.tab;
        return "" + this.tab + "/*" + sep + (this.lines.join(sep)) + "\n" + this.tab + "*/";
      } else {
        return ("" + this.tab + "//") + this.lines.join(("\n" + this.tab + "//"));
      }
    };
    return CommentNode;
  })();
  //### CallNode
  // Node for a function invocation. Takes care of converting `super()` calls into
  // calls against the prototype's function of the same name.
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
    // Tag this invocation as creating a new instance.
    CallNode.prototype.newInstance = function() {
      this.isNew = true;
      return this;
    };
    CallNode.prototype.prefix = function() {
      if (this.isNew) {
        return 'new ';
      } else {
        return '';
      }
    };
    // Grab the reference to the superclass' implementation of the current method.
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
    // Compile a vanilla function call.
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
      if (o.operation && this.wrapped) {
        return "(" + compilation + ")";
      } else {
        return compilation;
      }
    };
    // `super()` is converted into a call against the superclass's implementation
    // of the current function.
    CallNode.prototype.compileSuper = function(args, o) {
      return "" + (this.superReference(o)) + ".call(this" + (args.length ? ', ' : '') + args + ")";
    };
    // If you call a function with a splat, it's converted into a JavaScript
    // `.apply()` call to allow an array of arguments to be passed.
    CallNode.prototype.compileSplat = function(o) {
      var meth, obj, temp;
      meth = this.variable ? this.variable.compile(o) : this.superReference(o);
      obj = this.variable && this.variable.source || 'this';
      if (obj.match(/\(/)) {
        temp = o.scope.freeVariable();
        obj = temp;
        meth = ("(" + temp + " = " + (this.variable.source) + ")" + (this.variable.last));
      }
      return "" + (this.prefix()) + (meth) + ".apply(" + obj + ", " + (this.compileSplatArguments(o)) + ")";
    };
    return CallNode;
  })();
  //### ExtendsNode
  // Node to extend an object's prototype with an ancestor object.
  // After `goog.inherits` from the
  // [Closure Library](http://closure-library.googlecode.com/svn/docs/closureGoogBase.js.html).
  exports.ExtendsNode = (function() {
    ExtendsNode = function(child, parent) {
      this.child = child;
      this.parent = parent;
      return this;
    };
    __extends(ExtendsNode, BaseNode);
    ExtendsNode.prototype['class'] = 'ExtendsNode';
    ExtendsNode.prototype.children = ['child', 'parent'];
    // Hooks one constructor into another's prototype chain.
    ExtendsNode.prototype.compileNode = function(o) {
      var ref;
      ref = new ValueNode(literal(utility('extends')));
      return (new CallNode(ref, [this.child, this.parent])).compile(o);
    };
    return ExtendsNode;
  })();
  //### AccessorNode
  // A `.` accessor into a property of a value, or the `::` shorthand for
  // an accessor into the object's prototype.
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
  //### IndexNode
  // A `[ ... ]` indexed accessor into an array or object.
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
  //### RangeNode
  // A range literal. Ranges can be used to extract portions (slices) of arrays,
  // to specify a range for comprehensions, or as a value, to be expanded into the
  // corresponding array of integers at runtime.
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
    // Compiles the range's source variables -- where it starts and where it ends.
    // But only if they need to be cached to avoid double evaluation.
    RangeNode.prototype.compileVariables = function(o) {
      var _b, _c, parts;
      _b = this.from.compileReference(o, true);
      this.from = _b[0];
      this.fromVar = _b[1];
      _c = this.to.compileReference(o, true);
      this.to = _c[0];
      this.toVar = _c[1];
      parts = [];
      if (this.from !== this.fromVar) {
        parts.push(this.from.compile(o));
      }
      if (this.to !== this.toVar) {
        parts.push(this.to.compile(o));
      }
      if (parts.length) {
        return "" + (parts.join('; ')) + ";\n" + o.indent;
      } else {
        return '';
      }
    };
    // When compiled normally, the range returns the contents of the *for loop*
    // needed to iterate over the values in the range. Used by comprehensions.
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
    // When used as a value, expand the range into the equivalent array.
    RangeNode.prototype.compileArray = function(o) {
      var body, clause, equals, from, idt, post, pre, to, vars;
      idt = this.idt(1);
      vars = this.compileVariables(merge(o, {
        indent: idt
      }));
      equals = this.exclusive ? '' : '=';
      from = this.fromVar.compile(o);
      to = this.toVar.compile(o);
      clause = ("" + from + " <= " + to + " ?");
      pre = ("\n" + (idt) + "a = [];" + (vars));
      body = ("var i = " + from + "; (" + clause + " i <" + equals + " " + to + " : i >" + equals + " " + to + "); (" + clause + " i += 1 : i -= 1)");
      post = ("a.push(i);\n" + (idt) + "return a;\n" + o.indent);
      return "(function(){" + (pre) + "for (" + body + ") " + post + "}).call(this)";
    };
    return RangeNode;
  })();
  //### SliceNode
  // An array slice literal. Unlike JavaScript's `Array#slice`, the second parameter
  // specifies the index of the end of the slice, just as the first parameter
  // is the index of the beginning.
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
  //### ObjectNode
  // An object literal, nothing fancy.
  exports.ObjectNode = (function() {
    ObjectNode = function(props) {
      this.objects = (this.properties = props || []);
      return this;
    };
    __extends(ObjectNode, BaseNode);
    ObjectNode.prototype['class'] = 'ObjectNode';
    ObjectNode.prototype.children = ['properties'];
    // All the mucking about with commas is to make sure that CommentNodes and
    // AssignNodes get interleaved correctly, with no trailing commas or
    // commas affixed to comments.
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
  //### ArrayNode
  // An array literal.
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
          objects.push(("\n" + code + "\n" + o.indent));
        } else if (i === this.objects.length - 1) {
          objects.push(code);
        } else {
          objects.push(("" + code + ", "));
        }
      }
      objects = objects.join('');
      if (indexOf(objects, '\n') >= 0) {
        return "[\n" + (this.idt(1)) + objects + "\n" + this.tab + "]";
      } else {
        return "[" + objects + "]";
      }
    };
    return ArrayNode;
  })();
  //### ClassNode
  // The CoffeeScript class definition.
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
    // Initialize a **ClassNode** with its name, an optional superclass, and a
    // list of prototype property assignments.
    ClassNode.prototype.makeReturn = function() {
      this.returns = true;
      return this;
    };
    // Instead of generating the JavaScript string directly, we build up the
    // equivalent syntax tree and compile that, in pieces. You can see the
    // constructor, property assignments, and inheritance getting built out below.
    ClassNode.prototype.compileNode = function(o) {
      var _b, _c, _d, _e, access, applied, construct, extension, func, prop, props, pvar, returns, val;
      extension = this.parent && new ExtendsNode(this.variable, this.parent);
      props = new Expressions();
      o.top = true;
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
          func.name = this.variable.compile(o);
          func.body.push(new ReturnNode(literal('this')));
          this.variable = new ValueNode(this.variable);
          this.variable.namespaced = include(func.name, '.');
          constructor = func;
          continue;
        }
        if (func instanceof CodeNode && func.bound) {
          if (constructor.body.empty()) {
            constructor.body.push(new ReturnNode(literal('this')));
          }
          constructor.body.unshift(new AssignNode(new ValueNode(literal('this'), [new AccessorNode(pvar)]), func));
        } else {
          if (pvar) {
            access = prop.context === 'this' ? pvar.base.properties[0] : new AccessorNode(pvar, 'prototype');
            val = new ValueNode(this.variable, [access]);
            prop = new AssignNode(val, func);
          }
          props.push(prop);
        }
      }
      construct = this.idt() + (new AssignNode(this.variable, constructor)).compile(o) + ';\n';
      props = props.empty() ? '' : props.compile(o) + '\n';
      extension = extension ? this.idt() + extension.compile(o) + ';\n' : '';
      returns = this.returns ? new ReturnNode(this.variable).compile(o) : '';
      return "" + construct + extension + props + returns;
    };
    return ClassNode;
  })();
  //### AssignNode
  // The **AssignNode** is used to assign a local variable to value, or to set the
  // property of an object -- including within object literals.
  exports.AssignNode = (function() {
    AssignNode = function(variable, value, context) {
      this.variable = variable;
      this.value = value;
      this.context = context;
      return this;
    };
    __extends(AssignNode, BaseNode);
    // Matchers for detecting prototype assignments.
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
    // Compile an assignment, delegating to `compilePatternMatch` or
    // `compileSplice` if appropriate. Keep track of the name of the base object
    // we've been assigned to, for correct internal references. If the variable
    // has not been seen yet within the current scope, declare it.
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
      if (top) {
        return val;
      } else {
        return "(" + val + ")";
      }
    };
    // Brief implementation of recursive pattern matching, when assigning array or
    // object literals to a value. Peeks at their properties to assign inner names.
    // See the [ECMAScript Harmony Wiki](http://wiki.ecmascript.org/doku.php?id=harmony:destructuring)
    // for details.
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
        // A regular array pattern-match.
        idx = i;
        if (this.variable.isObject()) {
          if (obj instanceof AssignNode) {
            // A regular object pattern-match.
            _d = [obj.value, obj.variable.base];
            obj = _d[0];
            idx = _d[1];
          } else {
            // A shorthand `{a, b, c}: val` pattern-match.
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
    // Compile the assignment from an array splice literal, using JavaScript's
    // `Array#splice` method.
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
  //### CodeNode
  // A function definition. This is the only node that creates a new Scope.
  // When for the purposes of walking the contents of a function body, the CodeNode
  // has no *children* -- they're within the inner scope.
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
    // Compilation creates a new scope unless explicitly asked to share with the
    // outer scope. Handles splat parameters in the parameter list by peeking at
    // the JavaScript `arguments` objects. If the function is bound with the `=>`
    // arrow, generates a wrapper that saves the current value of `this` through
    // a closure.
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
        } else if ((typeof splat !== "undefined" && splat !== null)) {
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
    // Short-circuit traverseChildren method to prevent it from crossing scope boundaries
    // unless crossScope is true
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
  //### SplatNode
  // A splat, either as a parameter to a function, an argument to a call,
  // or as part of a destructuring assignment.
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
      if ((typeof (_b = this.index) !== "undefined" && _b !== null)) {
        return this.compileParam(o);
      } else {
        return this.name.compile(o);
      }
    };
    // Compiling a parameter splat means recovering the parameters that succeed
    // the splat in the parameter list, by slicing the arguments object.
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
    // A compiling a splat as a destructuring assignment means slicing arguments
    // from the right-hand-side's corresponding array.
    SplatNode.prototype.compileValue = function(o, name, index, trailings) {
      var trail;
      trail = trailings ? (", " + (name) + ".length - " + trailings) : '';
      return "" + (utility('slice')) + ".call(" + name + ", " + index + trail + ")";
    };
    // Utility function that converts arbitrary number of elements, mixed with
    // splats, to a proper array
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
  //### WhileNode
  // A while loop, the only sort of low-level loop exposed by CoffeeScript. From
  // it, all other loops can be manufactured. Useful in cases where you need more
  // flexibility or more speed than a comprehension can provide.
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
    // The main difference from a JavaScript *while* is that the CoffeeScript
    // *while* can be used as a part of a larger expression -- while loops may
    // return an array containing the computed result of each iteration.
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
  //### OpNode
  // Simple Arithmetic and logical operations. Performs some conversion from
  // CoffeeScript operations into their JavaScript equivalents.
  exports.OpNode = (function() {
    OpNode = function(operator, first, second, flip) {
      this.first = first;
      this.second = second;
      this.operator = this.CONVERSIONS[operator] || operator;
      this.flip = !!flip;
      return this;
    };
    __extends(OpNode, BaseNode);
    // The map of conversions from CoffeeScript to JavaScript symbols.
    OpNode.prototype.CONVERSIONS = {
      '==': '===',
      '!=': '!=='
    };
    // The list of operators for which we perform
    // [Python-style comparison chaining](http://docs.python.org/reference/expressions.html#notin).
    OpNode.prototype.CHAINABLE = ['<', '>', '>=', '<=', '===', '!=='];
    // Our assignment operators that have no JavaScript equivalent.
    OpNode.prototype.ASSIGNMENT = ['||=', '&&=', '?='];
    // Operators must come before their operands with a space.
    OpNode.prototype.PREFIX_OPERATORS = ['typeof', 'delete'];
    OpNode.prototype['class'] = 'OpNode';
    OpNode.prototype.children = ['first', 'second'];
    OpNode.prototype.isUnary = function() {
      return !this.second;
    };
    OpNode.prototype.isChainable = function() {
      return indexOf(this.CHAINABLE, this.operator) >= 0;
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
    // Mimic Python's chained comparisons when multiple comparison operators are
    // used sequentially. For example:
    //     bin/coffee -e "puts 50 < 65 > 10"
    //     true
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
    // When compiling a conditional assignment, take care to ensure that the
    // operands are only evaluated once, even though we have to reference them
    // more than once.
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
    // If this is an existence operator, we delegate to `ExistenceNode.compileTest`
    // to give us the safe references for the variables.
    OpNode.prototype.compileExistence = function(o) {
      var _b, first, second, test;
      _b = [this.first.compile(o), this.second.compile(o)];
      first = _b[0];
      second = _b[1];
      test = ExistenceNode.compileTest(o, this.first);
      return "" + test + " ? " + first + " : " + second;
    };
    // Compile a unary **OpNode**.
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
  //### TryNode
  // A classic *try/catch/finally* block.
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
    // Compilation is more or less as you would expect -- the *finally* clause
    // is optional, the *catch* is not.
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
  //### ThrowNode
  // Simple node to throw an exception.
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
    // A **ThrowNode** is already a return, of sorts...
    ThrowNode.prototype.makeReturn = function() {
      return this;
    };
    ThrowNode.prototype.compileNode = function(o) {
      return "" + (this.tab) + "throw " + (this.expression.compile(o)) + ";";
    };
    return ThrowNode;
  })();
  //### ExistenceNode
  // Checks a variable for existence -- not *null* and not *undefined*. This is
  // similar to `.nil?` in Ruby, and avoids having to consult a JavaScript truth
  // table.
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
    // The meat of the **ExistenceNode** is in this static `compileTest` method
    // because other nodes like to check the existence of their variables as well.
    // Be careful not to double-evaluate anything.
    ExistenceNode.compileTest = function(o, variable) {
      var _b, first, second;
      _b = variable.compileReference(o, true);
      first = _b[0];
      second = _b[1];
      return "(typeof " + (first.compile(o)) + " !== \"undefined\" && " + (second.compile(o)) + " !== null)";
    };
    return ExistenceNode;
  }).call(this);
  //### ParentheticalNode
  // An extra set of parentheses, specified explicitly in the source. At one time
  // we tried to clean up the results by detecting and removing redundant
  // parentheses, but no longer -- you can put in as many as you please.
  // Parentheses are a good way to force any statement to become an expression.
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
    ParentheticalNode.prototype.compileNode = function(o) {
      var code, l;
      code = this.expression.compile(o);
      if (this.isStatement()) {
        return code;
      }
      l = code.length;
      if (code.substr(l - 1, 1) === ';') {
        code = code.substr(o, l - 1);
      }
      if (this.expression instanceof AssignNode) {
        return code;
      } else {
        return "(" + code + ")";
      }
    };
    return ParentheticalNode;
  })();
  //### ForNode
  // CoffeeScript's replacement for the *for* loop is our array and object
  // comprehensions, that compile into *for* loops here. They also act as an
  // expression, able to return the result of each filtered iteration.
  // Unlike Python array comprehensions, they can be multi-line, and you can pass
  // the current index of the loop as a second parameter. Unlike Ruby blocks,
  // you can map and filter in a single pass.
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
    // Welcome to the hairiest method in all of CoffeeScript. Handles the inner
    // loop, filtering, stepping, and result saving for array, object, and range
    // comprehensions. Some of the generated code can be shared in common, and
    // some cannot.
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
        forPart = source.compile(merge(o, {
          index: ivar,
          step: this.step
        }));
      } else {
        svar = scope.freeVariable();
        sourcePart = ("" + svar + " = " + (this.source.compile(o)) + ";");
        if (this.pattern) {
          namePart = new AssignNode(this.name, literal(("" + svar + "[" + ivar + "]"))).compile(merge(o, {
            indent: this.idt(1),
            top: true
          })) + "\n";
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
          body.unshift(literal(("var " + namePart)));
        }
        if (index) {
          body.unshift(literal(("var " + index + " = " + ivar)));
        }
        body = ClosureNode.wrap(body, true);
      } else {
        if (namePart) {
          varPart = ("" + (this.idt(1)) + namePart + ";\n");
        }
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
  //### IfNode
  // *If/else* statements. Our *switch/when* will be compiled into this. Acts as an
  // expression by pushing down requested returns to the last line of each clause.
  // Single-expression **IfNodes** are compiled into ternary operators if possible,
  // because ternaries are already proper expressions, and don't need conversion.
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
    // Tag a chain of **IfNodes** with their object(s) to switch on for equality
    // tests. `rewriteSwitch` will perform the actual change at compile time.
    IfNode.prototype.switchesOver = function(expression) {
      this.switchSubject = expression;
      return this;
    };
    // Rewrite a chain of **IfNodes** with their switch condition for equality.
    // Ensure that the switch expression isn't evaluated more than once.
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
      // prevent this rewrite from happening again
      this.switchSubject = undefined;
      return this;
    };
    // Rewrite a chain of **IfNodes** to add a default case as the final *else*.
    IfNode.prototype.addElse = function(elseBody, statement) {
      if (this.isChain) {
        this.elseBodyNode().addElse(elseBody, statement);
      } else {
        this.isChain = elseBody instanceof IfNode;
        this.elseBody = this.ensureExpressions(elseBody);
      }
      return this;
    };
    // The **IfNode** only compiles into a statement if either of its bodies needs
    // to be a statement. Otherwise a ternary is safe.
    IfNode.prototype.isStatement = function() {
      return this.statement = this.statement || !!(this.comment || this.tags.statement || this.bodyNode().isStatement() || (this.elseBody && this.elseBodyNode().isStatement()));
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
      if (this.isStatement()) {
        return this.compileStatement(o);
      } else {
        return this.compileTernary(o);
      }
    };
    IfNode.prototype.makeReturn = function() {
      this.body = this.body && this.ensureExpressions(this.body.makeReturn());
      this.elseBody = this.elseBody && this.ensureExpressions(this.elseBody.makeReturn());
      return this;
    };
    IfNode.prototype.ensureExpressions = function(node) {
      if (node instanceof Expressions) {
        return node;
      } else {
        return new Expressions([node]);
      }
    };
    // Compile the **IfNode** as a regular *if-else* statement. Flattened chains
    // force inner *else* bodies into statement form.
    IfNode.prototype.compileStatement = function(o) {
      var body, child, comDent, condO, elsePart, ifDent, ifPart, prefix;
      if (this.switchSubject) {
        this.rewriteSwitch(o);
      }
      child = del(o, 'chainChild');
      condO = merge(o);
      o.indent = this.idt(1);
      o.top = true;
      ifDent = child ? '' : this.idt();
      comDent = child ? this.idt() : '';
      prefix = this.comment ? ("" + (this.comment.compile(condO)) + "\n" + comDent) : '';
      body = this.body.compile(o);
      ifPart = ("" + prefix + (ifDent) + "if (" + (this.compileCondition(condO)) + ") {\n" + body + "\n" + this.tab + "}");
      if (!(this.elseBody)) {
        return ifPart;
      }
      elsePart = this.isChain ? ' else ' + this.elseBodyNode().compile(merge(o, {
        indent: this.idt(),
        chainChild: true
      })) : (" else {\n" + (this.elseBody.compile(o)) + "\n" + this.tab + "}");
      return "" + ifPart + elsePart;
    };
    // Compile the IfNode as a ternary operator.
    IfNode.prototype.compileTernary = function(o) {
      var elsePart, ifPart;
      ifPart = this.condition.compile(o) + ' ? ' + this.bodyNode().compile(o);
      elsePart = this.elseBody ? this.elseBodyNode().compile(o) : 'null';
      return "" + ifPart + " : " + elsePart;
    };
    return IfNode;
  })();
  // Faux-Nodes
  // ----------
  //### PushNode
  // Faux-nodes are never created by the grammar, but are used during code
  // generation to generate other combinations of nodes. The **PushNode** creates
  // the tree for `array.push(value)`, which is helpful for recording the result
  // arrays from comprehensions.
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
  //### ClosureNode
  // A faux-node used to wrap an expressions body in a closure.
  ClosureNode = (exports.ClosureNode = {
    // Wrap the expressions body, unless it contains a pure statement,
    // in which case, no dice. If the body mentions `this` or `arguments`,
    // then make sure that the closure wrapper preserves the original values.
    wrap: function(expressions, statement) {
      var args, call, func, mentionsArgs, mentionsThis, meth;
      if (expressions.containsPureStatement()) {
        return expressions;
      }
      func = new ParentheticalNode(new CodeNode([], Expressions.wrap([expressions])));
      args = [];
      mentionsArgs = expressions.contains(function(n) {
        return (n instanceof LiteralNode) && (n.value === 'arguments');
      });
      mentionsThis = expressions.contains(function(n) {
        return (n instanceof LiteralNode) && (n.value === 'this');
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
      if (statement) {
        return Expressions.wrap([call]);
      } else {
        return call;
      }
    }
  });
  // Utility Functions
  // -----------------
  UTILITIES = {
    // Correctly set up a prototype chain for inheritance, including a reference
    // to the superclass for `super()` calls. See:
    // [goog.inherits](http://closure-library.googlecode.com/svn/docs/closureGoogBase.js.source.html#line1206).
    __extends: "function(child, parent) {\n    var ctor = function(){ };\n    ctor.prototype = parent.prototype;\n    child.__superClass__ = parent.prototype;\n    child.prototype = new ctor();\n    child.prototype.constructor = child;\n  }",
    // Shortcuts to speed up the lookup time for native functions.
    __hasProp: 'Object.prototype.hasOwnProperty',
    __slice: 'Array.prototype.slice'
  };
  // Constants
  // ---------
  // Tabs are two spaces for pretty printing.
  TAB = '  ';
  // Trim out all trailing whitespace, so that the generated code plays nice
  // with Git.
  TRAILING_WHITESPACE = /[ \t]+$/gm;
  // Keep these identifier regexes in sync with the Lexer.
  IDENTIFIER = /^[a-zA-Z\$_](\w|\$)*$/;
  NUMBER = /^(((\b0(x|X)[0-9a-fA-F]+)|((\b[0-9]+(\.[0-9]+)?|\.[0-9]+)(e[+\-]?[0-9]+)?)))\b$/i;
  // Is a literal value a string?
  IS_STRING = /^['"]/;
  // Utility Functions
  // -----------------
  // Handy helper for a generating LiteralNode.
  literal = function(name) {
    return new LiteralNode(name);
  };
  // Helper for ensuring that utility functions are assigned at the top level.
  utility = function(name) {
    var ref;
    ref = ("__" + name);
    Scope.root.assign(ref, UTILITIES[ref]);
    return ref;
  };
})();
