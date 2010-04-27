# `nodes.coffee` contains all of the node classes for the syntax tree. Most
# nodes are created as the result of actions in the [grammar](grammar.html),
# but some are created by other nodes as a method of code generation. To convert
# the syntax tree into a string of JavaScript code, call `compile()` on the root.

# Set up for both **Node.js** and the browser, by
# including the [Scope](scope.html) class and the [helper](helpers.html) functions.
if process?
  Scope:   require('./scope').Scope
  helpers: require('./helpers').helpers
else
  this.exports: this
  helpers:      this.helpers
  Scope:        this.Scope

# Import the helpers we plan to use.
{compact, flatten, merge, del}: helpers

# Helper function that marks a node as a JavaScript *statement*, or as a
# *pure_statement*. Statements must be wrapped in a closure when used as an
# expression, and nodes tagged as *pure_statement* cannot be closure-wrapped
# without losing their meaning.
statement: (klass, only) ->
  klass::is_statement: -> true
  (klass::is_pure_statement: -> true) if only

#### BaseNode

# The **BaseNode** is the abstract base class for all nodes in the syntax tree.
# Each subclass implements the `compile_node` method, which performs the
# code generation for that node. To compile a node to JavaScript,
# call `compile` on it, which wraps `compile_node` in some generic extra smarts,
# to know when the generated code needs to be wrapped up in a closure.
# An options hash is passed and cloned throughout, containing information about
# the environment from higher in the tree (such as if a returned value is
# being requested by the surrounding function), information about the current
# scope, and indentation level.
exports.BaseNode: class BaseNode

  # Common logic for determining whether to wrap this node in a closure before
  # compiling it, or to compile directly. We need to wrap if this node is a
  # *statement*, and it's not a *pure_statement*, and we're not at
  # the top level of a block (which would be unnecessary), and we haven't
  # already been asked to return the result (because statements know how to
  # return results).
  #
  # If a Node is *top_sensitive*, that means that it needs to compile differently
  # depending on whether it's being used as part of a larger expression, or is a
  # top-level statement within the function body.
  compile: (o) ->
    @options: merge o or {}
    @tab:     o.indent
    del @options, 'operation' unless this instanceof ValueNode
    top:      if @top_sensitive() then @options.top else del @options, 'top'
    closure:  @is_statement() and not @is_pure_statement() and not top and
              not @options.as_statement and not (this instanceof CommentNode) and
              not @contains_pure_statement()
    if closure then @compile_closure(@options) else @compile_node(@options)

  # Statements converted into expressions via closure-wrapping share a scope
  # object with their parent closure, to preserve the expected lexical scope.
  compile_closure: (o) ->
    @tab: o.indent
    o.shared_scope: o.scope
    ClosureNode.wrap(this).compile o

  # If the code generation wishes to use the result of a complex expression
  # in multiple places, ensure that the expression is only ever evaluated once,
  # by assigning it to a temporary variable.
  compile_reference: (o) ->
    reference: literal o.scope.free_variable()
    compiled:  new AssignNode reference, this
    [compiled, reference]

  # Convenience method to grab the current indentation level, plus tabbing in.
  idt: (tabs) ->
    idt: @tab or ''
    num: (tabs or 0) + 1
    idt: + TAB while num: - 1
    idt

  # Construct a node that returns the current node's result.
  # Note that this is overridden for smarter behavior for
  # many statement nodes (eg IfNode, ForNode)...
  make_return: ->
    new ReturnNode this

  # Does this node, or any of its children, contain a node of a certain kind?
  # Recursively traverses down the *children* of the nodes, yielding to a block
  # and returning true when the block finds a match. `contains` does not cross
  # scope boundaries.
  contains: (block) ->
    for node in @children
      return true if block(node)
      return true if node.contains and node.contains block
    false

  # Is this node of a certain type, or does it contain the type?
  contains_type: (type) ->
    this instanceof type or @contains (n) -> n instanceof type

  # Convenience for the most common use of contains. Does the node contain
  # a pure statement?
  contains_pure_statement: ->
    @is_pure_statement() or @contains (n) -> n.is_pure_statement()

  # Perform an in-order traversal of the AST. Crosses scope boundaries.
  traverse: (block) ->
    for node in @children
      block node
      node.traverse block if node.traverse

  # `toString` representation of the node, for inspecting the parse tree.
  # This is what `coffee --nodes` prints out.
  toString: (idt) ->
    idt: or ''
    '\n' + idt + @constructor.name + (child.toString(idt + TAB) for child in @children).join('')

  # Default implementations of the common node identification methods. Nodes
  # will override these with custom logic, if needed.
  unwrap:               -> this
  children:             []
  is_statement:         -> false
  is_pure_statement:    -> false
  top_sensitive:        -> false

#### Expressions

