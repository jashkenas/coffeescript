# `nodes.coffee` contains all of the node classes for the syntax tree. Most
# nodes are created as the result of actions in the [grammar](grammar.html),
# but some are created by other nodes as a method of code generation. To convert
# the syntax tree into a string of JavaScript code, call `compile()` on the root.

Error.stackTraceLimit = Infinity

{Scope} = require './scope'
{RESERVED, STRICT_PROSCRIBED} = require './lexer'

# Import the helpers we plan to use.
{compact, flatten, extend, merge, del, starts, ends, last, some,
addLocationDataFn, locationDataToString, throwSyntaxError} = require './helpers'

# Functions required by parser
exports.extend = extend
exports.addLocationDataFn = addLocationDataFn

# Constant functions for nodes that don't need customization.
YES     = -> yes
NO      = -> no
THIS    = -> this
NEGATE  = -> @negated = not @negated; this

#### CodeFragment

# The various nodes defined below all compile to a collection of **CodeFragment** objects.
# A CodeFragments is a block of generated code, and the location in the source file where the code
# came from. CodeFragments can be assembled together into working code just by catting together
# all the CodeFragments' `code` snippets, in order.
exports.CodeFragment = class CodeFragment
  constructor: (parent, code) ->
    @code = "#{code}"
    @locationData = parent?.locationData
    @type = parent?.constructor?.name or 'unknown'

  toString:   ->
    "#{@code}#{if @locationData then ": " + locationDataToString(@locationData) else ''}"

# Convert an array of CodeFragments into a string.
fragmentsToText = (fragments) ->
  (fragment.code for fragment in fragments).join('')

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

  compile: (o, lvl) ->
    fragmentsToText @compileToFragments o, lvl

  # Common logic for determining whether to wrap this node in a closure before
  # compiling it, or to compile directly. We need to wrap if this node is a
  # *statement*, and it's not a *pureStatement*, and we're not at
  # the top level of a block (which would be unnecessary), and we haven't
  # already been asked to return the result (because statements know how to
  # return results).
  compileToFragments: (o, lvl) ->
    o        = extend {}, o
    o.level  = lvl if lvl
    node     = @unfoldSoak(o) or this
    node.tab = o.indent
    if o.level is LEVEL_TOP or not node.isStatement(o)
      node.compileNode o
    else
      node.compileClosure o

  # Statements converted into expressions via closure-wrapping share a scope
  # object with their parent closure, to preserve the expected lexical scope.
  compileClosure: (o) ->
    if jumpNode = @jumps()
      jumpNode.error 'cannot use a pure statement in an expression'
    o.sharedScope = yes
    Closure.wrap(this).compileNode o

  # If the code generation wishes to use the result of a complex expression
  # in multiple places, ensure that the expression is only ever evaluated once,
  # by assigning it to a temporary variable. Pass a level to precompile.
  #
  # If `level` is passed, then returns `[val, ref]`, where `val` is the compiled value, and `ref`
  # is the compiled reference. If `level` is not passed, this returns `[val, ref]` where
  # the two values are raw nodes which have not been compiled.
  cache: (o, level, reused) ->
    unless @isComplex()
      ref = if level then @compileToFragments o, level else this
      [ref, ref]
    else
      ref = new Literal reused or o.scope.freeVariable 'ref'
      sub = new Assign ref, this
      if level then [sub.compileToFragments(o, level), [@makeCode(ref.value)]] else [sub, ref]

  cacheToCodeFragments: (cacheValues) ->
    [fragmentsToText(cacheValues[0]), fragmentsToText(cacheValues[1])]

  # Construct a node that returns the current node's result.
  # Note that this is overridden for smarter behavior for
  # many statement nodes (e.g. If, For)...
  makeReturn: (res) ->
    me = @unwrapAll()
    if res
      new Call new Literal("#{res}.push"), [me]
    else
      new Return me

  # Does this node, or any of its children, contain a node of a certain kind?
  # Recursively traverses down the *children* nodes and returns the first one
  # that verifies `pred`. Otherwise return undefined. `contains` does not cross
  # scope boundaries.
  contains: (pred) ->
    node = undefined
    @traverseChildren no, (n) ->
      if pred n
        node = n
        return no
    node

  # Pull out the last non-comment node of a node list.
  lastNonComment: (list) ->
    i = list.length
    return list[i] while i-- when list[i] not instanceof Comment
    null

  # `toString` representation of the node, for inspecting the parse tree.
  # This is what `coffee --nodes` prints out.
  toString: (idt = '', name = @constructor.name) ->
    tree = '\n' + idt + name
    tree += '?' if @soak
    @eachChild (node) -> tree += node.toString idt + TAB
    tree

  # Passes each child to a function, breaking when the function returns `false`.
  eachChild: (func) ->
    return this unless @children
    for attr in @children when @[attr]
      for child in flatten [@[attr]]
        return this if func(child) is false
    this

  traverseChildren: (crossScope, func) ->
    @eachChild (child) ->
      recur = func(child)
      child.traverseChildren(crossScope, func) unless recur is no

  invert: ->
    new Op '!', this

  unwrapAll: ->
    node = this
    continue until node is node = node.unwrap()
    node

  # Default implementations of the common node properties and methods. Nodes
  # will override these with custom logic, if needed.
  children: []

  isStatement     : NO
  jumps           : NO
  isComplex       : YES
  isChainable     : NO
  isAssignable    : NO

  unwrap     : THIS
  unfoldSoak : NO

  # Is this node used to assign a certain variable?
  assigns: NO

  # For this node and all descendents, set the location data to `locationData`
  # if the location data is not already set.
  updateLocationDataIfMissing: (locationData) ->
    return this if @locationData
    @locationData = locationData

    @eachChild (child) ->
      child.updateLocationDataIfMissing locationData

  # Throw a SyntaxError associated with this node's location.
  error: (message) ->
    throwSyntaxError message, @locationData

  makeCode: (code) ->
    new CodeFragment this, code

  wrapInBraces: (fragments) ->
    [].concat @makeCode('('), fragments, @makeCode(')')

  # `fragmentsList` is an array of arrays of fragments. Each array in fragmentsList will be
  # concatonated together, with `joinStr` added in between each, to produce a final flat array
  # of fragments.
  joinFragmentArrays: (fragmentsList, joinStr) ->
    answer = []
    for fragments,i in fragmentsList
      if i then answer.push @makeCode joinStr
      answer = answer.concat fragments
    answer

#### Block

# The block is the list of expressions that forms the body of an
# indented block of code -- the implementation of a function, a clause in an
# `if`, `switch`, or `try`, and so on...
exports.Block = class Block extends Base
  constructor: (nodes) ->
    @expressions = compact flatten nodes or []

  children: ['expressions']

  # Tack an expression on to the end of this expression list.
  push: (node) ->
    @expressions.push node
    this

  # Remove and return the last expression of this expression list.
  pop: ->
    @expressions.pop()

  # Add an expression at the beginning of this expression list.
  unshift: (node) ->
    @expressions.unshift node
    this

  # If this Block consists of just a single node, unwrap it by pulling
  # it back out.
  unwrap: ->
    if @expressions.length is 1 then @expressions[0] else this

  # Is this an empty block of code?
  isEmpty: ->
    not @expressions.length

  isStatement: (o) ->
    for exp in @expressions when exp.isStatement o
      return yes
    no

  jumps: (o) ->
    for exp in @expressions
      return exp if exp.jumps o

  # A Block node does not return its entire body, rather it
  # ensures that the final expression is returned.
  makeReturn: (res) ->
    len = @expressions.length
    while len--
      expr = @expressions[len]
      if expr not instanceof Comment
        @expressions[len] = expr.makeReturn res
        @expressions.splice(len, 1) if expr instanceof Return and not expr.expression
        break
    this

  # A **Block** is the only node that can serve as the root.
  compileToFragments: (o = {}, level) ->
    if o.scope then super o, level else @compileRoot o

  # Compile all expressions within the **Block** body. If we need to
  # return the result, and it's an expression, simply return it. If it's a
  # statement, ask the statement to do so.
  compileNode: (o) ->
    @tab  = o.indent
    top   = o.level is LEVEL_TOP
    compiledNodes = []

    for node, index in @expressions

      node = node.unwrapAll()
      node = (node.unfoldSoak(o) or node)
      if node instanceof Block
        # This is a nested block. We don't do anything special here like enclose
        # it in a new scope; we just compile the statements in this block along with
        # our own
        compiledNodes.push node.compileNode o
      else if top
        node.front = true
        fragments = node.compileToFragments o
        unless node.isStatement o
          fragments.unshift @makeCode "#{@tab}"
          fragments.push @makeCode ";"
        compiledNodes.push fragments
      else
        compiledNodes.push node.compileToFragments o, LEVEL_LIST
    if top
      if @spaced
        return [].concat @joinFragmentArrays(compiledNodes, '\n\n'), @makeCode("\n")
      else
        return @joinFragmentArrays(compiledNodes, '\n')
    if compiledNodes.length
      answer = @joinFragmentArrays(compiledNodes, ', ')
    else
      answer = [@makeCode "void 0"]
    if compiledNodes.length > 1 and o.level >= LEVEL_LIST then @wrapInBraces answer else answer

  # If we happen to be the top-level **Block**, wrap everything in
  # a safety closure, unless requested not to.
  # It would be better not to generate them in the first place, but for now,
  # clean up obvious double-parentheses.
  compileRoot: (o) ->
    o.indent  = if o.bare then '' else TAB
    o.level   = LEVEL_TOP
    @spaced   = yes
    o.scope   = new Scope null, this, null
    # Mark given local variables in the root scope as parameters so they don't
    # end up being declared on this block.
    o.scope.parameter name for name in o.locals or []
    prelude   = []
    unless o.bare
      preludeExps = for exp, i in @expressions
        break unless exp.unwrap() instanceof Comment
        exp
      rest = @expressions[preludeExps.length...]
      @expressions = preludeExps
      if preludeExps.length
        prelude = @compileNode merge(o, indent: '')
        prelude.push @makeCode "\n"
      @expressions = rest
    fragments = @compileWithDeclarations o
    return fragments if o.bare
    [].concat prelude, @makeCode("(function() {\n"), fragments, @makeCode("\n}).call(this);\n")

  # Compile the expressions body for the contents of a function, with
  # declarations of all inner variables pushed up to the top.
  compileWithDeclarations: (o) ->
    fragments = []
    post = []
    for exp, i in @expressions
      exp = exp.unwrap()
      break unless exp instanceof Comment or exp instanceof Literal
    o = merge(o, level: LEVEL_TOP)
    if i
      rest = @expressions.splice i, 9e9
      [spaced,    @spaced] = [@spaced, no]
      [fragments, @spaced] = [@compileNode(o), spaced]
      @expressions = rest
    post = @compileNode o
    {scope} = o
    if scope.expressions is this
      declars = o.scope.hasDeclarations()
      assigns = scope.hasAssignments
      if declars or assigns
        fragments.push @makeCode '\n' if i
        fragments.push @makeCode "#{@tab}var "
        if declars
          fragments.push @makeCode scope.declaredVariables().join(', ')
        if assigns
          fragments.push @makeCode ",\n#{@tab + TAB}" if declars
          fragments.push @makeCode scope.assignedVariables().join(",\n#{@tab + TAB}")
        fragments.push @makeCode ";\n#{if @spaced then '\n' else ''}"
      else if fragments.length and post.length
        fragments.push @makeCode "\n"
    fragments.concat post

  # Wrap up the given nodes as a **Block**, unless it already happens
  # to be one.
  @wrap: (nodes) ->
    return nodes[0] if nodes.length is 1 and nodes[0] instanceof Block
    new Block nodes

