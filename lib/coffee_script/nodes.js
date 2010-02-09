(function(){
  var Expressions, LiteralNode, Node, TAB, TRAILING_WHITESPACE, compact, del, dup, flatten, inherit, merge, statement;
  var __hasProp = Object.prototype.hasOwnProperty;
  process.mixin(require('./scope'));
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
  // Merge objects.
  merge = function merge(src, dest) {
    var __a, __b, key, val;
    dest[key] = (function() {
      __a = []; __b = src;
      for (key in __b) {
        val = __b[key];
        if (__hasProp.call(__b, key)) {
          __a.push(val);
        }
      }
      return __a;
    }).call(this);
    return dest;
  };
  // Delete a key from an object, returning the value.
  del = function del(obj, key) {
    var val;
    val = obj[key];
    delete obj[key];
    return val;
  };
  // Quickie inheritance convenience wrapper to reduce typing.
  inherit = function inherit(parent, props) {
    var __a, __b, klass, name, prop;
    klass = props.constructor;
    delete props.constructor;
    __a = function(){};
    __a.prototype = parent.prototype;
    klass.__superClass__ = parent.prototype;
    klass.prototype = new __a();
    klass.prototype.constructor = klass;
    __b = props;
    for (name in __b) {
      prop = __b[name];
      if (__hasProp.call(__b, name)) {
        ((klass.prototype[name] = prop));
      }
    }
    return klass;
  };
  // # Provide a quick implementation of a children method.
  // children: (klass, attrs...) ->
  //   klass::children: ->
  //     nodes: this[attr] for attr in attrs
  //     compact flatten nodes
  // Mark a node as a statement, or a statement only.
  statement = function statement(klass, only) {
    klass.prototype.is_statement = function is_statement() {
      return true;
    };
    return klass.prototype.is_statement_only = function is_statement_only() {
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
    closure = this.is_statement() && !this.is_statement_only() && !top && !o.returns && !this instanceof CommentNode && !this.contains(function(node) {
      return node.is_statement_only();
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
  Node.prototype.is_statement = function is_statement() {
    return false;
  };
  Node.prototype.is_statement_only = function is_statement_only() {
    return false;
  };
  Node.prototype.top_sensitive = function top_sensitive() {
    return false;
  };
  // A collection of nodes, each one representing an expression.
  Expressions = (exports.Expressions = inherit(Node, {
    constructor: function constructor(nodes) {
      this.expressions = flatten(nodes);
      this.children = this.expressions;
      return this;
    },
    // Tack an expression on to the end of this expression list.
    push: function push(node) {
      this.expressions.push(node);
      return this;
    },
    // Tack an expression on to the beginning of this expression list.
    unshift: function unshift(node) {
      this.expressions.unshift(node);
      return this;
    },
    // If this Expressions consists of a single node, pull it back out.
    unwrap: function unwrap() {
      return this.expressions.length === 1 ? this.expressions[0] : this;
    },
    // Is this an empty block of code?
    empty: function empty() {
      return this.expressions.length === 0;
    },
    // Is the node last in this block of expressions?
    is_last: function is_last(node) {
      var l;
      l = this.expressions.length;
      this.last_index = this.last_index || this.expressions[l - 1] instanceof CommentNode ? -2 : -1;
      return node === this.expressions[l - this.last_index];
    },
    compile: function compile(o) {
      return o.scope ? compile.__superClass__.constructor.call(this, o) : this.compile_root(o);
    },
    // Compile each expression in the Expressions body.
    compile_node: function compile_node(o) {
      var __a, __b, __c, node;
      return ((function() {
        __a = []; __b = this.expressions;
        for (__c = 0; __c < __b.length; __c++) {
          node = __b[__c];
          __a.push(this.compile_expression(node, dup(o)));
        }
        return __a;
      }).call(this)).join("\n");
    },
    // If this is the top-level Expressions, wrap everything in a safety closure.
    compile_root: function compile_root(o) {
      var code, indent;
      o.indent = (this.indent = (indent = o.no_wrap ? '' : TAB));
      o.scope = new Scope(null, this, null);
      code = o.globals ? this.compile_node(o) : this.compile_with_declarations(o);
      code = code.replace(TRAILING_WHITESPACE, '');
      return o.no_wrap ? code : "(function(){\n" + code + "\n})();";
    },
    // Compile the expressions body, with declarations of all inner variables
    // pushed up to the top.
    compile_with_declarations: function compile_with_declarations(o) {
      var args, argv, code;
      code = this.compile_node(o);
      args = this.contains(function(node) {
        return node instanceof ValueNode && node.arguments();
      });
      argv = args && o.scope.check('arguments') ? '' : 'var ';
      if (args) {
        code = this.idt() + argv + "arguments = Array.prototype.slice.call(arguments, 0);\n" + code;
      }
      if (o.scope.has_assignments(this)) {
        code = this.idt() + 'var ' + o.scope.compiled_assignments() + ";\n" + code;
      }
      if (o.scope.has_declarations(this)) {
        code = this.idt() + 'var ' + o.scope.compiled_declarations() + ";\n" + code;
      }
      return code;
    },
    // Compiles a single expression within the expressions body.
    compile_expression: function compile_expression(node, o) {
      var returns, stmt, temp;
      this.indent = o.indent;
      stmt = node.is_statement();
      // We need to return the result if this is the last node in the expressions body.
      returns = o.returns && this.is_last(node) && !node.is_statement_only();
      delete o.returns;
      // Return the regular compile of the node, unless we need to return the result.
      if (!(returns)) {
        return (stmt ? '' : this.idt()) + node.compile(merge(o, {
          top: true
        })) + (stmt ? '' : ';');
      }
      // If it's a statement, the node knows how to return itself.
      if (node.is_statement()) {
        return node.compile(merge(o, {
          returns: true
        }));
      }
      // If it's not part of a constructor, we can just return the value of the expression.
      if (!((o.scope.method == undefined ? undefined : o.scope.method.is_constructor()))) {
        return this.idt() + 'return ' + node.compile(o);
      }
      // It's the last line of a constructor, add a safety check.
      temp = o.scope.free_variable();
      return this.idt() + temp + ' = ' + node.compile(o) + ";\n" + this.idt() + "return " + o.scope.method.name + ' === this.constructor ? this : ' + temp + ';';
    }
  }));
  // Wrap up a node as an Expressions, unless it already is one.
  Expressions.wrap = function wrap(nodes) {
    if (nodes.length === 1 && nodes[0] instanceof Expressions) {
      return nodes[0];
    }
    return new Expressions(nodes);
  };
  statement(Expressions);
  // Literals are static values that can be passed through directly into
  // JavaScript without translation, eg.: strings, numbers, true, false, null...
  LiteralNode = (exports.LiteralNode = inherit(Node, {
    constructor: function constructor(value) {
      this.value = value;
      return this.children = [value];
    },
    // Break and continue must be treated as statements -- they lose their meaning
    // when wrapped in a closure.
    is_statement: function is_statement() {
      return this.value === 'break' || this.value === 'continue';
    },
    compile_node: function compile_node(o) {
      var end, idt;
      idt = this.is_statement() ? this.idt() : '';
      end = this.is_statement() ? ';' : '';
      return idt + this.value + end;
    }
  }));
  LiteralNode.prototype.is_statement_only = LiteralNode.prototype.is_statement;
})();