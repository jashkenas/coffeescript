(function(){
  var compact, dup, flatten;
  var __hasProp = Object.prototype.hasOwnProperty;
  // The abstract base class for all CoffeeScript nodes.
  // All nodes are implement a "compile_node" method, which performs the
  // code generation for that node. To compile a node, call the "compile"
  // method, which wraps "compile_node" in some extra smarts, to know when the
  // generated code should be wrapped up in a closure. An options hash is passed
  // and cloned throughout, containing messages from higher in the AST,
  // information about the current scope, and indentation level.
  exports.Node = function Node() {
    var __a;
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.values = arguments;
    __a = this.name = this.constructor.name;
    return Node === this.constructor ? this : __a;
  };
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
  // TODO -- shallow (1 deep) flatten..
  // need recursive version..
  flatten = function flatten(aggList, newList) {
    var __a, __b, item;
    __a = newList;
    for (__b = 0; __b < __a.length; __b++) {
      item = __a[__b];
      aggList.push(item);
    }
    return aggList;
  };
  compact = function compact(input) {
    var __a, __b, __c, compected, item;
    compected = [];
    __a = []; __b = input;
    for (__c = 0; __c < __b.length; __c++) {
      item = __b[__c];
      __a.push((typeof item !== "undefined" && item !== null) ? compacted.push(item) : null);
    }
    return __a;
  };
  dup = function dup(input) {
    var __a, __b, __c, key, output, val;
    output = null;
    if (input instanceof Array) {
      output = [];
      __a = input;
      for (__b = 0; __b < __a.length; __b++) {
        val = __a[__b];
        output.push(val);
      }
    } else {
      output = {
      };
      __c = input;
      for (key in __c) {
        val = __c[key];
        if (__hasProp.call(__c, key)) {
          output.key = val;
        }
      }
      output;
    }
    return output;
  };
  exports.Node.prototype.TAB = '  ';
  // Tag this node as a statement, meaning that it can't be used directly as
  // the result of an expression.
  exports.Node.prototype.mark_as_statement = function mark_as_statement() {
    return this.is_statement = function is_statement() {
      return true;
    };
  };
  // Tag this node as a statement that cannot be transformed into an expression.
  // (break, continue, etc.) It doesn't make sense to try to transform it.
  exports.Node.prototype.mark_as_statement_only = function mark_as_statement_only() {
    this.mark_as_statement();
    return this.is_statement_only = function is_statement_only() {
      return true;
    };
  };
  // This node needs to know if it's being compiled as a top-level statement,
  // in order to compile without special expression conversion.
  exports.Node.prototype.mark_as_top_sensitive = function mark_as_top_sensitive() {
    return this.is_top_sensitive = function is_top_sensitive() {
      return true;
    };
  };
  // Provide a quick implementation of a children method.
  exports.Node.prototype.children = function children(attributes) {
    var __a, __b, agg, compacted, item;
    // TODO -- are these optimal impls of flatten and compact
    // .. do better ones exist in a stdlib?
    agg = [];
    __a = attributes;
    for (__b = 0; __b < __a.length; __b++) {
      item = __a[__b];
      agg = flatten(agg, item);
    }
    compacted = compact(agg);
    return this.children = function children() {
      return compacted;
    };
  };
  exports.Node.prototype.write = function write(code) {
    // hm..
    // TODO -- should print to STDOUT in "VERBOSE" how to
    // go about this.. ? jsonify 'this'?
    // use node's puts ??
    return code;
  };
  // This is extremely important -- we convert JS statements into expressions
  // by wrapping them in a closure, only if it's possible, and we're not at
  // the top level of a block (which would be unnecessary), and we haven't
  // already been asked to return the result.
  exports.Node.prototype.compile = function compile(o) {
    var closure, opts, top;
    // TODO -- need JS dup/clone
    opts = (typeof !o !== "undefined" && !o !== null) ? {
    } : o;
    this.options = opts;
    this.indent = opts.indent;
    top = this.options.top;
    !this.is_top_sentitive() ? (this.options.top = undefined) : null;
    closure = this.is_statement() && !this.is_statement_only() && !top && typeof (this) === "CommentNode";
    closure = closure && !this.do_i_contain(function(n) {
      return n.is_statement_only();
    });
    return closure ? this.compile_closure(this.options) : compile_node(this.options);
  };
  // Statements converted into expressions share scope with their parent
  // closure, to preserve JavaScript-style lexical scope.
  exports.Node.prototype.compile_closure = function compile_closure(o) {
    var opts;
    opts = (typeof !o !== "undefined" && !o !== null) ? {
    } : o;
    this.indent = opts.indent;
    opts.shared_scope = o.scope;
    return exports.ClosureNode.wrap(this).compile(opts);
  };
  // Quick short method for the current indentation level, plus tabbing in.
  exports.Node.prototype.idt = function idt(tLvl) {
    var __a, __b, __c, __d, tabAmt, tabs, x;
    tabs = (typeof tLvl !== "undefined" && tLvl !== null) ? tLvl : 0;
    tabAmt = '';
    __c = 0; __d = tabs;
    for (__b=0, x=__c; (__c <= __d ? x < __d : x > __d); (__c <= __d ? x += 1 : x -= 1), __b++) {
      tabAmt = tabAmt + this.TAB;
    }
    return this.indent + tabAmt;
  };
  //Does this node, or any of it's children, contain a node of a certain kind?
  exports.Node.prototype.do_i_contain = function do_i_contain(block) {
    var __a, __b, node;
    __a = this.children;
    for (__b = 0; __b < __a.length; __b++) {
      node = __a[__b];
      if (block(node)) {
        return true;
      }
      if (node instanceof exports.Node && node.do_i_contain(block)) {
        return true;
      }
    }
    return false;
  };
  // Default implementations of the common node methods.
  exports.Node.prototype.unwrap = function unwrap() {
    return this;
  };
  exports.Node.prototype.children = [];
  exports.Node.prototype.is_a_statement = function is_a_statement() {
    return false;
  };
  exports.Node.prototype.is_a_statement_only = function is_a_statement_only() {
    return false;
  };
  exports.Node.prototype.is_top_sensitive = function is_top_sensitive() {
    return false;
  };
  // A collection of nodes, each one representing an expression.
  // exports.Expressions: (nodes) ->
  //   this.mark_as_statement()
  //   this.expressions: []
  //   this.children([this.expressions])
  //   for n in nodes
  //     this.expressions: flatten this.expressions, n
  // exports.Expressions extends exports.Node
  exports.Expressions.prototype.TRAILING_WHITESPACE = /\s+$/;
  // Wrap up a node as an Expressions, unless it already is.
  exports.Expressions.prototype.wrap = function wrap(nodes) {
    if (nodes.length === 1 && nodes[0] instanceof exports.Expressions) {
      return nodes[0];
    }
    return new Expressions(nodes);
  };
  // Tack an expression on to the end of this expression list.
  exports.Expressions.prototype.push = function push(node) {
    this.expressions.push(node);
    return this;
  };
  // Tack an expression on to the beginning of this expression list.
  exports.Expressions.prototype.unshift = function unshift(node) {
    this.expressions.unshift(node);
    return this;
  };
  // If this Expressions consists of a single node, pull it back out.
  exports.Expressions.prototype.unwrap = function unwrap() {
    return this.expressions.length === 1 ? this.expressions[0] : this;
  };
  // Is this an empty block of code?
  exports.Expressions.prototype.is_empty = function is_empty() {
    return this.expressions.length === 0;
  };
  // Is the node last in this block of expressions.
  exports.Expressions.prototype.is_last = function is_last(node) {
    var arr_length;
    arr_length = this.expressions.length;
    this.last_index = this.last_index || this.expressions[arr_length - 1] instanceof exports.CommentNode ? -2 : -1;
    return node === this.expressions[arr_length - this.last_index];
  };
  exports.Expressions.prototype.compile = function compile(o) {
    var opts;
    opts = (typeof o !== "undefined" && o !== null) ? o : {
    };
    return opts.scope ? exports.Expressions.__superClass__.compile.call(this, dup(opts)) : this.compile_root(o);
  };
  // Compile each expression in the Expressions body.
  exports.Expressions.prototype.compile_node = function compile_node(options) {
    var __a, __b, __c, __d, __e, code, compiled, e, line, opts;
    opts = (typeof options !== "undefined" && options !== null) ? options : {
    };
    compiled = [];
    __a = this.expressions;
    for (__b = 0; __b < __a.length; __b++) {
      e = __a[__b];
      compiled.push(this.compile_expression(e, dup(options)));
    }
    code = '';
    __c = []; __d = compiled;
    for (__e = 0; __e < __d.length; __e++) {
      line = __d[__e];
      __c.push((code = code + line + '\n'));
    }
    return __c;
  };
  // If this is the top-level Expressions, wrap everything in a safety closure.
  exports.Expressions.prototype.compile_root = function compile_root(o) {
    var code, indent, opts;
    opts = (typeof o !== "undefined" && o !== null) ? o : {
    };
    indent = opts.no_wrap ? '' : this.TAB;
    this.indent = indent;
    opts.indent = indent;
    opts.scope = new Scope(null, this, null);
    code = opts.globals ? compile_node(opts) : compile_with_declarations(opts);
    code.replace(this.TRAILING_WHITESPACE, '');
    return this.write(opts.no_wrap ? code : "(function(){\n" + code + "\n})();");
  };
})();