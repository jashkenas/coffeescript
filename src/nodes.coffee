# `nodes.coffee` contains all of the node classes for the syntax tree. Most
# nodes are created as the result of actions in the [grammar](grammar.html),
# but some are created by other nodes as a method of code generation. To convert
# the syntax tree into a string of JavaScript code, call `compile()` on the root.

{Scope} = require './scope'

# Import the helpers we plan to use.
{compact, flatten, extend, merge, del, starts, ends, last} = require './helpers'

exports.extend = extend  # for parser

# Constant functions for nodes that don't need customization.
YES  = -> yes
NO   = -> no
THIS = -> this

#### Base

# The **Base** is the abstract base class for all nodes in the syntax tree.
# Each subclass implements the `compileNode` method, which performs the
# code generation for that node. To compile a node to JavaScript,
# call `compile` on it, which wraps `compileNode` in some generic extra smarts,
# to know when the generated code needs to be wrapped up in a closure.
# An options hash is passed and cloned throughout, containing information about
# the environment from higher in the tree (such as if a returned value is
# being requested by the surrounding function), information about the current
# scope, and indentation level.
exports.Base = class Base

  constructor: ->
    @tags = {}

  # Common logic for determining whether to wrap this node in a closure before
  # compiling it, or to compile directly. We need to wrap if this node is a
  # *statement*, and it's not a *pureStatement*, and we're not at
  # the top level of a block (which would be unnecessary), and we haven't
  # already been asked to return the result (because statements know how to
  # return results).
  compile: (o, lvl) ->
    o        = if o then extend {}, o else {}
    o.level  = lvl if lvl?
    node     = @unfoldSoak(o) or this
    node.tab = o.indent
    if o.level is LEVEL_TOP or node.isPureStatement() or not node.isStatement(o)
      node.compileNode o
    else
      node.compileClosure o

  # Statements converted into expressions via closure-wrapping share a scope
  # object with their parent closure, to preserve the expected lexical scope.
  compileClosure: (o) ->
    if @containsPureStatement()
      throw SyntaxError 'cannot include a pure statement in an expression.'
    o.sharedScope = o.scope
    Closure.wrap(this).compileNode o

  # If the code generation wishes to use the result of a complex expression
  # in multiple places, ensure that the expression is only ever evaluated once,
  # by assigning it to a temporary variable. Pass a level to precompile.
  cache: (o, lvl) ->
    unless @isComplex()
      ref = if lvl then @compile o, lvl else this
      [ref, ref]
    else
      ref = new Literal o.scope.freeVariable 'ref'
      sub = new Assign ref, this
      if lvl then [sub.compile(o, lvl), ref.value] else [sub, ref]

  # Compile to a source/variable pair suitable for looping.
  compileLoopReference: (o, name) ->
    src = tmp = @compile o, LEVEL_LIST
    unless NUMBER.test(src) or IDENTIFIER.test(src) and o.scope.check(src, immediate: on)
      src = "#{ tmp = o.scope.freeVariable name } = #{src}"
    [src, tmp]

  # Convenience method to grab the current indentation level, plus tabbing in.
  idt: (tabs) ->
    (@tab or '') + Array((tabs or 0) + 1).join TAB

  # Construct a node that returns the current node's result.
  # Note that this is overridden for smarter behavior for
  # many statement nodes (eg If, For)...
  makeReturn: ->
    new Return this

  # Does this node, or any of its children, contain a node of a certain kind?
  # Recursively traverses down the *children* of the nodes, yielding to a block
  # and returning true when the block finds a match. `contains` does not cross
  # scope boundaries.
  contains: (block, arg) ->
    contains = no
    @traverseChildren false, (node, arg) ->
      if (rearg = block node, arg) is true then not contains = true else if arg? then rearg
    , arg
    contains

  # Is this node of a certain type, or does it contain the type?
  containsType: (type) ->
    this instanceof type or @contains (node) -> node instanceof type

  # Convenience for the most common use of contains. Does the node contain
  # a pure statement?
  containsPureStatement: ->
    @isPureStatement() or @contains (node, func) ->
      func(node) or if node instanceof While or node instanceof For
        (node) -> node instanceof Return
      else func
    , (node) -> node.isPureStatement()

  # `toString` representation of the node, for inspecting the parse tree.
  # This is what `coffee --nodes` prints out.
  toString: (idt, override) ->
    idt or= ''
    children = (child.toString idt + TAB for child in @collectChildren()).join('')
    klass = override or @constructor.name + if @soakNode then '?' else ''
    '\n' + idt + klass + children

  # Passes each child to a function, breaking when the function returns `false`.
  eachChild: (func) ->
    return this unless @children
    for attr in @children when @[attr]
      for child in flatten [@[attr]]
        return this if func(child) is false
    this

  collectChildren: ->
    nodes = []
    @eachChild (node) -> nodes.push node
    nodes

  traverseChildren: (crossScope, func, arg) ->
    @eachChild (child) ->
      return false if (arg = func child, arg) is false
      child.traverseChildren crossScope, func, arg

  invert: -> new Op '!', this

  # Default implementations of the common node properties and methods. Nodes
  # will override these with custom logic, if needed.
  children: []

  unwrap          : THIS
  isStatement     : NO
  isPureStatement : NO
  isComplex       : YES
  isChainable     : NO
  unfoldSoak      : NO

  # Is this node used to assign a certain variable?
  assigns: NO

#### Expressions

