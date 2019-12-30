# `nodes.coffee` contains all of the node classes for the syntax tree. Most
# nodes are created as the result of actions in the [grammar](grammar.html),
# but some are created by other nodes as a method of code generation. To convert
# the syntax tree into a string of JavaScript code, call `compile()` on the root.

Error.stackTraceLimit = Infinity

{Scope} = require './scope'
{isUnassignable, JS_FORBIDDEN} = require './lexer'

# Import the helpers we plan to use.
{compact, flatten, extend, merge, del, starts, ends, some,
addDataToNode, attachCommentsToNode, locationDataToString,
throwSyntaxError, replaceUnicodeCodePointEscapes,
isFunction, isPlainObject, isNumber, parseNumber} = require './helpers'

# Functions required by parser.
exports.extend = extend
exports.addDataToNode = addDataToNode

# Constant functions for nodes that don’t need customization.
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
    @type = parent?.constructor?.name or 'unknown'
    @locationData = parent?.locationData
    @comments = parent?.comments

  toString: ->
    # This is only intended for debugging.
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

  # Occasionally a node is compiled multiple times, for example to get the name
  # of a variable to add to scope tracking. When we know that a “premature”
  # compilation won’t result in comments being output, set those comments aside
  # so that they’re preserved for a later `compile` call that will result in
  # the comments being included in the output.
  compileWithoutComments: (o, lvl, method = 'compile') ->
    if @comments
      @ignoreTheseCommentsTemporarily = @comments
      delete @comments
    unwrapped = @unwrapAll()
    if unwrapped.comments
      unwrapped.ignoreTheseCommentsTemporarily = unwrapped.comments
      delete unwrapped.comments

    fragments = @[method] o, lvl

    if @ignoreTheseCommentsTemporarily
      @comments = @ignoreTheseCommentsTemporarily
      delete @ignoreTheseCommentsTemporarily
    if unwrapped.ignoreTheseCommentsTemporarily
      unwrapped.comments = unwrapped.ignoreTheseCommentsTemporarily
      delete unwrapped.ignoreTheseCommentsTemporarily

    fragments

  compileNodeWithoutComments: (o, lvl) ->
    @compileWithoutComments o, lvl, 'compileNode'

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

    fragments = if o.level is LEVEL_TOP or not node.isStatement(o)
      node.compileNode o
    else
      node.compileClosure o
    @compileCommentFragments o, node, fragments
    fragments

  compileToFragmentsWithoutComments: (o, lvl) ->
    @compileWithoutComments o, lvl, 'compileToFragments'

  # Statements converted into expressions via closure-wrapping share a scope
  # object with their parent closure, to preserve the expected lexical scope.
  compileClosure: (o) ->
    @checkForPureStatementInExpression()
    o.sharedScope = yes
    func = new Code [], Block.wrap [this]
    args = []
    if @contains ((node) -> node instanceof SuperCall)
      func.bound = yes
    else if (argumentsNode = @contains isLiteralArguments) or @contains isLiteralThis
      args = [new ThisLiteral]
      if argumentsNode
        meth = 'apply'
        args.push new IdentifierLiteral 'arguments'
      else
        meth = 'call'
      func = new Value func, [new Access new PropertyName meth]
    parts = (new Call func, args).compileNode o

    switch
      when func.isGenerator or func.base?.isGenerator
        parts.unshift @makeCode "(yield* "
        parts.push    @makeCode ")"
      when func.isAsync or func.base?.isAsync
        parts.unshift @makeCode "(await "
        parts.push    @makeCode ")"
    parts

  compileCommentFragments: (o, node, fragments) ->
    return fragments unless node.comments
    # This is where comments, that are attached to nodes as a `comments`
    # property, become `CodeFragment`s. “Inline block comments,” e.g.
    # `/* */`-delimited comments that are interspersed within code on a line,
    # are added to the current `fragments` stream. All other fragments are
    # attached as properties to the nearest preceding or following fragment,
    # to remain stowaways until they get properly output in `compileComments`
    # later on.
    unshiftCommentFragment = (commentFragment) ->
      if commentFragment.unshift
        # Find the first non-comment fragment and insert `commentFragment`
        # before it.
        unshiftAfterComments fragments, commentFragment
      else
        if fragments.length isnt 0
          precedingFragment = fragments[fragments.length - 1]
          if commentFragment.newLine and precedingFragment.code isnt '' and
             not /\n\s*$/.test precedingFragment.code
            commentFragment.code = "\n#{commentFragment.code}"
        fragments.push commentFragment

    for comment in node.comments when comment not in @compiledComments
      @compiledComments.push comment # Don’t output this comment twice.
      # For block/here comments, denoted by `###`, that are inline comments
      # like `1 + ### comment ### 2`, create fragments and insert them into
      # the fragments array.
      # Otherwise attach comment fragments to their closest fragment for now,
      # so they can be inserted into the output later after all the newlines
      # have been added.
      if comment.here # Block comment, delimited by `###`.
        commentFragment = new HereComment(comment).compileNode o
      else # Line comment, delimited by `#`.
        commentFragment = new LineComment(comment).compileNode o
      if (commentFragment.isHereComment and not commentFragment.newLine) or
         node.includeCommentFragments()
        # Inline block comments, like `1 + /* comment */ 2`, or a node whose
        # `compileToFragments` method has logic for outputting comments.
        unshiftCommentFragment commentFragment
      else
        fragments.push @makeCode '' if fragments.length is 0
        if commentFragment.unshift
          fragments[0].precedingComments ?= []
          fragments[0].precedingComments.push commentFragment
        else
          fragments[fragments.length - 1].followingComments ?= []
          fragments[fragments.length - 1].followingComments.push commentFragment
    fragments

  # If the code generation wishes to use the result of a complex expression
  # in multiple places, ensure that the expression is only ever evaluated once,
  # by assigning it to a temporary variable. Pass a level to precompile.
  #
  # If `level` is passed, then returns `[val, ref]`, where `val` is the compiled value, and `ref`
  # is the compiled reference. If `level` is not passed, this returns `[val, ref]` where
  # the two values are raw nodes which have not been compiled.
  cache: (o, level, shouldCache) ->
    complex = if shouldCache? then shouldCache this else @shouldCache()
    if complex
      ref = new IdentifierLiteral o.scope.freeVariable 'ref'
      sub = new Assign ref, this
      if level then [sub.compileToFragments(o, level), [@makeCode(ref.value)]] else [sub, ref]
    else
      ref = if level then @compileToFragments o, level else this
      [ref, ref]

  # Occasionally it may be useful to make an expression behave as if it was 'hoisted', whereby the
  # result of the expression is available before its location in the source, but the expression's
  # variable scope corresponds to the source position. This is used extensively to deal with executable
  # class bodies in classes.
  #
  # Calling this method mutates the node, proxying the `compileNode` and `compileToFragments`
  # methods to store their result for later replacing the `target` node, which is returned by the
  # call.
  hoist: ->
    @hoisted = yes
    target   = new HoistTarget @

    compileNode        = @compileNode
    compileToFragments = @compileToFragments

    @compileNode = (o) ->
      target.update compileNode, o

    @compileToFragments = (o) ->
      target.update compileToFragments, o

    target

  cacheToCodeFragments: (cacheValues) ->
    [fragmentsToText(cacheValues[0]), fragmentsToText(cacheValues[1])]

  # Construct a node that returns the current node’s result.
  # Note that this is overridden for smarter behavior for
  # many statement nodes (e.g. `If`, `For`).
  makeReturn: (results, mark) ->
    if mark
      # Mark this node as implicitly returned, so that it can be part of the
      # node metadata returned in the AST.
      @canBeReturned = yes
      return
    node = @unwrapAll()
    if results
      new Call new Literal("#{results}.push"), [node]
    else
      new Return node

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

  # Pull out the last node of a node list.
  lastNode: (list) ->
    if list.length is 0 then null else list[list.length - 1]

  # Debugging representation of the node, for inspecting the parse tree.
  # This is what `coffee --nodes` prints out.
  toString: (idt = '', name = @constructor.name) ->
    tree = '\n' + idt + name
    tree += '?' if @soak
    @eachChild (node) -> tree += node.toString idt + TAB
    tree

  checkForPureStatementInExpression: ->
    if jumpNode = @jumps()
      jumpNode.error 'cannot use a pure statement in an expression'

  # Plain JavaScript object representation of the node, that can be serialized
  # as JSON. This is what the `ast` option in the Node API returns.
  # We try to follow the [Babel AST spec](https://github.com/babel/babel/blob/master/packages/babel-parser/ast/spec.md)
  # as closely as possible, for improved interoperability with other tools.
  # **WARNING: DO NOT OVERRIDE THIS METHOD IN CHILD CLASSES.**
  # Only override the component `ast*` methods as needed.
  ast: (o, level) ->
    # Merge `level` into `o` and perform other universal checks.
    o = @astInitialize o, level
    # Create serializable representation of this node.
    astNode = @astNode o
    # Mark AST nodes that correspond to expressions that (implicitly) return.
    # We can’t do this as part of `astNode` because we need to assemble child
    # nodes first before marking the parent being returned.
    if @astNode? and @canBeReturned
      Object.assign astNode, {returns: yes}
    astNode

  astInitialize: (o, level) ->
    o = Object.assign {}, o
    o.level = level if level?
    if o.level > LEVEL_TOP
      @checkForPureStatementInExpression()
    # `@makeReturn` must be called before `astProperties`, because the latter may call
    # `.ast()` for child nodes and those nodes would need the return logic from `makeReturn`
    # already executed by then.
    @makeReturn null, yes if @isStatement(o) and o.level isnt LEVEL_TOP and o.scope?
    o

  astNode: (o) ->
    # Every abstract syntax tree node object has four categories of properties:
    # - type, stored in the `type` field and a string like `NumberLiteral`.
    # - location data, stored in the `loc`, `start`, `end` and `range` fields.
    # - properties specific to this node, like `parsedValue`.
    # - properties that are themselves child nodes, like `body`.
    # These fields are all intermixed in the Babel spec; `type` and `start` and
    # `parsedValue` are all top level fields in the AST node object. We have
    # separate methods for returning each category, that we merge together here.
    Object.assign {}, {type: @astType(o)}, @astProperties(o), @astLocationData()

  # By default, a node class has no specific properties.
  astProperties: -> {}

  # By default, a node class’s AST `type` is its class name.
  astType: -> @constructor.name

  # The AST location data is a rearranged version of our Jison location data,
  # mutated into the structure that the Babel spec uses.
  astLocationData: ->
    jisonLocationDataToAstLocationData @locationData

  # Determines whether an AST node needs an `ExpressionStatement` wrapper.
  # Typically matches our `isStatement()` logic but this allows overriding.
  isStatementAst: (o) ->
    @isStatement o

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

  # `replaceInContext` will traverse children looking for a node for which `match` returns
  # true. Once found, the matching node will be replaced by the result of calling `replacement`.
  replaceInContext: (match, replacement) ->
    return false unless @children
    for attr in @children when children = @[attr]
      if Array.isArray children
        for child, i in children
          if match child
            children[i..i] = replacement child, @
            return true
          else
            return true if child.replaceInContext match, replacement
      else if match children
        @[attr] = replacement children, @
        return true
      else
        return true if children.replaceInContext match, replacement

  invert: ->
    new Op '!', this

  unwrapAll: ->
    node = this
    continue until node is node = node.unwrap()
    node

  # Default implementations of the common node properties and methods. Nodes
  # will override these with custom logic, if needed.

  # `children` are the properties to recurse into when tree walking. The
  # `children` list *is* the structure of the AST. The `parent` pointer, and
  # the pointer to the `children` are how you can traverse the tree.
  children: []

  # `isStatement` has to do with “everything is an expression”. A few things
  # can’t be expressions, such as `break`. Things that `isStatement` returns
  # `true` for are things that can’t be used as expressions. There are some
  # error messages that come from `nodes.coffee` due to statements ending up
  # in expression position.
  isStatement: NO

  # Track comments that have been compiled into fragments, to avoid outputting
  # them twice.
  compiledComments: []

  # `includeCommentFragments` lets `compileCommentFragments` know whether this node
  # has special awareness of how to handle comments within its output.
  includeCommentFragments: NO

  # `jumps` tells you if an expression, or an internal part of an expression
  # has a flow control construct (like `break`, or `continue`, or `return`,
  # or `throw`) that jumps out of the normal flow of control and can’t be
  # used as a value. This is important because things like this make no sense;
  # we have to disallow them.
  jumps: NO

  # If `node.shouldCache() is false`, it is safe to use `node` more than once.
  # Otherwise you need to store the value of `node` in a variable and output
  # that variable several times instead. Kind of like this: `5` need not be
  # cached. `returnFive()`, however, could have side effects as a result of
  # evaluating it more than once, and therefore we need to cache it. The
  # parameter is named `shouldCache` rather than `mustCache` because there are
  # also cases where we might not need to cache but where we want to, for
  # example a long expression that may well be idempotent but we want to cache
  # for brevity.
  shouldCache: YES

  isChainable: NO
  isAssignable: NO
  isNumber: NO

  unwrap: THIS
  unfoldSoak: NO

  # Is this node used to assign a certain variable?
  assigns: NO

  # For this node and all descendents, set the location data to `locationData`
  # if the location data is not already set.
  updateLocationDataIfMissing: (locationData, force) ->
    @forceUpdateLocation = yes if force
    return this if @locationData and not @forceUpdateLocation
    delete @forceUpdateLocation
    @locationData = locationData

    @eachChild (child) ->
      child.updateLocationDataIfMissing locationData

  # Add location data from another node
  withLocationDataFrom: ({locationData}) ->
    @updateLocationDataIfMissing locationData

  # Add location data and comments from another node
  withLocationDataAndCommentsFrom: (node) ->
    @withLocationDataFrom node
    {comments} = node
    @comments = comments if comments?.length
    this

  # Throw a SyntaxError associated with this node’s location.
  error: (message) ->
    throwSyntaxError message, @locationData

  makeCode: (code) ->
    new CodeFragment this, code

  wrapInParentheses: (fragments) ->
    [@makeCode('('), fragments..., @makeCode(')')]

  wrapInBraces: (fragments) ->
    [@makeCode('{'), fragments..., @makeCode('}')]

  # `fragmentsList` is an array of arrays of fragments. Each array in fragmentsList will be
  # concatenated together, with `joinStr` added in between each, to produce a final flat array
  # of fragments.
  joinFragmentArrays: (fragmentsList, joinStr) ->
    answer = []
    for fragments, i in fragmentsList
      if i then answer.push @makeCode joinStr
      answer = answer.concat fragments
    answer

#### HoistTarget

# A **HoistTargetNode** represents the output location in the node tree for a hoisted node.
# See Base#hoist.
exports.HoistTarget = class HoistTarget extends Base
  # Expands hoisted fragments in the given array
  @expand = (fragments) ->
    for fragment, i in fragments by -1 when fragment.fragments
      fragments[i..i] = @expand fragment.fragments
    fragments

  constructor: (@source) ->
    super()

    # Holds presentational options to apply when the source node is compiled.
    @options = {}

    # Placeholder fragments to be replaced by the source node’s compilation.
    @targetFragments = { fragments: [] }

  isStatement: (o) ->
    @source.isStatement o

  # Update the target fragments with the result of compiling the source.
  # Calls the given compile function with the node and options (overriden with the target
  # presentational options).
  update: (compile, o) ->
    @targetFragments.fragments = compile.call @source, merge o, @options

  # Copies the target indent and level, and returns the placeholder fragments
  compileToFragments: (o, level) ->
    @options.indent = o.indent
    @options.level  = level ? o.level
    [ @targetFragments ]

  compileNode: (o) ->
    @compileToFragments o

  compileClosure: (o) ->
    @compileToFragments o

#### Root

# The root node of the node tree
exports.Root = class Root extends Base
  constructor: (@body) ->
    super()

  children: ['body']

  # Wrap everything in a safety closure, unless requested not to. It would be
  # better not to generate them in the first place, but for now, clean up
  # obvious double-parentheses.
  compileNode: (o) ->
    o.indent    = if o.bare then '' else TAB
    o.level     = LEVEL_TOP
    o.compiling = yes
    @initializeScope o
    fragments = @body.compileRoot o
    return fragments if o.bare
    [].concat @makeCode("(function() {\n"), fragments, @makeCode("\n}).call(this);\n")

  initializeScope: (o) ->
    o.scope = new Scope null, @body, null, o.referencedVars ? []
    # Mark given local variables in the root scope as parameters so they don’t
    # end up being declared on the root block.
    o.scope.parameter name for name in o.locals or []

  commentsAst: ->
    @allComments ?=
      for commentToken in (@allCommentTokens ? []) when not commentToken.heregex
        if commentToken.here
          new HereComment commentToken
        else
          new LineComment commentToken
    comment.ast() for comment in @allComments

  astNode: (o) ->
    o.level = LEVEL_TOP
    @initializeScope o
    super o

  astType: -> 'File'

  astProperties: (o) ->
    @body.isRootBlock = yes
    return
      program: Object.assign @body.ast(o), @astLocationData()
      comments: @commentsAst()

#### Block

# The block is the list of expressions that forms the body of an
# indented block of code -- the implementation of a function, a clause in an
# `if`, `switch`, or `try`, and so on...
exports.Block = class Block extends Base
  constructor: (nodes) ->
    super()

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
      return jumpNode if jumpNode = exp.jumps o

  # A Block node does not return its entire body, rather it
  # ensures that the final expression is returned.
  makeReturn: (results, mark) ->
    len = @expressions.length
    [..., lastExp] = @expressions
    lastExp = lastExp?.unwrap() or no
    # We also need to check that we’re not returning a JSX tag if there’s an
    # adjacent one at the same level; JSX doesn’t allow that.
    if lastExp and lastExp instanceof Parens and lastExp.body.expressions.length > 1
      {body:{expressions}} = lastExp
      [..., penult, last] = expressions
      penult = penult.unwrap()
      last = last.unwrap()
      if penult instanceof JSXElement and last instanceof JSXElement
        expressions[expressions.length - 1].error 'Adjacent JSX elements must be wrapped in an enclosing tag'
    if mark
      @expressions[len - 1]?.makeReturn results, mark
      return
    while len--
      expr = @expressions[len]
      @expressions[len] = expr.makeReturn results
      @expressions.splice(len, 1) if expr instanceof Return and not expr.expression
      break
    this

  compile: (o, lvl) ->
    return new Root(this).withLocationDataFrom(this).compile o, lvl unless o.scope

    super o, lvl

  # Compile all expressions within the **Block** body. If we need to return
  # the result, and it’s an expression, simply return it. If it’s a statement,
  # ask the statement to do so.
  compileNode: (o) ->
    @tab  = o.indent
    top   = o.level is LEVEL_TOP
    compiledNodes = []

    for node, index in @expressions
      if node.hoisted
        # This is a hoisted expression.
        # We want to compile this and ignore the result.
        node.compileToFragments o
        continue
      node = (node.unfoldSoak(o) or node)
      if node instanceof Block
        # This is a nested block. We don’t do anything special here like
        # enclose it in a new scope; we just compile the statements in this
        # block along with our own.
        compiledNodes.push node.compileNode o
      else if top
        node.front = yes
        fragments = node.compileToFragments o
        unless node.isStatement o
          fragments = indentInitial fragments, @
          [..., lastFragment] = fragments
          unless lastFragment.code is '' or lastFragment.isComment
            fragments.push @makeCode ';'
        compiledNodes.push fragments
      else
        compiledNodes.push node.compileToFragments o, LEVEL_LIST
    if top
      if @spaced
        return [].concat @joinFragmentArrays(compiledNodes, '\n\n'), @makeCode('\n')
      else
        return @joinFragmentArrays(compiledNodes, '\n')
    if compiledNodes.length
      answer = @joinFragmentArrays(compiledNodes, ', ')
    else
      answer = [@makeCode 'void 0']
    if compiledNodes.length > 1 and o.level >= LEVEL_LIST then @wrapInParentheses answer else answer

  compileRoot: (o) ->
    @spaced = yes
    fragments = @compileWithDeclarations o
    HoistTarget.expand fragments
    @compileComments fragments

  # Compile the expressions body for the contents of a function, with
  # declarations of all inner variables pushed up to the top.
  compileWithDeclarations: (o) ->
    fragments = []
    post = []
    for exp, i in @expressions
      exp = exp.unwrap()
      break unless exp instanceof Literal
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
          declaredVariables = scope.declaredVariables()
          for declaredVariable, declaredVariablesIndex in declaredVariables
            fragments.push @makeCode declaredVariable
            if Object::hasOwnProperty.call o.scope.comments, declaredVariable
              fragments.push o.scope.comments[declaredVariable]...
            if declaredVariablesIndex isnt declaredVariables.length - 1
              fragments.push @makeCode ', '
        if assigns
          fragments.push @makeCode ",\n#{@tab + TAB}" if declars
          fragments.push @makeCode scope.assignedVariables().join(",\n#{@tab + TAB}")
        fragments.push @makeCode ";\n#{if @spaced then '\n' else ''}"
      else if fragments.length and post.length
        fragments.push @makeCode "\n"
    fragments.concat post

  compileComments: (fragments) ->
    for fragment, fragmentIndex in fragments
      # Insert comments into the output at the next or previous newline.
      # If there are no newlines at which to place comments, create them.
      if fragment.precedingComments
        # Determine the indentation level of the fragment that we are about
        # to insert comments before, and use that indentation level for our
        # inserted comments. At this point, the fragments’ `code` property
        # is the generated output JavaScript, and CoffeeScript always
        # generates output indented by two spaces; so all we need to do is
        # search for a `code` property that begins with at least two spaces.
        fragmentIndent = ''
        for pastFragment in fragments[0...(fragmentIndex + 1)] by -1
          indent = /^ {2,}/m.exec pastFragment.code
          if indent
            fragmentIndent = indent[0]
            break
          else if '\n' in pastFragment.code
            break
        code = "\n#{fragmentIndent}" + (
            for commentFragment in fragment.precedingComments
              if commentFragment.isHereComment and commentFragment.multiline
                multident commentFragment.code, fragmentIndent, no
              else
                commentFragment.code
          ).join("\n#{fragmentIndent}").replace /^(\s*)$/gm, ''
        for pastFragment, pastFragmentIndex in fragments[0...(fragmentIndex + 1)] by -1
          newLineIndex = pastFragment.code.lastIndexOf '\n'
          if newLineIndex is -1
            # Keep searching previous fragments until we can’t go back any
            # further, either because there are no fragments left or we’ve
            # discovered that we’re in a code block that is interpolated
            # inside a string.
            if pastFragmentIndex is 0
              pastFragment.code = '\n' + pastFragment.code
              newLineIndex = 0
            else if pastFragment.isStringWithInterpolations and pastFragment.code is '{'
              code = code[1..] + '\n' # Move newline to end.
              newLineIndex = 1
            else
              continue
          delete fragment.precedingComments
          pastFragment.code = pastFragment.code[0...newLineIndex] +
            code + pastFragment.code[newLineIndex..]
          break

      # Yes, this is awfully similar to the previous `if` block, but if you
      # look closely you’ll find lots of tiny differences that make this
      # confusing if it were abstracted into a function that both blocks share.
      if fragment.followingComments
        # Does the first trailing comment follow at the end of a line of code,
        # like `; // Comment`, or does it start a new line after a line of code?
        trail = fragment.followingComments[0].trail
        fragmentIndent = ''
        # Find the indent of the next line of code, if we have any non-trailing
        # comments to output. We need to first find the next newline, as these
        # comments will be output after that; and then the indent of the line
        # that follows the next newline.
        unless trail and fragment.followingComments.length is 1
          onNextLine = no
          for upcomingFragment in fragments[fragmentIndex...]
            unless onNextLine
              if '\n' in upcomingFragment.code
                onNextLine = yes
              else
                continue
            else
              indent = /^ {2,}/m.exec upcomingFragment.code
              if indent
                fragmentIndent = indent[0]
                break
              else if '\n' in upcomingFragment.code
                break
        # Is this comment following the indent inserted by bare mode?
        # If so, there’s no need to indent this further.
        code = if fragmentIndex is 1 and /^\s+$/.test fragments[0].code
          ''
        else if trail
          ' '
        else
          "\n#{fragmentIndent}"
        # Assemble properly indented comments.
        code += (
            for commentFragment in fragment.followingComments
              if commentFragment.isHereComment and commentFragment.multiline
                multident commentFragment.code, fragmentIndent, no
              else
                commentFragment.code
          ).join("\n#{fragmentIndent}").replace /^(\s*)$/gm, ''
        for upcomingFragment, upcomingFragmentIndex in fragments[fragmentIndex...]
          newLineIndex = upcomingFragment.code.indexOf '\n'
          if newLineIndex is -1
            # Keep searching upcoming fragments until we can’t go any
            # further, either because there are no fragments left or we’ve
            # discovered that we’re in a code block that is interpolated
            # inside a string.
            if upcomingFragmentIndex is fragments.length - 1
              upcomingFragment.code = upcomingFragment.code + '\n'
              newLineIndex = upcomingFragment.code.length
            else if upcomingFragment.isStringWithInterpolations and upcomingFragment.code is '}'
              code = "#{code}\n"
              newLineIndex = 0
            else
              continue
          delete fragment.followingComments
          # Avoid inserting extra blank lines.
          code = code.replace /^\n/, '' if upcomingFragment.code is '\n'
          upcomingFragment.code = upcomingFragment.code[0...newLineIndex] +
            code + upcomingFragment.code[newLineIndex..]
          break

    fragments

  # Wrap up the given nodes as a **Block**, unless it already happens
  # to be one.
  @wrap: (nodes) ->
    return nodes[0] if nodes.length is 1 and nodes[0] instanceof Block
    new Block nodes

  astNode: (o) ->
    if (o.level? and o.level isnt LEVEL_TOP) and @expressions.length
      return (new Sequence(@expressions).withLocationDataFrom @).ast o

    super o

  astType: ->
    if @isRootBlock
      'Program'
    else if @isClassBody
      'ClassBody'
    else
      'BlockStatement'

  astProperties: (o) ->
    checkForDirectives = del o, 'checkForDirectives'

    sniffDirectives @expressions, notFinalExpression: checkForDirectives if @isRootBlock or checkForDirectives
    directives = []
    body = []
    for expression in @expressions
      expressionAst = expression.ast o
      # Ignore generated PassthroughLiteral
      if not expressionAst?
        continue
      else if expression instanceof Directive
        directives.push expressionAst
      # If an expression is a statement, it can be added to the body as is.
      else if expression.isStatementAst o
        body.push expressionAst
      # Otherwise, we need to wrap it in an `ExpressionStatement` AST node.
      else
        body.push Object.assign
            type: 'ExpressionStatement'
            expression: expressionAst
          ,
            expression.astLocationData()

    return {
      # For now, we’re not including `sourceType` on the `Program` AST node.
      # Its value could be either `'script'` or `'module'`, and there’s no way
      # for CoffeeScript to always know which it should be. The presence of an
      # `import` or `export` statement in source code would imply that it should
      # be a `module`, but a project may consist of mostly such files and also
      # an outlier file that lacks `import` or `export` but is still imported
      # into the project and therefore expects to be treated as a `module`.
      # Determining the value of `sourceType` is essentially the same challenge
      # posed by determining the parse goal of a JavaScript file, also `module`
      # or `script`, and so if Node figures out a way to do so for `.js` files
      # then CoffeeScript can copy Node’s algorithm.

      # sourceType: 'module'
      body, directives
    }

  astLocationData: ->
    return if @isRootBlock and not @locationData?
    super()

