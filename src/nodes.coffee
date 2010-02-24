if process?
  process.mixin require 'scope'
else
  this.exports: this

# Some helper functions

# Tabs are two spaces for pretty printing.
TAB: '  '
TRAILING_WHITESPACE: /\s+$/gm

# Keep the identifier regex in sync with the Lexer.
IDENTIFIER:   /^[a-zA-Z$_](\w|\$)*$/

# Merge objects.
merge: (options, overrides) ->
  fresh: {}
  (fresh[key]: val) for key, val of options
  (fresh[key]: val) for key, val of overrides if overrides
  fresh

# Trim out all falsy values from an array.
compact: (array) -> item for item in array when item

# Return a completely flattened version of an array.
flatten: (array) ->
  memo: []
  for item in array
    if item instanceof Array then memo: memo.concat(item) else memo.push(item)
  memo

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

# Mark a node as a statement, or a statement only.
statement: (klass, only) ->
  klass::is_statement: -> true
  (klass::is_statement_only: -> true) if only

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
  @options: merge o or {}
  @indent:  o.indent
  del @options, 'operation' unless @operation_sensitive()
  top:      if @top_sensitive() then @options.top else del @options, 'top'
  closure:  @is_statement() and not @is_statement_only() and not top and
            not @options.returns and not (this instanceof CommentNode) and
            not @contains (node) -> node.is_statement_only()
  if closure then @compile_closure(@options) else @compile_node(@options)

# Statements converted into expressions share scope with their parent
# closure, to preserve JavaScript-style lexical scope.
Node::compile_closure: (o) ->
  @indent: o.indent
  o.shared_scope: o.scope
  ClosureNode.wrap(this).compile(o)

# If the code generation wishes to use the result of a complex expression
# in multiple places, ensure that the expression is only ever evaluated once.
Node::compile_reference: (o) ->
  reference: new LiteralNode(o.scope.free_variable())
  compiled:  new AssignNode(reference, this)
  [compiled, reference]

# Quick short method for the current indentation level, plus tabbing in.
Node::idt: (tabs) ->
  idt: (@indent || '')
  idt += TAB for i in [0...(tabs or 0)]
  idt

# Does this node, or any of its children, contain a node of a certain kind?
Node::contains: (block) ->
  for node in @children
    return true if block(node)
    return true if node instanceof Node and node.contains block
  false

# toString representation of the node, for inspecting the parse tree.
Node::toString: (idt) ->
  idt ||= ''
  '\n' + idt + @type + (child.toString(idt + TAB) for child in @children).join('')

# Default implementations of the common node methods.
Node::unwrap:               -> this
Node::children:             []
Node::is_statement:         -> false
Node::is_statement_only:    -> false
Node::top_sensitive:        -> false
Node::operation_sensitive:  -> false

# A collection of nodes, each one representing an expression.
Expressions: exports.Expressions: inherit Node, {
  type: 'Expressions'

  constructor: (nodes) ->
    @children: @expressions: compact flatten nodes or []
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
    last_index: if @expressions[l - 1] instanceof CommentNode then 2 else 1
    node is @expressions[l - last_index]

  compile: (o) ->
    o ||= {}
    if o.scope then Node::compile.call(this, o) else @compile_root(o)

  # Compile each expression in the Expressions body.
  compile_node: (o) ->
    (@compile_expression(node, merge(o)) for node in @expressions).join("\n")

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
    code: @idt() + "arguments = Array.prototype.slice.call(arguments, 0);\n" + code if args
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
    # Otherwise, we can just return the value of the expression.
    return @idt() + 'return ' + node.compile(o) + ';'

}

# Wrap up a node as an Expressions, unless it already is one.
Expressions.wrap: (nodes) ->
  return nodes[0] if nodes.length is 1 and nodes[0] instanceof Expressions
  new Expressions(nodes)

statement Expressions

