# `nodes.coffee` contains all of the node classes for the syntax tree. Most
# nodes are created as the result of actions in the [grammar](grammar.html),
# but some are created by other nodes as a method of code generation. To convert
# the syntax tree into a string of JavaScript code, call `compile()` on the root.

# Set up for both **Node.js** and the browser, by
# including the [Scope](scope.html) class and the [helper](helpers.html) functions.
if process?
  Scope =   require('./scope').Scope
  helpers = require('./helpers').helpers
else
  this.exports = this
  helpers =      this.helpers
  Scope =        this.Scope

# Import the helpers we plan to use.
{compact, flatten, merge, del, include, indexOf, starts, ends} = helpers

#### BaseNode

# The **BaseNode** is the abstract base class for all nodes in the syntax tree.
# Each subclass implements the `compileNode` method, which performs the
# code generation for that node. To compile a node to JavaScript,
# call `compile` on it, which wraps `compileNode` in some generic extra smarts,
# to know when the generated code needs to be wrapped up in a closure.
# An options hash is passed and cloned throughout, containing information about
# the environment from higher in the tree (such as if a returned value is
# being requested by the surrounding function), information about the current
# scope, and indentation level.
exports.BaseNode = class BaseNode

  # Common logic for determining whether to wrap this node in a closure before
  # compiling it, or to compile directly. We need to wrap if this node is a
  # *statement*, and it's not a *pureStatement*, and we're not at
  # the top level of a block (which would be unnecessary), and we haven't
  # already been asked to return the result (because statements know how to
  # return results).
  #
  # If a Node is *topSensitive*, that means that it needs to compile differently
  # depending on whether it's being used as part of a larger expression, or is a
  # top-level statement within the function body.
  compile: (o) ->
    @options = merge o or {}
    @tab     = o.indent
    unless this instanceof ValueNode or this instanceof CallNode
      del @options, 'operation'
      del @options, 'chainRoot' unless this instanceof AccessorNode or this instanceof IndexNode
    top     = if @topSensitive() then @options.top else del @options, 'top'
    closure = @isStatement() and not @isPureStatement() and not top and
              not @options.asStatement and not (this instanceof CommentNode) and
              not @containsPureStatement()
    if closure then @compileClosure(@options) else @compileNode(@options)

  # Statements converted into expressions via closure-wrapping share a scope
  # object with their parent closure, to preserve the expected lexical scope.
  compileClosure: (o) ->
    @tab = o.indent
    o.sharedScope = o.scope
    ClosureNode.wrap(this).compile o

  # If the code generation wishes to use the result of a complex expression
  # in multiple places, ensure that the expression is only ever evaluated once,
  # by assigning it to a temporary variable.
  compileReference: (o, options) ->
    options or= {}
    pair = if not ((this instanceof CallNode or @contains((n) -> n instanceof CallNode)) or
                  (this instanceof ValueNode and (not (@base instanceof LiteralNode) or @hasProperties())))
      [this, this]
    else if this instanceof ValueNode and options.assignment
      this.cacheIndexes(o)
    else
      reference = literal o.scope.freeVariable()
      compiled  = new AssignNode reference, this
      [compiled, reference]
    return [pair[0].compile(o), pair[1].compile(o)] if options.precompile
    pair

  # Convenience method to grab the current indentation level, plus tabbing in.
  idt: (tabs) ->
    idt = @tab or ''
    num = (tabs or 0) + 1
    idt += TAB while num -= 1
    idt

  # Construct a node that returns the current node's result.
  # Note that this is overridden for smarter behavior for
  # many statement nodes (eg IfNode, ForNode)...
  makeReturn: ->
    new ReturnNode this

  # Does this node, or any of its children, contain a node of a certain kind?
  # Recursively traverses down the *children* of the nodes, yielding to a block
  # and returning true when the block finds a match. `contains` does not cross
  # scope boundaries.
  contains: (block) ->
    contains = false
    @traverseChildren false, (node) ->
      if block(node)
        contains = true
        return false
    contains

  # Is this node of a certain type, or does it contain the type?
  containsType: (type) ->
    this instanceof type or @contains (n) -> n instanceof type

  # Convenience for the most common use of contains. Does the node contain
  # a pure statement?
  containsPureStatement: ->
    @isPureStatement() or @contains (n) -> n.isPureStatement and n.isPureStatement()

  # Perform an in-order traversal of the AST. Crosses scope boundaries.
  traverse: (block) -> @traverseChildren true, block

  # `toString` representation of the node, for inspecting the parse tree.
  # This is what `coffee --nodes` prints out.
  toString: (idt, override) ->
    idt or= ''
    children = (child.toString idt + TAB for child in @collectChildren()).join('')
    '\n' + idt + (override or @class) + children

  eachChild: (func) ->
    return unless @children
    for attr in @children when this[attr]
      for child in flatten [this[attr]]
        return if func(child) is false

  collectChildren: ->
    nodes = []
    @eachChild (node) -> nodes.push node
    nodes

  traverseChildren: (crossScope, func) ->
    @eachChild (child) ->
      func.apply(this, arguments)
      child.traverseChildren(crossScope, func) if child instanceof BaseNode

  # Default implementations of the common node properties and methods. Nodes
  # will override these with custom logic, if needed.
  class:    'BaseNode'
  children: []

  unwrap          : -> this
  isStatement     : -> no
  isPureStatement : -> no
  topSensitive    : -> no

#### Expressions

# The expressions body is the list of expressions that forms the body of an
# indented block of code -- the implementation of a function, a clause in an
# `if`, `switch`, or `try`, and so on...
exports.Expressions = class Expressions extends BaseNode

  class:        'Expressions'
  children:     ['expressions']
  isStatement:  -> yes

  constructor: (nodes) ->
    @expressions = compact flatten nodes or []

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

  # An Expressions node does not return its entire body, rather it
  # ensures that the final expression is returned.
  makeReturn: ->
    idx  = @expressions.length - 1
    last = @expressions[idx]
    last = @expressions[idx -= 1] if last instanceof CommentNode
    return this if not last or last instanceof ReturnNode
    @expressions[idx] = last.makeReturn()
    this

  # An **Expressions** is the only node that can serve as the root.
  compile: (o) ->
    o or= {}
    if o.scope then super(o) else @compileRoot(o)

  compileNode: (o) ->
    (@compileExpression(node, merge(o)) for node in @expressions).join("\n")

  # If we happen to be the top-level **Expressions**, wrap everything in
  # a safety closure, unless requested not to.
  # It would be better not to generate them in the first place, but for now,
  # clean up obvious double-parentheses.
  compileRoot: (o) ->
    o.indent  = @tab = if o.noWrap then '' else TAB
    o.scope   = new Scope(null, this, null)
    code      = @compileWithDeclarations(o)
    code      = code.replace(TRAILING_WHITESPACE, '')
    if o.noWrap then code else "(function() {\n#{code}\n})();\n"

  # Compile the expressions body for the contents of a function, with
  # declarations of all inner variables pushed up to the top.
  compileWithDeclarations: (o) ->
    code = @compileNode(o)
    code = "#{@tab}var #{o.scope.compiledAssignments()};\n#{code}"  if o.scope.hasAssignments(this)
    code = "#{@tab}var #{o.scope.compiledDeclarations()};\n#{code}" if not o.globals and o.scope.hasDeclarations(this)
    code

  # Compiles a single expression within the expressions body. If we need to
  # return the result, and it's an expression, simply return it. If it's a
  # statement, ask the statement to do so.
  compileExpression: (node, o) ->
    @tab = o.indent
    compiledNode = node.compile merge o, top: true
    if node.isStatement() then compiledNode else "#{@idt()}#{compiledNode};"