# A directive e.g. 'use strict'.
# Currently only used during AST generation.
exports.Directive = class Directive extends Base
  constructor: (@value) ->
    super()

  astProperties: (o) ->
    return
      value: Object.assign {},
        @value.ast o
        type: 'DirectiveLiteral'

#### Literal

# `Literal` is a base class for static values that can be passed through
# directly into JavaScript without translation, such as: strings, numbers,
# `true`, `false`, `null`...
exports.Literal = class Literal extends Base
  constructor: (@value) ->
    super()

  shouldCache: NO

  assigns: (name) ->
    name is @value

  compileNode: (o) ->
    [@makeCode @value]

  astProperties: ->
    return
      value: @value

  toString: ->
    # This is only intended for debugging.
    " #{if @isStatement() then super() else @constructor.name}: #{@value}"

exports.NumberLiteral = class NumberLiteral extends Literal
  constructor: (@value, {@parsedValue} = {}) ->
    super()
    unless @parsedValue?
      if isNumber @value
        @parsedValue = @value
        @value = "#{@value}"
      else
        @parsedValue = parseNumber @value

  isBigInt: ->
    /n$/.test @value

  astType: ->
    if @isBigInt()
      'BigIntLiteral'
    else
      'NumericLiteral'

  astProperties: ->
    return
      value:
        if @isBigInt()
          @parsedValue.toString()
        else
          @parsedValue
      extra:
        rawValue:
          if @isBigInt()
            @parsedValue.toString()
          else
            @parsedValue
        raw: @value

exports.InfinityLiteral = class InfinityLiteral extends NumberLiteral
  constructor: (@value, {@originalValue = 'Infinity'} = {}) ->
    super()

  compileNode: ->
    [@makeCode '2e308']

  astNode: (o) ->
    unless @originalValue is 'Infinity'
      return new NumberLiteral(@value).withLocationDataFrom(@).ast o
    super o

  astType: -> 'Identifier'

  astProperties: ->
    return
      name: 'Infinity'
      declaration: no

exports.NaNLiteral = class NaNLiteral extends NumberLiteral
  constructor: ->
    super 'NaN'

  compileNode: (o) ->
    code = [@makeCode '0/0']
    if o.level >= LEVEL_OP then @wrapInParentheses code else code

  astType: -> 'Identifier'

  astProperties: ->
    return
      name: 'NaN'
      declaration: no

exports.StringLiteral = class StringLiteral extends Literal
  constructor: (@originalValue, {@quote, @initialChunk, @finalChunk, @indent, @double, @heregex} = {}) ->
    super ''
    @quote = null if @quote is '///'
    @fromSourceString = @quote?
    @quote ?= '"'
    heredoc = @isFromHeredoc()

    val = @originalValue
    if @heregex
      val = val.replace HEREGEX_OMIT, '$1$2'
      val = replaceUnicodeCodePointEscapes val, flags: @heregex.flags
    else
      val = val.replace STRING_OMIT, '$1'
      val =
        unless @fromSourceString
          val
        else if heredoc
          indentRegex = /// \n#{@indent} ///g if @indent

          val = val.replace indentRegex, '\n' if indentRegex
          val = val.replace LEADING_BLANK_LINE,  '' if @initialChunk
          val = val.replace TRAILING_BLANK_LINE, '' if @finalChunk
          val
        else
          val.replace SIMPLE_STRING_OMIT, (match, offset) =>
            if (@initialChunk and offset is 0) or
               (@finalChunk and offset + match.length is val.length)
              ''
            else
              ' '
    @delimiter = @quote.charAt 0
    @value = makeDelimitedLiteral val, {
      @delimiter
      @double
    }

    @unquotedValueForTemplateLiteral = makeDelimitedLiteral val, {
      delimiter: '`'
      @double
      escapeNewlines: no
      includeDelimiters: no
      convertTrailingNullEscapes: yes
    }

    @unquotedValueForJSX = makeDelimitedLiteral val, {
      @double
      escapeNewlines: no
      includeDelimiters: no
      escapeDelimiter: no
    }

  compileNode: (o) ->
    return StringWithInterpolations.fromStringLiteral(@).compileNode o if @shouldGenerateTemplateLiteral()
    return [@makeCode @unquotedValueForJSX] if @jsx
    super o

  # `StringLiteral`s can represent either entire literal strings
  # or pieces of text inside of e.g. an interpolated string.
  # When parsed as the former but needing to be treated as the latter
  # (e.g. the string part of a tagged template literal), this will return
  # a copy of the `StringLiteral` with the quotes trimmed from its location
  # data (like it would have if parsed as part of an interpolated string).
  withoutQuotesInLocationData: ->
    endsWithNewline = @originalValue[-1..] is '\n'
    locationData = Object.assign {}, @locationData
    locationData.first_column          += @quote.length
    if endsWithNewline
      locationData.last_line -= 1
      locationData.last_column =
        if locationData.last_line is locationData.first_line
          locationData.first_column + @originalValue.length - '\n'.length
        else
          @originalValue[...-1].length - '\n'.length - @originalValue[...-1].lastIndexOf('\n')
    else
      locationData.last_column         -= @quote.length
    locationData.last_column_exclusive -= @quote.length
    locationData.range = [
      locationData.range[0] + @quote.length
      locationData.range[1] - @quote.length
    ]
    copy = new StringLiteral @originalValue, {@quote, @initialChunk, @finalChunk, @indent, @double, @heregex}
    copy.locationData = locationData
    copy

  isFromHeredoc: ->
    @quote.length is 3

  shouldGenerateTemplateLiteral: ->
    @isFromHeredoc()

  astNode: (o) ->
    return StringWithInterpolations.fromStringLiteral(@).ast o if @shouldGenerateTemplateLiteral()
    super o

  astProperties: ->
    return
      value: @originalValue
      extra:
        raw: "#{@delimiter}#{@originalValue}#{@delimiter}"

exports.RegexLiteral = class RegexLiteral extends Literal
  constructor: (value, {@delimiter = '/', @heregexCommentTokens = []} = {}) ->
    super ''
    heregex = @delimiter is '///'
    endDelimiterIndex = value.lastIndexOf '/'
    @flags = value[endDelimiterIndex + 1..]
    val = @originalValue = value[1...endDelimiterIndex]
    val = val.replace HEREGEX_OMIT, '$1$2' if heregex
    val = replaceUnicodeCodePointEscapes val, {@flags}
    @value = "#{makeDelimitedLiteral val, delimiter: '/'}#{@flags}"

  REGEX_REGEX: /// ^ / (.*) / \w* $ ///

  astType: -> 'RegExpLiteral'

  astProperties: (o) ->
    [, pattern] = @REGEX_REGEX.exec @value
    return {
      value: undefined
      pattern, @flags, @delimiter
      originalPattern: @originalValue
      extra:
        raw: @value
        originalRaw: "#{@delimiter}#{@originalValue}#{@delimiter}#{@flags}"
        rawValue: undefined
      comments:
        for heregexCommentToken in @heregexCommentTokens
          if heregexCommentToken.here
            new HereComment(heregexCommentToken).ast o
          else
            new LineComment(heregexCommentToken).ast o
    }