# Literals are static values that can be passed through directly into
# JavaScript without translation, eg.: strings, numbers, true, false, null...
LiteralNode: exports.LiteralNode: inherit Node, {
  type: 'Literal'

  constructor: (value) ->
    @value: value
    this

  # Break and continue must be treated as statements -- they lose their meaning
  # when wrapped in a closure.
  is_statement: ->
    @value is 'break' or @value is 'continue'

  compile_node: (o) ->
    idt: if @is_statement() then @idt() else ''
    end: if @is_statement() then ';' else ''
    idt + @value + end

  toString: (idt) ->
    ' "' + @value + '"'

}

LiteralNode::is_statement_only: LiteralNode::is_statement

# Return an expression, or wrap it in a closure and return it.
ReturnNode: exports.ReturnNode: inherit Node, {
  type: 'Return'

  constructor: (expression) ->
    @children: [@expression: expression]
    this

  compile_node: (o) ->
    return @expression.compile(merge(o, {returns: true})) if @expression.is_statement()
    @idt() + 'return ' + @expression.compile(o) + ';'

}

statement ReturnNode, true

# A value, indexed or dotted into, or vanilla.
ValueNode: exports.ValueNode: inherit Node, {
  type: 'Value'

  SOAK: " == undefined ? undefined : "

  constructor: (base, properties) ->
    @children:   flatten [@base: base, @properties: (properties or [])]
    this

  push: (prop) ->
    @properties.push(prop)
    @children.push(prop)
    this

  operation_sensitive: ->
    true

  has_properties: ->
    !!@properties.length

  is_array: ->
    @base instanceof ArrayNode and not @has_properties()

  is_object: ->
    @base instanceof ObjectNode and not @has_properties()

  is_splice: ->
    @has_properties() and @properties[@properties.length - 1] instanceof SliceNode

  is_arguments: ->
    @base.value is 'arguments'

  unwrap: ->
    if @properties.length then this else @base

  # Values are statements if their base is a statement.
  is_statement: ->
    @base.is_statement and @base.is_statement() and not @has_properties()

  compile_node: (o) ->
    soaked:   false
    only:     del(o, 'only_first')
    op:       del(o, 'operation')
    props:    if only then @properties[0...@properties.length - 1] else @properties
    baseline: @base.compile o
    baseline: '(' + baseline + ')' if @base instanceof ObjectNode and @has_properties()
    complete: @last: baseline

    for prop in props
      @source: baseline
      if prop instanceof AccessorNode and prop.soak
        soaked: true
        if @base instanceof CallNode and prop is props[0]
          temp: o.scope.free_variable()
          complete: '(' + temp + ' = ' + complete + ')' + @SOAK + (baseline: temp + prop.compile(o))
        else
          complete: complete + @SOAK + (baseline += prop.compile(o))
      else
        part: prop.compile(o)
        baseline += part
        complete += part
        @last: part

    if op and soaked then '(' + complete + ')' else complete

}

# Pass through CoffeeScript comments into JavaScript comments at the
# same position.
CommentNode: exports.CommentNode: inherit Node, {
  type: 'Comment'

  constructor: (lines) ->
    @lines: lines
    this

  compile_node: (o) ->
    @idt() + '//' + @lines.join('\n' + @idt() + '//')

}

statement CommentNode

# Node for a function invocation. Takes care of converting super() calls into
# calls against the prototype's function of the same name.
CallNode: exports.CallNode: inherit Node, {
  type: 'Call'

  constructor: (variable, args) ->
    @children:  flatten [@variable: variable, @args: (args or [])]
    @prefix:    ''
    this

  new_instance: ->
    @prefix: 'new '
    this

  push: (arg) ->
    @args.push(arg)
    @children.push(arg)
    this

  # Compile a vanilla function call.
  compile_node: (o) ->
    return @compile_splat(o) if @args[@args.length - 1] instanceof SplatNode
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

}