# Wrap up the given nodes as an **Expressions**, unless it already happens
# to be one.
Expressions.wrap = (nodes) ->
  return nodes[0] if nodes.length is 1 and nodes[0] instanceof Expressions
  new Expressions(nodes)

#### LiteralNode

# Literals are static values that can be passed through directly into
# JavaScript without translation, such as: strings, numbers,
# `true`, `false`, `null`...
exports.LiteralNode = class LiteralNode extends BaseNode

  class: 'LiteralNode'

  constructor: (@value) ->

  makeReturn: ->
    if @isStatement() then this else super()

  # Break and continue must be treated as pure statements -- they lose their
  # meaning when wrapped in a closure.
  isStatement: ->
    @value is 'break' or @value is 'continue'
  isPureStatement: LiteralNode::isStatement

  compileNode: (o) ->
    idt = if @isStatement() then @idt() else ''
    end = if @isStatement() then ';' else ''
    idt + @value + end

  toString: (idt) ->
    '"' + @value + '"'

#### ReturnNode

# A `return` is a *pureStatement* -- wrapping it in a closure wouldn't
# make sense.
exports.ReturnNode = class ReturnNode extends BaseNode

  class:            'ReturnNode'
  isStatement:      -> yes
  isPureStatement:  -> yes
  children:         ['expression']

  constructor: (@expression) ->

  makeReturn: ->
    this

  compile: (o) ->
    expr = @expression.makeReturn()
    return expr.compile o unless expr instanceof ReturnNode
    super o

  compileNode: (o) ->
    o.asStatement = true if @expression.isStatement()
    "#{@tab}return #{@expression.compile(o)};"

#### ValueNode

# A value, variable or literal or parenthesized, indexed or dotted into,
# or vanilla.
exports.ValueNode = class ValueNode extends BaseNode

  SOAK:     " == undefined ? undefined : "

  class:     'ValueNode'
  children: ['base', 'properties']

  # A **ValueNode** has a base and a list of property accesses.
  constructor: (@base, @properties) ->
    @properties or= []

  # Add a property access to the list.
  push: (prop) ->
    @properties.push(prop)
    this

  hasProperties: ->
    !!@properties.length

  # Some boolean checks for the benefit of other nodes.

  isArray: ->
    @base instanceof ArrayNode and not @hasProperties()

  isObject: ->
    @base instanceof ObjectNode and not @hasProperties()

  isSplice: ->
    @hasProperties() and @properties[@properties.length - 1] instanceof SliceNode

  makeReturn: ->
    if @hasProperties() then super() else @base.makeReturn()

  # The value can be unwrapped as its inner node, if there are no attached
  # properties.
  unwrap: ->
    if @properties.length then this else @base

  # Values are considered to be statements if their base is a statement.
  isStatement: ->
    @base.isStatement and @base.isStatement() and not @hasProperties()

  isNumber: ->
    @base instanceof LiteralNode and @base.value.match NUMBER

  # Works out if the value is the start of a chain.
  isStart: (o) ->
    return true if this is o.chainRoot and @properties[0] instanceof AccessorNode
    node = o.chainRoot.base or o.chainRoot.variable
    while node instanceof CallNode then node = node.variable
    node is this

  # If the value node has indexes containing function calls, and the value node
  # needs to be used twice, in compound assignment ... then we need to cache
  # the value of the indexes.
  cacheIndexes: (o) ->
    copy = new ValueNode @base, @properties.slice 0
    for prop, i in copy.properties
      if prop instanceof IndexNode and prop.contains((n) -> n instanceof CallNode)
        [index, indexVar] = prop.index.compileReference o
        this.properties[i] = new IndexNode index
        copy.properties[i] = new IndexNode indexVar
    [this, copy]

  # Override compile to unwrap the value when possible.
  compile: (o) ->
    if not o.top or @properties.length then super(o) else @base.compile(o)

  # We compile a value to JavaScript by compiling and joining each property.
  # Things get much more insteresting if the chain of properties has *soak*
  # operators `?.` interspersed. Then we have to take care not to accidentally
  # evaluate a anything twice when building the soak chain.
  compileNode: (o) ->
    only        = del o, 'onlyFirst'
    op          = del o, 'operation'
    props       = if only then @properties[0...@properties.length - 1] else @properties
    o.chainRoot or= this
    baseline    = @base.compile o
    baseline    = "(#{baseline})" if @hasProperties() and (@base instanceof ObjectNode or @isNumber())
    complete    = @last = baseline

    for prop, i in props
      @source = baseline
      if prop.soakNode
        if @base instanceof CallNode or @base.contains((n) -> n instanceof CallNode) and i is 0
          temp = o.scope.freeVariable()
          complete = "(#{ baseline = temp } = (#{complete}))"
        complete = "typeof #{complete} === \"undefined\" || #{baseline}" if i is 0 and @isStart(o)
        complete += @SOAK + (baseline += prop.compile(o))
      else
        part = prop.compile(o)
        baseline += part
        complete += part
        @last = part

    if op and @wrapped then "(#{complete})" else complete

#### CommentNode

# CoffeeScript passes through block comments as JavaScript block comments
# at the same position.
exports.CommentNode = class CommentNode extends BaseNode

  class: 'CommentNode'
  isStatement: -> yes

  constructor: (@lines) ->

  makeReturn: ->
    this

  compileNode: (o) ->
    sep = '\n' + @tab
    "#{@tab}/*##{sep + @lines.join(sep) }\n#{@tab}*/"

#### CallNode