#### Literal

# Literals are static values that can be passed through directly into
# JavaScript without translation, such as: strings, numbers,
# `true`, `false`, `null`...
exports.Literal = class Literal extends Base
  constructor: (@value) ->

  makeReturn: ->
    if @isStatement() then this else super

  isAssignable: ->
    IDENTIFIER.test @value

  isStatement: ->
    @value in ['break', 'continue', 'debugger']

  isComplex: NO

  assigns: (name) ->
    name is @value

  jumps: (o) ->
    return this if @value is 'break' and not (o?.loop or o?.block)
    return this if @value is 'continue' and not o?.loop

  compileNode: (o) ->
    code = if @value is 'this'
      if o.scope.method?.bound then o.scope.method.context else @value
    else if @value.reserved
      "\"#{@value}\""
    else
      @value
    answer = if @isStatement() then "#{@tab}#{code};" else code
    [@makeCode answer]

  toString: ->
    ' "' + @value + '"'

class exports.Undefined extends Base
  isAssignable: NO
  isComplex: NO
  compileNode: (o) ->
    [@makeCode if o.level >= LEVEL_ACCESS then '(void 0)' else 'void 0']

class exports.Null extends Base
  isAssignable: NO
  isComplex: NO
  compileNode: -> [@makeCode "null"]

class exports.Bool extends Base
  isAssignable: NO
  isComplex: NO
  compileNode: -> [@makeCode @val]
  constructor: (@val) ->

#### Return

# A `return` is a *pureStatement* -- wrapping it in a closure wouldn't
# make sense.
exports.Return = class Return extends Base
  constructor: (expr) ->
    @expression = expr if expr and not expr.unwrap().isUndefined

  children: ['expression']

  isStatement:     YES
  makeReturn:      THIS
  jumps:           THIS

  compileToFragments: (o, level) ->
    expr = @expression?.makeReturn()
    if expr and expr not instanceof Return then expr.compileToFragments o, level else super o, level

  compileNode: (o) ->
    answer = []
    # TODO: If we call expression.compile() here twice, we'll sometimes get back different results!
    answer.push @makeCode @tab + "return#{if @expression then " " else ""}"
    if @expression
      answer = answer.concat @expression.compileToFragments o, LEVEL_PAREN
    answer.push @makeCode ";"
    return answer


#### Value

# A value, variable or literal or parenthesized, indexed or dotted into,
# or vanilla.
exports.Value = class Value extends Base
  constructor: (base, props, tag) ->
    return base if not props and base instanceof Value
    @base       = base
    @properties = props or []
    @[tag]      = true if tag
    return this

  children: ['base', 'properties']

  # Add a property (or *properties* ) `Access` to the list.
  add: (props) ->
    @properties = @properties.concat props
    this

  hasProperties: ->
    !!@properties.length

  # Some boolean checks for the benefit of other nodes.
  isArray        : -> not @properties.length and @base instanceof Arr
  isComplex      : -> @hasProperties() or @base.isComplex()
  isAssignable   : -> @hasProperties() or @base.isAssignable()
  isSimpleNumber : -> @base instanceof Literal and SIMPLENUM.test @base.value
  isString       : -> @base instanceof Literal and IS_STRING.test @base.value
  isAtomic       : ->
    for node in @properties.concat @base
      return no if node.soak or node instanceof Call
    yes

  isStatement : (o)    -> not @properties.length and @base.isStatement o
  assigns     : (name) -> not @properties.length and @base.assigns name
  jumps       : (o)    -> not @properties.length and @base.jumps o

  isObject: (onlyGenerated) ->
    return no if @properties.length
    (@base instanceof Obj) and (not onlyGenerated or @base.generated)

  isSplice: ->
    last(@properties) instanceof Slice

  # The value can be unwrapped as its inner node, if there are no attached
  # properties.
  unwrap: ->
    if @properties.length then this else @base

  # A reference has base part (`this` value) and name part.
  # We cache them separately for compiling complex expressions.
  # `a()[b()] ?= c` -> `(_base = a())[_name = b()] ? _base[_name] = c`
  cacheReference: (o) ->
    name = last @properties
    if @properties.length < 2 and not @base.isComplex() and not name?.isComplex()
      return [this, this]  # `a` `a.b`
    base = new Value @base, @properties[...-1]
    if base.isComplex()  # `a().b`
      bref = new Literal o.scope.freeVariable 'base'
      base = new Value new Parens new Assign bref, base
    return [base, bref] unless name  # `a()`
    if name.isComplex()  # `a[b()]`
      nref = new Literal o.scope.freeVariable 'name'
      name = new Index new Assign nref, name.index
      nref = new Index nref
    [base.add(name), new Value(bref or base.base, [nref or name])]

  # We compile a value to JavaScript by compiling and joining each property.
  # Things get much more interesting if the chain of properties has *soak*
  # operators `?.` interspersed. Then we have to take care not to accidentally
  # evaluate anything twice when building the soak chain.
  compileNode: (o) ->
    @base.front = @front
    props = @properties
    fragments = @base.compileToFragments o, (if props.length then LEVEL_ACCESS else null)
    if (@base instanceof Parens or props.length) and SIMPLENUM.test fragmentsToText fragments
      fragments.push @makeCode '.'
    for prop in props
      fragments.push (prop.compileToFragments o)...
    fragments

  # Unfold a soak into an `If`: `a?.b` -> `a.b if a?`
  unfoldSoak: (o) ->
    @unfoldedSoak ?= do =>
      if ifn = @base.unfoldSoak o
        ifn.body.properties.push @properties...
        return ifn
      for prop, i in @properties when prop.soak
        prop.soak = off
        fst = new Value @base, @properties[...i]
        snd = new Value @base, @properties[i..]
        if fst.isComplex()
          ref = new Literal o.scope.freeVariable 'ref'
          fst = new Parens new Assign ref, fst
          snd.base = ref
        return new If new Existence(fst), snd, soak: on
      no

#### Comment

# CoffeeScript passes through block comments as JavaScript block comments
# at the same position.
exports.Comment = class Comment extends Base
  constructor: (@comment) ->

  isStatement:     YES
  makeReturn:      THIS

  compileNode: (o, level) ->
    code = "/*#{multident @comment, @tab}#{if '\n' in @comment then "\n#{@tab}" else ''}*/"
    code = o.indent + code if (level or o.level) is LEVEL_TOP
    [@makeCode("\n"), @makeCode(code)]

#### Call