# Node to extend an object's prototype with an ancestor object.
# After goog.inherits from the Closure Library.
ExtendsNode: exports.ExtendsNode: inherit Node, {
  type: 'Extends'

  constructor: (child, parent) ->
    @children:  [@child: child, @parent: parent]
    this

  # Hooking one constructor into another's prototype chain.
  compile_node: (o) ->
    construct:  o.scope.free_variable()
    child:      @child.compile(o)
    parent:     @parent.compile(o)
    prefix:     ''
    if not (@child instanceof ValueNode) or @child.has_properties() or not (@child.unwrap() instanceof LiteralNode)
      child_var: o.scope.free_variable()
      prefix += @idt() + child_var + ' = ' + child + ';\n'
      child: child_var
    if not (@parent instanceof ValueNode) or @parent.has_properties() or not (@parent.unwrap() instanceof LiteralNode)
      parent_var: o.scope.free_variable()
      prefix += @idt() + parent_var + ' = ' + parent + ';\n'
      parent: parent_var
    prefix + @idt() + construct + ' = function(){};\n' + @idt() +
      construct + '.prototype = ' + parent + ".prototype;\n" + @idt() +
      child + '.__superClass__ = ' + parent + ".prototype;\n" + @idt() +
      child + '.prototype = new ' + construct + "();\n" + @idt() +
      child + '.prototype.constructor = ' + child + ';'

}

statement ExtendsNode

# A dotted accessor into a part of a value, or the :: shorthand for
# an accessor into the object's prototype.
AccessorNode: exports.AccessorNode: inherit Node, {
  type: 'Accessor'

  constructor: (name, tag) ->
    @children:  [@name: name]
    @prototype: tag is 'prototype'
    @soak:      tag is 'soak'
    this

  compile_node: (o) ->
    '.' + (if @prototype then 'prototype.' else '') + @name.compile(o)

}

# An indexed accessor into a part of an array or object.
IndexNode: exports.IndexNode: inherit Node, {
  type: 'Index'

  constructor: (index) ->
    @children: [@index: index]
    this

  compile_node: (o) ->
    '[' + @index.compile(o) + ']'

}

# A range literal. Ranges can be used to extract portions (slices) of arrays,
# or to specify a range for list comprehensions.
RangeNode: exports.RangeNode: inherit Node, {
  type: 'Range'

  constructor: (from, to, exclusive) ->
    @children:  [@from: from, @to: to]
    @exclusive: !!exclusive
    this

  compile_variables: (o) ->
    @indent:   o.indent
    @from_var: o.scope.free_variable()
    @to_var:   o.scope.free_variable()
    @from_var + ' = ' + @from.compile(o) + '; ' + @to_var + ' = ' + @to.compile(o) + ";\n" + @idt()

  compile_node: (o) ->
    return    @compile_array(o) unless o.index
    idx:      del o, 'index'
    step:     del o, 'step'
    vars:     idx + '=' + @from_var
    step:     if step then step.compile(o) else '1'
    equals:   if @exclusive then '' else '='
    intro:    '(' + @from_var + ' <= ' + @to_var + ' ? ' + idx
    compare:  intro + ' <' + equals + ' ' + @to_var + ' : ' + idx + ' >' + equals + ' ' + @to_var + ')'
    incr:     intro + ' += ' + step + ' : ' + idx + ' -= ' + step + ')'
    vars + '; ' + compare + '; ' + incr

  # Expand the range into the equivalent array, if it's not being used as
  # part of a comprehension, slice, or splice.
  # TODO: This generates pretty ugly code ... shrink it.
  compile_array: (o) ->
    name: o.scope.free_variable()
    body: Expressions.wrap([new LiteralNode(name)])
    arr:  Expressions.wrap([new ForNode(body, {source: (new ValueNode(this))}, new LiteralNode(name))])
    (new ParentheticalNode(new CallNode(new CodeNode([], arr)))).compile(o)

}

# An array slice literal. Unlike JavaScript's Array#slice, the second parameter
# specifies the index of the end of the slice (just like the first parameter)
# is the index of the beginning.
SliceNode: exports.SliceNode: inherit Node, {
  type: 'Slice'

  constructor: (range) ->
    @children: [@range: range]
    this

  compile_node: (o) ->
    from:       @range.from.compile(o)
    to:         @range.to.compile(o)
    plus_part:  if @range.exclusive then '' else ' + 1'
    ".slice(" + from + ', ' + to + plus_part + ')'

}

