# `nodes.coffee` contains all of the node classes for the syntax tree. Most
# nodes are created as the result of actions in the [grammar](grammar.html),
# but some are created by other nodes as a method of code generation. To convert
# the syntax tree into a string of JavaScript code, call `compile()` on the root.

# Set up for both **Node.js** and the browser, by
# including the [Scope](scope.html) class.
if process?
  Scope:   require('./scope').Scope
  helpers: require('./helpers').helpers
else
  this.exports: this
  helpers:      this.helpers
  Scope:        this.Scope

# Import the helpers we need.
compact: helpers.compact
flatten: helpers.flatten
merge:   helpers.merge
del:     helpers.del

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
              not @options.returns and not (this instanceof CommentNode)
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
    idt += TAB while num -= 1
    idt

  # Does this node, or any of its children, contain a node of a certain kind?
  # Recursively traverses down the *children* of the nodes, yielding to a block
  # and returning true when the block finds a match. `contains` does not cross
  # scope boundaries.
  contains: (block) ->
    for node in @children
      return true if block(node)
      return true if node.contains and node.contains block
    false

  # Perform an in-order traversal of the AST. Crosses scope boundaries.
  traverse: (block) ->
    for node in @children
      block node
      node.traverse block if node.traverse

  # `toString` representation of the node, for inspecting the parse tree.
  # This is what `coffee --nodes` prints out.
  toString: (idt) ->
    idt ||= ''
    '\n' + idt + @type + (child.toString(idt + TAB) for child in @children).join('')

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
  type: 'Expressions'

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

  # Is the given node the last one in this block of expressions?
  is_last: (node) ->
    l: @expressions.length
    last_index: if @expressions[l - 1] instanceof CommentNode then 2 else 1
    node is @expressions[l - last_index]

  # An **Expressions** is the only node that can serve as the root.
  compile: (o) ->
    o ||= {}
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
    stmt:    node.is_statement()
    returns: del(o, 'returns') and @is_last(node) and not node.is_pure_statement()
    return (if stmt then '' else @idt()) + node.compile(merge(o, {top: true})) + (if stmt then '' else ';') unless returns
    return node.compile(merge(o, {returns: true})) if node.is_statement()
    "${@tab}return ${node.compile(o)};"

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
  type: 'Literal'

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
  type: 'Return'

  constructor: (expression) ->
    @children: [@expression: expression]

  compile_node: (o) ->
    return @expression.compile(merge(o, {returns: true})) if @expression.is_statement()
    "${@tab}return ${@expression.compile(o)};"

statement ReturnNode, true

#### ValueNode

# A value, variable or literal or parenthesized, indexed or dotted into,
# or vanilla.
exports.ValueNode: class ValueNode extends BaseNode
  type: 'Value'

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
          complete: complete + @SOAK + (baseline += prop.compile(o))
      else
        part: prop.compile(o)
        baseline += part
        complete += part
        @last: part

    if op and soaked then "($complete)" else complete

#### CommentNode

# CoffeeScript passes through comments as JavaScript comments at the
# same position.
exports.CommentNode: class CommentNode extends BaseNode
  type: 'Comment'

  constructor: (lines) ->
    @lines: lines
    this

  compile_node: (o) ->
    "$@tab//" + @lines.join("\n$@tab//")

statement CommentNode

#### CallNode

