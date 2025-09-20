#!/usr/bin/env coffee

# ==============================================================================
# CS3 ES5 Backend - Clean Room Implementation
# ==============================================================================
#
# Converts CS3 data-oriented AST nodes to CoffeeScript's class-based AST nodes
# Then uses the existing CoffeeScript compiler to generate JavaScript
#
# Key fixes in this version:
# 1. Loop variable conflict prevention
# 2. Proper super call handling
# 3. Array elision support
# ==============================================================================

nodes = require './nodes'

class ES5Backend
  constructor: (@options = {}) ->
    @compileOptions =
      bare: true  # CS3 always outputs bare (no wrapper) - modern JS doesn't need it
      cs3: true  # CS3 always uses ES6 features
      header: @options.header ? false
      sourceMap: @options.sourceMap ? false
      inlineMap: @options.inlineMap ? false
      # Signal to nodes compiler that we're in CS3 pipeline, so it can relax
      # early "this-before-super" checks to let our lowering run.
      cs3: true

    # Track unique variable allocation for nested for-loops
    @loopVarCounter = 0
    @usedLoopVars = new Set()

  # Main entry point - convert Solar directive or CoffeeScript node to JavaScript
  generate: (node) ->
    # If already a CoffeeScript class node (from ReductionFrame), compile directly
    if node?.compile
      result = node.compile @compileOptions
      return result or ''

    # For ES6 mode with data nodes, do variable analysis first
    if @compileOptions.cs3 and node? and typeof node is 'object' and not node.compile
      @variableInfo = @analyzeVariables(node)

    # Otherwise, convert via legacy dataToClass method
    classNode = @dataToClass node
    return '' unless classNode?

    result = classNode.compile @compileOptions
    return result or ''

  # Helper to create default locationData
  defaultLocationData: ->
    first_line: 0
    first_column: 0
    last_line: 0
    last_column: 0
    last_line_exclusive: 0
    last_column_exclusive: 0
    range: [0, 0]

  # Analyze variables in the directive tree for const/let determination
  analyzeVariables: (directive, info = {declarations: {}, assignments: {}, scopes: []}) ->
    return info unless directive?

    # Handle arrays
    if Array.isArray directive
      for item in directive
        @analyzeVariables item, info
      return info

    # Handle objects/directives
    if typeof directive is 'object'
      # Check for variable assignments
      if directive.type is 'Assign'
        varName = directive.variable?.base?.value
        if varName and typeof varName is 'string'
          if directive.context  # Compound assignment (+=, -=, etc.)
            info.assignments[varName] = (info.assignments[varName] or 0) + 1
          else if info.declarations[varName]
            # Reassignment
            info.assignments[varName] = (info.assignments[varName] or 0) + 1
          else
            # First assignment (declaration)
            info.declarations[varName] = true

      # Check for loop variables
      else if directive.type is 'For'
        # Loop variables are always mutable in CoffeeScript due to hoisting
        if directive.name?.value
          info.declarations[directive.name.value] = true
          info.assignments[directive.name.value] = 1  # Mark as reassigned
        if directive.index?.value
          info.declarations[directive.index.value] = true
          info.assignments[directive.index.value] = 1  # Mark as reassigned

      # Recursively analyze all properties
      for key, value of directive when not key.startsWith '$pos'
        @analyzeVariables value, info

    info

  # Generate unique variable names for loop iterators
  getUniqueLoopVar: ->
    # Start with less common letters, since i and j are commonly used by users
    set = 'klmnopqrstuvwxyz'
    idx = @loopVarCounter % set.length
    num = Math.floor(@loopVarCounter / set.length)
    use = "#{set[idx]}#{num or ''}"

    @loopVarCounter++
    @usedLoopVars.add use
    use

  # Helper to strip common indentation from heredoc strings
  stripHeredocIndentation: (value, quote) ->
    return value unless quote in ['"""', "'''"] and typeof value is 'string'

    lines = value.split('\n')
    return value if lines.length <= 1

    # Find minimum indentation (excluding empty lines)
    minIndent = Infinity
    for line in lines[1..]  # Skip first line
      if line.trim().length > 0
        leadingSpaces = line.match(/^[ \t]*/)[0].length
        minIndent = Math.min(minIndent, leadingSpaces)

    # Strip common indentation from all lines except the first
    if minIndent > 0 and minIndent < Infinity
      for i in [1...lines.length]
        lines[i] = lines[i].slice(minIndent)
      lines.join('\n')
    else
      value

  # Helper to deep flatten arrays recursively
  deepFlatten: (arr) ->
    result = []
    for item in arr
      if Array.isArray(item)
        flattened = @deepFlatten(item)
        for sub in flattened
          result.push sub
      else
        result.push item
    result

  # Helper to ensure value is an array
  toArray: (value) ->
    if Array.isArray(value) then value else (if value? then [value] else [])

  # Helper to check if value is a node (performance optimization)
  isNode: (value) ->
    value instanceof nodes.Base

  # Helper to convert any value to a proper node
  toNode: (value) ->
    return null unless value?
    return value if @isNode(value)
    return @solarNodeToClass(value) if value?.type
    @ensureNode(value)

  # Helper to convert value to a Block node
  toBlock: (value) ->
    if Array.isArray(value)
      new nodes.Block @filterNodes(value)
    else if value instanceof nodes.Block
      value
    else if value?
      new nodes.Block [@ensureNode(value)]
    else
      new nodes.Block []

  # ==============================================================================
  # NODE CREATION METHODS - Extracted from main switch for clarity
  # ==============================================================================

  createLiteral: (directive, frame, ruleName) ->
    value = @evaluateDirective directive.value, frame, ruleName
    new nodes.Literal value

  createIdentifierLiteral: (directive, frame, ruleName) ->
    value = @evaluateDirective directive.value, frame, ruleName
    node = new nodes.IdentifierLiteral value
    node.locationData ?= @defaultLocationData()
    node

  createNumberLiteral: (directive, frame, ruleName) ->
    value = @evaluateDirective directive.value, frame, ruleName
    parsedValue = @evaluateDirective directive.parsedValue, frame, ruleName
    # Strip underscores from numeric literals for compatibility
    cleanValue = if typeof value is 'string' then value.replace(/_/g, '') else value
    node = new nodes.NumberLiteral cleanValue, parsedValue
    node.locationData ?= @defaultLocationData()
    node

  createBooleanLiteral: (directive, frame, ruleName) ->
    value = @evaluateDirective directive.value, frame, ruleName
    new nodes.BooleanLiteral value

  createNullLiteral: ->
    new nodes.NullLiteral()

  createUndefinedLiteral: ->
    new nodes.UndefinedLiteral()

  createThisLiteral: ->
    node = new nodes.ThisLiteral()
    node.locationData ?= @defaultLocationData()
    node

  createStringLiteral: (directive, frame, ruleName) ->
    value = @evaluateDirective directive.value, frame, ruleName
    quote = @evaluateDirective directive.quote, frame, ruleName

    # Strip the surrounding quotes from the value if present
    if value and typeof value is 'string' and value.length >= 2
      if (value[0] is '"' and value[value.length - 1] is '"') or
         (value[0] is "'" and value[value.length - 1] is "'")
        value = value.slice(1, -1)

    # Handle triple-quoted strings (heredocs)
    value = @stripHeredocIndentation(value, quote)

    node = new nodes.StringLiteral value, {quote}
    node.locationData ?= @defaultLocationData()
    node

  createArr: (directive, frame, ruleName) ->
    objects = @evaluateDirective directive.objects, frame, ruleName
    objects = @filterNodes @toArray(objects)
    arr = new nodes.Arr objects
    arr.locationData ?= @defaultLocationData()
    arr

  createPropertyName: (directive, frame, ruleName) ->
    value = @evaluateDirective directive.value, frame, ruleName
    new nodes.PropertyName(value or '')

  createIf: (directive, frame, ruleName, defaultType = 'if') ->
    condition = @evaluateDirective directive.condition, frame, ruleName
    body      = @evaluateDirective directive.body, frame, ruleName
    elseBody  = @evaluateDirective directive.elseBody, frame, ruleName
    type      = @evaluateDirective(directive.type, frame, ruleName) or defaultType
    postfix   = @evaluateDirective directive.postfix, frame, ruleName

    bodyNode = @toBlock(body)
    bodyNode.locationData ?= @defaultLocationData() if bodyNode
    elseNode = if elseBody then @toBlock(elseBody) else null
    elseNode.locationData ?= @defaultLocationData() if elseNode

    opts = {}
    opts.type = type if type is 'unless'
    opts.postfix = postfix if postfix

    ifNode = new nodes.If condition, bodyNode, opts
    ifNode.locationData ?= @defaultLocationData()

    if elseNode
      ifNode.addElse elseNode

    ifNode

  createReturn: (directive, frame, ruleName) ->
    expression = @evaluateDirective directive.expression, frame, ruleName
    new nodes.Return expression

  createYield: (directive, frame, ruleName) ->
    expression = @evaluateDirective directive.expression, frame, ruleName
    from       = @evaluateDirective directive.from, frame, ruleName
    new nodes.Yield expression, from

  createSlice: (directive, frame, ruleName) ->
    range = @evaluateDirective directive.range, frame, ruleName
    new nodes.Slice range

  createThrow: (directive, frame, ruleName) ->
    expression = @evaluateDirective directive.expression, frame, ruleName
    new nodes.Throw(@ensureNode(expression) or new nodes.Literal 'undefined')

  createAwait: (directive, frame, ruleName) ->
    expression = @evaluateDirective directive.expression, frame, ruleName
    new nodes.Await expression

  createYieldFrom: (directive, frame, ruleName) ->
    expression = @evaluateDirective directive.expression, frame, ruleName
    new nodes.YieldFrom expression

  createExistence: (directive, frame, ruleName) ->
    expression = @evaluateDirective directive.expression, frame, ruleName
    new nodes.Existence expression

  createSwitch: (directive, frame, ruleName) ->
    subject   = @evaluateDirective directive.subject, frame, ruleName
    cases     = @evaluateDirective directive.cases, frame, ruleName
    otherwise = @evaluateDirective directive.otherwise, frame, ruleName
    casesNode = @filterNodes (if Array.isArray(cases) then cases else [])
    # Ensure otherwise is a proper block or null
    if otherwise
      if Array.isArray(otherwise)
        otherwise = new nodes.Block @filterNodes(otherwise)
      else if not (otherwise instanceof nodes.Base)
        otherwise = new nodes.Block [@ensureNode(otherwise)]
    new nodes.Switch subject, casesNode, otherwise

  createCatch: (directive, frame, ruleName) ->
    # CS3 uses either 'recovery' or 'body' for the catch block
    body  = @evaluateDirective(directive.recovery, frame, ruleName) or @evaluateDirective(directive.body, frame, ruleName)
    # CS3 uses 'variable' or 'errorVariable' for the error parameter
    error = @evaluateDirective(directive.variable, frame, ruleName) or @evaluateDirective(directive.errorVariable, frame, ruleName)

    # Ensure body is a proper Block
    bodyNode = if Array.isArray(body)
      new nodes.Block @filterNodes(body)
    else if body instanceof nodes.Block
      body
    else if body
      new nodes.Block [@ensureNode(body)]
    else
      new nodes.Block []

    # Ensure error parameter is properly converted if present
    errorNode = if error then @ensureNode(error) else null

    # Catch constructor expects (recovery, errorVariable) not (errorVariable, recovery)!
    new nodes.Catch bodyNode, errorNode

  createWhile: (directive, frame, ruleName) ->
    condition = @evaluateDirective directive.condition, frame, ruleName
    body      = @evaluateDirective directive.body, frame, ruleName
    guard     = @evaluateDirective directive.guard, frame, ruleName
    isLoop    = @evaluateDirective directive.isLoop, frame, ruleName
    invert    = @evaluateDirective directive.invert, frame, ruleName

    # Handle body - convert from Solar node if needed
    bodyNode = if body?.type is 'Body' or body?.type is 'Block'
      @solarNodeToClass body
    else
      @toBlock(body)

    # While constructor expects (condition, opts)
    opts = {}
    opts.guard = guard if guard
    opts.isLoop = isLoop if isLoop
    opts.invert = invert if invert  # Handle 'until' loops
    whileNode = new nodes.While condition, opts
    # Set the body - ensure it's never null
    finalBody = bodyNode or new nodes.Block []
    whileNode.body = finalBody
    whileNode

  createTry: (directive, frame, ruleName) ->
    attempt        = @evaluateDirective directive.attempt, frame, ruleName
    # CS3 uses 'catch' not 'recovery' for the catch clause
    catchDirective = @evaluateDirective directive.catch, frame, ruleName
    ensure         = @evaluateDirective directive.ensure, frame, ruleName

    # Ensure attempt is a proper block
    attemptNode = @toBlock(attempt)

    # Process the catch clause - it should be a Catch node
    recovery = if catchDirective instanceof nodes.Catch
      catchDirective
    else if catchDirective
      # It might be a directive that needs to be evaluated into a Catch node
      catchDirective
    else
      null

    # Ensure ensure is a proper block if present
    ensureNode = if ensure then @toBlock(ensure) else null

    # Try expects (attempt, recovery, ensure) where recovery and ensure are optional
    new nodes.Try attemptNode, recovery, ensureNode

  createLoop: (directive, frame, ruleName) ->
    body = @evaluateDirective directive.body, frame, ruleName
    # Ensure body is a proper Block
    bodyNode = if Array.isArray(body)
      new nodes.Block @filterNodes(body)
    else if body instanceof nodes.Block
      body
    else if body
      new nodes.Block [body]
    else
      new nodes.Block []
    # Loop is a While with true condition
    loopNode = new nodes.While new nodes.BooleanLiteral('true'), {isLoop: true}
    loopNode.body = bodyNode
    loopNode

  createParens: (directive, frame, ruleName) ->
    body = @evaluateDirective directive.body, frame, ruleName

    # Handle array body (Parens can contain an array with a single expression)
    bodyNode = if Array.isArray(body) and body.length > 0
      # Take the first element if it's an array
      @toNode(body[0]) or new nodes.Literal ''
    else
      @toNode(body) or new nodes.Literal ''

    new nodes.Parens bodyNode

  createInterpolation: (directive, frame, ruleName) ->
    expression = @evaluateDirective directive.expression, frame, ruleName
    # Expression might be an array, so extract the first element
    actualExpression = if Array.isArray(expression) and expression.length > 0
      expression[0]
    else
      expression

    expressionNode = @toNode(actualExpression) or new nodes.Literal 'undefined'
    new nodes.Interpolation expressionNode

  createStringWithInterpolations: (directive, frame, ruleName) ->
    body  = @evaluateDirective directive.body, frame, ruleName
    quote = @evaluateDirective directive.quote, frame, ruleName

    # Convert body to proper nodes
    bodyNode = if Array.isArray(body)
      bodyNodes = body.map (b) => @toNode(b)
      new nodes.Block @filterNodes(bodyNodes)
    else if body instanceof nodes.Block
      body
    else
      new nodes.Block []

    new nodes.StringWithInterpolations bodyNode, {quote}

  createParam: (directive, frame, ruleName) ->
    name  = @evaluateDirective directive.name, frame, ruleName
    value = @evaluateDirective directive.value, frame, ruleName
    splat = @evaluateDirective directive.splat, frame, ruleName

    # Param requires at least a name
    name = new nodes.IdentifierLiteral 'param' unless name

    # Check if this is an @ parameter (like @x)
    if name instanceof nodes.Value and name.base instanceof nodes.ThisLiteral
      # This is an @param - mark it with this=true so Param recognizes it
      name.this = true
      name.locationData ?= @defaultLocationData()
    else if name and not name.locationData
      # Ensure name has locationData (needed for destructuring)
      name.locationData = @defaultLocationData()

    # Handle {@x, @y} destructuring - convert CS3 Assigns to CS2-style Values
    if name instanceof nodes.Obj or (name instanceof nodes.Value and name.base instanceof nodes.Obj)
      obj = if name instanceof nodes.Obj then name else name.base
      obj.generated = false
      if obj.properties
        for prop, i in obj.properties when prop instanceof nodes.Assign and prop.value?.this
          # Create the CS2-style Value node for @param
          obj.properties[i] = atValue = new nodes.Value(new nodes.ThisLiteral())
          atValue.properties = [new nodes.Access(new nodes.PropertyName(prop.variable.base.value))]
          atValue.this = true
        obj.objects = obj.properties # eachName uses 'objects' not 'properties'

    new nodes.Param name, value, splat

  createClass: (directive, frame, ruleName) ->
    variable = @evaluateDirective directive.variable, frame, ruleName
    parent   = @evaluateDirective directive.parent, frame, ruleName
    body     = @evaluateDirective directive.body, frame, ruleName
    bodyNode = if Array.isArray(body) then new nodes.Block @filterNodes(body) else body
    new nodes.Class variable, parent, bodyNode

  createBlock: (directive, frame, ruleName) ->
    expressions = @evaluateDirective directive.expressions, frame, ruleName
    new nodes.Block @filterNodes (if Array.isArray(expressions) then expressions else [])

  createBody: (directive, frame, ruleName) ->
    expressions = @evaluateDirective directive.expressions, frame, ruleName
    # Flatten nested arrays - expressions often come as [[expr1], [expr2]]
    flatExpressions = []
    if Array.isArray(expressions)
      for expr in expressions
        if Array.isArray(expr)
          flatExpressions.push item for item in expr
        else
          flatExpressions.push expr
    else if expressions?
      flatExpressions.push expressions
    new nodes.Block @filterNodes flatExpressions

  createRegexLiteral: (directive, frame, ruleName) ->
    value     = @evaluateDirective directive.value, frame, ruleName
    delimiter = @evaluateDirective directive.delimiter, frame, ruleName

    # RegexLiteral expects the full regex string including delimiters
    if value and typeof value is 'string' and value[0] is '/'
      new nodes.RegexLiteral value, {delimiter: delimiter or '/'}
    else
      # Otherwise try to construct from pattern and flags
      pattern = @evaluateDirective directive.pattern, frame, ruleName
      flags   = @evaluateDirective directive.flags, frame, ruleName
      fullRegex = "/#{pattern or ''}/#{flags or ''}"
      new nodes.RegexLiteral fullRegex, {delimiter: delimiter or '/'}

  createRange: (directive, frame, ruleName) ->
    from         = @evaluateDirective directive.from, frame, ruleName
    to           = @evaluateDirective directive.to, frame, ruleName
    # Evaluate the exclusive flag - it can be a directive or a boolean
    exclusiveVal = @evaluateDirective directive.exclusive, frame, ruleName
    exclusive = if typeof exclusiveVal is 'boolean'
      exclusiveVal
    else if directive.equals?
      @evaluateDirective(directive.equals, frame, ruleName) is 'exclusive'
    else
      false
    # Ensure from and to are proper nodes
    fromNode = @toNode(from) or @ensureNode(from)
    toNode = @toNode(to) or @ensureNode(to)
    # Pass 'exclusive' as the tag for exclusive ranges
    tag = if exclusive then 'exclusive' else null
    new nodes.Range fromNode, toNode, tag

  createSwitchWhen: (directive, frame, ruleName) ->
    conditions = @evaluateDirective directive.conditions, frame, ruleName
    body = @evaluateDirective directive.body, frame, ruleName

    # Process conditions - make sure they are proper nodes
    conditionsNode = if Array.isArray(conditions)
      processedConditions = []
      for cond in conditions
        if cond instanceof nodes.Base
          processedConditions.push cond
        else if cond?
          converted = @ensureNode(cond)
          processedConditions.push converted if converted instanceof nodes.Base
      processedConditions
    else if conditions instanceof nodes.Base
      [conditions]
    else if conditions?
      converted = @ensureNode(conditions)
      if converted instanceof nodes.Base then [converted] else []
    else
      []

    # SwitchWhen expects 'block' not 'body'
    blockNode = if Array.isArray(body)
      new nodes.Block @filterNodes(body)
    else if body
      if body instanceof nodes.Block
        body
      else
        new nodes.Block [body]
    else
      new nodes.Block []
    new nodes.SwitchWhen conditionsNode, blockNode

  createFor: (directive, frame, ruleName) ->
    # For loops are complex - they're built incrementally via $ops
    body    = @evaluateDirective directive.body, frame, ruleName
    source  = @evaluateDirective directive.source, frame, ruleName
    guard   = @evaluateDirective directive.guard, frame, ruleName
    name    = @evaluateDirective directive.name, frame, ruleName
    index   = @evaluateDirective directive.index, frame, ruleName
    step    = @evaluateDirective directive.step, frame, ruleName
    own     = @evaluateDirective directive.own, frame, ruleName
    object  = @evaluateDirective directive.object, frame, ruleName
    from    = @evaluateDirective directive.from, frame, ruleName
    isAwait = @evaluateDirective directive.await, frame, ruleName

    # Handle body
    bodyNode = if body?.expressions
      # Body node with expressions - preserve full list and order
      new nodes.Block @filterNodes(body.expressions)
    else
      @toBlock(body)

    # Handle name/index - they often come as arrays
    # Special case: for own k, v of obj - name comes as [k, v]
    # But nodes.For swaps name and index when object is true, so we need to account for that
    if own and object and Array.isArray(name) and name.length is 2 and not index?
      # nodes.For will swap these, so set them opposite to what we want
      # We want: name=v, index=k (after the swap)
      # So we set: name=k, index=v (before the swap)
      nameArray = name
      name = nameArray[0]   # k (will become index after swap)
      index = nameArray[1]  # v (will become name after swap)
    else if Array.isArray(name)
      name = name[0]

    if Array.isArray(index) then index = index[0]

    # Convert to proper nodes if needed
    if name?.type then name = @solarNodeToClass name
    if index?.type then index = @solarNodeToClass index
    if source?.type then source = @solarNodeToClass source

    # Build source object for For constructor
    sourceObj = {}
    # Ensure source is a proper node
    if source
      sourceObj.source = if source instanceof nodes.Base then source else @ensureNode(source)
    if name
      sourceObj.name = if name instanceof nodes.Base then name else @ensureNode(name)
    # Only add index if it's actually defined (not undefined/null)
    # This is important for for-await loops which may not have an index
    # Also check if index is the string "index" which means the variable wasn't found
    # console.error "[For] index value:", index, "typeof:", typeof index, "is null?:", index is null
    if index? and index isnt undefined and index isnt 'index'
      sourceObj.index = if index instanceof nodes.Base then index else @ensureNode(index)
    sourceObj.guard = guard if guard
    sourceObj.step = step if step
    sourceObj.own = own if own
    sourceObj.object = object if object
    sourceObj.from = from if from
    sourceObj.await = isAwait if isAwait

    # Create For node - constructor expects (body, source)
    forNode = new nodes.For bodyNode, sourceObj
    forNode.locationData ?= @defaultLocationData()

    # Pre-allocate unique loop variables and override scope.freeVariable
    loopVar = @getUniqueLoopVar()
    incrementVar = @getUniqueLoopVar()

    originalCompileNode = forNode.compileNode
    forNode.compileNode = (o) =>
      originalFreeVariable = null
      if o?.scope?.freeVariable
        originalFreeVariable = o.scope.freeVariable
        varCounter = 0
        preAllocatedVars = [loopVar, incrementVar]

        # Determine user-declared value variable name to avoid collisions
        userName = null
        try
          if forNode.name? and forNode.name instanceof nodes.IdentifierLiteral
            userName = forNode.name.value
          else if forNode.name? and forNode.name instanceof nodes.Value and forNode.name.base instanceof nodes.IdentifierLiteral
            userName = forNode.name.base.value
        catch e then userName = null

        o.scope.freeVariable = (name, options = {}) =>
          # When nodes.For requests 'i' with single:true, it's asking for an iterator temp
          # ALWAYS return our pre-allocated var for these iterator requests
          if options.single and name is 'i'
            if varCounter < preAllocatedVars.length
              result = preAllocatedVars[varCounter++]
              return result
            else
              return @getUniqueLoopVar()
          else
            return originalFreeVariable.call(o.scope, name, options)

      result = originalCompileNode.call(forNode, o)

      if originalFreeVariable?
        o.scope.freeVariable = originalFreeVariable

      result

    forNode

  createCode: (directive, frame, ruleName) ->
    params = @evaluateDirective directive.params, frame, ruleName

    # For body, check if it's a position reference to an already-processed array or Block
    # This preserves modifications made by operations like addElse
    if typeof directive.body is 'number' and frame?[directive.body - 1]
      frameValue = frame[directive.body - 1].value
      # If it's already a Block or an array of nodes, use it directly
      # This preserves any modifications made by operations
      if frameValue instanceof nodes.Block or (Array.isArray(frameValue) and frameValue.some((v) -> v instanceof nodes.Base))
        body = frameValue
      else
        body = @evaluateDirective directive.body, frame, ruleName
    else
      body = @evaluateDirective directive.body, frame, ruleName

    # Check if this is a bound function (fat arrow =>)
    funcGlyph = @evaluateDirective directive.funcGlyph, frame, ruleName
    bound = funcGlyph?.glyph is '=>' or @evaluateDirective directive.bound, frame, ruleName

    # Ensure params are proper nodes
    if Array.isArray(params)
      paramsNode = params.map (p) =>
        if p?.type
          @solarNodeToClass(p)
        else if p instanceof nodes.Base
          p
        else
          @ensureNode(p)
      paramsNode = @filterNodes paramsNode
    else
      paramsNode = []

    # Ensure body is a proper Block with converted nodes
    bodyNode = if Array.isArray(body)
      bodyNodes = body.map (b) =>
        # Check for nodes.Base FIRST to avoid re-processing existing nodes
        if b instanceof nodes.Base then b
        else if b?.type then @solarNodeToClass(b)
        else @ensureNode(b)
      new nodes.Block @filterNodes(bodyNodes)
    else
      @toBlock(body)

    # Create proper FuncGlyph for bound/unbound functions
    funcGlyph = if bound then new nodes.FuncGlyph('=>') else new nodes.FuncGlyph('->')
    codeNode = new nodes.Code paramsNode, bodyNode, funcGlyph

    # For CS3, pre-scan for super calls to avoid false positives
    # in derived constructor validation
    hasSuper = false
    if bodyNode?.expressions
      bodyNode.traverseChildren false, (node) ->
        if node instanceof nodes.SuperCall or (node instanceof nodes.Call and node.variable instanceof nodes.Super)
          hasSuper = true
          return false  # Stop traversing
        return true  # Continue traversing

    # Monkey-patch only for constructors; avoid affecting arrow methods and regular methods
    isCtor = !!(@evaluateDirective(directive.isConstructor, frame, ruleName))
    if hasSuper and isCtor
      # Skip validation for @params in derived constructors
      origFlag = codeNode.flagThisParamInDerivedClassConstructorWithoutCallingSuper
      codeNode.flagThisParamInDerivedClassConstructorWithoutCallingSuper = (param) ->
        # Skip the validation for CS3-generated code with super
        return

      # Also patch eachSuperCall to make it always find the super call
      origEachSuper = codeNode.eachSuperCall
      codeNode.eachSuperCall = (context, iterator, opts) ->
        # If checking params (not the body), use original so validations still run
        if context isnt @body and origEachSuper?
          return origEachSuper.call this, context, iterator, opts
        # Otherwise, search body for the real SuperCall and report it
        if iterator
          for expr in bodyNode.expressions
            if expr instanceof nodes.SuperCall or (expr instanceof nodes.Call and expr.variable instanceof nodes.Super)
              iterator(expr)
              break
        true

    codeNode

  createObj: (directive, frame, ruleName) ->
    properties = @evaluateDirective directive.properties, frame, ruleName
    properties = @filterNodes (if Array.isArray(properties) then properties else [])
    generated = @evaluateDirective directive.generated, frame, ruleName

    # If object is generated (from braces) and has shorthand properties,
    # convert them to proper key-value pairs
    if generated
      fixedProps = []
      for prop in properties
        if prop instanceof nodes.Value and prop.base instanceof nodes.IdentifierLiteral and not prop.properties?.length
          # This is a shorthand property like 'x' in {x}
          # Convert to x: x
          key = new nodes.Value prop.base
          value = new nodes.Value prop.base
          fixedProps.push new nodes.Assign key, value, 'object'
        else if prop instanceof nodes.Value and prop.base instanceof nodes.ThisLiteral
          # This is an @ property like {@x} - extract the property name
          # and mark the Value node with this=true for Param.eachName to handle correctly
          if prop.properties?[0] instanceof nodes.Access
            # Get the property name from the Access node
            propName = prop.properties[0].name
            if propName instanceof nodes.PropertyName
              # PropertyName has a 'value' property with the actual name
              propNameStr = propName.value
              propName = new nodes.IdentifierLiteral propNameStr
            else if typeof propName is 'string'
              propName = new nodes.IdentifierLiteral propName
            else if not (propName instanceof nodes.Base)
              propName = @ensureNode propName

            # Create the property assignment for object pattern
            # The value should be a Value node marked with this=true
            key = new nodes.Value propName
            value = new nodes.Value propName
            value.this = true  # Mark as @ parameter
            fixedProps.push new nodes.Assign key, value, 'object'
          else
            fixedProps.push prop
        else
          fixedProps.push prop
      properties = fixedProps

    obj = new nodes.Obj properties, generated
    obj.locationData ?= @defaultLocationData()
    obj

  createAssign: (directive, frame, ruleName) ->
    # Handle object property assignments differently
    if directive.context is 'object' and directive.expression?
      # In object context, 'value' is the property name, 'expression' is the value
      variable = @evaluateDirective directive.value, frame, ruleName
      value    = @evaluateDirective directive.expression, frame, ruleName
      context  = directive.context
      # Mark Value nodes with ThisLiteral base as this=true for static properties
      if variable instanceof nodes.Value and variable.base instanceof nodes.ThisLiteral
        variable.this = true
      new nodes.Assign variable, value, context
    else if directive.expression? and not directive.variable?
      # Default value assignment (e.g., in destructuring {x = 10})
      # Here 'value' is the variable name and 'expression' is the default value
      variable = @evaluateDirective directive.value, frame, ruleName
      value    = @evaluateDirective directive.expression, frame, ruleName
      # Use null context for destructuring defaults so Param.eachName handles it correctly
      new nodes.Assign variable, value, null
    else
      # Regular assignment
      variable = @evaluateDirective directive.variable, frame, ruleName
      value    = @evaluateDirective directive.value, frame, ruleName
      # For compound assignments, use the operator as the context
      context = if directive.operator?
        operator = @evaluateDirective directive.operator, frame, ruleName
        operator
      else
        @evaluateDirective directive.context, frame, ruleName
      options = {}
      if directive.originalContext?
        options.originalContext = @evaluateDirective directive.originalContext, frame, ruleName

      # Create the Assign node with the correct context for compound assignments
      assignNode = new nodes.Assign variable, value, context, options

      # For CS3, mark if this variable can be const based on our analysis
      if @compileOptions.cs3 and @variableInfo and variable instanceof nodes.Value
        varName = variable.base?.value
        if varName and typeof varName is 'string'
          # Variable can be const if it's declared but never reassigned
          canBeConst = @variableInfo.declarations[varName] and not @variableInfo.assignments[varName]
          assignNode.canBeConst = canBeConst

      assignNode

  # Helper to ensure value is a proper node
  ensureNode: (value) ->
    return null unless value?
    return value if value.compileToFragments or value instanceof nodes.Base
    # Only wrap primitives; drop unknown objects to avoid emitting debug strings.
    if typeof value in ['string', 'number', 'boolean']
      node = new nodes.Literal String(value)
      node.locationData ?= @defaultLocationData()
      return node
    # Try to convert objects that might be PropertyName-like
    if value?.value?
      node = new nodes.PropertyName value.value
      node.locationData ?= @defaultLocationData()
      return node
    null

  # Helper to filter and ensure all items are nodes
  filterNodes: (array) ->
    return [] unless array?
    result = []
    for item in array
      node = @toNode(item)
      result.push node if node?
    result

  # Add mergeLocationData helper
  mergeLocationData: (first, last) ->
    return first unless last
    first_line: first.first_line
    first_column: first.first_column
    last_line: last.last_line
    last_column: last.last_column
    last_line_exclusive: last.last_line_exclusive ? first.last_line_exclusive
    last_column_exclusive: last.last_column_exclusive ? first.last_column_exclusive
    range: [first.range[0], last.range[1]]

  # ReductionFrame-based Solar directive evaluation
  reduce: (values, positions, stackTop, symbolCount, directive) ->
    # Build frame directly from parser stacks using indices as a flat array
    frame = []
    for i in [0...symbolCount]
      offset = stackTop - symbolCount + i + 1
      frame.push {
        value: values[offset]
        pos: positions[offset]
      }

    # Evaluate Solar directive against ReductionFrame
    @evaluateDirective directive, frame, null

  # Core directive evaluator - evaluates Solar directives against RHS frame
  evaluateDirective: (directive, frame, ruleName = null) ->
    # Handle position references (1, 2, 3, ...) FIRST
    if typeof directive is 'number'
      return frame[directive - 1]?.value  # 1-based → 0-based

    # Handle primitives (except numbers, handled above)
    return directive if typeof directive in ['string', 'boolean']

    # Handle arrays
    if Array.isArray directive
      return directive.map (item) => @evaluateDirective item, frame, ruleName

    # Handle Solar directives
    if directive? and typeof directive is 'object'

      # $use directive (with optional method/prop/index)
      if directive.$use?
        ref = directive.$use
        value = if typeof ref is 'number'
          frame[ref - 1]?.value  # Position reference
        else if typeof ref is 'string' and @variableContext[ref]?
          @variableContext[ref]  # Lookup stored variable
        else
          ref  # Direct value

        # Apply method calls
        if directive.method?
          args = directive.args?.map((arg) => @evaluateDirective arg, frame) or []
          value?[directive.method]?.apply(value, args) or String(value)
        # Apply property access
        else if directive.prop?
          # Special handling for boolean properties to avoid the falsy trap
          result = value?[directive.prop]
          if result? or (value? and typeof value is 'object' and directive.prop of value)
            result
          else
            String(value)
        # Apply array index access
        else if directive.index?
          if Array.isArray(value) or value?.length?
            value?[directive.index] or undefined
          else
            undefined
        else
          value

      # $ast directive (AST node creation)
      else if directive.$ast?
        # @ is now replaced with actual rule name at parser generation time
        nodeType = directive.$ast

        # Directly create CoffeeScript node with evaluated properties
        switch nodeType
          when 'Root'
            body = @evaluateDirective directive.body, frame, ruleName
            body = @toArray(body)
            filteredBody = @filterNodes body
            new nodes.Root new nodes.Block filteredBody

          when 'IdentifierLiteral'
            @createIdentifierLiteral directive, frame, ruleName

          when 'Literal'
            @createLiteral directive, frame, ruleName

          when 'NumberLiteral'
            @createNumberLiteral directive, frame, ruleName

          when 'Value'
            # directive.val or directive.value can be a position reference (number) or actual value
            innerDirective = if directive.val? then directive.val else directive.value
            inner = @evaluateDirective innerDirective, frame, ruleName
            # Handle properties (accessors)
            properties = @evaluateDirective directive.properties, frame, ruleName
            # Special case: SuperCall should not be wrapped in Value unless it has properties
            if inner instanceof nodes.SuperCall and (not properties or properties.length is 0)
              return inner
            if inner?.compileToFragments or inner instanceof nodes.Base
              valueNode = if inner instanceof nodes.Value then inner else new nodes.Value inner
              if properties and Array.isArray(properties) and properties.length > 0
                validProps = []
                for prop in properties
                  # Handle nested arrays of properties (e.g., from :: operator)
                  if Array.isArray(prop)
                    for subProp in prop
                      node = @toNode(subProp)
                      validProps.push node if node instanceof nodes.Base
                  else
                    node = @toNode(prop)
                    validProps.push node if node instanceof nodes.Base
                # Only add non-null properties
                if validProps.length > 0
                  valueNode.add validProps
              return valueNode
            @ensureNode(inner) or new nodes.Literal "/* TODO: Solar Value */"

          when 'Access'
            nameNode = @evaluateDirective directive.name, frame, ruleName

            # Handle various forms of nameNode
            if not nameNode?
              # For shorthand (::), use "prototype" as the name
              nameNode = if directive.shorthand
                new nodes.PropertyName 'prototype'
              else
                new nodes.PropertyName ''
            else if typeof nameNode is 'string'
              nameNode = new nodes.PropertyName nameNode
            else if nameNode?.value? and not (nameNode instanceof nodes.Base)
              nameNode = new nodes.PropertyName String(nameNode.value)
            else
              nameNode = @toNode(nameNode) or new nodes.PropertyName ''

            new nodes.Access nameNode, soak: directive.soak, shorthand: directive.shorthand

          when 'Index'
            idx = @evaluateDirective (if directive.index? then directive.index else if directive.name? then directive.name else directive.object), frame, ruleName
            new nodes.Index @ensureNode idx

          when 'PropertyName'
            @createPropertyName directive, frame, ruleName

          when 'Op'
            op = @evaluateDirective (if directive.operator? then directive.operator else directive.args?[0]), frame, ruleName
            left  = @ensureNode @evaluateDirective (if directive.left? then directive.left else directive.args?[1]), frame, ruleName
            right = @ensureNode @evaluateDirective (if directive.right? then directive.right else directive.args?[2]), frame, ruleName
            flip  = @evaluateDirective (if directive.flip? then directive.flip else directive.args?[3]), frame, ruleName
            originalOperator = @evaluateDirective directive.originalOperator, frame, ruleName
            invertOperator   = @evaluateDirective directive.invertOperator, frame, ruleName

            # Handle CoffeeScript's in/of/instanceof operators
            # IMPORTANT: These work opposite to JavaScript!
            # CoffeeScript 'of' checks properties/keys (like JS 'in')
            # CoffeeScript 'in' checks values/elements (uses indexOf)

            # Check if this is a negated operator (not in, not of)
            negated = invertOperator is 'not' or invertOperator is true

            if op is 'of'
              # 'x of obj' checks if x is a property/key/index
              # Compiles to JavaScript's native 'in' operator
              # MUST set originalOperator to null to prevent it defaulting to 'in'
              # which would trigger the isInOperator() check and create an In node
              opNode = new nodes.Op 'in', left, right, false, {originalOperator: null}
              # If negated (not of), wrap in a Parens to ensure proper precedence
              if negated
                new nodes.Op '!', new nodes.Parens(opNode)
              else
                opNode
            else if op is 'in'
              # 'x in array' checks if x is in the values
              # Op with originalOperator='in' will create an In node internally
              # If negated, set invertOperator to trigger inversion
              new nodes.Op 'in', left, right, false, {
                originalOperator: 'in',
                invertOperator: if negated then '!' else null
              }
            else if op is 'instanceof'
              # instanceof checks type
              opNode = new nodes.Op 'instanceof', left, right
              if negated
                new nodes.Op '!', opNode
              else
                opNode
            else
              # All other operators
              new nodes.Op op, left, right, flip, {originalOperator, invertOperator}

          when 'Arguments'
            args = @evaluateDirective (if directive.args? then directive.args else if directive.$ary? then directive.$ary else directive), frame, ruleName
            args = @filterNodes @toArray(args)
            args = @deepFlatten(args)
            # Handle implicit property if provided
            if directive.implicit?
              implicitValue = @evaluateDirective directive.implicit, frame, ruleName
              args.implicit = !!implicitValue
            else
              args.implicit = !!directive.implicit
            args

          when 'Call'
            variableNode = @evaluateDirective directive.variable, frame, ruleName
            argsNode = @evaluateDirective directive.args, frame, ruleName

            # Ensure args are proper nodes
            if Array.isArray argsNode
              # Flatten and convert to nodes
              flattened = @deepFlatten(argsNode)
              argsNode = []
              for item in flattened
                node = @toNode(item)
                argsNode.push node if node?
            else
              argsNode = []

            # Check if this is a bare super() call (not a delegated super.method(...))
            if variableNode instanceof nodes.Super
              new nodes.SuperCall(variableNode, argsNode)
            else if variableNode instanceof nodes.Value and variableNode.base instanceof nodes.Super
              # Has a property access: this is super.method(...), NOT a constructor super()
              new nodes.Call variableNode, argsNode, @evaluateDirective(directive.soak, frame, ruleName), @evaluateDirective(directive.token, frame, ruleName)
            else
              new nodes.Call (if variableNode instanceof nodes.Value then variableNode else new nodes.Value variableNode), argsNode, @evaluateDirective(directive.soak, frame, ruleName), @evaluateDirective(directive.token, frame, ruleName)

          when 'TaggedTemplateCall'
            vNode = @evaluateDirective directive.variable, frame, ruleName
            templateArg = @ensureNode @evaluateDirective directive.template, frame, ruleName
            # Convert StringLiteral to StringWithInterpolations for tagged templates
            if templateArg instanceof nodes.StringLiteral
              templateArg = nodes.StringWithInterpolations.fromStringLiteral templateArg
            # Tagged templates should never have soak (no typeof check)
            new nodes.TaggedTemplateCall (if vNode instanceof nodes.Value then vNode else new nodes.Value vNode), templateArg, false

          when 'Assign'
            @createAssign directive, frame, ruleName

          when 'StringLiteral'
            @createStringLiteral directive, frame, ruleName

          when 'BooleanLiteral'
            @createBooleanLiteral directive, frame, ruleName

          when 'StatementLiteral'
            # Handle break, continue, debugger statements
            value = @evaluateDirective directive.value, frame, ruleName
            switch value
              when 'break'
                new nodes.StatementLiteral value
              when 'continue'
                new nodes.StatementLiteral value
              when 'debugger'
                new nodes.StatementLiteral value
              else
                # For other statements, create a basic literal
                new nodes.Literal value

          when 'NullLiteral'
            @createNullLiteral()

          when 'UndefinedLiteral'
            @createUndefinedLiteral()

          when 'Arr'
            @createArr directive, frame, ruleName

          when 'Obj'
            @createObj directive, frame, ruleName

          when 'Range'
            @createRange directive, frame, ruleName

          when 'If', 'if'
            @createIf directive, frame, ruleName, 'if'

          when 'Unless', 'unless'
            @createIf directive, frame, ruleName, 'unless'

          when 'While'
            @createWhile directive, frame, ruleName

          when 'For'
            @createFor directive, frame, ruleName

          when 'Try'
            @createTry directive, frame, ruleName

          when 'Code'
            @createCode directive, frame, ruleName

          when 'Param'
            @createParam directive, frame, ruleName

          when 'Return'
            @createReturn directive, frame, ruleName

          when 'Yield'
            @createYield directive, frame, ruleName

          when 'Class'
            @createClass directive, frame, ruleName

          when 'Slice'
            @createSlice directive, frame, ruleName

          when 'Super'
            # Handle Super nodes which may have accessor for super.method() calls
            accessor = @evaluateDirective directive.accessor, frame, ruleName
            literal = @evaluateDirective directive.literal, frame, ruleName
            # If accessor is present, this is super.method() or super[expr]
            # The CS2 nodes.Super expects accessor to be set on the node
            superNode = new nodes.Super()
            if accessor
              superNode.accessor = accessor
            if literal
              superNode.literal = literal
            superNode

          when 'SuperCall'
            # Handle super() calls in constructors and methods
            args = @evaluateDirective directive.args, frame, ruleName
            argsNode = if Array.isArray(args)
              # Filter out nulls that ensureNode might return
              args.map((arg) => @ensureNode(arg)).filter((arg) => arg?)
            else if args
              arg = @ensureNode(args)
              if arg? then [arg] else []
            else
              []

            # Create a SuperCall node with the Super variable and arguments
            variableNode = new nodes.Super()
            new nodes.SuperCall variableNode, argsNode

          when 'StringWithInterpolations'
            @createStringWithInterpolations directive, frame, ruleName

          when 'Interpolation'
            @createInterpolation directive, frame, ruleName

          when 'TemplateElement'
            value = @evaluateDirective directive.value, frame, ruleName
            tail = @evaluateDirective directive.tail, frame, ruleName
            new nodes.TemplateElement value, tail

          when 'Block'
            @createBlock directive, frame, ruleName

          when 'Body'
            @createBody directive, frame, ruleName

          when 'RegexLiteral', 'Regex'
            @createRegexLiteral directive, frame, ruleName

          when 'Parens'
            @createParens directive, frame, ruleName

          when 'PassthroughLiteral'
            value = @evaluateDirective directive.value, frame, ruleName
            new nodes.PassthroughLiteral value, {here: directive.here, generated: directive.generated}

          when 'Throw'
            @createThrow directive, frame, ruleName

          when 'Splat'
            # Check for 'name' or 'body' field (@ directive uses 'body')
            nameDirective = directive.name ? directive.body
            name = @evaluateDirective nameDirective, frame, ruleName
            # Splat requires a valid expression, not undefined
            if name
              new nodes.Splat name
            else
              # Create a placeholder if name is missing
              new nodes.Splat new nodes.Literal 'undefined'

          when 'Expansion'
            # Check for 'expression' or 'body' field (@ directive uses 'body')
            exprDirective = directive.expression ? directive.body
            expression = @evaluateDirective exprDirective, frame, ruleName
            # Expansion needs a valid expression
            if expression
              new nodes.Expansion expression
            else
              new nodes.Expansion new nodes.Literal 'undefined'

          when 'In'
            object = @evaluateDirective directive.object, frame, ruleName
            array = @evaluateDirective directive.array, frame, ruleName
            new nodes.In object, array

          when 'ImportDeclaration'
            clause = @evaluateDirective directive.clause, frame, ruleName
            source = @evaluateDirective directive.source, frame, ruleName
            new nodes.ImportDeclaration clause, source

          when 'ExportNamedDeclaration', 'ExportDeclaration'
            clause = @evaluateDirective directive.clause, frame, ruleName
            source = @evaluateDirective directive.source, frame, ruleName
            new nodes.ExportNamedDeclaration clause, source

          when 'Existence'
            @createExistence directive, frame, ruleName

          when 'Loop'
            @createLoop directive, frame, ruleName

          when 'Switch'
            @createSwitch directive, frame, ruleName

          when 'When', 'SwitchWhen'
            @createSwitchWhen directive, frame, ruleName

          when 'Case', 'SwitchCase'
            @createSwitchWhen directive, frame, ruleName

          when 'Catch'
            @createCatch directive, frame, ruleName

          when 'Finally'
            body = @evaluateDirective directive.body, frame, ruleName
            bodyNode = if Array.isArray(body) then new nodes.Block @filterNodes(body) else body
            new nodes.Finally bodyNode

          when 'Await'
            @createAwait directive, frame, ruleName

          when 'YieldFrom'
            @createYieldFrom directive, frame, ruleName

          when 'ThisLiteral', 'This'
            @createThisLiteral()

          when 'Elision'
            # Elisions in array destructuring are placeholders for skipped elements
            # CS2 has a special Elision class for this
            new nodes.Elision()

          when 'InfinityLiteral'
            # Infinity is a special numeric value
            new nodes.Literal 'Infinity'

          when 'NaNLiteral'
            # NaN is a special numeric value
            new nodes.Literal 'NaN'

          when 'ComputedPropertyName'
            # Computed property names like ["dynamic" + key]: value
            expression = @evaluateDirective directive.expression, frame, ruleName
            # Return a bracket notation access node
            if expression instanceof nodes.Base
              expression
            else
              @ensureNode(expression)

          when 'DynamicImport'
            # Dynamic import is just the 'import' keyword itself
            new nodes.IdentifierLiteral 'import'

          when 'DynamicImportCall'
            # Dynamic import: import('./module')
            variable = @evaluateDirective directive.variable, frame, ruleName
            args = @evaluateDirective directive.args, frame, ruleName

            # Ensure variable is the import identifier
            variableNode = if variable instanceof nodes.Base
              variable
            else
              new nodes.IdentifierLiteral 'import'

            # Process arguments
            argsNode = if Array.isArray(args)
              # Filter out nulls that ensureNode might return
              args.map((arg) => @ensureNode(arg)).filter((arg) => arg?)
            else if args
              arg = @ensureNode(args)
              if arg? then [arg] else []
            else
              []

            new nodes.Call variableNode, argsNode, false

          when 'FuncGlyph'
            # FuncGlyph for -> or => functions
            glyph = @evaluateDirective directive.glyph, frame, ruleName
            new nodes.FuncGlyph(glyph)

          else
            # For unimplemented types, create placeholder
            new nodes.Literal "/* TODO: Solar #{nodeType} */"

      # $ary directive (array creation)
      else if directive.$ary?
        # If $ary is a number, it's a position reference to an existing array
        if typeof directive.$ary is 'number'
          result = @evaluateDirective directive.$ary, frame, ruleName
          result = @toArray(result)
        else
          # Create new array from elements
          result = []
          for item in directive.$ary
            # If item is a number, it's a position reference
            if typeof item is 'number'
              evaluated = @evaluateDirective item, frame, ruleName
            else
              # Item is an object, might have a $pos directive - evaluate without it
              itemCopy = Object.assign {}, item
              delete itemCopy.$pos if itemCopy.$pos?
              evaluated = @evaluateDirective itemCopy, frame, ruleName
            # Skip null/undefined items
            result.push evaluated if evaluated?

        # Handle additional properties (like implicit)
        for key, value of directive when key isnt '$ary' and not key.startsWith '$'
          result[key] = @evaluateDirective value, frame, ruleName

        result

      # $ops directive (operations)
      else if directive.$ops?
        result = @applyOperation directive, frame, ruleName
        # If the operation returned a value, use it; otherwise evaluate the rest of the directive
        if result?
          result
        else
          # Try evaluating the directive without $ops (for combined directives)
          directiveCopy = Object.assign {}, directive
          delete directiveCopy.$ops
          @evaluateDirective directiveCopy, frame, ruleName

      # Plain object (evaluate properties)
      else
        result = {}
        for key, value of directive when not key.startsWith '$'
          result[key] = @evaluateDirective value, frame, ruleName
        result
    else
      directive

  # Convert evaluated Solar node to CoffeeScript class (Phase A: Legacy adapter)
  # This is a compatibility shim that converts already-evaluated Solar nodes to CoffeeScript nodes
  # It creates a mock directive and frame, then uses our existing creation methods
  solarNodeToClass: (solarNode) ->
    return null unless solarNode?.type

    # For nodes that are already CoffeeScript nodes, return as-is
    return solarNode if solarNode instanceof nodes.Base

    # Create a mock directive that looks like what evaluateDirective expects
    # Most Solar nodes have their properties directly on the object
    directive = Object.assign {$ast: solarNode.type}, solarNode

    # Create a mock frame with empty context
    mockFrame = { rhs: [], ruleName: solarNode.type }

    # Use our existing evaluateDirective logic, which will dispatch to the appropriate create method
    result = @evaluateDirective directive, mockFrame, solarNode.type

    # If evaluateDirective couldn't handle it, fall back to a simple literal
    result or new nodes.Literal "/* TODO: Solar node #{solarNode.type} */"

  # Resolve $pos directive to locationData
  resolvePosition: (posDirective, frame) ->
    if typeof posDirective is 'number'
      # $pos: 1 → copy slot 1's position
      frame[posDirective - 1]?.pos or @defaultLocationData()
    else if Array.isArray posDirective
      if posDirective.length is 2
        # $pos: [1, 3] → span from slot 1 to slot 3
        start = frame[posDirective[0] - 1]?.pos
        end = frame[posDirective[1] - 1]?.pos
        @mergeLocationData(start, end) if start and end
      else if posDirective.length is 4
        # $pos: [sl, sc, el, ec] → explicit position
        [startLine, startCol, endLine, endCol] = posDirective
        first_line: startLine, first_column: startCol
        last_line: endLine, last_column: endCol
        range: [0, 0]
    else
      @defaultLocationData()

  # Operation handlers
  applyArrayOperation: (directive, frame, ruleName) ->
    if directive.append?
      # First element is the target array, rest are items to append
      target = @evaluateDirective directive.append[0], frame, ruleName
      # Ensure target is an array
      target = if Array.isArray(target) then target else []

      for item in directive.append[1..]
        value = @evaluateDirective item, frame, ruleName
        # If value is already an array (from $ary), unwrap it
        if Array.isArray(value) and value.length == 1
          target.push value[0] if value[0]?
        else
          target.push value if value?
      target
    else if directive.gather?
      result = []
      for item in directive.gather
        evaluated = @evaluateDirective item, frame, ruleName
        if Array.isArray evaluated
          result = result.concat evaluated
        else
          result.push evaluated if evaluated?
      result

  applyValueOperation: (directive, frame, ruleName) ->
    # Add an accessor (Access/Index) to a Value
    if directive.add?
      targetRaw = @evaluateDirective directive.add[0], frame, ruleName
      propRaw = @evaluateDirective directive.add[1], frame, ruleName

      targetNode = @toNode(targetRaw) or @ensureNode targetRaw

      # Handle array of properties
      propNodes = if Array.isArray(propRaw)
        propRaw.map (p) => @toNode(p) or @ensureNode p
      else
        propNode = @toNode(propRaw) or @ensureNode propRaw
        [propNode] if propNode?

      # Ensure we have valid nodes before proceeding
      return null unless targetNode? and propNodes?.length > 0

      if targetNode instanceof nodes.Value
        # Clone the Value node to avoid mutation issues
        clonedValue = Object.assign Object.create(Object.getPrototypeOf(targetNode)), targetNode
        clonedValue.properties = (targetNode.properties or []).slice()
        clonedValue.add propNodes
        return clonedValue
      else
        return new nodes.Value targetNode, propNodes
    @evaluateDirective directive.add?[0], frame, ruleName

  applyIfOperation: (directive, frame, ruleName) ->
    # If operations for adding else clauses
    if directive.addElse?
      # addElse: [ifNode, elseBody] - add else clause to if statement
      ifNode = @evaluateDirective directive.addElse[0], frame, ruleName
      elseBody = @evaluateDirective directive.addElse[1], frame, ruleName

      if ifNode instanceof nodes.If
        # Convert elseBody to proper node if needed
        elseBody = @toNode(elseBody) if elseBody?.type

        # Set the else body (alternate property)
        elseBodyNode = if Array.isArray(elseBody)
          block = new nodes.Block @filterNodes(elseBody)
          block.locationData ?= @defaultLocationData()
          block
        else if elseBody instanceof nodes.Block
          elseBody.locationData ?= @defaultLocationData()
          elseBody
        else if elseBody
          if elseBody instanceof nodes.Base
            elseBody.locationData ?= @defaultLocationData()
            elseBody
          else
            block = new nodes.Block [@ensureNode(elseBody)]
            block.locationData ?= @defaultLocationData()
            block
        else
          null

        # Use addElse to properly handle else-if chains
        ifNode.addElse elseBodyNode if elseBodyNode?
      ifNode
    else
      null

  applyLoopOperation: (directive, frame, ruleName) ->
    if directive.addSource?
      # addSource: [loop, source] - add source to loop
      loopNode = @evaluateDirective directive.addSource[0], frame, ruleName
      sourceInfo = @evaluateDirective directive.addSource[1], frame, ruleName

      # Convert sourceInfo to proper node if needed
      sourceInfo = @toNode(sourceInfo) if sourceInfo?.type

      # Ensure source has proper structure
      if sourceInfo
        # For addSource, we might get an object with source, name, index, etc.
        if sourceInfo instanceof nodes.Base
          # Already a node, ensure it has locationData
          sourceInfo.locationData ?= @defaultLocationData()
        else if typeof sourceInfo is 'object' and not Array.isArray(sourceInfo)
          # It's a source object with properties
          sourceInfo.source = @ensureNode sourceInfo.source if sourceInfo.source and not (sourceInfo.source instanceof nodes.Base)
          sourceInfo.name = @ensureNode sourceInfo.name if sourceInfo.name and not (sourceInfo.name instanceof nodes.Base)
          sourceInfo.index = @ensureNode sourceInfo.index if sourceInfo.index and not (sourceInfo.index instanceof nodes.Base)
        else
          # Convert to node
          sourceInfo = @ensureNode sourceInfo

      loopNode.addSource sourceInfo if loopNode and sourceInfo
      loopNode
    else if directive.addBody?
      # addBody: [loop, body] - add body to loop
      loopNode = @evaluateDirective directive.addBody[0], frame, ruleName
      bodyArg = directive.addBody[1]

      # Handle "Body $N" placeholder
      if typeof bodyArg is 'string' and bodyArg.startsWith('Body $')
        position = parseInt(bodyArg.slice(6))
        bodyNode = @evaluateDirective position, frame, ruleName
      else
        bodyNode = @evaluateDirective bodyArg, frame, ruleName

      # Convert body to proper node if needed
      bodyNode = @toNode(bodyNode) if bodyNode?.type

      # Ensure body is a proper Block node with locationData
      if bodyNode
        # Handle different body types
        if Array.isArray(bodyNode)
          bodyNode = new nodes.Block @filterNodes(bodyNode)
        else if not (bodyNode instanceof nodes.Block)
          bodyNode = new nodes.Block [if bodyNode instanceof nodes.Base then bodyNode else @ensureNode(bodyNode)]
        bodyNode.locationData ?= @defaultLocationData()
      else
        bodyNode = new nodes.Block []
        bodyNode.locationData = @defaultLocationData()

      loopNode.addBody bodyNode if loopNode
      loopNode
    else
      loopNode = @evaluateDirective directive.addBody?[0], frame, ruleName

    # Handle postfix property if specified
    if directive.postfix? and loopNode?
      loopNode.postfix = @evaluateDirective directive.postfix, frame, ruleName

    loopNode

  # Apply $ops operations
  applyOperation: (directive, frame, ruleName) ->
    switch directive.$ops
      when 'array' then @applyArrayOperation directive, frame, ruleName
      when 'value' then @applyValueOperation directive, frame, ruleName
      when 'if' then @applyIfOperation directive, frame, ruleName
      when 'loop' then @applyLoopOperation directive, frame, ruleName
      when 'prop'
        # TODO: Implement property operations (set)
        @evaluateDirective directive.set?.target, frame, ruleName
      else
        new nodes.Literal "/* TODO: $ops #{directive.$ops} */"

  # Legacy dataToClass method (backward compatibility for non-frame calls)
  dataToClass: (node) ->
    return null unless node?
    return node if typeof node in ['string', 'number', 'boolean']

    if Array.isArray node
      return node.map (item) => @dataToClass item

    # For legacy calls without frame, create minimal frame
    if node? and typeof node is 'object'
      if node.type?
        # Already a normalized node - convert directly
        return @solarNodeToClass node
      else
        # Solar directive without frame - limited support
        mockFrame = rhs: [{value: node}]
        return @evaluateDirective node, mockFrame

module.exports = ES5Backend