# An object literal.
ObjectNode: exports.ObjectNode: inherit Node, {
  type: 'Object'

  constructor: (props) ->
    @children: @objects: @properties: props or []
    this

  # All the mucking about with commas is to make sure that CommentNodes and
  # AssignNodes get interleaved correctly, with no trailing commas or
  # commas affixed to comments. TODO: Extract this and add it to ArrayNode.
  compile_node: (o) ->
    o.indent: @idt(1)
    non_comments: prop for prop in @properties when not (prop instanceof CommentNode)
    last_noncom:  non_comments[non_comments.length - 1]
    props: for prop, i in @properties
      join:   ",\n"
      join:   "\n" if (prop is last_noncom) or (prop instanceof CommentNode)
      join:   '' if i is @properties.length - 1
      indent: if prop instanceof CommentNode then '' else @idt(1)
      indent + prop.compile(o) + join
    props: props.join('')
    inner: if props then '\n' + props + '\n' + @idt() else ''
    '{' + inner + '}'

}

# An array literal.
ArrayNode: exports.ArrayNode: inherit Node, {
  type: 'Array'

  constructor: (objects) ->
    @children: @objects: objects or []
    this

  compile_node: (o) ->
    o.indent: @idt(1)
    objects: for obj, i in @objects
      code: obj.compile(o)
      if obj instanceof CommentNode
        '\n' + code + '\n' + o.indent
      else if i is @objects.length - 1
        code
      else
        code + ', '
    objects: objects.join('')
    ending: if objects.indexOf('\n') >= 0 then "\n" + @idt() + ']' else ']'
    '[' + objects + ending

}

# A faux-node that is never created by the grammar, but is used during
# code generation to generate a quick "array.push(value)" tree of nodes.
PushNode: exports.PushNode: {

  wrap: (array, expressions) ->
    expr: expressions.unwrap()
    return expressions if expr.is_statement_only() or expr.contains (n) -> n.is_statement_only()
    Expressions.wrap([new CallNode(
      new ValueNode(new LiteralNode(array), [new AccessorNode(new LiteralNode('push'))]), [expr]
    )])

}

# A faux-node used to wrap an expressions body in a closure.
ClosureNode: exports.ClosureNode: {

  wrap: (expressions, statement) ->
    func: new ParentheticalNode(new CodeNode([], Expressions.wrap([expressions])))
    call: new CallNode(new ValueNode(func, [new AccessorNode(new LiteralNode('call'))]), [new LiteralNode('this')])
    if statement then Expressions.wrap([call]) else call

}

# Setting the value of a local variable, or the value of an object property.
AssignNode: exports.AssignNode: inherit Node, {
  type: 'Assign'

  PROTO_ASSIGN: /^(\S+)\.prototype/
  LEADING_DOT:  /^\.(prototype\.)?/

  constructor: (variable, value, context) ->
    @children: [@variable: variable, @value: value]
    @context: context
    this

  top_sensitive: ->
    true

  is_value: ->
    @variable instanceof ValueNode

  is_statement: ->
    @is_value() and (@variable.is_array() or @variable.is_object())

  compile_node: (o) ->
    top:    del o, 'top'
    return  @compile_pattern_match(o) if @is_statement()
    return  @compile_splice(o) if @is_value() and @variable.is_splice()
    stmt:   del o, 'as_statement'
    name:   @variable.compile(o)
    last:   if @is_value() then @variable.last.replace(@LEADING_DOT, '') else name
    match:  name.match(@PROTO_ASSIGN)
    proto:  match and match[1]
    if @value instanceof CodeNode
      @value.name:  last  if last.match(IDENTIFIER)
      @value.proto: proto if proto
    return name + ': ' + @value.compile(o) if @context is 'object'
    o.scope.find(name) unless @is_value() and @variable.has_properties()
    val: name + ' = ' + @value.compile(o)
    return @idt() + val + ';' if stmt
    val: '(' + val + ')' if not top or o.returns
    val: @idt() + 'return ' + val if o.returns
    val

  # Implementation of recursive pattern matching, when assigning array or
  # object literals to a value. Peeks at their properties to assign inner names.
  # See: http://wiki.ecmascript.org/doku.php?id=harmony:destructuring
  compile_pattern_match: (o) ->
    val_var: o.scope.free_variable()
    assigns: [@idt() + val_var + ' = ' + @value.compile(o) + ';']
    o.top: true
    o.as_statement: true
    for obj, i in @variable.base.objects
      idx: i
      [obj, idx]: [obj.value, obj.variable.base] if @variable.is_object()
      access_class: if @variable.is_array() then IndexNode else AccessorNode
      if obj instanceof SplatNode
        val: new LiteralNode(obj.compile_value(o, val_var, @variable.base.objects.indexOf(obj)))
      else
        idx: new LiteralNode(idx) unless typeof idx is 'object'
        val: new ValueNode(new LiteralNode(val_var), [new access_class(idx)])
      assigns.push(new AssignNode(obj, val).compile(o))
    assigns.join("\n")

  compile_splice: (o) ->
    name:   @variable.compile(merge(o, {only_first: true}))
    l:      @variable.properties.length
    range:  @variable.properties[l - 1].range
    plus:   if range.exclusive then '' else ' + 1'
    from:   range.from.compile(o)
    to:     range.to.compile(o) + ' - ' + from + plus
    name + '.splice.apply(' + name + ', [' + from + ', ' + to + '].concat(' + @value.compile(o) + '))'

}