# The expressions body is the list of expressions that forms the body of an
# indented block of code -- the implementation of a function, a clause in an
# `if`, `switch`, or `try`, and so on...
exports.Expressions = class Expressions extends Base

  children: ['expressions']

  isStatement: YES

  constructor: (nodes) ->
    super()
    @expressions = compact flatten nodes or []

  # Tack an expression on to the end of this expression list.
  push: (node) ->
    @expressions.push node
    this

  # Add an expression at the beginning of this expression list.
  unshift: (node) ->
    @expressions.unshift node
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
    for end, idx in @expressions by -1 when end not instanceof Comment
      @expressions[idx] = end.makeReturn()
      break
    this

  # An **Expressions** is the only node that can serve as the root.
  compile: (o, lvl) ->
    o or= {}
    if o.scope then super o, lvl else @compileRoot o

  compileNode: (o) ->
    @tab = o.indent
    (@compileExpression node, o for node in @expressions).join '\n'

  # If we happen to be the top-level **Expressions**, wrap everything in
  # a safety closure, unless requested not to.
  # It would be better not to generate them in the first place, but for now,
  # clean up obvious double-parentheses.
  compileRoot: (o) ->
    o.indent = @tab = if o.bare then '' else TAB
    o.scope  = new Scope null, this, null
    o.level  = LEVEL_TOP
    code     = @compileWithDeclarations o
    code     = code.replace TRAILING_WHITESPACE, ''
    if o.bare then code else "(function() {\n#{code}\n}).call(this);\n"

  # Compile the expressions body for the contents of a function, with
  # declarations of all inner variables pushed up to the top.
  compileWithDeclarations: (o) ->
    code    = @compileNode o
    {scope} = o
    if scope.hasAssignments this
      code = "#{@tab}var #{ multident scope.compiledAssignments(), @tab };\n#{code}"
    if not o.globals and o.scope.hasDeclarations this
      code = "#{@tab}var #{ scope.compiledDeclarations() };\n#{code}"
    code

  # Compiles a single expression within the expressions body. If we need to
  # return the result, and it's an expression, simply return it. If it's a
  # statement, ask the statement to do so.
  compileExpression: (node, o) ->
    while node isnt node = node.unwrap() then
    node = node.unfoldSoak(o) or node
    node.tags.front = on
    o.level = LEVEL_TOP
    code    = node.compile o
    if node.isStatement o then code else @tab + code + ';'

  # Wrap up the given nodes as an **Expressions**, unless it already happens
  # to be one.
  @wrap: (nodes) ->
    return nodes[0] if nodes.length is 1 and nodes[0] instanceof Expressions
    new Expressions nodes

#### Literal

# Literals are static values that can be passed through directly into
# JavaScript without translation, such as: strings, numbers,
# `true`, `false`, `null`...
exports.Literal = class Literal extends Base

  constructor: (@value) -> super()

  makeReturn: -> if @isStatement() then this else super()

  # Break and continue must be treated as pure statements -- they lose their
  # meaning when wrapped in a closure.
  isPureStatement: -> @value in ['break', 'continue', 'debugger']

  isComplex: NO

  assigns: (name) -> name is @value

  compile: -> if @value.reserved then "\"#{@value}\"" else @value

  toString: -> ' "' + @value + '"'

#### Return

# A `return` is a *pureStatement* -- wrapping it in a closure wouldn't
# make sense.
exports.Return = class Return extends Base

  children: ['expression']

  isStatement    : YES
  isPureStatement: YES

  constructor: (@expression) -> super()

  makeReturn: THIS

  compile: (o, lvl) ->
    expr = @expression?.makeReturn()
    if expr and expr not instanceof Return then expr.compile o, lvl else super o, lvl

  compileNode: (o) ->
    o.level = LEVEL_PAREN
    @tab + "return#{ if @expression then ' ' + @expression.compile o else '' };"

#### Value

# A value, variable or literal or parenthesized, indexed or dotted into,
# or vanilla.
exports.Value = class Value extends Base

  children: ['base', 'properties']

  # A **Value** has a base and a list of property accesses.
  constructor: (@base, props, tag) ->
    super()
    @properties = props or []
    @tags[tag]  = yes if tag

  # Add a property access to the list.
  push: (prop) ->
    @properties.push prop
    this

  hasProperties: ->
    !!@properties.length

  # Some boolean checks for the benefit of other nodes.

  isArray: ->
    @base instanceof ArrayLiteral and not @properties.length

  isObject: ->
    @base instanceof ObjectLiteral and not @properties.length

  isComplex: ->
    @base.isComplex() or @hasProperties()

  isAtomic: ->
    for node in @properties.concat @base
      return no if node.soakNode or node instanceof Call
    yes

  assigns: (name) ->
    not @properties.length and @base.assigns name

  makeReturn: ->
    if @properties.length then super() else @base.makeReturn()

  # The value can be unwrapped as its inner node, if there are no attached
  # properties.
  unwrap: ->
    if @properties.length then this else @base

  # Values are considered to be statements if their base is a statement.
  isStatement: (o) ->
    not @properties.length and @base.isStatement o

  isSimpleNumber: ->
    @base instanceof Literal and SIMPLENUM.test @base.value

  # A reference has base part (`this` value) and name part.
  # We cache them separately for compiling complex expressions.
  # `a()[b()] ?= c` -> `(_base = a())[_name = b()] ? _base[_name] = c`
  cacheReference: (o) ->
    name = last @properties
    if @properties.length < 2 and not @base.isComplex() and not name?.isComplex()
      return [this, this]  # `a` `a.b`
    base = new Value @base, @properties.slice 0, -1
    if base.isComplex()  # `a().b`
      bref = new Literal o.scope.freeVariable 'base'
      base = new Value new Parens new Assign bref, base
    return [base, bref] unless name  # `a()`
    if name.isComplex()  # `a[b()]`
      nref = new Literal o.scope.freeVariable 'name'
      name = new Index new Assign nref, name.index
      nref = new Index nref
    [base.push(name), new Value(bref or base.base, [nref or name])]

  # We compile a value to JavaScript by compiling and joining each property.
  # Things get much more insteresting if the chain of properties has *soak*
  # operators `?.` interspersed. Then we have to take care not to accidentally
  # evaluate anything twice when building the soak chain.
  compileNode: (o) ->
    @base.tags.front = @tags.front
    props = @properties
    code  = @base.compile o, if props.length then LEVEL_ACCESS else null
    code  = "(#{code})" if props[0] instanceof Accessor and @isSimpleNumber()
    (code += prop.compile o) for prop in props
    code

  # Unfold a soak into an `If`: `a?.b` -> `a.b if a?`
  unfoldSoak: (o) ->
    if ifn = @base.unfoldSoak o
      Array::push.apply ifn.body.properties, @properties
      return ifn
    for prop, i in @properties when prop.soakNode
      prop.soakNode = off
      fst = new Value @base, @properties.slice 0, i
      snd = new Value @base, @properties.slice i
      if fst.isComplex()
        ref = new Literal o.scope.freeVariable 'ref'
        fst = new Parens new Assign ref, fst
        snd.base = ref
      return new If new Existence(fst), snd, soak: on
    null

  @wrap: (node) -> if node instanceof Value then node else new Value node

#### Comment

# CoffeeScript passes through block comments as JavaScript block comments
# at the same position.
exports.Comment = class Comment extends Base

  isPureStatement: YES

  constructor: (@comment) -> super()

  makeReturn: THIS

  compileNode: (o) -> @tab + '/*' + multident(@comment, @tab) + '*/'

#### Call