# Node for a function invocation. Takes care of converting `super()` calls into
# calls against the prototype's function of the same name.
exports.Call = class Call extends Base
  constructor: (variable, @args = [], @soak) ->
    @isNew    = false
    @isSuper  = variable is 'super'
    @variable = if @isSuper then null else variable

  children: ['variable', 'args']

  # Tag this invocation as creating a new instance.
  newInstance: ->
    base = @variable?.base or @variable
    if base instanceof Call and not base.isNew
      base.newInstance()
    else
      @isNew = true
    this

  # Grab the reference to the superclass's implementation of the current
  # method.
  superReference: (o) ->
    method = o.scope.namedMethod()
    if method?.klass
      accesses = [new Access(new Literal '__super__')]
      accesses.push new Access new Literal 'constructor' if method.static
      accesses.push new Access new Literal method.name
      (new Value (new Literal method.klass), accesses).compile o
    else if method?.ctor
      "#{method.name}.__super__.constructor"
    else
      @error 'cannot call super outside of an instance method.'

  # The appropriate `this` value for a `super` call.
  superThis : (o) ->
    method = o.scope.method
    (method and not method.klass and method.context) or "this"

  # Soaked chained invocations unfold into if/else ternary structures.
  unfoldSoak: (o) ->
    if @soak
      if @variable
        return ifn if ifn = unfoldSoak o, this, 'variable'
        [left, rite] = new Value(@variable).cacheReference o
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
      ifn = unfoldSoak o, call, 'variable'
    ifn

  # Compile a vanilla function call.
  compileNode: (o) ->
    @variable?.front = @front
    compiledArray = Splat.compileSplattedArray o, @args, true
    if compiledArray.length
      return @compileSplat o, compiledArray
    compiledArgs = []
    for arg, argIndex in @args
      if argIndex then compiledArgs.push @makeCode ", "
      compiledArgs.push (arg.compileToFragments o, LEVEL_LIST)...

    fragments = []
    if @isSuper
      preface = @superReference(o) + ".call(#{@superThis(o)}"
      if compiledArgs.length then preface += ", "
      fragments.push @makeCode preface
    else
      if @isNew then fragments.push @makeCode 'new '
      fragments.push @variable.compileToFragments(o, LEVEL_ACCESS)...
      fragments.push @makeCode "("
    fragments.push compiledArgs...
    fragments.push @makeCode ")"
    fragments

  # If you call a function with a splat, it's converted into a JavaScript
  # `.apply()` call to allow an array of arguments to be passed.
  # If it's a constructor, then things get real tricky. We have to inject an
  # inner constructor in order to be able to pass the varargs.
  #
  # splatArgs is an array of CodeFragments to put into the 'apply'.
  compileSplat: (o, splatArgs) ->
    if @isSuper
      return [].concat @makeCode("#{ @superReference o }.apply(#{@superThis(o)}, "),
        splatArgs, @makeCode(")")

    if @isNew
      idt = @tab + TAB
      return [].concat @makeCode("""
        (function(func, args, ctor) {
        #{idt}ctor.prototype = func.prototype;
        #{idt}var child = new ctor, result = func.apply(child, args);
        #{idt}return Object(result) === result ? result : child;
        #{@tab}})("""),
        (@variable.compileToFragments o, LEVEL_LIST),
        @makeCode(", "), splatArgs, @makeCode(", function(){})")

    answer = []
    base = new Value @variable
    if (name = base.properties.pop()) and base.isComplex()
      ref = o.scope.freeVariable 'ref'
      answer = answer.concat @makeCode("(#{ref} = "),
        (base.compileToFragments o, LEVEL_LIST),
        @makeCode(")"),
        name.compileToFragments(o)
    else
      fun = base.compileToFragments o, LEVEL_ACCESS
      fun = @wrapInBraces fun if SIMPLENUM.test fragmentsToText fun
      if name
        ref = fragmentsToText fun
        fun.push (name.compileToFragments o)...
      else
        ref = 'null'
      answer = answer.concat fun
    answer = answer.concat @makeCode(".apply(#{ref}, "), splatArgs, @makeCode(")")

#### Extends

# Node to extend an object's prototype with an ancestor object.
# After `goog.inherits` from the
# [Closure Library](http://closure-library.googlecode.com/svn/docs/closureGoogBase.js.html).
exports.Extends = class Extends extends Base
  constructor: (@child, @parent) ->

  children: ['child', 'parent']

  # Hooks one constructor into another's prototype chain.
  compileToFragments: (o) ->
    new Call(new Value(new Literal utility 'extends'), [@child, @parent]).compileToFragments o

#### Access

# A `.` access into a property of a value, or the `::` shorthand for
# an access into the object's prototype.
exports.Access = class Access extends Base
  constructor: (@name, tag) ->
    @name.asKey = yes
    @soak  = tag is 'soak'

  children: ['name']

  compileToFragments: (o) ->
    name = @name.compileToFragments o
    if IDENTIFIER.test fragmentsToText name
      name.unshift @makeCode "."
    else
      name.unshift @makeCode "["
      name.push @makeCode "]"
    name

  isComplex: NO

#### Index

# A `[ ... ]` indexed access into an array or object.
exports.Index = class Index extends Base
  constructor: (@index) ->

  children: ['index']

  compileToFragments: (o) ->
    [].concat @makeCode("["), @index.compileToFragments(o, LEVEL_PAREN), @makeCode("]")

  isComplex: ->
    @index.isComplex()

#### Range

# A range literal. Ranges can be used to extract portions (slices) of arrays,
# to specify a range for comprehensions, or as a value, to be expanded into the
# corresponding array of integers at runtime.
exports.Range = class Range extends Base

  children: ['from', 'to']

  constructor: (@from, @to, tag) ->
    @exclusive = tag is 'exclusive'
    @equals = if @exclusive then '' else '='



  # Compiles the range's source variables -- where it starts and where it ends.
  # But only if they need to be cached to avoid double evaluation.
  compileVariables: (o) ->
    o = merge o, top: true
    [@fromC, @fromVar]  =  @cacheToCodeFragments @from.cache o, LEVEL_LIST
    [@toC, @toVar]      =  @cacheToCodeFragments @to.cache o, LEVEL_LIST
    [@step, @stepVar]   =  @cacheToCodeFragments step.cache o, LEVEL_LIST if step = del o, 'step'
    [@fromNum, @toNum]  = [@fromVar.match(SIMPLENUM), @toVar.match(SIMPLENUM)]
    @stepNum            = @stepVar.match(SIMPLENUM) if @stepVar

  # When compiled normally, the range returns the contents of the *for loop*
  # needed to iterate over the values in the range. Used by comprehensions.
  compileNode: (o) ->
    @compileVariables o unless @fromVar
    return @compileArray(o) unless o.index

    # Set up endpoints.
    known    = @fromNum and @toNum
    idx      = del o, 'index'
    idxName  = del o, 'name'
    namedIndex = idxName and idxName isnt idx
    varPart  = "#{idx} = #{@fromC}"
    varPart += ", #{@toC}" if @toC isnt @toVar
    varPart += ", #{@step}" if @step isnt @stepVar
    [lt, gt] = ["#{idx} <#{@equals}", "#{idx} >#{@equals}"]

    # Generate the condition.
    condPart = if @stepNum
      if +@stepNum > 0 then "#{lt} #{@toVar}" else "#{gt} #{@toVar}"
    else if known
      [from, to] = [+@fromNum, +@toNum]
      if from <= to then "#{lt} #{to}" else "#{gt} #{to}"
    else
      cond = if @stepVar then "#{@stepVar} > 0" else "#{@fromVar} <= #{@toVar}"
      "#{cond} ? #{lt} #{@toVar} : #{gt} #{@toVar}"

    # Generate the step.
    stepPart = if @stepVar
      "#{idx} += #{@stepVar}"
    else if known
      if namedIndex
        if from <= to then "++#{idx}" else "--#{idx}"
      else
        if from <= to then "#{idx}++" else "#{idx}--"
    else
      if namedIndex
        "#{cond} ? ++#{idx} : --#{idx}"
      else
        "#{cond} ? #{idx}++ : #{idx}--"

    varPart  = "#{idxName} = #{varPart}" if namedIndex
    stepPart = "#{idxName} = #{stepPart}" if namedIndex

    # The final loop body.
    [@makeCode "#{varPart}; #{condPart}; #{stepPart}"]


  # When used as a value, expand the range into the equivalent array.
  compileArray: (o) ->
    if @fromNum and @toNum and Math.abs(@fromNum - @toNum) <= 20
      range = [+@fromNum..+@toNum]
      range.pop() if @exclusive
      return [@makeCode "[#{ range.join(', ') }]"]
    idt    = @tab + TAB
    i      = o.scope.freeVariable 'i'
    result = o.scope.freeVariable 'results'
    pre    = "\n#{idt}#{result} = [];"
    if @fromNum and @toNum
      o.index = i
      body    = fragmentsToText @compileNode o
    else
      vars    = "#{i} = #{@fromC}" + if @toC isnt @toVar then ", #{@toC}" else ''
      cond    = "#{@fromVar} <= #{@toVar}"
      body    = "var #{vars}; #{cond} ? #{i} <#{@equals} #{@toVar} : #{i} >#{@equals} #{@toVar}; #{cond} ? #{i}++ : #{i}--"
    post   = "{ #{result}.push(#{i}); }\n#{idt}return #{result};\n#{o.indent}"
    hasArgs = (node) -> node?.contains (n) -> n instanceof Literal and n.value is 'arguments' and not n.asKey
    args   = ', arguments' if hasArgs(@from) or hasArgs(@to)
    [@makeCode "(function() {#{pre}\n#{idt}for (#{body})#{post}}).apply(this#{args ? ''})"]

#### Slice

# An array slice literal. Unlike JavaScript's `Array#slice`, the second parameter
# specifies the index of the end of the slice, just as the first parameter
# is the index of the beginning.
exports.Slice = class Slice extends Base

  children: ['range']

  constructor: (@range) ->
    super()

  # We have to be careful when trying to slice through the end of the array,
  # `9e9` is used because not all implementations respect `undefined` or `1/0`.
  # `9e9` should be safe because `9e9` > `2**32`, the max array length.
  compileNode: (o) ->
    {to, from} = @range
    fromCompiled = from and from.compileToFragments(o, LEVEL_PAREN) or [@makeCode '0']
    # TODO: jwalton - move this into the 'if'?
    if to
      compiled     = to.compileToFragments o, LEVEL_PAREN
      compiledText = fragmentsToText compiled
      if not (not @range.exclusive and +compiledText is -1)
        toStr = ', ' + if @range.exclusive
          compiledText
        else if SIMPLENUM.test compiledText
          "#{+compiledText + 1}"
        else
          compiled = to.compileToFragments o, LEVEL_ACCESS
          "+#{fragmentsToText compiled} + 1 || 9e9"
    [@makeCode ".slice(#{ fragmentsToText fromCompiled }#{ toStr or '' })"]

#### Obj