# Node for a function invocation. Takes care of converting `super()` calls into
# calls against the prototype's function of the same name.
exports.CallNode = class CallNode extends BaseNode

  class:     'CallNode'
  children: ['variable', 'args']

  constructor: (variable, @args) ->
    @isNew    = false
    @isSuper  = variable is 'super'
    @variable = if @isSuper then null else variable
    @args     or= []
    @compileSplatArguments = (o) ->
      SplatNode.compileSplattedArray.call(this, @args, o)

  # Tag this invocation as creating a new instance.
  newInstance: ->
    @isNew = true
    this

  prefix: ->
    if @isNew then 'new ' else ''

  # Grab the reference to the superclass' implementation of the current method.
  superReference: (o) ->
    methname = o.scope.method.name
    meth = if o.scope.method.proto
      "#{o.scope.method.proto}.__superClass__.#{methname}"
    else if methname
      "#{methname}.__superClass__.constructor"
    else throw new Error "cannot call super on an anonymous function."

  # Compile a vanilla function call.
  compileNode: (o) ->
    o.chainRoot = this unless o.chainRoot
    for arg in @args when arg instanceof SplatNode
      compilation = @compileSplat(o)
    unless compilation
      args = (arg.compile(o) for arg in @args).join(', ')
      compilation = if @isSuper then @compileSuper(args, o)
      else "#{@prefix()}#{@variable.compile(o)}(#{args})"
    if o.operation and @wrapped then "(#{compilation})" else compilation

  # `super()` is converted into a call against the superclass's implementation
  # of the current function.
  compileSuper: (args, o) ->
    "#{@superReference(o)}.call(this#{ if args.length then ', ' else '' }#{args})"

  # If you call a function with a splat, it's converted into a JavaScript
  # `.apply()` call to allow an array of arguments to be passed.
  # If it's a constructor, then things get real tricky. We have to inject an
  # inner constructor in order to be able to pass the varargs.
  compileSplat: (o) ->
    meth = if @variable then @variable.compile(o) else @superReference(o)
    obj =  @variable and @variable.source or 'this'
    if obj.match(/\(/)
      temp = o.scope.freeVariable()
      obj =  temp
      meth = "(#{temp} = #{ @variable.source })#{ @variable.last }"
    if @isNew
      utility 'extends'
      """
      (function() {
      #{@idt(1)}var ctor = function(){};
      #{@idt(1)}__extends(ctor, #{meth});
      #{@idt(1)}return #{meth}.apply(new ctor, #{ @compileSplatArguments(o) });
      #{@tab}}).call(this)
      """
    else
      "#{@prefix()}#{meth}.apply(#{obj}, #{ @compileSplatArguments(o) })"

#### ExtendsNode

# Node to extend an object's prototype with an ancestor object.
# After `goog.inherits` from the
# [Closure Library](http://closure-library.googlecode.com/svn/docs/closureGoogBase.js.html).
exports.ExtendsNode = class ExtendsNode extends BaseNode

  class:     'ExtendsNode'
  children: ['child', 'parent']

  constructor: (@child, @parent) ->

  # Hooks one constructor into another's prototype chain.
  compileNode: (o) ->
    ref =  new ValueNode literal utility 'extends'
    (new CallNode ref, [@child, @parent]).compile o

#### AccessorNode

# A `.` accessor into a property of a value, or the `::` shorthand for
# an accessor into the object's prototype.
exports.AccessorNode = class AccessorNode extends BaseNode

  class:     'AccessorNode'
  children: ['name']

  constructor: (@name, tag) ->
    @prototype = if tag is 'prototype' then '.prototype' else ''
    @soakNode = tag is 'soak'

  compileNode: (o) ->
    name = @name.compile o
    o.chainRoot.wrapped or= @soakNode
    namePart = if name.match(IS_STRING) then "[#{name}]" else ".#{name}"
    @prototype + namePart

#### IndexNode

# A `[ ... ]` indexed accessor into an array or object.
exports.IndexNode = class IndexNode extends BaseNode

  class:     'IndexNode'
  children: ['index']

  constructor: (@index) ->

  compileNode: (o) ->
    o.chainRoot.wrapped or= @soakNode
    idx = @index.compile o
    prefix = if @proto then '.prototype' else ''
    "#{prefix}[#{idx}]"

#### RangeNode

# A range literal. Ranges can be used to extract portions (slices) of arrays,
# to specify a range for comprehensions, or as a value, to be expanded into the
# corresponding array of integers at runtime.
exports.RangeNode = class RangeNode extends BaseNode

  class:     'RangeNode'
  children: ['from', 'to']

  constructor: (@from, @to, exclusive) ->
    @exclusive = !!exclusive
    @equals = if @exclusive then '' else '='

  # Compiles the range's source variables -- where it starts and where it ends.
  # But only if they need to be cached to avoid double evaluation.
  compileVariables: (o) ->
    o = merge(o, top: true)
    [@from, @fromVar] =  @from.compileReference o, precompile: yes
    [@to, @toVar] =      @to.compileReference o, precompile: yes
    [@fromNum, @toNum] = [@fromVar.match(SIMPLENUM), @toVar.match(SIMPLENUM)]
    parts = []
    parts.push @from if @from isnt @fromVar
    parts.push @to if @to isnt @toVar
    if parts.length then "#{parts.join('; ')}; " else ''

  # When compiled normally, the range returns the contents of the *for loop*
  # needed to iterate over the values in the range. Used by comprehensions.
  compileNode: (o) ->
    return    @compileArray(o)  unless o.index
    return    @compileSimple(o) if @fromNum and @toNum
    idx      = del o, 'index'
    step     = del o, 'step'
    vars     = "#{idx} = #{@fromVar}"
    intro    = "(#{@fromVar} <= #{@toVar} ? #{idx}"
    compare  = "#{intro} <#{@equals} #{@toVar} : #{idx} >#{@equals} #{@toVar})"
    stepPart = if step then step.compile(o) else '1'
    incr     = if step then "#{idx} += #{stepPart}" else "#{intro} += #{stepPart} : #{idx} -= #{stepPart})"
    "#{vars}; #{compare}; #{incr}"

  # Compile a simple range comprehension, with integers.
  compileSimple: (o) ->
    [from, to] = [parseInt(@fromNum, 10), parseInt(@toNum, 10)]
    idx        = del o, 'index'
    step       = del o, 'step'
    step       and= "#{idx} += #{step.compile(o)}"
    if from <= to
      "#{idx} = #{from}; #{idx} <#{@equals} #{to}; #{step or "#{idx}++"}"
    else
      "#{idx} = #{from}; #{idx} >#{@equals} #{to}; #{step or "#{idx}--"}"

  # When used as a value, expand the range into the equivalent array.
  compileArray: (o) ->
    idt    = @idt 1
    vars   = @compileVariables merge o, indent: idt
    if @fromNum and @toNum and Math.abs(+@fromNum - +@toNum) <= 20
      range = [+@fromNum..+@toNum]
      range.pop() if @exclusive
      return "[#{ range.join(', ') }]"
    i = o.scope.freeVariable()
    result = o.scope.freeVariable()
    pre    = "\n#{idt}#{result} = []; #{vars}"
    if @fromNum and @toNum
      o.index = i
      body = @compileSimple o
    else
      clause = "#{@fromVar} <= #{@toVar} ?"
      body   = "var #{i} = #{@fromVar}; #{clause} #{i} <#{@equals} #{@toVar} : #{i} >#{@equals} #{@toVar}; #{clause} #{i} += 1 : #{i} -= 1"
    post   = "{ #{result}.push(#{i}); }\n#{idt}return #{result};\n#{o.indent}"
    "(function() {#{pre}\n#{idt}for (#{body})#{post}}).call(this)"

#### SliceNode

# An array slice literal. Unlike JavaScript's `Array#slice`, the second parameter
# specifies the index of the end of the slice, just as the first parameter
# is the index of the beginning.
exports.SliceNode = class SliceNode extends BaseNode

  class:     'SliceNode'
  children: ['range']

  constructor: (@range) ->

  compileNode: (o) ->
    from     = @range.from.compile(o)
    to       = @range.to.compile(o)
    plusPart = if @range.exclusive then '' else ' + 1'
    ".slice(#{from}, #{to}#{plusPart})"

#### ObjectNode

# An object literal, nothing fancy.
exports.ObjectNode = class ObjectNode extends BaseNode

  class:     'ObjectNode'
  children: ['properties']

  constructor: (props) ->
    @objects = @properties = props or []

  compileNode: (o) ->
    o.indent = @idt 1
    nonComments = prop for prop in @properties when not (prop instanceof CommentNode)
    lastNoncom =  nonComments[nonComments.length - 1]
    props = for prop, i in @properties
      join   = ",\n"
      join   = "\n" if (prop is lastNoncom) or (prop instanceof CommentNode)
      join   = '' if i is @properties.length - 1
      indent = if prop instanceof CommentNode then '' else @idt 1
      prop   = new AssignNode prop, prop, 'object' unless prop instanceof AssignNode or prop instanceof CommentNode
      indent + prop.compile(o) + join
    props = props.join('')
    inner = if props then '\n' + props + '\n' + @idt() else ''
    '{' + inner + '}'

#### ArrayNode

# An array literal.
exports.ArrayNode = class ArrayNode extends BaseNode

  class:     'ArrayNode'
  children: ['objects']

  constructor: (@objects) ->
    @objects or= []
    @compileSplatLiteral = (o) ->
      SplatNode.compileSplattedArray.call(this, @objects, o)

  compileNode: (o) ->
    o.indent = @idt 1
    objects = []
    for obj, i in @objects
      code = obj.compile(o)
      if obj instanceof SplatNode
        return @compileSplatLiteral o
      else if obj instanceof CommentNode
        objects.push "\n#{code}\n#{o.indent}"
      else if i is @objects.length - 1
        objects.push code
      else
        objects.push "#{code}, "
    objects = objects.join('')
    if indexOf(objects, '\n') >= 0
      "[\n#{@idt(1)}#{objects}\n#{@tab}]"
    else
      "[#{objects}]"

#### ClassNode

# The CoffeeScript class definition.
exports.ClassNode = class ClassNode extends BaseNode

  class:        'ClassNode'
  children:     ['variable', 'parent', 'properties']
  isStatement:  -> yes

  # Initialize a **ClassNode** with its name, an optional superclass, and a
  # list of prototype property assignments.
  constructor: (@variable, @parent, @properties) ->
    @properties or= []
    @returns    = false

  makeReturn: ->
    @returns = true
    this

  # Instead of generating the JavaScript string directly, we build up the
  # equivalent syntax tree and compile that, in pieces. You can see the
  # constructor, property assignments, and inheritance getting built out below.
  compileNode: (o) ->
    @variable  = literal o.scope.freeVariable() if @variable is '__temp__'
    extension  = @parent and new ExtendsNode(@variable, @parent)
    props      = new Expressions
    o.top      = true
    me         = null
    className  = @variable.compile o
    constScope = null

    if @parent
      applied = new ValueNode(@parent, [new AccessorNode(literal('apply'))])
      constructor = new CodeNode([], new Expressions([
        new CallNode(applied, [literal('this'), literal('arguments')])
      ]))
    else
      constructor = new CodeNode

    for prop in @properties
      [pvar, func] = [prop.variable, prop.value]
      if pvar and pvar.base.value is 'constructor' and func instanceof CodeNode
        throw new Error "cannot define a constructor as a bound function." if func.bound
        func.name = className
        func.body.push new ReturnNode literal 'this'
        @variable = new ValueNode @variable
        @variable.namespaced = include func.name, '.'
        constructor = func
        continue
      if func instanceof CodeNode and func.bound
        func.bound = false
        constScope or= new Scope(o.scope, constructor.body, constructor)
        me or= constScope.freeVariable()
        pname = pvar.compile(o)
        constructor.body.push    new ReturnNode literal 'this' if constructor.body.empty()
        constructor.body.unshift literal "this.#{pname} = function(){ return #{className}.prototype.#{pname}.apply(#{me}, arguments); }"
      if pvar
        access = if prop.context is 'this' then pvar.base.properties[0] else new AccessorNode(pvar, 'prototype')
        val    = new ValueNode(@variable, [access])
        prop   = new AssignNode(val, func)
      props.push prop

    constructor.body.unshift literal "#{me} = this" if me
    construct = @idt() + (new AssignNode(@variable, constructor)).compile(merge o, {sharedScope: constScope}) + ';'
    props     = if !props.empty() then '\n' + props.compile(o)                     else ''
    extension = if extension      then '\n' + @idt() + extension.compile(o) + ';'  else ''
    returns   = if @returns       then '\n' + new ReturnNode(@variable).compile(o) else ''
    construct + extension + props + returns

#### AssignNode

# The **AssignNode** is used to assign a local variable to value, or to set the
# property of an object -- including within object literals.
exports.AssignNode = class AssignNode extends BaseNode

  # Matchers for detecting prototype assignments.
  PROTO_ASSIGN: /^(\S+)\.prototype/
  LEADING_DOT:  /^\.(prototype\.)?/

  class:     'AssignNode'
  children: ['variable', 'value']

  constructor: (@variable, @value, @context) ->

  topSensitive: ->
    true

  isValue: ->
    @variable instanceof ValueNode

  makeReturn: ->
    if @isStatement()
      return new Expressions [this, new ReturnNode(@variable)]
    else
      super()

  isStatement: ->
    @isValue() and (@variable.isArray() or @variable.isObject())

  # Compile an assignment, delegating to `compilePatternMatch` or
  # `compileSplice` if appropriate. Keep track of the name of the base object
  # we've been assigned to, for correct internal references. If the variable
  # has not been seen yet within the current scope, declare it.
  compileNode: (o) ->
    top    = del o, 'top'
    return   @compilePatternMatch(o) if @isStatement()
    return   @compileSplice(o) if @isValue() and @variable.isSplice()
    stmt   = del o, 'asStatement'
    name   = @variable.compile(o)
    last   = if @isValue() then @variable.last.replace(@LEADING_DOT, '') else name
    match  = name.match(@PROTO_ASSIGN)
    proto  = match and match[1]
    if @value instanceof CodeNode
      @value.name =  last  if last.match(IDENTIFIER)
      @value.proto = proto if proto
    val = @value.compile o
    return "#{name}: #{val}" if @context is 'object'
    o.scope.find name unless @isValue() and (@variable.hasProperties() or @variable.namespaced)
    val = "#{name} = #{val}"
    return "#{@tab}#{val};" if stmt
    if top then val else "(#{val})"

  # Brief implementation of recursive pattern matching, when assigning array or
  # object literals to a value. Peeks at their properties to assign inner names.
  # See the [ECMAScript Harmony Wiki](http://wiki.ecmascript.org/doku.php?id=harmony:destructuring)
  # for details.
  compilePatternMatch: (o) ->
    valVar        = o.scope.freeVariable()
    value         = if @value.isStatement() then ClosureNode.wrap(@value) else @value
    assigns       = ["#{@tab}#{valVar} = #{ value.compile(o) };"]
    o.top         = true
    o.asStatement = true
    splat         = false
    for obj, i in @variable.base.objects
      # A regular array pattern-match.
      idx = i
      if @variable.isObject()
        if obj instanceof AssignNode
          # A regular object pattern-match.
          [obj, idx] = [obj.value, obj.variable.base]
        else
          # A shorthand `{a, b, c} = val` pattern-match.
          idx = obj
      if not (obj instanceof ValueNode or obj instanceof SplatNode)
        throw new Error 'pattern matching must use only identifiers on the left-hand side.'
      isString = idx.value and idx.value.match IS_STRING
      accessClass = if isString or @variable.isArray() then IndexNode else AccessorNode
      if obj instanceof SplatNode and not splat
        val = literal obj.compileValue o, valVar,
          (oindex = indexOf(@variable.base.objects, obj)),
          (olength = @variable.base.objects.length) - oindex - 1
        splat = true
      else
        idx = literal(if splat then "#{valVar}.length - #{olength - idx}" else idx) if typeof idx isnt 'object'
        val = new ValueNode(literal(valVar), [new accessClass(idx)])
      assigns.push(new AssignNode(obj, val).compile(o))
    code = assigns.join("\n")
    code

  # Compile the assignment from an array splice literal, using JavaScript's
  # `Array#splice` method.
  compileSplice: (o) ->
    name  = @variable.compile merge o, onlyFirst: true
    l     = @variable.properties.length
    range = @variable.properties[l - 1].range
    plus  = if range.exclusive then '' else ' + 1'
    from  = range.from.compile(o)
    to    = range.to.compile(o) + ' - ' + from + plus
    val   = @value.compile(o)
    "#{name}.splice.apply(#{name}, [#{from}, #{to}].concat(#{val}))"

#### CodeNode

# A function definition. This is the only node that creates a new Scope.
# When for the purposes of walking the contents of a function body, the CodeNode
# has no *children* -- they're within the inner scope.
exports.CodeNode = class CodeNode extends BaseNode

  class:     'CodeNode'
  children: ['params', 'body']

  constructor: (@params, @body, tag) ->
    @params or= []
    @body   or= new Expressions
    @bound  = tag is 'boundfunc'

  # Compilation creates a new scope unless explicitly asked to share with the
  # outer scope. Handles splat parameters in the parameter list by peeking at
  # the JavaScript `arguments` objects. If the function is bound with the `=>`
  # arrow, generates a wrapper that saves the current value of `this` through
  # a closure.
  compileNode: (o) ->
    sharedScope = del o, 'sharedScope'
    top         = del o, 'top'
    o.scope     = sharedScope or new Scope(o.scope, @body, this)
    o.top       = true
    o.indent    = @idt(1)
    empty       = @body.expressions.length is 0
    del o, 'noWrap'
    del o, 'globals'
    splat = undefined
    params = []
    for param, i in @params
      if splat
        if param.attach
          param.assign = new AssignNode new ValueNode literal('this'), [new AccessorNode param.value]
          @body.expressions.splice splat.index + 1, 0, param.assign
        splat.trailings.push param
      else
        if param.attach
          {value} = param
          [param, param.splat] = [literal(o.scope.freeVariable()), param.splat]
          @body.unshift new AssignNode new ValueNode(literal('this'), [new AccessorNode value]), param
        if param.splat
          splat           = new SplatNode param.value
          splat.index     = i
          splat.trailings = []
          splat.arglength = @params.length
          @body.unshift(splat)
        else
          params.push param
    params = (param.compile(o) for param in params)
    @body.makeReturn() unless empty
    (o.scope.parameter(param)) for param in params
    code = if @body.expressions.length then "\n#{ @body.compileWithDeclarations(o) }\n" else ''
    func = "function(#{ params.join(', ') }) {#{code}#{ code and @tab }}"
    return "#{utility('bind')}(#{func}, this)" if @bound
    if top then "(#{func})" else func

  topSensitive: ->
    true

  # Short-circuit traverseChildren method to prevent it from crossing scope boundaries
  # unless crossScope is true
  traverseChildren: (crossScope, func) -> super(crossScope, func) if crossScope

  toString: (idt) ->
    idt or= ''
    children = (child.toString(idt + TAB) for child in @collectChildren()).join('')
    '\n' + idt + children

#### ParamNode

# A parameter in a function definition. Beyond a typical Javascript parameter,
# these parameters can also attach themselves to the context of the function,
# as well as be a splat, gathering up a group of parameters into an array.
exports.ParamNode = class ParamNode extends BaseNode

  class:    'ParamNode'
  children: ['name']

  constructor: (@name, @attach, @splat) ->
    @value = literal @name

  compileNode: (o) ->
    @value.compile o

  toString: (idt) ->
    if @attach then (literal '@' + @name).toString idt else @value.toString idt

#### SplatNode

# A splat, either as a parameter to a function, an argument to a call,
# or as part of a destructuring assignment.
exports.SplatNode = class SplatNode extends BaseNode

  class:     'SplatNode'
  children: ['name']

  constructor: (name) ->
    name = literal(name) unless name.compile
    @name = name

  compileNode: (o) ->
    if @index? then @compileParam(o) else @name.compile(o)

  # Compiling a parameter splat means recovering the parameters that succeed
  # the splat in the parameter list, by slicing the arguments object.
  compileParam: (o) ->
    name = @name.compile(o)
    o.scope.find name
    end = ''
    if @trailings.length
      len = o.scope.freeVariable()
      o.scope.assign len, "arguments.length"
      variadic = o.scope.freeVariable()
      o.scope.assign variadic, len + ' >= ' + @arglength
      end = if @trailings.length then ", #{len} - #{@trailings.length}"
      for trailing, idx in @trailings
        if trailing.attach
          assign        = trailing.assign
          trailing      = literal o.scope.freeVariable()
          assign.value  = trailing
        pos = @trailings.length - idx
        o.scope.assign(trailing.compile(o), "arguments[#{variadic} ? #{len} - #{pos} : #{@index + idx}]")
    "#{name} = #{utility('slice')}.call(arguments, #{@index}#{end})"

  # A compiling a splat as a destructuring assignment means slicing arguments
  # from the right-hand-side's corresponding array.
  compileValue: (o, name, index, trailings) ->
    trail = if trailings then ", #{name}.length - #{trailings}" else ''
    "#{utility 'slice'}.call(#{name}, #{index}#{trail})"

  # Utility function that converts arbitrary number of elements, mixed with
  # splats, to a proper array
  @compileSplattedArray: (list, o) ->
    args = []
    for arg, i in list
      code = arg.compile o
      prev = args[last = args.length - 1]
      if not (arg instanceof SplatNode)
        if prev and starts(prev, '[') and ends(prev, ']')
          args[last] = "#{prev.substr(0, prev.length - 1)}, #{code}]"
          continue
        else if prev and starts(prev, '.concat([') and ends(prev, '])')
          args[last] = "#{prev.substr(0, prev.length - 2)}, #{code}])"
          continue
        else
          code = "[#{code}]"
      args.push(if i is 0 then code else ".concat(#{code})")
    args.join('')

#### WhileNode

# A while loop, the only sort of low-level loop exposed by CoffeeScript. From
# it, all other loops can be manufactured. Useful in cases where you need more
# flexibility or more speed than a comprehension can provide.
exports.WhileNode = class WhileNode extends BaseNode

  class:         'WhileNode'
  children:     ['condition', 'guard', 'body']
  isStatement: -> yes

  constructor: (condition, opts) ->
    if opts and opts.invert
      condition = new ParentheticalNode condition if condition instanceof OpNode
      condition = new OpNode('!', condition)
    @condition  = condition
    @guard = opts and opts.guard

  addBody: (body) ->
    @body = body
    this

  makeReturn: ->
    @returns = true
    this

  topSensitive: ->
    true

  # The main difference from a JavaScript *while* is that the CoffeeScript
  # *while* can be used as a part of a larger expression -- while loops may
  # return an array containing the computed result of each iteration.
  compileNode: (o) ->
    top      =  del(o, 'top') and not @returns
    o.indent =  @idt 1
    o.top    =  true
    cond     =  @condition.compile(o)
    set      =  ''
    unless top
      rvar  = o.scope.freeVariable()
      set   = "#{@tab}#{rvar} = [];\n"
      @body = PushNode.wrap(rvar, @body) if @body
    pre     = "#{set}#{@tab}while (#{cond})"
    @body   = Expressions.wrap([new IfNode(@guard, @body)]) if @guard
    if @returns
      post = '\n' + new ReturnNode(literal(rvar)).compile(merge(o, indent: @idt()))
    else
      post = ''
    "#{pre} {\n#{ @body.compile(o) }\n#{@tab}}#{post}"

#### OpNode

# Simple Arithmetic and logical operations. Performs some conversion from
# CoffeeScript operations into their JavaScript equivalents.
exports.OpNode = class OpNode extends BaseNode

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

  class:     'OpNode'
  children: ['first', 'second']

  constructor: (@operator, @first, @second, flip) ->
    @operator = @CONVERSIONS[@operator] or @operator
    @flip     = !!flip
    if @first instanceof ValueNode and @first.base instanceof ObjectNode
      @first = new ParentheticalNode @first

  isUnary: ->
    not @second

  isChainable: ->
    indexOf(@CHAINABLE, @operator) >= 0

  toString: (idt) ->
    super(idt, @class + ' ' + @operator)

  compileNode: (o) ->
    o.operation = true
    return @compileChain(o)      if @isChainable() and @first.unwrap() instanceof OpNode and @first.unwrap().isChainable()
    return @compileAssignment(o) if indexOf(@ASSIGNMENT, @operator) >= 0
    return @compileUnary(o)      if @isUnary()
    return @compileExistence(o)  if @operator is '?'
    [@first.compile(o), @operator, @second.compile(o)].join ' '

  # Mimic Python's chained comparisons when multiple comparison operators are
  # used sequentially. For example:
  #
  #     bin/coffee -e "puts 50 < 65 > 10"
  #     true
  compileChain: (o) ->
    shared = @first.unwrap().second
    [@first.second, shared] = shared.compileReference(o) if shared.containsType CallNode
    [first, second, shared] = [@first.compile(o), @second.compile(o), shared.compile(o)]
    "(#{first}) && (#{shared} #{@operator} #{second})"

  # When compiling a conditional assignment, take care to ensure that the
  # operands are only evaluated once, even though we have to reference them
  # more than once.
  compileAssignment: (o) ->
    [first, firstVar] = @first.compileReference o, precompile: yes, assignment: yes
    second = @second.compile o
    second = "(#{second})" if @second instanceof OpNode
    o.scope.find(first) if first.match(IDENTIFIER)
    return "#{first} = #{ ExistenceNode.compileTest(o, literal(firstVar)) } ? #{firstVar} : #{second}" if @operator is '?='
    "#{first} = #{firstVar} #{ @operator.substr(0, 2) } #{second}"

  # If this is an existence operator, we delegate to `ExistenceNode.compileTest`
  # to give us the safe references for the variables.
  compileExistence: (o) ->
    [first, second] = [@first.compile(o), @second.compile(o)]
    test = ExistenceNode.compileTest(o, @first)
    "#{test} ? #{first} : #{second}"

  # Compile a unary **OpNode**.
  compileUnary: (o) ->
    space = if indexOf(@PREFIX_OPERATORS, @operator) >= 0 then ' ' else ''
    parts = [@operator, space, @first.compile(o)]
    parts = parts.reverse() if @flip
    parts.join('')

#### InNode
exports.InNode = class InNode extends BaseNode

  class:    'InNode'
  children: ['object', 'array']

  constructor: (@object, @array) ->

  isArray: ->
    @array instanceof ValueNode and @array.isArray()

  compileNode: (o) ->
    [@obj1, @obj2] = @object.compileReference o, precompile: yes
    if @isArray() then @compileOrTest(o) else @compileLoopTest(o)

  compileOrTest: (o) ->
    tests = for item, i in @array.base.objects
      "#{item.compile(o)} === #{if i then @obj2 else @obj1}"
    "(#{tests.join(' || ')})"

  compileLoopTest: (o) ->
    [@arr1, @arr2] = @array.compileReference o, precompile: yes
    [i, l] = [o.scope.freeVariable(), o.scope.freeVariable()]
    prefix = if @obj1 isnt @obj2 then @obj1 + '; ' else ''
    "(function(){ #{prefix}for (var #{i}=0, #{l}=#{@arr1}.length; #{i}<#{l}; #{i}++) { if (#{@arr2}[#{i}] === #{@obj2}) return true; } return false; }).call(this)"

#### TryNode

# A classic *try/catch/finally* block.
exports.TryNode = class TryNode extends BaseNode

  class:        'TryNode'
  children:     ['attempt', 'recovery', 'ensure']
  isStatement:  -> yes

  constructor: (@attempt, @error, @recovery, @ensure) ->

  makeReturn: ->
    @attempt  = @attempt.makeReturn() if @attempt
    @recovery = @recovery.makeReturn() if @recovery
    this

  # Compilation is more or less as you would expect -- the *finally* clause
  # is optional, the *catch* is not.
  compileNode: (o) ->
    o.indent    = @idt 1
    o.top       = true
    attemptPart = @attempt.compile(o)
    errorPart   = if @error then " (#{ @error.compile(o) }) " else ' '
    catchPart   = if @recovery then " catch#{errorPart}{\n#{ @recovery.compile(o) }\n#{@tab}}" else ''
    finallyPart = (@ensure or '') and ' finally {\n' + @ensure.compile(merge(o)) + "\n#{@tab}}"
    "#{@tab}try {\n#{attemptPart}\n#{@tab}}#{catchPart}#{finallyPart}"

#### ThrowNode

# Simple node to throw an exception.
exports.ThrowNode = class ThrowNode extends BaseNode

  class:         'ThrowNode'
  children:     ['expression']
  isStatement: -> yes

  constructor: (@expression) ->

  # A **ThrowNode** is already a return, of sorts...
  makeReturn: ->
    return this

  compileNode: (o) ->
    "#{@tab}throw #{@expression.compile(o)};"

#### ExistenceNode

# Checks a variable for existence -- not *null* and not *undefined*. This is
# similar to `.nil?` in Ruby, and avoids having to consult a JavaScript truth
# table.
exports.ExistenceNode = class ExistenceNode extends BaseNode

  class:     'ExistenceNode'
  children: ['expression']

  constructor: (@expression) ->

  compileNode: (o) ->
    ExistenceNode.compileTest(o, @expression)

  # The meat of the **ExistenceNode** is in this static `compileTest` method
  # because other nodes like to check the existence of their variables as well.
  # Be careful not to double-evaluate anything.
  @compileTest: (o, variable) ->
    [first, second] = variable.compileReference o
    "(typeof #{first.compile(o)} !== \"undefined\" && #{second.compile(o)} !== null)"

#### ParentheticalNode

# An extra set of parentheses, specified explicitly in the source. At one time
# we tried to clean up the results by detecting and removing redundant
# parentheses, but no longer -- you can put in as many as you please.
#
# Parentheses are a good way to force any statement to become an expression.
exports.ParentheticalNode = class ParentheticalNode extends BaseNode

  class:     'ParentheticalNode'
  children: ['expression']

  constructor: (@expression) ->

  isStatement: ->
    @expression.isStatement()

  makeReturn: ->
    @expression.makeReturn()

  topSensitive: ->
    yes

  compileNode: (o) ->
    top  = del o, 'top'
    code = @expression.compile(o)
    if @isStatement()
      return (if top then @tab + code + ';' else code)
    l    = code.length
    code = code.substr(o, l-1) if code.substr(l-1, 1) is ';'
    if @expression instanceof AssignNode then code else "(#{code})"

#### ForNode

# CoffeeScript's replacement for the *for* loop is our array and object
# comprehensions, that compile into *for* loops here. They also act as an
# expression, able to return the result of each filtered iteration.
#
# Unlike Python array comprehensions, they can be multi-line, and you can pass
# the current index of the loop as a second parameter. Unlike Ruby blocks,
# you can map and filter in a single pass.
exports.ForNode = class ForNode extends BaseNode

  class:         'ForNode'
  children:     ['body', 'source', 'guard']
  isStatement: -> yes

  constructor: (@body, source, @name, @index) ->
    @index  or= null
    @source = source.source
    @guard  = source.guard
    @step   = source.step
    @raw    = !!source.raw
    @object = !!source.object
    [@name, @index] = [@index, @name] if @object
    @pattern = @name instanceof ValueNode
    throw new Error('index cannot be a pattern matching expression') if @index instanceof ValueNode
    @returns = false

  topSensitive: ->
    true

  makeReturn: ->
    @returns = true
    this

  compileReturnValue: (val, o) ->
    return '\n' + new ReturnNode(literal(val)).compile(o) if @returns
    return '\n' + val if val
    ''

  # Welcome to the hairiest method in all of CoffeeScript. Handles the inner
  # loop, filtering, stepping, and result saving for array, object, and range
  # comprehensions. Some of the generated code can be shared in common, and
  # some cannot.
  compileNode: (o) ->
    topLevel      = del(o, 'top') and not @returns
    range         = @source instanceof ValueNode and @source.base instanceof RangeNode and not @source.properties.length
    source        = if range then @source.base else @source
    codeInBody    = @body.contains (n) -> n instanceof CodeNode
    scope         = o.scope
    name          = (@name and @name.compile(o)) or scope.freeVariable()
    index         = @index and @index.compile o
    scope.find name  if name and not @pattern and (range or not codeInBody)
    scope.find index if index
    rvar          = scope.freeVariable() unless topLevel
    ivar          = if codeInBody then scope.freeVariable() else if range then name else index or scope.freeVariable()
    varPart       = ''
    guardPart     = ''
    body          = Expressions.wrap([@body])
    if range
      sourcePart  = source.compileVariables(o)
      forPart     = source.compile merge o, index: ivar, step: @step
    else
      svar        = scope.freeVariable()
      sourcePart  = "#{svar} = #{ @source.compile(o) };"
      if @pattern
        namePart  = new AssignNode(@name, literal("#{svar}[#{ivar}]")).compile(merge o, {indent: @idt(1), top: true}) + '\n'
      else
        namePart  = "#{name} = #{svar}[#{ivar}]" if name
      unless @object
        lvar      = scope.freeVariable()
        stepPart  = if @step then "#{ivar} += #{ @step.compile(o) }" else "#{ivar}++"
        forPart   = "#{ivar} = 0, #{lvar} = #{svar}.length; #{ivar} < #{lvar}; #{stepPart}"
    sourcePart    = (if rvar then "#{rvar} = []; " else '') + sourcePart
    sourcePart    = if sourcePart then "#{@tab}#{sourcePart}\n#{@tab}" else @tab
    returnResult  = @compileReturnValue(rvar, o)

    body          = PushNode.wrap(rvar, body) unless topLevel
    if @guard
      body        = Expressions.wrap([new IfNode(@guard, body)])
    if codeInBody
      body.unshift  literal "var #{name} = #{ivar}" if range
      body.unshift  literal "var #{namePart}" if namePart
      body.unshift  literal "var #{index} = #{ivar}" if index
      body        = ClosureNode.wrap(body, true)
    else
      varPart     = (namePart or '') and (if @pattern then namePart else "#{@idt(1)}#{namePart};\n")
    if @object
      forPart     = "#{ivar} in #{svar}"
      guardPart   = "\n#{@idt(1)}if (!#{utility('hasProp')}.call(#{svar}, #{ivar})) continue;" unless @raw
    body          = body.compile(merge(o, {indent: @idt(1), top: true}))
    vars          = if range then name else "#{name}, #{ivar}"
    "#{sourcePart}for (#{forPart}) {#{guardPart}\n#{varPart}#{body}\n#{@tab}}#{returnResult}"

#### IfNode

# *If/else* statements. Our *switch/when* will be compiled into this. Acts as an
# expression by pushing down requested returns to the last line of each clause.
#
# Single-expression **IfNodes** are compiled into ternary operators if possible,
# because ternaries are already proper expressions, and don't need conversion.
exports.IfNode = class IfNode extends BaseNode

  class:     'IfNode'
  children: ['condition', 'switchSubject', 'body', 'elseBody', 'assigner']

  constructor: (@condition, @body, @tags) ->
    @tags      or= {}
    @condition = new OpNode('!', new ParentheticalNode(@condition)) if @tags.invert
    @elseBody = null
    @isChain  = false

  bodyNode: -> @body?.unwrap()
  elseBodyNode: -> @elseBody?.unwrap()

  forceStatement: ->
    @tags.statement = true
    this

  # Tag a chain of **IfNodes** with their object(s) to switch on for equality
  # tests. `rewriteSwitch` will perform the actual change at compile time.
  switchesOver: (expression) ->
    @switchSubject = expression
    this

  # Rewrite a chain of **IfNodes** with their switch condition for equality.
  # Ensure that the switch expression isn't evaluated more than once.
  rewriteSwitch: (o) ->
    @assigner = @switchSubject
    unless (@switchSubject.unwrap() instanceof LiteralNode)
      variable = literal(o.scope.freeVariable())
      @assigner = new AssignNode(variable, @switchSubject)
      @switchSubject = variable
    @condition = for cond, i in flatten [@condition]
      cond = new ParentheticalNode(cond) if cond instanceof OpNode
      new OpNode('==', (if i is 0 then @assigner else @switchSubject), cond)
    @elseBodyNode().switchesOver(@switchSubject) if @isChain
    # prevent this rewrite from happening again
    @switchSubject = undefined
    this

  # Rewrite a chain of **IfNodes** to add a default case as the final *else*.
  addElse: (elseBody, statement) ->
    if @isChain
      @elseBodyNode().addElse elseBody, statement
    else
      @isChain = elseBody instanceof IfNode
      @elseBody = @ensureExpressions elseBody
    this

  # The **IfNode** only compiles into a statement if either of its bodies needs
  # to be a statement. Otherwise a ternary is safe.
  isStatement: ->
    @statement or= !!(@tags.statement or @bodyNode().isStatement() or (@elseBody and @elseBodyNode().isStatement()))

  compileCondition: (o) ->
    (cond.compile(o) for cond in flatten([@condition])).join(' || ')

  compileNode: (o) ->
    if @isStatement() then @compileStatement(o) else @compileTernary(o)

  makeReturn: ->
    if @isStatement()
      @body     and= @ensureExpressions(@body.makeReturn())
      @elseBody and= @ensureExpressions(@elseBody.makeReturn())
      this
    else
      new ReturnNode this

  ensureExpressions: (node) ->
    if node instanceof Expressions then node else new Expressions [node]

  # Compile the **IfNode** as a regular *if-else* statement. Flattened chains
  # force inner *else* bodies into statement form.
  compileStatement: (o) ->
    @rewriteSwitch(o) if @switchSubject
    child    = del o, 'chainChild'
    condO    = merge o
    o.indent = @idt 1
    o.top    = true
    ifDent   = if child then '' else @idt()
    comDent  = if child then @idt() else ''
    body     = @body.compile(o)
    ifPart   = "#{ifDent}if (#{ @compileCondition(condO) }) {\n#{body}\n#{@tab}}"
    return ifPart unless @elseBody
    elsePart = if @isChain
      ' else ' + @elseBodyNode().compile(merge(o, {indent: @idt(), chainChild: true}))
    else
      " else {\n#{ @elseBody.compile(o) }\n#{@tab}}"
    "#{ifPart}#{elsePart}"

  # Compile the IfNode as a ternary operator.
  compileTernary: (o) ->
    o.operation = true
    ifPart      = @condition.compile(o) + ' ? ' + @bodyNode().compile(o)
    elsePart    = if @elseBody then @elseBodyNode().compile(o) else 'null'
    "#{ifPart} : #{elsePart}"

# Faux-Nodes
# ----------

#### PushNode

# Faux-nodes are never created by the grammar, but are used during code
# generation to generate other combinations of nodes. The **PushNode** creates
# the tree for `array.push(value)`, which is helpful for recording the result
# arrays from comprehensions.
PushNode = exports.PushNode = {

  wrap: (array, expressions) ->
    expr = expressions.unwrap()
    return expressions if expr.isPureStatement() or expr.containsPureStatement()
    Expressions.wrap([new CallNode(
      new ValueNode(literal(array), [new AccessorNode(literal('push'))]), [expr]
    )])

}

#### ClosureNode

# A faux-node used to wrap an expressions body in a closure.
ClosureNode = exports.ClosureNode = {

  # Wrap the expressions body, unless it contains a pure statement,
  # in which case, no dice. If the body mentions `this` or `arguments`,
  # then make sure that the closure wrapper preserves the original values.
  wrap: (expressions, statement) ->
    return expressions if expressions.containsPureStatement()
    func = new ParentheticalNode(new CodeNode([], Expressions.wrap([expressions])))
    args = []
    mentionsArgs = expressions.contains (n) ->
      n instanceof LiteralNode and (n.value is 'arguments')
    mentionsThis = expressions.contains (n) ->
      (n instanceof LiteralNode and (n.value is 'this')) or
      (n instanceof CodeNode and n.bound)
    if mentionsArgs or mentionsThis
      meth = literal(if mentionsArgs then 'apply' else 'call')
      args = [literal('this')]
      args.push literal 'arguments' if mentionsArgs
      func = new ValueNode func, [new AccessorNode(meth)]
    call = new CallNode(func, args)
    if statement then Expressions.wrap([call]) else call

}

# Utility Functions
# -----------------

UTILITIES = {

  # Correctly set up a prototype chain for inheritance, including a reference
  # to the superclass for `super()` calls. See:
  # [goog.inherits](http://closure-library.googlecode.com/svn/docs/closureGoogBase.js.source.html#line1206).
  extends:  """
            function(child, parent) {
                var ctor = function(){};
                ctor.prototype = parent.prototype;
                child.prototype = new ctor();
                child.prototype.constructor = child;
                if (typeof parent.extended === "function") parent.extended(child);
                child.__superClass__ = parent.prototype;
              }
            """

  # Create a function bound to the current value of "this".
  bind: """
        function(func, context) {
            return function(){ return func.apply(context, arguments); };
          }
        """

  # Shortcuts to speed up the lookup time for native functions.
  hasProp: 'Object.prototype.hasOwnProperty'
  slice:   'Array.prototype.slice'

}

# Constants
# ---------

# Tabs are two spaces for pretty printing.
TAB = '  '

# Trim out all trailing whitespace, so that the generated code plays nice
# with Git.
TRAILING_WHITESPACE = /[ \t]+$/gm

# Keep these identifier regexes in sync with the Lexer.
IDENTIFIER = /^[a-zA-Z\$_](\w|\$)*$/
NUMBER     = /^(((\b0(x|X)[0-9a-fA-F]+)|((\b[0-9]+(\.[0-9]+)?|\.[0-9]+)(e[+\-]?[0-9]+)?)))\b$/i
SIMPLENUM  = /^-?\d+/

# Is a literal value a string?
IS_STRING = /^['"]/

# Utility Functions
# -----------------

# Handy helper for a generating LiteralNode.
literal = (name) ->
  new LiteralNode(name)

# Helper for ensuring that utility functions are assigned at the top level.
utility = (name) ->
  ref = "__#{name}"
  Scope.root.assign ref, UTILITIES[name]
  ref
