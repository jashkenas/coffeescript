process.mixin require './scope'

# The abstract base class for all CoffeeScript nodes.
# All nodes are implement a "compile_node" method, which performs the
# code generation for that node. To compile a node, call the "compile"
# method, which wraps "compile_node" in some extra smarts, to know when the
# generated code should be wrapped up in a closure. An options hash is passed
# and cloned throughout, containing messages from higher in the AST,
# information about the current scope, and indentation level.

exports.Expressions       : -> @name: this.constructor.name; @values: arguments
exports.LiteralNode       : -> @name: this.constructor.name; @values: arguments
exports.ReturnNode        : -> @name: this.constructor.name; @values: arguments
exports.CommentNode       : -> @name: this.constructor.name; @values: arguments
exports.CallNode          : -> @name: this.constructor.name; @values: arguments
exports.ExtendsNode       : -> @name: this.constructor.name; @values: arguments
exports.ValueNode         : -> @name: this.constructor.name; @values: arguments
exports.AccessorNode      : -> @name: this.constructor.name; @values: arguments
exports.IndexNode         : -> @name: this.constructor.name; @values: arguments
exports.RangeNode         : -> @name: this.constructor.name; @values: arguments
exports.SliceNode         : -> @name: this.constructor.name; @values: arguments
exports.ThisNode          : -> @name: this.constructor.name; @values: arguments
exports.AssignNode        : -> @name: this.constructor.name; @values: arguments
exports.OpNode            : -> @name: this.constructor.name; @values: arguments
exports.CodeNode          : -> @name: this.constructor.name; @values: arguments
exports.SplatNode         : -> @name: this.constructor.name; @values: arguments
exports.ObjectNode        : -> @name: this.constructor.name; @values: arguments
exports.ArrayNode         : -> @name: this.constructor.name; @values: arguments
exports.PushNode          : -> @name: this.constructor.name; @values: arguments
exports.ClosureNode       : -> @name: this.constructor.name; @values: arguments
exports.WhileNode         : -> @name: this.constructor.name; @values: arguments
exports.ForNode           : -> @name: this.constructor.name; @values: arguments
exports.TryNode           : -> @name: this.constructor.name; @values: arguments
exports.ThrowNode         : -> @name: this.constructor.name; @values: arguments
exports.ExistenceNode     : -> @name: this.constructor.name; @values: arguments
exports.ParentheticalNode : -> @name: this.constructor.name; @values: arguments
exports.IfNode            : -> @name: this.constructor.name; @values: arguments

exports.Expressions.wrap  : (values) -> @values: values


# Some helper functions

# Tabs are two spaces for pretty printing.
TAB: '  '
TRAILING_WHITESPACE: /\s+$/g

# Flatten nested arrays recursively.
flatten: (list) ->
  memo: []
  for item in list
    return memo.concat(flatten(item)) if item instanceof Array
    memo.push(item)
    memo
  memo

# Remove all null values from an array.
compact: (input) ->
  item for item in input when item?

# Dup an array or object.
dup: (input) ->
  if input instanceof Array
    val for val in input
  else
    output: {}
    (output[key]: val) for key, val of input
    output

# Merge objects.
merge: (src, dest) ->
  dest[key]: val for key, val of src
  dest

# Do any of the elements in the list pass a truth test?
any: (list, test) ->
  result: true for item in list when test(item)
  !!result.length

# Delete a key from an object, returning the value.
del: (obj, key) ->
  val: obj[key]
  delete obj[key]
  val

# Quickie inheritance convenience wrapper to reduce typing.
inherit: (parent, props) ->
  klass: del(props, 'constructor')
  klass extends parent
  (klass.prototype[name]: prop) for name, prop of props
  klass

# # Provide a quick implementation of a children method.
# children: (klass, attrs...) ->
#   klass::children: ->
#     nodes: this[attr] for attr in attrs
#     compact flatten nodes

# Mark a node as a statement, or a statement only.
statement: (klass, only) ->
  klass::is_statement:       -> true
  (klass::is_statement_only:  -> true) if only


# The abstract base class for all CoffeeScript nodes.
# All nodes are implement a "compile_node" method, which performs the
# code generation for that node. To compile a node, call the "compile"
# method, which wraps "compile_node" in some extra smarts, to know when the
# generated code should be wrapped up in a closure. An options hash is passed
# and cloned throughout, containing messages from higher in the AST,
# information about the current scope, and indentation level.
Node: exports.Node: ->

# This is extremely important -- we convert JS statements into expressions
# by wrapping them in a closure, only if it's possible, and we're not at
# the top level of a block (which would be unnecessary), and we haven't
# already been asked to return the result.
Node::compile: (o) ->
  @options: dup(o || {})
  @indent:  o.indent
  top:      if @top_sensitive() then o.top else del o, 'top'
  closure:  @is_statement() and not @is_statement_only() and not top and
            not o.returns and not this instanceof CommentNode and
            not @contains (node) -> node.is_statement_only()
  if closure then @compile_closure(@options) else @compile_node(@options)