# Node for a function invocation. Takes care of converting `super()` calls into
# calls against the prototype's function of the same name.
exports.Call = class Call extends Base

  children: ['variable', 'args']

  constructor: (variable, @args, @soakNode) ->
    super()
    @isNew    = false
    @isSuper  = variable is 'super'
    @variable = if @isSuper then null else variable
    @args   or= []

  compileSplatArguments: (o) ->
    Splat.compileSplattedArray @args, o

  # Tag this invocation as creating a new instance.
  newInstance: ->
    @isNew = true
    this

  # Grab the reference to the superclass' implementation of the current method.
  superReference: (o) ->
    {method} = o.scope
    throw SyntaxError 'cannot call super outside of a function.' unless method
    {name} = method
    throw SyntaxError 'cannot call super on an anonymous function.' unless name
    if method.klass
      "#{method.klass}.__super__.#{name}"
    else
      "#{name}.__super__.constructor"

  # Soaked chained invocations unfold into if/else ternary structures.
  unfoldSoak: (o) ->
    if @soakNode
      if @variable
        return ifn if ifn = If.unfoldSoak o, this, 'variable'
        [left, rite] = Value.wrap(@variable).cacheReference o
      else
        left = new Literal @superReference o
        rite = new Value left
      rite = new Call rite, @args
      rite.isNew = @isNew
      left = new Literal "typeof #{ left.compile o } === \"function\""
      return new If left, new Value(rite), soak: yes
    call = this
    list = []
    loop
      if call.variable instanceof Call
        list.push call
        call = call.variable
        continue
      break unless call.variable instanceof Value
      list.push call
      break unless (call = call.variable.base) instanceof Call
    for call in list.reverse()
      if ifn
        if call.variable instanceof Call
          call.variable = ifn
        else
          call.variable.base = ifn
      ifn = If.unfoldSoak o, call, 'variable'
    ifn

  # Compile a vanilla function call.
  compileNode: (o) ->
    @variable?.tags.front = @tags.front
    for arg in @args when arg instanceof Splat
      return @compileSplat o
    args = (arg.compile o, LEVEL_LIST for arg in @args).join ', '
    if @isSuper
      @compileSuper args, o
    else
      (if @isNew then 'new ' else '') + @variable.compile(o, LEVEL_ACCESS) + "(#{args})"

  # `super()` is converted into a call against the superclass's implementation
  # of the current function.
  compileSuper: (args, o) ->
    "#{@superReference(o)}.call(this#{ if args.length then ', ' else '' }#{args})"

  # If you call a function with a splat, it's converted into a JavaScript
  # `.apply()` call to allow an array of arguments to be passed.
  # If it's a constructor, then things get real tricky. We have to inject an
  # inner constructor in order to be able to pass the varargs.
  compileSplat: (o) ->
    splatargs = @compileSplatArguments o
    return "#{ @superReference o }.apply(this, #{splatargs})" if @isSuper
    unless @isNew
      base = Value.wrap @variable
      if (name = base.properties.pop()) and base.isComplex()
        ref = o.scope.freeVariable 'this'
        fun = "(#{ref} = #{ base.compile o, LEVEL_LIST })#{ name.compile o }"
      else
        fun = ref = base.compile o, LEVEL_ACCESS
        fun += name.compile o if name
      return "#{fun}.apply(#{ref}, #{splatargs})"
    idt = @idt 1
    """
    (function(func, args, ctor) {
    #{idt}ctor.prototype = func.prototype;
    #{idt}var child = new ctor, result = func.apply(child, args);
    #{idt}return typeof result === "object" ? result : child;
    #{@tab}})(#{ @variable.compile o, LEVEL_LIST }, #{splatargs}, function() {})
    """

#### Extends

# Node to extend an object's prototype with an ancestor object.
# After `goog.inherits` from the
# [Closure Library](http://closure-library.googlecode.com/svn/docs/closureGoogBase.js.html).
exports.Extends = class Extends extends Base

  children: ['child', 'parent']

  constructor: (@child, @parent) -> super()

  # Hooks one constructor into another's prototype chain.
  compile: (o) ->
    new Call(new Value(new Literal utility 'extends'), [@child, @parent]).compile o

#### Accessor

# A `.` accessor into a property of a value, or the `::` shorthand for
# an accessor into the object's prototype.
exports.Accessor = class Accessor extends Base

  children: ['name']

  constructor: (@name, tag) ->
    super()
    @proto    = if tag is 'prototype' then '.prototype' else ''
    @soakNode = tag is 'soak'

  compile: (o) ->
    name = @name.compile o
    @proto + if IS_STRING.test name then "[#{name}]" else ".#{name}"

  isComplex: NO

#### Index

# A `[ ... ]` indexed accessor into an array or object.
exports.Index = class Index extends Base

  children: ['index']

  constructor: (@index) -> super()

  compile: (o) ->
    (if @proto then '.prototype' else '') + "[#{ @index.compile o, LEVEL_PAREN }]"

  isComplex: -> @index.isComplex()

#### ObjectLiteral

# An object literal, nothing fancy.
exports.ObjectLiteral = class ObjectLiteral extends Base

  children: ['properties']

  constructor: (props) ->
    super()
    @objects = @properties = props or []

  compileNode: (o) ->
    o.indent = @idt 1
    nonComments = prop for prop in @properties when prop not instanceof Comment
    lastNoncom  = last nonComments
    props = for prop, i in @properties
      join = if i is @properties.length - 1
        ''
      else if prop is lastNoncom or prop instanceof Comment
        '\n'
      else
        ',\n'
      indent = if prop instanceof Comment then '' else @idt 1
      if prop instanceof Value and prop.tags.this
        prop = new Assign prop.properties[0].name, prop, 'object'
      else if prop not instanceof Assign and prop not instanceof Comment
        prop = new Assign prop, prop, 'object'
      indent + prop.compile(o) + join
    props = props.join ''
    obj   = "{#{ if props then '\n' + props + '\n' + @idt() else '' }}"
    if @tags.front then "(#{obj})" else obj

  assigns: (name) ->
    for prop in @properties when prop.assigns name then return yes
    no

#### ArrayLiteral

# An array literal.
exports.ArrayLiteral = class ArrayLiteral extends Base

  children: ['objects']

  constructor: (objs) ->
    super()
    @objects = objs or []

  compileSplatLiteral: (o) ->
    Splat.compileSplattedArray @objects, o

  compileNode: (o) ->
    o.indent = @idt 1
    for obj in @objects when obj instanceof Splat
      return @compileSplatLiteral o
    objects = []
    for obj, i in @objects
      code = obj.compile o, LEVEL_LIST
      objects.push (if obj instanceof Comment
        "\n#{code}\n#{o.indent}"
      else if i is @objects.length - 1
        code
      else
        code + ', '
      )
    objects = objects.join ''
    if 0 < objects.indexOf '\n'
      "[\n#{o.indent}#{objects}\n#{@tab}]"
    else
      "[#{objects}]"

  assigns: (name) ->
    for obj in @objects when obj.assigns name then return yes
    no