# An object literal, nothing fancy.
exports.Obj = class Obj extends Base
  constructor: (props, @generated = false) ->
    @objects = @properties = props or []

  children: ['properties']

  compileNode: (o) ->
    props = @properties
    return [@makeCode(if @front then '({})' else '{}')] unless props.length
    if @generated
      for node in props when node instanceof Value
        node.error 'cannot have an implicit value in an implicit object'
    idt         = o.indent += TAB
    lastNoncom  = @lastNonComment @properties
    answer = []
    for prop, i in props
      join = if i is props.length - 1
        ''
      else if prop is lastNoncom or prop instanceof Comment
        '\n'
      else
        ',\n'
      indent = if prop instanceof Comment then '' else idt
      if prop instanceof Assign and prop.variable instanceof Value and prop.variable.hasProperties()
        prop.variable.error 'Invalid object key'
      if prop instanceof Value and prop.this
        prop = new Assign prop.properties[0].name, prop, 'object'
      if prop not instanceof Comment
        if prop not instanceof Assign
          prop = new Assign prop, prop, 'object'
        (prop.variable.base or prop.variable).asKey = yes
      if indent then answer.push @makeCode indent
      answer.push prop.compileToFragments(o, LEVEL_TOP)...
      if join then answer.push @makeCode join
    answer.unshift @makeCode "{#{ props.length and '\n' }"
    answer.push @makeCode "#{ props.length and '\n' + @tab }}"
    if @front then @wrapInBraces answer else answer

  assigns: (name) ->
    for prop in @properties when prop.assigns name then return yes
    no

#### Arr

# An array literal.
exports.Arr = class Arr extends Base
  constructor: (objs) ->
    @objects = objs or []

  children: ['objects']

  compileNode: (o) ->
    return [@makeCode '[]'] unless @objects.length
    o.indent += TAB
    answer = Splat.compileSplattedArray o, @objects
    return answer if answer.length

    answer = []
    compiledObjs = (obj.compileToFragments o, LEVEL_LIST for obj in @objects)
    for fragments, index in compiledObjs
      if index
        answer.push @makeCode ", "
      answer.push fragments...
    if fragmentsToText(answer).indexOf('\n') >= 0
      answer.unshift @makeCode "[\n#{o.indent}"
      answer.push @makeCode "\n#{@tab}]"
    else
      answer.unshift @makeCode "["
      answer.push @makeCode "]"
    answer

  assigns: (name) ->
    for obj in @objects when obj.assigns name then return yes
    no

#### Class

# The CoffeeScript class definition.
# Initialize a **Class** with its name, an optional superclass, and a
# list of prototype property assignments.
exports.Class = class Class extends Base
  constructor: (@variable, @parent, @body = new Block) ->
    @boundFuncs = []
    @body.classBody = yes

  children: ['variable', 'parent', 'body']

  # Figure out the appropriate name for the constructor function of this class.
  determineName: ->
    return null unless @variable
    decl = if tail = last @variable.properties
      tail instanceof Access and tail.name.value
    else
      @variable.base.value
    if decl in STRICT_PROSCRIBED
      @variable.error "class variable name may not be #{decl}"
    decl and= IDENTIFIER.test(decl) and decl

  # For all `this`-references and bound functions in the class definition,
  # `this` is the Class being constructed.
  setContext: (name) ->
    @body.traverseChildren false, (node) ->
      return false if node.classBody
      if node instanceof Literal and node.value is 'this'
        node.value    = name
      else if node instanceof Code
        node.klass    = name
        node.context  = name if node.bound

  # Ensure that all functions bound to the instance are proxied in the
  # constructor.
  addBoundFunctions: (o) ->
    for bvar in @boundFuncs
      lhs = (new Value (new Literal "this"), [new Access bvar]).compile o
      @ctor.body.unshift new Literal "#{lhs} = #{utility 'bind'}(#{lhs}, this)"
    return

  # Merge the properties from a top-level object as prototypal properties
  # on the class.
  addProperties: (node, name, o) ->
    props = node.base.properties[..]
    exprs = while assign = props.shift()
      if assign instanceof Assign
        base = assign.variable.base
        delete assign.context
        func = assign.value
        if base.value is 'constructor'
          if @ctor
            assign.error 'cannot define more than one constructor in a class'
          if func.bound
            assign.error 'cannot define a constructor as a bound function'
          if func instanceof Code
            assign = @ctor = func
          else
            @externalCtor = o.scope.freeVariable 'class'
            assign = new Assign new Literal(@externalCtor), func
        else
          if assign.variable.this
            func.static = yes
            if func.bound
              func.context = name
          else
            assign.variable = new Value(new Literal(name), [(new Access new Literal 'prototype'), new Access base])
            if func instanceof Code and func.bound
              @boundFuncs.push base
              func.bound = no
      assign
    compact exprs

  # Walk the body of the class, looking for prototype properties to be converted.
  walkBody: (name, o) ->
    @traverseChildren false, (child) =>
      cont = true
      return false if child instanceof Class
      if child instanceof Block
        for node, i in exps = child.expressions
          if node instanceof Value and node.isObject(true)
            cont = false
            exps[i] = @addProperties node, name, o
        child.expressions = exps = flatten exps
      cont and child not instanceof Class

  # `use strict` (and other directives) must be the first expression statement(s)
  # of a function body. This method ensures the prologue is correctly positioned
  # above the `constructor`.
  hoistDirectivePrologue: ->
    index = 0
    {expressions} = @body
    ++index while (node = expressions[index]) and node instanceof Comment or
      node instanceof Value and node.isString()
    @directives = expressions.splice 0, index

  # Make sure that a constructor is defined for the class, and properly
  # configured.
  ensureConstructor: (name, o) ->
    missing = not @ctor
    @ctor or= new Code
    @ctor.ctor = @ctor.name = name
    @ctor.klass = null
    @ctor.noReturn = yes
    if missing
      superCall = new Literal "#{name}.__super__.constructor.apply(this, arguments)" if @parent
      superCall = new Literal "#{@externalCtor}.apply(this, arguments)" if @externalCtor
      if superCall
        ref = new Literal o.scope.freeVariable 'ref'
        @ctor.body.unshift new Assign ref, superCall
      @addBoundFunctions o
      if superCall
        @ctor.body.push ref
        @ctor.body.makeReturn()
      @body.expressions.unshift @ctor
    else
      @addBoundFunctions o


  # Instead of generating the JavaScript string directly, we build up the
  # equivalent syntax tree and compile that, in pieces. You can see the
  # constructor, property assignments, and inheritance getting built out below.
  compileNode: (o) ->
    decl  = @determineName()
    name  = decl or '_Class'
    name = "_#{name}" if name.reserved
    lname = new Literal name

    @hoistDirectivePrologue()
    @setContext name
    @walkBody name, o
    @ensureConstructor name, o
    @body.spaced = yes
    @body.expressions.unshift @ctor unless @ctor instanceof Code
    @body.expressions.push lname
    @body.expressions.unshift @directives...

    call  = Closure.wrap @body

    if @parent
      @superClass = new Literal o.scope.freeVariable 'super', no
      @body.expressions.unshift new Extends lname, @superClass
      call.args.push @parent
      params = call.variable.params or call.variable.base.params
      params.push new Param @superClass

    klass = new Parens call, yes
    klass = new Assign @variable, klass if @variable
    klass.compileToFragments o

#### Assign