# Node for a function invocation. Takes care of converting `super()` calls into
# calls against the prototype's function of the same name.
exports.CallNode: class CallNode extends BaseNode
  type: 'Call'

  constructor: (variable, args) ->
    @children:  flatten [@variable: variable, @args: (args or [])]
    @prefix:    ''

  # Tag this invocation as creating a new instance.
  new_instance: ->
    @prefix: 'new '
    this

  # Compile a vanilla function call.
  compile_node: (o) ->
    for arg in @args
      return @compile_splat(o) if arg instanceof SplatNode
    args: (arg.compile(o) for arg in @args).join(', ')
    return @compile_super(args, o) if @variable is 'super'
    "$@prefix${@variable.compile(o)}($args)"

  # `super()` is converted into a call against the superclass's implementation
  # of the current function.
  compile_super: (args, o) ->
    methname: o.scope.method.name
    meth: if o.scope.method.proto
      "${o.scope.method.proto}.__superClass__.$methname"
    else
      "${methname}.__superClass__.constructor"
    "${meth}.call(this${ if args.length then ', ' else '' }$args)"

  # If you call a function with a splat, it's converted into a JavaScript
  # `.apply()` call to allow an array of arguments to be passed.
  compile_splat: (o) ->
    meth: @variable.compile o
    obj:  @variable.source or 'this'
    if obj.match(/\(/)
      temp: o.scope.free_variable()
      obj:  temp
      meth: "($temp = ${ @variable.source })${ @variable.last }"
    "$@prefix${meth}.apply($obj, ${ @compile_splat_arguments(o) })"
  
  # Converts arbitrary number of arguments, mixed with splats, to 
  # a proper array to pass to an `.apply()` call
  compile_splat_arguments: (o) ->
    args: []
    i: 0
    for arg in @args
      code: arg.compile o
      if not (arg instanceof SplatNode)
        prev: args[i - 1]
        if i is 1 and prev[0] is '[' and prev[prev.length - 1] is ']'
          args[i - 1] = "${prev[0...prev.length - 1]}, $code]"
          continue
        else if i > 1 and prev[8] is '[' and prev[prev.length - 2] is ']'
          args[i - 1] = "${prev[0...prev.length - 2]}, $code])"
          continue
        else
          code: "[$code]"
      args.push(if i is 0 then code else ".concat($code)")    
      i += 1
    args.join('')

#### ExtendsNode

# Node to extend an object's prototype with an ancestor object.
# After `goog.inherits` from the
# [Closure Library](http://closure-library.googlecode.com/svn/docs/closure_goog_base.js.html).
exports.ExtendsNode: class ExtendsNode extends BaseNode
  type: 'Extends'

  code: '''
        function(child, parent) {
            var ctor = function(){ };
            ctor.prototype = parent.prototype;
            child.__superClass__ = parent.prototype;
            child.prototype = new ctor();
            child.prototype.constructor = child;
          }
        '''

  constructor: (child, parent) ->
    @children:  [@child: child, @parent: parent]

  # Hooks one constructor into another's prototype chain.
  compile_node: (o) ->
    o.scope.assign('__extends', @code, true)
    ref:  new ValueNode literal('__extends')
    call: new CallNode ref, [@child, @parent]
    call.compile(o)

#### AccessorNode

# A `.` accessor into a property of a value, or the `::` shorthand for
# an accessor into the object's prototype.
exports.AccessorNode: class AccessorNode extends BaseNode
  type: 'Accessor'

  constructor: (name, tag) ->
    @children:  [@name: name]
    @prototype: tag is 'prototype'
    @soak_node: tag is 'soak'
    this

  compile_node: (o) ->
    proto_part: if @prototype then 'prototype.' else ''
    ".$proto_part${@name.compile(o)}"

#### IndexNode

# A `[ ... ]` indexed accessor into an array or object.
exports.IndexNode: class IndexNode extends BaseNode
  type: 'Index'

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
  type: 'Range'

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
    (new ParentheticalNode(new CallNode(new CodeNode([], arr)))).compile(o)

#### SliceNode

# An array slice literal. Unlike JavaScript's `Array#slice`, the second parameter
# specifies the index of the end of the slice, just as the first parameter
# is the index of the beginning.
exports.SliceNode: class SliceNode extends BaseNode
  type: 'Slice'

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
  type: 'Object'

  constructor: (props) ->
    @children: @objects: @properties: props or []

  # All the mucking about with commas is to make sure that CommentNodes and
  # AssignNodes get interleaved correctly, with no trailing commas or
  # commas affixed to comments.
  #
  # *TODO: Extract this and add it to ArrayNode*.
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
    "{$inner}"

#### ArrayNode

# An array literal.
exports.ArrayNode: class ArrayNode extends BaseNode
  type: 'Array'

  constructor: (objects) ->
    @children: @objects: objects or []

  compile_node: (o) ->
    o.indent: @idt(1)
    objects: for obj, i in @objects
      code: obj.compile(o)
      if obj instanceof CommentNode
        "\n$code\n$o.indent"
      else if i is @objects.length - 1
        code
      else
        "$code, "
    objects: objects.join('')
    ending: if objects.indexOf('\n') >= 0 then "\n$@tab]" else ']'
    "[$objects$ending"

#### ClassNode

# The CoffeeScript class definition.
exports.ClassNode: class ClassNode extends BaseNode
  type: 'Class'

  # Initialize a **ClassNode** with its name, an optional superclass, and a
  # list of prototype property assignments.
  constructor: (variable, parent, props) ->
    @children: compact flatten [@variable: variable, @parent: parent, @properties: props or []]

  # Instead of generating the JavaScript string directly, we build up the
  # equivalent syntax tree and compile that, in pieces. You can see the
  # constructor, property assignments, and inheritance getting built out below.
  compile_node: (o) ->
    extension:   @parent and new ExtendsNode(@variable, @parent)
    constructor: null
    props:       new Expressions()
    o.top:       true
    ret:         del o, 'returns'

    for prop in @properties
      if prop.variable and prop.variable.base.value is 'constructor'
        func: prop.value
        func.body.push(new ReturnNode(literal('this')))
        constructor: new AssignNode(@variable, func)
      else
        if prop.variable
          val: new ValueNode(@variable, [new AccessorNode(prop.variable, 'prototype')])
          prop: new AssignNode(val, prop.value)
        props.push prop

    if not constructor
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
    returns:   if ret           then '\n' + @idt() + 'return ' + @variable.compile(o) + ';' else ''
    "$construct$extension$props$returns"

statement ClassNode

#### AssignNode

# The **AssignNode** is used to assign a local variable to value, or to set the
# property of an object -- including within object literals.
exports.AssignNode: class AssignNode extends BaseNode
  type: 'Assign'

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
    val: "($val)" if not top or o.returns
    val: "${@tab}return $val" if o.returns
    val

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
    for obj, i in @variable.base.objects
      idx: i
      [obj, idx]: [obj.value, obj.variable.base] if @variable.is_object()
      access_class: if @variable.is_array() then IndexNode else AccessorNode
      if obj instanceof SplatNode
        val: literal(obj.compile_value(o, val_var, @variable.base.objects.indexOf(obj)))
      else
        idx: literal(idx) unless typeof idx is 'object'
        val: new ValueNode(literal(val_var), [new access_class(idx)])
      assigns.push(new AssignNode(obj, val).compile(o))
    code: assigns.join("\n")
    code += "\n${@tab}return ${ @variable.compile(o) };" if o.returns
    code

  # Compile the assignment from an array splice literal, using JavaScript's
  # `Array#splice` method.
  compile_splice: (o) ->
    name:   @variable.compile(merge(o, {only_first: true}))
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
  type: 'Code'

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
    o.returns:    true
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
      i += 1
    params: (param.compile(o) for param in params)
    (o.scope.parameter(param)) for param in params
    code: if @body.expressions.length then "\n${ @body.compile_with_declarations(o) }\n" else ''
    name_part: if @name then ' ' + @name else ''
    func: "function${ if @bound then '' else name_part }(${ params.join(', ') }) {$code${@idt(if @bound then 1 else 0)}}"
    func: "($func)" if top and not @bound
    return func unless @bound
    inner: "(function$name_part() {\n${@idt(2)}return __func.apply(__this, arguments);\n${@idt(1)}});"
    "(function(__this) {\n${@idt(1)}var __func = $func;\n${@idt(1)}return $inner\n$@tab})(this)"

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
    idt ||= ''
    children: (child.toString(idt + TAB) for child in @real_children()).join('')
    "\n$idt$children"

#### SplatNode

# A splat, either as a parameter to a function, an argument to a call,
# or as part of a destructuring assignment.
exports.SplatNode: class SplatNode extends BaseNode
  type: 'Splat'

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
      i += 1
    "$name = Array.prototype.slice.call(arguments, $@index, arguments.length - ${@trailings.length})"
  
  # A compiling a splat as a destructuring assignment means slicing arguments
  # from the right-hand-side's corresponding array.
  compile_value: (o, name, index) ->
    "Array.prototype.slice.call($name, $index)"

#### WhileNode

# A while loop, the only sort of low-level loop exposed by CoffeeScript. From
# it, all other loops can be manufactured. Useful in cases where you need more
# flexibility or more speed than a comprehension can provide.
exports.WhileNode: class WhileNode extends BaseNode
  type: 'While'

  constructor: (condition, opts) ->
    @children:[@condition: condition]
    @filter: opts and opts.filter

  add_body: (body) ->
    @children.push @body: body
    this

  top_sensitive: ->
    true

  # The main difference from a JavaScript *while* is that the CoffeeScript
  # *while* can be used as a part of a larger expression -- while loops may
  # return an array containing the computed result of each iteration.
  compile_node: (o) ->
    returns:    del(o, 'returns')
    top:        del(o, 'top') and not returns
    o.indent:   @idt(1)
    o.top:      true
    cond:       @condition.compile(o)
    set:        ''
    if not top
      rvar:     o.scope.free_variable()
      set:      "$@tab$rvar = [];\n"
      @body:    PushNode.wrap(rvar, @body) if @body
    post:       if returns then "\n${@tab}return $rvar;" else ''
    pre:        "$set${@tab}while ($cond)"
    return      "$pre null;$post" if not @body
    @body:      Expressions.wrap([new IfNode(@filter, @body)]) if @filter
    "$pre {\n${ @body.compile(o) }\n$@tab}$post"

statement WhileNode

#### OpNode

# Simple Arithmetic and logical operations. Performs some conversion from
# CoffeeScript operations into their JavaScript equivalents.
exports.OpNode: class OpNode extends BaseNode
  type: 'Op'

  # The map of conversions from CoffeeScript to JavaScript symbols.
  CONVERSIONS: {
    '==':   '==='
    '!=':   '!=='
    'and':  '&&'
    'or':   '||'
    'is':   '==='
    'isnt': '!=='
    'not':  '!'
  }

  # The list of operators for which we perform
  # [Python-style comparison chaining](http://docs.python.org/reference/expressions.html#notin).
  CHAINABLE:        ['<', '>', '>=', '<=', '===', '!==']

  # Our assignment operators that have no JavaScript equivalent.
  ASSIGNMENT:       ['||=', '&&=', '?=']

  # Operators must come before their operands with a space.
  PREFIX_OPERATORS: ['typeof', 'delete']

  constructor: (operator, first, second, flip) ->
    @type += ' ' + operator
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
    [@first.second, shared]: shared.compile_reference(o) if shared instanceof CallNode
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
  type: 'Try'

  constructor: (attempt, error, recovery, ensure) ->
    @children: compact [@attempt: attempt, @recovery: recovery, @ensure: ensure]
    @error: error
    this

  # Compilation is more or less as you would expect -- the *finally* clause
  # is optional, the *catch* is not.
  compile_node: (o) ->
    o.indent:     @idt(1)
    o.top:        true
    attempt_part: @attempt.compile(o)
    error_part:   if @error then " (${ @error.compile(o) }) " else ' '
    catch_part:   if @recovery then " catch$error_part{\n${ @recovery.compile(o) }\n$@tab}" else ''
    finally_part: (@ensure or '') and ' finally {\n' + @ensure.compile(merge(o, {returns: null})) + "\n$@tab}"
    "${@tab}try {\n$attempt_part\n$@tab}$catch_part$finally_part"

statement TryNode

#### ThrowNode

# Simple node to throw an exception.
exports.ThrowNode: class ThrowNode extends BaseNode
  type: 'Throw'

  constructor: (expression) ->
    @children: [@expression: expression]

  compile_node: (o) ->
    "${@tab}throw ${@expression.compile(o)};"

statement ThrowNode

#### ExistenceNode

# Checks a variable for existence -- not *null* and not *undefined*. This is
# similar to `.nil?` in Ruby, and avoids having to consult a JavaScript truth
# table.
exports.ExistenceNode: class ExistenceNode extends BaseNode
  type: 'Existence'

  constructor: (expression) ->
    @children: [@expression: expression]

  compile_node: (o) ->
    ExistenceNode.compile_test(o, @expression)

# The meat of the **ExistenceNode** is in this static `compile_test` method
# because other nodes like to check the existence of their variables as well.
# Be careful not to double-evaluate anything.
ExistenceNode.compile_test: (o, variable) ->
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
  type: 'Paren'

  constructor: (expression) ->
    @children: [@expression: expression]

  is_statement: ->
    @expression.is_statement()

  compile_node: (o) ->
    code: @expression.compile(o)
    return code if @is_statement()
    l:    code.length
    code: code.substr(o, l-1) if code.substr(l-1, 1) is ';'
    "($code)"

#### ForNode

# CoffeeScript's replacement for the *for* loop is our array and object
# comprehensions, that compile into *for* loops here. They also act as an
# expression, able to return the result of each filtered iteration.
#
# Unlike Python array comprehensions, they can be multi-line, and you can pass
# the current index of the loop as a second parameter. Unlike Ruby blocks,
# you can map and filter in a single pass.
exports.ForNode: class ForNode extends BaseNode
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

  top_sensitive: ->
    true

  # Welcome to the hairiest method in all of CoffeeScript. Handles the inner
  # loop, filtering, stepping, and result saving for array, object, and range
  # comprehensions. Some of the generated code can be shared in common, and
  # some cannot.
  compile_node: (o) ->
    top_level:      del(o, 'top') and not o.returns
    range:          @source instanceof ValueNode and @source.base instanceof RangeNode and not @source.properties.length
    source:         if range then @source.base else @source
    scope:          o.scope
    name:           @name and @name.compile o
    index:          @index and @index.compile o
    scope.find name  if name
    scope.find index if index
    body_dent:      @idt(1)
    rvar:           scope.free_variable() unless top_level
    svar:           scope.free_variable()
    ivar:           if range then name else index or scope.free_variable()
    var_part:       ''
    body:           Expressions.wrap([@body])
    if range
      index_var:    scope.free_variable()
      source_part:  source.compile_variables o
      for_part:     source.compile merge o, {index: ivar, step: @step}
      for_part:     "$index_var = 0, $for_part, $index_var++"
    else
      index_var:    null
      source_part:  "$svar = ${ @source.compile(o) };\n$@tab"
      var_part:     "$body_dent$name = $svar[$ivar];\n" if name
      if not @object
        lvar:       scope.free_variable()
        step_part:  if @step then "$ivar += ${ @step.compile(o) }" else "$ivar++"
        for_part:   "$ivar = 0, $lvar = ${svar}.length; $ivar < $lvar; $step_part"
    set_result:     if rvar then @idt() + rvar + ' = []; ' else @idt()
    return_result:  rvar or ''
    body:           ClosureNode.wrap(body, true) if top_level and body.contains (n) -> n instanceof CodeNode
    body:           PushNode.wrap(rvar, body) unless top_level
    if o.returns
      return_result: 'return ' + return_result
      del o, 'returns'
      body:         new IfNode(@filter, body, null, {statement: true}) if @filter
    else if @filter
      body:         Expressions.wrap([new IfNode(@filter, body)])
    if @object
      o.scope.assign('__hasProp', 'Object.prototype.hasOwnProperty', true)
      for_part: "$ivar in $svar) { if (__hasProp.call($svar, $ivar)"
    return_result:  "\n$@tab$return_result;" unless top_level
    body:           body.compile(merge(o, {indent: body_dent, top: true}))
    vars:           if range then name else "$name, $ivar"
    close:          if @object then '}}\n' else '}\n'
    "$set_result${source_part}for ($for_part) {\n$var_part$body\n$@tab$close$@tab$return_result"

statement ForNode

#### IfNode

# *If/else* statements. Our *switch/when* will be compiled into this. Acts as an
# expression by pushing down requested returns to the last line of each clause.
#
# Single-expression **IfNodes** are compiled into ternary operators if possible,
# because ternaries are already proper expressions, and don't need conversion.
exports.IfNode: class IfNode extends BaseNode
  type: 'If'

  constructor: (condition, body, else_body, tags) ->
    @condition: condition
    @body:      body and body.unwrap()
    @else_body: else_body and else_body.unwrap()
    @children:  compact [@condition, @body, @else_body]
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
    if not (@switcher.unwrap() instanceof LiteralNode)
      variable: literal(o.scope.free_variable())
      assigner: new AssignNode(variable, @switcher)
      @switcher: variable
    @condition: if @multiple
      for cond, i in @condition
        new OpNode('is', (if i is 0 then assigner else @switcher), cond)
    else
      new OpNode('is', assigner, @condition)
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
    @chain ||= @else_body and @else_body instanceof IfNode

  # The **IfNode** only compiles into a statement if either of its bodies needs
  # to be a statement. Otherwise a ternary is safe.
  is_statement: ->
    @statement ||= !!(@comment or @tags.statement or @body.is_statement() or (@else_body and @else_body.is_statement()))

  compile_condition: (o) ->
    (cond.compile(o) for cond in flatten([@condition])).join(' || ')

  compile_node: (o) ->
    if @is_statement() then @compile_statement(o) else @compile_ternary(o)

  # Compile the **IfNode** as a regular *if-else* statement. Flattened chains
  # force inner *else* bodies into statement form.
  compile_statement: (o) ->
    @rewrite_switch(o) if @switcher
    child:        del o, 'chain_child'
    cond_o:       merge o
    del cond_o, 'returns'
    o.indent:     @idt(1)
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
    return expressions if expr.is_pure_statement() or expr.contains (n) -> n.is_pure_statement()
    Expressions.wrap([new CallNode(
      new ValueNode(literal(array), [new AccessorNode(literal('push'))]), [expr]
    )])

}

#### ClosureNode

# A faux-node used to wrap an expressions body in a closure.
ClosureNode: exports.ClosureNode: {

  # Wrap the expressions body, unless it contains a pure statement,
  # in which case, no dice.
  wrap: (expressions, statement) ->
    return expressions if expressions.contains (n) -> n.is_pure_statement()
    func: new ParentheticalNode(new CodeNode([], Expressions.wrap([expressions])))
    call: new CallNode(new ValueNode(func, [new AccessorNode(literal('call'))]), [literal('this')])
    if statement then Expressions.wrap([call]) else call

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

# Utility Functions
# -----------------

# Handy helper for a generating LiteralNode.
literal: (name) ->
  new LiteralNode(name)