# A function definition. The only node that creates a new Scope.
# A CodeNode does not have any children -- they're within the new scope.
CodeNode: exports.CodeNode: inherit Node, {
  type: 'Code'

  constructor: (params, body, tag) ->
    @params:  params
    @body:    body
    @bound:   tag is 'boundfunc'
    this

  compile_node: (o) ->
    shared_scope: del o, 'shared_scope'
    top:          del o, 'top'
    o.scope:      shared_scope or new Scope(o.scope, @body, this)
    o.returns:    true
    o.top:        true
    o.indent:     @idt(if @bound then 2 else 1)
    del o, 'no_wrap'
    del o, 'globals'
    if @params[@params.length - 1] instanceof SplatNode
      splat: @params.pop()
      splat.index: @params.length
      @body.unshift(splat)
    params: (param.compile(o) for param in @params)
    (o.scope.parameter(param)) for param in params
    code: if @body.expressions.length then '\n' + @body.compile_with_declarations(o) + '\n' else ''
    name_part: if @name then ' ' + @name else ''
    func: 'function' + (if @bound then '' else name_part) + '(' + params.join(', ') + ') {' + code + @idt(if @bound then 1 else 0) + '}'
    func: '(' + func + ')' if top and not @bound
    return func unless @bound
    inner: '(function' + name_part + '() {\n' + @idt(2) + 'return __func.apply(__this, arguments);\n' + @idt(1) + '});'
    '(function(__this) {\n' + @idt(1) + 'var __func = ' + func + ';\n' + @idt(1) + 'return ' + inner + '\n' + @idt() + '})(this)'

  top_sensitive: ->
    true

  toString: (idt) ->
    idt ||= ''
    children: flatten [@params, @body.expressions]
    '\n' + idt + @type + (child.toString(idt + TAB) for child in children).join('')

}

# A splat, either as a parameter to a function, an argument to a call,
# or in a destructuring assignment.
SplatNode: exports.SplatNode: inherit Node, {
  type: 'Splat'

  constructor: (name) ->
    name: new LiteralNode(name) unless name.compile
    @children: [@name: name]
    this

  compile_node: (o) ->
    if @index? then @compile_param(o) else @name.compile(o)

  compile_param: (o) ->
    name: @name.compile(o)
    o.scope.find name
    name + ' = Array.prototype.slice.call(arguments, ' + @index + ')'

  compile_value: (o, name, index) ->
    "Array.prototype.slice.call(" + name + ', ' + index + ')'

}

# A while loop, the only sort of low-level loop exposed by CoffeeScript. From
# it, all other loops can be manufactured.
WhileNode: exports.WhileNode: inherit Node, {
  type: 'While'

  constructor: (condition, opts) ->
    @children:[@condition: condition]
    @filter: opts and opts.filter
    this

  add_body: (body) ->
    @children.push @body: body
    this

  top_sensitive: ->
    true

  compile_node: (o) ->
    returns:    del(o, 'returns')
    top:        del(o, 'top') and not returns
    o.indent:   @idt(1)
    o.top:      true
    cond:       @condition.compile(o)
    set:        ''
    if not top
      rvar:     o.scope.free_variable()
      set:      @idt() + rvar + ' = [];\n'
      @body:    PushNode.wrap(rvar, @body) if @body
    post:       if returns then '\n' + @idt() + 'return ' + rvar + ';' else ''
    pre:        set + @idt() + 'while (' + cond + ')'
    return pre + ' null;' + post if not @body
    @body:      Expressions.wrap([new IfNode(@filter, @body)]) if @filter
    pre + ' {\n' + @body.compile(o) + '\n' + @idt() + '}' + post

}