#### Class

# The CoffeeScript class definition.
exports.Class = class Class extends Base

  children: ['variable', 'parent', 'properties']

  isStatement: YES

  # Initialize a **Class** with its name, an optional superclass, and a
  # list of prototype property assignments.
  constructor: (variable, @parent, props) ->
    super()
    @variable   = if variable is '__temp__' then new Literal variable else variable
    @properties = props or []
    @returns    = false

  makeReturn: ->
    @returns = true
    this

  # Instead of generating the JavaScript string directly, we build up the
  # equivalent syntax tree and compile that, in pieces. You can see the
  # constructor, property assignments, and inheritance getting built out below.
  compileNode: (o) ->
    {variable} = this
    variable   = new Literal o.scope.freeVariable 'ctor' if variable.value is '__temp__'
    extension  = @parent and new Extends variable, @parent
    props      = new Expressions
    me         = null
    className  = variable.compile o
    constScope = null

    if @parent
      applied = new Value @parent, [new Accessor new Literal 'apply']
      constructor = new Code [], new Expressions [
        new Call applied, [new Literal('this'), new Literal('arguments')]
      ]
    else
      constructor = new Code [], new Expressions [new Return new Literal 'this']

    for prop in @properties
      {variable: pvar, value: func} = prop
      if pvar and pvar.base.value is 'constructor'
        if func not instanceof Code
          [func, ref] = func.cache o
          props.push func if func isnt ref
          apply = new Call new Value(ref, [new Accessor new Literal 'apply']),
                           [new Literal('this'), new Literal('arguments')]
          func  = new Code [], new Expressions([apply])
        throw SyntaxError 'cannot define a constructor as a bound function.' if func.bound
        func.name = className
        func.body.push new Return new Literal 'this'
        variable = new Value variable
        variable.namespaced = 0 < className.indexOf '.'
        constructor = func
        constructor.comment = props.expressions.pop() if last(props.expressions) instanceof Comment
        continue
      if func instanceof Code and func.bound
        if prop.context is 'this'
          func.context = className
        else
          func.bound = false
          constScope or= new Scope o.scope, constructor.body, constructor
          me or= constScope.freeVariable 'this'
          pname = pvar.compile o
          constructor.body.push    new Return new Literal 'this' if constructor.body.empty()
          constructor.body.unshift new Literal "this.#{pname} = function(){ return #{className}.prototype.#{pname}.apply(#{me}, arguments); }"
      if pvar
        access = if prop.context is 'this' then pvar.base.properties[0] else new Accessor(pvar, 'prototype')
        val    = new Value variable, [access]
        prop   = new Assign val, func
      props.push prop

    constructor.className = className.match /[$\w]+$/
    constructor.body.unshift new Literal "#{me} = this" if me
    o.sharedScope = constScope
    construct  = @tab + new Assign(variable, constructor).compile(o) + ';'
    construct += '\n' + @tab + extension.compile(o) + ';' if extension
    construct += '\n' + props.compile o                   if !props.empty()
    construct += '\n' + new Return(variable).compile o    if @returns
    construct

#### Assign

# The **Assign** is used to assign a local variable to value, or to set the
# property of an object -- including within object literals.
exports.Assign = class Assign extends Base

  # Matchers for detecting class/method names
  METHOD_DEF: /^(?:(\S+)\.prototype\.)?([$A-Za-z_][$\w]*)$/

  CONDITIONAL: ['||=', '&&=', '?=']

  children: ['variable', 'value']

  constructor: (@variable, @value, @context) -> super()

  assigns: (name) ->
    @[if @context is 'object' then 'value' else 'variable'].assigns name

  unfoldSoak: (o) -> If.unfoldSoak o, this, 'variable'

  # Compile an assignment, delegating to `compilePatternMatch` or
  # `compileSplice` if appropriate. Keep track of the name of the base object
  # we've been assigned to, for correct internal references. If the variable
  # has not been seen yet within the current scope, declare it.
  compileNode: (o) ->
    if isValue = @variable instanceof Value
      return @compilePatternMatch o if @variable.isArray() or @variable.isObject()
      return @compileConditional  o if @context in @CONDITIONAL
    name = @variable.compile o, LEVEL_LIST
    if @value instanceof Code and match = @METHOD_DEF.exec name
      @value.name  = match[2]
      @value.klass = match[1]
    val = @value.compile o, LEVEL_LIST
    return "#{name}: #{val}" if @context is 'object'
    o.scope.find name unless isValue and (@variable.hasProperties() or @variable.namespaced)
    val = name + " #{ @context or '=' } " + val
    if o.level <= LEVEL_LIST then val else "(#{val})"

  # Brief implementation of recursive pattern matching, when assigning array or
  # object literals to a value. Peeks at their properties to assign inner names.
  # See the [ECMAScript Harmony Wiki](http://wiki.ecmascript.org/doku.php?id=harmony:destructuring)
  # for details.
  compilePatternMatch: (o) ->
    top       = o.level is LEVEL_TOP
    {value}   = this
    {objects} = @variable.base
    return value.compile o unless olength = objects.length
    isObject = @variable.isObject()
    if top and olength is 1 and (obj = objects[0]) not instanceof Splat
      # Unroll simplest cases: `{v} = x` -> `v = x.v`
      if obj instanceof Assign
        {variable: {base: idx}, value: obj} = obj
      else
        idx = if isObject
          if obj.tags.this then obj.properties[0].name else obj
        else
          new Literal 0
      accessClass = if IDENTIFIER.test idx.value then Accessor else Index
      (value = Value.wrap value).properties.push new accessClass idx
      return new Assign(obj, value).compile o
    valVar  = value.compile o, LEVEL_LIST
    assigns = []
    splat   = false
    if not IDENTIFIER.test(valVar) or @variable.assigns(valVar)
      assigns.push "#{ ref = o.scope.freeVariable 'ref' } = #{valVar}"
      valVar = ref
    for obj, i in objects
      # A regular array pattern-match.
      idx = i
      if isObject
        if obj instanceof Assign
          # A regular object pattern-match.
          {variable: {base: idx}, value: obj} = obj
        else
          # A shorthand `{a, b, @c} = val` pattern-match.
          idx = if obj.tags.this then obj.properties[0].name else obj
      unless obj instanceof Value or obj instanceof Splat
        throw SyntaxError 'pattern matching must use only identifiers on the left-hand side.'
      accessClass = if isObject and IDENTIFIER.test(idx.value) then Accessor else Index
      if not splat and obj instanceof Splat
        val   = new Literal obj.compileValue o, valVar, i, olength - i - 1
        splat = true
      else
        if typeof idx isnt 'object'
          idx = new Literal(if splat then "#{valVar}.length - #{ olength - idx }" else idx)
        val = new Value new Literal(valVar), [new accessClass idx]
      assigns.push new Assign(obj, val).compile o, LEVEL_LIST
    assigns.push valVar unless top
    code = assigns.join ', '
    if o.level < LEVEL_LIST then code else "(#{code})"

  # When compiling a conditional assignment, take care to ensure that the
  # operands are only evaluated once, even though we have to reference them
  # more than once.
  compileConditional: (o) ->
    [left, rite] = @variable.cacheReference o
    return new Op(@context.slice(0, -1), left, new Assign(rite, @value)).compile o

