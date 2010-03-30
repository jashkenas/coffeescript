(function(){
  var AccessorNode, ArrayNode, AssignNode, BaseNode, CallNode, ClassNode, ClosureNode, CodeNode, CommentNode, CurryNode, ExistenceNode, Expressions, ExtendsNode, ForNode, IDENTIFIER, IfNode, IndexNode, LiteralNode, ObjectNode, OpNode, ParentheticalNode, PushNode, RangeNode, ReturnNode, Scope, SliceNode, SplatNode, TAB, TRAILING_WHITESPACE, ThrowNode, TryNode, ValueNode, WhileNode, compact, del, flatten, helpers, literal, merge, statement;
  var __extend = function(child, parent) {
    var ctor = function(){ };
    ctor.prototype = parent.prototype;
    child.__superClass__ = parent.prototype;
    child.prototype = new ctor();
    child.prototype.constructor = child;
  }, __range = function(array, from, to, exclusive) {
    return [
      (from < 0 ? from + array.length : from || 0),
      (to < 0 ? to + array.length : to || array.length) + (exclusive ? 0 : 1)
    ];
  }, __bind = function(func, obj, args) {
    return function() {
      return func.apply(obj || {}, args ? args.concat(__slice.call(arguments, 0)) : arguments);
    };
  }, __slice = Array.prototype.slice;
  // `nodes.coffee` contains all of the node classes for the syntax tree. Most
  // nodes are created as the result of actions in the [grammar](grammar.html),
  // but some are created by other nodes as a method of code generation. To convert
  // the syntax tree into a string of JavaScript code, call `compile()` on the root.
  // Set up for both **Node.js** and the browser, by
  // including the [Scope](scope.html) class.
  if ((typeof process !== "undefined" && process !== null)) {
    Scope = require('./scope').Scope;
    helpers = require('./helpers').helpers;
  } else {
    this.exports = this;
    helpers = this.helpers;
    Scope = this.Scope;
  }
  // Import the helpers we need.
  compact = helpers.compact;
  flatten = helpers.flatten;
  merge = helpers.merge;
  del = helpers.del;
  // Helper function that marks a node as a JavaScript *statement*, or as a
  // *pure_statement*. Statements must be wrapped in a closure when used as an
  // expression, and nodes tagged as *pure_statement* cannot be closure-wrapped
  // without losing their meaning.
  statement = function statement(klass, only) {
    klass.prototype.is_statement = function is_statement() {
      return true;
    };
    if (only) {
      klass.prototype.is_pure_statement = function is_pure_statement() {
        return true;
      };
      return klass.prototype.is_pure_statement;
    }
  };
  //### BaseNode
  // The **BaseNode** is the abstract base class for all nodes in the syntax tree.
  // Each subclass implements the `compile_node` method, which performs the
  // code generation for that node. To compile a node to JavaScript,
  // call `compile` on it, which wraps `compile_node` in some generic extra smarts,
  // to know when the generated code needs to be wrapped up in a closure.
  // An options hash is passed and cloned throughout, containing information about
  // the environment from higher in the tree (such as if a returned value is
  // being requested by the surrounding function), information about the current
  // scope, and indentation level.
  exports.BaseNode = (function() {
    BaseNode = function BaseNode() {    };
    // Common logic for determining whether to wrap this node in a closure before
    // compiling it, or to compile directly. We need to wrap if this node is a
    // *statement*, and it's not a *pure_statement*, and we're not at
    // the top level of a block (which would be unnecessary), and we haven't
    // already been asked to return the result (because statements know how to
    // return results).
    // If a Node is *top_sensitive*, that means that it needs to compile differently
    // depending on whether it's being used as part of a larger expression, or is a
    // top-level statement within the function body.
    BaseNode.prototype.compile = function compile(o) {
      var closure, top;
      this.options = merge(o || {});
      this.tab = o.indent;
      if (!(this instanceof ValueNode)) {
        del(this.options, 'operation');
      }
      top = this.top_sensitive() ? this.options.top : del(this.options, 'top');
      closure = this.is_statement() && !this.is_pure_statement() && !top && !this.options.as_statement && !(this instanceof CommentNode) && !this.contains_pure_statement();
      if (closure) {
        return this.compile_closure(this.options);
      } else {
        return this.compile_node(this.options);
      }
    };
    // Statements converted into expressions via closure-wrapping share a scope
    // object with their parent closure, to preserve the expected lexical scope.
    BaseNode.prototype.compile_closure = function compile_closure(o) {
      this.tab = o.indent;
      o.shared_scope = o.scope;
      return ClosureNode.wrap(this).compile(o);
    };
    // If the code generation wishes to use the result of a complex expression
    // in multiple places, ensure that the expression is only ever evaluated once,
    // by assigning it to a temporary variable.
    BaseNode.prototype.compile_reference = function compile_reference(o) {
      var compiled, reference;
      reference = literal(o.scope.free_variable());
      compiled = new AssignNode(reference, this);
      return [compiled, reference];
    };
    // Convenience method to grab the current indentation level, plus tabbing in.
    BaseNode.prototype.idt = function idt(tabs) {
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
    BaseNode.prototype.make_return = function make_return() {
      return new ReturnNode(this);
    };
    // Does this node, or any of its children, contain a node of a certain kind?
    // Recursively traverses down the *children* of the nodes, yielding to a block
    // and returning true when the block finds a match. `contains` does not cross
    // scope boundaries.
    BaseNode.prototype.contains = function contains(block) {
      var _a, _b, _c, node;
      _b = this.children;
      for (_a = 0, _c = _b.length; _a < _c; _a++) {
        node = _b[_a];
        if (block(node)) {
          return true;
        }
        if (node.contains && node.contains(block)) {
          return true;
        }
      }
      return false;
    };
    // Convenience for the most common use of contains. Does the node contain
    // a pure statement?
    BaseNode.prototype.contains_pure_statement = function contains_pure_statement() {
      return this.is_pure_statement() || this.contains(function(n) {
        return n.is_pure_statement();
      });
    };
    // Perform an in-order traversal of the AST. Crosses scope boundaries.
    BaseNode.prototype.traverse = function traverse(block) {
      var _a, _b, _c, _d, node;
      _a = []; _c = this.children;
      for (_b = 0, _d = _c.length; _b < _d; _b++) {
        node = _c[_b];
        _a.push((function() {
          block(node);
          if (node.traverse) {
            return node.traverse(block);
          }
        }).call(this));
      }
      return _a;
    };
    // `toString` representation of the node, for inspecting the parse tree.
    // This is what `coffee --nodes` prints out.
    BaseNode.prototype.toString = function toString(idt) {
      var _a, _b, _c, _d, child;
      idt = idt || '';
      return '\n' + idt + this.type + (function() {
        _a = []; _c = this.children;
        for (_b = 0, _d = _c.length; _b < _d; _b++) {
          child = _c[_b];
          _a.push(child.toString(idt + TAB));
        }
        return _a;
      }).call(this).join('');
    };
    // Default implementations of the common node identification methods. Nodes
    // will override these with custom logic, if needed.
    BaseNode.prototype.unwrap = function unwrap() {
      return this;
    };
    BaseNode.prototype.children = [];
    BaseNode.prototype.is_statement = function is_statement() {
      return false;
    };
    BaseNode.prototype.is_pure_statement = function is_pure_statement() {
      return false;
    };
    BaseNode.prototype.top_sensitive = function top_sensitive() {
      return false;
    };
    return BaseNode;
  }).call(this);
  //### Expressions
  // The expressions body is the list of expressions that forms the body of an
  // indented block of code -- the implementation of a function, a clause in an
  // `if`, `switch`, or `try`, and so on...
  exports.Expressions = (function() {
    Expressions = function Expressions(nodes) {
      this.children = (this.expressions = compact(flatten(nodes || [])));
      return this;
    };
    __extend(Expressions, BaseNode);
    Expressions.prototype.type = 'Expressions';
    // Tack an expression on to the end of this expression list.
    Expressions.prototype.push = function push(node) {
      this.expressions.push(node);
      return this;
    };
    // Add an expression at the beginning of this expression list.
    Expressions.prototype.unshift = function unshift(node) {
      this.expressions.unshift(node);
      return this;
    };
    // If this Expressions consists of just a single node, unwrap it by pulling
    // it back out.
    Expressions.prototype.unwrap = function unwrap() {
      if (this.expressions.length === 1) {
        return this.expressions[0];
      } else {
        return this;
      }
    };
    // Is this an empty block of code?
    Expressions.prototype.empty = function empty() {
      return this.expressions.length === 0;
    };
    // Make a copy of this node.
    Expressions.prototype.copy = function copy() {
      return new Expressions(this.children.slice());
    };
    // An Expressions node does not return its entire body, rather it
    // ensures that the final expression is returned.
    Expressions.prototype.make_return = function make_return() {
      var idx, last;
      idx = this.expressions.length - 1;
      last = this.expressions[idx];
      if (last instanceof CommentNode) {
        last = this.expressions[idx -= 1];
      }
      if (!last || last instanceof ReturnNode) {
        return this;
      }
      if (!(last.contains_pure_statement())) {
        this.expressions[idx] = last.make_return();
      }
      return this;
    };
    // An **Expressions** is the only node that can serve as the root.
    Expressions.prototype.compile = function compile(o) {
      o = o || {};
      if (o.scope) {
        return Expressions.__superClass__.compile.call(this, o);
      } else {
        return this.compile_root(o);
      }
    };
    Expressions.prototype.compile_node = function compile_node(o) {
      var _a, _b, _c, _d, node;
      return (function() {
        _a = []; _c = this.expressions;
        for (_b = 0, _d = _c.length; _b < _d; _b++) {
          node = _c[_b];
          _a.push(this.compile_expression(node, merge(o)));
        }
        return _a;
      }).call(this).join("\n");
    };
    // If we happen to be the top-level **Expressions**, wrap everything in
    // a safety closure, unless requested not to.
    Expressions.prototype.compile_root = function compile_root(o) {
      var code;
      o.indent = (this.tab = o.no_wrap ? '' : TAB);
      o.scope = new Scope(null, this, null);
      code = o.globals ? this.compile_node(o) : this.compile_with_declarations(o);
      code = code.replace(TRAILING_WHITESPACE, '');
      if (o.no_wrap) {
        return code;
      } else {
        return "(function(){\n" + code + "\n})();\n";
      }
    };
    // Compile the expressions body for the contents of a function, with
    // declarations of all inner variables pushed up to the top.
    Expressions.prototype.compile_with_declarations = function compile_with_declarations(o) {
      var code;
      code = this.compile_node(o);
      if (o.scope.has_assignments(this)) {
        code = "" + (this.tab) + "var " + (o.scope.compiled_assignments(this.tab)) + ";\n" + code;
      }
      if (o.scope.has_declarations(this)) {
        code = "" + (this.tab) + "var " + (o.scope.compiled_declarations()) + ";\n" + code;
      }
      return code;
    };
    // Compiles a single expression within the expressions body. If we need to
    // return the result, and it's an expression, simply return it. If it's a
    // statement, ask the statement to do so.
    Expressions.prototype.compile_expression = function compile_expression(node, o) {
      var compiled_node;
      this.tab = o.indent;
      compiled_node = node.compile(merge(o, {
        top: true
      }));
      if (node.is_statement()) {
        return compiled_node;
      } else {
        return "" + (this.idt()) + compiled_node + ";";
      }
    };
    return Expressions;
  }).call(this);
  // Wrap up the given nodes as an **Expressions**, unless it already happens
  // to be one.
  Expressions.wrap = function wrap(nodes) {
    if (nodes.length === 1 && nodes[0] instanceof Expressions) {
      return nodes[0];
    }
    return new Expressions(nodes);
  };
  statement(Expressions);
  //### LiteralNode
  // Literals are static values that can be passed through directly into
  // JavaScript without translation, such as: strings, numbers,
  // `true`, `false`, `null`...
  exports.LiteralNode = (function() {
    LiteralNode = function LiteralNode(value) {
      this.value = value;
      return this;
    };
    __extend(LiteralNode, BaseNode);
    LiteralNode.prototype.type = 'Literal';
    // Break and continue must be treated as pure statements -- they lose their
    // meaning when wrapped in a closure.
    LiteralNode.prototype.is_statement = function is_statement() {
      return this.value === 'break' || this.value === 'continue';
    };
    LiteralNode.prototype.is_pure_statement = LiteralNode.prototype.is_statement;
    LiteralNode.prototype.compile_node = function compile_node(o) {
      var end, idt;
      idt = this.is_statement() ? this.idt() : '';
      end = this.is_statement() ? ';' : '';
      return "" + idt + this.value + end;
    };
    LiteralNode.prototype.toString = function toString(idt) {
      return " \"" + this.value + "\"";
    };
    return LiteralNode;
  }).call(this);
  //### ReturnNode
  // A `return` is a *pure_statement* -- wrapping it in a closure wouldn't
  // make sense.
  exports.ReturnNode = (function() {
    ReturnNode = function ReturnNode(expression) {
      this.children = [(this.expression = expression)];
      return this;
    };
    __extend(ReturnNode, BaseNode);
    ReturnNode.prototype.type = 'Return';
    ReturnNode.prototype.top_sensitive = function top_sensitive() {
      return true;
    };
    ReturnNode.prototype.compile_node = function compile_node(o) {
      var expr;
      expr = this.expression.make_return();
      if (!(expr instanceof ReturnNode)) {
        return expr.compile(o);
      }
      del(o, 'top');
      if (this.expression.is_statement()) {
        o.as_statement = true;
      }
      return "" + (this.tab) + "return " + (this.expression.compile(o)) + ";";
    };
    return ReturnNode;
  }).call(this);
  statement(ReturnNode, true);
  //### ValueNode
  // A value, variable or literal or parenthesized, indexed or dotted into,
  // or vanilla.
  exports.ValueNode = (function() {
    ValueNode = function ValueNode(base, properties) {
      this.children = flatten([(this.base = base), (this.properties = (properties || []))]);
      return this;
    };
    __extend(ValueNode, BaseNode);
    ValueNode.prototype.type = 'Value';
    ValueNode.prototype.SOAK = " == undefined ? undefined : ";
    // A **ValueNode** has a base and a list of property accesses.
    // Add a property access to the list.
    ValueNode.prototype.push = function push(prop) {
      this.properties.push(prop);
      this.children.push(prop);
      return this;
    };
    ValueNode.prototype.has_properties = function has_properties() {
      return !!this.properties.length;
    };
    // Some boolean checks for the benefit of other nodes.
    ValueNode.prototype.is_array = function is_array() {
      return this.base instanceof ArrayNode && !this.has_properties();
    };
    ValueNode.prototype.is_object = function is_object() {
      return this.base instanceof ObjectNode && !this.has_properties();
    };
    ValueNode.prototype.is_splice = function is_splice() {
      return this.has_properties() && this.properties[this.properties.length - 1] instanceof SliceNode;
    };
    ValueNode.prototype.make_return = function make_return() {
      if (this.has_properties()) {
        return ValueNode.__superClass__.make_return.call(this);
      } else {
        return this.base.make_return();
      }
    };
    // The value can be unwrapped as its inner node, if there are no attached
    // properties.
    ValueNode.prototype.unwrap = function unwrap() {
      if (this.properties.length) {
        return this;
      } else {
        return this.base;
      }
    };
    // Values are considered to be statements if their base is a statement.
    ValueNode.prototype.is_statement = function is_statement() {
      return this.base.is_statement && this.base.is_statement() && !this.has_properties();
    };
    // We compile a value to JavaScript by compiling and joining each property.
    // Things get much more insteresting if the chain of properties has *soak*
    // operators `?.` interspersed. Then we have to take care not to accidentally
    // evaluate a anything twice when building the soak chain.
    ValueNode.prototype.compile_node = function compile_node(o) {
      var _a, _b, _c, baseline, complete, only, op, part, prop, props, replace, soaked, splice, temp;
      soaked = false;
      only = del(o, 'only_first');
      op = del(o, 'operation');
      splice = del(o, 'splice');
      replace = del(o, 'replace');
      props = only ? this.properties.slice.apply(this.properties, __range(this.properties, 0, this.properties.length - 1, true)) : this.properties;
      baseline = this.base.compile(o);
      if (this.base instanceof ObjectNode && this.has_properties()) {
        baseline = "(" + baseline + ")";
      }
      complete = (this.last = baseline);
      _b = props;
      for (_a = 0, _c = _b.length; _a < _c; _a++) {
        prop = _b[_a];
        this.source = baseline;
        if (prop.soak_node) {
          soaked = true;
          if (this.base instanceof CallNode && prop === props[0]) {
            temp = o.scope.free_variable();
            complete = "(" + temp + " = " + complete + ")" + this.SOAK + (baseline = temp + prop.compile(o));
          } else {
            complete = complete + this.SOAK + (baseline += prop.compile(o));
          }
        } else if (prop instanceof SliceNode) {
          o.array = complete;
          if (splice) {
            o.replace = replace;
            part = prop.compile_splice(o);
          } else {
            part = prop.compile_slice(o);
          }
          baseline = part;
          complete = part;
          this.last = part;
        } else {
          part = prop.compile(o);
          baseline += part;
          complete += part;
          this.last = part;
        }
      }
      if (op && soaked) {
        return "(" + complete + ")";
      } else {
        return complete;
      }
    };
    return ValueNode;
  }).call(this);
  //### CommentNode
  // CoffeeScript passes through comments as JavaScript comments at the
  // same position.
  exports.CommentNode = (function() {
    CommentNode = function CommentNode(lines) {
      this.lines = lines;
      this;
      return this;
    };
    __extend(CommentNode, BaseNode);
    CommentNode.prototype.type = 'Comment';
    CommentNode.prototype.make_return = function make_return() {
      return this;
    };
    CommentNode.prototype.compile_node = function compile_node(o) {
      return "" + this.tab + "//" + this.lines.join("\n" + this.tab + "//");
    };
    return CommentNode;
  }).call(this);
  statement(CommentNode);
  //### CallNode
  // Node for a function invocation. Takes care of converting `super()` calls into
  // calls against the prototype's function of the same name.
  exports.CallNode = (function() {
    CallNode = function CallNode(variable, args) {
      this.is_new = false;
      this.is_super = variable === 'super';
      this.variable = this.is_super ? null : variable;
      this.children = compact(flatten([this.variable, (this.args = (args || []))]));
      this.compile_splat_arguments = __bind(SplatNode.compile_mixed_array, this, [this.args]);
      return this;
    };
    __extend(CallNode, BaseNode);
    CallNode.prototype.type = 'Call';
    // Tag this invocation as creating a new instance.
    CallNode.prototype.new_instance = function new_instance() {
      this.is_new = true;
      return this;
    };
    CallNode.prototype.prefix = function prefix() {
      if (this.is_new) {
        return 'new ';
      } else {
        return '';
      }
    };
    // Compile a vanilla function call.
    CallNode.prototype.compile_node = function compile_node(o) {
      var _a, _b, _c, _d, _e, _f, _g, arg, args;
      _b = this.args;
      for (_a = 0, _c = _b.length; _a < _c; _a++) {
        arg = _b[_a];
        if (arg instanceof SplatNode) {
          return this.compile_splat(o);
        }
      }
      args = (function() {
        _d = []; _f = this.args;
        for (_e = 0, _g = _f.length; _e < _g; _e++) {
          arg = _f[_e];
          _d.push(arg.compile(o));
        }
        return _d;
      }).call(this).join(', ');
      if (this.is_super) {
        return this.compile_super(args, o);
      }
      return "" + (this.prefix()) + (this.variable.compile(o)) + "(" + args + ")";
    };
    // `super()` is converted into a call against the superclass's implementation
    // of the current function.
    CallNode.prototype.compile_super = function compile_super(args, o) {
      var meth, methname;
      methname = o.scope.method.name;
      meth = o.scope.method.proto ? "" + (o.scope.method.proto) + ".__superClass__." + methname : "" + (methname) + ".__superClass__.constructor";
      return "" + (meth) + ".call(this" + (args.length ? ', ' : '') + args + ")";
    };
    // If you call a function with a splat, it's converted into a JavaScript
    // `.apply()` call to allow an array of arguments to be passed.
    CallNode.prototype.compile_splat = function compile_splat(o) {
      var meth, obj, temp;
      meth = this.variable.compile(o);
      obj = this.variable.source || 'this';
      if (obj.match(/\(/)) {
        temp = o.scope.free_variable();
        obj = temp;
        meth = "(" + temp + " = " + (this.variable.source) + ")" + (this.variable.last);
      }
      return "" + (this.prefix()) + (meth) + ".apply(" + obj + ", " + (this.compile_splat_arguments(o)) + ")";
    };
    return CallNode;
  }).call(this);
  //### CurryNode
  // Binds a context object and a list of arguments to a function,
  // returning the bound function. After ECMAScript 5, Prototype.js, and
  // Underscore's `bind` functions.
  exports.CurryNode = (function() {
    CurryNode = function CurryNode(meth, args) {
      this.children = flatten([(this.meth = meth), (this.context = args[0]), (this.args = (args.slice(1) || []))]);
      this.compile_splat_arguments = __bind(SplatNode.compile_mixed_array, this, [this.args]);
      return this;
    };
    __extend(CurryNode, CallNode);
    CurryNode.prototype.type = 'Curry';
    CurryNode.prototype.arguments = function arguments(o) {
      var _a, _b, _c, arg;
      _b = this.args;
      for (_a = 0, _c = _b.length; _a < _c; _a++) {
        arg = _b[_a];
        if (arg instanceof SplatNode) {
          return this.compile_splat_arguments(o);
        }
      }
      return (new ArrayNode(this.args)).compile(o);
    };
    CurryNode.prototype.compile_node = function compile_node(o) {
      var ref;
      ref = new ValueNode(literal(o.scope.utility('bind')));
      return (new CallNode(ref, [this.meth, this.context, literal(this.arguments(o))])).compile(o);
    };
    return CurryNode;
  }).call(this);
  //### ExtendsNode
  // Node to extend an object's prototype with an ancestor object.
  // After `goog.inherits` from the
  // [Closure Library](http://closure-library.googlecode.com/svn/docs/closure_goog_base.js.html).
  exports.ExtendsNode = (function() {
    ExtendsNode = function ExtendsNode(child, parent) {
      this.children = [(this.child = child), (this.parent = parent)];
      return this;
    };
    __extend(ExtendsNode, BaseNode);
    ExtendsNode.prototype.type = 'Extends';
    // Hooks one constructor into another's prototype chain.
    ExtendsNode.prototype.compile_node = function compile_node(o) {
      var ref;
      ref = new ValueNode(literal(o.scope.utility('extend')));
      return (new CallNode(ref, [this.child, this.parent])).compile(o);
    };
    return ExtendsNode;
  }).call(this);
  //### AccessorNode
  // A `.` accessor into a property of a value, or the `::` shorthand for
  // an accessor into the object's prototype.
  exports.AccessorNode = (function() {
    AccessorNode = function AccessorNode(name, tag) {
      this.children = [(this.name = name)];
      this.prototype = tag === 'prototype';
      this.soak_node = tag === 'soak';
      this;
      return this;
    };
    __extend(AccessorNode, BaseNode);
    AccessorNode.prototype.type = 'Accessor';
    AccessorNode.prototype.compile_node = function compile_node(o) {
      var proto_part;
      proto_part = this.prototype ? 'prototype.' : '';
      return "." + proto_part + (this.name.compile(o));
    };
    return AccessorNode;
  }).call(this);
  //### IndexNode
  // A `[ ... ]` indexed accessor into an array or object.
  exports.IndexNode = (function() {
    IndexNode = function IndexNode(index, tag) {
      this.children = [(this.index = index)];
      this.soak_node = tag === 'soak';
      return this;
    };
    __extend(IndexNode, BaseNode);
    IndexNode.prototype.type = 'Index';
    IndexNode.prototype.compile_node = function compile_node(o) {
      var idx;
      idx = this.index.compile(o);
      return "[" + idx + "]";
    };
    return IndexNode;
  }).call(this);
  //### RangeNode
  // A range literal. Ranges can be used to extract portions (slices) of arrays,
  // to specify a range for comprehensions, or as a value, to be expanded into the
  // corresponding array of integers at runtime.
  exports.RangeNode = (function() {
    RangeNode = function RangeNode(from, to, exclusive) {
      this.children = [(this.from = from), (this.to = to)];
      this.exclusive = !!exclusive;
      return this;
    };
    __extend(RangeNode, BaseNode);
    RangeNode.prototype.type = 'Range';
    // Compiles the range's source variables -- where it starts and where it ends.
    RangeNode.prototype.compile_variables = function compile_variables(o) {
      var _a, _b, from, to;
      this.tab = o.indent;
      _a = [o.scope.free_variable(), o.scope.free_variable()];
      this.from_var = _a[0];
      this.to_var = _a[1];
      _b = [this.from.compile(o), this.to.compile(o)];
      from = _b[0];
      to = _b[1];
      return "" + this.from_var + " = " + from + "; " + this.to_var + " = " + to + ";\n" + this.tab;
    };
    // When compiled normally, the range returns the contents of the *for loop*
    // needed to iterate over the values in the range. Used by comprehensions.
    RangeNode.prototype.compile_node = function compile_node(o) {
      var compare, equals, idx, incr, intro, step, vars;
      if (!(o.index)) {
        return this.compile_array(o);
      }
      idx = del(o, 'index');
      step = del(o, 'step');
      vars = "" + idx + " = " + this.from_var;
      step = step ? step.compile(o) : '1';
      equals = this.exclusive ? '' : '=';
      intro = "(" + this.from_var + " <= " + this.to_var + " ? " + idx;
      compare = "" + intro + " <" + equals + " " + this.to_var + " : " + idx + " >" + equals + " " + this.to_var + ")";
      incr = "" + intro + " += " + step + " : " + idx + " -= " + step + ")";
      return "" + vars + "; " + compare + "; " + incr;
    };
    // When used as a value, expand the range into the equivalent array. In the
    // future, the code this generates should probably be cleaned up by handwriting
    // it instead of wrapping nodes.
    RangeNode.prototype.compile_array = function compile_array(o) {
      var arr, body, name;
      name = o.scope.free_variable();
      body = Expressions.wrap([literal(name)]);
      arr = Expressions.wrap([new ForNode(body, {
          source: (new ValueNode(this))
        }, literal(name))
      ]);
      return (new ParentheticalNode(new CallNode(new CodeNode([], arr.make_return())))).compile(o);
    };
    return RangeNode;
  }).call(this);
  //### SliceNode
  // An array slice literal. Unlike JavaScript's `Array#slice`, the second parameter
  // specifies the index of the end of the slice, just as the first parameter
  // is the index of the beginning.
  exports.SliceNode = (function() {
    SliceNode = function SliceNode(range) {
      this.children = [(this.range = range)];
      this;
      return this;
    };
    __extend(SliceNode, BaseNode);
    SliceNode.prototype.type = 'Slice';
    SliceNode.prototype.compile_node = function compile_node(o) {
      var from, plus_part, to;
      from = this.range.from.compile(o);
      to = this.range.to.compile(o);
      plus_part = this.range.exclusive ? '' : ' + 1';
      return ".slice(" + from + ", " + to + plus_part + ")";
    };
    SliceNode.prototype.compile_splice = function compile_splice(o) {
      var _a, _b, args, array, call, exclusive, from, replace, rng, to, v;
      array = del(o, 'array');
      replace = del(o, 'replace');
      from = (typeof (_a = this.range.from) !== "undefined" && _a !== null) ? this.range.from : literal('null');
      to = (typeof (_b = this.range.to) !== "undefined" && _b !== null) ? this.range.to : literal('null');
      exclusive = this.range.exclusive ? 'true' : 'false';
      v = o.scope.free_variable();
      rng = new CallNode(new ValueNode(literal(o.scope.utility('range'))), [literal(array), from, to, literal(exclusive)]);
      args = literal("[(" + v + " = " + (rng.compile(o)) + ")[0], " + v + "[1] - " + v + "[0]].concat(" + (replace.compile(o)) + ")");
      call = new CallNode(new ValueNode(literal(array), [literal('.splice.apply')]), [literal(array), args]);
      return call.compile(o);
    };
    SliceNode.prototype.compile_slice = function compile_slice(o) {
      var _a, _b, array, call, exclusive, from, rng, to;
      array = del(o, 'array');
      from = (typeof (_a = this.range.from) !== "undefined" && _a !== null) ? this.range.from : literal('null');
      to = (typeof (_b = this.range.to) !== "undefined" && _b !== null) ? this.range.to : literal('null');
      exclusive = this.range.exclusive ? 'true' : 'false';
      rng = new CallNode(new ValueNode(literal(o.scope.utility('range'))), [literal(array), from, to, literal(exclusive)]);
      call = new CallNode(new ValueNode(literal(array), [literal('.slice.apply')]), [literal(array), rng]);
      return call.compile(o);
    };
    return SliceNode;
  }).call(this);
  //### ObjectNode
  // An object literal, nothing fancy.
  exports.ObjectNode = (function() {
    ObjectNode = function ObjectNode(props) {
      this.children = (this.objects = (this.properties = props || []));
      return this;
    };
    __extend(ObjectNode, BaseNode);
    ObjectNode.prototype.type = 'Object';
    // All the mucking about with commas is to make sure that CommentNodes and
    // AssignNodes get interleaved correctly, with no trailing commas or
    // commas affixed to comments.
    // *TODO: Extract this and add it to ArrayNode*.
    ObjectNode.prototype.compile_node = function compile_node(o) {
      var _a, _b, _c, _d, _e, _f, _g, i, indent, inner, join, last_noncom, non_comments, prop, props;
      o.indent = this.idt(1);
      non_comments = (function() {
        _a = []; _c = this.properties;
        for (_b = 0, _d = _c.length; _b < _d; _b++) {
          prop = _c[_b];
          !(prop instanceof CommentNode) ? _a.push(prop) : null;
        }
        return _a;
      }).call(this);
      last_noncom = non_comments[non_comments.length - 1];
      props = (function() {
        _e = []; _f = this.properties;
        for (i = 0, _g = _f.length; i < _g; i++) {
          prop = _f[i];
          _e.push((function() {
            join = ",\n";
            if ((prop === last_noncom) || (prop instanceof CommentNode)) {
              join = "\n";
            }
            if (i === this.properties.length - 1) {
              join = '';
            }
            indent = prop instanceof CommentNode ? '' : this.idt(1);
            return indent + prop.compile(o) + join;
          }).call(this));
        }
        return _e;
      }).call(this);
      props = props.join('');
      inner = props ? '\n' + props + '\n' + this.idt() : '';
      return "{" + inner + "}";
    };
    return ObjectNode;
  }).call(this);
  //### ArrayNode
  // An array literal.
  exports.ArrayNode = (function() {
    ArrayNode = function ArrayNode(objects) {
      this.children = (this.objects = objects || []);
      this.compile_splat_literal = __bind(SplatNode.compile_mixed_array, this, [this.objects]);
      return this;
    };
    __extend(ArrayNode, BaseNode);
    ArrayNode.prototype.type = 'Array';
    ArrayNode.prototype.compile_node = function compile_node(o) {
      var _a, _b, code, ending, i, obj, objects;
      o.indent = this.idt(1);
      objects = [];
      _a = this.objects;
      for (i = 0, _b = _a.length; i < _b; i++) {
        obj = _a[i];
        code = obj.compile(o);
        if (obj instanceof SplatNode) {
          return this.compile_splat_literal(o);
        } else if (obj instanceof CommentNode) {
          objects.push("\n" + code + "\n" + o.indent);
        } else if (i === this.objects.length - 1) {
          objects.push(code);
        } else {
          objects.push("" + code + ", ");
        }
      }
      objects = objects.join('');
      ending = objects.indexOf('\n') >= 0 ? "\n" + this.tab + "]" : ']';
      return "[" + objects + ending;
    };
    return ArrayNode;
  }).call(this);
  //### ClassNode
  // The CoffeeScript class definition.
  exports.ClassNode = (function() {
    ClassNode = function ClassNode(variable, parent, props) {
      this.children = compact(flatten([(this.variable = variable), (this.parent = parent), (this.properties = props || [])]));
      this.returns = false;
      return this;
    };
    __extend(ClassNode, BaseNode);
    ClassNode.prototype.type = 'Class';
    // Initialize a **ClassNode** with its name, an optional superclass, and a
    // list of prototype property assignments.
    ClassNode.prototype.make_return = function make_return() {
      this.returns = true;
      return this;
    };
    // Instead of generating the JavaScript string directly, we build up the
    // equivalent syntax tree and compile that, in pieces. You can see the
    // constructor, property assignments, and inheritance getting built out below.
    ClassNode.prototype.compile_node = function compile_node(o) {
      var _a, _b, _c, access, applied, construct, extension, func, prop, props, pvar, returns, val;
      extension = this.parent && new ExtendsNode(this.variable, this.parent);
      constructor = null;
      props = new Expressions();
      o.top = true;
      _b = this.properties;
      for (_a = 0, _c = _b.length; _a < _c; _a++) {
        prop = _b[_a];
        pvar = prop.variable;
        if (pvar && pvar.base.value === 'constructor') {
          func = prop.value;
          func.body.push(new ReturnNode(literal('this')));
          constructor = new AssignNode(this.variable, func);
        } else {
          if (pvar) {
            access = prop.context === 'this' ? pvar.base.properties[0] : new AccessorNode(pvar, 'prototype');
            val = new ValueNode(this.variable, [access]);
            prop = new AssignNode(val, prop.value);
          }
          props.push(prop);
        }
      }
      if (!constructor) {
        if (this.parent) {
          applied = new ValueNode(this.parent, [new AccessorNode(literal('apply'))]);
          constructor = new AssignNode(this.variable, new CodeNode([], new Expressions([new CallNode(applied, [literal('this'), literal('arguments')])])));
        } else {
          constructor = new AssignNode(this.variable, new CodeNode());
        }
      }
      construct = this.idt() + constructor.compile(o) + ';\n';
      props = props.empty() ? '' : props.compile(o) + '\n';
      extension = extension ? this.idt() + extension.compile(o) + ';\n' : '';
      returns = this.returns ? new ReturnNode(this.variable).compile(o) : '';
      return "" + construct + extension + props + returns;
    };
    return ClassNode;
  }).call(this);
  statement(ClassNode);
  //### AssignNode
  // The **AssignNode** is used to assign a local variable to value, or to set the
  // property of an object -- including within object literals.
  exports.AssignNode = (function() {
    AssignNode = function AssignNode(variable, value, context) {
      this.children = [(this.variable = variable), (this.value = value)];
      this.context = context;
      return this;
    };
    __extend(AssignNode, BaseNode);
    AssignNode.prototype.type = 'Assign';
    // Matchers for detecting prototype assignments.
    AssignNode.prototype.PROTO_ASSIGN = /^(\S+)\.prototype/;
    AssignNode.prototype.LEADING_DOT = /^\.(prototype\.)?/;
    AssignNode.prototype.top_sensitive = function top_sensitive() {
      return true;
    };
    AssignNode.prototype.is_value = function is_value() {
      return this.variable instanceof ValueNode;
    };
    AssignNode.prototype.make_return = function make_return() {
      return new Expressions([this, new ReturnNode(this.variable)]);
    };
    AssignNode.prototype.is_statement = function is_statement() {
      return this.is_value() && (this.variable.is_array() || this.variable.is_object());
    };
    // Compile an assignment, delegating to `compile_pattern_match` or
    // `compile_splice` if appropriate. Keep track of the name of the base object
    // we've been assigned to, for correct internal references. If the variable
    // has not been seen yet within the current scope, declare it.
    AssignNode.prototype.compile_node = function compile_node(o) {
      var last, match, name, proto, stmt, top, val;
      top = del(o, 'top');
      if (this.is_statement()) {
        return this.compile_pattern_match(o);
      }
      if (this.is_value() && this.variable.is_splice()) {
        return this.compile_splice(o);
      }
      stmt = del(o, 'as_statement');
      name = this.variable.compile(o);
      last = this.is_value() ? this.variable.last.replace(this.LEADING_DOT, '') : name;
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
        return "" + name + ": " + val;
      }
      if (!(this.is_value() && this.variable.has_properties())) {
        o.scope.find(name);
      }
      val = "" + name + " = " + val;
      if (stmt) {
        return "" + this.tab + val + ";";
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
    AssignNode.prototype.compile_pattern_match = function compile_pattern_match(o) {
      var _a, _b, _c, access_class, assigns, code, i, idx, obj, oindex, olength, splat, val, val_var, value;
      val_var = o.scope.free_variable();
      value = this.value.is_statement() ? ClosureNode.wrap(this.value) : this.value;
      assigns = ["" + this.tab + val_var + " = " + (value.compile(o)) + ";"];
      o.top = true;
      o.as_statement = true;
      splat = false;
      _a = this.variable.base.objects;
      for (i = 0, _b = _a.length; i < _b; i++) {
        obj = _a[i];
        idx = i;
        if (this.variable.is_object()) {
          _c = [obj.value, obj.variable.base];
          obj = _c[0];
          idx = _c[1];
        }
        access_class = this.variable.is_array() ? IndexNode : AccessorNode;
        if (obj instanceof SplatNode && !splat) {
          val = literal(obj.compile_value(o, val_var, (oindex = this.variable.base.objects.indexOf(obj)), (olength = this.variable.base.objects.length) - oindex - 1));
          splat = true;
        } else {
          if (typeof idx !== 'object') {
            idx = literal(splat ? "" + (val_var) + ".length - " + (olength - idx) : idx);
          }
          val = new ValueNode(literal(val_var), [new access_class(idx)]);
        }
        assigns.push(new AssignNode(obj, val).compile(o));
      }
      code = assigns.join("\n");
      return code;
    };
    // Compile the assignment from an array splice literal, using JavaScript's
    // `Array#splice` method.
    AssignNode.prototype.compile_splice = function compile_splice(o) {
      return this.variable.compile(merge(o, {
        only_first: true,
        splice: true,
        replace: this.value
      }));
    };
    return AssignNode;
  }).call(this);
  //### CodeNode
  // A function definition. This is the only node that creates a new Scope.
  // When for the purposes of walking the contents of a function body, the CodeNode
  // has no *children* -- they're within the inner scope.
  exports.CodeNode = (function() {
    CodeNode = function CodeNode(params, body, tag) {
      this.params = params || [];
      this.body = body || new Expressions();
      this.bound = tag === 'boundfunc';
      return this;
    };
    __extend(CodeNode, BaseNode);
    CodeNode.prototype.type = 'Code';
    // Compilation creates a new scope unless explicitly asked to share with the
    // outer scope. Handles splat parameters in the parameter list by peeking at
    // the JavaScript `arguments` objects. If the function is bound with the `=>`
    // arrow, generates a wrapper that saves the current value of `this` through
    // a closure.
    CodeNode.prototype.compile_node = function compile_node(o) {
      var _a, _b, _c, _d, _e, _f, _g, _h, _i, _j, code, func, i, name_part, param, params, ref, shared_scope, splat, top;
      shared_scope = del(o, 'shared_scope');
      top = del(o, 'top');
      o.scope = shared_scope || new Scope(o.scope, this.body, this);
      o.top = true;
      o.indent = this.idt(this.bound ? 2 : 1);
      del(o, 'no_wrap');
      del(o, 'globals');
      i = 0;
      splat = undefined;
      params = [];
      _b = this.params;
      for (_a = 0, _c = _b.length; _a < _c; _a++) {
        param = _b[_a];
        if (param instanceof SplatNode && !(typeof splat !== "undefined" && splat !== null)) {
          splat = param;
          splat.index = i;
          this.body.unshift(splat);
          splat.trailings = [];
        } else if ((typeof splat !== "undefined" && splat !== null)) {
          splat.trailings.push(param);
        } else {
          params.push(param);
        }
        i += 1;
      }
      params = (function() {
        _d = []; _f = params;
        for (_e = 0, _g = _f.length; _e < _g; _e++) {
          param = _f[_e];
          _d.push(param.compile(o));
        }
        return _d;
      }).call(this);
      this.body.make_return();
      _i = params;
      for (_h = 0, _j = _i.length; _h < _j; _h++) {
        param = _i[_h];
        (o.scope.parameter(param));
      }
      code = this.body.expressions.length ? "\n" + (this.body.compile_with_declarations(o)) + "\n" : '';
      name_part = this.name ? ' ' + this.name : '';
      func = "function" + (this.bound ? '' : name_part) + "(" + (params.join(', ')) + ") {" + code + (this.idt(this.bound ? 1 : 0)) + "}";
      if (top && !this.bound) {
        func = "(" + func + ")";
      }
      if (!(this.bound)) {
        return func;
      }
      ref = new ValueNode(literal(o.scope.utility('bind')));
      return (new CallNode(ref, [literal(func), literal('this')])).compile(o);
    };
    CodeNode.prototype.top_sensitive = function top_sensitive() {
      return true;
    };
    // When traversing (for printing or inspecting), return the real children of
    // the function -- the parameters and body of expressions.
    CodeNode.prototype.real_children = function real_children() {
      return flatten([this.params, this.body.expressions]);
    };
    // Custom `traverse` implementation that uses the `real_children`.
    CodeNode.prototype.traverse = function traverse(block) {
      var _a, _b, _c, _d, child;
      block(this);
      _a = []; _c = this.real_children();
      for (_b = 0, _d = _c.length; _b < _d; _b++) {
        child = _c[_b];
        _a.push(child.traverse(block));
      }
      return _a;
    };
    CodeNode.prototype.toString = function toString(idt) {
      var _a, _b, _c, _d, child, children;
      idt = idt || '';
      children = (function() {
        _a = []; _c = this.real_children();
        for (_b = 0, _d = _c.length; _b < _d; _b++) {
          child = _c[_b];
          _a.push(child.toString(idt + TAB));
        }
        return _a;
      }).call(this).join('');
      return "\n" + idt + children;
    };
    return CodeNode;
  }).call(this);
  //### SplatNode
  // A splat, either as a parameter to a function, an argument to a call,
  // or as part of a destructuring assignment.
  exports.SplatNode = (function() {
    SplatNode = function SplatNode(name) {
      if (!(name.compile)) {
        name = literal(name);
      }
      this.children = [(this.name = name)];
      return this;
    };
    __extend(SplatNode, BaseNode);
    SplatNode.prototype.type = 'Splat';
    SplatNode.prototype.compile_node = function compile_node(o) {
      var _a;
      if ((typeof (_a = this.index) !== "undefined" && _a !== null)) {
        return this.compile_param(o);
      } else {
        return this.name.compile(o);
      }
    };
    // Compiling a parameter splat means recovering the parameters that succeed
    // the splat in the parameter list, by slicing the arguments object.
    SplatNode.prototype.compile_param = function compile_param(o) {
      var _a, _b, _c, i, name, trailing;
      name = this.name.compile(o);
      o.scope.find(name);
      i = 0;
      _b = this.trailings;
      for (_a = 0, _c = _b.length; _a < _c; _a++) {
        trailing = _b[_a];
        o.scope.assign(trailing.compile(o), "arguments[arguments.length - " + this.trailings.length + " + " + i + "]");
        i += 1;
      }
      return "" + name + " = " + (o.scope.utility('slice')) + ".call(arguments, " + this.index + ", arguments.length - " + (this.trailings.length) + ")";
    };
    // A compiling a splat as a destructuring assignment means slicing arguments
    // from the right-hand-side's corresponding array.
    SplatNode.prototype.compile_value = function compile_value(o, name, index, trailings) {
      if ((typeof trailings !== "undefined" && trailings !== null)) {
        return "" + (o.scope.utility('slice')) + ".call(" + name + ", " + index + ", " + (name) + ".length - " + trailings + ")";
      } else {
        return "" + (o.scope.utility('slice')) + ".call(" + name + ", " + index + ")";
      }
    };
    // Utility function that converts arbitrary number of elements, mixed with
    // splats, to a proper array
    SplatNode.compile_mixed_array = function compile_mixed_array(list, o) {
      var _a, _b, _c, arg, args, code, i, prev;
      args = [];
      i = 0;
      _b = list;
      for (_a = 0, _c = _b.length; _a < _c; _a++) {
        arg = _b[_a];
        code = arg.compile(o);
        if (!(arg instanceof SplatNode)) {
          prev = args[i - 1];
          if (i === 1 && prev.substr(0, 1) === '[' && prev.substr(prev.length - 1, 1) === ']') {
            args[i - 1] = "" + (prev.substr(0, prev.length - 1)) + ", " + code + "]";
            continue;
          } else if (i > 1 && prev.substr(0, 9) === '.concat([' && prev.substr(prev.length - 2, 2) === '])') {
            args[i - 1] = "" + (prev.substr(0, prev.length - 2)) + ", " + code + "])";
            continue;
          } else {
            code = "[" + code + "]";
          }
        }
        args.push(i === 0 ? code : ".concat(" + code + ")");
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
    WhileNode = function WhileNode(condition, opts) {
      this.children = [(this.condition = condition)];
      this.filter = opts && opts.filter;
      return this;
    };
    __extend(WhileNode, BaseNode);
    WhileNode.prototype.type = 'While';
    WhileNode.prototype.add_body = function add_body(body) {
      this.children.push((this.body = body));
      return this;
    };
    WhileNode.prototype.make_return = function make_return() {
      this.returns = true;
      return this;
    };
    WhileNode.prototype.top_sensitive = function top_sensitive() {
      return true;
    };
    // The main difference from a JavaScript *while* is that the CoffeeScript
    // *while* can be used as a part of a larger expression -- while loops may
    // return an array containing the computed result of each iteration.
    WhileNode.prototype.compile_node = function compile_node(o) {
      var cond, post, pre, rvar, set, top;
      top = del(o, 'top') && !this.returns;
      o.indent = this.idt(1);
      o.top = true;
      cond = this.condition.compile(o);
      set = '';
      if (!top) {
        rvar = o.scope.free_variable();
        set = "" + this.tab + rvar + " = [];\n";
        if (this.body) {
          this.body = PushNode.wrap(rvar, this.body);
        }
      }
      pre = "" + set + (this.tab) + "while (" + cond + ")";
      if (!this.body) {
        return "" + pre + " null;" + post;
      }
      if (this.filter) {
        this.body = Expressions.wrap([new IfNode(this.filter, this.body)]);
      }
      this.returns ? (post = new ReturnNode(literal(rvar)).compile(merge(o, {
        indent: this.idt()
      }))) : (post = '');
      return "" + pre + " {\n" + (this.body.compile(o)) + "\n" + this.tab + "}\n" + post;
    };
    return WhileNode;
  }).call(this);
  statement(WhileNode);
  //### OpNode
  // Simple Arithmetic and logical operations. Performs some conversion from
  // CoffeeScript operations into their JavaScript equivalents.
  exports.OpNode = (function() {
    OpNode = function OpNode(operator, first, second, flip) {
      this.type += ' ' + operator;
      this.children = compact([(this.first = first), (this.second = second)]);
      this.operator = this.CONVERSIONS[operator] || operator;
      this.flip = !!flip;
      return this;
    };
    __extend(OpNode, BaseNode);
    OpNode.prototype.type = 'Op';
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
    OpNode.prototype.is_unary = function is_unary() {
      return !this.second;
    };
    OpNode.prototype.is_chainable = function is_chainable() {
      return this.CHAINABLE.indexOf(this.operator) >= 0;
    };
    OpNode.prototype.compile_node = function compile_node(o) {
      o.operation = true;
      if (this.is_chainable() && this.first.unwrap() instanceof OpNode && this.first.unwrap().is_chainable()) {
        return this.compile_chain(o);
      }
      if (this.ASSIGNMENT.indexOf(this.operator) >= 0) {
        return this.compile_assignment(o);
      }
      if (this.is_unary()) {
        return this.compile_unary(o);
      }
      if (this.operator === '?') {
        return this.compile_existence(o);
      }
      return [this.first.compile(o), this.operator, this.second.compile(o)].join(' ');
    };
    // Mimic Python's chained comparisons when multiple comparison operators are
    // used sequentially. For example:
    //     bin/coffee -e "puts 50 < 65 > 10"
    //     true
    OpNode.prototype.compile_chain = function compile_chain(o) {
      var _a, _b, first, second, shared;
      shared = this.first.unwrap().second;
      if (shared instanceof CallNode) {
        _a = shared.compile_reference(o);
        this.first.second = _a[0];
        shared = _a[1];
      }
      _b = [this.first.compile(o), this.second.compile(o), shared.compile(o)];
      first = _b[0];
      second = _b[1];
      shared = _b[2];
      return "(" + first + ") && (" + shared + " " + this.operator + " " + second + ")";
    };
    // When compiling a conditional assignment, take care to ensure that the
    // operands are only evaluated once, even though we have to reference them
    // more than once.
    OpNode.prototype.compile_assignment = function compile_assignment(o) {
      var _a, first, second;
      _a = [this.first.compile(o), this.second.compile(o)];
      first = _a[0];
      second = _a[1];
      if (first.match(IDENTIFIER)) {
        o.scope.find(first);
      }
      if (this.operator === '?=') {
        return "" + first + " = " + (ExistenceNode.compile_test(o, this.first)) + " ? " + first + " : " + second;
      }
      return "" + first + " = " + first + " " + (this.operator.substr(0, 2)) + " " + second;
    };
    // If this is an existence operator, we delegate to `ExistenceNode.compile_test`
    // to give us the safe references for the variables.
    OpNode.prototype.compile_existence = function compile_existence(o) {
      var _a, first, second, test;
      _a = [this.first.compile(o), this.second.compile(o)];
      first = _a[0];
      second = _a[1];
      test = ExistenceNode.compile_test(o, this.first);
      return "" + test + " ? " + first + " : " + second;
    };
    // Compile a unary **OpNode**.
    OpNode.prototype.compile_unary = function compile_unary(o) {
      var parts, space;
      space = this.PREFIX_OPERATORS.indexOf(this.operator) >= 0 ? ' ' : '';
      parts = [this.operator, space, this.first.compile(o)];
      if (this.flip) {
        parts = parts.reverse();
      }
      return parts.join('');
    };
    return OpNode;
  }).call(this);
  //### TryNode
  // A classic *try/catch/finally* block.
  exports.TryNode = (function() {
    TryNode = function TryNode(attempt, error, recovery, ensure) {
      this.children = compact([(this.attempt = attempt), (this.recovery = recovery), (this.ensure = ensure)]);
      this.error = error;
      this;
      return this;
    };
    __extend(TryNode, BaseNode);
    TryNode.prototype.type = 'Try';
    TryNode.prototype.make_return = function make_return() {
      if (this.attempt) {
        this.attempt = this.attempt.make_return();
      }
      if (this.recovery) {
        this.recovery = this.recovery.make_return();
      }
      return this;
    };
    // Compilation is more or less as you would expect -- the *finally* clause
    // is optional, the *catch* is not.
    TryNode.prototype.compile_node = function compile_node(o) {
      var attempt_part, catch_part, error_part, finally_part;
      o.indent = this.idt(1);
      o.top = true;
      attempt_part = this.attempt.compile(o);
      error_part = this.error ? " (" + (this.error.compile(o)) + ") " : ' ';
      catch_part = this.recovery ? " catch" + error_part + "{\n" + (this.recovery.compile(o)) + "\n" + this.tab + "}" : '';
      finally_part = (this.ensure || '') && ' finally {\n' + this.ensure.compile(merge(o)) + "\n" + this.tab + "}";
      return "" + (this.tab) + "try {\n" + attempt_part + "\n" + this.tab + "}" + catch_part + finally_part;
    };
    return TryNode;
  }).call(this);
  statement(TryNode);
  //### ThrowNode
  // Simple node to throw an exception.
  exports.ThrowNode = (function() {
    ThrowNode = function ThrowNode(expression) {
      this.children = [(this.expression = expression)];
      return this;
    };
    __extend(ThrowNode, BaseNode);
    ThrowNode.prototype.type = 'Throw';
    // A **ThrowNode** is already a return, of sorts...
    ThrowNode.prototype.make_return = function make_return() {
      return this;
    };
    ThrowNode.prototype.compile_node = function compile_node(o) {
      return "" + (this.tab) + "throw " + (this.expression.compile(o)) + ";";
    };
    return ThrowNode;
  }).call(this);
  statement(ThrowNode);
  //### ExistenceNode
  // Checks a variable for existence -- not *null* and not *undefined*. This is
  // similar to `.nil?` in Ruby, and avoids having to consult a JavaScript truth
  // table.
  exports.ExistenceNode = (function() {
    ExistenceNode = function ExistenceNode(expression) {
      this.children = [(this.expression = expression)];
      return this;
    };
    __extend(ExistenceNode, BaseNode);
    ExistenceNode.prototype.type = 'Existence';
    ExistenceNode.prototype.compile_node = function compile_node(o) {
      return ExistenceNode.compile_test(o, this.expression);
    };
    // The meat of the **ExistenceNode** is in this static `compile_test` method
    // because other nodes like to check the existence of their variables as well.
    // Be careful not to double-evaluate anything.
    ExistenceNode.compile_test = function compile_test(o, variable) {
      var _a, _b, _c, first, second;
      _a = [variable, variable];
      first = _a[0];
      second = _a[1];
      if (variable instanceof CallNode || (variable instanceof ValueNode && variable.has_properties())) {
        _b = variable.compile_reference(o);
        first = _b[0];
        second = _b[1];
      }
      _c = [first.compile(o), second.compile(o)];
      first = _c[0];
      second = _c[1];
      return "(typeof " + first + " !== \"undefined\" && " + second + " !== null)";
    };
    return ExistenceNode;
  }).call(this);
  //### ParentheticalNode
  // An extra set of parentheses, specified explicitly in the source. At one time
  // we tried to clean up the results by detecting and removing redundant
  // parentheses, but no longer -- you can put in as many as you please.
  // Parentheses are a good way to force any statement to become an expression.
  exports.ParentheticalNode = (function() {
    ParentheticalNode = function ParentheticalNode(expression) {
      this.children = [(this.expression = expression)];
      return this;
    };
    __extend(ParentheticalNode, BaseNode);
    ParentheticalNode.prototype.type = 'Paren';
    ParentheticalNode.prototype.is_statement = function is_statement() {
      return this.expression.is_statement();
    };
    ParentheticalNode.prototype.make_return = function make_return() {
      return this.expression.make_return();
    };
    ParentheticalNode.prototype.compile_node = function compile_node(o) {
      var code, l;
      code = this.expression.compile(o);
      if (this.is_statement()) {
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
  }).call(this);
  //### ForNode
  // CoffeeScript's replacement for the *for* loop is our array and object
  // comprehensions, that compile into *for* loops here. They also act as an
  // expression, able to return the result of each filtered iteration.
  // Unlike Python array comprehensions, they can be multi-line, and you can pass
  // the current index of the loop as a second parameter. Unlike Ruby blocks,
  // you can map and filter in a single pass.
  exports.ForNode = (function() {
    ForNode = function ForNode(body, source, name, index) {
      var _a;
      this.body = body;
      this.name = name;
      this.index = index || null;
      this.source = source.source;
      this.filter = source.filter;
      this.step = source.step;
      this.object = !!source.object;
      if (this.object) {
        _a = [this.index, this.name];
        this.name = _a[0];
        this.index = _a[1];
      }
      this.children = compact([this.body, this.source, this.filter]);
      this.returns = false;
      return this;
    };
    __extend(ForNode, BaseNode);
    ForNode.prototype.type = 'For';
    ForNode.prototype.top_sensitive = function top_sensitive() {
      return true;
    };
    ForNode.prototype.make_return = function make_return() {
      this.returns = true;
      return this;
    };
    ForNode.prototype.compile_return_value = function compile_return_value(val, o) {
      if (this.returns) {
        return new ReturnNode(literal(val)).compile(o);
      }
      return val || '';
    };
    // Welcome to the hairiest method in all of CoffeeScript. Handles the inner
    // loop, filtering, stepping, and result saving for array, object, and range
    // comprehensions. Some of the generated code can be shared in common, and
    // some cannot.
    ForNode.prototype.compile_node = function compile_node(o) {
      var body, body_dent, close, for_part, index, index_var, ivar, lvar, name, range, return_result, rvar, scope, set_result, source, source_part, step_part, svar, top_level, var_part, vars;
      top_level = del(o, 'top') && !this.returns;
      range = this.source instanceof ValueNode && this.source.base instanceof RangeNode && !this.source.properties.length;
      source = range ? this.source.base : this.source;
      scope = o.scope;
      name = this.name && this.name.compile(o);
      index = this.index && this.index.compile(o);
      if (name) {
        scope.find(name);
      }
      if (index) {
        scope.find(index);
      }
      body_dent = this.idt(1);
      if (!(top_level)) {
        rvar = scope.free_variable();
      }
      ivar = range ? name : index || scope.free_variable();
      var_part = '';
      body = Expressions.wrap([this.body]);
      if (range) {
        index_var = scope.free_variable();
        source_part = source.compile_variables(o);
        for_part = source.compile(merge(o, {
          index: ivar,
          step: this.step
        }));
        for_part = "" + index_var + " = 0, " + for_part + ", " + index_var + "++";
      } else {
        svar = scope.free_variable();
        index_var = null;
        source_part = "" + svar + " = " + (this.source.compile(o)) + ";\n" + this.tab;
        if (name) {
          var_part = "" + body_dent + name + " = " + svar + "[" + ivar + "];\n";
        }
        if (!this.object) {
          lvar = scope.free_variable();
          step_part = this.step ? "" + ivar + " += " + (this.step.compile(o)) : "" + ivar + "++";
          for_part = "" + ivar + " = 0, " + lvar + " = " + (svar) + ".length; " + ivar + " < " + lvar + "; " + step_part;
        }
      }
      set_result = rvar ? this.idt() + rvar + ' = []; ' : this.idt();
      return_result = this.compile_return_value(rvar, o);
      if (top_level && body.contains(function(n) {
        return n instanceof CodeNode;
      })) {
        body = ClosureNode.wrap(body, true);
      }
      if (!(top_level)) {
        body = PushNode.wrap(rvar, body);
      }
      this.filter ? (body = Expressions.wrap([new IfNode(this.filter, body)])) : null;
      this.object ? (for_part = "" + ivar + " in " + svar + ") { if (" + (o.scope.utility('hasProp')) + ".call(" + svar + ", " + ivar + ")") : null;
      body = body.compile(merge(o, {
        indent: body_dent,
        top: true
      }));
      vars = range ? name : "" + name + ", " + ivar;
      close = this.object ? '}}\n' : '}\n';
      return "" + set_result + (source_part) + "for (" + for_part + ") {\n" + var_part + body + "\n" + this.tab + close + return_result;
    };
    return ForNode;
  }).call(this);
  statement(ForNode);
  //### IfNode
  // *If/else* statements. Our *switch/when* will be compiled into this. Acts as an
  // expression by pushing down requested returns to the last line of each clause.
  // Single-expression **IfNodes** are compiled into ternary operators if possible,
  // because ternaries are already proper expressions, and don't need conversion.
  exports.IfNode = (function() {
    IfNode = function IfNode(condition, body, else_body, tags) {
      this.condition = condition;
      this.body = body && body.unwrap();
      this.else_body = else_body && else_body.unwrap();
      this.children = compact(flatten([this.condition, this.body, this.else_body]));
      this.tags = tags || {};
      if (this.condition instanceof Array) {
        this.multiple = true;
      }
      if (this.tags.invert) {
        this.condition = new OpNode('!', new ParentheticalNode(this.condition));
      }
      return this;
    };
    __extend(IfNode, BaseNode);
    IfNode.prototype.type = 'If';
    // Add a new *else* clause to this **IfNode**, or push it down to the bottom
    // of the chain recursively.
    IfNode.prototype.push = function push(else_body) {
      var eb;
      eb = else_body.unwrap();
      this.else_body ? this.else_body.push(eb) : (this.else_body = eb);
      return this;
    };
    IfNode.prototype.force_statement = function force_statement() {
      this.tags.statement = true;
      return this;
    };
    // Tag a chain of **IfNodes** with their object(s) to switch on for equality
    // tests. `rewrite_switch` will perform the actual change at compile time.
    IfNode.prototype.rewrite_condition = function rewrite_condition(expression) {
      this.switcher = expression;
      return this;
    };
    // Rewrite a chain of **IfNodes** with their switch condition for equality.
    // Ensure that the switch expression isn't evaluated more than once.
    IfNode.prototype.rewrite_switch = function rewrite_switch(o) {
      var _a, _b, _c, assigner, cond, i, variable;
      assigner = this.switcher;
      if (!(this.switcher.unwrap() instanceof LiteralNode)) {
        variable = literal(o.scope.free_variable());
        assigner = new AssignNode(variable, this.switcher);
        this.switcher = variable;
      }
      this.condition = (function() {
        if (this.multiple) {
          _a = []; _b = this.condition;
          for (i = 0, _c = _b.length; i < _c; i++) {
            cond = _b[i];
            _a.push(new OpNode('==', (i === 0 ? assigner : this.switcher), cond));
          }
          return _a;
        } else {
          return new OpNode('==', assigner, this.condition);
        }
      }).call(this);
      if (this.is_chain()) {
        this.else_body.rewrite_condition(this.switcher);
      }
      return this;
    };
    // Rewrite a chain of **IfNodes** to add a default case as the final *else*.
    IfNode.prototype.add_else = function add_else(exprs, statement) {
      if (this.is_chain()) {
        this.else_body.add_else(exprs, statement);
      } else {
        if (!(statement)) {
          exprs = exprs.unwrap();
        }
        this.children.push((this.else_body = exprs));
      }
      return this;
    };
    // If the `else_body` is an **IfNode** itself, then we've got an *if-else* chain.
    IfNode.prototype.is_chain = function is_chain() {
      return this.chain = this.chain || this.else_body && this.else_body instanceof IfNode;
    };
    // The **IfNode** only compiles into a statement if either of its bodies needs
    // to be a statement. Otherwise a ternary is safe.
    IfNode.prototype.is_statement = function is_statement() {
      return this.statement = this.statement || !!(this.comment || this.tags.statement || this.body.is_statement() || (this.else_body && this.else_body.is_statement()));
    };
    IfNode.prototype.compile_condition = function compile_condition(o) {
      var _a, _b, _c, _d, cond;
      return (function() {
        _a = []; _c = flatten([this.condition]);
        for (_b = 0, _d = _c.length; _b < _d; _b++) {
          cond = _c[_b];
          _a.push(cond.compile(o));
        }
        return _a;
      }).call(this).join(' || ');
    };
    IfNode.prototype.compile_node = function compile_node(o) {
      if (this.is_statement()) {
        return this.compile_statement(o);
      } else {
        return this.compile_ternary(o);
      }
    };
    IfNode.prototype.make_return = function make_return() {
      this.body = this.body && this.body.make_return();
      this.else_body = this.else_body && this.else_body.make_return();
      return this;
    };
    // Compile the **IfNode** as a regular *if-else* statement. Flattened chains
    // force inner *else* bodies into statement form.
    IfNode.prototype.compile_statement = function compile_statement(o) {
      var body, child, com_dent, cond_o, else_part, if_dent, if_part, prefix;
      if (this.switcher) {
        this.rewrite_switch(o);
      }
      child = del(o, 'chain_child');
      cond_o = merge(o);
      o.indent = this.idt(1);
      o.top = true;
      if_dent = child ? '' : this.idt();
      com_dent = child ? this.idt() : '';
      prefix = this.comment ? "" + (this.comment.compile(cond_o)) + "\n" + com_dent : '';
      body = Expressions.wrap([this.body]).compile(o);
      if_part = "" + prefix + (if_dent) + "if (" + (this.compile_condition(cond_o)) + ") {\n" + body + "\n" + this.tab + "}";
      if (!(this.else_body)) {
        return if_part;
      }
      else_part = this.is_chain() ? ' else ' + this.else_body.compile(merge(o, {
        indent: this.idt(),
        chain_child: true
      })) : " else {\n" + (Expressions.wrap([this.else_body]).compile(o)) + "\n" + this.tab + "}";
      return "" + if_part + else_part;
    };
    // Compile the IfNode as a ternary operator.
    IfNode.prototype.compile_ternary = function compile_ternary(o) {
      var else_part, if_part;
      if_part = this.condition.compile(o) + ' ? ' + this.body.compile(o);
      else_part = this.else_body ? this.else_body.compile(o) : 'null';
      return "" + if_part + " : " + else_part;
    };
    return IfNode;
  }).call(this);
  // Faux-Nodes
  // ----------
  //### PushNode
  // Faux-nodes are never created by the grammar, but are used during code
  // generation to generate other combinations of nodes. The **PushNode** creates
  // the tree for `array.push(value)`, which is helpful for recording the result
  // arrays from comprehensions.
  PushNode = (exports.PushNode = {
    wrap: function wrap(array, expressions) {
      var expr;
      expr = expressions.unwrap();
      if (expr.is_pure_statement() || expr.contains_pure_statement()) {
        return expressions;
      }
      return Expressions.wrap([new CallNode(new ValueNode(literal(array), [new AccessorNode(literal('push'))]), [expr])]);
    }
  });
  //### ClosureNode
  // A faux-node used to wrap an expressions body in a closure.
  ClosureNode = (exports.ClosureNode = {
    // Wrap the expressions body, unless it contains a pure statement,
    // in which case, no dice.
    wrap: function wrap(expressions, statement) {
      var call, func;
      if (expressions.contains_pure_statement()) {
        return expressions;
      }
      func = new ParentheticalNode(new CodeNode([], Expressions.wrap([expressions])));
      call = new CallNode(new ValueNode(func, [new AccessorNode(literal('call'))]), [literal('this')]);
      if (statement) {
        return Expressions.wrap([call]);
      } else {
        return call;
      }
    }
  });
  // Constants
  // ---------
  // Tabs are two spaces for pretty printing.
  TAB = '  ';
  // Trim out all trailing whitespace, so that the generated code plays nice
  // with Git.
  TRAILING_WHITESPACE = /\s+$/gm;
  // Keep this identifier regex in sync with the Lexer.
  IDENTIFIER = /^[a-zA-Z\$_](\w|\$)*$/;
  // Utility Functions
  // -----------------
  // Handy helper for a generating LiteralNode.
  literal = function literal(name) {
    return new LiteralNode(name);
  };
})();