# The **Assign** is used to assign a local variable to value, or to set the
# property of an object -- including within object literals.
exports.Assign = class Assign extends Base
  constructor: (@variable, @value, @context, options) ->
    @param = options and options.param
    @subpattern = options and options.subpattern
    forbidden = (name = @variable.unwrapAll().value) in STRICT_PROSCRIBED
    if forbidden and @context isnt 'object'
      @variable.error "variable name may not be \"#{name}\""

  children: ['variable', 'value']

  isStatement: (o) ->
    o?.level is LEVEL_TOP and @context? and "?" in @context

  assigns: (name) ->
    @[if @context is 'object' then 'value' else 'variable'].assigns name

  unfoldSoak: (o) ->
    unfoldSoak o, this, 'variable'

  # Compile an assignment, delegating to `compilePatternMatch` or
  # `compileSplice` if appropriate. Keep track of the name of the base object
  # we've been assigned to, for correct internal references. If the variable
  # has not been seen yet within the current scope, declare it.
  compileNode: (o) ->
    if isValue = @variable instanceof Value
      return @compilePatternMatch o if @variable.isArray() or @variable.isObject()
      return @compileSplice       o if @variable.isSplice()
      return @compileConditional  o if @context in ['||=', '&&=', '?=']
    compiledName = @variable.compileToFragments o, LEVEL_LIST
    name = fragmentsToText compiledName
    unless @context
      varBase = @variable.unwrapAll()
      unless varBase.isAssignable()
        @variable.error "\"#{@variable.compile o}\" cannot be assigned"
      unless varBase.hasProperties?()
        if @param
          o.scope.add name, 'var'
        else
          o.scope.find name
    if @value instanceof Code and match = METHOD_DEF.exec name
      @value.klass = match[1] if match[1]
      @value.name  = match[2] ? match[3] ? match[4] ? match[5]
    val = @value.compileToFragments o, LEVEL_LIST
    return (compiledName.concat @makeCode(": "), val) if @context is 'object'
    answer = compiledName.concat @makeCode(" #{ @context or '=' } "), val
    if o.level <= LEVEL_LIST then answer else @wrapInBraces answer

  # Brief implementation of recursive pattern matching, when assigning array or
  # object literals to a value. Peeks at their properties to assign inner names.
  # See the [ECMAScript Harmony Wiki](http://wiki.ecmascript.org/doku.php?id=harmony:destructuring)
  # for details.
  compilePatternMatch: (o) ->
    top       = o.level is LEVEL_TOP
    {value}   = this
    {objects} = @variable.base
    unless olen = objects.length
      code = value.compileToFragments o
      return if o.level >= LEVEL_OP then @wrapInBraces code else code
    isObject = @variable.isObject()
    if top and olen is 1 and (obj = objects[0]) not instanceof Splat
      # Unroll simplest cases: `{v} = x` -> `v = x.v`
      if obj instanceof Assign
        {variable: {base: idx}, value: obj} = obj
      else
        idx = if isObject
          if obj.this then obj.properties[0].name else obj
        else
          new Literal 0
      acc   = IDENTIFIER.test idx.unwrap().value or 0
      value = new Value value
      value.properties.push new (if acc then Access else Index) idx
      if obj.unwrap().value in RESERVED
        obj.error "assignment to a reserved word: #{obj.compile o}"
      return new Assign(obj, value, null, param: @param).compileToFragments o, LEVEL_TOP
    vvar    = value.compileToFragments o, LEVEL_LIST
    vvarText = fragmentsToText vvar
    assigns = []
    splat   = false
    # Make vvar into a simple variable if it isn't already.
    if not IDENTIFIER.test(vvarText) or @variable.assigns(vvarText)
      assigns.push [@makeCode("#{ ref = o.scope.freeVariable 'ref' } = "), vvar...]
      vvar = [@makeCode ref]
      vvarText = ref
    for obj, i in objects
      # A regular array pattern-match.
      idx = i
      if isObject
        if obj instanceof Assign
          # A regular object pattern-match.
          {variable: {base: idx}, value: obj} = obj
        else
          # A shorthand `{a, b, @c} = val` pattern-match.
          if obj.base instanceof Parens
            [obj, idx] = new Value(obj.unwrapAll()).cacheReference o
          else
            idx = if obj.this then obj.properties[0].name else obj
      if not splat and obj instanceof Splat
        name = obj.name.unwrap().value
        obj = obj.unwrap()
        val = "#{olen} <= #{vvarText}.length ? #{ utility 'slice' }.call(#{vvarText}, #{i}"
        if rest = olen - i - 1
          ivar = o.scope.freeVariable 'i'
          val += ", #{ivar} = #{vvarText}.length - #{rest}) : (#{ivar} = #{i}, [])"
        else
          val += ") : []"
        val   = new Literal val
        splat = "#{ivar}++"
      else
        name = obj.unwrap().value
        if obj instanceof Splat
          obj.error "multiple splats are disallowed in an assignment"
        if typeof idx is 'number'
          idx = new Literal splat or idx
          acc = no
        else
          acc = isObject and IDENTIFIER.test idx.unwrap().value or 0
        val = new Value new Literal(vvarText), [new (if acc then Access else Index) idx]
      if name? and name in RESERVED
        obj.error "assignment to a reserved word: #{obj.compile o}"
      assigns.push new Assign(obj, val, null, param: @param, subpattern: yes).compileToFragments o, LEVEL_LIST
    assigns.push vvar unless top or @subpattern
    fragments = @joinFragmentArrays assigns, ', '
    if o.level < LEVEL_LIST then fragments else @wrapInBraces fragments

  # When compiling a conditional assignment, take care to ensure that the
  # operands are only evaluated once, even though we have to reference them
  # more than once.
  compileConditional: (o) ->
    [left, right] = @variable.cacheReference o
    # Disallow conditional assignment of undefined variables.
    if not left.properties.length and left.base instanceof Literal and
           left.base.value != "this" and not o.scope.check left.base.value
      @variable.error "the variable \"#{left.base.value}\" can't be assigned with #{@context} because it has not been declared before"
    if "?" in @context then o.isExistentialEquals = true
    new Op(@context[...-1], left, new Assign(right, @value, '=')).compileToFragments o

  # Compile the assignment from an array splice literal, using JavaScript's
  # `Array#splice` method.
  compileSplice: (o) ->
    {range: {from, to, exclusive}} = @variable.properties.pop()
    name = @variable.compile o
    if from
      [fromDecl, fromRef] = @cacheToCodeFragments from.cache o, LEVEL_OP
    else
      fromDecl = fromRef = '0'
    if to
      if from?.isSimpleNumber() and to.isSimpleNumber()
        to = +to.compile(o) - +fromRef
        to += 1 unless exclusive
      else
        to = to.compile(o, LEVEL_ACCESS) + ' - ' + fromRef
        to += ' + 1' unless exclusive
    else
      to = "9e9"
    [valDef, valRef] = @value.cache o, LEVEL_LIST
    answer = [].concat @makeCode("[].splice.apply(#{name}, [#{fromDecl}, #{to}].concat("), valDef, @makeCode(")), "), valRef
    if o.level > LEVEL_TOP then @wrapInBraces answer else answer

#### Code

# A function definition. This is the only node that creates a new Scope.
# When for the purposes of walking the contents of a function body, the Code
# has no *children* -- they're within the inner scope.
exports.Code = class Code extends Base
  constructor: (params, body, tag) ->
    @params  = params or []
    @body    = body or new Block
    @bound   = tag is 'boundfunc'
    @context = '_this' if @bound

  children: ['params', 'body']

  isStatement: -> !!@ctor

  jumps: NO

  # Compilation creates a new scope unless explicitly asked to share with the
  # outer scope. Handles splat parameters in the parameter list by peeking at
  # the JavaScript `arguments` object. If the function is bound with the `=>`
  # arrow, generates a wrapper that saves the current value of `this` through
  # a closure.
  compileNode: (o) ->
    o.scope         = new Scope o.scope, @body, this
    o.scope.shared  = del(o, 'sharedScope')
    o.indent        += TAB
    delete o.bare
    delete o.isExistentialEquals
    params = []
    exprs  = []
    @eachParamName (name) -> # this step must be performed before the others
      unless o.scope.check name then o.scope.parameter name
    for param in @params when param.splat
      for {name: p} in @params
        if p.this then p = p.properties[0].name
        if p.value then o.scope.add p.value, 'var', yes
      splats = new Assign new Value(new Arr(p.asReference o for p in @params)),
                          new Value new Literal 'arguments'
      break
    for param in @params
      if param.isComplex()
        val = ref = param.asReference o
        val = new Op '?', ref, param.value if param.value
        exprs.push new Assign new Value(param.name), val, '=', param: yes
      else
        ref = param
        if param.value
          lit = new Literal ref.name.value + ' == null'
          val = new Assign new Value(param.name), param.value, '='
          exprs.push new If lit, val
      params.push ref unless splats
    wasEmpty = @body.isEmpty()
    exprs.unshift splats if splats
    @body.expressions.unshift exprs... if exprs.length
    for p, i in params
      params[i] = p.compileToFragments o
      o.scope.parameter fragmentsToText params[i]
    uniqs = []
    @eachParamName (name, node) ->
      node.error "multiple parameters named '#{name}'" if name in uniqs
      uniqs.push name
    @body.makeReturn() unless wasEmpty or @noReturn
    if @bound
      if o.scope.parent.method?.bound
        @bound = @context = o.scope.parent.method.context
      else if not @static
        o.scope.parent.assign '_this', 'this'
    idt   = o.indent
    code  = 'function'
    code  += ' ' + @name if @ctor
    code  += '('
    answer = [@makeCode(code)]
    for p, i in params
      if i then answer.push @makeCode ", "
      answer.push p...
    answer.push @makeCode ') {'
    answer = answer.concat(@makeCode("\n"), @body.compileWithDeclarations(o), @makeCode("\n#{@tab}")) unless @body.isEmpty()
    answer.push @makeCode '}'

    return [@makeCode(@tab), answer...] if @ctor
    if @front or (o.level >= LEVEL_ACCESS) then @wrapInBraces answer else answer

  eachParamName: (iterator) ->
    param.eachName iterator for param in @params

  # Short-circuit `traverseChildren` method to prevent it from crossing scope boundaries
  # unless `crossScope` is `true`.
  traverseChildren: (crossScope, func) ->
    super(crossScope, func) if crossScope

#### Param

# A parameter in a function definition. Beyond a typical Javascript parameter,
# these parameters can also attach themselves to the context of the function,
# as well as be a splat, gathering up a group of parameters into an array.
exports.Param = class Param extends Base
  constructor: (@name, @value, @splat) ->
    if (name = @name.unwrapAll().value) in STRICT_PROSCRIBED
      @name.error "parameter name \"#{name}\" is not allowed"

  children: ['name', 'value']

  compileToFragments: (o) ->
    @name.compileToFragments o, LEVEL_LIST

  asReference: (o) ->
    return @reference if @reference
    node = @name
    if node.this
      node = node.properties[0].name
      if node.value.reserved
        node = new Literal o.scope.freeVariable node.value
    else if node.isComplex()
      node = new Literal o.scope.freeVariable 'arg'
    node = new Value node
    node = new Splat node if @splat
    @reference = node

  isComplex: ->
    @name.isComplex()

  # Iterates the name or names of a `Param`.
  # In a sense, a destructured parameter represents multiple JS parameters. This
  # method allows to iterate them all.
  # The `iterator` function will be called as `iterator(name, node)` where
  # `name` is the name of the parameter and `node` is the AST node corresponding
  # to that name.
  eachName: (iterator, name = @name)->
    atParam = (obj) ->
      node = obj.properties[0].name
      iterator node.value, node unless node.value.reserved
    # * simple literals `foo`
    return iterator name.value, name if name instanceof Literal
    # * at-params `@foo`
    return atParam name if name instanceof Value
    for obj in name.objects
      # * assignments within destructured parameters `{foo:bar}`
      if obj instanceof Assign
        @eachName iterator, obj.value.unwrap()
      # * splats within destructured parameters `[xs...]`
      else if obj instanceof Splat
        node = obj.name.unwrap()
        iterator node.value, node
      else if obj instanceof Value
        # * destructured parameters within destructured parameters `[{a}]`
        if obj.isArray() or obj.isObject()
          @eachName iterator, obj.base
        # * at-params within destructured parameters `{@foo}`
        else if obj.this
          atParam obj
        # * simple destructured parameters {foo}
        else iterator obj.base.value, obj.base
      else
        obj.error "illegal parameter #{obj.compile()}"
    return