#### Code

# A function definition. This is the only node that creates a new Scope.
# When for the purposes of walking the contents of a function body, the Code
# has no *children* -- they're within the inner scope.
exports.Code = class Code extends Base

  children: ['params', 'body']

  constructor: (@params, @body, tag) ->
    super()
    @params or= []
    @body   or= new Expressions
    @bound    = tag is 'boundfunc'
    @context  = 'this' if @bound

  # Compilation creates a new scope unless explicitly asked to share with the
  # outer scope. Handles splat parameters in the parameter list by peeking at
  # the JavaScript `arguments` objects. If the function is bound with the `=>`
  # arrow, generates a wrapper that saves the current value of `this` through
  # a closure.
  compileNode: (o) ->
    sharedScope = del o, 'sharedScope'
    o.scope     = scope = sharedScope or new Scope o.scope, @body, this
    o.indent    = @idt 1
    empty       = @body.expressions.length is 0
    delete o.bare
    delete o.globals
    splat = undefined
    params = []
    for param, i in @params
      if splat
        if param.attach
          param.assign = new Assign new Value new Literal('this'), [new Accessor param.value]
          @body.expressions.splice splat.index + 1, 0, param.assign
        splat.trailings.push param
      else
        if param.attach
          {value} = param
          [param, param.splat] = [new Literal(scope.freeVariable 'arg'), param.splat]
          @body.unshift new Assign new Value(new Literal('this'), [new Accessor value]), param
        if param.splat
          splat           = new Splat param.value
          splat.index     = i
          splat.trailings = []
          splat.arglength = @params.length
          @body.unshift splat
        else
          params.push param
    scope.startLevel()
    @body.makeReturn() unless empty or @noReturn
    params = for param in params
      scope.parameter param = param.compile o
      param
    comm  = if @comment then @comment.compile(o) + '\n' else ''
    o.indent = @idt 2 if @className
    idt  = @idt 1
    code = if @body.expressions.length then "\n#{ @body.compileWithDeclarations o }\n" else ''
    if @className
      open  = "(function() {\n#{comm}#{idt}function #{@className}("
      close = "#{ code and idt }};\n#{idt}return #{@className};\n#{@tab}})()"
    else
      open  = "function("
      close = "#{ code and @tab }}"
    func = "#{open}#{ params.join ', ' }) {#{code}#{close}"
    scope.endLevel()
    return "#{ utility 'bind' }(#{func}, #{@context})" if @bound
    if @tags.front then "(#{func})" else func

  # Short-circuit `traverseChildren` method to prevent it from crossing scope boundaries
  # unless `crossScope` is `true`.
  traverseChildren: (crossScope, func) -> super(crossScope, func) if crossScope

#### Param

# A parameter in a function definition. Beyond a typical Javascript parameter,
# these parameters can also attach themselves to the context of the function,
# as well as be a splat, gathering up a group of parameters into an array.
exports.Param = class Param extends Base

  children: ['name']

  constructor: (@name, @attach, @splat) ->
    super()
    @value = new Literal @name

  compile: (o) -> @value.compile o, LEVEL_LIST

  toString: ->
    {name} = this
    name   = '@' + name if @attach
    name  += '...'      if @splat
    new Literal(name).toString()

#### Splat

# A splat, either as a parameter to a function, an argument to a call,
# or as part of a destructuring assignment.
exports.Splat = class Splat extends Base

  children: ['name']

  constructor: (name) ->
    super()
    @name = if name.compile then name else new Literal name

  assigns: (name) -> @name.assigns name

  compile: (o) ->
    if @index? then @compileParam o else @name.compile o

  # Compiling a parameter splat means recovering the parameters that succeed
  # the splat in the parameter list, by slicing the arguments object.
  compileParam: (o) ->
    name = @name.compile o
    o.scope.find name
    end = ''
    if @trailings.length
      len = o.scope.freeVariable 'len'
      o.scope.assign len, 'arguments.length'
      variadic = o.scope.freeVariable 'result'
      o.scope.assign variadic, len + ' >= ' + @arglength
      end = if @trailings.length then ", #{len} - #{@trailings.length}"
      for trailing, idx in @trailings
        if trailing.attach
          assign        = trailing.assign
          trailing      = new Literal o.scope.freeVariable 'arg'
          assign.value  = trailing
        pos = @trailings.length - idx
        o.scope.assign trailing.compile(o),
          "arguments[#{variadic} ? #{len} - #{pos} : #{ @index + idx }]"
    "#{name} = #{ utility 'slice' }.call(arguments, #{@index}#{end})"

  # A compiling a splat as a destructuring assignment means slicing arguments
  # from the right-hand-side's corresponding array.
  compileValue: (o, name, index, trailings) ->
    trail = if trailings then ", #{name}.length - #{trailings}" else ''
    "#{ utility 'slice' }.call(#{name}, #{index}#{trail})"

  # Utility function that converts arbitrary number of elements, mixed with
  # splats, to a proper array
  @compileSplattedArray: (list, o) ->
    args = []
    end  = -1
    for arg, i in list
      code = arg.compile o, LEVEL_LIST
      prev = args[end]
      if arg not instanceof Splat
        if prev and starts(prev, '[') and ends(prev, ']')
          args[end] = "#{prev.slice 0, -1}, #{code}]"
          continue
        if prev and starts(prev, '.concat([') and ends(prev, '])')
          args[end] = "#{prev.slice 0, -2}, #{code}])"
          continue
        code = "[#{code}]"
      args[++end] = if i is 0 then code else ".concat(#{code})"
    args.join ''

#### While

