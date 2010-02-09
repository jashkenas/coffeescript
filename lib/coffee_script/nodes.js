(function(){
  var Expressions, Node, TAB, TRAILING_WHITESPACE, __a, compact, del, dup, flatten, statement;
  var __hasProp = Object.prototype.hasOwnProperty;
  // The abstract base class for all CoffeeScript nodes.
  // All nodes are implement a "compile_node" method, which performs the
  // code generation for that node. To compile a node, call the "compile"
  // method, which wraps "compile_node" in some extra smarts, to know when the
  // generated code should be wrapped up in a closure. An options hash is passed
  // and cloned throughout, containing messages from higher in the AST,
  // information about the current scope, and indentation level.
  exports.Expressions = function Expressions() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return Expressions === this.constructor ? this : __a;
  };
  exports.LiteralNode = function LiteralNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return LiteralNode === this.constructor ? this : __a;
  };
  exports.ReturnNode = function ReturnNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return ReturnNode === this.constructor ? this : __a;
  };
  exports.CommentNode = function CommentNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return CommentNode === this.constructor ? this : __a;
  };
  exports.CallNode = function CallNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return CallNode === this.constructor ? this : __a;
  };
  exports.ExtendsNode = function ExtendsNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return ExtendsNode === this.constructor ? this : __a;
  };
  exports.ValueNode = function ValueNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return ValueNode === this.constructor ? this : __a;
  };
  exports.AccessorNode = function AccessorNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return AccessorNode === this.constructor ? this : __a;
  };
  exports.IndexNode = function IndexNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return IndexNode === this.constructor ? this : __a;
  };
  exports.RangeNode = function RangeNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return RangeNode === this.constructor ? this : __a;
  };
  exports.SliceNode = function SliceNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return SliceNode === this.constructor ? this : __a;
  };
  exports.AssignNode = function AssignNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return AssignNode === this.constructor ? this : __a;
  };
  exports.OpNode = function OpNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return OpNode === this.constructor ? this : __a;
  };
  exports.CodeNode = function CodeNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return CodeNode === this.constructor ? this : __a;
  };
  exports.SplatNode = function SplatNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return SplatNode === this.constructor ? this : __a;
  };
  exports.ObjectNode = function ObjectNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return ObjectNode === this.constructor ? this : __a;
  };
  exports.ArrayNode = function ArrayNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return ArrayNode === this.constructor ? this : __a;
  };
  exports.PushNode = function PushNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return PushNode === this.constructor ? this : __a;
  };
  exports.ClosureNode = function ClosureNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return ClosureNode === this.constructor ? this : __a;
  };
  exports.WhileNode = function WhileNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return WhileNode === this.constructor ? this : __a;
  };
  exports.ForNode = function ForNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return ForNode === this.constructor ? this : __a;
  };
  exports.TryNode = function TryNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return TryNode === this.constructor ? this : __a;
  };
  exports.ThrowNode = function ThrowNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return ThrowNode === this.constructor ? this : __a;
  };
  exports.ExistenceNode = function ExistenceNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return ExistenceNode === this.constructor ? this : __a;
  };
  exports.ParentheticalNode = function ParentheticalNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return ParentheticalNode === this.constructor ? this : __a;
  };
  exports.IfNode = function IfNode() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    __a = this.values = arguments;
    return IfNode === this.constructor ? this : __a;
  };
  exports.Expressions.wrap = function wrap(values) {
    return this.values = values;
  };
  // Some helper functions
  // Tabs are two spaces for pretty printing.
  TAB = '  ';
  TRAILING_WHITESPACE = /\s+$/g;
  // Flatten nested arrays recursively.
  flatten = function flatten(list) {
    var __a, __b, __c, item, memo;
    memo = [];
    __a = []; __b = list;
    for (__c = 0; __c < __b.length; __c++) {
      item = __b[__c];
      if (item instanceof Array) {
        return memo.concat(flatten(item));
      }
      memo.push(item);
      memo;
    }
    return __a;
  };
  // Remove all null values from an array.
  compact = function compact(input) {
    var __a, __b, __c, item;
    __a = []; __b = input;
    for (__c = 0; __c < __b.length; __c++) {
      item = __b[__c];
      if ((typeof item !== "undefined" && item !== null)) {
        __a.push(item);
      }
    }
    return __a;
  };
  // Dup an array or object.
  dup = function dup(input) {
    var __a, __b, __c, __d, key, output, val;
    if (input instanceof Array) {
      __a = []; __b = input;
      for (__c = 0; __c < __b.length; __c++) {
        val = __b[__c];
        __a.push(val);
      }
      return __a;
    } else {
      output = {
      };
      __d = input;
      for (key in __d) {
        val = __d[key];
        if (__hasProp.call(__d, key)) {
          ((output[key] = val));
        }
      }
      return output;
    }
  };
  // Delete a key from an object, returning the value.
  del = function del(obj, key) {
    var val;
    val = obj[key];
    delete obj[key];
    return val;
  };
  // # Provide a quick implementation of a children method.
  // children: (klass, attrs...) ->
  //   klass::children: ->
  //     nodes: this[attr] for attr in attrs
  //     compact flatten nodes
  // Mark a node as a statement, or a statement only.
  statement = function statement(klass, only) {
    klass.prototype.statement = function statement() {
      return true;
    };
    return klass.prototype.statement_only = function statement_only() {
      if (only) {
        return true;
      }
    };
  };
  // The abstract base class for all CoffeeScript nodes.
  // All nodes are implement a "compile_node" method, which performs the
  // code generation for that node. To compile a node, call the "compile"
  // method, which wraps "compile_node" in some extra smarts, to know when the
  // generated code should be wrapped up in a closure. An options hash is passed
  // and cloned throughout, containing messages from higher in the AST,
  // information about the current scope, and indentation level.
  Node = (exports.Node = function Node() {  });
  // This is extremely important -- we convert JS statements into expressions
  // by wrapping them in a closure, only if it's possible, and we're not at
  // the top level of a block (which would be unnecessary), and we haven't
  // already been asked to return the result.
  Node.prototype.compile = function compile(o) {
    var closure, top;
    this.options = dup(o || {
    });
    this.indent = o.indent;
    top = this.top_sensitive() ? o.top : del(obj('top'));
    closure = this.statement() && !this.statement_only() && !top && !o.returns && !this instanceof CommentNode && !this.contains(function(node) {
      return node.statement_only();
    });
    return closure ? this.compile_closure(this.options) : this.compile_node(this.options);
  };
  // Statements converted into expressions share scope with their parent
  // closure, to preserve JavaScript-style lexical scope.
  Node.prototype.compile_closure = function compile_closure(o) {
    this.indent = o.indent;
    o.shared_scope = o.scope;
    return ClosureNode.wrap(this).compile(o);
  };
  // Quick short method for the current indentation level, plus tabbing in.
  Node.prototype.idt = function idt(tabs) {
    var __a, __b, __c, __d, i, idt;
    idt = this.indent;
    __c = 0; __d = (tabs || 0);
    for (__b=0, i=__c; (__c <= __d ? i <= __d : i >= __d); (__c <= __d ? i += 1 : i -= 1), __b++) {
      idt += TAB;
    }
    return idt;
  };
  // Does this node, or any of its children, contain a node of a certain kind?
  Node.prototype.contains = function contains(block) {
    var __a, __b, node;
    __a = this.children;
    for (__b = 0; __b < __a.length; __b++) {
      node = __a[__b];
      if (block(node)) {
        return true;
      }
      if (node instanceof Node && node.contains(block)) {
        return true;
      }
    }
    return false;
  };
  // Default implementations of the common node methods.
  Node.prototype.unwrap = function unwrap() {
    return this;
  };
  Node.prototype.children = [];
  Node.prototype.statement = function statement() {
    return false;
  };
  Node.prototype.statement_only = function statement_only() {
    return false;
  };
  Node.prototype.top_sensitive = function top_sensitive() {
    return false;
  };
  // A collection of nodes, each one representing an expression.
  Expressions = (exports.Expressions = function Expressions() {
    var __a, nodes;
    nodes = Array.prototype.slice.call(arguments, 0);
    this.expressions = flatten(nodes);
    __a = this.children = this.expressions;
    return Expressions === this.constructor ? this : __a;
  });
  __a = function(){};
  __a.prototype = Node.prototype;
  Expressions.__superClass__ = Node.prototype;
  Expressions.prototype = new __a();
  Expressions.prototype.constructor = Expressions;
  statement(Expressions);
  // Wrap up a node as an Expressions, unless it already is.
  Expressions.prototype.wrap = function wrap() {
    var nodes;
    nodes = Array.prototype.slice.call(arguments, 0);
    if (nodes.length === 1 && nodes[0] instanceof Expressions) {
      return nodes[0];
    }
    return new Expressions.apply(this, nodes);
  };
  // Tack an expression on to the end of this expression list.
  Expressions.prototype.push = function push(node) {
    this.expressions.push(node);
    return this;
  };
  // Tack an expression on to the beginning of this expression list.
  Expressions.prototype.unshift = function unshift(node) {
    this.expressions.unshift(node);
    return this;
  };
  // If this Expressions consists of a single node, pull it back out.
  Expressions.prototype.unwrap = function unwrap() {
    return this.expressions.length === 1 ? this.expressions[0] : this;
  };
  // Is this an empty block of code?
  Expressions.prototype.empty = function empty() {
    return this.expressions.length === 0;
  };
  // Is the node last in this block of expressions?
  Expressions.prototype.is_last = function is_last(node) {
    var l;
    l = this.expressions.length;
    this.last_index = this.last_index || this.expressions[l - 1] instanceof CommentNode ? -2 : -1;
    return node === this.expressions[l - this.last_index];
  };
  Expressions.prototype.compile = function compile(o) {
    return o.scope ? Expressions.__superClass__.compile.call(this, o) : this.compile_root(o);
  };
  // Compile each expression in the Expressions body.
  Expressions.prototype.compile_node = function compile_node(o) {
    var __b, __c, __d, node;
    return ((function() {
      __b = []; __c = this.expressions;
      for (__d = 0; __d < __c.length; __d++) {
        node = __c[__d];
        __b.push(this.compile_expression(node, dup(o)));
      }
      return __b;
    }).call(this)).join("\n");
  };
  // If this is the top-level Expressions, wrap everything in a safety closure.
  Expressions.prototype.compile_root = function compile_root(o) {
    var code, indent;
    o.indent = (this.indent = (indent = o.no_wrap ? '' : TAB));
    o.scope = new Scope(null, this, null);
    code = o.globals ? this.compile_node(o) : this.compile_with_declarations(o);
    code = code.replace(TRAILING_WHITESPACE, '');
    return o.no_wrap ? code : "(function(){\n" + code + "\n})();";
  };
})();