#### Splat

# A splat, either as a parameter to a function, an argument to a call,
# or as part of a destructuring assignment.
exports.Splat = class Splat extends Base

  children: ['name']

  isAssignable: YES

  constructor: (name) ->
    @name = if name.compile then name else new Literal name

  assigns: (name) ->
    @name.assigns name

  compileToFragments: (o) ->
    @name.compileToFragments o

  unwrap: -> @name

  # Utility function that converts an arbitrary number of elements, mixed with
  # splats, to a proper array.
  @compileSplattedArray: (o, list, apply) ->
    index = -1
    continue while (node = list[++index]) and node not instanceof Splat
    return [] if index >= list.length
    if list.length is 1
      node = list[0]
      fragments = node.compileToFragments o, LEVEL_LIST
      return fragments if apply
      return [].concat node.makeCode("#{ utility 'slice' }.call("), fragments, node.makeCode(")")
    args = list[index..]
    for node, i in args
      compiledNode = node.compileToFragments o, LEVEL_LIST
      args[i] = if node instanceof Splat
      then [].concat node.makeCode("#{ utility 'slice' }.call("), compiledNode, node.makeCode(")")
      else [].concat node.makeCode("["), compiledNode, node.makeCode("]")
    if index is 0
      node = list[0]
      concatPart = (node.joinFragmentArrays args[1..], ', ')
      return args[0].concat node.makeCode(".concat("), concatPart, node.makeCode(")")
    base = (node.compileToFragments o, LEVEL_LIST for node in list[...index])
    base = list[0].joinFragmentArrays base, ', '
    concatPart = list[index].joinFragmentArrays args, ', '
    [].concat list[0].makeCode("["), base, list[index].makeCode("].concat("), concatPart, (last list).makeCode(")")

#### While

# A while loop, the only sort of low-level loop exposed by CoffeeScript. From
# it, all other loops can be manufactured. Useful in cases where you need more
# flexibility or more speed than a comprehension can provide.
exports.While = class While extends Base
  constructor: (condition, options) ->
    @condition = if options?.invert then condition.invert() else condition
    @guard     = options?.guard

  children: ['condition', 'guard', 'body']

  isStatement: YES

  makeReturn: (res) ->
    if res
      super
    else
      @returns = not @jumps loop: yes
      this

  addBody: (@body) ->
    this

  jumps: ->
    {expressions} = @body
    return no unless expressions.length
    for node in expressions
      return node if node.jumps loop: yes
    no

  # The main difference from a JavaScript *while* is that the CoffeeScript
  # *while* can be used as a part of a larger expression -- while loops may
  # return an array containing the computed result of each iteration.
  compileNode: (o) ->
    o.indent += TAB
    set      = ''
    {body}   = this
    if body.isEmpty()
      body = @makeCode ''
    else
      if @returns
        body.makeReturn rvar = o.scope.freeVariable 'results'
        set  = "#{@tab}#{rvar} = [];\n"
      if @guard
        if body.expressions.length > 1
          body.expressions.unshift new If (new Parens @guard).invert(), new Literal "continue"
        else
          body = Block.wrap [new If @guard, body] if @guard
      body = [].concat @makeCode("\n"), (body.compileToFragments o, LEVEL_TOP), @makeCode("\n#{@tab}")
    answer = [].concat @makeCode(set + @tab + "while ("), @condition.compileToFragments(o, LEVEL_PAREN),
      @makeCode(") {"), body, @makeCode("}")
    if @returns
      answer.push @makeCode "\n#{@tab}return #{rvar};"
    answer

#### Op

# Simple Arithmetic and logical operations. Performs some conversion from
# CoffeeScript operations into their JavaScript equivalents.
exports.Op = class Op extends Base
  constructor: (op, first, second, flip ) ->
    return new In first, second if op is 'in'
    if op is 'do'
      return @generateDo first
    if op is 'new'
      return first.newInstance() if first instanceof Call and not first.do and not first.isNew
      first = new Parens first   if first instanceof Code and first.bound or first.do
    @operator = CONVERSIONS[op] or op
    @first    = first
    @second   = second
    @flip     = !!flip
    return this

  # The map of conversions from CoffeeScript to JavaScript symbols.
  CONVERSIONS =
    '==': '==='
    '!=': '!=='
    'of': 'in'

  # The map of invertible operators.
  INVERSIONS =
    '!==': '==='
    '===': '!=='

  children: ['first', 'second']

  isSimpleNumber: NO

  isUnary: ->
    not @second

  isComplex: ->
    not (@isUnary() and @operator in ['+', '-']) or @first.isComplex()

  # Am I capable of
  # [Python-style comparison chaining](http://docs.python.org/reference/expressions.html#notin)?
  isChainable: ->
    @operator in ['<', '>', '>=', '<=', '===', '!==']

  invert: ->
    if @isChainable() and @first.isChainable()
      allInvertable = yes
      curr = this
      while curr and curr.operator
        allInvertable and= (curr.operator of INVERSIONS)
        curr = curr.first
      return new Parens(this).invert() unless allInvertable
      curr = this
      while curr and curr.operator
        curr.invert = !curr.invert
        curr.operator = INVERSIONS[curr.operator]
        curr = curr.first
      this
    else if op = INVERSIONS[@operator]
      @operator = op
      if @first.unwrap() instanceof Op
        @first.invert()
      this
    else if @second
      new Parens(this).invert()
    else if @operator is '!' and (fst = @first.unwrap()) instanceof Op and
                                  fst.operator in ['!', 'in', 'instanceof']
      fst
    else
      new Op '!', this

  unfoldSoak: (o) ->
    @operator in ['++', '--', 'delete'] and unfoldSoak o, this, 'first'

  generateDo: (exp) ->
    passedParams = []
    func = if exp instanceof Assign and (ref = exp.value.unwrap()) instanceof Code
      ref
    else
      exp
    for param in func.params or []
      if param.value
        passedParams.push param.value
        delete param.value
      else
        passedParams.push param
    call = new Call exp, passedParams
    call.do = yes
    call

  compileNode: (o) ->
    isChain = @isChainable() and @first.isChainable()
    # In chains, there's no need to wrap bare obj literals in parens,
    # as the chained expression is wrapped.
    @first.front = @front unless isChain
    if @operator is 'delete' and o.scope.check(@first.unwrapAll().value)
      @error 'delete operand may not be argument or var'
    if @operator in ['--', '++'] and @first.unwrapAll().value in STRICT_PROSCRIBED
      @error "cannot increment/decrement \"#{@first.unwrapAll().value}\""
    return @compileUnary     o if @isUnary()
    return @compileChain     o if isChain
    return @compileExistence o if @operator is '?'
    answer = [].concat @first.compileToFragments(o, LEVEL_OP), @makeCode(' ' + @operator + ' '),
            @second.compileToFragments(o, LEVEL_OP)
    if o.level <= LEVEL_OP then answer else @wrapInBraces answer

  # Mimic Python's chained comparisons when multiple comparison operators are
  # used sequentially. For example:
  #
  #     bin/coffee -e 'console.log 50 < 65 > 10'
  #     true
  compileChain: (o) ->
    [@first.second, shared] = @first.second.cache o
    fst = @first.compileToFragments o, LEVEL_OP
    fragments = fst.concat @makeCode(" #{if @invert then '&&' else '||'} "),
      (shared.compileToFragments o), @makeCode(" #{@operator} "), (@second.compileToFragments o, LEVEL_OP)
    @wrapInBraces fragments

  # Keep reference to the left expression, unless this an existential assignment
  compileExistence: (o) ->
    if !o.isExistentialEquals and @first.isComplex()
      ref = new Literal o.scope.freeVariable 'ref'
      fst = new Parens new Assign ref, @first
    else
      fst = @first
      ref = fst
    new If(new Existence(fst), ref, type: 'if').addElse(@second).compileToFragments o

  # Compile a unary **Op**.
  compileUnary: (o) ->
    parts = []
    op = @operator
    parts.push [@makeCode op]
    if op is '!' and @first instanceof Existence
      @first.negated = not @first.negated
      return @first.compileToFragments o
    if o.level >= LEVEL_ACCESS
      return (new Parens this).compileToFragments o
    plusMinus = op in ['+', '-']
    parts.push [@makeCode(' ')] if op in ['new', 'typeof', 'delete'] or
                      plusMinus and @first instanceof Op and @first.operator is op
    if (plusMinus and @first instanceof Op) or (op is 'new' and @first.isStatement o)
      @first = new Parens @first
    parts.push @first.compileToFragments o, LEVEL_OP
    parts.reverse() if @flip
    @joinFragmentArrays parts, ''

  toString: (idt) ->
    super idt, @constructor.name + ' ' + @operator