# A while loop, the only sort of low-level loop exposed by CoffeeScript. From
# it, all other loops can be manufactured. Useful in cases where you need more
# flexibility or more speed than a comprehension can provide.
exports.While = class While extends Base

  children: ['condition', 'guard', 'body']

  isStatement: YES

  constructor: (condition, opts) ->
    super()
    @condition  = if opts?.invert then condition.invert() else condition
    @guard = opts?.guard

  addBody: (body) ->
    @body = body
    this

  makeReturn: ->
    @returns = true
    this

  # The main difference from a JavaScript *while* is that the CoffeeScript
  # *while* can be used as a part of a larger expression -- while loops may
  # return an array containing the computed result of each iteration.
  compileNode: (o) ->
    o.indent = @idt 1
    set      = ''
    {body}   = this
    if o.level > LEVEL_TOP or @returns
      rvar = o.scope.freeVariable 'result'
      set  = "#{@tab}#{rvar} = [];\n"
      body = Push.wrap rvar, body if body
    body = Expressions.wrap [new If @guard, body] if @guard
    code = set + @tab + """
      while (#{ @condition.compile o, LEVEL_PAREN }) {
      #{ body.compile o, LEVEL_TOP }
      #{@tab}}
    """
    if @returns
      o.indent = @tab
      code += '\n' + new Return(new Literal rvar).compile o
    code

#### Op

# Simple Arithmetic and logical operations. Performs some conversion from
# CoffeeScript operations into their JavaScript equivalents.
exports.Op = class Op extends Base

  # The map of conversions from CoffeeScript to JavaScript symbols.
  CONVERSIONS:
    '==': '==='
    '!=': '!=='
    'of': 'in'

  # The map of invertible operators.
  INVERSIONS:
    '!==': '==='
    '===': '!=='

  children: ['first', 'second']

  constructor: (op, first, second, flip) ->
    return new In first, second if op is 'in'
    if op is 'new'
      return first.newInstance() if first instanceof Call
      first = new Parens first   if first instanceof Code and first.bound
    super()
    @operator = @CONVERSIONS[op] or op
    @first  = first
    @second = second
    @flip   = !!flip

  isUnary: -> not @second

  isComplex: -> @operator isnt '!' or @first.isComplex()

  # Am I capable of
  # [Python-style comparison chaining](http://docs.python.org/reference/expressions.html#notin)?
  isChainable: -> @operator in ['<', '>', '>=', '<=', '===', '!==']

  invert: ->
    if op = @INVERSIONS[@operator]
      @operator = op
      this
    else if @second
      new Parens(this).invert()
    else
      super()

  unfoldSoak: (o) ->
    @operator in ['++', '--', 'delete'] and If.unfoldSoak o, this, 'first'

  compileNode: (o) ->
    return @compileUnary     o if @isUnary()
    return @compileChain     o if @isChainable() and @first.isChainable()
    return @compileExistence o if @operator is '?'
    @first.tags.front = @tags.front
    "#{ @first.compile o, LEVEL_OP } #{@operator} #{ @second.compile o, LEVEL_OP }"

  # Mimic Python's chained comparisons when multiple comparison operators are
  # used sequentially. For example:
  #
  #     bin/coffee -e 'console.log 50 < 65 > 10'
  #     true
  compileChain: (o) ->
    [@first.second, shared] = @first.second.cache o
    fst  = @first .compile o, LEVEL_OP
    fst  = fst.slice 1, -1 if fst.charAt(0) is '('
    code = "#{fst} && #{ shared.compile o } #{@operator} #{ @second.compile o, LEVEL_OP }"
    if o.level < LEVEL_OP then code else "(#{code})"

  compileExistence: (o) ->
    if @first.isComplex()
      ref = o.scope.freeVariable 'ref'
      fst = new Parens new Assign new Literal(ref), @first
    else
      fst = @first
      ref = fst.compile o
    new Existence(fst).compile(o) + " ? #{ref} : #{ @second.compile o, LEVEL_LIST }"

  # Compile a unary **Op**.
  compileUnary: (o) ->
    parts = [op = @operator]
    parts.push ' ' if op in ['new', 'typeof', 'delete'] or
                      op in ['+', '-'] and @first instanceof Op and @first.operator is op
    parts.push @first.compile o, LEVEL_OP
    parts.reverse() if @flip
    parts.join ''

  toString: (idt) -> super idt, @constructor.name + ' ' + @operator

#### In
exports.In = class In extends Base

  children: ['object', 'array']

  constructor: (@object, @array) -> super()

  invert: ->
    @negated = not @negated
    this

  compileNode: (o) ->
    if @array instanceof Value and @array.isArray()
      @compileOrTest o
    else
      @compileLoopTest o

  compileOrTest: (o) ->
    [sub, ref] = @object.cache o, LEVEL_OP
    [cmp, cnj] = if @negated then [' !== ', ' && '] else [' === ', ' || ']
    tests = for item, i in @array.base.objects
      (if i then ref else sub) + cmp + item.compile o
    tests = tests.join cnj
    if o.level < LEVEL_OP then tests else "(#{tests})"

  compileLoopTest: (o) ->
    [sub, ref] = @object.cache o, LEVEL_LIST
    code = utility('indexOf') + ".call(#{ @array.compile o }, #{ref}) " +
           if @negated then '< 0' else '>= 0'
    return code if sub is ref
    code = sub + ', ' + code
    if o.level < LEVEL_LIST then code else "(#{code})"

  toString: (idt) ->
    super idt, @constructor.name + if @negated then '!' else ''

#### Try

# A classic *try/catch/finally* block.
exports.Try = class Try extends Base

  children: ['attempt', 'recovery', 'ensure']

  isStatement: YES

  constructor: (@attempt, @error, @recovery, @ensure) -> super()

  makeReturn: ->
    @attempt  = @attempt .makeReturn() if @attempt
    @recovery = @recovery.makeReturn() if @recovery
    this

  # Compilation is more or less as you would expect -- the *finally* clause
  # is optional, the *catch* is not.
  compileNode: (o) ->
    o.indent  = @idt 1
    errorPart = if @error then " (#{ @error.compile o }) " else ' '
    catchPart = if @recovery
      " catch#{errorPart}{\n#{ @recovery.compile o, LEVEL_TOP }\n#{@tab}}"
    else unless @ensure or @recovery
      ' catch (_e) {}'
    """
    #{@tab}try {
    #{ @attempt.compile o, LEVEL_TOP }
    #{@tab}}#{ catchPart or '' }
    """ + if @ensure then " finally {\n#{ @ensure.compile o, LEVEL_TOP }\n#{@tab}}" else ''

#### Throw

# Simple node to throw an exception.
exports.Throw = class Throw extends Base

  children: ['expression']

  isStatement: YES

  constructor: (@expression) -> super()

  # A **Throw** is already a return, of sorts...
  makeReturn: THIS

  compileNode: (o) -> @tab + "throw #{ @expression.compile o };"

#### Existence