statement WhileNode

# Simple Arithmetic and logical operations. Performs some conversion from
# CoffeeScript operations into their JavaScript equivalents.
OpNode: exports.OpNode: inherit Node, {
  type: 'Op'

  CONVERSIONS: {
    '==':   '==='
    '!=':   '!=='
    'and':  '&&'
    'or':   '||'
    'is':   '==='
    'isnt': '!=='
    'not':  '!'
  }

  CHAINABLE:        ['<', '>', '>=', '<=', '===', '!==']
  ASSIGNMENT:       ['||=', '&&=', '?=']
  PREFIX_OPERATORS: ['typeof', 'delete']

  constructor: (operator, first, second, flip) ->
    @type += ' ' + operator
    @children: compact [@first: first, @second: second]
    @operator: @CONVERSIONS[operator] or operator
    @flip: !!flip
    this

  is_unary: ->
    not @second

  is_chainable: ->
    @CHAINABLE.indexOf(@operator) >= 0

  compile_node: (o) ->
    o.operation: true
    return @compile_chain(o)      if @is_chainable() and @first.unwrap() instanceof OpNode and @first.unwrap().is_chainable()
    return @compile_assignment(o) if @ASSIGNMENT.indexOf(@operator) >= 0
    return @compile_unary(o)      if @is_unary()
    return @compile_existence(o)  if @operator is '?'
    @first.compile(o) + ' ' + @operator + ' ' + @second.compile(o)

  # Mimic Python's chained comparisons. See:
  # http://docs.python.org/reference/expressions.html#notin
  compile_chain: (o) ->
    shared: @first.unwrap().second
    [@first.second, shared]: shared.compile_reference(o) if shared instanceof CallNode
    '(' + @first.compile(o) + ') && (' + shared.compile(o) + ' ' + @operator + ' ' + @second.compile(o) + ')'

  compile_assignment: (o) ->
    [first, second]: [@first.compile(o), @second.compile(o)]
    o.scope.find(first) if first.match(IDENTIFIER)
    return first + ' = ' + ExistenceNode.compile_test(o, @first) + ' ? ' + first + ' : ' + second if @operator is '?='
    first + ' = ' + first + ' ' + @operator.substr(0, 2) + ' ' + second

  compile_existence: (o) ->
    [first, second]: [@first.compile(o), @second.compile(o)]
    ExistenceNode.compile_test(o, @first) + ' ? ' + first + ' : ' + second

  compile_unary: (o) ->
    space: if @PREFIX_OPERATORS.indexOf(@operator) >= 0 then ' ' else ''
    parts: [@operator, space, @first.compile(o)]
    parts: parts.reverse() if @flip
    parts.join('')

}

# A try/catch/finally block.
TryNode: exports.TryNode: inherit Node, {
  type: 'Try'

  constructor: (attempt, error, recovery, ensure) ->
    @children: compact [@attempt: attempt, @recovery: recovery, @ensure: ensure]
    @error: error
    this

  compile_node: (o) ->
    o.indent:     @idt(1)
    o.top:        true
    error_part:   if @error then ' (' + @error.compile(o) + ') ' else ' '
    catch_part:   (@recovery or '') and ' catch' + error_part + '{\n' + @recovery.compile(o) + '\n' + @idt() + '}'
    finally_part: (@ensure or '') and ' finally {\n' + @ensure.compile(merge(o, {returns: null})) + '\n' + @idt() + '}'
    @idt() + 'try {\n' + @attempt.compile(o) + '\n' + @idt() + '}' + catch_part + finally_part

}

statement TryNode