# The expressions body is the list of expressions that forms the body of an
# indented block of code -- the implementation of a function, a clause in an
# `if`, `switch`, or `try`, and so on...
exports.Expressions: class Expressions extends BaseNode

  constructor: (nodes) ->
    @children: @expressions: compact flatten nodes or []

  # Tack an expression on to the end of this expression list.
  push: (node) ->
    @expressions.push(node)
    this

  # Add an expression at the beginning of this expression list.
  unshift: (node) ->
    @expressions.unshift(node)
    this

  # If this Expressions consists of just a single node, unwrap it by pulling
  # it back out.
  unwrap: ->
    if @expressions.length is 1 then @expressions[0] else this

  # Is this an empty block of code?
  empty: ->
    @expressions.length is 0

  # Make a copy of this node.
  copy: ->
    new Expressions @children.slice()

  # An Expressions node does not return its entire body, rather it
  # ensures that the final expression is returned.
  make_return: ->
    idx:  @expressions.length - 1
    last: @expressions[idx]
    last: @expressions[idx: - 1] if last instanceof CommentNode
    return this if not last or last instanceof ReturnNode
    @expressions[idx]: last.make_return() unless last.contains_pure_statement()
    this

  # An **Expressions** is the only node that can serve as the root.
  compile: (o) ->
    o: or {}
    if o.scope then super(o) else @compile_root(o)

  compile_node: (o) ->
    (@compile_expression(node, merge(o)) for node in @expressions).join("\n")

  # If we happen to be the top-level **Expressions**, wrap everything in
  # a safety closure, unless requested not to.
  compile_root: (o) ->
    o.indent: @tab: if o.no_wrap then '' else TAB
    o.scope: new Scope(null, this, null)
    code: if o.globals then @compile_node(o) else @compile_with_declarations(o)
    code: code.replace(TRAILING_WHITESPACE, '')
    if o.no_wrap then code else "(function(){\n$code\n})();\n"

  # Compile the expressions body for the contents of a function, with
  # declarations of all inner variables pushed up to the top.
  compile_with_declarations: (o) ->
    code: @compile_node(o)
    code: "${@tab}var ${o.scope.compiled_assignments()};\n$code"  if o.scope.has_assignments(this)
    code: "${@tab}var ${o.scope.compiled_declarations()};\n$code" if o.scope.has_declarations(this)
    code

  # Compiles a single expression within the expressions body. If we need to
  # return the result, and it's an expression, simply return it. If it's a
  # statement, ask the statement to do so.
  compile_expression: (node, o) ->
    @tab: o.indent
    compiled_node: node.compile merge o, {top: true}
    if node.is_statement() then compiled_node else "${@idt()}$compiled_node;"

# Wrap up the given nodes as an **Expressions**, unless it already happens
# to be one.
Expressions.wrap: (nodes) ->
  return nodes[0] if nodes.length is 1 and nodes[0] instanceof Expressions
  new Expressions(nodes)

statement Expressions

#### LiteralNode

# Literals are static values that can be passed through directly into
# JavaScript without translation, such as: strings, numbers,
# `true`, `false`, `null`...
exports.LiteralNode: class LiteralNode extends BaseNode

  constructor: (value) ->
    @value: value

  # Break and continue must be treated as pure statements -- they lose their
  # meaning when wrapped in a closure.
  is_statement: ->
    @value is 'break' or @value is 'continue'
  is_pure_statement: LiteralNode::is_statement

  compile_node: (o) ->
    idt: if @is_statement() then @idt() else ''
    end: if @is_statement() then ';' else ''
    "$idt$@value$end"

  toString: (idt) ->
    " \"$@value\""

#### ReturnNode

# A `return` is a *pure_statement* -- wrapping it in a closure wouldn't
# make sense.
exports.ReturnNode: class ReturnNode extends BaseNode

  constructor: (expression) ->
    @children: [@expression: expression]

  top_sensitive: ->
    true

  compile_node: (o) ->
    expr: @expression.make_return()
    return expr.compile(o) unless expr instanceof ReturnNode
    del o, 'top'
    o.as_statement: true if @expression.is_statement()
    "${@tab}return ${@expression.compile(o)};"

statement ReturnNode, true

#### ValueNode

# A value, variable or literal or parenthesized, indexed or dotted into,
# or vanilla.
exports.ValueNode: class ValueNode extends BaseNode

  SOAK: " == undefined ? undefined : "

  # A **ValueNode** has a base and a list of property accesses.
  constructor: (base, properties) ->
    @children:   flatten [@base: base, @properties: (properties or [])]

  # Add a property access to the list.
  push: (prop) ->
    @properties.push(prop)
    @children.push(prop)
    this

  has_properties: ->
    !!@properties.length

  # Some boolean checks for the benefit of other nodes.

  is_array: ->
    @base instanceof ArrayNode and not @has_properties()

  is_object: ->
    @base instanceof ObjectNode and not @has_properties()

  is_splice: ->
    @has_properties() and @properties[@properties.length - 1] instanceof SliceNode

  make_return: ->
    if @has_properties() then super() else @base.make_return()

  # The value can be unwrapped as its inner node, if there are no attached
  # properties.
  unwrap: ->
    if @properties.length then this else @base

  # Values are considered to be statements if their base is a statement.
  is_statement: ->
    @base.is_statement and @base.is_statement() and not @has_properties()

  # We compile a value to JavaScript by compiling and joining each property.
  # Things get much more insteresting if the chain of properties has *soak*
  # operators `?.` interspersed. Then we have to take care not to accidentally
  # evaluate a anything twice when building the soak chain.
  compile_node: (o) ->
    soaked:   false
    only:     del(o, 'only_first')
    op:       del(o, 'operation')
    props:    if only then @properties[0...@properties.length - 1] else @properties
    baseline: @base.compile o
    baseline: "($baseline)" if @base instanceof ObjectNode and @has_properties()
    complete: @last: baseline

    for prop in props
      @source: baseline
      if prop.soak_node
        soaked: true
        if @base instanceof CallNode and prop is props[0]
          temp: o.scope.free_variable()
          complete: "($temp = $complete)$@SOAK" + (baseline: temp + prop.compile(o))
        else
          complete: complete + @SOAK + (baseline: + prop.compile(o))
      else
        part: prop.compile(o)
        baseline: + part
        complete: + part
        @last: part

    if op and soaked then "($complete)" else complete

#### CommentNode

# CoffeeScript passes through comments as JavaScript comments at the
# same position.
exports.CommentNode: class CommentNode extends BaseNode

  constructor: (lines) ->
    @lines: lines
    this

  make_return: ->
    this

  compile_node: (o) ->
    "$@tab//" + @lines.join("\n$@tab//")

statement CommentNode

#### CallNode