# Checks a variable for existence -- not *null* and not *undefined*. This is
# similar to `.nil?` in Ruby, and avoids having to consult a JavaScript truth
# table.
exports.Existence = class Existence extends Base

  children: ['expression']

  constructor: (@expression) -> super()

  compileNode: (o) ->
    code = @expression.compile o
    code = if IDENTIFIER.test(code) and not o.scope.check code
      "typeof #{code} !== \"undefined\" && #{code} !== null"
    else
      "#{code} != null"
    if o.level <= LEVEL_COND then code else "(#{code})"

#### Parens

# An extra set of parentheses, specified explicitly in the source. At one time
# we tried to clean up the results by detecting and removing redundant
# parentheses, but no longer -- you can put in as many as you please.
#
# Parentheses are a good way to force any statement to become an expression.
exports.Parens = class Parens extends Base

  children: ['expression']

  constructor: (@expression) -> super()

  unwrap    : -> @expression
  isComplex : -> @expression.isComplex()
  makeReturn: -> @expression.makeReturn()

  compileNode: (o) ->
    expr = @expression
    if expr instanceof Value and expr.isAtomic()
      expr.tags.front = @tags.front
      return expr.compile o
    bare = o.level < LEVEL_OP and (expr instanceof Op or expr instanceof Call)
    code = expr.compile o, LEVEL_PAREN
    if bare then code else "(#{code})"

#### For

# CoffeeScript's replacement for the *for* loop is our array and object
# comprehensions, that compile into *for* loops here. They also act as an
# expression, able to return the result of each filtered iteration.
#
# Unlike Python array comprehensions, they can be multi-line, and you can pass
# the current index of the loop as a second parameter. Unlike Ruby blocks,
# you can map and filter in a single pass.
exports.For = class For extends Base

  children: ['body', 'source', 'guard', 'step', 'from', 'to']

  isStatement: YES

  constructor: (@body, head) ->
    if head.index instanceof Value
      throw SyntaxError 'index cannot be a pattern matching expression'
    super()
    extend this, head
    @step  or= new Literal 1 unless @object
    @pattern = @name instanceof Value
    @returns = false

  makeReturn: ->
    @returns = true
    this

  compileReturnValue: (val, o) ->
    return '\n' + new Return(new Literal val).compile o if @returns
    return '\n' + val if val
    ''

  # Welcome to the hairiest method in all of CoffeeScript. Handles the inner
  # loop, filtering, stepping, and result saving for array, object, and range
  # comprehensions. Some of the generated code can be shared in common, and
  # some cannot.
  compileNode: (o) ->
    {scope} = o
    name    = not @pattern and @name?.compile o
    index   = @index?.compile o
    ivar    = if not index then scope.freeVariable 'i' else index
    varPart = guardPart = defPart = retPart = ''
    body    = Expressions.wrap [@body]
    idt     = @idt 1
    scope.find(name,  immediate: yes) if name
    scope.find(index, immediate: yes) if index
    [step, pvar] = @step.compileLoopReference o, 'step' if @step
    if @from
      [tail, tvar] = @to.compileLoopReference o, 'to'
      vars  = ivar + ' = ' + @from.compile o
      vars += ', ' + tail if tail isnt tvar
      cond = if +pvar
        "#{ivar} #{ if pvar < 0 then '>' else '<' }= #{tvar}"
      else
        "#{pvar} < 0 ? #{ivar} >= #{tvar} : #{ivar} <= #{tvar}"
    else
      if name or @object and not @raw
        [sourcePart, svar] = @source.compileLoopReference o, 'ref'
      else
        sourcePart = svar = @source.compile o, LEVEL_PAREN
      namePart = if @pattern
        new Assign(@name, new Literal "#{svar}[#{ivar}]").compile o, LEVEL_TOP
      else if name
        "#{name} = #{svar}[#{ivar}]"
      unless @object
        if 0 > pvar and (pvar | 0) is +pvar  # negative int
          vars = "#{ivar} = #{svar}.length - 1"
          cond = "#{ivar} >= 0"
        else
          lvar = scope.freeVariable 'len'
          vars = "#{ivar} = 0, #{lvar} = #{svar}.length"
          cond = "#{ivar} < #{lvar}"
    if @object
      forPart   = ivar + ' in ' + sourcePart
      guardPart = if @raw then '' else
        idt + "if (!#{ utility 'hasProp' }.call(#{svar}, #{ivar})) continue;\n"
    else
      vars   += ', ' + step if step isnt pvar
      defPart = @tab + sourcePart + ';\n' if svar isnt sourcePart
      forPart = vars + "; #{cond}; " + ivar + switch +pvar
        when  1 then '++'
        when -1 then '--'
        else (if pvar < 0 then ' -= ' + pvar.slice 1 else ' += ' + pvar)
    if o.level > LEVEL_TOP or @returns
      rvar     = scope.freeVariable 'result'
      defPart += @tab + rvar + ' = [];\n'
      retPart  = @compileReturnValue rvar, o
      body     = Push.wrap rvar, body
    body     = Expressions.wrap [new If @guard, body] if @guard
    varPart  = idt + namePart + ';\n' if namePart
    o.indent = idt
    defPart + """
    #{@tab}for (#{forPart}) {
    #{ guardPart or '' }#{varPart}#{ body.compile o, LEVEL_TOP }
    #{@tab}}
    """ + retPart

#### Switch

# A JavaScript *switch* statement. Converts into a returnable expression on-demand.
exports.Switch = class Switch extends Base

  children: ['subject', 'cases', 'otherwise']

  isStatement: YES

  constructor: (@subject, @cases, @otherwise) -> super()

  makeReturn: ->
    pair[1].makeReturn() for pair in @cases
    @otherwise?.makeReturn()
    this

  compileNode: (o) ->
    idt1 = @idt 1
    idt2 = o.indent = @idt 2
    code = @tab + "switch (#{ @subject?.compile(o, LEVEL_PAREN) or true }) {\n"
    for [conditions, block], i in @cases
      for cond in flatten [conditions]
        cond  = cond.invert().invert() unless @subject
        code += idt1 + "case #{ cond.compile o, LEVEL_PAREN }:\n"
      code += block.compile(o, LEVEL_TOP) + '\n'
      break if i is @cases.length - 1 and not @otherwise
      for expr in block.expressions by -1 when expr not instanceof Comment
        code += idt2 + 'break;\n' unless expr instanceof Return
        break
    code += idt1 + "default:\n#{ @otherwise.compile o, LEVEL_TOP }\n" if @otherwise
    code +  @tab + '}'

#### If