exports.PassthroughLiteral = class PassthroughLiteral extends Literal
  constructor: (@originalValue, {@here, @generated} = {}) ->
    super ''
    @value = @originalValue.replace /\\+(`|$)/g, (string) ->
      # `string` is always a value like '\`', '\\\`', '\\\\\`', etc.
      # By reducing it to its latter half, we turn '\`' to '`', '\\\`' to '\`', etc.
      string[-Math.ceil(string.length / 2)..]

  astNode: (o) ->
    return null if @generated
    super o

  astProperties: ->
    return {
      value: @originalValue
      here: !!@here
    }

exports.IdentifierLiteral = class IdentifierLiteral extends Literal
  isAssignable: YES

  eachName: (iterator) ->
    iterator @

  astType: ->
    if @jsx
      'JSXIdentifier'
    else
      'Identifier'

  astProperties: ->
    return
      name: @value
      declaration: !!@isDeclaration

exports.PropertyName = class PropertyName extends Literal
  isAssignable: YES

  astType: ->
    if @jsx
      'JSXIdentifier'
    else
      'Identifier'

  astProperties: ->
    return
      name: @value
      declaration: no

exports.ComputedPropertyName = class ComputedPropertyName extends PropertyName
  compileNode: (o) ->
    [@makeCode('['), @value.compileToFragments(o, LEVEL_LIST)..., @makeCode(']')]

  astNode: (o) ->
    @value.ast o

exports.StatementLiteral = class StatementLiteral extends Literal
  isStatement: YES

  makeReturn: THIS

  jumps: (o) ->
    return this if @value is 'break' and not (o?.loop or o?.block)
    return this if @value is 'continue' and not o?.loop

  compileNode: (o) ->
    [@makeCode "#{@tab}#{@value};"]

  astType: ->
    switch @value
      when 'continue' then 'ContinueStatement'
      when 'break'    then 'BreakStatement'
      when 'debugger' then 'DebuggerStatement'

exports.ThisLiteral = class ThisLiteral extends Literal
  constructor: (value) ->
    super 'this'
    @shorthand = value is '@'

  compileNode: (o) ->
    code = if o.scope.method?.bound then o.scope.method.context else @value
    [@makeCode code]

  astType: -> 'ThisExpression'

  astProperties: ->
    return
      shorthand: @shorthand

exports.UndefinedLiteral = class UndefinedLiteral extends Literal
  constructor: ->
    super 'undefined'

  compileNode: (o) ->
    [@makeCode if o.level >= LEVEL_ACCESS then '(void 0)' else 'void 0']

  astType: -> 'Identifier'

  astProperties: ->
    return
      name: @value
      declaration: no

exports.NullLiteral = class NullLiteral extends Literal
  constructor: ->
    super 'null'

exports.BooleanLiteral = class BooleanLiteral extends Literal
  constructor: (value, {@originalValue} = {}) ->
    super value
    @originalValue ?= @value

  astProperties: ->
    value: if @value is 'true' then yes else no
    name: @originalValue

exports.DefaultLiteral = class DefaultLiteral extends Literal
  astType: -> 'Identifier'

  astProperties: ->
    return
      name: 'default'
      declaration: no

#### Return

# A `return` is a *pureStatement*—wrapping it in a closure wouldn’t make sense.
exports.Return = class Return extends Base
  constructor: (@expression, {@belongsToFuncDirectiveReturn} = {}) ->
    super()

  children: ['expression']

  isStatement:     YES
  makeReturn:      THIS
  jumps:           THIS

  compileToFragments: (o, level) ->
    expr = @expression?.makeReturn()
    if expr and expr not instanceof Return then expr.compileToFragments o, level else super o, level

  compileNode: (o) ->
    answer = []
    # TODO: If we call `expression.compile()` here twice, we’ll sometimes
    # get back different results!
    if @expression
      answer = @expression.compileToFragments o, LEVEL_PAREN
      unshiftAfterComments answer, @makeCode "#{@tab}return "
      # Since the `return` got indented by `@tab`, preceding comments that are
      # multiline need to be indented.
      for fragment in answer
        if fragment.isHereComment and '\n' in fragment.code
          fragment.code = multident fragment.code, @tab
        else if fragment.isLineComment
          fragment.code = "#{@tab}#{fragment.code}"
        else
          break
    else
      answer.push @makeCode "#{@tab}return"
    answer.push @makeCode ';'
    answer

  checkForPureStatementInExpression: ->
    # don’t flag `return` from `await return`/`yield return` as invalid.
    return if @belongsToFuncDirectiveReturn
    super()

  astType: -> 'ReturnStatement'

  astProperties: (o) ->
    argument: @expression?.ast(o, LEVEL_PAREN) ? null

# Parent class for `YieldReturn`/`AwaitReturn`.
exports.FuncDirectiveReturn = class FuncDirectiveReturn extends Return
  constructor: (expression, {@returnKeyword}) ->
    super expression

  compileNode: (o) ->
    @checkScope o
    super o

  checkScope: (o) ->
    unless o.scope.parent?
      @error "#{@keyword} can only occur inside functions"

  isStatementAst: NO

  astNode: (o) ->
    @checkScope o

    new Op @keyword,
      new Return @expression, belongsToFuncDirectiveReturn: yes
      .withLocationDataFrom(
        if @expression?
          locationData: mergeLocationData @returnKeyword.locationData, @expression.locationData
        else
          @returnKeyword
      )
    .withLocationDataFrom @
    .ast o

# `yield return` works exactly like `return`, except that it turns the function
# into a generator.
exports.YieldReturn = class YieldReturn extends FuncDirectiveReturn
  keyword: 'yield'

exports.AwaitReturn = class AwaitReturn extends FuncDirectiveReturn
  keyword: 'await'

#### Value

# A value, variable or literal or parenthesized, indexed or dotted into,
# or vanilla.
exports.Value = class Value extends Base
  constructor: (base, props, tag, isDefaultValue = no) ->
    super()
    return base if not props and base instanceof Value
    @base           = base
    @properties     = props or []
    @tag            = tag
    @[tag]          = yes if tag
    @isDefaultValue = isDefaultValue
    # If this is a `@foo =` assignment, if there are comments on `@` move them
    # to be on `foo`.
    if @base?.comments and @base instanceof ThisLiteral and @properties[0]?.name?
      moveComments @base, @properties[0].name

  children: ['base', 'properties']

  # Add a property (or *properties* ) `Access` to the list.
  add: (props) ->
    @properties = @properties.concat props
    @forceUpdateLocation = yes
    this

  hasProperties: ->
    @properties.length isnt 0

  bareLiteral: (type) ->
    not @properties.length and @base instanceof type

  # Some boolean checks for the benefit of other nodes.
  isArray        : -> @bareLiteral(Arr)
  isRange        : -> @bareLiteral(Range)
  shouldCache    : -> @hasProperties() or @base.shouldCache()
  isAssignable   : (opts) -> @hasProperties() or @base.isAssignable opts
  isNumber       : -> @bareLiteral(NumberLiteral)
  isString       : -> @bareLiteral(StringLiteral)
  isRegex        : -> @bareLiteral(RegexLiteral)
  isUndefined    : -> @bareLiteral(UndefinedLiteral)
  isNull         : -> @bareLiteral(NullLiteral)
  isBoolean      : -> @bareLiteral(BooleanLiteral)
  isAtomic       : ->
    for node in @properties.concat @base
      return no if node.soak or node instanceof Call or node instanceof Op and node.operator is 'do'
    yes

  isNotCallable  : -> @isNumber() or @isString() or @isRegex() or
                      @isArray() or @isRange() or @isSplice() or @isObject() or
                      @isUndefined() or @isNull() or @isBoolean()

  isStatement : (o)    -> not @properties.length and @base.isStatement o
  isJSXTag    : -> @base instanceof JSXTag
  assigns     : (name) -> not @properties.length and @base.assigns name
  jumps       : (o)    -> not @properties.length and @base.jumps o

  isObject: (onlyGenerated) ->
    return no if @properties.length
    (@base instanceof Obj) and (not onlyGenerated or @base.generated)

  isElision: ->
    return no unless @base instanceof Arr
    @base.hasElision()

  isSplice: ->
    [..., lastProperty] = @properties
    lastProperty instanceof Slice

  looksStatic: (className) ->
    return no unless ((thisLiteral = @base) instanceof ThisLiteral or (name = @base).value is className) and
      @properties.length is 1 and @properties[0].name?.value isnt 'prototype'
    return
      staticClassName: thisLiteral ? name

  # The value can be unwrapped as its inner node, if there are no attached
  # properties.
  unwrap: ->
    if @properties.length then this else @base

  # A reference has base part (`this` value) and name part.
  # We cache them separately for compiling complex expressions.
  # `a()[b()] ?= c` -> `(_base = a())[_name = b()] ? _base[_name] = c`
  cacheReference: (o) ->
    [..., name] = @properties
    if @properties.length < 2 and not @base.shouldCache() and not name?.shouldCache()
      return [this, this]  # `a` `a.b`
    base = new Value @base, @properties[...-1]
    if base.shouldCache()  # `a().b`
      bref = new IdentifierLiteral o.scope.freeVariable 'base'
      base = new Value new Parens new Assign bref, base
    return [base, bref] unless name  # `a()`
    if name.shouldCache()  # `a[b()]`
      nref = new IdentifierLiteral o.scope.freeVariable 'name'
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
    if props.length and @base.cached?
      # Cached fragments enable correct order of the compilation,
      # and reuse of variables in the scope.
      # Example:
      # `a(x = 5).b(-> x = 6)` should compile in the same order as
      # `a(x = 5); b(-> x = 6)`
      # (see issue #4437, https://github.com/jashkenas/coffeescript/issues/4437)
      fragments = @base.cached
    else
      fragments = @base.compileToFragments o, (if props.length then LEVEL_ACCESS else null)
    if props.length and SIMPLENUM.test fragmentsToText fragments
      fragments.push @makeCode '.'
    for prop in props
      fragments.push (prop.compileToFragments o)...

    fragments

  # Unfold a soak into an `If`: `a?.b` -> `a.b if a?`
  unfoldSoak: (o) ->
    @unfoldedSoak ?= do =>
      ifn = @base.unfoldSoak o
      if ifn
        ifn.body.properties.push @properties...
        return ifn
      for prop, i in @properties when prop.soak
        prop.soak = off
        fst = new Value @base, @properties[...i]
        snd = new Value @base, @properties[i..]
        if fst.shouldCache()
          ref = new IdentifierLiteral o.scope.freeVariable 'ref'
          fst = new Parens new Assign ref, fst
          snd.base = ref
        return new If new Existence(fst), snd, soak: on
      no

  eachName: (iterator, {checkAssignability = yes} = {}) ->
    if @hasProperties()
      iterator @
    else if not checkAssignability or @base.isAssignable()
      @base.eachName iterator
    else
      @error 'tried to assign to unassignable value'

  # For AST generation, we need an `object` that’s this `Value` minus its last
  # property, if it has properties.
  object: ->
    return @ unless @hasProperties()
    # Get all properties except the last one; for a `Value` with only one
    # property, `initialProperties` is an empty array.
    initialProperties = @properties[0...@properties.length - 1]
    # Create the `object` that becomes the new “base” for the split-off final
    # property.
    object = new Value @base, initialProperties, @tag, @isDefaultValue
    # Add location data to our new node, so that it has correct location data
    # for source maps or later conversion into AST location data.
    object.locationData =
      if initialProperties.length is 0
        # This new `Value` has only one property, so the location data is just
        # that of the parent `Value`’s base.
        @base.locationData
      else
        # This new `Value` has multiple properties, so the location data spans
        # from the parent `Value`’s base to the last property that’s included
        # in this new node (a.k.a. the second-to-last property of the parent).
        mergeLocationData @base.locationData, initialProperties[initialProperties.length - 1].locationData
    object

  containsSoak: ->
    return no unless @hasProperties()

    for property in @properties when property.soak
      return yes

    return yes if @base instanceof Call and @base.soak

    no

  astNode: (o) ->
    # If the `Value` has no properties, the AST node is just whatever this
    # node’s `base` is.
    return @base.ast o unless @hasProperties()
    # Otherwise, call `Base::ast` which in turn calls the `astType` and
    # `astProperties` methods below.
    super o

  astType: ->
    if @isJSXTag()
      'JSXMemberExpression'
    else if @containsSoak()
      'OptionalMemberExpression'
    else
      'MemberExpression'

  # If this `Value` has properties, the *last* property (e.g. `c` in `a.b.c`)
  # becomes the `property`, and the preceding properties (e.g. `a.b`) become
  # a child `Value` node assigned to the `object` property.
  astProperties: (o) ->
    [..., property] = @properties
    property.name.jsx = yes if @isJSXTag()
    computed = property instanceof Index or property.name?.unwrap() not instanceof PropertyName
    return {
      object: @object().ast o, LEVEL_ACCESS
      property: property.ast o, (LEVEL_PAREN if computed)
      computed
      optional: !!property.soak
      shorthand: !!property.shorthand
    }

  astLocationData: ->
    return super() unless @isJSXTag()
    # don't include leading < of JSX tag in location data
    mergeAstLocationData(
      jisonLocationDataToAstLocationData(@base.tagNameLocationData),
      jisonLocationDataToAstLocationData(@properties[@properties.length - 1].locationData)
    )

exports.MetaProperty = class MetaProperty extends Base
  constructor: (@meta, @property) ->
    super()

  children: ['meta', 'property']

  checkValid: (o) ->
    if @meta.value is 'new'
      if @property instanceof Access and @property.name.value is 'target'
        unless o.scope.parent?
          @error "new.target can only occur inside functions"
      else
        @error "the only valid meta property for new is new.target"

  compileNode: (o) ->
    @checkValid o
    fragments = []
    fragments.push @meta.compileToFragments(o, LEVEL_ACCESS)...
    fragments.push @property.compileToFragments(o)...
    fragments

  astProperties: (o) ->
    @checkValid o

    return
      meta: @meta.ast o, LEVEL_ACCESS
      property: @property.ast o

#### HereComment

# Comment delimited by `###` (becoming `/* */`).
exports.HereComment = class HereComment extends Base
  constructor: ({ @content, @newLine, @unshift, @locationData }) ->
    super()

  compileNode: (o) ->
    multiline = '\n' in @content

    # Unindent multiline comments. They will be reindented later.
    if multiline
      indent = null
      for line in @content.split '\n'
        leadingWhitespace = /^\s*/.exec(line)[0]
        if not indent or leadingWhitespace.length < indent.length
          indent = leadingWhitespace
      @content = @content.replace /// \n #{indent} ///g, '\n' if indent

    hasLeadingMarks = /\n\s*[#|\*]/.test @content
    @content = @content.replace /^([ \t]*)#(?=\s)/gm, ' *' if hasLeadingMarks

    @content = "/*#{@content}#{if hasLeadingMarks then ' ' else ''}*/"
    fragment = @makeCode @content
    fragment.newLine = @newLine
    fragment.unshift = @unshift
    fragment.multiline = multiline
    # Don’t rely on `fragment.type`, which can break when the compiler is minified.
    fragment.isComment = fragment.isHereComment = yes
    fragment

  astType: -> 'CommentBlock'

  astProperties: ->
    return
      value: @content

#### LineComment

# Comment running from `#` to the end of a line (becoming `//`).
exports.LineComment = class LineComment extends Base
  constructor: ({ @content, @newLine, @unshift, @locationData, @precededByBlankLine }) ->
    super()

  compileNode: (o) ->
    fragment = @makeCode(if /^\s*$/.test @content then '' else "#{if @precededByBlankLine then "\n#{o.indent}" else ''}//#{@content}")
    fragment.newLine = @newLine
    fragment.unshift = @unshift
    fragment.trail = not @newLine and not @unshift
    # Don’t rely on `fragment.type`, which can break when the compiler is minified.
    fragment.isComment = fragment.isLineComment = yes
    fragment

  astType: -> 'CommentLine'

  astProperties: ->
    return
      value: @content

#### JSX

exports.JSXIdentifier = class JSXIdentifier extends IdentifierLiteral
  astType: -> 'JSXIdentifier'

exports.JSXTag = class JSXTag extends JSXIdentifier
  constructor: (value, {
    @tagNameLocationData
    @closingTagOpeningBracketLocationData
    @closingTagSlashLocationData
    @closingTagNameLocationData
    @closingTagClosingBracketLocationData
  }) ->
    super value

  astProperties: ->
    return
      name: @value

exports.JSXExpressionContainer = class JSXExpressionContainer extends Base
  constructor: (@expression, {locationData} = {}) ->
    super()
    @expression.jsxAttribute = yes
    @locationData = locationData ? @expression.locationData

  children: ['expression']

  compileNode: (o) ->
    @expression.compileNode(o)

  astProperties: (o) ->
    return
      expression: astAsBlockIfNeeded @expression, o

exports.JSXEmptyExpression = class JSXEmptyExpression extends Base

exports.JSXText = class JSXText extends Base
  constructor: (stringLiteral) ->
    super()
    @value = stringLiteral.unquotedValueForJSX
    @locationData = stringLiteral.locationData

  astProperties: ->
    return {
      @value
      extra:
        raw: @value
    }

exports.JSXAttribute = class JSXAttribute extends Base
  constructor: ({@name, value}) ->
    super()
    @value =
      if value?
        value = value.base
        if value instanceof StringLiteral
          value
        else
          new JSXExpressionContainer value
      else
        null
    @value?.comments = value.comments

  children: ['name', 'value']

  compileNode: (o) ->
    compiledName = @name.compileToFragments o, LEVEL_LIST
    return compiledName unless @value?
    val = @value.compileToFragments o, LEVEL_LIST
    compiledName.concat @makeCode('='), val

  astProperties: (o) ->
    name = @name
    if ':' in name.value
      name = new JSXNamespacedName name
    return
      name: name.ast o
      value: @value?.ast(o) ? null

exports.JSXAttributes = class JSXAttributes extends Base
  constructor: (arr) ->
    super()
    @attributes = []
    for object in arr.objects
      @checkValidAttribute object
      {base} = object
      if base instanceof IdentifierLiteral
        # attribute with no value eg disabled
        attribute = new JSXAttribute name: new JSXIdentifier(base.value).withLocationDataAndCommentsFrom base
        attribute.locationData = base.locationData
        @attributes.push attribute
      else if not base.generated
        # object spread attribute eg {...props}
        attribute = base.properties[0]
        attribute.jsx = yes
        attribute.locationData = base.locationData
        @attributes.push attribute
      else
        # Obj containing attributes with values eg a="b" c={d}
        for property in base.properties
          {variable, value} = property
          attribute = new JSXAttribute {
            name: new JSXIdentifier(variable.base.value).withLocationDataAndCommentsFrom variable.base
            value
          }
          attribute.locationData = property.locationData
          @attributes.push attribute
    @locationData = arr.locationData

  children: ['attributes']

  # Catch invalid attributes: <div {a:"b", props} {props} "value" />
  checkValidAttribute: (object) ->
    {base: attribute} = object
    properties = attribute?.properties or []
    if not (attribute instanceof Obj or attribute instanceof IdentifierLiteral) or (attribute instanceof Obj and not attribute.generated and (properties.length > 1 or not (properties[0] instanceof Splat)))
      object.error """
        Unexpected token. Allowed JSX attributes are: id="val", src={source}, {props...} or attribute.
      """

  compileNode: (o) ->
    fragments = []
    for attribute in @attributes
      fragments.push @makeCode ' '
      fragments.push attribute.compileToFragments(o, LEVEL_TOP)...
    fragments

  astNode: (o) ->
    attribute.ast(o) for attribute in @attributes

exports.JSXNamespacedName = class JSXNamespacedName extends Base
  constructor: (tag) ->
    super()
    [namespace, name] = tag.value.split ':'
    @namespace = new JSXIdentifier(namespace).withLocationDataFrom locationData: extractSameLineLocationDataFirst(namespace.length) tag.locationData
    @name      = new JSXIdentifier(name     ).withLocationDataFrom locationData: extractSameLineLocationDataLast(name.length      ) tag.locationData
    @locationData = tag.locationData

  children: ['namespace', 'name']

  astProperties: (o) ->
    return
      namespace: @namespace.ast o
      name: @name.ast o

# Node for a JSX element
exports.JSXElement = class JSXElement extends Base
  constructor: ({@tagName, @attributes, @content}) ->
    super()

  children: ['tagName', 'attributes', 'content']

  compileNode: (o) ->
    @content?.base.jsx = yes
    fragments = [@makeCode('<')]
    fragments.push (tag = @tagName.compileToFragments(o, LEVEL_ACCESS))...
    fragments.push @attributes.compileToFragments(o)...
    if @content
      fragments.push @makeCode('>')
      fragments.push @content.compileNode(o, LEVEL_LIST)...
      fragments.push [@makeCode('</'), tag..., @makeCode('>')]...
    else
      fragments.push @makeCode(' />')
    fragments

  isFragment: ->
    !@tagName.base.value.length

  astNode: (o) ->
    # The location data spanning the opening element < ... > is captured by
    # the generated Arr which contains the element's attributes
    @openingElementLocationData = jisonLocationDataToAstLocationData @attributes.locationData

    tagName = @tagName.base
    tagName.locationData = tagName.tagNameLocationData
    if @content?
      @closingElementLocationData = mergeAstLocationData(
        jisonLocationDataToAstLocationData tagName.closingTagOpeningBracketLocationData
        jisonLocationDataToAstLocationData tagName.closingTagClosingBracketLocationData
      )

    super o

  astType: ->
    if @isFragment()
      'JSXFragment'
    else
      'JSXElement'

  elementAstProperties: (o) ->
    tagNameAst = =>
      tag = @tagName.unwrap()
      if tag?.value and ':' in tag.value
        tag = new JSXNamespacedName tag
      tag.ast o

    openingElement = Object.assign {
      type: 'JSXOpeningElement'
      name: tagNameAst()
      selfClosing: not @closingElementLocationData?
      attributes: @attributes.ast o
    }, @openingElementLocationData

    closingElement = null
    if @closingElementLocationData?
      closingElement = Object.assign {
        type: 'JSXClosingElement'
        name: Object.assign(
          tagNameAst(),
          jisonLocationDataToAstLocationData @tagName.base.closingTagNameLocationData
        )
      }, @closingElementLocationData
      if closingElement.name.type in ['JSXMemberExpression', 'JSXNamespacedName']
        rangeDiff = closingElement.range[0] - openingElement.range[0] + '/'.length
        columnDiff = closingElement.loc.start.column - openingElement.loc.start.column + '/'.length
        shiftAstLocationData = (node) =>
          node.range = [
            node.range[0] + rangeDiff
            node.range[1] + rangeDiff
          ]
          node.start += rangeDiff
          node.end += rangeDiff
          node.loc.start =
            line: @closingElementLocationData.loc.start.line
            column: node.loc.start.column + columnDiff
          node.loc.end =
            line: @closingElementLocationData.loc.start.line
            column: node.loc.end.column + columnDiff
        if closingElement.name.type is 'JSXMemberExpression'
          currentExpr = closingElement.name
          while currentExpr.type is 'JSXMemberExpression'
            shiftAstLocationData currentExpr unless currentExpr is closingElement.name
            shiftAstLocationData currentExpr.property
            currentExpr = currentExpr.object
          shiftAstLocationData currentExpr
        else # JSXNamespacedName
          shiftAstLocationData closingElement.name.namespace
          shiftAstLocationData closingElement.name.name

    {openingElement, closingElement}

  fragmentAstProperties: (o) ->
    openingFragment = Object.assign {
      type: 'JSXOpeningFragment'
    }, @openingElementLocationData

    closingFragment = Object.assign {
      type: 'JSXClosingFragment'
    }, @closingElementLocationData

    {openingFragment, closingFragment}

  contentAst: (o) ->
    return [] unless @content and not @content.base.isEmpty?()

    content = @content.unwrapAll()
    children =
      if content instanceof StringLiteral
        [new JSXText content]
      else # StringWithInterpolations
        for element in @content.unwrapAll().extractElements o, includeInterpolationWrappers: yes, isJsx: yes
          if element instanceof StringLiteral
            new JSXText element
          else # Interpolation
            {expression} = element
            unless expression?
              emptyExpression = new JSXEmptyExpression()
              emptyExpression.locationData = emptyExpressionLocationData {
                interpolationNode: element
                openingBrace: '{'
                closingBrace: '}'
              }

              new JSXExpressionContainer emptyExpression, locationData: element.locationData
            else
              unwrapped = expression.unwrapAll()
              if unwrapped instanceof JSXElement and
                  # distinguish `<a><b /></a>` from `<a>{<b />}</a>`
                  unwrapped.locationData.range[0] is element.locationData.range[0]
                unwrapped
              else
                new JSXExpressionContainer unwrapped, locationData: element.locationData

    child.ast(o) for child in children when not (child instanceof JSXText and child.value.length is 0)

  astProperties: (o) ->
    Object.assign(
      if @isFragment()
        @fragmentAstProperties o
      else
        @elementAstProperties o
    ,
      children: @contentAst o
    )

  astLocationData: ->
    if @closingElementLocationData?
      mergeAstLocationData @openingElementLocationData, @closingElementLocationData
    else
      @openingElementLocationData

#### Call

# Node for a function invocation.
exports.Call = class Call extends Base
  constructor: (@variable, @args = [], @soak, @token) ->
    super()

    @implicit = @args.implicit
    @isNew = no
    if @variable instanceof Value and @variable.isNotCallable()
      @variable.error "literal is not a function"

    if @variable.base instanceof JSXTag
      return new JSXElement(
        tagName: @variable
        attributes: new JSXAttributes @args[0].base
        content: @args[1]
      )

    # `@variable` never gets output as a result of this node getting created as
    # part of `RegexWithInterpolations`, so for that case move any comments to
    # the `args` property that gets passed into `RegexWithInterpolations` via
    # the grammar.
    if @variable.base?.value is 'RegExp' and @args.length isnt 0
      moveComments @variable, @args[0]

  children: ['variable', 'args']

  # When setting the location, we sometimes need to update the start location to
  # account for a newly-discovered `new` operator to the left of us. This
  # expands the range on the left, but not the right.
  updateLocationDataIfMissing: (locationData) ->
    if @locationData and @needsUpdatedStartLocation
      @locationData = Object.assign {},
        @locationData,
        first_line: locationData.first_line
        first_column: locationData.first_column
        range: [
          locationData.range[0]
          @locationData.range[1]
        ]
      base = @variable?.base or @variable
      if base.needsUpdatedStartLocation
        @variable.locationData = Object.assign {},
          @variable.locationData,
          first_line: locationData.first_line
          first_column: locationData.first_column
          range: [
            locationData.range[0]
            @variable.locationData.range[1]
          ]
        base.updateLocationDataIfMissing locationData
      delete @needsUpdatedStartLocation
    super locationData

  # Tag this invocation as creating a new instance.
  newInstance: ->
    base = @variable?.base or @variable
    if base instanceof Call and not base.isNew
      base.newInstance()
    else
      @isNew = true
    @needsUpdatedStartLocation = true
    this

  # Soaked chained invocations unfold into if/else ternary structures.
  unfoldSoak: (o) ->
    if @soak
      if @variable instanceof Super
        left = new Literal @variable.compile o
        rite = new Value left
        @variable.error "Unsupported reference to 'super'" unless @variable.accessor?
      else
        return ifn if ifn = unfoldSoak o, this, 'variable'
        [left, rite] = new Value(@variable).cacheReference o
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
    @checkForNewSuper()
    @variable?.front = @front
    compiledArgs = []
    # If variable is `Accessor` fragments are cached and used later
    # in `Value::compileNode` to ensure correct order of the compilation,
    # and reuse of variables in the scope.
    # Example:
    # `a(x = 5).b(-> x = 6)` should compile in the same order as
    # `a(x = 5); b(-> x = 6)`
    # (see issue #4437, https://github.com/jashkenas/coffeescript/issues/4437)
    varAccess = @variable?.properties?[0] instanceof Access
    argCode = (arg for arg in (@args || []) when arg instanceof Code)
    if argCode.length > 0 and varAccess and not @variable.base.cached
      [cache] = @variable.base.cache o, LEVEL_ACCESS, -> no
      @variable.base.cached = cache

    for arg, argIndex in @args
      if argIndex then compiledArgs.push @makeCode ", "
      compiledArgs.push (arg.compileToFragments o, LEVEL_LIST)...

    fragments = []
    if @isNew
      fragments.push @makeCode 'new '
    fragments.push @variable.compileToFragments(o, LEVEL_ACCESS)...
    fragments.push @makeCode('('), compiledArgs..., @makeCode(')')
    fragments

  checkForNewSuper: ->
    if @isNew
      @variable.error "Unsupported reference to 'super'" if @variable instanceof Super

  containsSoak: ->
    return yes if @soak
    return yes if @variable?.containsSoak?()
    no

  astNode: (o) ->
    if @soak and @variable instanceof Super and o.scope.namedMethod()?.ctor
      @variable.error "Unsupported reference to 'super'"
    @checkForNewSuper()
    super o

  astType: ->
    if @isNew
      'NewExpression'
    else if @containsSoak()
      'OptionalCallExpression'
    else
      'CallExpression'

  astProperties: (o) ->
    return
      callee: @variable.ast o, LEVEL_ACCESS
      arguments: arg.ast(o, LEVEL_LIST) for arg in @args
      optional: !!@soak
      implicit: !!@implicit

#### Super

# Takes care of converting `super()` calls into calls against the prototype's
# function of the same name.
# When `expressions` are set the call will be compiled in such a way that the
# expressions are evaluated without altering the return value of the `SuperCall`
# expression.
exports.SuperCall = class SuperCall extends Call
  children: Call::children.concat ['expressions']

  isStatement: (o) ->
    @expressions?.length and o.level is LEVEL_TOP

  compileNode: (o) ->
    return super o unless @expressions?.length

    superCall   = new Literal fragmentsToText super o
    replacement = new Block @expressions.slice()

    if o.level > LEVEL_TOP
      # If we might be in an expression we need to cache and return the result
      [superCall, ref] = superCall.cache o, null, YES
      replacement.push ref

    replacement.unshift superCall
    replacement.compileToFragments o, if o.level is LEVEL_TOP then o.level else LEVEL_LIST

exports.Super = class Super extends Base
  constructor: (@accessor, @superLiteral) ->
    super()

  children: ['accessor']

  compileNode: (o) ->
    @checkInInstanceMethod o

    method = o.scope.namedMethod()
    unless method.ctor? or @accessor?
      {name, variable} = method
      if name.shouldCache() or (name instanceof Index and name.index.isAssignable())
        nref = new IdentifierLiteral o.scope.parent.freeVariable 'name'
        name.index = new Assign nref, name.index
      @accessor = if nref? then new Index nref else name

    if @accessor?.name?.comments
      # A `super()` call gets compiled to e.g. `super.method()`, which means
      # the `method` property name gets compiled for the first time here, and
      # again when the `method:` property of the class gets compiled. Since
      # this compilation happens first, comments attached to `method:` would
      # get incorrectly output near `super.method()`, when we want them to
      # get output on the second pass when `method:` is output. So set them
      # aside during this compilation pass, and put them back on the object so
      # that they’re there for the later compilation.
      salvagedComments = @accessor.name.comments
      delete @accessor.name.comments
    fragments = (new Value (new Literal 'super'), if @accessor then [ @accessor ] else [])
    .compileToFragments o
    attachCommentsToNode salvagedComments, @accessor.name if salvagedComments
    fragments

  checkInInstanceMethod: (o) ->
    method = o.scope.namedMethod()
    @error 'cannot use super outside of an instance method' unless method?.isMethod

  astNode: (o) ->
    @checkInInstanceMethod o

    if @accessor?
      return (
        new Value(
          new Super().withLocationDataFrom (@superLiteral ? @)
          [@accessor]
        ).withLocationDataFrom @
      ).ast o

    super o

#### RegexWithInterpolations

# Regexes with interpolations are in fact just a variation of a `Call` (a
# `RegExp()` call to be precise) with a `StringWithInterpolations` inside.
exports.RegexWithInterpolations = class RegexWithInterpolations extends Base
  constructor: (@call, {@heregexCommentTokens = []} = {}) ->
    super()

  children: ['call']

  compileNode: (o) ->
    @call.compileNode o

  astType: -> 'InterpolatedRegExpLiteral'

  astProperties: (o) ->
    interpolatedPattern: @call.args[0].ast o
    flags: @call.args[1]?.unwrap().originalValue ? ''
    comments:
      for heregexCommentToken in @heregexCommentTokens
        if heregexCommentToken.here
          new HereComment(heregexCommentToken).ast o
        else
          new LineComment(heregexCommentToken).ast o

#### TaggedTemplateCall

exports.TaggedTemplateCall = class TaggedTemplateCall extends Call
  constructor: (variable, arg, soak) ->
    arg = StringWithInterpolations.fromStringLiteral arg if arg instanceof StringLiteral
    super variable, [ arg ], soak

  compileNode: (o) ->
    @variable.compileToFragments(o, LEVEL_ACCESS).concat @args[0].compileToFragments(o, LEVEL_LIST)

  astType: -> 'TaggedTemplateExpression'

  astProperties: (o) ->
    return
      tag: @variable.ast o, LEVEL_ACCESS
      quasi: @args[0].ast o, LEVEL_LIST

#### Extends

# Node to extend an object's prototype with an ancestor object.
# After `goog.inherits` from the
# [Closure Library](https://github.com/google/closure-library/blob/master/closure/goog/base.js).
exports.Extends = class Extends extends Base
  constructor: (@child, @parent) ->
    super()

  children: ['child', 'parent']

  # Hooks one constructor into another's prototype chain.
  compileToFragments: (o) ->
    new Call(new Value(new Literal utility 'extend', o), [@child, @parent]).compileToFragments o

#### Access

# A `.` access into a property of a value, or the `::` shorthand for
# an access into the object's prototype.
exports.Access = class Access extends Base
  constructor: (@name, {@soak, @shorthand} = {}) ->
    super()

  children: ['name']

  compileToFragments: (o) ->
    name = @name.compileToFragments o
    node = @name.unwrap()
    if node instanceof PropertyName
      [@makeCode('.'), name...]
    else
      [@makeCode('['), name..., @makeCode(']')]

  shouldCache: NO

  astNode: (o) ->
    # Babel doesn’t have an AST node for `Access`, but rather just includes
    # this Access node’s child `name` Identifier node as the `property` of
    # the `MemberExpression` node.
    @name.ast o

#### Index

# A `[ ... ]` indexed access into an array or object.
exports.Index = class Index extends Base
  constructor: (@index) ->
    super()

  children: ['index']

  compileToFragments: (o) ->
    [].concat @makeCode("["), @index.compileToFragments(o, LEVEL_PAREN), @makeCode("]")

  shouldCache: ->
    @index.shouldCache()

  astNode: (o) ->
    # Babel doesn’t have an AST node for `Index`, but rather just includes
    # this Index node’s child `index` Identifier node as the `property` of
    # the `MemberExpression` node. The fact that the `MemberExpression`’s
    # `property` is an Index means that `computed` is `true` for the
    # `MemberExpression`.
    @index.ast o

#### Range

# A range literal. Ranges can be used to extract portions (slices) of arrays,
# to specify a range for comprehensions, or as a value, to be expanded into the
# corresponding array of integers at runtime.
exports.Range = class Range extends Base

  children: ['from', 'to']

  constructor: (@from, @to, tag) ->
    super()

    @exclusive = tag is 'exclusive'
    @equals = if @exclusive then '' else '='

  # Compiles the range's source variables -- where it starts and where it ends.
  # But only if they need to be cached to avoid double evaluation.
  compileVariables: (o) ->
    o = merge o, top: true
    shouldCache = del o, 'shouldCache'
    [@fromC, @fromVar] = @cacheToCodeFragments @from.cache o, LEVEL_LIST, shouldCache
    [@toC, @toVar]     = @cacheToCodeFragments @to.cache o, LEVEL_LIST, shouldCache
    [@step, @stepVar]  = @cacheToCodeFragments step.cache o, LEVEL_LIST, shouldCache if step = del o, 'step'
    @fromNum = if @from.isNumber() then parseNumber @fromVar else null
    @toNum   = if @to.isNumber()   then parseNumber @toVar   else null
    @stepNum = if step?.isNumber() then parseNumber @stepVar else null

  # When compiled normally, the range returns the contents of the *for loop*
  # needed to iterate over the values in the range. Used by comprehensions.
  compileNode: (o) ->
    @compileVariables o unless @fromVar
    return @compileArray(o) unless o.index

    # Set up endpoints.
    known    = @fromNum? and @toNum?
    idx      = del o, 'index'
    idxName  = del o, 'name'
    namedIndex = idxName and idxName isnt idx
    varPart  =
      if known and not namedIndex
        "var #{idx} = #{@fromC}"
      else
        "#{idx} = #{@fromC}"
    varPart += ", #{@toC}" if @toC isnt @toVar
    varPart += ", #{@step}" if @step isnt @stepVar
    [lt, gt] = ["#{idx} <#{@equals}", "#{idx} >#{@equals}"]

    # Generate the condition.
    [from, to] = [@fromNum, @toNum]
    # Always check if the `step` isn't zero to avoid the infinite loop.
    stepNotZero = "#{ @stepNum ? @stepVar } !== 0"
    stepCond = "#{ @stepNum ? @stepVar } > 0"
    lowerBound = "#{lt} #{ if known then to else @toVar }"
    upperBound = "#{gt} #{ if known then to else @toVar }"
    condPart =
      if @step?
        if @stepNum? and @stepNum isnt 0
          if @stepNum > 0 then "#{lowerBound}" else "#{upperBound}"
        else
          "#{stepNotZero} && (#{stepCond} ? #{lowerBound} : #{upperBound})"
      else
        if known
          "#{ if from <= to then lt else gt } #{to}"
        else
          "(#{@fromVar} <= #{@toVar} ? #{lowerBound} : #{upperBound})"

    cond = if @stepVar then "#{@stepVar} > 0" else "#{@fromVar} <= #{@toVar}"

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
    known = @fromNum? and @toNum?
    if known and Math.abs(@fromNum - @toNum) <= 20
      range = [@fromNum..@toNum]
      range.pop() if @exclusive
      return [@makeCode "[#{ range.join(', ') }]"]
    idt    = @tab + TAB
    i      = o.scope.freeVariable 'i', single: true, reserve: no
    result = o.scope.freeVariable 'results', reserve: no
    pre    = "\n#{idt}var #{result} = [];"
    if known
      o.index = i
      body    = fragmentsToText @compileNode o
    else
      vars    = "#{i} = #{@fromC}" + if @toC isnt @toVar then ", #{@toC}" else ''
      cond    = "#{@fromVar} <= #{@toVar}"
      body    = "var #{vars}; #{cond} ? #{i} <#{@equals} #{@toVar} : #{i} >#{@equals} #{@toVar}; #{cond} ? #{i}++ : #{i}--"
    post   = "{ #{result}.push(#{i}); }\n#{idt}return #{result};\n#{o.indent}"
    hasArgs = (node) -> node?.contains isLiteralArguments
    args   = ', arguments' if hasArgs(@from) or hasArgs(@to)
    [@makeCode "(function() {#{pre}\n#{idt}for (#{body})#{post}}).apply(this#{args ? ''})"]

  astProperties: (o) ->
    return {
      from: @from?.ast(o) ? null
      to: @to?.ast(o) ? null
      @exclusive
    }

#### Slice

# An array slice literal. Unlike JavaScript’s `Array#slice`, the second parameter
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
    # Handle an expression in the property access, e.g. `a[!b in c..]`.
    if from?.shouldCache()
      from = new Value new Parens from
    if to?.shouldCache()
      to = new Value new Parens to
    fromCompiled = from?.compileToFragments(o, LEVEL_PAREN) or [@makeCode '0']
    if to
      compiled     = to.compileToFragments o, LEVEL_PAREN
      compiledText = fragmentsToText compiled
      if not (not @range.exclusive and +compiledText is -1)
        toStr = ', ' + if @range.exclusive
          compiledText
        else if to.isNumber()
          "#{+compiledText + 1}"
        else
          compiled = to.compileToFragments o, LEVEL_ACCESS
          "+#{fragmentsToText compiled} + 1 || 9e9"
    [@makeCode ".slice(#{ fragmentsToText fromCompiled }#{ toStr or '' })"]

  astNode: (o) ->
    @range.ast o

#### Obj

# An object literal, nothing fancy.
exports.Obj = class Obj extends Base
  constructor: (props, @generated = no) ->
    super()

    @objects = @properties = props or []

  children: ['properties']

  isAssignable: (opts) ->
    for prop in @properties
      # Check for reserved words.
      message = isUnassignable prop.unwrapAll().value
      prop.error message if message

      prop = prop.value if prop instanceof Assign and
        prop.context is 'object' and
        prop.value?.base not instanceof Arr
      return no unless prop.isAssignable opts
    yes

  shouldCache: ->
    not @isAssignable()

  # Check if object contains splat.
  hasSplat: ->
    return yes for prop in @properties when prop instanceof Splat
    no

  # Move rest property to the end of the list.
  # `{a, rest..., b} = obj` -> `{a, b, rest...} = obj`
  # `foo = ({a, rest..., b}) ->` -> `foo = {a, b, rest...}) ->`
  reorderProperties: ->
    props = @properties
    splatProps = @getAndCheckSplatProps()
    splatProp = props.splice splatProps[0], 1
    @objects = @properties = [].concat props, splatProp

  compileNode: (o) ->
    @reorderProperties() if @hasSplat() and @lhs
    props = @properties
    if @generated
      for node in props when node instanceof Value
        node.error 'cannot have an implicit value in an implicit object'

    idt      = o.indent += TAB
    lastNode = @lastNode @properties

    # If this object is the left-hand side of an assignment, all its children
    # are too.
    @propagateLhs()

    isCompact = yes
    for prop in @properties
      if prop instanceof Assign and prop.context is 'object'
        isCompact = no

    answer = []
    answer.push @makeCode if isCompact then '' else '\n'
    for prop, i in props
      join = if i is props.length - 1
        ''
      else if isCompact
        ', '
      else if prop is lastNode
        '\n'
      else
        ',\n'
      indent = if isCompact then '' else idt

      key = if prop instanceof Assign and prop.context is 'object'
        prop.variable
      else if prop instanceof Assign
        prop.operatorToken.error "unexpected #{prop.operatorToken.value}" unless @lhs
        prop.variable
      else
        prop
      if key instanceof Value and key.hasProperties()
        key.error 'invalid object key' if prop.context is 'object' or not key.this
        key  = key.properties[0].name
        prop = new Assign key, prop, 'object'
      if key is prop
        if prop.shouldCache()
          [key, value] = prop.base.cache o
          key  = new PropertyName key.value if key instanceof IdentifierLiteral
          prop = new Assign key, value, 'object'
        else if key instanceof Value and key.base instanceof ComputedPropertyName
          # `{ [foo()] }` output as `{ [ref = foo()]: ref }`.
          if prop.base.value.shouldCache()
            [key, value] = prop.base.value.cache o
            key  = new ComputedPropertyName key.value if key instanceof IdentifierLiteral
            prop = new Assign key, value, 'object'
          else
            # `{ [expression] }` output as `{ [expression]: expression }`.
            prop = new Assign key, prop.base.value, 'object'
        else if not prop.bareLiteral?(IdentifierLiteral) and prop not instanceof Splat
          prop = new Assign prop, prop, 'object'
      if indent then answer.push @makeCode indent
      answer.push prop.compileToFragments(o, LEVEL_TOP)...
      if join then answer.push @makeCode join
    answer.push @makeCode if isCompact then '' else "\n#{@tab}"
    answer = @wrapInBraces answer
    if @front then @wrapInParentheses answer else answer

  getAndCheckSplatProps: ->
    return unless @hasSplat() and @lhs
    props = @properties
    splatProps = (i for prop, i in props when prop instanceof Splat)
    props[splatProps[1]].error "multiple spread elements are disallowed" if splatProps?.length > 1
    splatProps

  assigns: (name) ->
    for prop in @properties when prop.assigns name then return yes
    no

  eachName: (iterator) ->
    for prop in @properties
      prop = prop.value if prop instanceof Assign and prop.context is 'object'
      prop = prop.unwrapAll()
      prop.eachName iterator if prop.eachName?

  # Convert “bare” properties to `ObjectProperty`s (or `Splat`s).
  expandProperty: (property) ->
    {variable, context, operatorToken} = property
    key = if property instanceof Assign and context is 'object'
      variable
    else if property instanceof Assign
      operatorToken.error "unexpected #{operatorToken.value}" unless @lhs
      variable
    else
      property
    if key instanceof Value and key.hasProperties()
      key.error 'invalid object key' unless context isnt 'object' and key.this
      if property instanceof Assign
        return new ObjectProperty fromAssign: property
      else
        return new ObjectProperty key: property
    return new ObjectProperty(fromAssign: property) unless key is property
    return property if property instanceof Splat

    new ObjectProperty key: property

  expandProperties: ->
    @expandProperty(property) for property in @properties

  propagateLhs: (setLhs) ->
    @lhs = yes if setLhs
    return unless @lhs

    for property in @properties
      if property instanceof Assign and property.context is 'object'
        {value} = property
        unwrappedValue = value.unwrapAll()
        if unwrappedValue instanceof Arr or unwrappedValue instanceof Obj
          unwrappedValue.propagateLhs yes
        else if unwrappedValue instanceof Assign
          unwrappedValue.nestedLhs = yes
      else if property instanceof Assign
        # Shorthand property with default, e.g. `{a = 1} = b`.
        property.nestedLhs = yes
      else if property instanceof Splat
        property.propagateLhs yes

  astNode: (o) ->
    @getAndCheckSplatProps()
    super o

  astType: ->
    if @lhs
      'ObjectPattern'
    else
      'ObjectExpression'

  astProperties: (o) ->
    return
      implicit: !!@generated
      properties:
        property.ast(o) for property in @expandProperties()

exports.ObjectProperty = class ObjectProperty extends Base
  constructor: ({key, fromAssign}) ->
    super()
    if fromAssign
      {variable: @key, value, context} = fromAssign
      if context is 'object'
        # All non-shorthand properties (i.e. includes `:`).
        @value = value
      else
        # Left-hand-side shorthand with default e.g. `{a = 1} = b`.
        @value = fromAssign
        @shorthand = yes
      @locationData = fromAssign.locationData
    else
      # Shorthand without default e.g. `{a}` or `{@a}` or `{[a]}`.
      @key = key
      @shorthand = yes
      @locationData = key.locationData

  astProperties: (o) ->
    isComputedPropertyName = (@key instanceof Value and @key.base instanceof ComputedPropertyName) or @key.unwrap() instanceof StringWithInterpolations
    keyAst = @key.ast o, LEVEL_LIST

    return
      key:
        if keyAst?.declaration
          Object.assign {}, keyAst, declaration: no
        else
          keyAst
      value: @value?.ast(o, LEVEL_LIST) ? keyAst
      shorthand: !!@shorthand
      computed: !!isComputedPropertyName
      method: no

#### Arr

# An array literal.
exports.Arr = class Arr extends Base
  constructor: (objs, @lhs = no) ->
    super()
    @objects = objs or []
    @propagateLhs()

  children: ['objects']

  hasElision: ->
    return yes for obj in @objects when obj instanceof Elision
    no

  isAssignable: (opts) ->
    {allowExpansion, allowNontrailingSplat, allowEmptyArray = no} = opts ? {}
    return allowEmptyArray unless @objects.length

    for obj, i in @objects
      return no if not allowNontrailingSplat and obj instanceof Splat and i + 1 isnt @objects.length
      return no unless (allowExpansion and obj instanceof Expansion) or (obj.isAssignable(opts) and (not obj.isAtomic or obj.isAtomic()))
    yes

  shouldCache: ->
    not @isAssignable()

  compileNode: (o) ->
    return [@makeCode '[]'] unless @objects.length
    o.indent += TAB
    fragmentIsElision = ([ fragment ]) ->
      fragment.type is 'Elision' and fragment.code.trim() is ','
    # Detect if `Elision`s at the beginning of the array are processed (e.g. [, , , a]).
    passedElision = no

    answer = []
    for obj, objIndex in @objects
      unwrappedObj = obj.unwrapAll()
      # Let `compileCommentFragments` know to intersperse block comments
      # into the fragments created when compiling this array.
      if unwrappedObj.comments and
         unwrappedObj.comments.filter((comment) -> not comment.here).length is 0
        unwrappedObj.includeCommentFragments = YES

    compiledObjs = (obj.compileToFragments o, LEVEL_LIST for obj in @objects)
    olen = compiledObjs.length
    # If `compiledObjs` includes newlines, we will output this as a multiline
    # array (i.e. with a newline and indentation after the `[`). If an element
    # contains line comments, that should also trigger multiline output since
    # by definition line comments will introduce newlines into our output.
    # The exception is if only the first element has line comments; in that
    # case, output as the compact form if we otherwise would have, so that the
    # first element’s line comments get output before or after the array.
    includesLineCommentsOnNonFirstElement = no
    for fragments, index in compiledObjs
      for fragment in fragments
        if fragment.isHereComment
          fragment.code = fragment.code.trim()
        else if index isnt 0 and includesLineCommentsOnNonFirstElement is no and hasLineComments fragment
          includesLineCommentsOnNonFirstElement = yes
      # Add ', ' if all `Elisions` from the beginning of the array are processed (e.g. [, , , a]) and
      # element isn't `Elision` or last element is `Elision` (e.g. [a,,b,,])
      if index isnt 0 and passedElision and (not fragmentIsElision(fragments) or index is olen - 1)
        answer.push @makeCode ', '
      passedElision = passedElision or not fragmentIsElision fragments
      answer.push fragments...
    if includesLineCommentsOnNonFirstElement or '\n' in fragmentsToText(answer)
      for fragment, fragmentIndex in answer
        if fragment.isHereComment
          fragment.code = "#{multident(fragment.code, o.indent, no)}\n#{o.indent}"
        else if fragment.code is ', ' and not fragment?.isElision and fragment.type not in ['StringLiteral', 'StringWithInterpolations']
          fragment.code = ",\n#{o.indent}"
      answer.unshift @makeCode "[\n#{o.indent}"
      answer.push @makeCode "\n#{@tab}]"
    else
      for fragment in answer when fragment.isHereComment
        fragment.code = "#{fragment.code} "
      answer.unshift @makeCode '['
      answer.push @makeCode ']'
    answer

  assigns: (name) ->
    for obj in @objects when obj.assigns name then return yes
    no

  eachName: (iterator) ->
    for obj in @objects
      obj = obj.unwrapAll()
      obj.eachName iterator

  # If this array is the left-hand side of an assignment, all its children
  # are too.
  propagateLhs: (setLhs) ->
    @lhs = yes if setLhs
    return unless @lhs
    for object in @objects
      object.lhs = yes if object instanceof Splat or object instanceof Expansion
      unwrappedObject = object.unwrapAll()
      if unwrappedObject instanceof Arr or unwrappedObject instanceof Obj
        unwrappedObject.propagateLhs yes
      else if unwrappedObject instanceof Assign
        unwrappedObject.nestedLhs = yes

  astType: ->
    if @lhs
      'ArrayPattern'
    else
      'ArrayExpression'

  astProperties: (o) ->
    return
      elements:
        object.ast(o, LEVEL_LIST) for object in @objects

#### Class

# The CoffeeScript class definition.
# Initialize a **Class** with its name, an optional superclass, and a body.

exports.Class = class Class extends Base
  children: ['variable', 'parent', 'body']

  constructor: (@variable, @parent, @body) ->
    super()
    unless @body?
      @body = new Block
      @hasGeneratedBody = yes

  compileNode: (o) ->
    @name          = @determineName()
    executableBody = @walkBody o

    # Special handling to allow `class expr.A extends A` declarations
    parentName    = @parent.base.value if @parent instanceof Value and not @parent.hasProperties()
    @hasNameClash = @name? and @name is parentName

    node = @

    if executableBody or @hasNameClash
      node = new ExecutableClassBody node, executableBody
    else if not @name? and o.level is LEVEL_TOP
      # Anonymous classes are only valid in expressions
      node = new Parens node

    if @boundMethods.length and @parent
      @variable ?= new IdentifierLiteral o.scope.freeVariable '_class'
      [@variable, @variableRef] = @variable.cache o unless @variableRef?

    if @variable
      node = new Assign @variable, node, null, { @moduleDeclaration }

    @compileNode = @compileClassDeclaration
    try
      return node.compileToFragments o
    finally
      delete @compileNode

  compileClassDeclaration: (o) ->
    @ctor ?= @makeDefaultConstructor() if @externalCtor or @boundMethods.length
    @ctor?.noReturn = true

    @proxyBoundMethods() if @boundMethods.length

    o.indent += TAB

    result = []
    result.push @makeCode "class "
    result.push @makeCode @name if @name
    @compileCommentFragments o, @variable, result if @variable?.comments?
    result.push @makeCode ' ' if @name
    result.push @makeCode('extends '), @parent.compileToFragments(o)..., @makeCode ' ' if @parent

    result.push @makeCode '{'
    unless @body.isEmpty()
      @body.spaced = true
      result.push @makeCode '\n'
      result.push @body.compileToFragments(o, LEVEL_TOP)...
      result.push @makeCode "\n#{@tab}"
    result.push @makeCode '}'

    result

  # Figure out the appropriate name for this class
  determineName: ->
    return null unless @variable
    [..., tail] = @variable.properties
    node = if tail
      tail instanceof Access and tail.name
    else
      @variable.base
    unless node instanceof IdentifierLiteral or node instanceof PropertyName
      return null
    name = node.value
    unless tail
      message = isUnassignable name
      @variable.error message if message
    if name in JS_FORBIDDEN then "_#{name}" else name

  walkBody: (o) ->
    @ctor          = null
    @boundMethods  = []
    executableBody = null

    initializer     = []
    { expressions } = @body

    i = 0
    for expression in expressions.slice()
      if expression instanceof Value and expression.isObject true
        { properties } = expression.base
        exprs     = []
        end       = 0
        start     = 0
        pushSlice = -> exprs.push new Value new Obj properties[start...end], true if end > start

        while assign = properties[end]
          if initializerExpression = @addInitializerExpression assign, o
            pushSlice()
            exprs.push initializerExpression
            initializer.push initializerExpression
            start = end + 1
          end++
        pushSlice()

        expressions[i..i] = exprs
        i += exprs.length
      else
        if initializerExpression = @addInitializerExpression expression, o
          initializer.push initializerExpression
          expressions[i] = initializerExpression
        i += 1

    for method in initializer when method instanceof Code
      if method.ctor
        method.error 'Cannot define more than one constructor in a class' if @ctor
        @ctor = method
      else if method.isStatic and method.bound
        method.context = @name
      else if method.bound
        @boundMethods.push method

    return unless o.compiling
    if initializer.length isnt expressions.length
      @body.expressions = (expression.hoist() for expression in initializer)
      new Block expressions

  # Add an expression to the class initializer
  #
  # This is the key method for determining whether an expression in a class
  # body should appear in the initializer or the executable body. If the given
  # `node` is valid in a class body the method will return a (new, modified,
  # or identical) node for inclusion in the class initializer, otherwise
  # nothing will be returned and the node will appear in the executable body.
  #
  # At time of writing, only methods (instance and static) are valid in ES
  # class initializers. As new ES class features (such as class fields) reach
  # Stage 4, this method will need to be updated to support them. We
  # additionally allow `PassthroughLiteral`s (backticked expressions) in the
  # initializer as an escape hatch for ES features that are not implemented
  # (e.g. getters and setters defined via the `get` and `set` keywords as
  # opposed to the `Object.defineProperty` method).
  addInitializerExpression: (node, o) ->
    if node.unwrapAll() instanceof PassthroughLiteral
      node
    else if @validInitializerMethod node
      @addInitializerMethod node
    else if not o.compiling and @validClassProperty node
      @addClassProperty node
    else if not o.compiling and @validClassPrototypeProperty node
      @addClassPrototypeProperty node
    else
      null

  # Checks if the given node is a valid ES class initializer method.
  validInitializerMethod: (node) ->
    return no unless node instanceof Assign and node.value instanceof Code
    return yes if node.context is 'object' and not node.variable.hasProperties()
    return node.variable.looksStatic(@name) and (@name or not node.value.bound)

  # Returns a configured class initializer method
  addInitializerMethod: (assign) ->
    { variable, value: method, operatorToken } = assign
    method.isMethod = yes
    method.isStatic = variable.looksStatic @name

    if method.isStatic
      method.name = variable.properties[0]
    else
      methodName  = variable.base
      method.name = new (if methodName.shouldCache() then Index else Access) methodName
      method.name.updateLocationDataIfMissing methodName.locationData
      isConstructor =
        if methodName instanceof StringLiteral
          methodName.originalValue is 'constructor'
        else
          methodName.value is 'constructor'
      method.ctor = (if @parent then 'derived' else 'base') if isConstructor
      method.error 'Cannot define a constructor as a bound (fat arrow) function' if method.bound and method.ctor

    method.operatorToken = operatorToken
    method

  validClassProperty: (node) ->
    return no unless node instanceof Assign
    return node.variable.looksStatic @name

  addClassProperty: (assign) ->
    {variable, value, operatorToken} = assign
    {staticClassName} = variable.looksStatic @name
    new ClassProperty({
      name: variable.properties[0]
      isStatic: yes
      staticClassName
      value
      operatorToken
    }).withLocationDataFrom assign

  validClassPrototypeProperty: (node) ->
    return no unless node instanceof Assign
    node.context is 'object' and not node.variable.hasProperties()

  addClassPrototypeProperty: (assign) ->
    {variable, value} = assign
    new ClassPrototypeProperty({
      name: variable.base
      value
    }).withLocationDataFrom assign

  makeDefaultConstructor: ->
    ctor = @addInitializerMethod new Assign (new Value new PropertyName 'constructor'), new Code
    @body.unshift ctor

    if @parent
      ctor.body.push new SuperCall new Super, [new Splat new IdentifierLiteral 'arguments']

    if @externalCtor
      applyCtor = new Value @externalCtor, [ new Access new PropertyName 'apply' ]
      applyArgs = [ new ThisLiteral, new IdentifierLiteral 'arguments' ]
      ctor.body.push new Call applyCtor, applyArgs
      ctor.body.makeReturn()

    ctor

  proxyBoundMethods: ->
    @ctor.thisAssignments = for method in @boundMethods
      method.classVariable = @variableRef if @parent

      name = new Value(new ThisLiteral, [ method.name ])
      new Assign name, new Call(new Value(name, [new Access new PropertyName 'bind']), [new ThisLiteral])

    null

  declareName: (o) ->
    return unless (name = @variable?.unwrap()) instanceof IdentifierLiteral
    alreadyDeclared = o.scope.find name.value
    name.isDeclaration = not alreadyDeclared

  isStatementAst: -> yes

  astNode: (o) ->
    if jumpNode = @body.jumps()
      jumpNode.error 'Class bodies cannot contain pure statements'
    if argumentsNode = @body.contains isLiteralArguments
      argumentsNode.error "Class bodies shouldn't reference arguments"
    @declareName o
    @name = @determineName()
    @body.isClassBody = yes
    @body.locationData = zeroWidthLocationDataFromEndLocation @locationData if @hasGeneratedBody
    @walkBody o
    sniffDirectives @body.expressions
    @ctor?.noReturn = yes

    super o

  astType: (o) ->
    if o.level is LEVEL_TOP
      'ClassDeclaration'
    else
      'ClassExpression'

  astProperties: (o) ->
    return
      id: @variable?.ast(o) ? null
      superClass: @parent?.ast(o, LEVEL_PAREN) ? null
      body: @body.ast o, LEVEL_TOP

exports.ExecutableClassBody = class ExecutableClassBody extends Base
  children: [ 'class', 'body' ]

  defaultClassVariableName: '_Class'

  constructor: (@class, @body = new Block) ->
    super()

  compileNode: (o) ->
    if jumpNode = @body.jumps()
      jumpNode.error 'Class bodies cannot contain pure statements'
    if argumentsNode = @body.contains isLiteralArguments
      argumentsNode.error "Class bodies shouldn't reference arguments"

    params  = []
    args    = [new ThisLiteral]
    wrapper = new Code params, @body
    klass   = new Parens new Call (new Value wrapper, [new Access new PropertyName 'call']), args

    @body.spaced = true

    o.classScope = wrapper.makeScope o.scope

    @name      = @class.name ? o.classScope.freeVariable @defaultClassVariableName
    ident      = new IdentifierLiteral @name
    directives = @walkBody()
    @setContext()

    if @class.hasNameClash
      parent = new IdentifierLiteral o.classScope.freeVariable 'superClass'
      wrapper.params.push new Param parent
      args.push @class.parent
      @class.parent = parent

    if @externalCtor
      externalCtor = new IdentifierLiteral o.classScope.freeVariable 'ctor', reserve: no
      @class.externalCtor = externalCtor
      @externalCtor.variable.base = externalCtor

    if @name isnt @class.name
      @body.expressions.unshift new Assign (new IdentifierLiteral @name), @class
    else
      @body.expressions.unshift @class
    @body.expressions.unshift directives...
    @body.push ident

    klass.compileToFragments o

  # Traverse the class's children and:
  # - Hoist valid ES properties into `@properties`
  # - Hoist static assignments into `@properties`
  # - Convert invalid ES properties into class or prototype assignments
  walkBody: ->
    directives  = []

    index = 0
    while expr = @body.expressions[index]
      break unless expr instanceof Value and expr.isString()
      if expr.hoisted
        index++
      else
        directives.push @body.expressions.splice(index, 1)...

    @traverseChildren false, (child) =>
      return false if child instanceof Class or child instanceof HoistTarget

      cont = true
      if child instanceof Block
        for node, i in child.expressions
          if node instanceof Value and node.isObject(true)
            cont = false
            child.expressions[i] = @addProperties node.base.properties
          else if node instanceof Assign and node.variable.looksStatic @name
            node.value.isStatic = yes
        child.expressions = flatten child.expressions
      cont

    directives

  setContext: ->
    @body.traverseChildren false, (node) =>
      if node instanceof ThisLiteral
        node.value   = @name
      else if node instanceof Code and node.bound and (node.isStatic or not node.name)
        node.context = @name

  # Make class/prototype assignments for invalid ES properties
  addProperties: (assigns) ->
    result = for assign in assigns
      variable = assign.variable
      base     = variable?.base
      value    = assign.value
      delete assign.context

      if base.value is 'constructor'
        if value instanceof Code
          base.error 'constructors must be defined at the top level of a class body'

        # The class scope is not available yet, so return the assignment to update later
        assign = @externalCtor = new Assign new Value, value
      else if not assign.variable.this
        name =
          if base instanceof ComputedPropertyName
            new Index base.value
          else
            new (if base.shouldCache() then Index else Access) base
        prototype = new Access new PropertyName 'prototype'
        variable  = new Value new ThisLiteral(), [ prototype, name ]

        assign.variable = variable
      else if assign.value instanceof Code
        assign.value.isStatic = true

      assign
    compact result

exports.ClassProperty = class ClassProperty extends Base
  constructor: ({@name, @isStatic, @staticClassName, @value, @operatorToken}) ->
    super()

  children: ['name', 'value', 'staticClassName']

  isStatement: YES

  astProperties: (o) ->
    return
      key: @name.ast o, LEVEL_LIST
      value: @value.ast o, LEVEL_LIST
      static: !!@isStatic
      computed: @name instanceof Index or @name instanceof ComputedPropertyName
      operator: @operatorToken?.value ? '='
      staticClassName: @staticClassName?.ast(o) ? null

exports.ClassPrototypeProperty = class ClassPrototypeProperty extends Base
  constructor: ({@name, @value}) ->
    super()

  children: ['name', 'value']

  isStatement: YES

  astProperties: (o) ->
    return
      key: @name.ast o, LEVEL_LIST
      value: @value.ast o, LEVEL_LIST
      computed: @name instanceof ComputedPropertyName or @name instanceof StringWithInterpolations

#### Import and Export

exports.ModuleDeclaration = class ModuleDeclaration extends Base
  constructor: (@clause, @source) ->
    super()
    @checkSource()

  children: ['clause', 'source']

  isStatement: YES
  jumps:       THIS
  makeReturn:  THIS

  checkSource: ->
    if @source? and @source instanceof StringWithInterpolations
      @source.error 'the name of the module to be imported from must be an uninterpolated string'

  checkScope: (o, moduleDeclarationType) ->
    # TODO: would be appropriate to flag this error during AST generation (as
    # well as when compiling to JS). But `o.indent` isn’t tracked during AST
    # generation, and there doesn’t seem to be a current alternative way to track
    # whether we’re at the “program top-level”.
    if o.indent.length isnt 0
      @error "#{moduleDeclarationType} statements must be at top-level scope"

exports.ImportDeclaration = class ImportDeclaration extends ModuleDeclaration
  compileNode: (o) ->
    @checkScope o, 'import'
    o.importedSymbols = []

    code = []
    code.push @makeCode "#{@tab}import "
    code.push @clause.compileNode(o)... if @clause?

    if @source?.value?
      code.push @makeCode ' from ' unless @clause is null
      code.push @makeCode @source.value

    code.push @makeCode ';'
    code

  astNode: (o) ->
    o.importedSymbols = []
    super o

  astProperties: (o) ->
    ret =
      specifiers: @clause?.ast(o) ? []
      source: @source.ast o
    ret.importKind = 'value' if @clause
    ret

exports.ImportClause = class ImportClause extends Base
  constructor: (@defaultBinding, @namedImports) ->
    super()

  children: ['defaultBinding', 'namedImports']

  compileNode: (o) ->
    code = []

    if @defaultBinding?
      code.push @defaultBinding.compileNode(o)...
      code.push @makeCode ', ' if @namedImports?

    if @namedImports?
      code.push @namedImports.compileNode(o)...

    code

  astNode: (o) ->
    # The AST for `ImportClause` is the non-nested list of import specifiers
    # that will be the `specifiers` property of an `ImportDeclaration` AST
    compact flatten [
      @defaultBinding?.ast o
      @namedImports?.ast o
    ]

exports.ExportDeclaration = class ExportDeclaration extends ModuleDeclaration
  compileNode: (o) ->
    @checkScope o, 'export'
    @checkForAnonymousClassExport()

    code = []
    code.push @makeCode "#{@tab}export "
    code.push @makeCode 'default ' if @ instanceof ExportDefaultDeclaration

    if @ not instanceof ExportDefaultDeclaration and
       (@clause instanceof Assign or @clause instanceof Class)
      code.push @makeCode 'var '
      @clause.moduleDeclaration = 'export'

    if @clause.body? and @clause.body instanceof Block
      code = code.concat @clause.compileToFragments o, LEVEL_TOP
    else
      code = code.concat @clause.compileNode o

    code.push @makeCode " from #{@source.value}" if @source?.value?
    code.push @makeCode ';'
    code

  # Prevent exporting an anonymous class; all exported members must be named
  checkForAnonymousClassExport: ->
    if @ not instanceof ExportDefaultDeclaration and @clause instanceof Class and not @clause.variable
      @clause.error 'anonymous classes cannot be exported'

  astNode: (o) ->
    @checkForAnonymousClassExport()
    super o

exports.ExportNamedDeclaration = class ExportNamedDeclaration extends ExportDeclaration
  astProperties: (o) ->
    ret =
      source: @source?.ast(o) ? null
      exportKind: 'value'
    clauseAst = @clause.ast o
    if @clause instanceof ExportSpecifierList
      ret.specifiers = clauseAst
      ret.declaration = null
    else
      ret.specifiers = []
      ret.declaration = clauseAst
    ret

exports.ExportDefaultDeclaration = class ExportDefaultDeclaration extends ExportDeclaration
  astProperties: (o) ->
    return
      declaration: @clause.ast o

exports.ExportAllDeclaration = class ExportAllDeclaration extends ExportDeclaration
  astProperties: (o) ->
    return
      source: @source.ast o
      exportKind: 'value'

exports.ModuleSpecifierList = class ModuleSpecifierList extends Base
  constructor: (@specifiers) ->
    super()

  children: ['specifiers']

  compileNode: (o) ->
    code = []
    o.indent += TAB
    compiledList = (specifier.compileToFragments o, LEVEL_LIST for specifier in @specifiers)

    if @specifiers.length isnt 0
      code.push @makeCode "{\n#{o.indent}"
      for fragments, index in compiledList
        code.push @makeCode(",\n#{o.indent}") if index
        code.push fragments...
      code.push @makeCode "\n}"
    else
      code.push @makeCode '{}'
    code

  astNode: (o) ->
    specifier.ast(o) for specifier in @specifiers

exports.ImportSpecifierList = class ImportSpecifierList extends ModuleSpecifierList

exports.ExportSpecifierList = class ExportSpecifierList extends ModuleSpecifierList

exports.ModuleSpecifier = class ModuleSpecifier extends Base
  constructor: (@original, @alias, @moduleDeclarationType) ->
    super()

    if @original.comments or @alias?.comments
      @comments = []
      @comments.push @original.comments... if @original.comments
      @comments.push @alias.comments...    if @alias?.comments

    # The name of the variable entering the local scope
    @identifier = if @alias? then @alias.value else @original.value

  children: ['original', 'alias']

  compileNode: (o) ->
    @addIdentifierToScope o
    code = []
    code.push @makeCode @original.value
    code.push @makeCode " as #{@alias.value}" if @alias?
    code

  addIdentifierToScope: (o) ->
    o.scope.find @identifier, @moduleDeclarationType

  astNode: (o) ->
    @addIdentifierToScope o
    super o

exports.ImportSpecifier = class ImportSpecifier extends ModuleSpecifier
  constructor: (imported, local) ->
    super imported, local, 'import'

  addIdentifierToScope: (o) ->
    # Per the spec, symbols can’t be imported multiple times
    # (e.g. `import { foo, foo } from 'lib'` is invalid)
    if @identifier in o.importedSymbols or o.scope.check(@identifier)
      @error "'#{@identifier}' has already been declared"
    else
      o.importedSymbols.push @identifier
    super o

  astProperties: (o) ->
    originalAst = @original.ast o
    return
      imported: originalAst
      local: @alias?.ast(o) ? originalAst
      importKind: null

exports.ImportDefaultSpecifier = class ImportDefaultSpecifier extends ImportSpecifier
  astProperties: (o) ->
    return
      local: @original.ast o

exports.ImportNamespaceSpecifier = class ImportNamespaceSpecifier extends ImportSpecifier
  astProperties: (o) ->
    return
      local: @alias.ast o

exports.ExportSpecifier = class ExportSpecifier extends ModuleSpecifier
  constructor: (local, exported) ->
    super local, exported, 'export'

  astProperties: (o) ->
    originalAst = @original.ast o
    return
      local: originalAst
      exported: @alias?.ast(o) ? originalAst

exports.DynamicImport = class DynamicImport extends Base
  compileNode: ->
    [@makeCode 'import']

  astType: -> 'Import'

exports.DynamicImportCall = class DynamicImportCall extends Call
  compileNode: (o) ->
    @checkArguments()
    super o

  checkArguments: ->
    unless @args.length is 1
      @error 'import() requires exactly one argument'

  astNode: (o) ->
    @checkArguments()
    super o

#### Assign

# The **Assign** is used to assign a local variable to value, or to set the
# property of an object -- including within object literals.
exports.Assign = class Assign extends Base
  constructor: (@variable, @value, @context, options = {}) ->
    super()
    {@param, @subpattern, @operatorToken, @moduleDeclaration, @originalContext = @context} = options
    @propagateLhs()

  children: ['variable', 'value']

  isAssignable: YES

  isStatement: (o) ->
    o?.level is LEVEL_TOP and @context? and (@moduleDeclaration or "?" in @context)

  checkNameAssignability: (o, varBase) ->
    if o.scope.type(varBase.value) is 'import'
      varBase.error "'#{varBase.value}' is read-only"

  assigns: (name) ->
    @[if @context is 'object' then 'value' else 'variable'].assigns name

  unfoldSoak: (o) ->
    unfoldSoak o, this, 'variable'

  addScopeVariables: (o, {
    # During AST generation, we need to allow assignment to these constructs
    # that are considered “unassignable” during compile-to-JS, while still
    # flagging things like `[null] = b`.
    allowAssignmentToExpansion = no,
    allowAssignmentToNontrailingSplat = no,
    allowAssignmentToEmptyArray = no,
    allowAssignmentToComplexSplat = no
  } = {}) ->
    return unless not @context or @context is '**='

    varBase = @variable.unwrapAll()
    if not varBase.isAssignable {
      allowExpansion: allowAssignmentToExpansion
      allowNontrailingSplat: allowAssignmentToNontrailingSplat
      allowEmptyArray: allowAssignmentToEmptyArray
      allowComplexSplat: allowAssignmentToComplexSplat
    }
      @variable.error "'#{@variable.compile o}' can't be assigned"

    varBase.eachName (name) =>
      return if name.hasProperties?()

      message = isUnassignable name.value
      name.error message if message

      # `moduleDeclaration` can be `'import'` or `'export'`.
      @checkNameAssignability o, name
      if @moduleDeclaration
        o.scope.add name.value, @moduleDeclaration
        name.isDeclaration = yes
      else if @param
        o.scope.add name.value,
          if @param is 'alwaysDeclare'
            'var'
          else
            'param'
      else
        alreadyDeclared = o.scope.find name.value
        name.isDeclaration ?= not alreadyDeclared
        # If this assignment identifier has one or more herecomments
        # attached, output them as part of the declarations line (unless
        # other herecomments are already staged there) for compatibility
        # with Flow typing. Don’t do this if this assignment is for a
        # class, e.g. `ClassName = class ClassName {`, as Flow requires
        # the comment to be between the class name and the `{`.
        if name.comments and not o.scope.comments[name.value] and
           @value not instanceof Class and
           name.comments.every((comment) -> comment.here and not comment.multiline)
          commentsNode = new IdentifierLiteral name.value
          commentsNode.comments = name.comments
          commentFragments = []
          @compileCommentFragments o, commentsNode, commentFragments
          o.scope.comments[name.value] = commentFragments

  # Compile an assignment, delegating to `compileDestructuring` or
  # `compileSplice` if appropriate. Keep track of the name of the base object
  # we've been assigned to, for correct internal references. If the variable
  # has not been seen yet within the current scope, declare it.
  compileNode: (o) ->
    isValue = @variable instanceof Value
    if isValue
      # If `@variable` is an array or an object, we’re destructuring;
      # if it’s also `isAssignable()`, the destructuring syntax is supported
      # in ES and we can output it as is; otherwise we `@compileDestructuring`
      # and convert this ES-unsupported destructuring into acceptable output.
      if @variable.isArray() or @variable.isObject()
        unless @variable.isAssignable()
          if @variable.isObject() and @variable.base.hasSplat()
            return @compileObjectDestruct o
          else
            return @compileDestructuring o

      return @compileSplice       o if @variable.isSplice()
      return @compileConditional  o if @isConditional()
      return @compileSpecialMath  o if @context in ['//=', '%%=']

    @addScopeVariables o
    if @value instanceof Code
      if @value.isStatic
        @value.name = @variable.properties[0]
      else if @variable.properties?.length >= 2
        [properties..., prototype, name] = @variable.properties
        @value.name = name if prototype.name?.value is 'prototype'

    val = @value.compileToFragments o, LEVEL_LIST
    compiledName = @variable.compileToFragments o, LEVEL_LIST

    if @context is 'object'
      if @variable.shouldCache()
        compiledName.unshift @makeCode '['
        compiledName.push @makeCode ']'
      return compiledName.concat @makeCode(': '), val

    answer = compiledName.concat @makeCode(" #{ @context or '=' } "), val
    # Per https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Destructuring_assignment#Assignment_without_declaration,
    # if we’re destructuring without declaring, the destructuring assignment must be wrapped in parentheses.
    # The assignment is wrapped in parentheses if 'o.level' has lower precedence than LEVEL_LIST (3)
    # (i.e. LEVEL_COND (4), LEVEL_OP (5) or LEVEL_ACCESS (6)), or if we're destructuring object, e.g. {a,b} = obj.
    if o.level > LEVEL_LIST or isValue and @variable.base instanceof Obj and not @nestedLhs and not (@param is yes)
      @wrapInParentheses answer
    else
      answer

  # Object rest property is not assignable: `{{a}...}`
  compileObjectDestruct: (o) ->
    @variable.base.reorderProperties()
    {properties: props} = @variable.base
    [..., splat] = props
    splatProp = splat.name
    assigns = []
    refVal = new Value new IdentifierLiteral o.scope.freeVariable 'ref'
    props.splice -1, 1, new Splat refVal
    assigns.push new Assign(new Value(new Obj props), @value).compileToFragments o, LEVEL_LIST
    assigns.push new Assign(new Value(splatProp), refVal).compileToFragments o, LEVEL_LIST
    @joinFragmentArrays assigns, ', '

  # Brief implementation of recursive pattern matching, when assigning array or
  # object literals to a value. Peeks at their properties to assign inner names.
  compileDestructuring: (o) ->
    top       = o.level is LEVEL_TOP
    {value}   = this
    {objects} = @variable.base
    olen      = objects.length

    # Special-case for `{} = a` and `[] = a` (empty patterns).
    # Compile to simply `a`.
    if olen is 0
      code = value.compileToFragments o
      return if o.level >= LEVEL_OP then @wrapInParentheses code else code
    [obj] = objects

    @disallowLoneExpansion()
    {splats, expans, splatsAndExpans} = @getAndCheckSplatsAndExpansions()

    isSplat = splats?.length > 0
    isExpans = expans?.length > 0

    vvar     = value.compileToFragments o, LEVEL_LIST
    vvarText = fragmentsToText vvar
    assigns  = []
    pushAssign = (variable, val) =>
      assigns.push new Assign(variable, val, null, param: @param, subpattern: yes).compileToFragments o, LEVEL_LIST

    if isSplat
      splatVar = objects[splats[0]].name.unwrap()
      if splatVar instanceof Arr or splatVar instanceof Obj
        splatVarRef = new IdentifierLiteral o.scope.freeVariable 'ref'
        objects[splats[0]].name = splatVarRef
        splatVarAssign = -> pushAssign new Value(splatVar), splatVarRef

    # At this point, there are several things to destructure. So the `fn()` in
    # `{a, b} = fn()` must be cached, for example. Make vvar into a simple
    # variable if it isn’t already.
    if value.unwrap() not instanceof IdentifierLiteral or @variable.assigns(vvarText)
      ref = o.scope.freeVariable 'ref'
      assigns.push [@makeCode(ref + ' = '), vvar...]
      vvar = [@makeCode ref]
      vvarText = ref

    slicer = (type) -> (vvar, start, end = no) ->
      vvar = new IdentifierLiteral vvar unless vvar instanceof Value
      args = [vvar, new NumberLiteral(start)]
      args.push new NumberLiteral end if end
      slice = new Value (new IdentifierLiteral utility type, o), [new Access new PropertyName 'call']
      new Value new Call slice, args

    # Helper which outputs `[].slice` code.
    compSlice = slicer "slice"

    # Helper which outputs `[].splice` code.
    compSplice = slicer "splice"

    # Check if `objects` array contains any instance of `Assign`, e.g. {a:1}.
    hasObjAssigns = (objs) ->
      (i for obj, i in objs when obj instanceof Assign and obj.context is 'object')

    # Check if `objects` array contains any unassignable object.
    objIsUnassignable = (objs) ->
      return yes for obj in objs when not obj.isAssignable()
      no

    # `objects` are complex when there is object assign ({a:1}),
    # unassignable object, or just a single node.
    complexObjects = (objs) ->
      hasObjAssigns(objs).length or objIsUnassignable(objs) or olen is 1

    # "Complex" `objects` are processed in a loop.
    # Examples: [a, b, {c, r...}, d], [a, ..., {b, r...}, c, d]
    loopObjects = (objs, vvar, vvarTxt) =>
      for obj, i in objs
        # `Elision` can be skipped.
        continue if obj instanceof Elision
        # If `obj` is {a: 1}
        if obj instanceof Assign and obj.context is 'object'
          {variable: {base: idx}, value: vvar} = obj
          {variable: vvar} = vvar if vvar instanceof Assign
          idx =
            if vvar.this
              vvar.properties[0].name
            else
              new PropertyName vvar.unwrap().value
          acc = idx.unwrap() instanceof PropertyName
          vval = new Value value, [new (if acc then Access else Index) idx]
        else
          # `obj` is [a...], {a...} or a
          vvar = switch
            when obj instanceof Splat then new Value obj.name
            else obj
          vval = switch
            when obj instanceof Splat then compSlice(vvarTxt, i)
            else new Value new Literal(vvarTxt), [new Index new NumberLiteral i]
        message = isUnassignable vvar.unwrap().value
        vvar.error message if message
        pushAssign vvar, vval

    # "Simple" `objects` can be split and compiled to arrays, [a, b, c] = arr, [a, b, c...] = arr
    assignObjects = (objs, vvar, vvarTxt) =>
      vvar = new Value new Arr(objs, yes)
      vval = if vvarTxt instanceof Value then vvarTxt else new Value new Literal(vvarTxt)
      pushAssign vvar, vval

    processObjects = (objs, vvar, vvarTxt) ->
      if complexObjects objs
        loopObjects objs, vvar, vvarTxt
      else
        assignObjects objs, vvar, vvarTxt

    # In case there is `Splat` or `Expansion` in `objects`,
    # we can split array in two simple subarrays.
    # `Splat` [a, b, c..., d, e] can be split into  [a, b, c...] and [d, e].
    # `Expansion` [a, b, ..., c, d] can be split into [a, b] and [c, d].
    # Examples:
    # a) `Splat`
    #   CS: [a, b, c..., d, e] = arr
    #   JS: [a, b, ...c] = arr, [d, e] = splice.call(c, -2)
    # b) `Expansion`
    #   CS: [a, b, ..., d, e] = arr
    #   JS: [a, b] = arr, [d, e] = slice.call(arr, -2)
    if splatsAndExpans.length
      expIdx = splatsAndExpans[0]
      leftObjs = objects.slice 0, expIdx + (if isSplat then 1 else 0)
      rightObjs = objects.slice expIdx + 1
      processObjects leftObjs, vvar, vvarText if leftObjs.length isnt 0
      if rightObjs.length isnt 0
        # Slice or splice `objects`.
        refExp = switch
          when isSplat then compSplice new Value(objects[expIdx].name), rightObjs.length * -1
          when isExpans then compSlice vvarText, rightObjs.length * -1
        if complexObjects rightObjs
          restVar = refExp
          refExp = o.scope.freeVariable 'ref'
          assigns.push [@makeCode(refExp + ' = '), restVar.compileToFragments(o, LEVEL_LIST)...]
        processObjects rightObjs, vvar, refExp
    else
      # There is no `Splat` or `Expansion` in `objects`.
      processObjects objects, vvar, vvarText
    splatVarAssign?()
    assigns.push vvar unless top or @subpattern
    fragments = @joinFragmentArrays assigns, ', '
    if o.level < LEVEL_LIST then fragments else @wrapInParentheses fragments

  # Disallow `[...] = a` for some reason. (Could be equivalent to `[] = a`?)
  disallowLoneExpansion: ->
    return unless @variable.base instanceof Arr
    {objects} = @variable.base
    return unless objects?.length is 1
    [loneObject] = objects
    if loneObject instanceof Expansion
      loneObject.error 'Destructuring assignment has no target'

  # Show error if there is more than one `Splat`, or `Expansion`.
  # Examples: [a, b, c..., d, e, f...], [a, b, ..., c, d, ...], [a, b, ..., c, d, e...]
  getAndCheckSplatsAndExpansions: ->
    return {splats: [], expans: [], splatsAndExpans: []} unless @variable.base instanceof Arr
    {objects} = @variable.base

    # Count all `Splats`: [a, b, c..., d, e]
    splats = (i for obj, i in objects when obj instanceof Splat)
    # Count all `Expansions`: [a, b, ..., c, d]
    expans = (i for obj, i in objects when obj instanceof Expansion)
    # Combine splats and expansions.
    splatsAndExpans = [splats..., expans...]
    if splatsAndExpans.length > 1
      # Sort 'splatsAndExpans' so we can show error at first disallowed token.
      objects[splatsAndExpans.sort()[1]].error "multiple splats/expansions are disallowed in an assignment"
    {splats, expans, splatsAndExpans}

  # When compiling a conditional assignment, take care to ensure that the
  # operands are only evaluated once, even though we have to reference them
  # more than once.
  compileConditional: (o) ->
    [left, right] = @variable.cacheReference o
    # Disallow conditional assignment of undefined variables.
    if not left.properties.length and left.base instanceof Literal and
           left.base not instanceof ThisLiteral and not o.scope.check left.base.value
      @throwUnassignableConditionalError left.base.value
    if "?" in @context
      o.isExistentialEquals = true
      new If(new Existence(left), right, type: 'if').addElse(new Assign(right, @value, '=')).compileToFragments o
    else
      fragments = new Op(@context[...-1], left, new Assign(right, @value, '=')).compileToFragments o
      if o.level <= LEVEL_LIST then fragments else @wrapInParentheses fragments

  # Convert special math assignment operators like `a //= b` to the equivalent
  # extended form `a = a ** b` and then compiles that.
  compileSpecialMath: (o) ->
    [left, right] = @variable.cacheReference o
    new Assign(left, new Op(@context[...-1], right, @value)).compileToFragments o

  # Compile the assignment from an array splice literal, using JavaScript's
  # `Array#splice` method.
  compileSplice: (o) ->
    {range: {from, to, exclusive}} = @variable.properties.pop()
    unwrappedVar = @variable.unwrapAll()
    if unwrappedVar.comments
      moveComments unwrappedVar, @
      delete @variable.comments
    name = @variable.compile o
    if from
      [fromDecl, fromRef] = @cacheToCodeFragments from.cache o, LEVEL_OP
    else
      fromDecl = fromRef = '0'
    if to
      if from?.isNumber() and to.isNumber()
        to = to.compile(o) - fromRef
        to += 1 unless exclusive
      else
        to = to.compile(o, LEVEL_ACCESS) + ' - ' + fromRef
        to += ' + 1' unless exclusive
    else
      to = "9e9"
    [valDef, valRef] = @value.cache o, LEVEL_LIST
    answer = [].concat @makeCode("#{utility 'splice', o}.apply(#{name}, [#{fromDecl}, #{to}].concat("), valDef, @makeCode(")), "), valRef
    if o.level > LEVEL_TOP then @wrapInParentheses answer else answer

  eachName: (iterator) ->
    @variable.unwrapAll().eachName iterator

  isDefaultAssignment: -> @param or @nestedLhs

  propagateLhs: ->
    return unless @variable?.isArray?() or @variable?.isObject?()
    # This is the left-hand side of an assignment; let `Arr` and `Obj`
    # know that, so that those nodes know that they’re assignable as
    # destructured variables.
    @variable.base.propagateLhs yes

  throwUnassignableConditionalError: (name) ->
    @variable.error "the variable \"#{name}\" can't be assigned with #{@context} because it has not been declared before"

  isConditional: ->
    @context in ['||=', '&&=', '?=']

  isStatementAst: NO

  astNode: (o) ->
    @disallowLoneExpansion()
    @getAndCheckSplatsAndExpansions()
    if @isConditional()
      variable = @variable.unwrap()
      if variable instanceof IdentifierLiteral and not o.scope.check variable.value
        @throwUnassignableConditionalError variable.value
    @addScopeVariables o, allowAssignmentToExpansion: yes, allowAssignmentToNontrailingSplat: yes, allowAssignmentToEmptyArray: yes, allowAssignmentToComplexSplat: yes
    super o

  astType: ->
    if @isDefaultAssignment()
      'AssignmentPattern'
    else
      'AssignmentExpression'

  astProperties: (o) ->
    ret =
      right: @value.ast o, LEVEL_LIST
      left: @variable.ast o, LEVEL_LIST

    unless @isDefaultAssignment()
      ret.operator = @originalContext ? '='

    ret

#### FuncGlyph

exports.FuncGlyph = class FuncGlyph extends Base
  constructor: (@glyph) ->
    super()

#### Code

# A function definition. This is the only node that creates a new Scope.
# When for the purposes of walking the contents of a function body, the Code
# has no *children* -- they're within the inner scope.
exports.Code = class Code extends Base
  constructor: (params, body, @funcGlyph, @paramStart) ->
    super()

    @params      = params or []
    @body        = body or new Block
    @bound       = @funcGlyph?.glyph is '=>'
    @isGenerator = no
    @isAsync     = no
    @isMethod    = no

    @body.traverseChildren no, (node) =>
      if (node instanceof Op and node.isYield()) or node instanceof YieldReturn
        @isGenerator = yes
      if (node instanceof Op and node.isAwait()) or node instanceof AwaitReturn
        @isAsync = yes
      if node instanceof For and node.isAwait()
        @isAsync = yes

    @propagateLhs()

  children: ['params', 'body']

  isStatement: -> @isMethod

  jumps: NO

  makeScope: (parentScope) -> new Scope parentScope, @body, this

  # Compilation creates a new scope unless explicitly asked to share with the
  # outer scope. Handles splat parameters in the parameter list by setting
  # such parameters to be the final parameter in the function definition, as
  # required per the ES2015 spec. If the CoffeeScript function definition had
  # parameters after the splat, they are declared via expressions in the
  # function body.
  compileNode: (o) ->
    @checkForAsyncOrGeneratorConstructor()

    if @bound
      @context = o.scope.method.context if o.scope.method?.bound
      @context = 'this' unless @context

    @updateOptions o
    params           = []
    exprs            = []
    thisAssignments  = @thisAssignments?.slice() ? []
    paramsAfterSplat = []
    haveSplatParam   = no
    haveBodyParam    = no

    @checkForDuplicateParams()
    @disallowLoneExpansionAndMultipleSplats()

    # Separate `this` assignments.
    @eachParamName (name, node, param, obj) ->
      if node.this
        name   = node.properties[0].name.value
        name   = "_#{name}" if name in JS_FORBIDDEN
        target = new IdentifierLiteral o.scope.freeVariable name, reserve: no
        # `Param` is object destructuring with a default value: ({@prop = 1}) ->
        # In a case when the variable name is already reserved, we have to assign
        # a new variable name to the destructured variable: ({prop:prop1 = 1}) ->
        replacement =
            if param.name instanceof Obj and obj instanceof Assign and
                obj.operatorToken.value is '='
              new Assign (new IdentifierLiteral name), target, 'object' #, operatorToken: new Literal ':'
            else
              target
        param.renameParam node, replacement
        thisAssignments.push new Assign node, target

    # Parse the parameters, adding them to the list of parameters to put in the
    # function definition; and dealing with splats or expansions, including
    # adding expressions to the function body to declare all parameter
    # variables that would have been after the splat/expansion parameter.
    # If we encounter a parameter that needs to be declared in the function
    # body for any reason, for example it’s destructured with `this`, also
    # declare and assign all subsequent parameters in the function body so that
    # any non-idempotent parameters are evaluated in the correct order.
    for param, i in @params
      # Was `...` used with this parameter? Splat/expansion parameters cannot
      # have default values, so we need not worry about that.
      if param.splat or param instanceof Expansion
        haveSplatParam = yes
        if param.splat
          if param.name instanceof Arr or param.name instanceof Obj
            # Splat arrays are treated oddly by ES; deal with them the legacy
            # way in the function body. TODO: Should this be handled in the
            # function parameter list, and if so, how?
            splatParamName = o.scope.freeVariable 'arg'
            params.push ref = new Value new IdentifierLiteral splatParamName
            exprs.push new Assign new Value(param.name), ref
          else
            params.push ref = param.asReference o
            splatParamName = fragmentsToText ref.compileNodeWithoutComments o
          if param.shouldCache()
            exprs.push new Assign new Value(param.name), ref
        else # `param` is an Expansion
          splatParamName = o.scope.freeVariable 'args'
          params.push new Value new IdentifierLiteral splatParamName

        o.scope.parameter splatParamName

      # Parse all other parameters; if a splat paramater has not yet been
      # encountered, add these other parameters to the list to be output in
      # the function definition.
      else
        if param.shouldCache() or haveBodyParam
          param.assignedInBody = yes
          haveBodyParam = yes
          # This parameter cannot be declared or assigned in the parameter
          # list. So put a reference in the parameter list and add a statement
          # to the function body assigning it, e.g.
          # `(arg) => { var a = arg.a; }`, with a default value if it has one.
          if param.value?
            condition = new Op '===', param, new UndefinedLiteral
            ifTrue = new Assign new Value(param.name), param.value
            exprs.push new If condition, ifTrue
          else
            exprs.push new Assign new Value(param.name), param.asReference(o), null, param: 'alwaysDeclare'

        # If this parameter comes before the splat or expansion, it will go
        # in the function definition parameter list.
        unless haveSplatParam
          # If this parameter has a default value, and it hasn’t already been
          # set by the `shouldCache()` block above, define it as a statement in
          # the function body. This parameter comes after the splat parameter,
          # so we can’t define its default value in the parameter list.
          if param.shouldCache()
            ref = param.asReference o
          else
            if param.value? and not param.assignedInBody
              ref = new Assign new Value(param.name), param.value, null, param: yes
            else
              ref = param
          # Add this parameter’s reference(s) to the function scope.
          if param.name instanceof Arr or param.name instanceof Obj
            # This parameter is destructured.
            param.name.lhs = yes
            unless param.shouldCache()
              param.name.eachName (prop) ->
                o.scope.parameter prop.value
          else
            # This compilation of the parameter is only to get its name to add
            # to the scope name tracking; since the compilation output here
            # isn’t kept for eventual output, don’t include comments in this
            # compilation, so that they get output the “real” time this param
            # is compiled.
            paramToAddToScope = if param.value? then param else ref
            o.scope.parameter fragmentsToText paramToAddToScope.compileToFragmentsWithoutComments o
          params.push ref
        else
          paramsAfterSplat.push param
          # If this parameter had a default value, since it’s no longer in the
          # function parameter list we need to assign its default value
          # (if necessary) as an expression in the body.
          if param.value? and not param.shouldCache()
            condition = new Op '===', param, new UndefinedLiteral
            ifTrue = new Assign new Value(param.name), param.value
            exprs.push new If condition, ifTrue
          # Add this parameter to the scope, since it wouldn’t have been added
          # yet since it was skipped earlier.
          o.scope.add param.name.value, 'var', yes if param.name?.value?

    # If there were parameters after the splat or expansion parameter, those
    # parameters need to be assigned in the body of the function.
    if paramsAfterSplat.length isnt 0
      # Create a destructured assignment, e.g. `[a, b, c] = [args..., b, c]`
      exprs.unshift new Assign new Value(
          new Arr [new Splat(new IdentifierLiteral(splatParamName)), (param.asReference o for param in paramsAfterSplat)...]
        ), new Value new IdentifierLiteral splatParamName

    # Add new expressions to the function body
    wasEmpty = @body.isEmpty()
    @disallowSuperInParamDefaults()
    @checkSuperCallsInConstructorBody()
    @body.expressions.unshift thisAssignments... unless @expandCtorSuper thisAssignments
    @body.expressions.unshift exprs...
    if @isMethod and @bound and not @isStatic and @classVariable
      boundMethodCheck = new Value new Literal utility 'boundMethodCheck', o
      @body.expressions.unshift new Call(boundMethodCheck, [new Value(new ThisLiteral), @classVariable])
    @body.makeReturn() unless wasEmpty or @noReturn

    # JavaScript doesn’t allow bound (`=>`) functions to also be generators.
    # This is usually caught via `Op::compileContinuation`, but double-check:
    if @bound and @isGenerator
      yieldNode = @body.contains (node) -> node instanceof Op and node.operator is 'yield'
      (yieldNode or @).error 'yield cannot occur inside bound (fat arrow) functions'

    # Assemble the output
    modifiers = []
    modifiers.push 'static' if @isMethod and @isStatic
    modifiers.push 'async'  if @isAsync
    unless @isMethod or @bound
      modifiers.push "function#{if @isGenerator then '*' else ''}"
    else if @isGenerator
      modifiers.push '*'

    signature = [@makeCode '(']
    # Block comments between a function name and `(` get output between
    # `function` and `(`.
    if @paramStart?.comments?
      @compileCommentFragments o, @paramStart, signature
    for param, i in params
      signature.push @makeCode ', ' if i isnt 0
      signature.push @makeCode '...' if haveSplatParam and i is params.length - 1
      # Compile this parameter, but if any generated variables get created
      # (e.g. `ref`), shift those into the parent scope since we can’t put a
      # `var` line inside a function parameter list.
      scopeVariablesCount = o.scope.variables.length
      signature.push param.compileToFragments(o, LEVEL_PAREN)...
      if scopeVariablesCount isnt o.scope.variables.length
        generatedVariables = o.scope.variables.splice scopeVariablesCount
        o.scope.parent.variables.push generatedVariables...
    signature.push @makeCode ')'
    # Block comments between `)` and `->`/`=>` get output between `)` and `{`.
    if @funcGlyph?.comments?
      comment.unshift = no for comment in @funcGlyph.comments
      @compileCommentFragments o, @funcGlyph, signature

    body = @body.compileWithDeclarations o unless @body.isEmpty()

    # We need to compile the body before method names to ensure `super`
    # references are handled.
    if @isMethod
      [methodScope, o.scope] = [o.scope, o.scope.parent]
      name = @name.compileToFragments o
      name.shift() if name[0].code is '.'
      o.scope = methodScope

    answer = @joinFragmentArrays (@makeCode m for m in modifiers), ' '
    answer.push @makeCode ' ' if modifiers.length and name
    answer.push name... if name
    answer.push signature...
    answer.push @makeCode ' =>' if @bound and not @isMethod
    answer.push @makeCode ' {'
    answer.push @makeCode('\n'), body..., @makeCode("\n#{@tab}") if body?.length
    answer.push @makeCode '}'

    return indentInitial answer, @ if @isMethod
    if @front or (o.level >= LEVEL_ACCESS) then @wrapInParentheses answer else answer

  updateOptions: (o) ->
    o.scope         = del(o, 'classScope') or @makeScope o.scope
    o.scope.shared  = del(o, 'sharedScope')
    o.indent        += TAB
    delete o.bare
    delete o.isExistentialEquals

  checkForDuplicateParams: ->
    paramNames = []
    @eachParamName (name, node, param) ->
      node.error "multiple parameters named '#{name}'" if name in paramNames
      paramNames.push name

  eachParamName: (iterator) ->
    param.eachName iterator for param in @params

  # Short-circuit `traverseChildren` method to prevent it from crossing scope
  # boundaries unless `crossScope` is `true`.
  traverseChildren: (crossScope, func) ->
    super(crossScope, func) if crossScope

  # Short-circuit `replaceInContext` method to prevent it from crossing context boundaries. Bound
  # functions have the same context.
  replaceInContext: (child, replacement) ->
    if @bound
      super child, replacement
    else
      false

  disallowSuperInParamDefaults: ({forAst} = {}) ->
    return false unless @ctor

    @eachSuperCall Block.wrap(@params), (superCall) ->
      superCall.error "'super' is not allowed in constructor parameter defaults"
    , checkForThisBeforeSuper: not forAst

  checkSuperCallsInConstructorBody: ->
    return false unless @ctor

    seenSuper = @eachSuperCall @body, (superCall) =>
      superCall.error "'super' is only allowed in derived class constructors" if @ctor is 'base'

    seenSuper

  flagThisParamInDerivedClassConstructorWithoutCallingSuper: (param) ->
    param.error "Can't use @params in derived class constructors without calling super"

  checkForAsyncOrGeneratorConstructor: ->
    if @ctor
      @name.error 'Class constructor may not be async'       if @isAsync
      @name.error 'Class constructor may not be a generator' if @isGenerator

  disallowLoneExpansionAndMultipleSplats: ->
    seenSplatParam = no
    for param in @params
      # Was `...` used with this parameter? (Only one such parameter is allowed
      # per function.)
      if param.splat or param instanceof Expansion
        if seenSplatParam
          param.error 'only one splat or expansion parameter is allowed per function definition'
        else if param instanceof Expansion and @params.length is 1
          param.error 'an expansion parameter cannot be the only parameter in a function definition'
        seenSplatParam = yes

  expandCtorSuper: (thisAssignments) ->
    return false unless @ctor

    seenSuper = @eachSuperCall @body, (superCall) =>
      superCall.expressions = thisAssignments

    haveThisParam = thisAssignments.length and thisAssignments.length isnt @thisAssignments?.length
    if @ctor is 'derived' and not seenSuper and haveThisParam
      param = thisAssignments[0].variable
      @flagThisParamInDerivedClassConstructorWithoutCallingSuper param

    seenSuper

  # Find all super calls in the given context node;
  # returns `true` if `iterator` is called.
  eachSuperCall: (context, iterator, {checkForThisBeforeSuper = yes} = {}) ->
    seenSuper = no

    context.traverseChildren yes, (child) =>
      if child instanceof SuperCall
        # `super` in a constructor (the only `super` without an accessor)
        # cannot be given an argument with a reference to `this`, as that would
        # be referencing `this` before calling `super`.
        unless child.variable.accessor
          childArgs = child.args.filter (arg) ->
            arg not instanceof Class and (arg not instanceof Code or arg.bound)
          Block.wrap(childArgs).traverseChildren yes, (node) =>
            node.error "Can't call super with @params in derived class constructors" if node.this
        seenSuper = yes
        iterator child
      else if checkForThisBeforeSuper and child instanceof ThisLiteral and @ctor is 'derived' and not seenSuper
        child.error "Can't reference 'this' before calling super in derived class constructors"

      # `super` has the same target in bound (arrow) functions, so check them too
      child not instanceof SuperCall and (child not instanceof Code or child.bound)

    seenSuper

  propagateLhs: ->
    for param in @params
      {name} = param
      if name instanceof Arr or name instanceof Obj
        name.propagateLhs yes
      else if param instanceof Expansion
        param.lhs = yes

  astAddParamsToScope: (o) ->
    @eachParamName (name) ->
      o.scope.add name, 'param'

  astNode: (o) ->
    @updateOptions o
    @checkForAsyncOrGeneratorConstructor()
    @checkForDuplicateParams()
    @disallowSuperInParamDefaults forAst: yes
    @disallowLoneExpansionAndMultipleSplats()
    seenSuper = @checkSuperCallsInConstructorBody()
    if @ctor is 'derived' and not seenSuper
      @eachParamName (name, node) =>
        if node.this
          @flagThisParamInDerivedClassConstructorWithoutCallingSuper node
    @astAddParamsToScope o
    @body.makeReturn null, yes unless @body.isEmpty() or @noReturn

    super o

  astType: ->
    if @isMethod
      'ClassMethod'
    else if @bound
      'ArrowFunctionExpression'
    else
      'FunctionExpression'

  paramForAst: (param) ->
    return param if param instanceof Expansion
    {name, value, splat} = param
    if splat
      new Splat name, lhs: yes, postfix: splat.postfix
      .withLocationDataFrom param
    else if value?
      new Assign name, value, null, param: yes
      .withLocationDataFrom locationData: mergeLocationData name.locationData, value.locationData
    else
      name

  methodAstProperties: (o) ->
    getIsComputed = =>
      return yes if @name instanceof Index
      return yes if @name instanceof ComputedPropertyName
      return yes if @name.name instanceof ComputedPropertyName
      no

    return
      static: !!@isStatic
      key: @name.ast o
      computed: getIsComputed()
      kind:
        if @ctor
          'constructor'
        else
          'method'
      operator: @operatorToken?.value ? '='
      staticClassName: @isStatic.staticClassName?.ast(o) ? null
      bound: !!@bound

  astProperties: (o) ->
    return Object.assign
      params: @paramForAst(param).ast(o) for param in @params
      body: @body.ast (Object.assign {}, o, checkForDirectives: yes), LEVEL_TOP
      generator: !!@isGenerator
      async: !!@isAsync
      # We never generate named functions, so specify `id` as `null`, which
      # matches the Babel AST for anonymous function expressions/arrow functions
      id: null
      hasIndentedBody: @body.locationData.first_line > @funcGlyph?.locationData.first_line
    ,
      if @isMethod then @methodAstProperties o else {}

  astLocationData: ->
    functionLocationData = super()
    return functionLocationData unless @isMethod

    astLocationData = mergeAstLocationData @name.astLocationData(), functionLocationData
    if @isStatic.staticClassName?
      astLocationData = mergeAstLocationData @isStatic.staticClassName.astLocationData(), astLocationData
    astLocationData

#### Param

# A parameter in a function definition. Beyond a typical JavaScript parameter,
# these parameters can also attach themselves to the context of the function,
# as well as be a splat, gathering up a group of parameters into an array.
exports.Param = class Param extends Base
  constructor: (@name, @value, @splat) ->
    super()

    message = isUnassignable @name.unwrapAll().value
    @name.error message if message
    if @name instanceof Obj and @name.generated
      token = @name.objects[0].operatorToken
      token.error "unexpected #{token.value}"

  children: ['name', 'value']

  compileToFragments: (o) ->
    @name.compileToFragments o, LEVEL_LIST

  compileToFragmentsWithoutComments: (o) ->
    @name.compileToFragmentsWithoutComments o, LEVEL_LIST

  asReference: (o) ->
    return @reference if @reference
    node = @name
    if node.this
      name = node.properties[0].name.value
      name = "_#{name}" if name in JS_FORBIDDEN
      node = new IdentifierLiteral o.scope.freeVariable name
    else if node.shouldCache()
      node = new IdentifierLiteral o.scope.freeVariable 'arg'
    node = new Value node
    node.updateLocationDataIfMissing @locationData
    @reference = node

  shouldCache: ->
    @name.shouldCache()

  # Iterates the name or names of a `Param`.
  # In a sense, a destructured parameter represents multiple JS parameters. This
  # method allows to iterate them all.
  # The `iterator` function will be called as `iterator(name, node)` where
  # `name` is the name of the parameter and `node` is the AST node corresponding
  # to that name.
  eachName: (iterator, name = @name) ->
    checkAssignabilityOfLiteral = (literal) ->
      message = isUnassignable literal.value
      if message
        literal.error message
      unless literal.isAssignable()
        literal.error "'#{literal.value}' can't be assigned"

    atParam = (obj, originalObj = null) => iterator "@#{obj.properties[0].name.value}", obj, @, originalObj
    if name instanceof Call
      name.error "Function invocation can't be assigned"

    # * simple literals `foo`
    if name instanceof Literal
      checkAssignabilityOfLiteral name
      return iterator name.value, name, @
    # * at-params `@foo`
    return atParam name if name instanceof Value
    for obj in name.objects ? []
      # Save original obj.
      nObj = obj
      # * destructured parameter with default value
      if obj instanceof Assign and not obj.context?
        obj = obj.variable
      # * assignments within destructured parameters `{foo:bar}`
      if obj instanceof Assign
        # ... possibly with a default value
        if obj.value instanceof Assign
          obj = obj.value.variable
        else
          obj = obj.value
        @eachName iterator, obj.unwrap()
      # * splats within destructured parameters `[xs...]`
      else if obj instanceof Splat
        node = obj.name.unwrap()
        iterator node.value, node, @
      else if obj instanceof Value
        # * destructured parameters within destructured parameters `[{a}]`
        if obj.isArray() or obj.isObject()
          @eachName iterator, obj.base
        # * at-params within destructured parameters `{@foo}`
        else if obj.this
          atParam obj, nObj
        # * simple destructured parameters {foo}
        else
          checkAssignabilityOfLiteral obj.base
          iterator obj.base.value, obj.base, @
      else if obj instanceof Elision
        obj
      else if obj not instanceof Expansion
        obj.error "illegal parameter #{obj.compile()}"
    return

  # Rename a param by replacing the given AST node for a name with a new node.
  # This needs to ensure that the the source for object destructuring does not change.
  renameParam: (node, newNode) ->
    isNode      = (candidate) -> candidate is node
    replacement = (node, parent) =>
      if parent instanceof Obj
        key = node
        key = node.properties[0].name if node.this
        # No need to assign a new variable for the destructured variable if the variable isn't reserved.
        # Examples:
        # `({@foo}) ->`  should compile to `({foo}) { this.foo = foo}`
        # `foo = 1; ({@foo}) ->` should compile to `foo = 1; ({foo:foo1}) { this.foo = foo1 }`
        if node.this and key.value is newNode.value
          new Value newNode
        else
          new Assign new Value(key), newNode, 'object'
      else
        newNode

    @replaceInContext isNode, replacement

#### Splat

# A splat, either as a parameter to a function, an argument to a call,
# or as part of a destructuring assignment.
exports.Splat = class Splat extends Base
  constructor: (name, {@lhs, @postfix = true} = {}) ->
    super()
    @name = if name.compile then name else new Literal name

  children: ['name']

  shouldCache: -> no

  isAssignable: ({allowComplexSplat = no} = {})->
    return allowComplexSplat if @name instanceof Obj or @name instanceof Parens
    @name.isAssignable() and (not @name.isAtomic or @name.isAtomic())

  assigns: (name) ->
    @name.assigns name

  compileNode: (o) ->
    compiledSplat = [@makeCode('...'), @name.compileToFragments(o, LEVEL_OP)...]
    return compiledSplat unless @jsx
    return [@makeCode('{'), compiledSplat..., @makeCode('}')]

  unwrap: -> @name

  propagateLhs: (setLhs) ->
    @lhs = yes if setLhs
    return unless @lhs
    @name.propagateLhs? yes

  astType: ->
    if @jsx
      'JSXSpreadAttribute'
    else if @lhs
      'RestElement'
    else
      'SpreadElement'

  astProperties: (o) -> {
    argument: @name.ast o, LEVEL_OP
    @postfix
  }

#### Expansion

# Used to skip values inside an array destructuring (pattern matching) or
# parameter list.
exports.Expansion = class Expansion extends Base

  shouldCache: NO

  compileNode: (o) ->
    @throwLhsError()

  asReference: (o) ->
    this

  eachName: (iterator) ->

  throwLhsError: ->
    @error 'Expansion must be used inside a destructuring assignment or parameter list'

  astNode: (o) ->
    unless @lhs
      @throwLhsError()

    super o

  astType: -> 'RestElement'

  astProperties: ->
    return
      argument: null

#### Elision

# Array elision element (for example, [,a, , , b, , c, ,]).
exports.Elision = class Elision extends Base

  isAssignable: YES

  shouldCache: NO

  compileToFragments: (o, level) ->
    fragment = super o, level
    fragment.isElision = yes
    fragment

  compileNode: (o) ->
    [@makeCode ', ']

  asReference: (o) ->
    this

  eachName: (iterator) ->

  astNode: ->
    null

#### While

# A while loop, the only sort of low-level loop exposed by CoffeeScript. From
# it, all other loops can be manufactured. Useful in cases where you need more
# flexibility or more speed than a comprehension can provide.
exports.While = class While extends Base
  constructor: (@condition, {@invert, @guard, @isLoop} = {}) ->
    super()

  children: ['condition', 'guard', 'body']

  isStatement: YES

  makeReturn: (results, mark) ->
    return super(results, mark) if results
    @returns = not @jumps()
    if mark
      @body.makeReturn(results, mark) if @returns
      return
    this

  addBody: (@body) ->
    this

  jumps: ->
    {expressions} = @body
    return no unless expressions.length
    for node in expressions
      return jumpNode if jumpNode = node.jumps loop: yes
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
          body.expressions.unshift new If (new Parens @guard).invert(), new StatementLiteral "continue"
        else
          body = Block.wrap [new If @guard, body] if @guard
      body = [].concat @makeCode("\n"), (body.compileToFragments o, LEVEL_TOP), @makeCode("\n#{@tab}")
    answer = [].concat @makeCode(set + @tab + "while ("), @processedCondition().compileToFragments(o, LEVEL_PAREN),
      @makeCode(") {"), body, @makeCode("}")
    if @returns
      answer.push @makeCode "\n#{@tab}return #{rvar};"
    answer

  processedCondition: ->
    @processedConditionCache ?= if @invert then @condition.invert() else @condition

  astType: -> 'WhileStatement'

  astProperties: (o) ->
    return
      test: @condition.ast o, LEVEL_PAREN
      body: @body.ast o, LEVEL_TOP
      guard: @guard?.ast(o) ? null
      inverted: !!@invert
      postfix: !!@postfix
      loop: !!@isLoop

#### Op

# Simple Arithmetic and logical operations. Performs some conversion from
# CoffeeScript operations into their JavaScript equivalents.
exports.Op = class Op extends Base
  constructor: (op, first, second, flip, {@invertOperator, @originalOperator = op} = {}) ->
    super()

    if op is 'new'
      if ((firstCall = unwrapped = first.unwrap()) instanceof Call or (firstCall = unwrapped.base) instanceof Call) and not firstCall.do and not firstCall.isNew
        return new Value firstCall.newInstance(), if firstCall is unwrapped then [] else unwrapped.properties
      first = new Parens first unless first instanceof Parens or first.unwrap() instanceof IdentifierLiteral or first.hasProperties?()
      call = new Call first, []
      call.locationData = @locationData
      call.isNew = yes
      return call

    @operator = CONVERSIONS[op] or op
    @first    = first
    @second   = second
    @flip     = !!flip

    if @operator in ['--', '++']
      message = isUnassignable @first.unwrapAll().value
      @first.error message if message

    return this

  # The map of conversions from CoffeeScript to JavaScript symbols.
  CONVERSIONS =
    '==':        '==='
    '!=':        '!=='
    'of':        'in'
    'yieldfrom': 'yield*'

  # The map of invertible operators.
  INVERSIONS =
    '!==': '==='
    '===': '!=='

  children: ['first', 'second']

  isNumber: ->
    @isUnary() and @operator in ['+', '-'] and
      @first instanceof Value and @first.isNumber()

  isAwait: ->
    @operator is 'await'

  isYield: ->
    @operator in ['yield', 'yield*']

  isUnary: ->
    not @second

  shouldCache: ->
    not @isNumber()

  # Am I capable of
  # [Python-style comparison chaining](https://docs.python.org/3/reference/expressions.html#not-in)?
  isChainable: ->
    @operator in ['<', '>', '>=', '<=', '===', '!==']

  isChain: ->
    @isChainable() and @first.isChainable()

  invert: ->
    if @isInOperator()
      @invertOperator = '!'
      return @
    if @isChain()
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

  isInOperator: ->
    @originalOperator is 'in'

  compileNode: (o) ->
    if @isInOperator()
      inNode = new In @first, @second
      return (if @invertOperator then inNode.invert() else inNode).compileNode o
    if @invertOperator
      @invertOperator = null
      return @invert().compileNode(o)
    return Op::generateDo(@first).compileNode o if @operator is 'do'
    isChain = @isChain()
    # In chains, there's no need to wrap bare obj literals in parens,
    # as the chained expression is wrapped.
    @first.front = @front unless isChain
    @checkDeleteOperand o
    return @compileContinuation o if @isYield() or @isAwait()
    return @compileUnary        o if @isUnary()
    return @compileChain        o if isChain
    switch @operator
      when '?'  then @compileExistence o, @second.isDefaultValue
      when '//' then @compileFloorDivision o
      when '%%' then @compileModulo o
      else
        lhs = @first.compileToFragments o, LEVEL_OP
        rhs = @second.compileToFragments o, LEVEL_OP
        answer = [].concat lhs, @makeCode(" #{@operator} "), rhs
        if o.level <= LEVEL_OP then answer else @wrapInParentheses answer

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
    @wrapInParentheses fragments

  # Keep reference to the left expression, unless this an existential assignment
  compileExistence: (o, checkOnlyUndefined) ->
    if @first.shouldCache()
      ref = new IdentifierLiteral o.scope.freeVariable 'ref'
      fst = new Parens new Assign ref, @first
    else
      fst = @first
      ref = fst
    new If(new Existence(fst, checkOnlyUndefined), ref, type: 'if').addElse(@second).compileToFragments o

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
    parts.push [@makeCode(' ')] if op in ['typeof', 'delete'] or
                      plusMinus and @first instanceof Op and @first.operator is op
    if plusMinus and @first instanceof Op
      @first = new Parens @first
    parts.push @first.compileToFragments o, LEVEL_OP
    parts.reverse() if @flip
    @joinFragmentArrays parts, ''

  compileContinuation: (o) ->
    parts = []
    op = @operator
    @checkContinuation o
    if 'expression' in Object.keys(@first) and not (@first instanceof Throw)
      parts.push @first.expression.compileToFragments o, LEVEL_OP if @first.expression?
    else
      parts.push [@makeCode "("] if o.level >= LEVEL_PAREN
      parts.push [@makeCode op]
      parts.push [@makeCode " "] if @first.base?.value isnt ''
      parts.push @first.compileToFragments o, LEVEL_OP
      parts.push [@makeCode ")"] if o.level >= LEVEL_PAREN
    @joinFragmentArrays parts, ''

  checkContinuation: (o) ->
    unless o.scope.parent?
      @error "#{@operator} can only occur inside functions"
    if o.scope.method?.bound and o.scope.method.isGenerator
      @error 'yield cannot occur inside bound (fat arrow) functions'

  compileFloorDivision: (o) ->
    floor = new Value new IdentifierLiteral('Math'), [new Access new PropertyName 'floor']
    second = if @second.shouldCache() then new Parens @second else @second
    div = new Op '/', @first, second
    new Call(floor, [div]).compileToFragments o

  compileModulo: (o) ->
    mod = new Value new Literal utility 'modulo', o
    new Call(mod, [@first, @second]).compileToFragments o

  toString: (idt) ->
    super idt, @constructor.name + ' ' + @operator

  checkDeleteOperand: (o) ->
    if @operator is 'delete' and o.scope.check(@first.unwrapAll().value)
      @error 'delete operand may not be argument or var'

  astNode: (o) ->
    @checkContinuation o if @isYield() or @isAwait()
    @checkDeleteOperand o
    super o

  astType: ->
    return 'AwaitExpression' if @isAwait()
    return 'YieldExpression' if @isYield()
    return 'ChainedComparison' if @isChain()
    switch @operator
      when '||', '&&', '?' then 'LogicalExpression'
      when '++', '--'      then 'UpdateExpression'
      else
        if @isUnary()      then 'UnaryExpression'
        else                    'BinaryExpression'

  operatorAst: ->
    "#{if @invertOperator then "#{@invertOperator} " else ''}#{@originalOperator}"

  chainAstProperties: (o) ->
    operators = [@operatorAst()]
    operands = [@second]
    currentOp = @first
    loop
      operators.unshift currentOp.operatorAst()
      operands.unshift currentOp.second
      currentOp = currentOp.first
      unless currentOp.isChainable()
        operands.unshift currentOp
        break
    return {
      operators
      operands: (operand.ast(o, LEVEL_OP) for operand in operands)
    }

  astProperties: (o) ->
    return @chainAstProperties(o) if @isChain()

    firstAst = @first.ast o, LEVEL_OP
    secondAst = @second?.ast o, LEVEL_OP
    operatorAst = @operatorAst()
    switch
      when @isUnary()
        argument =
          if @isYield() and @first.unwrap().value is ''
            null
          else
            firstAst
        return {argument} if @isAwait()
        return {
          argument
          delegate: @operator is 'yield*'
        } if @isYield()
        return {
          argument
          operator: operatorAst
          prefix: !@flip
        }
      else
        return
          left: firstAst
          right: secondAst
          operator: operatorAst

#### In
exports.In = class In extends Base
  constructor: (@object, @array) ->
    super()

  children: ['object', 'array']

  invert: NEGATE

  compileNode: (o) ->
    if @array instanceof Value and @array.isArray() and @array.base.objects.length
      for obj in @array.base.objects when obj instanceof Splat
        hasSplat = yes
        break
      # `compileOrTest` only if we have an array literal with no splats
      return @compileOrTest o unless hasSplat
    @compileLoopTest o

  compileOrTest: (o) ->
    [sub, ref] = @object.cache o, LEVEL_OP
    [cmp, cnj] = if @negated then [' !== ', ' && '] else [' === ', ' || ']
    tests = []
    for item, i in @array.base.objects
      if i then tests.push @makeCode cnj
      tests = tests.concat (if i then ref else sub), @makeCode(cmp), item.compileToFragments(o, LEVEL_ACCESS)
    if o.level < LEVEL_OP then tests else @wrapInParentheses tests

  compileLoopTest: (o) ->
    [sub, ref] = @object.cache o, LEVEL_LIST
    fragments = [].concat @makeCode(utility('indexOf', o) + ".call("), @array.compileToFragments(o, LEVEL_LIST),
      @makeCode(", "), ref, @makeCode(") " + if @negated then '< 0' else '>= 0')
    return fragments if fragmentsToText(sub) is fragmentsToText(ref)
    fragments = sub.concat @makeCode(', '), fragments
    if o.level < LEVEL_LIST then fragments else @wrapInParentheses fragments

  toString: (idt) ->
    super idt, @constructor.name + if @negated then '!' else ''

#### Try

# A classic *try/catch/finally* block.
exports.Try = class Try extends Base
  constructor: (@attempt, @catch, @ensure, @finallyTag) ->
    super()

  children: ['attempt', 'catch', 'ensure']

  isStatement: YES

  jumps: (o) -> @attempt.jumps(o) or @catch?.jumps(o)

  makeReturn: (results, mark) ->
    if mark
      @attempt?.makeReturn results, mark
      @catch?.makeReturn results, mark
      return
    @attempt = @attempt.makeReturn results if @attempt
    @catch   = @catch  .makeReturn results if @catch
    this

  # Compilation is more or less as you would expect -- the *finally* clause
  # is optional, the *catch* is not.
  compileNode: (o) ->
    originalIndent = o.indent
    o.indent  += TAB
    tryPart   = @attempt.compileToFragments o, LEVEL_TOP

    catchPart = if @catch
      @catch.compileToFragments merge(o, indent: originalIndent), LEVEL_TOP
    else unless @ensure or @catch
      generatedErrorVariableName = o.scope.freeVariable 'error', reserve: no
      [@makeCode(" catch (#{generatedErrorVariableName}) {}")]
    else
      []

    ensurePart = if @ensure then ([].concat @makeCode(" finally {\n"), @ensure.compileToFragments(o, LEVEL_TOP),
      @makeCode("\n#{@tab}}")) else []

    [].concat @makeCode("#{@tab}try {\n"),
      tryPart,
      @makeCode("\n#{@tab}}"), catchPart, ensurePart

  astType: -> 'TryStatement'

  astProperties: (o) ->
    return
      block: @attempt.ast o, LEVEL_TOP
      handler: @catch?.ast(o) ? null
      finalizer:
        if @ensure?
          Object.assign @ensure.ast(o, LEVEL_TOP),
            # Include `finally` keyword in location data.
            mergeAstLocationData(
              jisonLocationDataToAstLocationData(@finallyTag.locationData),
              @ensure.astLocationData()
            )
        else
          null

exports.Catch = class Catch extends Base
  constructor: (@recovery, @errorVariable) ->
    super()
    @errorVariable?.unwrap().propagateLhs? yes

  children: ['recovery', 'errorVariable']

  isStatement: YES

  jumps: (o) -> @recovery.jumps(o)

  makeReturn: (results, mark) ->
    ret = @recovery.makeReturn results, mark
    return if mark
    @recovery = ret
    this

  compileNode: (o) ->
    o.indent  += TAB
    generatedErrorVariableName = o.scope.freeVariable 'error', reserve: no
    placeholder = new IdentifierLiteral generatedErrorVariableName
    @checkUnassignable()
    if @errorVariable
      @recovery.unshift new Assign @errorVariable, placeholder
    [].concat @makeCode(" catch ("), placeholder.compileToFragments(o), @makeCode(") {\n"),
      @recovery.compileToFragments(o, LEVEL_TOP), @makeCode("\n#{@tab}}")

  checkUnassignable: ->
    if @errorVariable
      message = isUnassignable @errorVariable.unwrapAll().value
      @errorVariable.error message if message

  astNode: (o) ->
    @checkUnassignable()
    @errorVariable?.eachName (name) ->
      alreadyDeclared = o.scope.find name.value
      name.isDeclaration = not alreadyDeclared

    super o

  astType: -> 'CatchClause'

  astProperties: (o) ->
    return
      param: @errorVariable?.ast(o) ? null
      body: @recovery.ast o, LEVEL_TOP

#### Throw

# Simple node to throw an exception.
exports.Throw = class Throw extends Base
  constructor: (@expression) ->
    super()

  children: ['expression']

  isStatement: YES
  jumps:       NO

  # A **Throw** is already a return, of sorts...
  makeReturn: THIS

  compileNode: (o) ->
    fragments = @expression.compileToFragments o, LEVEL_LIST
    unshiftAfterComments fragments, @makeCode 'throw '
    fragments.unshift @makeCode @tab
    fragments.push @makeCode ';'
    fragments

  astType: -> 'ThrowStatement'

  astProperties: (o) ->
    return
      argument: @expression.ast o, LEVEL_LIST

#### Existence

# Checks a variable for existence -- not `null` and not `undefined`. This is
# similar to `.nil?` in Ruby, and avoids having to consult a JavaScript truth
# table. Optionally only check if a variable is not `undefined`.
exports.Existence = class Existence extends Base
  constructor: (@expression, onlyNotUndefined = no) ->
    super()
    @comparisonTarget = if onlyNotUndefined then 'undefined' else 'null'
    salvagedComments = []
    @expression.traverseChildren yes, (child) ->
      if child.comments
        for comment in child.comments
          salvagedComments.push comment unless comment in salvagedComments
        delete child.comments
    attachCommentsToNode salvagedComments, @
    moveComments @expression, @

  children: ['expression']

  invert: NEGATE

  compileNode: (o) ->
    @expression.front = @front
    code = @expression.compile o, LEVEL_OP
    if @expression.unwrap() instanceof IdentifierLiteral and not o.scope.check code
      [cmp, cnj] = if @negated then ['===', '||'] else ['!==', '&&']
      code = "typeof #{code} #{cmp} \"undefined\"" + if @comparisonTarget isnt 'undefined' then " #{cnj} #{code} #{cmp} #{@comparisonTarget}" else ''
    else
      # We explicity want to use loose equality (`==`) when comparing against `null`,
      # so that an existence check roughly corresponds to a check for truthiness.
      # Do *not* change this to `===` for `null`, as this will break mountains of
      # existing code. When comparing only against `undefined`, however, we want to
      # use `===` because this use case is for parity with ES2015+ default values,
      # which only get assigned when the variable is `undefined` (but not `null`).
      cmp = if @comparisonTarget is 'null'
        if @negated then '==' else '!='
      else # `undefined`
        if @negated then '===' else '!=='
      code = "#{code} #{cmp} #{@comparisonTarget}"
    [@makeCode(if o.level <= LEVEL_COND then code else "(#{code})")]

  astType: -> 'UnaryExpression'

  astProperties: (o) ->
    return
      argument: @expression.ast o
      operator: '?'
      prefix: no

#### Parens

# An extra set of parentheses, specified explicitly in the source. At one time
# we tried to clean up the results by detecting and removing redundant
# parentheses, but no longer -- you can put in as many as you please.
#
# Parentheses are a good way to force any statement to become an expression.
exports.Parens = class Parens extends Base
  constructor: (@body) ->
    super()

  children: ['body']

  unwrap: -> @body

  shouldCache: -> @body.shouldCache()

  compileNode: (o) ->
    expr = @body.unwrap()
    # If these parentheses are wrapping an `IdentifierLiteral` followed by a
    # block comment, output the parentheses (or put another way, don’t optimize
    # away these redundant parentheses). This is because Flow requires
    # parentheses in certain circumstances to distinguish identifiers followed
    # by comment-based type annotations from JavaScript labels.
    shouldWrapComment = expr.comments?.some(
      (comment) -> comment.here and not comment.unshift and not comment.newLine)
    if expr instanceof Value and expr.isAtomic() and not @jsxAttribute and not shouldWrapComment
      expr.front = @front
      return expr.compileToFragments o
    fragments = expr.compileToFragments o, LEVEL_PAREN
    bare = o.level < LEVEL_OP and not shouldWrapComment and (
        expr instanceof Op and not expr.isInOperator() or expr.unwrap() instanceof Call or
        (expr instanceof For and expr.returns)
      ) and (o.level < LEVEL_COND or fragments.length <= 3)
    return @wrapInBraces fragments if @jsxAttribute
    if bare then fragments else @wrapInParentheses fragments

  astNode: (o) -> @body.unwrap().ast o, LEVEL_PAREN

#### StringWithInterpolations

exports.StringWithInterpolations = class StringWithInterpolations extends Base
  constructor: (@body, {@quote, @startQuote} = {}) ->
    super()

  @fromStringLiteral: (stringLiteral) ->
    updatedString = stringLiteral.withoutQuotesInLocationData()
    updatedStringValue = new Value(updatedString).withLocationDataFrom updatedString
    new StringWithInterpolations Block.wrap([updatedStringValue]), quote: stringLiteral.quote
    .withLocationDataFrom stringLiteral

  children: ['body']

  # `unwrap` returns `this` to stop ancestor nodes reaching in to grab @body,
  # and using @body.compileNode. `StringWithInterpolations.compileNode` is
  # _the_ custom logic to output interpolated strings as code.
  unwrap: -> this

  shouldCache: -> @body.shouldCache()

  extractElements: (o, {includeInterpolationWrappers, isJsx} = {}) ->
    # Assumes that `expr` is `Block`
    expr = @body.unwrap()

    elements = []
    salvagedComments = []
    expr.traverseChildren no, (node) =>
      if node instanceof StringLiteral
        if node.comments
          salvagedComments.push node.comments...
          delete node.comments
        elements.push node
        return yes
      else if node instanceof Interpolation
        if salvagedComments.length isnt 0
          for comment in salvagedComments
            comment.unshift = yes
            comment.newLine = yes
          attachCommentsToNode salvagedComments, node
        if (unwrapped = node.expression?.unwrapAll()) instanceof PassthroughLiteral and unwrapped.generated and not (isJsx and o.compiling)
          if o.compiling
            commentPlaceholder = new StringLiteral('').withLocationDataFrom node
            commentPlaceholder.comments = unwrapped.comments
            (commentPlaceholder.comments ?= []).push node.comments... if node.comments
            elements.push new Value commentPlaceholder
          else
            empty = new Interpolation().withLocationDataFrom node
            empty.comments = node.comments
            elements.push empty
        else if node.expression or includeInterpolationWrappers
          (node.expression?.comments ?= []).push node.comments... if node.comments
          elements.push if includeInterpolationWrappers then node else node.expression
        return no
      else if node.comments
        # This node is getting discarded, but salvage its comments.
        if elements.length isnt 0 and elements[elements.length - 1] not instanceof StringLiteral
          for comment in node.comments
            comment.unshift = no
            comment.newLine = yes
          attachCommentsToNode node.comments, elements[elements.length - 1]
        else
          salvagedComments.push node.comments...
        delete node.comments
      return yes

    elements

  compileNode: (o) ->
    @comments ?= @startQuote?.comments

    if @jsxAttribute
      wrapped = new Parens new StringWithInterpolations @body
      wrapped.jsxAttribute = yes
      return wrapped.compileNode o

    elements = @extractElements o, isJsx: @jsx

    fragments = []
    fragments.push @makeCode '`' unless @jsx
    for element in elements
      if element instanceof StringLiteral
        unquotedElementValue = if @jsx then element.unquotedValueForJSX else element.unquotedValueForTemplateLiteral
        fragments.push @makeCode unquotedElementValue
      else
        fragments.push @makeCode '$' unless @jsx
        code = element.compileToFragments(o, LEVEL_PAREN)
        if not @isNestedTag(element) or
           code.some((fragment) -> fragment.comments?.some((comment) -> comment.here is no))
          code = @wrapInBraces code
          # Flag the `{` and `}` fragments as having been generated by this
          # `StringWithInterpolations` node, so that `compileComments` knows
          # to treat them as bounds. But the braces are unnecessary if all of
          # the enclosed comments are `/* */` comments. Don’t trust
          # `fragment.type`, which can report minified variable names when
          # this compiler is minified.
          code[0].isStringWithInterpolations = yes
          code[code.length - 1].isStringWithInterpolations = yes
        fragments.push code...
    fragments.push @makeCode '`' unless @jsx
    fragments

  isNestedTag: (element) ->
    call = element.unwrapAll?()
    @jsx and call instanceof JSXElement

  astType: -> 'TemplateLiteral'

  astProperties: (o) ->
    elements = @extractElements o, includeInterpolationWrappers: yes
    [..., last] = elements

    quasis = []
    expressions = []

    for element, index in elements
      if element instanceof StringLiteral
        quasis.push new TemplateElement(
          element.originalValue
          tail: element is last
        ).withLocationDataFrom(element).ast o
      else # Interpolation
        {expression} = element
        node =
          unless expression?
            emptyInterpolation = new EmptyInterpolation()
            emptyInterpolation.locationData = emptyExpressionLocationData {
              interpolationNode: element
              openingBrace: '#{'
              closingBrace: '}'
            }
            emptyInterpolation
          else
            expression.unwrapAll()
        expressions.push astAsBlockIfNeeded node, o

    {expressions, quasis, @quote}

exports.TemplateElement = class TemplateElement extends Base
  constructor: (@value, {@tail} = {}) ->
    super()

  astProperties: ->
    return
      value:
        raw: @value
      tail: !!@tail

exports.Interpolation = class Interpolation extends Base
  constructor: (@expression) ->
    super()

  children: ['expression']

# Represents the contents of an empty interpolation (e.g. `#{}`).
# Only used during AST generation.
exports.EmptyInterpolation = class EmptyInterpolation extends Base
  constructor: ->
    super()

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
    super()
    @addBody body
    @addSource source

  children: ['body', 'source', 'guard', 'step']

  isAwait: -> @await ? no

  addBody: (body) ->
    @body = Block.wrap [body]
    {expressions} = @body
    if expressions.length
      @body.locationData ?= mergeLocationData expressions[0].locationData, expressions[expressions.length - 1].locationData
    this

  addSource: (source) ->
    {@source  = no} = source
    attribs   = ["name", "index", "guard", "step", "own", "ownTag", "await", "awaitTag", "object", "from"]
    @[attr]   = source[attr] ? @[attr] for attr in attribs
    return this unless @source
    @index.error 'cannot use index with for-from' if @from and @index
    @ownTag.error "cannot use own with for-#{if @from then 'from' else 'in'}" if @own and not @object
    [@name, @index] = [@index, @name] if @object
    @index.error 'index cannot be a pattern matching expression' if @index?.isArray?() or @index?.isObject?()
    @awaitTag.error 'await must be used with for-from' if @await and not @from
    @range   = @source instanceof Value and @source.base instanceof Range and not @source.properties.length and not @from
    @pattern = @name instanceof Value
    @name.unwrap().propagateLhs?(yes) if @pattern
    @index.error 'indexes do not apply to range loops' if @range and @index
    @name.error 'cannot pattern match over range loops' if @range and @pattern
    @returns = no
    # Move up any comments in the “`for` line”, i.e. the line of code with `for`,
    # from any child nodes of that line up to the `for` node itself so that these
    # comments get output, and get output above the `for` loop.
    for attribute in ['source', 'guard', 'step', 'name', 'index'] when @[attribute]
      @[attribute].traverseChildren yes, (node) =>
        if node.comments
          # These comments are buried pretty deeply, so if they happen to be
          # trailing comments the line they trail will be unrecognizable when
          # we’re done compiling this `for` loop; so just shift them up to
          # output above the `for` line.
          comment.newLine = comment.unshift = yes for comment in node.comments
          moveComments node, @[attribute]
      moveComments @[attribute], @
    this

  # Welcome to the hairiest method in all of CoffeeScript. Handles the inner
  # loop, filtering, stepping, and result saving for array, object, and range
  # comprehensions. Some of the generated code can be shared in common, and
  # some cannot.
  compileNode: (o) ->
    body        = Block.wrap [@body]
    [..., last] = body.expressions
    @returns    = no if last?.jumps() instanceof Return
    source      = if @range then @source.base else @source
    scope       = o.scope
    name        = @name  and (@name.compile o, LEVEL_LIST) if not @pattern
    index       = @index and (@index.compile o, LEVEL_LIST)
    scope.find(name)  if name and not @pattern
    scope.find(index) if index and @index not instanceof Value
    rvar        = scope.freeVariable 'results' if @returns
    if @from
      ivar = scope.freeVariable 'x', single: true if @pattern
    else
      ivar = (@object and index) or scope.freeVariable 'i', single: true
    kvar        = ((@range or @from) and name) or index or ivar
    kvarAssign  = if kvar isnt ivar then "#{kvar} = " else ""
    if @step and not @range
      [step, stepVar] = @cacheToCodeFragments @step.cache o, LEVEL_LIST, shouldCacheOrIsAssignable
      stepNum   = parseNumber stepVar if @step.isNumber()
    name        = ivar if @pattern
    varPart     = ''
    guardPart   = ''
    defPart     = ''
    idt1        = @tab + TAB
    if @range
      forPartFragments = source.compileToFragments merge o,
        {index: ivar, name, @step, shouldCache: shouldCacheOrIsAssignable}
    else
      svar    = @source.compile o, LEVEL_LIST
      if (name or @own) and @source.unwrap() not instanceof IdentifierLiteral
        defPart    += "#{@tab}#{ref = scope.freeVariable 'ref'} = #{svar};\n"
        svar       = ref
      if name and not @pattern and not @from
        namePart   = "#{name} = #{svar}[#{kvar}]"
      if not @object and not @from
        defPart += "#{@tab}#{step};\n" if step isnt stepVar
        down = stepNum < 0
        lvar = scope.freeVariable 'len' unless @step and stepNum? and down
        declare = "#{kvarAssign}#{ivar} = 0, #{lvar} = #{svar}.length"
        declareDown = "#{kvarAssign}#{ivar} = #{svar}.length - 1"
        compare = "#{ivar} < #{lvar}"
        compareDown = "#{ivar} >= 0"
        if @step
          if stepNum?
            if down
              compare = compareDown
              declare = declareDown
          else
            compare = "#{stepVar} > 0 ? #{compare} : #{compareDown}"
            declare = "(#{stepVar} > 0 ? (#{declare}) : #{declareDown})"
          increment = "#{ivar} += #{stepVar}"
        else
          increment = "#{if kvar isnt ivar then "++#{ivar}" else "#{ivar}++"}"
        forPartFragments = [@makeCode("#{declare}; #{compare}; #{kvarAssign}#{increment}")]
    if @returns
      resultPart   = "#{@tab}#{rvar} = [];\n"
      returnResult = "\n#{@tab}return #{rvar};"
      body.makeReturn rvar
    if @guard
      if body.expressions.length > 1
        body.expressions.unshift new If (new Parens @guard).invert(), new StatementLiteral "continue"
      else
        body = Block.wrap [new If @guard, body] if @guard
    if @pattern
      body.expressions.unshift new Assign @name, if @from then new IdentifierLiteral kvar else new Literal "#{svar}[#{kvar}]"

    varPart = "\n#{idt1}#{namePart};" if namePart
    if @object
      forPartFragments = [@makeCode("#{kvar} in #{svar}")]
      guardPart = "\n#{idt1}if (!#{utility 'hasProp', o}.call(#{svar}, #{kvar})) continue;" if @own
    else if @from
      if @await
        forPartFragments = new Op 'await', new Parens new Literal "#{kvar} of #{svar}"
        forPartFragments = forPartFragments.compileToFragments o, LEVEL_TOP
      else
        forPartFragments = [@makeCode("#{kvar} of #{svar}")]
    bodyFragments = body.compileToFragments merge(o, indent: idt1), LEVEL_TOP
    if bodyFragments and bodyFragments.length > 0
      bodyFragments = [].concat @makeCode('\n'), bodyFragments, @makeCode('\n')

    fragments = [@makeCode(defPart)]
    fragments.push @makeCode(resultPart) if resultPart
    forCode = if @await then 'for ' else 'for ('
    forClose = if @await then '' else ')'
    fragments = fragments.concat @makeCode(@tab), @makeCode( forCode),
      forPartFragments, @makeCode("#{forClose} {#{guardPart}#{varPart}"), bodyFragments,
      @makeCode(@tab), @makeCode('}')
    fragments.push @makeCode(returnResult) if returnResult
    fragments

  astNode: (o) ->
    addToScope = (name) ->
      alreadyDeclared = o.scope.find name.value
      name.isDeclaration = not alreadyDeclared
    @name?.eachName addToScope, checkAssignability: no
    @index?.eachName addToScope, checkAssignability: no
    super o

  astType: -> 'For'

  astProperties: (o) ->
    return
      source: @source?.ast o
      body: @body.ast o, LEVEL_TOP
      guard: @guard?.ast(o) ? null
      name: @name?.ast(o) ? null
      index: @index?.ast(o) ? null
      step: @step?.ast(o) ? null
      postfix: !!@postfix
      own: !!@own
      await: !!@await
      style: switch
        when @from   then 'from'
        when @object then 'of'
        when @name   then 'in'
        else              'range'

#### Switch

# A JavaScript *switch* statement. Converts into a returnable expression on-demand.
exports.Switch = class Switch extends Base
  constructor: (@subject, @cases, @otherwise) ->
    super()

  children: ['subject', 'cases', 'otherwise']

  isStatement: YES

  jumps: (o = {block: yes}) ->
    for {block} in @cases
      return jumpNode if jumpNode = block.jumps o
    @otherwise?.jumps o

  makeReturn: (results, mark) ->
    block.makeReturn(results, mark) for {block} in @cases
    @otherwise or= new Block [new Literal 'void 0'] if results
    @otherwise?.makeReturn results, mark
    this

  compileNode: (o) ->
    idt1 = o.indent + TAB
    idt2 = o.indent = idt1 + TAB
    fragments = [].concat @makeCode(@tab + "switch ("),
      (if @subject then @subject.compileToFragments(o, LEVEL_PAREN) else @makeCode "false"),
      @makeCode(") {\n")
    for {conditions, block}, i in @cases
      for cond in flatten [conditions]
        cond  = cond.invert() unless @subject
        fragments = fragments.concat @makeCode(idt1 + "case "), cond.compileToFragments(o, LEVEL_PAREN), @makeCode(":\n")
      fragments = fragments.concat body, @makeCode('\n') if (body = block.compileToFragments o, LEVEL_TOP).length > 0
      break if i is @cases.length - 1 and not @otherwise
      expr = @lastNode block.expressions
      continue if expr instanceof Return or expr instanceof Throw or (expr instanceof Literal and expr.jumps() and expr.value isnt 'debugger')
      fragments.push cond.makeCode(idt2 + 'break;\n')
    if @otherwise and @otherwise.expressions.length
      fragments.push @makeCode(idt1 + "default:\n"), (@otherwise.compileToFragments o, LEVEL_TOP)..., @makeCode("\n")
    fragments.push @makeCode @tab + '}'
    fragments

  astType: -> 'SwitchStatement'

  casesAst: (o) ->
    cases = []

    for kase, caseIndex in @cases
      {conditions: tests, block: consequent} = kase
      tests = flatten [tests]
      lastTestIndex = tests.length - 1
      for test, testIndex in tests
        testConsequent =
          if testIndex is lastTestIndex
            consequent
          else
            null

        caseLocationData = test.locationData
        caseLocationData = mergeLocationData caseLocationData, testConsequent.expressions[testConsequent.expressions.length - 1].locationData if testConsequent?.expressions.length
        caseLocationData = mergeLocationData caseLocationData, kase.locationData, justLeading: yes if testIndex is 0
        caseLocationData = mergeLocationData caseLocationData, kase.locationData, justEnding:  yes if testIndex is lastTestIndex

        cases.push new SwitchCase(test, testConsequent, trailing: testIndex is lastTestIndex).withLocationDataFrom locationData: caseLocationData

    if @otherwise?.expressions.length
      cases.push new SwitchCase(null, @otherwise).withLocationDataFrom @otherwise

    kase.ast(o) for kase in cases

  astProperties: (o) ->
    return
      discriminant: @subject?.ast(o, LEVEL_PAREN) ? null
      cases: @casesAst o

class SwitchCase extends Base
  constructor: (@test, @block, {@trailing} = {}) ->
    super()

  children: ['test', 'block']

  astProperties: (o) ->
    return
      test: @test?.ast(o, LEVEL_PAREN) ? null
      consequent: @block?.ast(o, LEVEL_TOP).body ? []
      trailing: !!@trailing

exports.SwitchWhen = class SwitchWhen extends Base
  constructor: (@conditions, @block) ->
    super()

  children: ['conditions', 'block']

#### If

# *If/else* statements. Acts as an expression by pushing down requested returns
# to the last line of each clause.
#
# Single-expression **Ifs** are compiled into conditional operators if possible,
# because ternaries are already proper expressions, and don’t need conversion.
exports.If = class If extends Base
  constructor: (@condition, @body, options = {}) ->
    super()
    @elseBody  = null
    @isChain   = false
    {@soak, @postfix, @type} = options
    moveComments @condition, @ if @condition.comments

  children: ['condition', 'body', 'elseBody']

  bodyNode:     -> @body?.unwrap()
  elseBodyNode: -> @elseBody?.unwrap()

  # Rewrite a chain of **Ifs** to add a default case as the final *else*.
  addElse: (elseBody) ->
    if @isChain
      @elseBodyNode().addElse elseBody
      @locationData = mergeLocationData @locationData, @elseBodyNode().locationData
    else
      @isChain  = elseBody instanceof If
      @elseBody = @ensureBlock elseBody
      @elseBody.updateLocationDataIfMissing elseBody.locationData
      @locationData = mergeLocationData @locationData, @elseBody.locationData if @locationData? and @elseBody.locationData?
    this

  # The **If** only compiles into a statement if either of its bodies needs
  # to be a statement. Otherwise a conditional operator is safe.
  isStatement: (o) ->
    o?.level is LEVEL_TOP or
      @bodyNode().isStatement(o) or @elseBodyNode()?.isStatement(o)

  jumps: (o) -> @body.jumps(o) or @elseBody?.jumps(o)

  compileNode: (o) ->
    if @isStatement o then @compileStatement o else @compileExpression o

  makeReturn: (results, mark) ->
    if mark
      @body?.makeReturn results, mark
      @elseBody?.makeReturn results, mark
      return
    @elseBody  or= new Block [new Literal 'void 0'] if results
    @body     and= new Block [@body.makeReturn results]
    @elseBody and= new Block [@elseBody.makeReturn results]
    this

  ensureBlock: (node) ->
    if node instanceof Block then node else new Block [node]

  # Compile the `If` as a regular *if-else* statement. Flattened chains
  # force inner *else* bodies into statement form.
  compileStatement: (o) ->
    child    = del o, 'chainChild'
    exeq     = del o, 'isExistentialEquals'

    if exeq
      return new If(@processedCondition().invert(), @elseBodyNode(), type: 'if').compileToFragments o

    indent   = o.indent + TAB
    cond     = @processedCondition().compileToFragments o, LEVEL_PAREN
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
    cond = @processedCondition().compileToFragments o, LEVEL_COND
    body = @bodyNode().compileToFragments o, LEVEL_LIST
    alt  = if @elseBodyNode() then @elseBodyNode().compileToFragments(o, LEVEL_LIST) else [@makeCode('void 0')]
    fragments = cond.concat @makeCode(" ? "), body, @makeCode(" : "), alt
    if o.level >= LEVEL_COND then @wrapInParentheses fragments else fragments

  unfoldSoak: ->
    @soak and this

  processedCondition: ->
    @processedConditionCache ?= if @type is 'unless' then @condition.invert() else @condition

  isStatementAst: (o) ->
    o.level is LEVEL_TOP

  astType: (o) ->
    if @isStatementAst o
      'IfStatement'
    else
      'ConditionalExpression'

  astProperties: (o) ->
    isStatement = @isStatementAst o

    return
      test: @condition.ast o, if isStatement then LEVEL_PAREN else LEVEL_COND
      consequent:
        if isStatement
          @body.ast o, LEVEL_TOP
        else
          @bodyNode().ast o, LEVEL_TOP
      alternate:
        if @isChain
          @elseBody.unwrap().ast o, if isStatement then LEVEL_TOP else LEVEL_COND
        else if not isStatement and @elseBody?.expressions?.length is 1
          @elseBody.expressions[0].ast o, LEVEL_TOP
        else
          @elseBody?.ast(o, LEVEL_TOP) ? null
      postfix: !!@postfix
      inverted: @type is 'unless'

# A sequence expression e.g. `(a; b)`.
# Currently only used during AST generation.
exports.Sequence = class Sequence extends Base
  children: ['expressions']

  constructor: (@expressions) ->
    super()

  astNode: (o) ->
    return @expressions[0].ast(o) if @expressions.length is 1
    super o

  astType: -> 'SequenceExpression'

  astProperties: (o) ->
    return
      expressions:
        expression.ast(o) for expression in @expressions

# Constants
# ---------

UTILITIES =
  modulo: -> 'function(a, b) { return (+a % (b = +b) + b) % b; }'

  boundMethodCheck: -> "
    function(instance, Constructor) {
      if (!(instance instanceof Constructor)) {
        throw new Error('Bound instance method accessed before binding');
      }
    }
  "

  # Shortcuts to speed up the lookup time for native functions.
  hasProp: -> '{}.hasOwnProperty'
  indexOf: -> '[].indexOf'
  slice  : -> '[].slice'
  splice : -> '[].splice'

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

SIMPLENUM = /^[+-]?\d+$/
SIMPLE_STRING_OMIT = /\s*\n\s*/g
LEADING_BLANK_LINE  = /^[^\n\S]*\n/
TRAILING_BLANK_LINE = /\n[^\n\S]*$/
STRING_OMIT    = ///
    ((?:\\\\)+)      # Consume (and preserve) an even number of backslashes.
  | \\[^\S\n]*\n\s*  # Remove escaped newlines.
///g
HEREGEX_OMIT = ///
    ((?:\\\\)+)     # Consume (and preserve) an even number of backslashes.
  | \\(\s)          # Preserve escaped whitespace.
  | \s+(?:#.*)?     # Remove whitespace and comments.
///g

# Helper Functions
# ----------------

# Helper for ensuring that utility functions are assigned at the top level.
utility = (name, o) ->
  {root} = o.scope
  if name of root.utilities
    root.utilities[name]
  else
    ref = root.freeVariable name
    root.assign ref, UTILITIES[name] o
    root.utilities[name] = ref

multident = (code, tab, includingFirstLine = yes) ->
  endsWithNewLine = code[code.length - 1] is '\n'
  code = (if includingFirstLine then tab else '') + code.replace /\n/g, "$&#{tab}"
  code = code.replace /\s+$/, ''
  code = code + '\n' if endsWithNewLine
  code

# Wherever in CoffeeScript 1 we might’ve inserted a `makeCode "#{@tab}"` to
# indent a line of code, now we must account for the possibility of comments
# preceding that line of code. If there are such comments, indent each line of
# such comments, and _then_ indent the first following line of code.
indentInitial = (fragments, node) ->
  for fragment, fragmentIndex in fragments
    if fragment.isHereComment
      fragment.code = multident fragment.code, node.tab
    else
      fragments.splice fragmentIndex, 0, node.makeCode "#{node.tab}"
      break
  fragments

hasLineComments = (node) ->
  return no unless node.comments
  for comment in node.comments
    return yes if comment.here is no
  return no

# Move the `comments` property from one object to another, deleting it from
# the first object.
moveComments = (from, to) ->
  return unless from?.comments
  attachCommentsToNode from.comments, to
  delete from.comments

# Sometimes when compiling a node, we want to insert a fragment at the start
# of an array of fragments; but if the start has one or more comment fragments,
# we want to insert this fragment after those but before any non-comments.
unshiftAfterComments = (fragments, fragmentToInsert) ->
  inserted = no
  for fragment, fragmentIndex in fragments when not fragment.isComment
    fragments.splice fragmentIndex, 0, fragmentToInsert
    inserted = yes
    break
  fragments.push fragmentToInsert unless inserted
  fragments

isLiteralArguments = (node) ->
  node instanceof IdentifierLiteral and node.value is 'arguments'

isLiteralThis = (node) ->
  node instanceof ThisLiteral or (node instanceof Code and node.bound)

shouldCacheOrIsAssignable = (node) -> node.shouldCache() or node.isAssignable?()

# Unfold a node's child if soak, then tuck the node under created `If`
unfoldSoak = (o, parent, name) ->
  return unless ifn = parent[name].unfoldSoak o
  parent[name] = ifn.body
  ifn.body = new Value parent
  ifn

# Constructs a string or regex by escaping certain characters.
makeDelimitedLiteral = (body, {delimiter: delimiterOption, escapeNewlines, double, includeDelimiters = yes, escapeDelimiter = yes, convertTrailingNullEscapes} = {}) ->
  body = '(?:)' if body is '' and delimiterOption is '/'
  escapeTemplateLiteralCurlies = delimiterOption is '`'
  regex = ///
      (\\\\)                               # Escaped backslash.
    | (\\0(?=\d))                          # Null character mistaken as octal escape.
    #{
      if convertTrailingNullEscapes
        /// | (\\0) $ ///.source           # Trailing null character that could be mistaken as octal escape.
      else
        ''
    }
    #{
      if escapeDelimiter
        /// | \\?(#{delimiterOption}) ///.source # (Possibly escaped) delimiter.
      else
        ''
    }
    #{
      if escapeTemplateLiteralCurlies
        /// | \\?(\$\{) ///.source         # `${` inside template literals must be escaped.
      else
        ''
    }
    | \\?(?:
        #{if escapeNewlines then '(\n)|' else ''}
          (\r)
        | (\u2028)
        | (\u2029)
      )                                    # (Possibly escaped) newlines.
    | (\\.)                                # Other escapes.
  ///g
  body = body.replace regex, (match, backslash, nul, ...args) ->
    trailingNullEscape =
      args.shift() if convertTrailingNullEscapes
    delimiter =
      args.shift() if escapeDelimiter
    templateLiteralCurly =
      args.shift() if escapeTemplateLiteralCurlies
    lf =
      args.shift() if escapeNewlines
    [cr, ls, ps, other] = args
    switch
      # Ignore escaped backslashes.
      when backslash then (if double then backslash + backslash else backslash)
      when nul                  then '\\x00'
      when trailingNullEscape   then "\\x00"
      when delimiter            then "\\#{delimiter}"
      when templateLiteralCurly then "\\${"
      when lf                   then '\\n'
      when cr                   then '\\r'
      when ls                   then '\\u2028'
      when ps                   then '\\u2029'
      when other                then (if double then "\\#{other}" else other)
  printedDelimiter = if includeDelimiters then delimiterOption else ''
  "#{printedDelimiter}#{body}#{printedDelimiter}"

sniffDirectives = (expressions, {notFinalExpression} = {}) ->
  index = 0
  lastIndex = expressions.length - 1
  while index <= lastIndex
    break if index is lastIndex and notFinalExpression
    expression = expressions[index]
    if (unwrapped = expression?.unwrap?()) instanceof PassthroughLiteral and unwrapped.generated
      index++
      continue
    break unless expression instanceof Value and expression.isString() and not expression.unwrap().shouldGenerateTemplateLiteral()
    expressions[index] =
      new Directive expression
      .withLocationDataFrom expression
    index++

astAsBlockIfNeeded = (node, o) ->
  unwrapped = node.unwrap()
  if unwrapped instanceof Block and unwrapped.expressions.length > 1
    unwrapped.makeReturn null, yes
    unwrapped.ast o, LEVEL_TOP
  else
    node.ast o, LEVEL_PAREN

# Helpers for `mergeLocationData` and `mergeAstLocationData` below.
lesser  = (a, b) -> if a < b then a else b
greater = (a, b) -> if a > b then a else b

isAstLocGreater = (a, b) ->
  return yes if a.line > b.line
  return no unless a.line is b.line
  a.column > b.column

isLocationDataStartGreater = (a, b) ->
  return yes if a.first_line > b.first_line
  return no unless a.first_line is b.first_line
  a.first_column > b.first_column

isLocationDataEndGreater = (a, b) ->
  return yes if a.last_line > b.last_line
  return no unless a.last_line is b.last_line
  a.last_column > b.last_column

# Take two nodes’ location data and return a new `locationData` object that
# encompasses the location data of both nodes. So the new `first_line` value
# will be the earlier of the two nodes’ `first_line` values, the new
# `last_column` the later of the two nodes’ `last_column` values, etc.
#
# If you only want to extend the first node’s location data with the start or
# end location data of the second node, pass the `justLeading` or `justEnding`
# options. So e.g. if `first`’s range is [4, 5] and `second`’s range is [1, 10],
# you’d get:
# ```
# mergeLocationData(first, second).range                   # [1, 10]
# mergeLocationData(first, second, justLeading: yes).range # [1, 5]
# mergeLocationData(first, second, justEnding:  yes).range # [4, 10]
# ```
exports.mergeLocationData = mergeLocationData = (locationDataA, locationDataB, {justLeading, justEnding} = {}) ->
  return Object.assign(
    if justEnding
      first_line:   locationDataA.first_line
      first_column: locationDataA.first_column
    else
      if isLocationDataStartGreater locationDataA, locationDataB
        first_line:   locationDataB.first_line
        first_column: locationDataB.first_column
      else
        first_line:   locationDataA.first_line
        first_column: locationDataA.first_column
  ,
    if justLeading
      last_line:             locationDataA.last_line
      last_column:           locationDataA.last_column
      last_line_exclusive:   locationDataA.last_line_exclusive
      last_column_exclusive: locationDataA.last_column_exclusive
    else
      if isLocationDataEndGreater locationDataA, locationDataB
        last_line:             locationDataA.last_line
        last_column:           locationDataA.last_column
        last_line_exclusive:   locationDataA.last_line_exclusive
        last_column_exclusive: locationDataA.last_column_exclusive
      else
        last_line:             locationDataB.last_line
        last_column:           locationDataB.last_column
        last_line_exclusive:   locationDataB.last_line_exclusive
        last_column_exclusive: locationDataB.last_column_exclusive
  ,
    range: [
      if justEnding
        locationDataA.range[0]
      else
        lesser locationDataA.range[0], locationDataB.range[0]
    ,
      if justLeading
        locationDataA.range[1]
      else
        greater locationDataA.range[1], locationDataB.range[1]
    ]
  )

# Take two AST nodes, or two AST nodes’ location data objects, and return a new
# location data object that encompasses the location data of both nodes. So the
# new `start` value will be the earlier of the two nodes’ `start` values, the
# new `end` value will be the later of the two nodes’ `end` values, etc.
#
# If you only want to extend the first node’s location data with the start or
# end location data of the second node, pass the `justLeading` or `justEnding`
# options. So e.g. if `first`’s range is [4, 5] and `second`’s range is [1, 10],
# you’d get:
# ```
# mergeAstLocationData(first, second).range                   # [1, 10]
# mergeAstLocationData(first, second, justLeading: yes).range # [1, 5]
# mergeAstLocationData(first, second, justEnding:  yes).range # [4, 10]
# ```
exports.mergeAstLocationData = mergeAstLocationData = (nodeA, nodeB, {justLeading, justEnding} = {}) ->
  return
    loc:
      start:
        if justEnding
          nodeA.loc.start
        else
          if isAstLocGreater nodeA.loc.start, nodeB.loc.start
            nodeB.loc.start
          else
            nodeA.loc.start
      end:
        if justLeading
          nodeA.loc.end
        else
          if isAstLocGreater nodeA.loc.end, nodeB.loc.end
            nodeA.loc.end
          else
            nodeB.loc.end
    range: [
      if justEnding
        nodeA.range[0]
      else
        lesser nodeA.range[0], nodeB.range[0]
    ,
      if justLeading
        nodeA.range[1]
      else
        greater nodeA.range[1], nodeB.range[1]
    ]
    start:
      if justEnding
        nodeA.start
      else
        lesser nodeA.start, nodeB.start
    end:
      if justLeading
        nodeA.end
      else
        greater nodeA.end, nodeB.end

# Convert Jison-style node class location data to Babel-style location data
exports.jisonLocationDataToAstLocationData = jisonLocationDataToAstLocationData = ({first_line, first_column, last_line_exclusive, last_column_exclusive, range}) ->
  return
    loc:
      start:
        line:   first_line + 1
        column: first_column
      end:
        line:   last_line_exclusive + 1
        column: last_column_exclusive
    range: [
      range[0]
      range[1]
    ]
    start: range[0]
    end:   range[1]

# Generate a zero-width location data that corresponds to the end of another node’s location.
zeroWidthLocationDataFromEndLocation = ({range: [, endRange], last_line_exclusive, last_column_exclusive}) -> {
  first_line: last_line_exclusive
  first_column: last_column_exclusive
  last_line: last_line_exclusive
  last_column: last_column_exclusive
  last_line_exclusive
  last_column_exclusive
  range: [endRange, endRange]
}

extractSameLineLocationDataFirst = (numChars) -> ({range: [startRange], first_line, first_column}) -> {
  first_line
  first_column
  last_line: first_line
  last_column: first_column + numChars - 1
  last_line_exclusive: first_line
  last_column_exclusive: first_column + numChars
  range: [startRange, startRange + numChars]
}

extractSameLineLocationDataLast = (numChars) -> ({range: [, endRange], last_line, last_column, last_line_exclusive, last_column_exclusive}) -> {
  first_line: last_line
  first_column: last_column - (numChars - 1)
  last_line: last_line
  last_column: last_column
  last_line_exclusive
  last_column_exclusive
  range: [endRange - numChars, endRange]
}

# We don’t currently have a token corresponding to the empty space
# between interpolation/JSX expression braces, so piece together the location
# data by trimming the braces from the Interpolation’s location data.
# Technically the last_line/last_column calculation here could be
# incorrect if the ending brace is preceded by a newline, but
# last_line/last_column aren’t used for AST generation anyway.
emptyExpressionLocationData = ({interpolationNode: element, openingBrace, closingBrace}) ->
  first_line:            element.locationData.first_line
  first_column:          element.locationData.first_column + openingBrace.length
  last_line:             element.locationData.last_line
  last_column:           element.locationData.last_column - closingBrace.length
  last_line_exclusive:   element.locationData.last_line
  last_column_exclusive: element.locationData.last_column
  range: [
    element.locationData.range[0] + openingBrace.length
    element.locationData.range[1] - closingBrace.length
  ]
