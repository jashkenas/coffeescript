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

# Delete a key from an object, returning the value.
del: (obj, key) ->
  val: obj[key]
  delete obj[key]
  val

# # Provide a quick implementation of a children method.
# children: (klass, attrs...) ->
#   klass::children: ->
#     nodes: this[attr] for attr in attrs
#     compact flatten nodes

# Mark a node as a statement, or a statement only.
statement: (klass, only) ->
  klass::statement:       -> true
  klass::statement_only:  -> true if only


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
  top:      if @top_sensitive() then o.top else del obj 'top'
  closure:  @statement() and not @statement_only() and not top and
            not o.returns and not this instanceof CommentNode and
            not @contains (node) -> node.statement_only()
  if closure then @compile_closure(@options) else @compile_node(@options)

# Statements converted into expressions share scope with their parent
# closure, to preserve JavaScript-style lexical scope.
Node::compile_closure: (o) ->
  @indent: o.indent
  o.shared_scope: o.scope
  ClosureNode.wrap(this).compile(o)

# Quick short method for the current indentation level, plus tabbing in.
Node::idt: (tabs) ->
  idt: @indent
  idt += TAB for i in [0..(tabs or 0)]
  idt

# Does this node, or any of its children, contain a node of a certain kind?
Node::contains: (block) ->
  for node in @children
    return true if block(node)
    return true if node instanceof Node and node.contains block
  false

# Default implementations of the common node methods.
Node::unwrap:         -> this
Node::children:       []
Node::statement:      -> false
Node::statement_only: -> false
Node::top_sensitive:  -> false


# A collection of nodes, each one representing an expression.
Expressions: exports.Expressions: (nodes...) ->
  @expressions: flatten nodes
  @children: @expressions

Expressions extends Node
statement Expressions

# Wrap up a node as an Expressions, unless it already is.
Expressions::wrap: (nodes...) ->
  return nodes[0] if nodes.length is 1 and nodes[0] instanceof Expressions
  new Expressions(nodes...)

# Tack an expression on to the end of this expression list.
Expressions::push: (node) ->
  @expressions.push(node)
  this

# Tack an expression on to the beginning of this expression list.
Expressions::unshift: (node) ->
  @expressions.unshift(node)
  this

# If this Expressions consists of a single node, pull it back out.
Expressions::unwrap: ->
  if @expressions.length is 1 then @expressions[0] else this

# Is this an empty block of code?
Expressions::empty: ->
  @expressions.length is 0

# Is the node last in this block of expressions?
Expressions::is_last: (node) ->
  l: @expressions.length
  @last_index ||= if @expressions[l - 1] instanceof CommentNode then -2 else -1
  node is @expressions[l - @last_index]

Expressions::compile: (o) ->
  if o.scope then super(o) else @compile_root(o)

# Compile each expression in the Expressions body.
Expressions::compile_node: (o) ->
  (@compile_expression(node, dup(o)) for node in @expressions).join("\n")

# If this is the top-level Expressions, wrap everything in a safety closure.
Expressions::compile_root: (o) ->
  o.indent: @indent: indent: if o.no_wrap then '' else TAB
  o.scope: new Scope(null, this, null)
  code: if o.globals then @compile_node(o) else @compile_with_declarations(o)
  code: code.replace(TRAILING_WHITESPACE, '')
  if o.no_wrap then code else "(function(){\n"+code+"\n})();"
