# *If/else* statements. Acts as an expression by pushing down requested returns
# to the last line of each clause.
#
# Single-expression **Ifs** are compiled into conditional operators if possible,
# because ternaries are already proper expressions, and don't need conversion.
exports.If = class If extends Base

  children: ['condition', 'body', 'elseBody']

  constructor: (condition, @body, tags) ->
    @tags      = tags or= {}
    @condition = if tags.invert then condition.invert() else condition
    @soakNode  = tags.soak
    @elseBody  = null
    @isChain   = false

  bodyNode: -> @body?.unwrap()
  elseBodyNode: -> @elseBody?.unwrap()

  # Rewrite a chain of **Ifs** to add a default case as the final *else*.
  addElse: (elseBody) ->
    if @isChain
      @elseBodyNode().addElse elseBody
    else
      @isChain  = elseBody instanceof If
      @elseBody = @ensureExpressions elseBody
    this

  # The **If** only compiles into a statement if either of its bodies needs
  # to be a statement. Otherwise a conditional operator is safe.
  isStatement: (o) ->
    o?.level is LEVEL_TOP or @bodyNode().isStatement(o) or @elseBodyNode()?.isStatement(o)

  compileNode: (o) ->
    if @isStatement o then @compileStatement o else @compileExpression o

  makeReturn: ->
    if @isStatement()
      @body     and= @ensureExpressions @body.makeReturn()
      @elseBody and= @ensureExpressions @elseBody.makeReturn()
      this
    else
      new Return this

  ensureExpressions: (node) ->
    if node instanceof Expressions then node else new Expressions [node]

  # Compile the **If** as a regular *if-else* statement. Flattened chains
  # force inner *else* bodies into statement form.
  compileStatement: (o) ->
    child    = del o, 'chainChild'
    cond     = @condition.compile o, LEVEL_PAREN
    o.indent = @idt 1
    body     = @ensureExpressions(@body).compile o
    ifPart   = "if (#{cond}) {\n#{body}\n#{@tab}}"
    ifPart   = @tab + ifPart unless child
    return ifPart unless @elseBody
    ifPart + ' else ' + if @isChain
       @elseBodyNode().compile merge o, indent: @tab, chainChild: true
    else
      "{\n#{ @elseBody.compile o, LEVEL_TOP }\n#{@tab}}"

  # Compile the If as a conditional operator.
  compileExpression: (o) ->
    code = @condition .compile(o, LEVEL_COND) + ' ? ' +
           @bodyNode().compile(o, LEVEL_LIST) + ' : ' +
           @elseBodyNode()?.compile o, LEVEL_LIST
    if o.level >= LEVEL_COND then "(#{code})" else code

  unfoldSoak: -> @soakNode and this

  # Unfold a node's child if soak, then tuck the node under created `If`
  @unfoldSoak: (o, parent, name) ->
    return unless ifn = parent[name].unfoldSoak o
    parent[name] = ifn.body
    ifn.body     = new Value parent
    ifn

# Faux-Nodes
# ----------
# Faux-nodes are never created by the grammar, but are used during code
# generation to generate other combinations of nodes.

#### Push

# The **Push** creates the tree for `array.push(value)`,
# which is helpful for recording the result arrays from comprehensions.
Push =
  wrap: (name, expressions) ->
    return expressions if expressions.empty() or expressions.containsPureStatement()
    Expressions.wrap [new Call(
      new Value new Literal(name), [new Accessor new Literal 'push']
      [expressions.unwrap()]
    )]

#### Closure

# A faux-node used to wrap an expressions body in a closure.
Closure =

  # Wrap the expressions body, unless it contains a pure statement,
  # in which case, no dice. If the body mentions `this` or `arguments`,
  # then make sure that the closure wrapper preserves the original values.
  wrap: (expressions, statement, noReturn) ->
    return expressions if expressions.containsPureStatement()
    func = new Parens new Code [], Expressions.wrap [expressions]
    args = []
    if (mentionsArgs = expressions.contains @literalArgs) or
       (               expressions.contains @literalThis)
      meth = new Literal if mentionsArgs then 'apply' else 'call'
      args = [new Literal 'this']
      args.push new Literal 'arguments' if mentionsArgs
      func = new Value func, [new Accessor meth]
      func.noReturn = noReturn
    call = new Call func, args
    if statement then Expressions.wrap [call] else call

  literalArgs: (node) -> node instanceof Literal and node.value is 'arguments'
  literalThis: (node) -> node instanceof Literal and node.value is 'this' or
                         node instanceof Code    and node.bound

# Constants
# ---------

UTILITIES =

  # Correctly set up a prototype chain for inheritance, including a reference
  # to the superclass for `super()` calls. See:
  # [goog.inherits](http://closure-library.googlecode.com/svn/docs/closureGoogBase.js.source.html#line1206).
  extends: '''
    function(child, parent) {
      function ctor() { this.constructor = child; }
      ctor.prototype = parent.prototype;
      child.prototype = new ctor;
      if (typeof parent.extended === "function") parent.extended(child);
      child.__super__ = parent.prototype;
    }
  '''

  # Create a function bound to the current value of "this".
  bind: '''
    function(func, context) {
      return function() { return func.apply(context, arguments); };
    }
  '''

  # Discover if an item is in an array.
  indexOf: '''
    Array.prototype.indexOf || function(item) {
      for (var i = 0, l = this.length; i < l; i++) if (this[i] === item) return i;
      return -1;
    }
  '''

  # Shortcuts to speed up the lookup time for native functions.
  hasProp: 'Object.prototype.hasOwnProperty'
  slice  : 'Array.prototype.slice'

# Levels indicates a node's position in the AST.
LEVEL_TOP    = 0  # ...;
LEVEL_PAREN  = 1  # (...)
LEVEL_LIST   = 2  # [...]
LEVEL_COND   = 3  # ... ? x : y
LEVEL_OP     = 4  # !...
LEVEL_ACCESS = 5  # ...[0]

# Tabs are two spaces for pretty printing.
TAB = '  '

# Trim out all trailing whitespace, so that the generated code plays nice
# with Git.
TRAILING_WHITESPACE = /[ \t]+$/gm

IDENTIFIER = /^[$A-Za-z_][$\w]*$/
NUMBER     = /// ^ -? (?: 0x[\da-f]+ | (?:\d+(\.\d+)?|\.\d+)(?:e[+-]?\d+)? ) $ ///i
SIMPLENUM  = /^[+-]?\d+$/

# Is a literal value a string?
IS_STRING = /^['"]/

# Utility Functions
# -----------------

# Helper for ensuring that utility functions are assigned at the top level.
utility = (name) ->
  ref = "__#{name}"
  Scope.root.assign ref, UTILITIES[name]
  ref

multident = (code, tab) -> code.replace /\n/g, '$&' + tab