# Statements converted into expressions share scope with their parent
# closure, to preserve JavaScript-style lexical scope.
Node::compile_closure: (o) ->
  @indent: o.indent
  o.shared_scope: o.scope
  ClosureNode.wrap(this).compile(o)

# Quick short method for the current indentation level, plus tabbing in.
Node::idt: (tabs) ->
  idt: (@indent || '')
  idt += TAB for i in [0..(tabs or 0)]
  idt

# Does this node, or any of its children, contain a node of a certain kind?
Node::contains: (block) ->
  for node in @children
    return true if block(node)
    return true if node instanceof Node and node.contains block
  false

# Default implementations of the common node methods.
Node::unwrap:             -> this
Node::children:           []
Node::is_statement:       -> false
Node::is_statement_only:  -> false
Node::top_sensitive:      -> false


# A collection of nodes, each one representing an expression.
Expressions: exports.Expressions: inherit Node, {

  constructor: (nodes) ->
    @expressions: flatten nodes
    @children: @expressions
    this

  # Tack an expression on to the end of this expression list.
  push: (node) ->
    @expressions.push(node)
    this

  # Tack an expression on to the beginning of this expression list.
  unshift: (node) ->
    @expressions.unshift(node)
    this

  # If this Expressions consists of a single node, pull it back out.
  unwrap: ->
    if @expressions.length is 1 then @expressions[0] else this

  # Is this an empty block of code?
  empty: ->
    @expressions.length is 0

  # Is the node last in this block of expressions?
  is_last: (node) ->
    l: @expressions.length
    @last_index ||= if @expressions[l - 1] instanceof CommentNode then -2 else -1
    node is @expressions[l - @last_index]

  compile: (o) ->
    if o.scope then super(o) else @compile_root(o)

  # Compile each expression in the Expressions body.
  compile_node: (o) ->
    (@compile_expression(node, dup(o)) for node in @expressions).join("\n")

  # If this is the top-level Expressions, wrap everything in a safety closure.
  compile_root: (o) ->
    o.indent: @indent: indent: if o.no_wrap then '' else TAB
    o.scope: new Scope(null, this, null)
    code: if o.globals then @compile_node(o) else @compile_with_declarations(o)
    code: code.replace(TRAILING_WHITESPACE, '')
    if o.no_wrap then code else "(function(){\n"+code+"\n})();"

  # Compile the expressions body, with declarations of all inner variables
  # pushed up to the top.
  compile_with_declarations: (o) ->
    code: @compile_node(o)
    args: @contains (node) -> node instanceof ValueNode and node.is_arguments()
    argv: if args and o.scope.check('arguments') then '' else 'var '
    code: @idt() + argv + "arguments = Array.prototype.slice.call(arguments, 0);\n" + code if args
    code: @idt() + 'var ' + o.scope.compiled_assignments() + ";\n" + code  if o.scope.has_assignments(this)
    code: @idt() + 'var ' + o.scope.compiled_declarations() + ";\n" + code if o.scope.has_declarations(this)
    code

  # Compiles a single expression within the expressions body.
  compile_expression: (node, o) ->
    @indent: o.indent
    stmt:    node.is_statement()
    # We need to return the result if this is the last node in the expressions body.
    returns: del(o, 'returns') and @is_last(node) and not node.is_statement_only()
    # Return the regular compile of the node, unless we need to return the result.
    return (if stmt then '' else @idt()) + node.compile(merge(o, {top: true})) + (if stmt then '' else ';') unless returns
    # If it's a statement, the node knows how to return itself.
    return node.compile(merge(o, {returns: true})) if node.is_statement()
    # If it's not part of a constructor, we can just return the value of the expression.
    return @idt() + 'return ' + node.compile(o) unless o.scope.method?.is_constructor()
    # It's the last line of a constructor, add a safety check.
    temp: o.scope.free_variable()
    @idt() + temp + ' = ' + node.compile(o) + ";\n" + @idt() + "return " + o.scope.method.name + ' === this.constructor ? this : ' + temp + ';'
}

# Wrap up a node as an Expressions, unless it already is one.
Expressions.wrap: (nodes) ->
  return nodes[0] if nodes.length is 1 and nodes[0] instanceof Expressions
  new Expressions(nodes)

statement Expressions


# Literals are static values that can be passed through directly into
# JavaScript without translation, eg.: strings, numbers, true, false, null...
LiteralNode: exports.LiteralNode: inherit Node, {

  constructor: (value) ->
    @value: value
    @children: [value]
    this

  # Break and continue must be treated as statements -- they lose their meaning
  # when wrapped in a closure.
  is_statement: ->
    @value is 'break' or @value is 'continue'

  compile_node: (o) ->
    idt: if @is_statement() then @idt() else ''
    end: if @is_statement() then ';' else ''
    idt + @value + end

}