#### In
exports.In = class In extends Base
  constructor: (@object, @array) ->

  children: ['object', 'array']

  invert: NEGATE

  compileNode: (o) ->
    if @array instanceof Value and @array.isArray()
      for obj in @array.base.objects when obj instanceof Splat
        hasSplat = yes
        break
      # `compileOrTest` only if we have an array literal with no splats
      return @compileOrTest o unless hasSplat
    @compileLoopTest o

  compileOrTest: (o) ->
    return [@makeCode("#{!!@negated}")] if @array.base.objects.length is 0
    [sub, ref] = @object.cache o, LEVEL_OP
    [cmp, cnj] = if @negated then [' !== ', ' && '] else [' === ', ' || ']
    tests = []
    for item, i in @array.base.objects
      if i then tests.push @makeCode cnj
      tests = tests.concat (if i then ref else sub), @makeCode(cmp), item.compileToFragments(o, LEVEL_ACCESS)
    if o.level < LEVEL_OP then tests else @wrapInBraces tests

  compileLoopTest: (o) ->
    [sub, ref] = @object.cache o, LEVEL_LIST
    fragments = [].concat @makeCode(utility('indexOf') + ".call("), @array.compileToFragments(o, LEVEL_LIST),
      @makeCode(", "), ref, @makeCode(") " + if @negated then '< 0' else '>= 0')
    return fragments if fragmentsToText(sub) is fragmentsToText(ref)
    fragments = sub.concat @makeCode(', '), fragments
    if o.level < LEVEL_LIST then fragments else @wrapInBraces fragments

  toString: (idt) ->
    super idt, @constructor.name + if @negated then '!' else ''

#### Try

# A classic *try/catch/finally* block.
exports.Try = class Try extends Base
  constructor: (@attempt, @errorVariable, @recovery, @ensure) ->

  children: ['attempt', 'recovery', 'ensure']

  isStatement: YES

  jumps: (o) -> @attempt.jumps(o) or @recovery?.jumps(o)

  makeReturn: (res) ->
    @attempt  = @attempt .makeReturn res if @attempt
    @recovery = @recovery.makeReturn res if @recovery
    this

  # Compilation is more or less as you would expect -- the *finally* clause
  # is optional, the *catch* is not.
  compileNode: (o) ->
    o.indent  += TAB
    tryPart   = @attempt.compileToFragments o, LEVEL_TOP

    catchPart = if @recovery
      placeholder = new Literal '_error'
      @recovery.unshift new Assign @errorVariable, placeholder if @errorVariable
      [].concat @makeCode(" catch ("), placeholder.compileToFragments(o), @makeCode(") {\n"),
        @recovery.compileToFragments(o, LEVEL_TOP), @makeCode("\n#{@tab}}")
    else unless @ensure or @recovery
      [@makeCode(' catch (_error) {}')]
    else
      []

    ensurePart = if @ensure then ([].concat @makeCode(" finally {\n"), @ensure.compileToFragments(o, LEVEL_TOP),
      @makeCode("\n#{@tab}}")) else []

    [].concat @makeCode("#{@tab}try {\n"),
      tryPart,
      @makeCode("\n#{@tab}}"), catchPart, ensurePart

#### Throw

# Simple node to throw an exception.
exports.Throw = class Throw extends Base
  constructor: (@expression) ->

  children: ['expression']

  isStatement: YES
  jumps:       NO

  # A **Throw** is already a return, of sorts...
  makeReturn: THIS

  compileNode: (o) ->
    [].concat @makeCode(@tab + "throw "), @expression.compileToFragments(o), @makeCode(";")

#### Existence

# Checks a variable for existence -- not *null* and not *undefined*. This is
# similar to `.nil?` in Ruby, and avoids having to consult a JavaScript truth
# table.
exports.Existence = class Existence extends Base
  constructor: (@expression) ->

  children: ['expression']

  invert: NEGATE

  compileNode: (o) ->
    @expression.front = @front
    code = @expression.compile o, LEVEL_OP
    if IDENTIFIER.test(code) and not o.scope.check code
      [cmp, cnj] = if @negated then ['===', '||'] else ['!==', '&&']
      code = "typeof #{code} #{cmp} \"undefined\" #{cnj} #{code} #{cmp} null"
    else
      # do not use strict equality here; it will break existing code
      code = "#{code} #{if @negated then '==' else '!='} null"
    [@makeCode(if o.level <= LEVEL_COND then code else "(#{code})")]

#### Parens

# An extra set of parentheses, specified explicitly in the source. At one time
# we tried to clean up the results by detecting and removing redundant
# parentheses, but no longer -- you can put in as many as you please.
#
# Parentheses are a good way to force any statement to become an expression.
exports.Parens = class Parens extends Base
  constructor: (@body) ->

  children: ['body']

  unwrap    : -> @body
  isComplex : -> @body.isComplex()

  compileNode: (o) ->
    expr = @body.unwrap()
    if expr instanceof Value and expr.isAtomic()
      expr.front = @front
      return expr.compileToFragments o
    fragments = expr.compileToFragments o, LEVEL_PAREN
    bare = o.level < LEVEL_OP and (expr instanceof Op or expr instanceof Call or
      (expr instanceof For and expr.returns))
    if bare then fragments else @wrapInBraces fragments

#### For

# CoffeeScript's replacement for the *for* loop is our array and object
# comprehensions, that compile into *for* loops here. They also act as an
# expression, able to return the result of each filtered iteration.
#
# Unlike Python array comprehensions, they can be multi-line, and you can pass
# the current index of the loop as a second parameter. Unlike Ruby blocks,
# you can map and filter in a single pass.
exports.For = class For extends While
  constructor: (body, source) ->
    {@source, @guard, @step, @name, @index} = source
    @body    = Block.wrap [body]
    @own     = !!source.own
    @object  = !!source.object
    [@name, @index] = [@index, @name] if @object
    @index.error 'index cannot be a pattern matching expression' if @index instanceof Value
    @range   = @source instanceof Value and @source.base instanceof Range and not @source.properties.length
    @pattern = @name instanceof Value
    @index.error 'indexes do not apply to range loops' if @range and @index
    @name.error 'cannot pattern match over range loops' if @range and @pattern
    @index.error 'cannot use own with for-in' if @own and not @object
    @returns = false

  children: ['body', 'source', 'guard', 'step']

  # Welcome to the hairiest method in all of CoffeeScript. Handles the inner
  # loop, filtering, stepping, and result saving for array, object, and range
  # comprehensions. Some of the generated code can be shared in common, and
  # some cannot.
  compileNode: (o) ->
    body      = Block.wrap [@body]
    lastJumps = last(body.expressions)?.jumps()
    @returns  = no if lastJumps and lastJumps instanceof Return
    source    = if @range then @source.base else @source
    scope     = o.scope
    name      = @name  and (@name.compile o, LEVEL_LIST)
    index     = @index and (@index.compile o, LEVEL_LIST)
    scope.find(name)  if name and not @pattern
    scope.find(index) if index
    rvar      = scope.freeVariable 'results' if @returns
    ivar      = (@object and index) or scope.freeVariable 'i'
    kvar      = (@range and name) or index or ivar
    kvarAssign = if kvar isnt ivar then "#{kvar} = " else ""
    if @step and not @range
      [step, stepVar] = @cacheToCodeFragments @step.cache o, LEVEL_LIST
      stepNum = stepVar.match SIMPLENUM
    name      = ivar if @pattern
    varPart   = ''
    guardPart = ''
    defPart   = ''
    idt1      = @tab + TAB
    if @range
      forPartFragments = source.compileToFragments merge(o, {index: ivar, name, @step})
    else
      svar    = @source.compile o, LEVEL_LIST
      if (name or @own) and not IDENTIFIER.test svar
        defPart    += "#{@tab}#{ref = scope.freeVariable 'ref'} = #{svar};\n"
        svar       = ref
      if name and not @pattern
        namePart   = "#{name} = #{svar}[#{kvar}]"
      if not @object
        defPart += "#{@tab}#{step};\n" if step isnt stepVar
        lvar = scope.freeVariable 'len' unless @step and stepNum and down = (+stepNum < 0)
        declare = "#{kvarAssign}#{ivar} = 0, #{lvar} = #{svar}.length"
        declareDown = "#{kvarAssign}#{ivar} = #{svar}.length - 1"
        compare = "#{ivar} < #{lvar}"
        compareDown = "#{ivar} >= 0"
        if @step
          if stepNum
            if down
              compare = compareDown
              declare = declareDown
          else
            compare = "#{stepVar} > 0 ? #{compare} : #{compareDown}"
            declare = "(#{stepVar} > 0 ? (#{declare}) : #{declareDown})"
          increment = "#{ivar} += #{stepVar}"
        else
          increment = "#{if kvar isnt ivar then "++#{ivar}" else "#{ivar}++"}"
        forPartFragments  = [@makeCode("#{declare}; #{compare}; #{kvarAssign}#{increment}")]
    if @returns
      resultPart   = "#{@tab}#{rvar} = [];\n"
      returnResult = "\n#{@tab}return #{rvar};"
      body.makeReturn rvar
    if @guard
      if body.expressions.length > 1
        body.expressions.unshift new If (new Parens @guard).invert(), new Literal "continue"
      else
        body = Block.wrap [new If @guard, body] if @guard
    if @pattern
      body.expressions.unshift new Assign @name, new Literal "#{svar}[#{kvar}]"
    defPartFragments = [].concat @makeCode(defPart), @pluckDirectCall(o, body)
    varPart = "\n#{idt1}#{namePart};" if namePart
    if @object
      forPartFragments   = [@makeCode("#{kvar} in #{svar}")]
      guardPart = "\n#{idt1}if (!#{utility 'hasProp'}.call(#{svar}, #{kvar})) continue;" if @own
    bodyFragments = body.compileToFragments merge(o, indent: idt1), LEVEL_TOP
    if bodyFragments and (bodyFragments.length > 0)
      bodyFragments = [].concat @makeCode("\n"), bodyFragments, @makeCode("\n")
    [].concat defPartFragments, @makeCode("#{resultPart or ''}#{@tab}for ("),
      forPartFragments, @makeCode(") {#{guardPart}#{varPart}"), bodyFragments,
      @makeCode("#{@tab}}#{returnResult or ''}")

  pluckDirectCall: (o, body) ->
    defs = []
    for expr, idx in body.expressions
      expr = expr.unwrapAll()
      continue unless expr instanceof Call
      val = expr.variable.unwrapAll()
      continue unless (val instanceof Code) or
                      (val instanceof Value and
                      val.base?.unwrapAll() instanceof Code and
                      val.properties.length is 1 and
                      val.properties[0].name?.value in ['call', 'apply'])
      fn    = val.base?.unwrapAll() or val
      ref   = new Literal o.scope.freeVariable 'fn'
      base  = new Value ref
      if val.base
        [val.base, base] = [base, val]
      body.expressions[idx] = new Call base, expr.args
      defs = defs.concat @makeCode(@tab), (new Assign(ref, fn).compileToFragments(o, LEVEL_TOP)), @makeCode(';\n')
    defs