# Throw an exception.
ThrowNode: exports.ThrowNode: inherit Node, {
  type: 'Throw'

  constructor: (expression) ->
    @children: [@expression: expression]
    this

  compile_node: (o) ->
    @idt() + 'throw ' + @expression.compile(o) + ';'

}

statement ThrowNode, true

# Check an expression for existence (meaning not null or undefined).
ExistenceNode: exports.ExistenceNode: inherit Node, {
  type: 'Existence'

  constructor: (expression) ->
    @children: [@expression: expression]
    this

  compile_node: (o) ->
    ExistenceNode.compile_test(o, @expression)

}

ExistenceNode.compile_test: (o, variable) ->
  [first, second]: [variable, variable]
  if variable instanceof CallNode or (variable instanceof ValueNode and variable.has_properties())
    [first, second]: variable.compile_reference(o)
  '(typeof ' + first.compile(o) + ' !== "undefined" && ' + second.compile(o) + ' !== null)'

# An extra set of parentheses, specified explicitly in the source.
ParentheticalNode: exports.ParentheticalNode: inherit Node, {
  type: 'Paren'

  constructor: (expression) ->
    @children: [@expression: expression]
    this

  is_statement: ->
    @expression.is_statement()

  compile_node: (o) ->
    code: @expression.compile(o)
    return code if @is_statement()
    l:    code.length
    code: code.substr(o, l-1) if code.substr(l-1, 1) is ';'
    '(' + code + ')'

}

# The replacement for the for loop is an array comprehension (that compiles)
# into a for loop. Also acts as an expression, able to return the result
# of the comprehenion. Unlike Python array comprehensions, it's able to pass
# the current index of the loop as a second parameter.
ForNode: exports.ForNode: inherit Node, {
  type: 'For'

  constructor: (body, source, name, index) ->
    @body:    body
    @name:    name
    @index:   index or null
    @source:  source.source
    @filter:  source.filter
    @step:    source.step
    @object:  !!source.object
    [@name, @index]: [@index, @name] if @object
    @children: compact [@body, @source, @filter]
    this

  top_sensitive: ->
    true

  compile_node: (o) ->
    top_level:      del(o, 'top') and not o.returns
    range:          @source instanceof ValueNode and @source.base instanceof RangeNode and not @source.properties.length
    source:         if range then @source.base else @source
    scope:          o.scope
    name:           @name and @name.compile(o)
    index:          @index and @index.compile(o)
    name_found:     name and scope.find(name)
    index_found:    index and scope.find(index)
    body_dent:      @idt(1)
    rvar:           scope.free_variable() unless top_level
    svar:           scope.free_variable()
    ivar:           if range then name else index or scope.free_variable()
    var_part:       ''
    body:           Expressions.wrap([@body])
    if range
      index_var:    scope.free_variable()
      source_part:  source.compile_variables(o)
      for_part:     index_var + ' = 0, ' + source.compile(merge(o, {index: ivar, step: @step})) + ', ' + index_var + '++'
    else
      index_var:    null
      source_part:  svar + ' = ' + @source.compile(o) + ';\n' + @idt()
      step_part:    if @step then ivar + ' += ' + @step.compile(o) else ivar + '++'
      for_part:     ivar + ' = 0; ' + ivar + ' < ' + svar + '.length; ' + step_part
      var_part:     body_dent + name + ' = ' + svar + '[' + ivar + '];\n' if name
    set_result:     if rvar then @idt() + rvar + ' = []; ' else @idt()
    return_result:  rvar or ''
    body:           ClosureNode.wrap(body, true) if top_level and @contains (n) -> n instanceof CodeNode
    body:           PushNode.wrap(rvar, body) unless top_level
    if o.returns
      return_result: 'return ' + return_result
      del o, 'returns'
      body:         new IfNode(@filter, body, null, {statement: true}) if @filter
    else if @filter
      body:         Expressions.wrap([new IfNode(@filter, body)])
    if @object
      o.scope.assign('__hasProp', 'Object.prototype.hasOwnProperty', true)
      for_part: ivar + ' in ' + svar + ') { if (__hasProp.call(' + svar + ', ' + ivar + ')'
    return_result:  '\n' + @idt() + return_result + ';' unless top_level
    body:           body.compile(merge(o, {indent: body_dent, top: true}))
    vars:           if range then name else name + ', ' + ivar
    close:          if @object then '}}\n' else '}\n'
    set_result + source_part + 'for (' + for_part + ') {\n' + var_part + body + '\n' + @idt() + close + @idt() + return_result

}