LiteralNode::is_statement_only: LiteralNode::is_statement


# Return an expression, or wrap it in a closure and return it.
ReturnNode: exports.ReturnNode: inherit Node, {

  constructor: (expression) ->
    @expression: expression
    @children: [expression]
    this

  compile_node: (o) ->
    return @expression.compile(merge(o, {returns: true})) if @expression.is_statement()
    @idt() + 'return ' + @expression.compile(o) + ';'

}

statement ReturnNode, true


# A value, indexed or dotted into, or vanilla.
ValueNode: exports.ValueNode: inherit Node, {

  SOAK: " == undefined ? undefined : "

  constructor: (base, properties) ->
    @base:       base
    @properties: flatten(properties or [])
    @children:   flatten(@base, @properties)
    this

  push: (prop) ->
    @properties.push(prop)
    @children.push(prop)

  has_properties: ->
    @properties.length or @base instanceof ThisNode

  is_array: ->
    @base instanceof ArrayNode and not @has_properties()

  is_object: ->
    @base instanceof ObjectNode and not @has_properties()

  is_splice: ->
    @has_properties() and @properties[@properties.length - 1] instanceof SliceNode

  is_arguments: ->
    @base is 'arguments'

  unwrap: ->
    if @properties.length then this else @base

  # Values are statements if their base is a statement.
  is_statement: ->
    @base.is_statement and @base.is_statement() and not @has_properties()

  compile_node: (o) ->
    soaked:   false
    only:     del(o, 'only_first')
    props:    if only then @properties[0...@properties.length] else @properties
    baseline: @base.compile o
    parts:    [baseline]

    for prop in props
      if prop instanceof AccessorNode and prop.soak
        soaked: true
        if @base instanceof CallNode and prop is props[0]
          temp: o.scope.free_variable()
          parts[parts.length - 1]: '(' + temp + ' = ' + baseline + ')' + @SOAK + (baseline: temp + prop.compile(o))
        else
          parts[parts.length - 1]: @SOAK + (baseline += prop.compile(o))
      else
        part: prop.compile(o)
        baseline += part
        parts.push(part)

    @last: parts[parts.length - 1]
    @source: if parts.length > 1 then parts[0...parts.length].join('') else null
    code: parts.join('').replace(/\)\(\)\)/, '()))')
    return code unless soaked
    '(' + code + ')'

}


# Pass through CoffeeScript comments into JavaScript comments at the
# same position.
CommentNode: exports.CommentNode: inherit Node, {

  constructor: (lines) ->
    @lines: lines
    this

  compile_node: (o) ->
    delimiter: "\n" + @idt() + '//'
    delimiter + @lines.join(delimiter)

}

statement CommentNode


# Node for a function invocation. Takes care of converting super() calls into
# calls against the prototype's function of the same name.
CallNode: exports.CallNode: inherit Node, {

  constructor: (variable, args) ->
    @variable:  variable
    @args:      args or []
    @children:  flatten([@variable, @args])
    @prefix:    ''
    this

  new_instance: ->
    @prefix: 'new '
    this

  push: (arg) ->
    @args.push(arg)
    @children.push(arg)

  # Compile a vanilla function call.
  compile_node: (o) ->
    return @compile_splat(o) if any @args, (a) -> a instanceof SplatNode
    args: (arg.compile(o) for arg in @args).join(', ')
    return @compile_super(args, o) if @variable is 'super'
    @prefix + @variable.compile(o) + '(' + args + ')'

  # Compile a call against the superclass's implementation of the current function.
  compile_super: (args, o) ->
    methname: o.scope.method.name
    arg_part: if args.length then ', ' + args else ''
    meth: if o.scope.method.proto
      o.scope.method.proto + '.__superClass__.' + methname
    else
      methname + '.__superClass__.constructor'
    meth + '.call(this' + arg_part + ')'

  # Compile a function call being passed variable arguments.
  compile_splat: (o) ->
    meth: @variable.compile o
    obj:  @variable.source or 'this'
    args: for arg, i in @args
      code: arg.compile o
      code: if arg instanceof SplatNode then code else '[' + code + ']'
      if i is 0 then code else '.concat(' + code + ')'
    @prefix + meth + '.apply(' + obj + ', ' + args.join('') + ')'

  # If the code generation wished to use the result of a function call
  # in multiple places, ensure that the function is only ever called once.
  compile_reference: (o) ->
    reference: o.scope.free_variable()
    call: new ParentheticalNode(new AssignNode(reference, this))
    [call, reference]

}








































