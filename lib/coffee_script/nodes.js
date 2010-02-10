(function(){
  var AccessorNode, ArrayNode, AssignNode, CallNode, ClosureNode, CodeNode, CommentNode, Expressions, ExtendsNode, IndexNode, LiteralNode, Node, ObjectNode, PushNode, RangeNode, ReturnNode, SliceNode, SplatNode, TAB, TRAILING_WHITESPACE, ThisNode, ValueNode, any, compact, del, dup, flatten, inherit, merge, statement;
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
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    return this.values = arguments;
  };
  exports.LiteralNode = function LiteralNode() {
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    return this.values = arguments;
  };
  exports.ReturnNode = function ReturnNode() {
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    return this.values = arguments;
  };
  exports.CommentNode = function CommentNode() {
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    return this.values = arguments;
  };
  exports.CallNode = function CallNode() {
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    return this.values = arguments;
  };
  exports.ExtendsNode = function ExtendsNode() {
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    return this.values = arguments;
  };
  exports.ValueNode = function ValueNode() {
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    return this.values = arguments;
  };
  exports.AccessorNode = function AccessorNode() {
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    return this.values = arguments;
  };
  exports.IndexNode = function IndexNode() {
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    return this.values = arguments;
  };
  exports.RangeNode = function RangeNode() {
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    return this.values = arguments;
  };
  exports.SliceNode = function SliceNode() {
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    return this.values = arguments;
  };
  exports.ThisNode = function ThisNode() {
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    return this.values = arguments;
  };
  exports.AssignNode = function AssignNode() {
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    return this.values = arguments;
  };
  exports.OpNode = function OpNode() {
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    return this.values = arguments;
  };
  exports.CodeNode = function CodeNode() {
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    return this.values = arguments;
  };
  exports.SplatNode = function SplatNode() {
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    return this.values = arguments;
  };
  exports.ObjectNode = function ObjectNode() {
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    return this.values = arguments;
  };
  exports.ArrayNode = function ArrayNode() {
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    return this.values = arguments;
  };
  exports.PushNode = function PushNode() {
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    return this.values = arguments;
  };
  exports.ClosureNode = function ClosureNode() {
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    return this.values = arguments;
  };
  exports.WhileNode = function WhileNode() {
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    return this.values = arguments;
  };
  exports.ForNode = function ForNode() {
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    return this.values = arguments;
  };
  exports.TryNode = function TryNode() {
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    return this.values = arguments;
  };
  exports.ThrowNode = function ThrowNode() {
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    return this.values = arguments;
  };
  exports.ExistenceNode = function ExistenceNode() {
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    return this.values = arguments;
  };
  exports.ParentheticalNode = function ParentheticalNode() {
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    return this.values = arguments;
  };
  exports.IfNode = function IfNode() {
    var arguments = Array.prototype.slice.call(arguments, 0);
    this.name = this.constructor.name;
    return this.values = arguments;
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
    var __a, __b, item, memo;
    memo = [];
    __a = list;
    for (__b = 0; __b < __a.length; __b++) {
      item = __a[__b];
      if (item instanceof Array) {
        return memo.concat(flatten(item));
      }
      memo.push(item);
      memo;
    }
    return memo;
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
    var __a, key, val;
    __a = src;
    for (key in __a) {
      val = __a[key];
      if (__hasProp.call(__a, key)) {
        ((dest[key] = val));
      }
    }
    return dest;
  };
  // Do any of the elements in the list pass a truth test?
  any = function any(list, test) {
    var __a, __b, __c, item, result;
    result = (function() {
      __a = []; __b = list;
      for (__c = 0; __c < __b.length; __c++) {
        item = __b[__c];
        if (test(item)) {
          __a.push(true);
        }
      }
      return __a;
    }).call(this);
    return !!result.length;
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
    klass = del(props, 'constructor');
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
    if (only) {
      return ((klass.prototype.is_statement_only = function is_statement_only() {
        return true;
      }));
    }
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
    top = this.top_sensitive() ? o.top : del(o, 'top');
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
    idt = (this.indent || '');
    __c = 0; __d = (tabs || 0);
    for (__b=0, i=__c; (__c <= __d ? i < __d : i > __d); (__c <= __d ? i += 1 : i -= 1), __b++) {
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
      this.children = (this.expressions = flatten(nodes));
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
      this.last_index = this.last_index || this.expressions[l - 1] instanceof CommentNode ? 2 : 1;
      return node === this.expressions[l - this.last_index];
    },
    compile: function compile(o) {
      o = o || {
      };
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
        return node instanceof ValueNode && node.is_arguments();
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
      var returns, stmt;
      this.indent = o.indent;
      stmt = node.is_statement();
      // We need to return the result if this is the last node in the expressions body.
      returns = del(o, 'returns') && this.is_last(node) && !node.is_statement_only();
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
      // Otherwise, we can just return the value of the expression.
      return this.idt() + 'return ' + node.compile(o) + ';';
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
      this.children = [(this.value = value)];
      return this;
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
  // Return an expression, or wrap it in a closure and return it.
  ReturnNode = (exports.ReturnNode = inherit(Node, {
    constructor: function constructor(expression) {
      this.children = [(this.expression = expression)];
      return this;
    },
    compile_node: function compile_node(o) {
      if (this.expression.is_statement()) {
        return this.expression.compile(merge(o, {
          returns: true
        }));
      }
      return this.idt() + 'return ' + this.expression.compile(o) + ';';
    }
  }));
  statement(ReturnNode, true);
  // A value, indexed or dotted into, or vanilla.
  ValueNode = (exports.ValueNode = inherit(Node, {
    SOAK: " == undefined ? undefined : ",
    constructor: function constructor(base, properties) {
      this.children = flatten((this.base = base), (this.properties = (properties || [])));
      return this;
    },
    push: function push(prop) {
      this.properties.push(prop);
      this.children.push(prop);
      return this;
    },
    has_properties: function has_properties() {
      return this.properties.length || this.base instanceof ThisNode;
    },
    is_array: function is_array() {
      return this.base instanceof ArrayNode && !this.has_properties();
    },
    is_object: function is_object() {
      return this.base instanceof ObjectNode && !this.has_properties();
    },
    is_splice: function is_splice() {
      return this.has_properties() && this.properties[this.properties.length - 1] instanceof SliceNode;
    },
    is_arguments: function is_arguments() {
      return this.base === 'arguments';
    },
    unwrap: function unwrap() {
      return this.properties.length ? this : this.base;
    },
    // Values are statements if their base is a statement.
    is_statement: function is_statement() {
      return this.base.is_statement && this.base.is_statement() && !this.has_properties();
    },
    compile_node: function compile_node(o) {
      var __a, __b, baseline, code, only, part, parts, prop, props, soaked, temp;
      soaked = false;
      only = del(o, 'only_first');
      props = only ? this.properties.slice(0, this.properties.length) : this.properties;
      baseline = this.base.compile(o);
      parts = [baseline];
      __a = props;
      for (__b = 0; __b < __a.length; __b++) {
        prop = __a[__b];
        if (prop instanceof AccessorNode && prop.soak) {
          soaked = true;
          if (this.base instanceof CallNode && prop === props[0]) {
            temp = o.scope.free_variable();
            parts[parts.length - 1] = '(' + temp + ' = ' + baseline + ')' + this.SOAK + ((baseline = temp + prop.compile(o)));
          } else {
            parts[parts.length - 1] = this.SOAK + (baseline += prop.compile(o));
          }
        } else {
          part = prop.compile(o);
          baseline += part;
          parts.push(part);
        }
      }
      this.last = parts[parts.length - 1];
      this.source = parts.length > 1 ? parts.slice(0, parts.length).join('') : null;
      code = parts.join('').replace(/\)\(\)\)/, '()))');
      if (!(soaked)) {
        return code;
      }
      return '(' + code + ')';
    }
  }));
  // Pass through CoffeeScript comments into JavaScript comments at the
  // same position.
  CommentNode = (exports.CommentNode = inherit(Node, {
    constructor: function constructor(lines) {
      this.lines = lines;
      return this;
    },
    compile_node: function compile_node(o) {
      var delimiter;
      delimiter = "\n" + this.idt() + '//';
      return delimiter + this.lines.join(delimiter);
    }
  }));
  statement(CommentNode);
  // Node for a function invocation. Takes care of converting super() calls into
  // calls against the prototype's function of the same name.
  CallNode = (exports.CallNode = inherit(Node, {
    constructor: function constructor(variable, args) {
      this.children = flatten([(this.variable = variable), (this.args = (args || []))]);
      this.prefix = '';
      return this;
    },
    new_instance: function new_instance() {
      this.prefix = 'new ';
      return this;
    },
    push: function push(arg) {
      this.args.push(arg);
      this.children.push(arg);
      return this;
    },
    // Compile a vanilla function call.
    compile_node: function compile_node(o) {
      var __a, __b, __c, arg, args;
      if (any(this.args, function(a) {
        return a instanceof SplatNode;
      })) {
        return this.compile_splat(o);
      }
      args = ((function() {
        __a = []; __b = this.args;
        for (__c = 0; __c < __b.length; __c++) {
          arg = __b[__c];
          __a.push(arg.compile(o));
        }
        return __a;
      }).call(this)).join(', ');
      if (this.variable === 'super') {
        return this.compile_super(args, o);
      }
      return this.prefix + this.variable.compile(o) + '(' + args + ')';
    },
    // Compile a call against the superclass's implementation of the current function.
    compile_super: function compile_super(args, o) {
      var arg_part, meth, methname;
      methname = o.scope.method.name;
      arg_part = args.length ? ', ' + args : '';
      meth = o.scope.method.proto ? o.scope.method.proto + '.__superClass__.' + methname : methname + '.__superClass__.constructor';
      return meth + '.call(this' + arg_part + ')';
    },
    // Compile a function call being passed variable arguments.
    compile_splat: function compile_splat(o) {
      var __a, __b, arg, args, code, i, meth, obj;
      meth = this.variable.compile(o);
      obj = this.variable.source || 'this';
      args = (function() {
        __a = []; __b = this.args;
        for (i = 0; i < __b.length; i++) {
          arg = __b[i];
          __a.push((function() {
            code = arg.compile(o);
            code = arg instanceof SplatNode ? code : '[' + code + ']';
            return i === 0 ? code : '.concat(' + code + ')';
          }).call(this));
        }
        return __a;
      }).call(this);
      return this.prefix + meth + '.apply(' + obj + ', ' + args.join('') + ')';
    },
    // If the code generation wished to use the result of a function call
    // in multiple places, ensure that the function is only ever called once.
    compile_reference: function compile_reference(o) {
      var call, reference;
      reference = o.scope.free_variable();
      call = new ParentheticalNode(new AssignNode(reference, this));
      return [call, reference];
    }
  }));
  // Node to extend an object's prototype with an ancestor object.
  // After goog.inherits from the Closure Library.
  ExtendsNode = (exports.ExtendsNode = inherit(Node, {
    constructor: function constructor(child, parent) {
      this.children = [(this.child = child), (this.parent = parent)];
      return this;
    },
    // Hooking one constructor into another's prototype chain.
    compile_node: function compile_node(o) {
      var child, constructor, parent;
      constructor = o.scope.free_variable();
      child = this.child.compile(o);
      parent = this.parent.compile(o);
      return this.idt() + constructor + ' = function(){};\n' + this.idt() + constructor + '.prototype = ' + parent + ".prototype;\n" + this.idt() + child + '.__superClass__ = ' + parent + ".prototype;\n" + this.idt() + child + '.prototype = new ' + constructor + "();\n" + this.idt() + child + '.prototype.constructor = ' + child + ';';
    }
  }));
  statement(ExtendsNode);
  // A dotted accessor into a part of a value, or the :: shorthand for
  // an accessor into the object's prototype.
  AccessorNode = (exports.AccessorNode = inherit(Node, {
    constructor: function constructor(name, tag) {
      this.children = [(this.name = name)];
      this.prototype = tag === 'prototype';
      this.soak = tag === 'soak';
      return this;
    },
    compile_node: function compile_node(o) {
      return '.' + (this.prototype ? 'prototype.' : '') + this.name.compile(o);
    }
  }));
  // An indexed accessor into a part of an array or object.
  IndexNode = (exports.IndexNode = inherit(Node, {
    constructor: function constructor(index) {
      this.children = [(this.index = index)];
      return this;
    },
    compile_node: function compile_node(o) {
      return '[' + this.index.compile(o) + ']';
    }
  }));
  // A this-reference, using '@'.
  ThisNode = (exports.ThisNode = inherit(Node, {
    constructor: function constructor(property) {
      this.property = property || null;
      return this;
    },
    compile_node: function compile_node(o) {
      return 'this' + (this.property ? '.' + this.property : '');
    }
  }));
  // A range literal. Ranges can be used to extract portions (slices) of arrays,
  // or to specify a range for list comprehensions.
  RangeNode = (exports.RangeNode = inherit(Node, {
    constructor: function constructor(from, to, exclusive) {
      this.children = [(this.from = from), (this.to = to)];
      this.exclusive = !!exclusive;
      return this;
    },
    compile_variables: function compile_variables(o) {
      this.indent = o.indent;
      this.from_var = o.scope.free_variable();
      this.to_var = o.scope.free_variable();
      return this.from_var + ' = ' + this.from.compile(o) + '; ' + this.to_var + ' = ' + this.to.compile(o) + ";\n" + this.idt();
    },
    compile_node: function compile_node(o) {
      var compare, equals, idx, incr, intro, step;
      if (!(o.index)) {
        return this.compile_array(o);
      }
      idx = del(o, 'index');
      step = del(o, 'step');
      equals = this.exclusive ? '' : '=';
      intro = '(' + this.from_var + ' <= ' + this.to_var + ' ? ' + idx;
      compare = intro + ' <' + equals + ' ' + this.to_var + ' : ' + idx + ' >' + equals + ' ' + this.to_var + ')';
      incr = intro + ' += ' + step + ' : ' + idx + ' -= ' + step + ')';
      return vars + '; ' + compare + '; ' + incr;
    },
    // Expand the range into the equivalent array, if it's not being used as
    // part of a comprehension, slice, or splice.
    // TODO: This generates pretty ugly code ... shrink it.
    compile_array: function compile_array(o) {
      var arr, body;
      body = Expressions.wrap(new LiteralNode('i'));
      arr = Expressions.wrap(new ForNode(body, {
        source: (new ValueNode(this))
      }, 'i'));
      return (new ParentheticalNode(new CallNode(new CodeNode([], arr)))).compile(o);
    }
  }));
  // An array slice literal. Unlike JavaScript's Array#slice, the second parameter
  // specifies the index of the end of the slice (just like the first parameter)
  // is the index of the beginning.
  SliceNode = (exports.SliceNode = inherit(Node, {
    constructor: function constructor(range) {
      this.children = [(this.range = range)];
      return this;
    },
    compile_node: function compile_node(o) {
      var from, plus_part, to;
      from = this.range.from.compile(o);
      to = this.range.to.compile(o);
      plus_part = this.range.exclusive ? '' : ' + 1';
      return ".slice(" + from + ', ' + to + plus_part + ')';
    }
  }));
  // An object literal.
  ObjectNode = (exports.ObjectNode = inherit(Node, {
    constructor: function constructor(props) {
      this.objects = (this.properties = props || []);
      return this;
    },
    // All the mucking about with commas is to make sure that CommentNodes and
    // AssignNodes get interleaved correctly, with no trailing commas or
    // commas affixed to comments. TODO: Extract this and add it to ArrayNode.
    compile_node: function compile_node(o) {
      var __a, __b, __c, __d, __e, i, indent, join, last_noncom, non_comments, prop, props;
      o.indent = this.idt(1);
      non_comments = (function() {
        __a = []; __b = this.properties;
        for (__c = 0; __c < __b.length; __c++) {
          prop = __b[__c];
          if (!(prop instanceof CommentNode)) {
            __a.push(prop);
          }
        }
        return __a;
      }).call(this);
      last_noncom = non_comments[non_comments.length - 1];
      props = (function() {
        __d = []; __e = this.properties;
        for (i = 0; i < __e.length; i++) {
          prop = __e[i];
          __d.push((function() {
            join = ",\n";
            if (prop === last_noncom || prop instanceof CommentNode) {
              join = "\n";
            }
            if (i === non_comments.length - 1) {
              join = '';
            }
            indent = prop instanceof CommentNode ? '' : this.idt(1);
            return indent + prop.compile(o) + join;
          }).call(this));
        }
        return __d;
      }).call(this);
      return '{\n' + props.join('') + '\n' + this.idt() + '}';
    }
  }));
  // An array literal.
  ArrayNode = (exports.ArrayNode = inherit(Node, {
    constructor: function constructor(objects) {
      this.children = (this.objects = objects || []);
      return this;
    },
    compile_node: function compile_node(o) {
      var __a, __b, code, ending, i, obj, objects;
      o.indent = this.idt(1);
      objects = (function() {
        __a = []; __b = this.objects;
        for (i = 0; i < __b.length; i++) {
          obj = __b[i];
          __a.push((function() {
            code = obj.compile(o);
            if (obj instanceof CommentNode) {
              return '\n' + code + '\n' + o.indent;
            } else if (i === this.objects.length - 1) {
              return code;
            } else {
              return code + ', ';
            }
          }).call(this));
        }
        return __a;
      }).call(this);
      objects = objects.join('');
      ending = objects.indexOf('\n') >= 0 ? "\n" + this.idt() + ']' : ']';
      return '[' + objects + ending;
    }
  }));
  // A faux-node that is never created by the grammar, but is used during
  // code generation to generate a quick "array.push(value)" tree of nodes.
  PushNode = (exports.PushNode = {
    wrap: function wrap(array, expressions) {
      var expr;
      expr = expressions.unwrap();
      if (expr.is_statement_only() || expr.contains(function(n) {
        return n.is_statement_only();
      })) {
        return expressions;
      }
      return Expressions.wrap(new CallNode(new ValueNode(new LiteralNode(array), [new AccessorNode(new LiteralNode('push'))]), [expr]));
    }
  });
  // A faux-node used to wrap an expressions body in a closure.
  ClosureNode = (exports.ClosureNode = {
    wrap: function wrap(expressions, statement) {
      var call, func;
      func = new ParentheticalNode(new CodeNode([], Expressions.wrap(expressions)));
      call = new CallNode(new ValueNode(func, new AccessorNode(new LiteralNode('call'))), [new LiteralNode('this')]);
      return statement ? Expressions.wrap(call) : call;
    }
  });
  // Setting the value of a local variable, or the value of an object property.
  AssignNode = (exports.AssignNode = inherit(Node, {
    // Keep the identifier regex in sync with the Lexer.
    IDENTIFIER: /^([a-zA-Z$_](\w|\$)*)/,
    PROTO_ASSIGN: /^(\S+)\.prototype/,
    LEADING_DOT: /^\.(prototype\.)?/,
    constructor: function constructor(variable, value, context) {
      this.children = [(this.variable = variable), (this.value = value)];
      this.context = context;
      return this;
    },
    top_sensitive: function top_sensitive() {
      return true;
    },
    is_value: function is_value() {
      return this.variable instanceof ValueNode;
    },
    is_statement: function is_statement() {
      return this.is_value() && (this.variable.is_array() || this.variable.is_object());
    },
    compile_node: function compile_node(o) {
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
        if (last.match(this.IDENTIFIER)) {
          this.value.name = last;
        }
        if (proto) {
          this.value.proto = proto;
        }
      }
      if (this.context === 'object') {
        return name + ': ' + this.value.compile(o);
      }
      if (!(this.is_value() && this.variable.has_properties())) {
        o.scope.find(name);
      }
      val = name + ' = ' + this.value.compile(o);
      if (stmt) {
        return this.idt() + val + ';';
      }
      if (!top || o.returns) {
        val = '(' + val + ')';
      }
      if (o.returns) {
        val = this.idt() + 'return ' + val;
      }
      return val;
    },
    // Implementation of recursive pattern matching, when assigning array or
    // object literals to a value. Peeks at their properties to assign inner names.
    // See: http://wiki.ecmascript.org/doku.php?id=harmony:destructuring
    compile_pattern_match: function compile_pattern_match(o) {
      var __a, __b, access_class, assigns, i, obj, val, val_var;
      val_var = o.scope.free_variable();
      assigns = [this.idt() + val_var + ' = ' + this.value.compile(o) + ';'];
      o.top = true;
      o.as_statement = true;
      __a = this.variable.base.objects;
      for (i = 0; i < __a.length; i++) {
        obj = __a[i];
        if (this.variable.is_object()) {
          __b = [obj.value, obj.variable.base];
          obj = __b[0];
          i = __b[1];
        }
        access_class = this.variable.is_array() ? IndexNode : AccessorNode;
        obj instanceof SplatNode ? (val = new LiteralNode(obj.compile_value(o, val_var, this.variable.base.objects.indexOf(obj)))) : (val = new ValueNode(val_var, [new access_class(new LiteralNode(i))]));
        assigns.push(new AssignNode(obj, val).compile(o));
      }
      return assigns.join("\n");
    },
    compile_splice: function compile_splice(o) {
      var from, name, plus, range, to;
      name = this.variable.compile(merge(o, {
        only_first: true
      }));
      range = this.variable.properties.last.range;
      plus = range.exclusive ? '' : ' + 1';
      from = range.from.compile(o);
      to = range.to.compile(o) + ' - ' + from + plus;
      return name + '.splice.apply(' + name + ', [' + from + ', ' + to + '].concat(' + this.value.compile(o) + '))';
    }
  }));
  // A function definition. The only node that creates a new Scope.
  // A CodeNode does not have any children -- they're within the new scope.
  CodeNode = (exports.CodeNode = inherit(Node, {
    constructor: function constructor(params, body, tag) {
      this.params = params;
      this.body = body;
      this.bound = tag === 'boundfunc';
      return this;
    },
    compile_node: function compile_node(o) {
      var __a, __b, code, func, inner, name_part, param, shared_scope, splat, top;
      shared_scope = del(o, 'shared_scope');
      top = del(o, 'top');
      o.scope = shared_scope || new Scope(o.scope, this.body, this);
      o.returns = true;
      o.top = true;
      o.indent = this.idt(this.bound ? 2 : 1);
      del(o, 'no_wrap');
      del(o, 'globals');
      if (this.params[this.params.length - 1] instanceof SplatNode) {
        splat = this.params.pop();
        splat.index = this.params.length;
        this.body.unshift(splat);
      }
      __a = this.params;
      for (__b = 0; __b < __a.length; __b++) {
        param = __a[__b];
        (o.scope.parameter(param));
      }
      code = this.body.expressions.length ? '\n' + this.body.compile_with_declarations(o) + '\n' : '';
      name_part = this.name ? ' ' + this.name : '';
      func = 'function' + (this.bound ? '' : name_part) + '(' + this.params.join(', ') + ') {' + code + this.idt(this.bound ? 1 : 0) + '}';
      if (top && !this.bound) {
        func = '(' + func + ')';
      }
      if (!(this.bound)) {
        return func;
      }
      inner = '(function' + name_part + '() {\n' + this.idt(2) + 'return __func.apply(__this, arguments);\n' + this.idt(1) + '});';
      return '(function(__this) {\n' + this.idt(1) + 'var __func = ' + func + ';\n' + this.idt(1) + 'return ' + inner + '\n' + this.idt() + '})(this)';
    },
    top_sensitive: function top_sensitive() {
      return true;
    }
  }));
  // A splat, either as a parameter to a function, an argument to a call,
  // or in a destructuring assignment.
  SplatNode = (exports.SplatNode = inherit(Node, {
    constructor: function constructor(name) {
      this.children = [(this.name = name)];
      return this;
    },
    compile_node: function compile_node(o) {
      return this.index ? this.compile_param(o) : this.name.compile(o);
    },
    compile_param: function compile_param(o) {
      o.scope.find(this.name);
      return this.name + ' = Array.prototype.slice.call(arguments, ' + this.index + ')';
    },
    compile_value: function compile_value(o, name, index) {
      return "Array.prototype.slice.call(" + this.name + ', ' + this.index + ')';
    }
  }));
})();