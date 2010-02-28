(function(){
  var AccessorNode, ArrayNode, AssignNode, BaseNode, CallNode, ClassNode, ClosureNode, CodeNode, CommentNode, ExistenceNode, Expressions, ExtendsNode, ForNode, IDENTIFIER, IfNode, IndexNode, LiteralNode, ObjectNode, OpNode, ParentheticalNode, PushNode, RangeNode, ReturnNode, SliceNode, SplatNode, TAB, TRAILING_WHITESPACE, ThrowNode, TryNode, ValueNode, WhileNode, _a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, _s, _t, _u, _v, _w, _x, _y, compact, del, flatten, inherit, merge, statement;
  var __hasProp = Object.prototype.hasOwnProperty;
  (typeof process !== "undefined" && process !== null) ? process.mixin(require('scope')) : (this.exports = this);
  // Some helper functions
  // Tabs are two spaces for pretty printing.
  TAB = '  ';
  TRAILING_WHITESPACE = /\s+$/gm;
  // Keep the identifier regex in sync with the Lexer.
  IDENTIFIER = /^[a-zA-Z$_](\w|\$)*$/;
  // Merge objects.
  merge = function merge(options, overrides) {
    var _a, _b, fresh, key, val;
    fresh = {};
    _a = options;
    for (key in _a) { if (__hasProp.call(_a, key)) {
      val = _a[key];
      ((fresh[key] = val));
    }}
    if (overrides) {
      _b = overrides;
      for (key in _b) { if (__hasProp.call(_b, key)) {
        val = _b[key];
        ((fresh[key] = val));
      }}
    }
    return fresh;
  };
  // Trim out all falsy values from an array.
  compact = function compact(array) {
    var _a, _b, _c, _d, item;
    _a = []; _b = array;
    for (_c = 0, _d = _b.length; _c < _d; _c++) {
      item = _b[_c];
      if (item) {
        _a.push(item);
      }
    }
    return _a;
  };
  // Return a completely flattened version of an array.
  flatten = function flatten(array) {
    var _a, _b, _c, item, memo;
    memo = [];
    _a = array;
    for (_b = 0, _c = _a.length; _b < _c; _b++) {
      item = _a[_b];
      item instanceof Array ? (memo = memo.concat(item)) : memo.push(item);
    }
    return memo;
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
    var _a, _b, klass, name, prop;
    klass = del(props, 'constructor');
    _a = function(){};
    _a.prototype = parent.prototype;
    klass.__superClass__ = parent.prototype;
    klass.prototype = new _a();
    klass.prototype.constructor = klass;
    _b = props;
    for (name in _b) { if (__hasProp.call(_b, name)) {
      prop = _b[name];
      ((klass.prototype[name] = prop));
    }}
    return klass;
  };
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
  exports.BaseNode = (function() {
    BaseNode = function BaseNode() {    };
    // This is extremely important -- we convert JS statements into expressions
    // by wrapping them in a closure, only if it's possible, and we're not at
    // the top level of a block (which would be unnecessary), and we haven't
    // already been asked to return the result.
    BaseNode.prototype.compile = function compile(o) {
      var closure, top;
      this.options = merge(o || {});
      this.indent = o.indent;
      if (!(this.operation_sensitive())) {
        del(this.options, 'operation');
      }
      top = this.top_sensitive() ? this.options.top : del(this.options, 'top');
      closure = this.is_statement() && !this.is_statement_only() && !top && !this.options.returns && !(this instanceof CommentNode) && !this.contains(function(node) {
        return node.is_statement_only();
      });
      return closure ? this.compile_closure(this.options) : this.compile_node(this.options);
    };
    // Statements converted into expressions share scope with their parent
    // closure, to preserve JavaScript-style lexical scope.
    BaseNode.prototype.compile_closure = function compile_closure(o) {
      this.indent = o.indent;
      o.shared_scope = o.scope;
      return ClosureNode.wrap(this).compile(o);
    };
    // If the code generation wishes to use the result of a complex expression
    // in multiple places, ensure that the expression is only ever evaluated once.
    BaseNode.prototype.compile_reference = function compile_reference(o) {
      var compiled, reference;
      reference = new LiteralNode(o.scope.free_variable());
      compiled = new AssignNode(reference, this);
      return [compiled, reference];
    };
    // Quick short method for the current indentation level, plus tabbing in.
    BaseNode.prototype.idt = function idt(tabs) {
      var _a, _b, _c, _d, i, idt;
      idt = (this.indent || '');
      _c = 0; _d = (tabs || 0);
      for (_b = 0, i = _c; (_c <= _d ? i < _d : i > _d); (_c <= _d ? i += 1 : i -= 1), _b++) {
        idt += TAB;
      }
      return idt;
    };
    // Does this node, or any of its children, contain a node of a certain kind?
    BaseNode.prototype.contains = function contains(block) {
      var _a, _b, _c, node;
      _a = this.children;
      for (_b = 0, _c = _a.length; _b < _c; _b++) {
        node = _a[_b];
        if (block(node)) {
          return true;
        }
        if (node.contains && node.contains(block)) {
          return true;
        }
      }
      return false;
    };
    // Perform an in-order traversal of the AST.
    BaseNode.prototype.traverse = function traverse(block) {
      var _a, _b, _c, _d, node;
      _a = []; _b = this.children;
      for (_c = 0, _d = _b.length; _c < _d; _c++) {
        node = _b[_c];
        _a.push((function() {
          block(node);
          if (node.traverse) {
            return node.traverse(block);
          }
        }).call(this));
      }
      return _a;
    };
    // toString representation of the node, for inspecting the parse tree.
    BaseNode.prototype.toString = function toString(idt) {
      var _a, _b, _c, _d, child;
      idt = idt || '';
      return '\n' + idt + this.type + (function() {
        _a = []; _b = this.children;
        for (_c = 0, _d = _b.length; _c < _d; _c++) {
          child = _b[_c];
          _a.push(child.toString(idt + TAB));
        }
        return _a;
      }).call(this).join('');
    };
    // Default implementations of the common node methods.
    BaseNode.prototype.unwrap = function unwrap() {
      return this;
    };
    BaseNode.prototype.children = [];
    BaseNode.prototype.is_statement = function is_statement() {
      return false;
    };
    BaseNode.prototype.is_statement_only = function is_statement_only() {
      return false;
    };
    BaseNode.prototype.top_sensitive = function top_sensitive() {
      return false;
    };
    BaseNode.prototype.operation_sensitive = function operation_sensitive() {
      return false;
    };
    return BaseNode;
  }).call(this);
  // A collection of nodes, each one representing an expression.
  exports.Expressions = (function() {
    Expressions = function Expressions(nodes) {
      this.children = (this.expressions = compact(flatten(nodes || [])));
      return this;
    };
    _a = function(){};
    _a.prototype = BaseNode.prototype;
    Expressions.__superClass__ = BaseNode.prototype;
    Expressions.prototype = new _a();
    Expressions.prototype.constructor = Expressions;
    Expressions.prototype.type = 'Expressions';
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
      var l, last_index;
      l = this.expressions.length;
      last_index = this.expressions[l - 1] instanceof CommentNode ? 2 : 1;
      return node === this.expressions[l - last_index];
    };
    Expressions.prototype.compile = function compile(o) {
      o = o || {};
      return o.scope ? BaseNode.prototype.compile.call(this, o) : this.compile_root(o);
    };
    // Compile each expression in the Expressions body.
    Expressions.prototype.compile_node = function compile_node(o) {
      var _a, _b, _c, _d, node;
      return (function() {
        _a = []; _b = this.expressions;
        for (_c = 0, _d = _b.length; _c < _d; _c++) {
          node = _b[_c];
          _a.push(this.compile_expression(node, merge(o)));
        }
        return _a;
      }).call(this).join("\n");
    };
    // If this is the top-level Expressions, wrap everything in a safety closure.
    Expressions.prototype.compile_root = function compile_root(o) {
      var code, indent;
      o.indent = (this.indent = (indent = o.no_wrap ? '' : TAB));
      o.scope = new Scope(null, this, null);
      code = o.globals ? this.compile_node(o) : this.compile_with_declarations(o);
      code = code.replace(TRAILING_WHITESPACE, '');
      return o.no_wrap ? code : "(function(){\n" + code + "\n})();\n";
    };
    // Compile the expressions body, with declarations of all inner variables
    // pushed up to the top.
    Expressions.prototype.compile_with_declarations = function compile_with_declarations(o) {
      var args, code;
      code = this.compile_node(o);
      args = this.contains(function(node) {
        return node instanceof ValueNode && node.is_arguments();
      });
      if (args) {
        code = this.idt() + "arguments = Array.prototype.slice.call(arguments, 0);\n" + code;
      }
      if (o.scope.has_assignments(this)) {
        code = this.idt() + 'var ' + o.scope.compiled_assignments() + ";\n" + code;
      }
      if (o.scope.has_declarations(this)) {
        code = this.idt() + 'var ' + o.scope.compiled_declarations() + ";\n" + code;
      }
      return code;
    };
    // Compiles a single expression within the expressions body.
    Expressions.prototype.compile_expression = function compile_expression(node, o) {
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
    };
    return Expressions;
  }).call(this);
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
  exports.LiteralNode = (function() {
    LiteralNode = function LiteralNode(value) {
      this.value = value;
      return this;
    };
    _b = function(){};
    _b.prototype = BaseNode.prototype;
    LiteralNode.__superClass__ = BaseNode.prototype;
    LiteralNode.prototype = new _b();
    LiteralNode.prototype.constructor = LiteralNode;
    LiteralNode.prototype.type = 'Literal';
    // Break and continue must be treated as statements -- they lose their meaning
    // when wrapped in a closure.
    LiteralNode.prototype.is_statement = function is_statement() {
      return this.value === 'break' || this.value === 'continue';
    };
    LiteralNode.prototype.is_statement_only = LiteralNode.prototype.is_statement;
    LiteralNode.prototype.compile_node = function compile_node(o) {
      var end, idt;
      idt = this.is_statement() ? this.idt() : '';
      end = this.is_statement() ? ';' : '';
      return idt + this.value + end;
    };
    LiteralNode.prototype.toString = function toString(idt) {
      return ' "' + this.value + '"';
    };
    return LiteralNode;
  }).call(this);
  // Return an expression, or wrap it in a closure and return it.
  exports.ReturnNode = (function() {
    ReturnNode = function ReturnNode(expression) {
      this.children = [(this.expression = expression)];
      return this;
    };
    _c = function(){};
    _c.prototype = BaseNode.prototype;
    ReturnNode.__superClass__ = BaseNode.prototype;
    ReturnNode.prototype = new _c();
    ReturnNode.prototype.constructor = ReturnNode;
    ReturnNode.prototype.type = 'Return';
    ReturnNode.prototype.compile_node = function compile_node(o) {
      if (this.expression.is_statement()) {
        return this.expression.compile(merge(o, {
          returns: true
        }));
      }
      return this.idt() + 'return ' + this.expression.compile(o) + ';';
    };
    return ReturnNode;
  }).call(this);
  statement(ReturnNode, true);
  // A value, indexed or dotted into, or vanilla.
  exports.ValueNode = (function() {
    ValueNode = function ValueNode(base, properties) {
      this.children = flatten([(this.base = base), (this.properties = (properties || []))]);
      return this;
    };
    _d = function(){};
    _d.prototype = BaseNode.prototype;
    ValueNode.__superClass__ = BaseNode.prototype;
    ValueNode.prototype = new _d();
    ValueNode.prototype.constructor = ValueNode;
    ValueNode.prototype.type = 'Value';
    ValueNode.prototype.SOAK = " == undefined ? undefined : ";
    ValueNode.prototype.push = function push(prop) {
      this.properties.push(prop);
      this.children.push(prop);
      return this;
    };
    ValueNode.prototype.operation_sensitive = function operation_sensitive() {
      return true;
    };
    ValueNode.prototype.has_properties = function has_properties() {
      return !!this.properties.length;
    };
    ValueNode.prototype.is_array = function is_array() {
      return this.base instanceof ArrayNode && !this.has_properties();
    };
    ValueNode.prototype.is_object = function is_object() {
      return this.base instanceof ObjectNode && !this.has_properties();
    };
    ValueNode.prototype.is_splice = function is_splice() {
      return this.has_properties() && this.properties[this.properties.length - 1] instanceof SliceNode;
    };
    ValueNode.prototype.is_arguments = function is_arguments() {
      return this.base.value === 'arguments';
    };
    ValueNode.prototype.unwrap = function unwrap() {
      return this.properties.length ? this : this.base;
    };
    // Values are statements if their base is a statement.
    ValueNode.prototype.is_statement = function is_statement() {
      return this.base.is_statement && this.base.is_statement() && !this.has_properties();
    };
    ValueNode.prototype.compile_node = function compile_node(o) {
      var _d, _e, _f, baseline, complete, only, op, part, prop, props, soaked, temp;
      soaked = false;
      only = del(o, 'only_first');
      op = del(o, 'operation');
      props = only ? this.properties.slice(0, this.properties.length - 1) : this.properties;
      baseline = this.base.compile(o);
      if (this.base instanceof ObjectNode && this.has_properties()) {
        baseline = '(' + baseline + ')';
      }
      complete = (this.last = baseline);
      _d = props;
      for (_e = 0, _f = _d.length; _e < _f; _e++) {
        prop = _d[_e];
        this.source = baseline;
        if (prop.soak_node) {
          soaked = true;
          if (this.base instanceof CallNode && prop === props[0]) {
            temp = o.scope.free_variable();
            complete = '(' + temp + ' = ' + complete + ')' + this.SOAK + ((baseline = temp + prop.compile(o)));
          } else {
            complete = complete + this.SOAK + (baseline += prop.compile(o));
          }
        } else {
          part = prop.compile(o);
          baseline += part;
          complete += part;
          this.last = part;
        }
      }
      return op && soaked ? '(' + complete + ')' : complete;
    };
    return ValueNode;
  }).call(this);
  // Pass through CoffeeScript comments into JavaScript comments at the
  // same position.
  exports.CommentNode = (function() {
    CommentNode = function CommentNode(lines) {
      this.lines = lines;
      this;
      return this;
    };
    _e = function(){};
    _e.prototype = BaseNode.prototype;
    CommentNode.__superClass__ = BaseNode.prototype;
    CommentNode.prototype = new _e();
    CommentNode.prototype.constructor = CommentNode;
    CommentNode.prototype.type = 'Comment';
    CommentNode.prototype.compile_node = function compile_node(o) {
      return this.idt() + '//' + this.lines.join('\n' + this.idt() + '//');
    };
    return CommentNode;
  }).call(this);
  statement(CommentNode);
  // Node for a function invocation. Takes care of converting super() calls into
  // calls against the prototype's function of the same name.
  exports.CallNode = (function() {
    CallNode = function CallNode(variable, args) {
      this.children = flatten([(this.variable = variable), (this.args = (args || []))]);
      this.prefix = '';
      return this;
    };
    _f = function(){};
    _f.prototype = BaseNode.prototype;
    CallNode.__superClass__ = BaseNode.prototype;
    CallNode.prototype = new _f();
    CallNode.prototype.constructor = CallNode;
    CallNode.prototype.type = 'Call';
    CallNode.prototype.new_instance = function new_instance() {
      this.prefix = 'new ';
      return this;
    };
    CallNode.prototype.push = function push(arg) {
      this.args.push(arg);
      this.children.push(arg);
      return this;
    };
    // Compile a vanilla function call.
    CallNode.prototype.compile_node = function compile_node(o) {
      var _f, _g, _h, _i, arg, args;
      if (this.args[this.args.length - 1] instanceof SplatNode) {
        return this.compile_splat(o);
      }
      args = (function() {
        _f = []; _g = this.args;
        for (_h = 0, _i = _g.length; _h < _i; _h++) {
          arg = _g[_h];
          _f.push(arg.compile(o));
        }
        return _f;
      }).call(this).join(', ');
      if (this.variable === 'super') {
        return this.compile_super(args, o);
      }
      return this.prefix + this.variable.compile(o) + '(' + args + ')';
    };
    // Compile a call against the superclass's implementation of the current function.
    CallNode.prototype.compile_super = function compile_super(args, o) {
      var arg_part, meth, methname;
      methname = o.scope.method.name;
      arg_part = args.length ? ', ' + args : '';
      meth = o.scope.method.proto ? o.scope.method.proto + '.__superClass__.' + methname : methname + '.__superClass__.constructor';
      return meth + '.call(this' + arg_part + ')';
    };
    // Compile a function call being passed variable arguments.
    CallNode.prototype.compile_splat = function compile_splat(o) {
      var _f, _g, _h, arg, args, code, i, meth, obj, temp;
      meth = this.variable.compile(o);
      obj = this.variable.source || 'this';
      if (obj.match(/\(/)) {
        temp = o.scope.free_variable();
        obj = temp;
        meth = '(' + temp + ' = ' + this.variable.source + ')' + this.variable.last;
      }
      args = (function() {
        _f = []; _g = this.args;
        for (i = 0, _h = _g.length; i < _h; i++) {
          arg = _g[i];
          _f.push((function() {
            code = arg.compile(o);
            code = arg instanceof SplatNode ? code : '[' + code + ']';
            return i === 0 ? code : '.concat(' + code + ')';
          }).call(this));
        }
        return _f;
      }).call(this);
      return this.prefix + meth + '.apply(' + obj + ', ' + args.join('') + ')';
    };
    return CallNode;
  }).call(this);
  // Node to extend an object's prototype with an ancestor object.
  // After goog.inherits from the Closure Library.
  exports.ExtendsNode = (function() {
    ExtendsNode = function ExtendsNode(child, parent) {
      this.children = [(this.child = child), (this.parent = parent)];
      return this;
    };
    _g = function(){};
    _g.prototype = BaseNode.prototype;
    ExtendsNode.__superClass__ = BaseNode.prototype;
    ExtendsNode.prototype = new _g();
    ExtendsNode.prototype.constructor = ExtendsNode;
    ExtendsNode.prototype.type = 'Extends';
    // Hooking one constructor into another's prototype chain.
    ExtendsNode.prototype.compile_node = function compile_node(o) {
      var child, child_var, construct, parent, parent_var, prefix;
      construct = o.scope.free_variable();
      child = this.child.compile(o);
      parent = this.parent.compile(o);
      prefix = '';
      if (!(this.child instanceof ValueNode) || this.child.has_properties() || !(this.child.unwrap() instanceof LiteralNode)) {
        child_var = o.scope.free_variable();
        prefix += this.idt() + child_var + ' = ' + child + ';\n';
        child = child_var;
      }
      if (!(this.parent instanceof ValueNode) || this.parent.has_properties() || !(this.parent.unwrap() instanceof LiteralNode)) {
        parent_var = o.scope.free_variable();
        prefix += this.idt() + parent_var + ' = ' + parent + ';\n';
        parent = parent_var;
      }
      return prefix + this.idt() + construct + ' = function(){};\n' + this.idt() + construct + '.prototype = ' + parent + ".prototype;\n" + this.idt() + child + '.__superClass__ = ' + parent + ".prototype;\n" + this.idt() + child + '.prototype = new ' + construct + "();\n" + this.idt() + child + '.prototype.constructor = ' + child + ';';
    };
    return ExtendsNode;
  }).call(this);
  statement(ExtendsNode);
  // A dotted accessor into a part of a value, or the :: shorthand for
  // an accessor into the object's prototype.
  exports.AccessorNode = (function() {
    AccessorNode = function AccessorNode(name, tag) {
      this.children = [(this.name = name)];
      this.prototype = tag === 'prototype';
      this.soak_node = tag === 'soak';
      this;
      return this;
    };
    _h = function(){};
    _h.prototype = BaseNode.prototype;
    AccessorNode.__superClass__ = BaseNode.prototype;
    AccessorNode.prototype = new _h();
    AccessorNode.prototype.constructor = AccessorNode;
    AccessorNode.prototype.type = 'Accessor';
    AccessorNode.prototype.compile_node = function compile_node(o) {
      return '.' + (this.prototype ? 'prototype.' : '') + this.name.compile(o);
    };
    return AccessorNode;
  }).call(this);
  // An indexed accessor into a part of an array or object.
  exports.IndexNode = (function() {
    IndexNode = function IndexNode(index, tag) {
      this.children = [(this.index = index)];
      this.soak_node = tag === 'soak';
      return this;
    };
    _i = function(){};
    _i.prototype = BaseNode.prototype;
    IndexNode.__superClass__ = BaseNode.prototype;
    IndexNode.prototype = new _i();
    IndexNode.prototype.constructor = IndexNode;
    IndexNode.prototype.type = 'Index';
    IndexNode.prototype.compile_node = function compile_node(o) {
      return '[' + this.index.compile(o) + ']';
    };
    return IndexNode;
  }).call(this);
  // A range literal. Ranges can be used to extract portions (slices) of arrays,
  // or to specify a range for list comprehensions.
  exports.RangeNode = (function() {
    RangeNode = function RangeNode(from, to, exclusive) {
      this.children = [(this.from = from), (this.to = to)];
      this.exclusive = !!exclusive;
      return this;
    };
    _j = function(){};
    _j.prototype = BaseNode.prototype;
    RangeNode.__superClass__ = BaseNode.prototype;
    RangeNode.prototype = new _j();
    RangeNode.prototype.constructor = RangeNode;
    RangeNode.prototype.type = 'Range';
    RangeNode.prototype.compile_variables = function compile_variables(o) {
      this.indent = o.indent;
      this.from_var = o.scope.free_variable();
      this.to_var = o.scope.free_variable();
      return this.from_var + ' = ' + this.from.compile(o) + '; ' + this.to_var + ' = ' + this.to.compile(o) + ";\n" + this.idt();
    };
    RangeNode.prototype.compile_node = function compile_node(o) {
      var compare, equals, idx, incr, intro, step, vars;
      if (!(o.index)) {
        return this.compile_array(o);
      }
      idx = del(o, 'index');
      step = del(o, 'step');
      vars = idx + ' = ' + this.from_var;
      step = step ? step.compile(o) : '1';
      equals = this.exclusive ? '' : '=';
      intro = '(' + this.from_var + ' <= ' + this.to_var + ' ? ' + idx;
      compare = intro + ' <' + equals + ' ' + this.to_var + ' : ' + idx + ' >' + equals + ' ' + this.to_var + ')';
      incr = intro + ' += ' + step + ' : ' + idx + ' -= ' + step + ')';
      return vars + '; ' + compare + '; ' + incr;
    };
    // Expand the range into the equivalent array, if it's not being used as
    // part of a comprehension, slice, or splice.
    // TODO: This generates pretty ugly code ... shrink it.
    RangeNode.prototype.compile_array = function compile_array(o) {
      var arr, body, name;
      name = o.scope.free_variable();
      body = Expressions.wrap([new LiteralNode(name)]);
      arr = Expressions.wrap([new ForNode(body, {
          source: (new ValueNode(this))
        }, new LiteralNode(name))
      ]);
      return (new ParentheticalNode(new CallNode(new CodeNode([], arr)))).compile(o);
    };
    return RangeNode;
  }).call(this);
  // An array slice literal. Unlike JavaScript's Array#slice, the second parameter
  // specifies the index of the end of the slice (just like the first parameter)
  // is the index of the beginning.
  exports.SliceNode = (function() {
    SliceNode = function SliceNode(range) {
      this.children = [(this.range = range)];
      this;
      return this;
    };
    _k = function(){};
    _k.prototype = BaseNode.prototype;
    SliceNode.__superClass__ = BaseNode.prototype;
    SliceNode.prototype = new _k();
    SliceNode.prototype.constructor = SliceNode;
    SliceNode.prototype.type = 'Slice';
    SliceNode.prototype.compile_node = function compile_node(o) {
      var from, plus_part, to;
      from = this.range.from.compile(o);
      to = this.range.to.compile(o);
      plus_part = this.range.exclusive ? '' : ' + 1';
      return ".slice(" + from + ', ' + to + plus_part + ')';
    };
    return SliceNode;
  }).call(this);
  // An object literal.
  exports.ObjectNode = (function() {
    ObjectNode = function ObjectNode(props) {
      this.children = (this.objects = (this.properties = props || []));
      return this;
    };
    _l = function(){};
    _l.prototype = BaseNode.prototype;
    ObjectNode.__superClass__ = BaseNode.prototype;
    ObjectNode.prototype = new _l();
    ObjectNode.prototype.constructor = ObjectNode;
    ObjectNode.prototype.type = 'Object';
    // All the mucking about with commas is to make sure that CommentNodes and
    // AssignNodes get interleaved correctly, with no trailing commas or
    // commas affixed to comments. TODO: Extract this and add it to ArrayNode.
    ObjectNode.prototype.compile_node = function compile_node(o) {
      var _l, _m, _n, _o, _p, _q, _r, i, indent, inner, join, last_noncom, non_comments, prop, props;
      o.indent = this.idt(1);
      non_comments = (function() {
        _l = []; _m = this.properties;
        for (_n = 0, _o = _m.length; _n < _o; _n++) {
          prop = _m[_n];
          if (!(prop instanceof CommentNode)) {
            _l.push(prop);
          }
        }
        return _l;
      }).call(this);
      last_noncom = non_comments[non_comments.length - 1];
      props = (function() {
        _p = []; _q = this.properties;
        for (i = 0, _r = _q.length; i < _r; i++) {
          prop = _q[i];
          _p.push((function() {
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
        return _p;
      }).call(this);
      props = props.join('');
      inner = props ? '\n' + props + '\n' + this.idt() : '';
      return '{' + inner + '}';
    };
    return ObjectNode;
  }).call(this);
  // A class literal, including optional superclass and constructor.
  exports.ClassNode = (function() {
    ClassNode = function ClassNode(variable, parent, props) {
      this.children = compact(flatten([(this.variable = variable), (this.parent = parent), (this.properties = props || [])]));
      return this;
    };
    _m = function(){};
    _m.prototype = BaseNode.prototype;
    ClassNode.__superClass__ = BaseNode.prototype;
    ClassNode.prototype = new _m();
    ClassNode.prototype.constructor = ClassNode;
    ClassNode.prototype.type = 'Class';
    ClassNode.prototype.compile_node = function compile_node(o) {
      var _m, _n, _o, construct, extension, func, prop, props, ret, returns, val;
      extension = this.parent && new ExtendsNode(this.variable, this.parent);
      constructor = null;
      props = new Expressions();
      o.top = true;
      ret = del(o, 'returns');
      _m = this.properties;
      for (_n = 0, _o = _m.length; _n < _o; _n++) {
        prop = _m[_n];
        if (prop.variable && prop.variable.base.value === 'constructor') {
          func = prop.value;
          func.body.push(new ReturnNode(new LiteralNode('this')));
          constructor = new AssignNode(this.variable, func);
        } else {
          if (prop.variable) {
            val = new ValueNode(this.variable, [new AccessorNode(prop.variable, 'prototype')]);
            prop = new AssignNode(val, prop.value);
          }
          props.push(prop);
        }
      }
      if (!(constructor)) {
        constructor = new AssignNode(this.variable, new CodeNode());
      }
      construct = this.idt() + constructor.compile(o) + ';\n';
      props = props.empty() ? '' : props.compile(o) + '\n';
      extension = extension ? extension.compile(o) + '\n' : '';
      returns = ret ? '\n' + this.idt() + 'return ' + this.variable.compile(o) + ';' : '';
      return construct + extension + props + returns;
    };
    return ClassNode;
  }).call(this);
  statement(ClassNode);
  // An array literal.
  exports.ArrayNode = (function() {
    ArrayNode = function ArrayNode(objects) {
      this.children = (this.objects = objects || []);
      return this;
    };
    _n = function(){};
    _n.prototype = BaseNode.prototype;
    ArrayNode.__superClass__ = BaseNode.prototype;
    ArrayNode.prototype = new _n();
    ArrayNode.prototype.constructor = ArrayNode;
    ArrayNode.prototype.type = 'Array';
    ArrayNode.prototype.compile_node = function compile_node(o) {
      var _n, _o, _p, code, ending, i, obj, objects;
      o.indent = this.idt(1);
      objects = (function() {
        _n = []; _o = this.objects;
        for (i = 0, _p = _o.length; i < _p; i++) {
          obj = _o[i];
          _n.push((function() {
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
        return _n;
      }).call(this);
      objects = objects.join('');
      ending = objects.indexOf('\n') >= 0 ? "\n" + this.idt() + ']' : ']';
      return '[' + objects + ending;
    };
    return ArrayNode;
  }).call(this);
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
      return Expressions.wrap([new CallNode(new ValueNode(new LiteralNode(array), [new AccessorNode(new LiteralNode('push'))]), [expr])]);
    }
  });
  // A faux-node used to wrap an expressions body in a closure.
  ClosureNode = (exports.ClosureNode = {
    wrap: function wrap(expressions, statement) {
      var call, func;
      func = new ParentheticalNode(new CodeNode([], Expressions.wrap([expressions])));
      call = new CallNode(new ValueNode(func, [new AccessorNode(new LiteralNode('call'))]), [new LiteralNode('this')]);
      return statement ? Expressions.wrap([call]) : call;
    }
  });
  // Setting the value of a local variable, or the value of an object property.
  exports.AssignNode = (function() {
    AssignNode = function AssignNode(variable, value, context) {
      this.children = [(this.variable = variable), (this.value = value)];
      this.context = context;
      return this;
    };
    _o = function(){};
    _o.prototype = BaseNode.prototype;
    AssignNode.__superClass__ = BaseNode.prototype;
    AssignNode.prototype = new _o();
    AssignNode.prototype.constructor = AssignNode;
    AssignNode.prototype.type = 'Assign';
    AssignNode.prototype.PROTO_ASSIGN = /^(\S+)\.prototype/;
    AssignNode.prototype.LEADING_DOT = /^\.(prototype\.)?/;
    AssignNode.prototype.top_sensitive = function top_sensitive() {
      return true;
    };
    AssignNode.prototype.is_value = function is_value() {
      return this.variable instanceof ValueNode;
    };
    AssignNode.prototype.is_statement = function is_statement() {
      return this.is_value() && (this.variable.is_array() || this.variable.is_object());
    };
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
    };
    // Implementation of recursive pattern matching, when assigning array or
    // object literals to a value. Peeks at their properties to assign inner names.
    // See: http://wiki.ecmascript.org/doku.php?id=harmony:destructuring
    AssignNode.prototype.compile_pattern_match = function compile_pattern_match(o) {
      var _o, _p, _q, access_class, assigns, code, i, idx, obj, val, val_var, value;
      val_var = o.scope.free_variable();
      value = this.value.is_statement() ? ClosureNode.wrap(this.value) : this.value;
      assigns = [this.idt() + val_var + ' = ' + value.compile(o) + ';'];
      o.top = true;
      o.as_statement = true;
      _o = this.variable.base.objects;
      for (i = 0, _p = _o.length; i < _p; i++) {
        obj = _o[i];
        idx = i;
        if (this.variable.is_object()) {
          _q = [obj.value, obj.variable.base];
          obj = _q[0];
          idx = _q[1];
        }
        access_class = this.variable.is_array() ? IndexNode : AccessorNode;
        if (obj instanceof SplatNode) {
          val = new LiteralNode(obj.compile_value(o, val_var, this.variable.base.objects.indexOf(obj)));
        } else {
          if (!(typeof idx === 'object')) {
            idx = new LiteralNode(idx);
          }
          val = new ValueNode(new LiteralNode(val_var), [new access_class(idx)]);
        }
        assigns.push(new AssignNode(obj, val).compile(o));
      }
      code = assigns.join("\n");
      if (o.returns) {
        code += '\n' + this.idt() + 'return ' + this.variable.compile(o) + ';';
      }
      return code;
    };
    AssignNode.prototype.compile_splice = function compile_splice(o) {
      var from, l, name, plus, range, to;
      name = this.variable.compile(merge(o, {
        only_first: true
      }));
      l = this.variable.properties.length;
      range = this.variable.properties[l - 1].range;
      plus = range.exclusive ? '' : ' + 1';
      from = range.from.compile(o);
      to = range.to.compile(o) + ' - ' + from + plus;
      return name + '.splice.apply(' + name + ', [' + from + ', ' + to + '].concat(' + this.value.compile(o) + '))';
    };
    return AssignNode;
  }).call(this);
  // A function definition. The only node that creates a new Scope.
  // A CodeNode does not have any children -- they're within the new scope.
  exports.CodeNode = (function() {
    CodeNode = function CodeNode(params, body, tag) {
      this.params = params || [];
      this.body = body || new Expressions();
      this.bound = tag === 'boundfunc';
      return this;
    };
    _p = function(){};
    _p.prototype = BaseNode.prototype;
    CodeNode.__superClass__ = BaseNode.prototype;
    CodeNode.prototype = new _p();
    CodeNode.prototype.constructor = CodeNode;
    CodeNode.prototype.type = 'Code';
    CodeNode.prototype.compile_node = function compile_node(o) {
      var _p, _q, _r, _s, _t, _u, _v, code, func, inner, name_part, param, params, shared_scope, splat, top;
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
      params = (function() {
        _p = []; _q = this.params;
        for (_r = 0, _s = _q.length; _r < _s; _r++) {
          param = _q[_r];
          _p.push(param.compile(o));
        }
        return _p;
      }).call(this);
      _t = params;
      for (_u = 0, _v = _t.length; _u < _v; _u++) {
        param = _t[_u];
        (o.scope.parameter(param));
      }
      code = this.body.expressions.length ? '\n' + this.body.compile_with_declarations(o) + '\n' : '';
      name_part = this.name ? ' ' + this.name : '';
      func = 'function' + (this.bound ? '' : name_part) + '(' + params.join(', ') + ') {' + code + this.idt(this.bound ? 1 : 0) + '}';
      if (top && !this.bound) {
        func = '(' + func + ')';
      }
      if (!(this.bound)) {
        return func;
      }
      inner = '(function' + name_part + '() {\n' + this.idt(2) + 'return __func.apply(__this, arguments);\n' + this.idt(1) + '});';
      return '(function(__this) {\n' + this.idt(1) + 'var __func = ' + func + ';\n' + this.idt(1) + 'return ' + inner + '\n' + this.idt() + '})(this)';
    };
    CodeNode.prototype.top_sensitive = function top_sensitive() {
      return true;
    };
    CodeNode.prototype.real_children = function real_children() {
      return flatten([this.params, this.body.expressions]);
    };
    CodeNode.prototype.traverse = function traverse(block) {
      var _p, _q, _r, _s, child;
      block(this);
      _p = []; _q = this.real_children();
      for (_r = 0, _s = _q.length; _r < _s; _r++) {
        child = _q[_r];
        _p.push(block(child));
      }
      return _p;
    };
    CodeNode.prototype.toString = function toString(idt) {
      var _p, _q, _r, _s, child;
      idt = idt || '';
      return '\n' + idt + this.type + (function() {
        _p = []; _q = this.real_children();
        for (_r = 0, _s = _q.length; _r < _s; _r++) {
          child = _q[_r];
          _p.push(child.toString(idt + TAB));
        }
        return _p;
      }).call(this).join('');
    };
    return CodeNode;
  }).call(this);
  // A splat, either as a parameter to a function, an argument to a call,
  // or in a destructuring assignment.
  exports.SplatNode = (function() {
    SplatNode = function SplatNode(name) {
      if (!(name.compile)) {
        name = new LiteralNode(name);
      }
      this.children = [(this.name = name)];
      return this;
    };
    _q = function(){};
    _q.prototype = BaseNode.prototype;
    SplatNode.__superClass__ = BaseNode.prototype;
    SplatNode.prototype = new _q();
    SplatNode.prototype.constructor = SplatNode;
    SplatNode.prototype.type = 'Splat';
    SplatNode.prototype.compile_node = function compile_node(o) {
      var _q;
      return (typeof (_q = this.index) !== "undefined" && _q !== null) ? this.compile_param(o) : this.name.compile(o);
    };
    SplatNode.prototype.compile_param = function compile_param(o) {
      var name;
      name = this.name.compile(o);
      o.scope.find(name);
      return name + ' = Array.prototype.slice.call(arguments, ' + this.index + ')';
    };
    SplatNode.prototype.compile_value = function compile_value(o, name, index) {
      return "Array.prototype.slice.call(" + name + ', ' + index + ')';
    };
    return SplatNode;
  }).call(this);
  // A while loop, the only sort of low-level loop exposed by CoffeeScript. From
  // it, all other loops can be manufactured.
  exports.WhileNode = (function() {
    WhileNode = function WhileNode(condition, opts) {
      this.children = [(this.condition = condition)];
      this.filter = opts && opts.filter;
      return this;
    };
    _r = function(){};
    _r.prototype = BaseNode.prototype;
    WhileNode.__superClass__ = BaseNode.prototype;
    WhileNode.prototype = new _r();
    WhileNode.prototype.constructor = WhileNode;
    WhileNode.prototype.type = 'While';
    WhileNode.prototype.add_body = function add_body(body) {
      this.children.push((this.body = body));
      return this;
    };
    WhileNode.prototype.top_sensitive = function top_sensitive() {
      return true;
    };
    WhileNode.prototype.compile_node = function compile_node(o) {
      var cond, post, pre, returns, rvar, set, top;
      returns = del(o, 'returns');
      top = del(o, 'top') && !returns;
      o.indent = this.idt(1);
      o.top = true;
      cond = this.condition.compile(o);
      set = '';
      if (!top) {
        rvar = o.scope.free_variable();
        set = this.idt() + rvar + ' = [];\n';
        if (this.body) {
          this.body = PushNode.wrap(rvar, this.body);
        }
      }
      post = returns ? '\n' + this.idt() + 'return ' + rvar + ';' : '';
      pre = set + this.idt() + 'while (' + cond + ')';
      if (!this.body) {
        return pre + ' null;' + post;
      }
      if (this.filter) {
        this.body = Expressions.wrap([new IfNode(this.filter, this.body)]);
      }
      return pre + ' {\n' + this.body.compile(o) + '\n' + this.idt() + '}' + post;
    };
    return WhileNode;
  }).call(this);
  statement(WhileNode);
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
    _s = function(){};
    _s.prototype = BaseNode.prototype;
    OpNode.__superClass__ = BaseNode.prototype;
    OpNode.prototype = new _s();
    OpNode.prototype.constructor = OpNode;
    OpNode.prototype.type = 'Op';
    OpNode.prototype.CONVERSIONS = {
      '==': '===',
      '!=': '!==',
      'and': '&&',
      'or': '||',
      'is': '===',
      'isnt': '!==',
      'not': '!'
    };
    OpNode.prototype.CHAINABLE = ['<', '>', '>=', '<=', '===', '!=='];
    OpNode.prototype.ASSIGNMENT = ['||=', '&&=', '?='];
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
      return this.first.compile(o) + ' ' + this.operator + ' ' + this.second.compile(o);
    };
    // Mimic Python's chained comparisons. See:
    // http://docs.python.org/reference/expressions.html#notin
    OpNode.prototype.compile_chain = function compile_chain(o) {
      var _s, shared;
      shared = this.first.unwrap().second;
      if (shared instanceof CallNode) {
        _s = shared.compile_reference(o);
        this.first.second = _s[0];
        shared = _s[1];
      }
      return '(' + this.first.compile(o) + ') && (' + shared.compile(o) + ' ' + this.operator + ' ' + this.second.compile(o) + ')';
    };
    OpNode.prototype.compile_assignment = function compile_assignment(o) {
      var _s, first, second;
      _s = [this.first.compile(o), this.second.compile(o)];
      first = _s[0];
      second = _s[1];
      if (first.match(IDENTIFIER)) {
        o.scope.find(first);
      }
      if (this.operator === '?=') {
        return first + ' = ' + ExistenceNode.compile_test(o, this.first) + ' ? ' + first + ' : ' + second;
      }
      return first + ' = ' + first + ' ' + this.operator.substr(0, 2) + ' ' + second;
    };
    OpNode.prototype.compile_existence = function compile_existence(o) {
      var _s, first, second;
      _s = [this.first.compile(o), this.second.compile(o)];
      first = _s[0];
      second = _s[1];
      return ExistenceNode.compile_test(o, this.first) + ' ? ' + first + ' : ' + second;
    };
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
  // A try/catch/finally block.
  exports.TryNode = (function() {
    TryNode = function TryNode(attempt, error, recovery, ensure) {
      this.children = compact([(this.attempt = attempt), (this.recovery = recovery), (this.ensure = ensure)]);
      this.error = error;
      this;
      return this;
    };
    _t = function(){};
    _t.prototype = BaseNode.prototype;
    TryNode.__superClass__ = BaseNode.prototype;
    TryNode.prototype = new _t();
    TryNode.prototype.constructor = TryNode;
    TryNode.prototype.type = 'Try';
    TryNode.prototype.compile_node = function compile_node(o) {
      var catch_part, error_part, finally_part;
      o.indent = this.idt(1);
      o.top = true;
      error_part = this.error ? ' (' + this.error.compile(o) + ') ' : ' ';
      catch_part = (this.recovery || '') && ' catch' + error_part + '{\n' + this.recovery.compile(o) + '\n' + this.idt() + '}';
      finally_part = (this.ensure || '') && ' finally {\n' + this.ensure.compile(merge(o, {
        returns: null
      })) + '\n' + this.idt() + '}';
      return this.idt() + 'try {\n' + this.attempt.compile(o) + '\n' + this.idt() + '}' + catch_part + finally_part;
    };
    return TryNode;
  }).call(this);
  statement(TryNode);
  // Throw an exception.
  exports.ThrowNode = (function() {
    ThrowNode = function ThrowNode(expression) {
      this.children = [(this.expression = expression)];
      return this;
    };
    _u = function(){};
    _u.prototype = BaseNode.prototype;
    ThrowNode.__superClass__ = BaseNode.prototype;
    ThrowNode.prototype = new _u();
    ThrowNode.prototype.constructor = ThrowNode;
    ThrowNode.prototype.type = 'Throw';
    ThrowNode.prototype.compile_node = function compile_node(o) {
      return this.idt() + 'throw ' + this.expression.compile(o) + ';';
    };
    return ThrowNode;
  }).call(this);
  statement(ThrowNode, true);
  // Check an expression for existence (meaning not null or undefined).
  exports.ExistenceNode = (function() {
    ExistenceNode = function ExistenceNode(expression) {
      this.children = [(this.expression = expression)];
      return this;
    };
    _v = function(){};
    _v.prototype = BaseNode.prototype;
    ExistenceNode.__superClass__ = BaseNode.prototype;
    ExistenceNode.prototype = new _v();
    ExistenceNode.prototype.constructor = ExistenceNode;
    ExistenceNode.prototype.type = 'Existence';
    ExistenceNode.prototype.compile_node = function compile_node(o) {
      return ExistenceNode.compile_test(o, this.expression);
    };
    return ExistenceNode;
  }).call(this);
  ExistenceNode.compile_test = function compile_test(o, variable) {
    var _w, _x, first, second;
    _w = [variable, variable];
    first = _w[0];
    second = _w[1];
    if (variable instanceof CallNode || (variable instanceof ValueNode && variable.has_properties())) {
      _x = variable.compile_reference(o);
      first = _x[0];
      second = _x[1];
    }
    return '(typeof ' + first.compile(o) + ' !== "undefined" && ' + second.compile(o) + ' !== null)';
  };
  // An extra set of parentheses, specified explicitly in the source.
  exports.ParentheticalNode = (function() {
    ParentheticalNode = function ParentheticalNode(expression) {
      this.children = [(this.expression = expression)];
      return this;
    };
    _w = function(){};
    _w.prototype = BaseNode.prototype;
    ParentheticalNode.__superClass__ = BaseNode.prototype;
    ParentheticalNode.prototype = new _w();
    ParentheticalNode.prototype.constructor = ParentheticalNode;
    ParentheticalNode.prototype.type = 'Paren';
    ParentheticalNode.prototype.is_statement = function is_statement() {
      return this.expression.is_statement();
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
      return '(' + code + ')';
    };
    return ParentheticalNode;
  }).call(this);
  // The replacement for the for loop is an array comprehension (that compiles)
  // into a for loop. Also acts as an expression, able to return the result
  // of the comprehenion. Unlike Python array comprehensions, it's able to pass
  // the current index of the loop as a second parameter.
  exports.ForNode = (function() {
    ForNode = function ForNode(body, source, name, index) {
      var _x;
      this.body = body;
      this.name = name;
      this.index = index || null;
      this.source = source.source;
      this.filter = source.filter;
      this.step = source.step;
      this.object = !!source.object;
      if (this.object) {
        _x = [this.index, this.name];
        this.name = _x[0];
        this.index = _x[1];
      }
      this.children = compact([this.body, this.source, this.filter]);
      return this;
    };
    _x = function(){};
    _x.prototype = BaseNode.prototype;
    ForNode.__superClass__ = BaseNode.prototype;
    ForNode.prototype = new _x();
    ForNode.prototype.constructor = ForNode;
    ForNode.prototype.type = 'For';
    ForNode.prototype.top_sensitive = function top_sensitive() {
      return true;
    };
    ForNode.prototype.compile_node = function compile_node(o) {
      var body, body_dent, close, for_part, index, index_found, index_var, ivar, lvar, name, name_found, range, return_result, rvar, scope, set_result, source, source_part, step_part, svar, top_level, var_part, vars;
      top_level = del(o, 'top') && !o.returns;
      range = this.source instanceof ValueNode && this.source.base instanceof RangeNode && !this.source.properties.length;
      source = range ? this.source.base : this.source;
      scope = o.scope;
      name = this.name && this.name.compile(o);
      index = this.index && this.index.compile(o);
      name_found = name && scope.find(name);
      index_found = index && scope.find(index);
      body_dent = this.idt(1);
      if (!(top_level)) {
        rvar = scope.free_variable();
      }
      svar = scope.free_variable();
      ivar = range ? name : index || scope.free_variable();
      var_part = '';
      body = Expressions.wrap([this.body]);
      if (range) {
        index_var = scope.free_variable();
        source_part = source.compile_variables(o);
        for_part = index_var + ' = 0, ' + source.compile(merge(o, {
          index: ivar,
          step: this.step
        })) + ', ' + index_var + '++';
      } else {
        index_var = null;
        source_part = svar + ' = ' + this.source.compile(o) + ';\n' + this.idt();
        if (name) {
          var_part = body_dent + name + ' = ' + svar + '[' + ivar + '];\n';
        }
        if (!this.object) {
          lvar = scope.free_variable();
          step_part = this.step ? ivar + ' += ' + this.step.compile(o) : ivar + '++';
          for_part = ivar + ' = 0, ' + lvar + ' = ' + svar + '.length; ' + ivar + ' < ' + lvar + '; ' + step_part;
        }
      }
      set_result = rvar ? this.idt() + rvar + ' = []; ' : this.idt();
      return_result = rvar || '';
      if (top_level && this.contains(function(n) {
        return n instanceof CodeNode;
      })) {
        body = ClosureNode.wrap(body, true);
      }
      if (!(top_level)) {
        body = PushNode.wrap(rvar, body);
      }
      if (o.returns) {
        return_result = 'return ' + return_result;
        del(o, 'returns');
        if (this.filter) {
          body = new IfNode(this.filter, body, null, {
            statement: true
          });
        }
      } else if (this.filter) {
        body = Expressions.wrap([new IfNode(this.filter, body)]);
      }
      if (this.object) {
        o.scope.assign('__hasProp', 'Object.prototype.hasOwnProperty', true);
        for_part = ivar + ' in ' + svar + ') { if (__hasProp.call(' + svar + ', ' + ivar + ')';
      }
      if (!(top_level)) {
        return_result = '\n' + this.idt() + return_result + ';';
      }
      body = body.compile(merge(o, {
        indent: body_dent,
        top: true
      }));
      vars = range ? name : name + ', ' + ivar;
      close = this.object ? '}}\n' : '}\n';
      return set_result + source_part + 'for (' + for_part + ') {\n' + var_part + body + '\n' + this.idt() + close + this.idt() + return_result;
    };
    return ForNode;
  }).call(this);
  statement(ForNode);
  // If/else statements. Switch/whens get compiled into these. Acts as an
  // expression by pushing down requested returns to the expression bodies.
  // Single-expression IfNodes are compiled into ternary operators if possible,
  // because ternaries are first-class returnable assignable expressions.
  exports.IfNode = (function() {
    IfNode = function IfNode(condition, body, else_body, tags) {
      this.condition = condition;
      this.body = body && body.unwrap();
      this.else_body = else_body && else_body.unwrap();
      this.children = compact([this.condition, this.body, this.else_body]);
      this.tags = tags || {};
      if (this.condition instanceof Array) {
        this.multiple = true;
      }
      if (this.tags.invert) {
        this.condition = new OpNode('!', new ParentheticalNode(this.condition));
      }
      return this;
    };
    _y = function(){};
    _y.prototype = BaseNode.prototype;
    IfNode.__superClass__ = BaseNode.prototype;
    IfNode.prototype = new _y();
    IfNode.prototype.constructor = IfNode;
    IfNode.prototype.type = 'If';
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
    // Tag a chain of IfNodes with their switch condition for equality.
    IfNode.prototype.rewrite_condition = function rewrite_condition(expression) {
      this.switcher = expression;
      return this;
    };
    // Rewrite a chain of IfNodes with their switch condition for equality.
    IfNode.prototype.rewrite_switch = function rewrite_switch(o) {
      var _aa, _y, _z, assigner, cond, i, variable;
      assigner = this.switcher;
      if (!(this.switcher.unwrap() instanceof LiteralNode)) {
        variable = new LiteralNode(o.scope.free_variable());
        assigner = new AssignNode(variable, this.switcher);
        this.switcher = variable;
      }
      this.condition = (function() {
        if (this.multiple) {
          _y = []; _z = this.condition;
          for (i = 0, _aa = _z.length; i < _aa; i++) {
            cond = _z[i];
            _y.push(new OpNode('is', (i === 0 ? assigner : this.switcher), cond));
          }
          return _y;
        } else {
          return new OpNode('is', assigner, this.condition);
        }
      }).call(this);
      if (this.is_chain()) {
        this.else_body.rewrite_condition(this.switcher);
      }
      return this;
    };
    // Rewrite a chain of IfNodes to add a default case as the final else.
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
    // If the else_body is an IfNode itself, then we've got an if-else chain.
    IfNode.prototype.is_chain = function is_chain() {
      return this.chain = this.chain || this.else_body && this.else_body instanceof IfNode;
    };
    // The IfNode only compiles into a statement if either of the bodies needs
    // to be a statement.
    IfNode.prototype.is_statement = function is_statement() {
      return this.statement = this.statement || !!(this.comment || this.tags.statement || this.body.is_statement() || (this.else_body && this.else_body.is_statement()));
    };
    IfNode.prototype.compile_condition = function compile_condition(o) {
      var _aa, _ab, _y, _z, cond;
      return (function() {
        _y = []; _z = flatten([this.condition]);
        for (_aa = 0, _ab = _z.length; _aa < _ab; _aa++) {
          cond = _z[_aa];
          _y.push(cond.compile(o));
        }
        return _y;
      }).call(this).join(' || ');
    };
    IfNode.prototype.compile_node = function compile_node(o) {
      return this.is_statement() ? this.compile_statement(o) : this.compile_ternary(o);
    };
    // Compile the IfNode as a regular if-else statement. Flattened chains
    // force sub-else bodies into statement form.
    IfNode.prototype.compile_statement = function compile_statement(o) {
      var body, child, com_dent, cond_o, else_part, if_dent, if_part, prefix;
      if (this.switcher) {
        this.rewrite_switch(o);
      }
      child = del(o, 'chain_child');
      cond_o = merge(o);
      del(cond_o, 'returns');
      o.indent = this.idt(1);
      o.top = true;
      if_dent = child ? '' : this.idt();
      com_dent = child ? this.idt() : '';
      prefix = this.comment ? this.comment.compile(cond_o) + '\n' + com_dent : '';
      body = Expressions.wrap([this.body]).compile(o);
      if_part = prefix + if_dent + 'if (' + this.compile_condition(cond_o) + ') {\n' + body + '\n' + this.idt() + '}';
      if (!(this.else_body)) {
        return if_part;
      }
      else_part = this.is_chain() ? ' else ' + this.else_body.compile(merge(o, {
        indent: this.idt(),
        chain_child: true
      })) : ' else {\n' + Expressions.wrap([this.else_body]).compile(o) + '\n' + this.idt() + '}';
      return if_part + else_part;
    };
    // Compile the IfNode into a ternary operator.
    IfNode.prototype.compile_ternary = function compile_ternary(o) {
      var else_part, if_part;
      if_part = this.condition.compile(o) + ' ? ' + this.body.compile(o);
      else_part = this.else_body ? this.else_body.compile(o) : 'null';
      return if_part + ' : ' + else_part;
    };
    return IfNode;
  }).call(this);
})();