statement ForNode

# If/else statements. Switch/whens get compiled into these. Acts as an
# expression by pushing down requested returns to the expression bodies.
# Single-expression IfNodes are compiled into ternary operators if possible,
# because ternaries are first-class returnable assignable expressions.
IfNode: exports.IfNode: inherit Node, {
  type: 'If'

  constructor: (condition, body, else_body, tags) ->
    @condition: condition
    @body:      body and body.unwrap()
    @else_body: else_body and else_body.unwrap()
    @children:  compact [@condition, @body, @else_body]
    @tags:      tags or {}
    @multiple:  true if @condition instanceof Array
    @condition: new OpNode('!', new ParentheticalNode(@condition)) if @tags.invert
    this

  push: (else_body) ->
    eb: else_body.unwrap()
    if @else_body then @else_body.push(eb) else @else_body: eb
    this

  force_statement: ->
    @tags.statement: true
    this

  # Tag a chain of IfNodes with their switch condition for equality.
  rewrite_condition: (expression) ->
    @switcher: expression
    this

  # Rewrite a chain of IfNodes with their switch condition for equality.
  rewrite_switch: (o) ->
    assigner: @switcher
    if not (@switcher.unwrap() instanceof LiteralNode)
      variable: new LiteralNode(o.scope.free_variable())
      assigner: new AssignNode(variable, @switcher)
      @switcher: variable
    @condition: if @multiple
      for cond, i in @condition
        new OpNode('is', (if i is 0 then assigner else @switcher), cond)
    else
      new OpNode('is', assigner, @condition)
    @else_body.rewrite_condition(@switcher) if @is_chain()
    this

  # Rewrite a chain of IfNodes to add a default case as the final else.
  add_else: (exprs, statement) ->
    if @is_chain()
      @else_body.add_else exprs, statement
    else
      exprs: exprs.unwrap() unless statement
      @children.push @else_body: exprs
    this

  # If the else_body is an IfNode itself, then we've got an if-else chain.
  is_chain: ->
    @chain ||= @else_body and @else_body instanceof IfNode

  # The IfNode only compiles into a statement if either of the bodies needs
  # to be a statement.
  is_statement: ->
    @statement ||= !!(@comment or @tags.statement or @body.is_statement() or (@else_body and @else_body.is_statement()))

  compile_condition: (o) ->
    (cond.compile(o) for cond in flatten([@condition])).join(' || ')

  compile_node: (o) ->
    if @is_statement() then @compile_statement(o) else @compile_ternary(o)

  # Compile the IfNode as a regular if-else statement. Flattened chains
  # force sub-else bodies into statement form.
  compile_statement: (o) ->
    @rewrite_switch(o) if @switcher
    child:        del o, 'chain_child'
    cond_o:       merge o
    del cond_o, 'returns'
    o.indent:     @idt(1)
    o.top:        true
    if_dent:      if child then '' else @idt()
    com_dent:     if child then @idt() else ''
    prefix:       if @comment then @comment.compile(cond_o) + '\n' + com_dent else ''
    body:         Expressions.wrap([@body]).compile(o)
    if_part:      prefix + if_dent + 'if (' + @compile_condition(cond_o) + ') {\n' + body + '\n' + @idt() + '}'
    return if_part unless @else_body
    else_part: if @is_chain()
      ' else ' + @else_body.compile(merge(o, {indent: @idt(), chain_child: true}))
    else
      ' else {\n' + Expressions.wrap([@else_body]).compile(o) + '\n' + @idt() + '}'
    if_part + else_part

  # Compile the IfNode into a ternary operator.
  compile_ternary: (o) ->
    if_part:    @condition.compile(o) + ' ? ' + @body.compile(o)
    else_part:  if @else_body then @else_body.compile(o) else 'null'
    if_part + ' : ' + else_part

}