#### Switch

# A JavaScript *switch* statement. Converts into a returnable expression on-demand.
exports.Switch = class Switch extends Base
  constructor: (@subject, @cases, @otherwise) ->

  children: ['subject', 'cases', 'otherwise']

  isStatement: YES

  jumps: (o = {block: yes}) ->
    for [conds, block] in @cases
      return block if block.jumps o
    @otherwise?.jumps o

  makeReturn: (res) ->
    pair[1].makeReturn res for pair in @cases
    @otherwise or= new Block [new Literal 'void 0'] if res
    @otherwise?.makeReturn res
    this

  compileNode: (o) ->
    idt1 = o.indent + TAB
    idt2 = o.indent = idt1 + TAB
    fragments = [].concat @makeCode(@tab + "switch ("),
      (if @subject then @subject.compileToFragments(o, LEVEL_PAREN) else @makeCode "false"),
      @makeCode(") {\n")
    for [conditions, block], i in @cases
      for cond in flatten [conditions]
        cond  = cond.invert() unless @subject
        fragments = fragments.concat @makeCode(idt1 + "case "), cond.compileToFragments(o, LEVEL_PAREN), @makeCode(":\n")
      fragments = fragments.concat body, @makeCode('\n') if (body = block.compileToFragments o, LEVEL_TOP).length > 0
      break if i is @cases.length - 1 and not @otherwise
      expr = @lastNonComment block.expressions
      continue if expr instanceof Return or (expr instanceof Literal and expr.jumps() and expr.value isnt 'debugger')
      fragments.push cond.makeCode(idt2 + 'break;\n')
    if @otherwise and @otherwise.expressions.length
      fragments.push @makeCode(idt1 + "default:\n"), (@otherwise.compileToFragments o, LEVEL_TOP)..., @makeCode("\n")
    fragments.push @makeCode @tab + '}'
    fragments

#### If

# *If/else* statements. Acts as an expression by pushing down requested returns
# to the last line of each clause.
#
# Single-expression **Ifs** are compiled into conditional operators if possible,
# because ternaries are already proper expressions, and don't need conversion.
exports.If = class If extends Base
  constructor: (condition, @body, options = {}) ->
    @condition = if options.type is 'unless' then condition.invert() else condition
    @elseBody  = null
    @isChain   = false
    {@soak}    = options

  children: ['condition', 'body', 'elseBody']

  bodyNode:     -> @body?.unwrap()
  elseBodyNode: -> @elseBody?.unwrap()

  # Rewrite a chain of **Ifs** to add a default case as the final *else*.
  addElse: (elseBody) ->
    if @isChain
      @elseBodyNode().addElse elseBody
    else
      @isChain  = elseBody instanceof If
      @elseBody = @ensureBlock elseBody
      @elseBody.updateLocationDataIfMissing elseBody.locationData
    this

  # The **If** only compiles into a statement if either of its bodies needs
  # to be a statement. Otherwise a conditional operator is safe.
  isStatement: (o) ->
    o?.level is LEVEL_TOP or
      @bodyNode().isStatement(o) or @elseBodyNode()?.isStatement(o)

  jumps: (o) -> @body.jumps(o) or @elseBody?.jumps(o)

  compileNode: (o) ->
    if @isStatement o then @compileStatement o else @compileExpression o

  makeReturn: (res) ->
    @elseBody  or= new Block [new Literal 'void 0'] if res
    @body     and= new Block [@body.makeReturn res]
    @elseBody and= new Block [@elseBody.makeReturn res]
    this

  ensureBlock: (node) ->
    if node instanceof Block then node else new Block [node]

  # Compile the `If` as a regular *if-else* statement. Flattened chains
  # force inner *else* bodies into statement form.
  compileStatement: (o) ->
    child    = del o, 'chainChild'
    exeq     = del o, 'isExistentialEquals'

    if exeq
      return new If(@condition.invert(), @elseBodyNode(), type: 'if').compileToFragments o

    indent   = o.indent + TAB
    cond     = @condition.compileToFragments o, LEVEL_PAREN
    body     = @ensureBlock(@body).compileToFragments merge o, {indent}
    ifPart   = [].concat @makeCode("if ("), cond, @makeCode(") {\n"), body, @makeCode("\n#{@tab}}")
    ifPart.unshift @makeCode @tab unless child
    return ifPart unless @elseBody
    answer = ifPart.concat @makeCode(' else ')
    if @isChain
      o.chainChild = yes
      answer = answer.concat @elseBody.unwrap().compileToFragments o, LEVEL_TOP
    else
      answer = answer.concat @makeCode("{\n"), @elseBody.compileToFragments(merge(o, {indent}), LEVEL_TOP), @makeCode("\n#{@tab}}")
    answer

  # Compile the `If` as a conditional operator.
  compileExpression: (o) ->
    cond = @condition.compileToFragments o, LEVEL_COND
    body = @bodyNode().compileToFragments o, LEVEL_LIST
    alt  = if @elseBodyNode() then @elseBodyNode().compileToFragments(o, LEVEL_LIST) else [@makeCode('void 0')]
    fragments = cond.concat @makeCode(" ? "), body, @makeCode(" : "), alt
    if o.level >= LEVEL_COND then @wrapInBraces fragments else fragments

  unfoldSoak: ->
    @soak and this

# Faux-Nodes
# ----------
# Faux-nodes are never created by the grammar, but are used during code
# generation to generate other combinations of nodes.

#### Closure

# A faux-node used to wrap an expressions body in a closure.
Closure =

  # Wrap the expressions body, unless it contains a pure statement,
  # in which case, no dice. If the body mentions `this` or `arguments`,
  # then make sure that the closure wrapper preserves the original values.
  wrap: (expressions, statement, noReturn) ->
    return expressions if expressions.jumps()
    func = new Code [], Block.wrap [expressions]
    args = []
    argumentsNode = expressions.contains @isLiteralArguments
    if argumentsNode and expressions.classBody
      argumentsNode.error "Class bodies shouldn't reference arguments"
    if argumentsNode or expressions.contains @isLiteralThis
      meth = new Literal if argumentsNode then 'apply' else 'call'
      args = [new Literal 'this']
      args.push new Literal 'arguments' if argumentsNode
      func = new Value func, [new Access meth]
    func.noReturn = noReturn
    call = new Call func, args
    if statement then Block.wrap [call] else call

  isLiteralArguments: (node) ->
    node instanceof Literal and node.value is 'arguments' and not node.asKey

  isLiteralThis: (node) ->
    (node instanceof Literal and node.value is 'this' and not node.asKey) or
      (node instanceof Code and node.bound) or
      (node instanceof Call and node.isSuper)

# Unfold a node's child if soak, then tuck the node under created `If`
unfoldSoak = (o, parent, name) ->
  return unless ifn = parent[name].unfoldSoak o
  parent[name] = ifn.body
  ifn.body = new Value parent
  ifn

# Constants
# ---------

UTILITIES =

  # Correctly set up a prototype chain for inheritance, including a reference
  # to the superclass for `super()` calls, and copies of any static properties.
  extends: -> """
    function(child, parent) { for (var key in parent) { if (#{utility 'hasProp'}.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; }
  """

  # Create a function bound to the current value of "this".
  bind: -> '''
    function(fn, me){ return function(){ return fn.apply(me, arguments); }; }
  '''

  # Discover if an item is in an array.
  indexOf: -> """
    [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; }
  """

  # Shortcuts to speed up the lookup time for native functions.
  hasProp: -> '{}.hasOwnProperty'
  slice  : -> '[].slice'

# Levels indicate a node's position in the AST. Useful for knowing if
# parens are necessary or superfluous.
LEVEL_TOP    = 1  # ...;
LEVEL_PAREN  = 2  # (...)
LEVEL_LIST   = 3  # [...]
LEVEL_COND   = 4  # ... ? x : y
LEVEL_OP     = 5  # !...
LEVEL_ACCESS = 6  # ...[0]

# Tabs are two spaces for pretty printing.
TAB = '  '

IDENTIFIER_STR = "[$A-Za-z_\\x7f-\\uffff][$\\w\\x7f-\\uffff]*"
IDENTIFIER = /// ^ #{IDENTIFIER_STR} $ ///
SIMPLENUM  = /^[+-]?\d+$/
METHOD_DEF = ///
  ^
    (?:
      (#{IDENTIFIER_STR})
      \.prototype
      (?:
        \.(#{IDENTIFIER_STR})
      | \[("(?:[^\\"\r\n]|\\.)*"|'(?:[^\\'\r\n]|\\.)*')\]
      | \[(0x[\da-fA-F]+ | \d*\.?\d+ (?:[eE][+-]?\d+)?)\]
      )
    )
  |
    (#{IDENTIFIER_STR})
  $
///

# Is a literal value a string?
IS_STRING = /^['"]/

# Utility Functions
# -----------------

# Helper for ensuring that utility functions are assigned at the top level.
utility = (name) ->
  ref = "__#{name}"
  Scope.root.assign ref, UTILITIES[name]()
  ref

multident = (code, tab) ->
  code = code.replace /\n/g, '$&' + tab
  code.replace /\s+$/, ''