# Node for a function invocation. Takes care of converting `super()` calls into
# calls against the prototype's function of the same name.
exports.CallNode: class CallNode extends BaseNode

  constructor: (variable, args) ->
    @is_new:   false
    @is_super: variable is 'super'
    @variable: if @is_super then null else variable
    @children: compact flatten [@variable, @args: (args or [])]
    @compile_splat_arguments: SplatNode.compile_mixed_array <- @, @args

  # Tag this invocation as creating a new instance.
  new_instance: ->
    @is_new: true
    this

  prefix: ->
    if @is_new then 'new ' else ''

  # Grab the reference to the superclass' implementation of the current method.
  super_reference: (o) ->
    methname: o.scope.method.name
    meth: if o.scope.method.proto
      "${o.scope.method.proto}.__superClass__.$methname"
    else
      "${methname}.__superClass__.constructor"

  # Compile a vanilla function call.
  compile_node: (o) ->
    for arg in @args
      return @compile_splat(o) if arg instanceof SplatNode
    args: (arg.compile(o) for arg in @args).join(', ')
    return @compile_super(args, o) if @is_super
    "${@prefix()}${@variable.compile(o)}($args)"

  # `super()` is converted into a call against the superclass's implementation
  # of the current function.
  compile_super: (args, o) ->
    "${@super_reference(o)}.call(this${ if args.length then ', ' else '' }$args)"

  # If you call a function with a splat, it's converted into a JavaScript
  # `.apply()` call to allow an array of arguments to be passed.
  compile_splat: (o) ->
    meth: if @variable then @variable.compile(o) else @super_reference(o)
    obj:  @variable and @variable.source or 'this'
    if obj.match(/\(/)
      temp: o.scope.free_variable()
      obj:  temp
      meth: "($temp = ${ @variable.source })${ @variable.last }"
    "${@prefix()}${meth}.apply($obj, ${ @compile_splat_arguments(o) })"

#### CurryNode

# Binds a context object and a list of arguments to a function,
# returning the bound function. After ECMAScript 5, Prototype.js, and
# Underscore's `bind` functions.
exports.CurryNode: class CurryNode extends CallNode

  constructor: (meth, args) ->
    @children:  flatten [@meth: meth, @context: args[0], @args: (args.slice(1) or [])]
    @compile_splat_arguments: SplatNode.compile_mixed_array <- @, @args

  arguments: (o) ->
    for arg in @args
      return @compile_splat_arguments(o) if arg instanceof SplatNode
    (new ArrayNode(@args)).compile o

  compile_node: (o) ->
    utility 'slice'
    ref: new ValueNode literal utility 'bind'
    (new CallNode(ref, [@meth, @context, literal(@arguments(o))])).compile o


#### ExtendsNode

# Node to extend an object's prototype with an ancestor object.
# After `goog.inherits` from the
# [Closure Library](http://closure-library.googlecode.com/svn/docs/closure_goog_base.js.html).
exports.ExtendsNode: class ExtendsNode extends BaseNode

  constructor: (child, parent) ->
    @children:  [@child: child, @parent: parent]

  # Hooks one constructor into another's prototype chain.
  compile_node: (o) ->
    ref:  new ValueNode literal utility 'extends'
    (new CallNode ref, [@child, @parent]).compile o

#### AccessorNode

# A `.` accessor into a property of a value, or the `::` shorthand for
# an accessor into the object's prototype.
exports.AccessorNode: class AccessorNode extends BaseNode

  constructor: (name, tag) ->
    @children:  [@name: name]
    @prototype:tag is 'prototype'
    @soak_node: tag is 'soak'
    this

  compile_node: (o) ->
    proto_part: if @prototype then 'prototype.' else ''
    ".$proto_part${@name.compile(o)}"

#### IndexNode

# A `[ ... ]` indexed accessor into an array or object.
exports.IndexNode: class IndexNode extends BaseNode

  constructor: (index, tag) ->
    @children:  [@index: index]
    @soak_node: tag is 'soak'

  compile_node: (o) ->
    idx: @index.compile o
    "[$idx]"

#### RangeNode

# A range literal. Ranges can be used to extract portions (slices) of arrays,
# to specify a range for comprehensions, or as a value, to be expanded into the
# corresponding array of integers at runtime.
exports.RangeNode: class RangeNode extends BaseNode

  constructor: (from, to, exclusive) ->
    @children:  [@from: from, @to: to]
    @exclusive: !!exclusive

  # Compiles the range's source variables -- where it starts and where it ends.
  compile_variables: (o) ->
    @tab: o.indent
    [@from_var, @to_var]: [o.scope.free_variable(), o.scope.free_variable()]
    [from, to]:           [@from.compile(o), @to.compile(o)]
    "$@from_var = $from; $@to_var = $to;\n$@tab"

  # When compiled normally, the range returns the contents of the *for loop*
  # needed to iterate over the values in the range. Used by comprehensions.
  compile_node: (o) ->
    return    @compile_array(o) unless o.index
    idx:      del o, 'index'
    step:     del o, 'step'
    vars:     "$idx = $@from_var"
    step:     if step then step.compile(o) else '1'
    equals:   if @exclusive then '' else '='
    intro:    "($@from_var <= $@to_var ? $idx"
    compare:  "$intro <$equals $@to_var : $idx >$equals $@to_var)"
    incr:     "$intro += $step : $idx -= $step)"
    "$vars; $compare; $incr"

  # When used as a value, expand the range into the equivalent array. In the
  # future, the code this generates should probably be cleaned up by handwriting
  # it instead of wrapping nodes.
  compile_array: (o) ->
    name: o.scope.free_variable()
    body: Expressions.wrap([literal(name)])
    arr:  Expressions.wrap([new ForNode(body, {source: (new ValueNode(this))}, literal(name))])
    (new ParentheticalNode(new CallNode(new CodeNode([], arr.make_return())))).compile(o)

#### SliceNode

# An array slice literal. Unlike JavaScript's `Array#slice`, the second parameter
# specifies the index of the end of the slice, just as the first parameter
# is the index of the beginning.
exports.SliceNode: class SliceNode extends BaseNode

  constructor: (range) ->
    @children: [@range: range]
    this

  compile_node: (o) ->
    from:       @range.from.compile(o)
    to:         @range.to.compile(o)
    plus_part:  if @range.exclusive then '' else ' + 1'
    ".slice($from, $to$plus_part)"

#### ObjectNode

# An object literal, nothing fancy.
exports.ObjectNode: class ObjectNode extends BaseNode

  constructor: (props) ->
    @children: @objects: @properties: props or []

  # All the mucking about with commas is to make sure that CommentNodes and
  # AssignNodes get interleaved correctly, with no trailing commas or
  # commas affixed to comments.
  compile_node: (o) ->
    o.indent: @idt 1
    non_comments: prop for prop in @properties when not (prop instanceof CommentNode)
    last_noncom:  non_comments[non_comments.length - 1]
    props: for prop, i in @properties
      join:   ",\n"
      join:   "\n" if (prop is last_noncom) or (prop instanceof CommentNode)
      join:   '' if i is @properties.length - 1
      indent: if prop instanceof CommentNode then '' else @idt 1
      prop:   new AssignNode prop, prop, 'object' unless prop instanceof AssignNode or prop instanceof CommentNode
      indent + prop.compile(o) + join
    props: props.join('')
    inner: if props then '\n' + props + '\n' + @idt() else ''
    "{$inner}"

#### ArrayNode

# An array literal.
exports.ArrayNode: class ArrayNode extends BaseNode

  constructor: (objects) ->
    @children: @objects: objects or []
    @compile_splat_literal: SplatNode.compile_mixed_array <- @, @objects

  compile_node: (o) ->
    o.indent: @idt 1
    objects: []
    for obj, i in @objects
      code: obj.compile(o)
      if obj instanceof SplatNode
        return @compile_splat_literal @objects, o
      else if obj instanceof CommentNode
        objects.push "\n$code\n$o.indent"
      else if i is @objects.length - 1
        objects.push code
      else
        objects.push "$code, "
    objects: objects.join('')
    if objects.indexOf('\n') >= 0
      "[\n${@idt(1)}$objects\n$@tab]"
    else
      "[$objects]"

#### ClassNode

# The CoffeeScript class definition.
exports.ClassNode: class ClassNode extends BaseNode

  # Initialize a **ClassNode** with its name, an optional superclass, and a
  # list of prototype property assignments.
  constructor: (variable, parent, props) ->
    @children: compact flatten [@variable: variable, @parent: parent, @properties: props or []]
    @returns:  false

  make_return: ->
    @returns: true
    this

  # Instead of generating the JavaScript string directly, we build up the
  # equivalent syntax tree and compile that, in pieces. You can see the
  # constructor, property assignments, and inheritance getting built out below.
  compile_node: (o) ->
    extension:   @parent and new ExtendsNode(@variable, @parent)
    constructor: null
    props:       new Expressions()
    o.top:       true

    for prop in @properties
      [pvar, func]: [prop.variable, prop.value]
      if pvar and pvar.base.value is 'constructor' and func instanceof CodeNode
        func.body.push(new ReturnNode(literal('this')))
        constructor: new AssignNode(@variable, func)
      else
        if pvar
          access: if prop.context is 'this' then pvar.base.properties[0] else new AccessorNode(pvar, 'prototype')
          val:    new ValueNode(@variable, [access])
          prop:   new AssignNode(val, func)
        props.push prop

    unless constructor
      if @parent
        applied: new ValueNode(@parent, [new AccessorNode(literal('apply'))])
        constructor: new AssignNode(@variable, new CodeNode([], new Expressions([
          new CallNode(applied, [literal('this'), literal('arguments')])
        ])))
      else
        constructor: new AssignNode(@variable, new CodeNode())

    construct:                       @idt() + constructor.compile(o) + ';\n'
    props:     if props.empty() then '' else props.compile(o) + '\n'
    extension: if extension     then @idt() + extension.compile(o) + ';\n' else ''
    returns:   if @returns      then new ReturnNode(@variable).compile(o)  else ''
    "$construct$extension$props$returns"

statement ClassNode

#### AssignNode

# The **AssignNode** is used to assign a local variable to value, or to set the
# property of an object -- including within object literals.
exports.AssignNode: class AssignNode extends BaseNode

  # Matchers for detecting prototype assignments.
  PROTO_ASSIGN: /^(\S+)\.prototype/
  LEADING_DOT:  /^\.(prototype\.)?/

  constructor: (variable, value, context) ->
    @children: [@variable: variable, @value: value]
    @context: context

  top_sensitive: ->
    true

  is_value: ->
    @variable instanceof ValueNode

  make_return: ->
    return new Expressions [this, new ReturnNode(@variable)]

  is_statement: ->
    @is_value() and (@variable.is_array() or @variable.is_object())

  # Compile an assignment, delegating to `compile_pattern_match` or
  # `compile_splice` if appropriate. Keep track of the name of the base object
  # we've been assigned to, for correct internal references. If the variable
  # has not been seen yet within the current scope, declare it.
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
    val: @value.compile o
    return "$name: $val" if @context is 'object'
    o.scope.find name unless @is_value() and @variable.has_properties()
    val: "$name = $val"
    return "$@tab$val;" if stmt
    if top then val else "($val)"

  # Brief implementation of recursive pattern matching, when assigning array or
  # object literals to a value. Peeks at their properties to assign inner names.
  # See the [ECMAScript Harmony Wiki](http://wiki.ecmascript.org/doku.php?id=harmony:destructuring)
  # for details.
  compile_pattern_match: (o) ->
    val_var: o.scope.free_variable()
    value: if @value.is_statement() then ClosureNode.wrap(@value) else @value
    assigns: ["$@tab$val_var = ${ value.compile(o) };"]
    o.top: true
    o.as_statement: true
    splat: false
    for obj, i in @variable.base.objects
      # A regular array pattern-match.
      idx: i
      if @variable.is_object()
        if obj instanceof AssignNode
          # A regular object pattern-match.
          [obj, idx]: [obj.value, obj.variable.base]
        else
          # A shorthand `{a, b, c}: val` pattern-match.
          idx: obj
      if not (obj instanceof ValueNode or obj instanceof SplatNode)
        throw new Error 'pattern matching must use only identifiers on the left-hand side.'
      is_string: idx.value and idx.value.match IS_STRING
      access_class: if is_string or @variable.is_array() then IndexNode else AccessorNode
      if obj instanceof SplatNode and not splat
        val: literal(obj.compile_value(o, val_var,
          (oindex: @variable.base.objects.indexOf(obj)),
          (olength: @variable.base.objects.length) - oindex - 1))
        splat: true
      else
        idx: literal(if splat then "${val_var}.length - ${olength - idx}" else idx) if typeof idx isnt 'object'
        val: new ValueNode(literal(val_var), [new access_class(idx)])
      assigns.push(new AssignNode(obj, val).compile(o))
    code: assigns.join("\n")
    code

  # Compile the assignment from an array splice literal, using JavaScript's
  # `Array#splice` method.
  compile_splice: (o) ->
    name:   @variable.compile merge o, {only_first: true}
    l:      @variable.properties.length
    range:  @variable.properties[l - 1].range
    plus:   if range.exclusive then '' else ' + 1'
    from:   range.from.compile(o)
    to:     range.to.compile(o) + ' - ' + from + plus
    val:    @value.compile(o)
    "${name}.splice.apply($name, [$from, $to].concat($val))"

#### CodeNode

# A function definition. This is the only node that creates a new Scope.
# When for the purposes of walking the contents of a function body, the CodeNode
# has no *children* -- they're within the inner scope.
exports.CodeNode: class CodeNode extends BaseNode

  constructor: (params, body, tag) ->
    @params:  params or []
    @body:    body or new Expressions()
    @bound:   tag is 'boundfunc'

  # Compilation creates a new scope unless explicitly asked to share with the
  # outer scope. Handles splat parameters in the parameter list by peeking at
  # the JavaScript `arguments` objects. If the function is bound with the `=>`
  # arrow, generates a wrapper that saves the current value of `this` through
  # a closure.
  compile_node: (o) ->
    shared_scope: del o, 'shared_scope'
    top:          del o, 'top'
    o.scope:      shared_scope or new Scope(o.scope, @body, this)
    o.top:        true
    o.indent:     @idt(if @bound then 2 else 1)
    del o, 'no_wrap'
    del o, 'globals'
    i: 0
    splat: undefined
    params: []
    for param in @params
      if param instanceof SplatNode and not splat?
        splat: param
        splat.index: i
        @body.unshift(splat)
        splat.trailings: []
      else if splat?
        splat.trailings.push(param)
      else
        params.push(param)
      i: + 1
    params: (param.compile(o) for param in params)
    @body.make_return()
    (o.scope.parameter(param)) for param in params
    code: if @body.expressions.length then "\n${ @body.compile_with_declarations(o) }\n" else ''
    name_part: if @name then ' ' + @name else ''
    func: "function${ if @bound then '' else name_part }(${ params.join(', ') }) {$code${@idt(if @bound then 1 else 0)}}"
    func: "($func)" if top and not @bound
    return func unless @bound
    utility 'slice'
    ref: new ValueNode literal utility 'bind'
    (new CallNode ref, [literal(func), literal('this')]).compile o

  top_sensitive: ->
    true

  # When traversing (for printing or inspecting), return the real children of
  # the function -- the parameters and body of expressions.
  real_children: ->
    flatten [@params, @body.expressions]

  # Custom `traverse` implementation that uses the `real_children`.
  traverse: (block) ->
    block this
    child.traverse block for child in @real_children()

  toString: (idt) ->
    idt: or ''
    children: (child.toString(idt + TAB) for child in @real_children()).join('')
    "\n$idt$children"

#### SplatNode

# A splat, either as a parameter to a function, an argument to a call,
# or as part of a destructuring assignment.
exports.SplatNode: class SplatNode extends BaseNode

  constructor: (name) ->
    name: literal(name) unless name.compile
    @children: [@name: name]

  compile_node: (o) ->
    if @index? then @compile_param(o) else @name.compile(o)

  # Compiling a parameter splat means recovering the parameters that succeed
  # the splat in the parameter list, by slicing the arguments object.
  compile_param: (o) ->
    name: @name.compile(o)
    o.scope.find name
    i: 0
    for trailing in @trailings
      o.scope.assign(trailing.compile(o), "arguments[arguments.length - $@trailings.length + $i]")
      i: + 1
    "$name = ${utility('slice')}.call(arguments, $@index, arguments.length - ${@trailings.length})"

  # A compiling a splat as a destructuring assignment means slicing arguments
  # from the right-hand-side's corresponding array.
  compile_value: (o, name, index, trailings) ->
    trail: if trailings then ", ${name}.length - $trailings" else ''
    "${utility 'slice'}.call($name, $index$trail)"

  # Utility function that converts arbitrary number of elements, mixed with
  # splats, to a proper array
  @compile_mixed_array: (list, o) ->
    args: []
    i: 0
    for arg in list
      code: arg.compile o
      if not (arg instanceof SplatNode)
        prev: args[i - 1]
        if i is 1 and prev.substr(0, 1) is '[' and prev.substr(prev.length - 1, 1) is ']'
          args[i - 1]: "${prev.substr(0, prev.length - 1)}, $code]"
          continue
        else if i > 1 and prev.substr(0, 9) is '.concat([' and prev.substr(prev.length - 2, 2) is '])'
          args[i - 1]: "${prev.substr(0, prev.length - 2)}, $code])"
          continue
        else
          code: "[$code]"
      args.push(if i is 0 then code else ".concat($code)")
      i: + 1
    args.join('')

#### WhileNode

# A while loop, the only sort of low-level loop exposed by CoffeeScript. From
# it, all other loops can be manufactured. Useful in cases where you need more
# flexibility or more speed than a comprehension can provide.
exports.WhileNode: class WhileNode extends BaseNode

  constructor: (condition, opts) ->
    @children:[@condition: condition]
    @filter: opts and opts.filter

  add_body: (body) ->
    @children.push @body: body
    this

  make_return: ->
    @returns: true
    this

  top_sensitive: ->
    true

  # The main difference from a JavaScript *while* is that the CoffeeScript
  # *while* can be used as a part of a larger expression -- while loops may
  # return an array containing the computed result of each iteration.
  compile_node: (o) ->
    top:        del(o, 'top') and not @returns
    o.indent:   @idt 1
    o.top:      true
    cond:       @condition.compile(o)
    set:        ''
    unless top
      rvar:     o.scope.free_variable()
      set:      "$@tab$rvar = [];\n"
      @body:    PushNode.wrap(rvar, @body) if @body
    pre:        "$set${@tab}while ($cond)"
    return "$pre null;$post" if not @body
    @body:      Expressions.wrap([new IfNode(@filter, @body)]) if @filter
    if @returns
      post: new ReturnNode(literal(rvar)).compile(merge(o, {indent: @idt()}))
    else
      post: ''
    "$pre {\n${ @body.compile(o) }\n$@tab}\n$post"

statement WhileNode

#### OpNode

# Simple Arithmetic and logical operations. Performs some conversion from
# CoffeeScript operations into their JavaScript equivalents.
exports.OpNode: class OpNode extends BaseNode

  # The map of conversions from CoffeeScript to JavaScript symbols.
  CONVERSIONS: {
    '==': '==='
    '!=': '!=='
  }

  # The list of operators for which we perform
  # [Python-style comparison chaining](http://docs.python.org/reference/expressions.html#notin).
  CHAINABLE:        ['<', '>', '>=', '<=', '===', '!==']

  # Our assignment operators that have no JavaScript equivalent.
  ASSIGNMENT:       ['||=', '&&=', '?=']

  # Operators must come before their operands with a space.
  PREFIX_OPERATORS: ['typeof', 'delete']

  constructor: (operator, first, second, flip) ->
    @constructor.name: + ' ' + operator
    @children: compact [@first: first, @second: second]
    @operator: @CONVERSIONS[operator] or operator
    @flip: !!flip

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
    [@first.compile(o), @operator, @second.compile(o)].join ' '

  # Mimic Python's chained comparisons when multiple comparison operators are
  # used sequentially. For example:
  #
  #     bin/coffee -e "puts 50 < 65 > 10"
  #     true
  compile_chain: (o) ->
    shared: @first.unwrap().second
    [@first.second, shared]: shared.compile_reference(o) if shared.contains_type CallNode
    [first, second, shared]: [@first.compile(o), @second.compile(o), shared.compile(o)]
    "($first) && ($shared $@operator $second)"

  # When compiling a conditional assignment, take care to ensure that the
  # operands are only evaluated once, even though we have to reference them
  # more than once.
  compile_assignment: (o) ->
    [first, second]: [@first.compile(o), @second.compile(o)]
    o.scope.find(first) if first.match(IDENTIFIER)
    return "$first = ${ ExistenceNode.compile_test(o, @first) } ? $first : $second" if @operator is '?='
    "$first = $first ${ @operator.substr(0, 2) } $second"

  # If this is an existence operator, we delegate to `ExistenceNode.compile_test`
  # to give us the safe references for the variables.
  compile_existence: (o) ->
    [first, second]: [@first.compile(o), @second.compile(o)]
    test: ExistenceNode.compile_test(o, @first)
    "$test ? $first : $second"

  # Compile a unary **OpNode**.
  compile_unary: (o) ->
    space: if @PREFIX_OPERATORS.indexOf(@operator) >= 0 then ' ' else ''
    parts: [@operator, space, @first.compile(o)]
    parts: parts.reverse() if @flip
    parts.join('')

#### TryNode

# A classic *try/catch/finally* block.
exports.TryNode: class TryNode extends BaseNode

  constructor: (attempt, error, recovery, ensure) ->
    @children: compact [@attempt: attempt, @recovery: recovery, @ensure: ensure]
    @error: error
    this

  make_return: ->
    @attempt: @attempt.make_return() if @attempt
    @recovery: @recovery.make_return() if @recovery
    this

  # Compilation is more or less as you would expect -- the *finally* clause
  # is optional, the *catch* is not.
  compile_node: (o) ->
    o.indent:     @idt 1
    o.top:        true
    attempt_part: @attempt.compile(o)
    error_part:   if @error then " (${ @error.compile(o) }) " else ' '
    catch_part:   if @recovery then " catch$error_part{\n${ @recovery.compile(o) }\n$@tab}" else ''
    finally_part: (@ensure or '') and ' finally {\n' + @ensure.compile(merge(o)) + "\n$@tab}"
    "${@tab}try {\n$attempt_part\n$@tab}$catch_part$finally_part"

statement TryNode

#### ThrowNode

# Simple node to throw an exception.
exports.ThrowNode: class ThrowNode extends BaseNode

  constructor: (expression) ->
    @children: [@expression: expression]

  # A **ThrowNode** is already a return, of sorts...
  make_return: ->
    return this

  compile_node: (o) ->
    "${@tab}throw ${@expression.compile(o)};"

statement ThrowNode

#### ExistenceNode

# Checks a variable for existence -- not *null* and not *undefined*. This is
# similar to `.nil?` in Ruby, and avoids having to consult a JavaScript truth
# table.
exports.ExistenceNode: class ExistenceNode extends BaseNode

  constructor: (expression) ->
    @children: [@expression: expression]

  compile_node: (o) ->
    ExistenceNode.compile_test(o, @expression)

  # The meat of the **ExistenceNode** is in this static `compile_test` method
  # because other nodes like to check the existence of their variables as well.
  # Be careful not to double-evaluate anything.
  @compile_test: (o, variable) ->
    [first, second]: [variable, variable]
    if variable instanceof CallNode or (variable instanceof ValueNode and variable.has_properties())
      [first, second]: variable.compile_reference(o)
    [first, second]: [first.compile(o), second.compile(o)]
    "(typeof $first !== \"undefined\" && $second !== null)"

#### ParentheticalNode

# An extra set of parentheses, specified explicitly in the source. At one time
# we tried to clean up the results by detecting and removing redundant
# parentheses, but no longer -- you can put in as many as you please.
#
# Parentheses are a good way to force any statement to become an expression.
exports.ParentheticalNode: class ParentheticalNode extends BaseNode

  constructor: (expression) ->
    @children: [@expression: expression]

  is_statement: ->
    @expression.is_statement()

  make_return: ->
    @expression.make_return()

  compile_node: (o) ->
    code: @expression.compile(o)
    return code if @is_statement()
    l:    code.length
    code: code.substr(o, l-1) if code.substr(l-1, 1) is ';'
    if @expression instanceof AssignNode then code else "($code)"

#### ForNode

# CoffeeScript's replacement for the *for* loop is our array and object
# comprehensions, that compile into *for* loops here. They also act as an
# expression, able to return the result of each filtered iteration.
#
# Unlike Python array comprehensions, they can be multi-line, and you can pass
# the current index of the loop as a second parameter. Unlike Ruby blocks,
# you can map and filter in a single pass.
exports.ForNode: class ForNode extends BaseNode

  constructor: (body, source, name, index) ->
    @body:    body
    @name:    name
    @index:   index or null
    @source:  source.source
    @filter:  source.filter
    @step:    source.step
    @object:  !!source.object
    [@name, @index]: [@index, @name] if @object
    @pattern: @name instanceof ValueNode
    throw new Error('index cannot be a pattern matching expression') if @index instanceof ValueNode
    @children: compact [@body, @source, @filter]
    @returns: false

  top_sensitive: ->
    true

  make_return: ->
    @returns: true
    this

  compile_return_value: (val, o) ->
    return new ReturnNode(literal(val)).compile(o) if @returns
    val or ''

  # Welcome to the hairiest method in all of CoffeeScript. Handles the inner
  # loop, filtering, stepping, and result saving for array, object, and range
  # comprehensions. Some of the generated code can be shared in common, and
  # some cannot.
  compile_node: (o) ->
    top_level:      del(o, 'top') and not @returns
    range:          @source instanceof ValueNode and @source.base instanceof RangeNode and not @source.properties.length
    source:         if range then @source.base else @source
    scope:          o.scope
    name:           @name and @name.compile o
    index:          @index and @index.compile o
    scope.find name  if name and not @pattern
    scope.find index if index
    body_dent:      @idt 1
    rvar:           scope.free_variable() unless top_level
    ivar:           if range then name else index or scope.free_variable()
    var_part:       ''
    body:           Expressions.wrap([@body])
    if range
      index_var:    scope.free_variable()
      source_part:  source.compile_variables o
      for_part:     source.compile merge o, {index: ivar, step: @step}
      for_part:     "$index_var = 0, $for_part, $index_var++"
    else
      svar:         scope.free_variable()
      index_var:    null
      source_part:  "$svar = ${ @source.compile(o) };\n$@tab"
      if @pattern
        var_part:   new AssignNode(@name, literal("$svar[$ivar]")).compile(merge o, {indent: @idt(1), top: true}) + "\n"
      else
        var_part:   "$body_dent$name = $svar[$ivar];\n" if name
      unless @object
        lvar:       scope.free_variable()
        step_part:  if @step then "$ivar += ${ @step.compile(o) }" else "$ivar++"
        for_part:   "$ivar = 0, $lvar = ${svar}.length; $ivar < $lvar; $step_part"
    set_result:     if rvar then @idt() + rvar + ' = []; ' else @idt()
    return_result:  @compile_return_value(rvar, o)

    body:           ClosureNode.wrap(body, true) if top_level and body.contains (n) -> n instanceof CodeNode
    body:           PushNode.wrap(rvar, body) unless top_level
    if @filter
      body:         Expressions.wrap([new IfNode(@filter, body)])
    if @object
      for_part: "$ivar in $svar) { if (${utility('hasProp')}.call($svar, $ivar)"
    body:           body.compile(merge(o, {indent: body_dent, top: true}))
    vars:           if range then name else "$name, $ivar"
    close:          if @object then '}}\n' else '}\n'
    "$set_result${source_part}for ($for_part) {\n$var_part$body\n$@tab$close$return_result"

statement ForNode

#### IfNode

# *If/else* statements. Our *switch/when* will be compiled into this. Acts as an
# expression by pushing down requested returns to the last line of each clause.
#
# Single-expression **IfNodes** are compiled into ternary operators if possible,
# because ternaries are already proper expressions, and don't need conversion.
exports.IfNode: class IfNode extends BaseNode

  constructor: (condition, body, else_body, tags) ->
    @condition: condition
    @body:      body and body.unwrap()
    @else_body: else_body and else_body.unwrap()
    @children:  compact flatten [@condition, @body, @else_body]
    @tags:      tags or {}
    @multiple:  true if @condition instanceof Array
    @condition: new OpNode('!', new ParentheticalNode(@condition)) if @tags.invert

  # Add a new *else* clause to this **IfNode**, or push it down to the bottom
  # of the chain recursively.
  push: (else_body) ->
    eb: else_body.unwrap()
    if @else_body then @else_body.push(eb) else @else_body: eb
    this

  force_statement: ->
    @tags.statement: true
    this

  # Tag a chain of **IfNodes** with their object(s) to switch on for equality
  # tests. `rewrite_switch` will perform the actual change at compile time.
  rewrite_condition: (expression) ->
    @switcher: expression
    this

  # Rewrite a chain of **IfNodes** with their switch condition for equality.
  # Ensure that the switch expression isn't evaluated more than once.
  rewrite_switch: (o) ->
    assigner: @switcher
    unless @switcher.unwrap() instanceof LiteralNode
      variable: literal(o.scope.free_variable())
      assigner: new AssignNode(variable, @switcher)
      @switcher: variable
    @condition: if @multiple
      for cond, i in @condition
        new OpNode('==', (if i is 0 then assigner else @switcher), cond)
    else
      new OpNode('==', assigner, @condition)
    @else_body.rewrite_condition(@switcher) if @is_chain()
    this

  # Rewrite a chain of **IfNodes** to add a default case as the final *else*.
  add_else: (exprs, statement) ->
    if @is_chain()
      @else_body.add_else exprs, statement
    else
      exprs: exprs.unwrap() unless statement
      @children.push @else_body: exprs
    this

  # If the `else_body` is an **IfNode** itself, then we've got an *if-else* chain.
  is_chain: ->
    @chain: or @else_body and @else_body instanceof IfNode

  # The **IfNode** only compiles into a statement if either of its bodies needs
  # to be a statement. Otherwise a ternary is safe.
  is_statement: ->
    @statement: or !!(@comment or @tags.statement or @body.is_statement() or (@else_body and @else_body.is_statement()))

  compile_condition: (o) ->
    (cond.compile(o) for cond in flatten([@condition])).join(' || ')

  compile_node: (o) ->
    if @is_statement() then @compile_statement(o) else @compile_ternary(o)

  make_return: ->
    @body:      and @body.make_return()
    @else_body: and @else_body.make_return()
    this

  # Compile the **IfNode** as a regular *if-else* statement. Flattened chains
  # force inner *else* bodies into statement form.
  compile_statement: (o) ->
    @rewrite_switch(o) if @switcher
    child:        del o, 'chain_child'
    cond_o:       merge o
    o.indent:     @idt 1
    o.top:        true
    if_dent:      if child then '' else @idt()
    com_dent:     if child then @idt() else ''
    prefix:       if @comment then "${ @comment.compile(cond_o) }\n$com_dent" else ''
    body:         Expressions.wrap([@body]).compile(o)
    if_part:      "$prefix${if_dent}if (${ @compile_condition(cond_o) }) {\n$body\n$@tab}"
    return if_part unless @else_body
    else_part: if @is_chain()
      ' else ' + @else_body.compile(merge(o, {indent: @idt(), chain_child: true}))
    else
      " else {\n${ Expressions.wrap([@else_body]).compile(o) }\n$@tab}"
    "$if_part$else_part"

  # Compile the IfNode as a ternary operator.
  compile_ternary: (o) ->
    if_part:    @condition.compile(o) + ' ? ' + @body.compile(o)
    else_part:  if @else_body then @else_body.compile(o) else 'null'
    "$if_part : $else_part"

# Faux-Nodes
# ----------

#### PushNode

# Faux-nodes are never created by the grammar, but are used during code
# generation to generate other combinations of nodes. The **PushNode** creates
# the tree for `array.push(value)`, which is helpful for recording the result
# arrays from comprehensions.
PushNode: exports.PushNode: {

  wrap: (array, expressions) ->
    expr: expressions.unwrap()
    return expressions if expr.is_pure_statement() or expr.contains_pure_statement()
    Expressions.wrap([new CallNode(
      new ValueNode(literal(array), [new AccessorNode(literal('push'))]), [expr]
    )])

}

#### ClosureNode

# A faux-node used to wrap an expressions body in a closure.
ClosureNode: exports.ClosureNode: {

  # Wrap the expressions body, unless it contains a pure statement,
  # in which case, no dice. If the body mentions `this` or `arguments`,
  # then make sure that the closure wrapper preserves the original values.
  wrap: (expressions, statement) ->
    return expressions if expressions.contains_pure_statement()
    func: new ParentheticalNode(new CodeNode([], Expressions.wrap([expressions])))
    args: []
    mentions_args: expressions.contains (n) -> (n instanceof LiteralNode) and (n.value is 'arguments')
    mentions_this: expressions.contains (n) -> (n instanceof LiteralNode) and (n.value is 'this')
    if mentions_args or mentions_this
      meth: literal(if mentions_args then 'apply' else 'call')
      args: [literal('this')]
      args.push literal 'arguments' if mentions_args
      func: new ValueNode func, [new AccessorNode(meth)]
    call: new CallNode(func, args)
    if statement then Expressions.wrap([call]) else call

}

# Utility Functions
# -----------------

UTILITIES: {

  # Correctly set up a prototype chain for inheritance, including a reference
  # to the superclass for `super()` calls. See:
  # [goog.inherits](http://closure-library.googlecode.com/svn/docs/closure_goog_base.js.source.html#line1206).
  __extends:  """
              function(child, parent) {
                  var ctor = function(){ };
                  ctor.prototype = parent.prototype;
                  child.__superClass__ = parent.prototype;
                  child.prototype = new ctor();
                  child.prototype.constructor = child;
                }
              """

  # Bind a function to a calling context, optionally including curried arguments.
  # See [Underscore's implementation](http://jashkenas.github.com/coffee-script/documentation/docs/underscore.html#section-47).
  __bind:   """
            function(func, obj, args) {
                return function() {
                  return func.apply(obj || {}, args ? args.concat(__slice.call(arguments, 0)) : arguments);
                };
              }
            """

  # Shortcuts to speed up the lookup time for native functions.
  __hasProp: 'Object.prototype.hasOwnProperty'
  __slice: 'Array.prototype.slice'

}

# Constants
# ---------

# Tabs are two spaces for pretty printing.
TAB: '  '

# Trim out all trailing whitespace, so that the generated code plays nice
# with Git.
TRAILING_WHITESPACE: /\s+$/gm

# Keep this identifier regex in sync with the Lexer.
IDENTIFIER: /^[a-zA-Z\$_](\w|\$)*$/

# Is a literal value a string?
IS_STRING: /^['"]/

# Utility Functions
# -----------------

# Handy helper for a generating LiteralNode.
literal: (name) ->
  new LiteralNode(name)

# Helper for ensuring that utility functions are assigned at the top level.
utility: (name) ->
  ref: "__$name"
  Scope.root.assign ref, UTILITIES[ref]
  ref
