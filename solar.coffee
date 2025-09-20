#!/usr/bin/env coffee

# ==============================================================================
# Solar - SLR(1) Parser Generator for CoffeeScript
#
# Clean implementation influenced by Jison, but rewritten in CoffeeScript for
# readability, efficiency, and maintainability.
#
# Author: Steve Shreeve <steve.shreeve@gmail.com>
#   Date: September 15, 2025
# ==============================================================================

VERSION = '1.0.0'

# Token: A terminal symbol that cannot be broken down further
class Token
  constructor: (name, id) ->
    @id   = id   # unique numeric ID for this token
    @name = name # name of this token (terminal) ["NUMBER" or  "+"]

# Type: A nonterminal symbol that can be matched by one or more rules
class Type
  constructor: (name, id) ->
    @id       = id      # unique numeric ID for this type
    @name     = name    # name of this type (nonterminal) ["ForLoop" or "Splat"]
    @rules    = []      # rules that define this type
    @nullable = false   # true if one of the rules can produce no tokens (ε)
    @firsts   = new Set # FIRST set: tokens that can start this type
    @follows  = new Set # FOLLOW set: tokens that can follow this type

# Rule: One possible match for a type (Expr → Expr + Term)
class Rule
  constructor: (type, symbols, id) ->
    @id         = id      # unique numeric ID for this rule
    @type       = type    # type (nonterminal) that this rule defines
    @symbols    = symbols # array of symbols to match ["Expr", "**"", "Expr"]
    @nullable   = false   # true if this rule can produce no tokens (ε)
    @firsts     = new Set # FIRST set: tokens that can start this rule
    @precedence = 0       # operator precedence for conflict resolution

# LR Item: A rule with a dot position and lookaheads (Expr → Expr • + Term)
class Item
  constructor: (rule, lookaheads, dot = 0) ->
    @rule       = rule                      # the rule this item is based on
    @dot        = dot                       # position of the dot in the rule
    @id         = "#{@rule.id}:#{@dot}"     # compact unique ID
    @lookaheads = new Set(lookaheads or []) # lookahead tokens (if any)
    @nextSymbol = @rule.symbols[@dot]       # symbol after dot (if any)

# LR State: A set of items with transitions to other states
class State
  constructor: (items...) ->
    @id           = null           # state number (assigned later)
    @items        = new Set(items) # kernel and closure items
    @transitions  = new Map        # symbol → next state
    @reductions   = new Set        # items that trigger a reduction
    @hasShifts    = false          # if this state has shift actions
    @hasConflicts = false          # has shift/reduce or reduce/reduce conflicts

# ==============================================================================
# SLR(1) Parser Generator
# ==============================================================================

class Generator
  constructor: (grammar, options = {}) ->

    # Configuration
    @options     = { ...grammar.options, ...options }
    @parseParams = grammar.parseParams
    @yy          = {}

    # Detect grammar mode based on export structure
    if grammar.bnf?
      @mode = 'cs2'  # CS2 grammar.coffee with string actions
    else if grammar.grammar?
      @mode = 'cs3'  # CS3 syntax.coffee with directive objects
    else
      throw new Error "Unknown grammar format: expected 'bnf' or 'grammar' property"

    # Grammar structures
    @types     = {}
    @rules     = []
    @operators = {}
    @conflicts = 0

    # Initialize symbol table with special symbols
    @symbolTable = new Map
    @symbolTable.set "$accept", new Type  "$accept", 0
    @symbolTable.set "$end"   , new Token "$end"   , 1
    @symbolTable.set "error"  , new Token "error"  , 2

    # Code generation setup
    @moduleInclude = grammar.moduleInclude or ''
    @actionInclude = grammar.actionInclude and
      if typeof grammar.actionInclude is 'function'
        String(grammar.actionInclude).replace(/^\s*function \(\) \{|\}\s*$/g, '')
      else
        grammar.actionInclude

    # Build parser
    @timing '💥 Total time', =>
      @timing 'processGrammar'   , => @processGrammar grammar # Process grammar rules
      @timing 'buildLRAutomaton' , => @buildLRAutomaton()     # Build LR(0) automaton
      @timing 'processLookaheads', => @processLookaheads()    # Compute FIRST/FOLLOW and assign lookaheads
      @timing 'buildParseTable'  , => @buildParseTable()      # Build parse table with default actions

  # ============================================================================
  # Helper Functions
  # ============================================================================

  timing: (label, fn) ->
    console.time(label)
    result = fn() if fn
    console.timeEnd(label)
    result

  # ============================================================================
  # Grammar Processing
  # ============================================================================

  processGrammar: (grammar) ->
    @_processOperators grammar.operators
    @_buildRules (grammar.grammar or grammar.bnf)
    @_augmentGrammar grammar

  _processOperators: (ops) ->
    if ops
      for precedence, i in ops
        for k in [1...precedence.length]
          @operators[precedence[k]] = {precedence: i + 1, assoc: precedence[0]}
    null # prevent comprehension building above

  _buildRules: (grammar) ->
    actionGroups = {}
    ruleTable    = [0]
    @symbolIds   = {"$accept": 0, "$end": 1, "error": 2}  # Add reserved symbols
    symbolId     = 3 # Next available symbol ID (after special symbols)

    # Add symbol to symbol table if not already present
    addSymbol = (name) =>
      return if not name or @symbolIds[name]

      # Use existing symbol or create a new one
      unless symbol = @symbolTable.get(name)
        id = symbolId++
        symbol = if grammar[name] then new Type(name, id) else new Token(name, id)
        @symbolTable.set name, symbol
      @symbolIds[name] = symbol.id

    # Process types and their rules
    for own type, rules of grammar
      addSymbol type
      @types[type] = @symbolTable.get type

      handles = if typeof rules is 'string' then rules.split(/\s*\|\s*/g) else rules[..]

      for handle in handles
        [symbols, action, precedence] = @_parseHandle handle

        # Add symbols to grammar
        addSymbol symbol for symbol in symbols

        # Track current rule name for ReductionFrame generation
        @currentType = type

        # Process semantic actions
        if action
          action = @_processGrammarAction action, symbols
          label = 'case ' + (@rules.length + 1) + ':'
          actionGroups[action]?.push(label) or actionGroups[action] = [label]

        # Create rule
        rule = new Rule type, symbols, @rules.length + 1

        # Set precedence
        @_assignPrecedence rule, precedence

        @rules.push rule
        ruleTable.push [@symbolIds[type], if symbols[0] is '' then 0 else symbols.length]
        @types[type].rules.push rule

    # Generate parser components
    actionsCode = @_generateActionCode actionGroups
    @ruleData = ruleTable
    @_buildTokenMappings()

    parameters = "yytext, yyleng, yylineno, yy, yystate, $$, _$"
    parameters += ', ' + @parseParams.join(', ') if @parseParams

    @performAction = "function anonymous(#{parameters}) {\n#{actionsCode}\n}"

  _parseHandle: (handle) ->
    if Array.isArray handle
      symbols = if typeof handle[0] is 'string' then handle[0].trim().split(' ') else handle[0][..]
      symbols = symbols.map (e) -> e.replace(/\[[a-zA-Z_][a-zA-Z0-9_-]*\]/g, '')

      action = if typeof handle[1] is 'string' or handle.length is 3 then handle[1] else null
      precedence = if handle[2] then handle[2] else if handle[1] and typeof handle[1] isnt 'string' then handle[1] else null

      [symbols, action, precedence]
    else
      handle = handle.replace /\[[a-zA-Z_][a-zA-Z0-9_-]*\]/g, ''
      symbols = handle.trim().split ' '
      [symbols, null, null]

  _processGrammarAction: (action, symbols) ->
    # Main dispatcher - handles both CS2 and CS3 formats
    if @mode is 'cs3' and typeof action is 'object' and action?
      @_generateDataAction(action, symbols)
    else if @mode is 'cs2' and typeof action is 'string'
      @_generateClassAction(action, symbols)
    else if action is null or action is undefined
      # Default pass-through: for single-symbol rules, return $1; for ε, null
      if symbols.length is 0 then 'return null;' else 'return $$[1];'
    else
      throw new Error "Invalid action type for mode #{@mode}: #{typeof action}"

  _generateClassAction: (action, symbols) ->
    # CS2 mode: process string actions like "-> new Value $1"
    # Process named semantic values
    if action.match(/[$@][a-zA-Z][a-zA-Z0-9_]*/)
      count = {}
      names = {}

      for token, i in symbols
        symbols_i = token.match(/\[[a-zA-Z][a-zA-Z0-9_-]*\]/) # Like [var]
        if symbols_i
          symbols_i = symbols_i[0].slice(1, -1)
        else
          symbols_i = token

        if names[symbols_i]
          names[symbols_i + (++count[symbols_i])] = i + 1
        else
          names[symbols_i] = i + 1
          names[symbols_i + "1"] = i + 1
          count[symbols_i] = 1

      action = action
        .replace /\$([a-zA-Z][a-zA-Z0-9_]*)/g, (str, pl) -> if names[pl] then '$' + names[pl] else str # Like $var
        .replace  /@([a-zA-Z][a-zA-Z0-9_]*)/g, (str, pl) -> if names[pl] then '@' + names[pl] else str # Like @var

    # Transform $$ and positional references
    action
      .replace(/([^'"])\$\$|^\$\$/g, '$1this.$') # Like $$var
      .replace(/@[0$]/g, "this._$") # Like @var
      .replace(/\$(-?\d+)/g, (_, n) -> "$$[$0" + (parseInt(n, 10) - symbols.length || '') + "]") # Like $1
      .replace( /@(-?\d+)/g, (_, n) -> "_$[$0" +               (n - symbols.length || '') + "]") # Like @1

  # Call reduce function with count then directive
  _generateDataAction: (directive, symbols) ->
    len = symbols.length
    dir = @_objectToJSUnresolved(directive)
    "return r(#{len}, #{dir});"

  _needsQuotes: (key) -> not /^[$_a-zA-Z][$_a-zA-Z0-9]*$/.test(key)

  # Generate directive object with unresolved position references
  _objectToJSUnresolved: (obj) ->
    return 'null' unless obj?

    if typeof obj is 'number'
      # Keep position reference as number (don't resolve to $$[N])
      "#{obj}"
    else if typeof obj is 'string'
      JSON.stringify(obj)
    else if typeof obj is 'boolean'
      JSON.stringify(obj)
    else if Array.isArray(obj)
      items = (if typeof item is 'object' and item? then @_objectToJSUnresolved(item) else JSON.stringify(item) for item in obj)
      "[#{items.join(', ')}]"
    else if typeof obj is 'object'
      props = []
      for key, value of obj
        # Format key - only quote if necessary
        keyStr = if @_needsQuotes(key) then JSON.stringify(key) else key

        # Replace $ast: '@' with the actual rule name
        if key is '$ast' and value is '@'
          props.push "#{keyStr}: #{JSON.stringify(@currentType)}"
        else if typeof value is 'number'
          props.push "#{keyStr}: #{value}"  # Keep as position number
        else if typeof value is 'object' and value?
          props.push "#{keyStr}: #{@_objectToJSUnresolved(value)}"
        else
          props.push "#{keyStr}: #{JSON.stringify(value)}"
      "{#{props.join(', ')}}"
    else
      JSON.stringify(obj)

  _objectToJS: (obj, symbols) ->
    return 'null' unless obj?

    if typeof obj is 'number'
      # Position reference
      "$$[#{obj}]"
    else if typeof obj is 'string'
      JSON.stringify(obj)
    else if typeof obj is 'boolean'
      JSON.stringify(obj)
    else if Array.isArray(obj)
      # Array of directives
      items = (if typeof item is 'object' then @_objectToJS(item, symbols) else JSON.stringify(item) for item in obj)
      "[#{items.join(', ')}]"
    else if typeof obj is 'object'
      # Object with properties
      props = []
      for key, value of obj
        if typeof value is 'number'
          props.push "#{JSON.stringify(key)}: $$[#{value}]"
        else if typeof value is 'object' and value?
          props.push "#{JSON.stringify(key)}: #{@_objectToJS(value, symbols)}"
        else
          props.push "#{JSON.stringify(key)}: #{JSON.stringify(value)}"

      "{#{props.join(', ')}}"
    else
      JSON.stringify(obj)

  _assignPrecedence: (rule, precedence) ->
    if precedence?.prec and @operators[precedence.prec]
      rule.precedence = @operators[precedence.prec].precedence
    else if rule.precedence is 0
      # Use rightmost token's precedence
      for token in rule.symbols by -1
        if @operators[token] and not @types[token]
          rule.precedence = @operators[token].precedence
          break

  _generateActionCode: (actionGroups) ->
    actions = []

    # Add mode-specific setup
    if @mode is 'cs3'
      # CS3: Add reduce function (r) - curried with $$, _$ for efficient backend calls
      actions.push @actionInclude or ''
      actions.push 'var r = yy.backend && function(count, directive) { return yy.backend.reduce($$, _$, $$.length - 1, count, directive); };'
    else
      # CS2: Add comment about this context and $0 variable
      actions.push '/* this == yyval */'
      actions.push @actionInclude or ''
      actions.push 'var $0 = $$.length - 1;'

    actions.push 'switch (yystate) {'
    for action, labels of actionGroups
      actions.push labels.join(' ')
      actions.push action
      # Only add break if the action doesn't start with 'return' (all CS3 actions return)
      actions.push 'break;' unless action.trim().startsWith('return')
    actions.push '}'

    actions.join('\n')
      .replace(/YYABORT/g, 'return false')
      .replace(/YYACCEPT/g, 'return true')

  _buildTokenMappings: ->
    @tokenNames = {}

    for own name, id of @symbolIds when id >= 2
      unless @types[name]
        @tokenNames[id] = name

  _augmentGrammar: (grammar) ->
    throw new Error "Grammar error: no rules defined." if @rules.length is 0

    @start = grammar.start or @rules[0].type
    unless @types[@start]
      throw new Error "Grammar error: no start symbol '#{@start}' defined."

    acceptRule = new Rule "$accept", [@start, "$end"], 0
    @rules.push acceptRule
    @acceptRuleIndex = @rules.length - 1

    @types.$accept = @symbolTable.get "$accept"
    @types.$accept.rules.push acceptRule
    @types[@start].follows.add "$end"

  # ============================================================================
  # LR Automaton Construction
  # ============================================================================

  buildLRAutomaton: ->
    acceptItem = new Item @rules[@acceptRuleIndex]
    firstState = @_closure new State(acceptItem)
    firstState.id = 0
    firstState.signature = @_computeStateSignature(firstState)

    states = [firstState]
    stateMap = new Map # stateSignature -> state index
    stateMap.set firstState.signature, 0

    # Build automaton by exploring all transitions
    marked = 0
    while marked < states.length
      itemSet = states[marked++]
      symbols = new Set
      for item from itemSet.items when symbol = item.nextSymbol
        if symbol isnt '$end'
          symbols.add symbol
      for symbol from symbols
        @_insertState symbol, itemSet, states, stateMap

    @states = states

  # Calculate unique identifier for a state based on its items
  _computeStateSignature: (state) ->
    ids = (item.id for item from state.items)
    ids.sort((a, b) -> a - b).join('|')

  # Compute closure of an LR item set (lookaheads assigned later using FOLLOW sets)
  _closure: (itemSet) ->
    closureSet = new State
    workingSet = new Set itemSet.items
    itemCores  = new Map # item.id -> item

    # Process all items
    while workingSet.size > 0
      newItems = new Set

      # Only process item cores we haven't yet seen
      for item from workingSet when !itemCores.has(item.id)

        # Add item to closure
        closureSet.items.add(item)
        itemCores.set(item.id, item)

        # Check item type
        {nextSymbol} = item

        if not nextSymbol
          # Reduction item
          closureSet.reductions.add(item)
          closureSet.hasConflicts = closureSet.reductions.size > 1 or closureSet.hasShifts
        else if not @types[nextSymbol]
          # Shift item (token)
          closureSet.hasShifts = true
          closureSet.hasConflicts = closureSet.reductions.size > 0
        else
          # Type - add items for all its rules
          type = @types[nextSymbol]
          for rule in type.rules
            # Create [B → •γ] with empty lookaheads (will be filled by FOLLOW sets later)
            newItem = new Item rule
            newItems.add(newItem) unless itemCores.has(newItem.id)

      workingSet = newItems

    closureSet

  # Compute GOTO(state, symbol) - transitions from one state to another
  _goto: (itemSet, symbol) ->
    gotoSet = new State

    for item from itemSet.items when item.nextSymbol is symbol
      # Create advanced item (lookaheads will be set from FOLLOW sets later)
      newItem = new Item item.rule, null, item.dot + 1
      gotoSet.items.add newItem

    if gotoSet.items.size is 0 then gotoSet else @_closure gotoSet

  # Insert new state into automaton
  _insertState: (symbol, itemSet, states, stateMap) ->
    # Build kernel signature (advanced items) before computing closure
    kernel = []
    for item from itemSet.items when item.nextSymbol is symbol
      kernel.push [item.rule.id, item.dot + 1]
    return unless kernel.length

    kernel.sort (a, b) -> (a[0] - b[0]) or (a[1] - b[1])
    kernelSig = (pid + '.' + pos for [pid, pos] in kernel).join '|'

    existing = stateMap.get kernelSig
    if existing?
      itemSet.transitions.set symbol, existing
      return

    # Kernel is new; compute closure now
    gotoSet = @_goto itemSet, symbol
    return unless gotoSet.items.size > 0

    gotoSet.signature = kernelSig
    gotoSet.id = states.length
    stateMap.set kernelSig, gotoSet.id
    itemSet.transitions.set symbol, gotoSet.id
    states.push gotoSet

  # ============================================================================
  # Lookahead Computation - SLR(1) Algorithm
  # ============================================================================

  processLookaheads: ->
    @processLookaheads = ->  # Computes once; no-op on subsequent calls
    @_computeNullableSets()  # ε-derivable symbols
    @_computeFirstSets()     # First tokens
    @_computeFollowSets()    # Following tokens
    @_assignItemLookaheads() # FOLLOW(A) → item lookaheads

  # Determine nullable symbols (can derive ε)
  _computeNullableSets: ->
    changed = true
    while changed
      changed = false

      # Mark rules nullable if all handle symbols are nullable
      for rule in @rules when not rule.nullable
        if rule.symbols.every (symbol) => @_isNullable symbol
          rule.nullable = changed = true

      # Propagate to types
      for symbol, type of @types when not @_isNullable symbol
        if type.rules.some (p) -> p.nullable
          type.nullable = changed = true

  _isNullable: (symbol) ->
    return true if symbol is ''
    return symbol.every((s) => @_isNullable s) if Array.isArray symbol
    @types[symbol]?.nullable or false

  # Compute FIRST sets (tokens that can begin derivations)
  _computeFirstSets: ->
    changed = true
    while changed
      changed = false

      for rule in @rules
        firsts = @_computeFirst rule.symbols
        oldSize = rule.firsts.size
        rule.firsts.clear()
        firsts.forEach (item) => rule.firsts.add item
        changed = true if rule.firsts.size > oldSize

      for symbol, type of @types
        oldSize = type.firsts.size
        type.firsts.clear()
        for rule in type.rules
          rule.firsts.forEach (s) => type.firsts.add s
        changed = true if type.firsts.size > oldSize

  _computeFirst: (symbols) ->
    return new Set if symbols is ''
    return @_computeFirstOfSequence symbols if Array.isArray symbols
    return new Set([symbols]) unless @types[symbols]
    @types[symbols].firsts

  _computeFirstOfSequence: (symbols) ->
    firsts = new Set
    for symbol in symbols
      if @types[symbol]
        @types[symbol].firsts.forEach (s) => firsts.add s
      else
        firsts.add symbol
      break unless @_isNullable symbol
    firsts

  # Compute FOLLOW sets (tokens that can follow types)
  _computeFollowSets: ->
    changed = true
    while changed
      changed = false

      for rule in @rules
        for symbol, i in rule.symbols when @types[symbol]
          oldSize = @types[symbol].follows.size

          if i is rule.symbols.length - 1
            # Symbol at end: add FOLLOW(LHS)
            @types[rule.type].follows.forEach (item) =>
              @types[symbol].follows.add item
          else
            # Add FIRST(β) where β follows symbol
            beta = rule.symbols[i + 1..]
            firstSet = @_computeFirst beta

            firstSet.forEach (item) => @types[symbol].follows.add item

            # If β is nullable, also add FOLLOW(LHS)
            if @_isNullable beta
              @types[rule.type].follows.forEach (item) =>
                @types[symbol].follows.add item

          changed = true if @types[symbol].follows.size > oldSize

  # Assign FOLLOW sets to reduction items
  _assignItemLookaheads: ->
    for state in @states
      for item from state.reductions
        follows = @types[item.rule.type]?.follows
        if follows
          item.lookaheads.clear()
          item.lookaheads.add token for token from follows

  # ============================================================================
  # Parse Table Generation
  # ============================================================================

  buildParseTable: (itemSets = @states) ->
    states = []
    {types, operators} = this
    [NONASSOC, SHIFT, REDUCE, ACCEPT] = [0, 1, 2, 3]

    for itemSet, k in itemSets
      state = states[k] = {}

      # Shift and goto actions
      for [stackSymbol, gotoState] from itemSet.transitions when @symbolIds[stackSymbol]?
        for item from itemSet.items when item.nextSymbol is stackSymbol
          if types[stackSymbol]
            state[@symbolIds[stackSymbol]] = gotoState
          else
            state[@symbolIds[stackSymbol]] = [SHIFT, gotoState]

      # Accept action
      for item from itemSet.items when item.nextSymbol is "$end" and @symbolIds["$end"]?
        state[@symbolIds["$end"]] = [ACCEPT]

      # Reduce actions
      for item from itemSet.reductions
        for stackSymbol from item.lookaheads when @symbolIds[stackSymbol]?
          action = state[@symbolIds[stackSymbol]]
          op = operators[stackSymbol]

          if action
            # Resolve conflict
            which = if action[0] instanceof Array then action[0] else action
            solution = @_resolveConflict item.rule, op, [REDUCE, item.rule.id], which

            if solution.bydefault
              @conflicts++
            else
              action = solution.action
          else
            action = [REDUCE, item.rule.id]

          if action?.length
            state[@symbolIds[stackSymbol]] = action
          else if action is NONASSOC
            state[@symbolIds[stackSymbol]] = undefined

    @_computeDefaultActions @parseTable = states

  # Resolve conflicts using precedence and associativity
  _resolveConflict: (rule, op, reduce, shift) ->
    solution = {rule, operator: op, r: reduce, s: shift}
    [NONASSOC, SHIFT, REDUCE] = [0, 1, 2]

    if shift[0] is REDUCE
      solution.action = if shift[1] < reduce[1] then shift else reduce
      solution.bydefault = true if shift[1] isnt reduce[1]
      return solution

    if rule.precedence is 0 or not op
      solution.bydefault = true
      solution.action = shift
    else if rule.precedence < op.precedence
      solution.action = shift
    else if rule.precedence is op.precedence
      solution.action = switch op.assoc
        when "right" then shift
        when "left" then reduce
        when "nonassoc" then NONASSOC
        else shift
    else
      solution.action = reduce

    solution

  # Compute default actions for single-action states
  _computeDefaultActions: (states) ->
    defaults = {}
    for state, k in states
      actionCount = 0
      lastAction = null

      for own action of state
        actionCount++
        lastAction = state[action]

      defaults[k] = lastAction if actionCount is 1 and lastAction[0] is 2

    @defaultActions = defaults

  # ============================================================================
  # Code Generation
  # ============================================================================

  generate: (options = {}) ->
    @options = { ...@options, ...options }
    parserCode = @generateCommonJSModule @options

    if @options.compress
      @_compressParser parserCode
    else
      parserCode

  generateCommonJSModule: (options = {}) ->
    moduleName = options.moduleName or "parser"
    moduleName = "parser" unless moduleName.match /^[A-Za-z_$][A-Za-z0-9_$]*$/

    @generateModule(options) + """
      \n
      if (typeof require !== 'undefined' && typeof exports !== 'undefined') {
        exports.parser = #{moduleName};
        exports.Parser = #{moduleName}.Parser;
        exports.parse = function () { return #{moduleName}.parse.apply(#{moduleName}, arguments); };
        exports.main = function() {};
        if (typeof module !== 'undefined' && require.main === module) { exports.main(process.argv.slice(1)); }
      }
      """

  generateModule: (options = {}) ->
    moduleName = options.moduleName or "parser"
    out = "/* Parser generated by Solar #{VERSION} */\n"
    out += if moduleName.match /\./ then moduleName else "var #{moduleName}"
    out += " = #{@generateModuleExpr()}"

  generateModuleExpr: ->
    module = @_generateModuleCore()
    """
    (function(){
      var hasProp = {}.hasOwnProperty;
      #{module.commonCode}
      var parser = #{module.moduleCode};
      #{@moduleInclude}
      function Parser () { this.yy = {}; }
      Parser.prototype = parser;
      parser.Parser = Parser;
      return new Parser;
    })();
    """

  _generateModuleCore: ->
    tableCode = @_generateTableCode @parseTable

    moduleCode = """{
      trace: function trace() {},
      yy: {},
      symbolIds: #{JSON.stringify @symbolIds},
      tokenNames: #{JSON.stringify(@tokenNames).replace /"([0-9]+)":/g, "$1:"},
      ruleData: #{JSON.stringify @ruleData},
      parseTable: #{tableCode.moduleCode},
      defaultActions: #{JSON.stringify(@defaultActions).replace /"([0-9]+)":/g, "$1:"},
      performAction: #{@performAction},
      parseError: function #{@parseError},
      parse: function #{@parse}
    }"""

    {commonCode: tableCode.commonCode, moduleCode}

  _generateTableCode: (stateTable) ->
    moduleCode = JSON.stringify(stateTable, null, 0).replace /"([0-9]+)"(?=:)/g, "$1"
    {commonCode: '', moduleCode}

  _compressParser: (parserCode) ->
    # Compress the entire parser with Brotli
    compressedData = @_brotliCompress parserCode

    """
    /* Brotli-compressed parser generated by Solar #{VERSION} */
    (function() {
      // Brotli decompression (requires Node.js with Brotli support)
      function loadBrotliDecoder() {
        if (typeof require !== 'undefined') {
          try {
            // Try built-in Node.js zlib brotli first (Node 12+)
            const zlib = require('zlib');
            if (zlib.brotliDecompressSync) {
              return function(buffer) {
                return zlib.brotliDecompressSync(buffer);
              };
            }
          } catch (e) {}

          try {
            // Fallback to brotli package
            const brotli = require('brotli');
            return function(buffer) {
              return Buffer.from(brotli.decompress(new Uint8Array(buffer)));
            };
          } catch (e) {
            throw new Error('Brotli decompression not available. This parser requires Brotli support. Please install the brotli package or use Node.js 12+.');
          }
        }
        throw new Error('This compressed parser requires Node.js environment with Brotli support.');
      }

      // Decompress and evaluate the parser
      const brotliDecode = loadBrotliDecoder();
      const compressedBuffer = Buffer.from('#{compressedData}', 'base64');
      const decompressedBuffer = brotliDecode(compressedBuffer);
      const parserCode = decompressedBuffer.toString('utf8');

      // Evaluate the decompressed parser code
      return eval(parserCode);
    })();
    """

  _brotliCompress: (data) ->
    try
      if typeof require isnt 'undefined'
        # Try Node.js built-in zlib brotli first
        zlib = require 'zlib'
        if zlib.brotliCompressSync
          compressed = zlib.brotliCompressSync Buffer.from(data)
          return compressed.toString 'base64'

        # Fallback to brotli package
        brotli = require 'brotli'
        compressed = brotli.compress Buffer.from(data)
        return Buffer.from(compressed).toString 'base64'
      else
        throw new Error 'Brotli compression requires Node.js environment'
    catch error
      throw new Error "Brotli compression failed: #{error.message}. Please ensure Brotli is available (Node.js 12+ or install 'brotli' package)."

  # ============================================================================
  # Runtime Parser
  # ============================================================================

  parseError: (str, hash) ->
    if hash.recoverable
      @trace str
    else
      error = new Error str
      error.hash = hash
      throw error

  parse: (input) ->
    [stk, val, loc] = [[0], [null], []]
    [parseTable, yytext, yylineno, yyleng, recovering] = [@parseTable, '', 0, 0, 0]
    [TERROR, EOF] = [2, 1]

    lexer = Object.create @lexer
    sharedState = {yy: {}}
    sharedState.yy[k] = v for own k, v of @yy

    lexer.setInput input, sharedState.yy
    [sharedState.yy.lexer, sharedState.yy.parser] = [lexer, this]

    lexer.yylloc = {} unless lexer.yylloc?
    yyloc = lexer.yylloc
    loc.push yyloc

    ranges = lexer.options?.ranges

    @parseError = if typeof sharedState.yy.parseError is 'function'
      sharedState.yy.parseError
    else
      Object.getPrototypeOf(this).parseError

    lex = =>
      token = lexer.lex() or EOF
      token = @symbolIds[token] or token unless typeof token is 'number'
      token

    [symbol, preErrorSymbol, state, action, r, yyval, p, len, newState, expected] =
      [null, null, null, null, null, {}, null, null, null, null]

    loop
      state = stk[stk.length - 1]
      action = @defaultActions[state] or (
        symbol = lex() if not symbol?
        parseTable[state]?[symbol]
      )

      unless action?.length and action[0]
        errStr = ''
        unless recovering
          expected = ("'#{@tokenNames[p]}'" for own p of parseTable[state] when @tokenNames[p] and p > TERROR)
        errStr = if lexer.showPosition
          "Parse error on line #{yylineno + 1}:\n#{lexer.showPosition()}\nExpecting #{expected.join(', ')}, got '#{@tokenNames[symbol] or symbol}'"
        else
          "Parse error on line #{yylineno + 1}: Unexpected #{if symbol is EOF then "end of input" else "'#{@tokenNames[symbol] or symbol}'"}"

          @parseError errStr, {
            text: lexer.match
            token: @tokenNames[symbol] or symbol
            line: lexer.yylineno
            loc: yyloc
            expected
          }
        throw new Error errStr

      throw new Error "Parse Error: multiple actions possible at state: #{state}, token: #{symbol}" if action[0] instanceof Array and action.length > 1

      switch action[0]
        when 1 # shift
          stk.push symbol, action[1]
          val.push lexer.yytext
          loc.push lexer.yylloc
          symbol = null
          unless preErrorSymbol
            [yyleng, yytext, yylineno, yyloc] = [lexer.yyleng, lexer.yytext, lexer.yylineno, lexer.yylloc]
            recovering-- if recovering > 0
          else
            [symbol, preErrorSymbol] = [preErrorSymbol, null]

        when 2 # reduce
          len = @ruleData[action[1]][1]
          yyval.$ = val[val.length - len]
          [locFirst, locLast] = [loc[loc.length - (len or 1)], loc[loc.length - 1]]
          yyval._$ = {
            first_line: locFirst.first_line, last_line: locLast.last_line
            first_column: locFirst.first_column, last_column: locLast.last_column
          }
          yyval._$.range = [locFirst.range[0], locLast.range[1]] if ranges

          r = @performAction.apply yyval, [yytext, yyleng, yylineno, sharedState.yy, action[1], val, loc]
          yyval.$ = r if r?

          if len
            stk.length -= len * 2
            val.length -= len
            loc.length -= len

          stk.push @ruleData[action[1]][0]
          val.push yyval.$
          loc.push yyval._$
          newState = parseTable[stk[stk.length - 2]][stk[stk.length - 1]]
          stk.push newState

        when 3 # accept
          return val[val.length - 1]

  trace: (msg) -> # Debug output (no-op by default)
    console.log msg if @options?.debug

  createParser: ->
    parser = eval @generateModuleExpr()
    parser.rules = @rules

    bindMethod = (method) => => @lexer = parser.lexer; @[method].apply this, arguments

    parser.lexer = @lexer
    parser.generate = bindMethod 'generate'
    parser.generateModule = bindMethod 'generateModule'
    parser.generateCommonJSModule = bindMethod 'generateCommonJSModule'

    parser

# ==============================================================================
# Exports
# ==============================================================================

Solar = exports.Solar = exports

Solar.Parser = (grammar, options) ->
  generator = new Generator grammar, options
  generator.createParser()

exports.Generator = Generator

Solar.Generator = (g, options) ->
  new Generator g, Object.assign({}, g.options, options)

exports.Parser = (grammar, options) ->
  generator = Solar.Generator grammar, options
  generator.createParser()

# ==============================================================================
# CLI Interface
# ==============================================================================

if require.main is module
  fs = require 'fs'
  path = require 'path'

  showHelp = ->
    console.log """
    Solar - SLR(1) Parser Generator
    ===============================

    Usage: coffee solar.coffee [options] [grammar-file]

    Options:
      -h, --help              Show this help
      -s, --stats             Show grammar statistics
      -g, --generate          Generate parser (default)
      -o, --output <file>     Output file (default: parser.js)
      -c, --compress          Compress parser with Brotli (requires Brotli support)
      -v, --verbose           Verbose output

    Examples:
      coffee solar.coffee grammar.coffee
      coffee solar.coffee --stats grammar.coffee
      coffee solar.coffee -c -o parser.js grammar.coffee
      coffee solar.coffee --compress --output parser.js grammar.coffee
    """

  showStats = (generator) ->
    tokens = Object.keys(generator.tokenNames or {}).length
    types = Object.keys(generator.types or {}).length
    rules = generator.rules?.length or 0
    states = generator.states?.length or 0
    conflicts = generator.conflicts or 0

    console.log """

    ⏱️ Statistics:
    • Tokens: #{tokens}
    • Types: #{types}
    • Rules: #{rules}
    • States: #{states}
    • Conflicts: #{conflicts}
    """

  # Parse command line
  options = {help: false, stats: false, generate: false, output: 'parser.js', verbose: false, compress: false}
  grammarFile = null

  i = 0
  while i < process.argv.length - 2
    arg = process.argv[i + 2]
    switch arg
      when '-h', '--help'     then options.help     = true
      when '-s', '--stats'    then options.stats    = true
      when '-g', '--generate' then options.generate = true
      when '-o', '--output'   then options.output   = process.argv[++i + 2]
      when '-v', '--verbose'  then options.verbose  = true
      when '-c', '--compress' then options.compress = true
      else grammarFile = arg unless arg.startsWith('-')
    i++

  if options.help or not grammarFile
    showHelp()
    process.exit 0

  try
    unless fs.existsSync grammarFile
      console.error "Grammar file not found: #{grammarFile}"
      process.exit 1

    # Load grammar
    grammar = if grammarFile.endsWith('.coffee')
      require(path.resolve(grammarFile))
    else if grammarFile.endsWith('.json')
      JSON.parse fs.readFileSync(grammarFile, 'utf8')
    else
      throw new Error "Unsupported format. Use .coffee or .json"
    unless grammar
      throw new Error "Failed to load grammar"

    # Generate parser
    generator = new Generator grammar, options

    if options.stats
      showStats generator

    if options.generate or not options.stats
      parserCode = generator.generate()
      fs.writeFileSync options.output, parserCode
      console.log "\nParser generated: #{options.output}"

  catch error
    console.error "Error:", error.message
    console.error error.stack if options.verbose
    process.exit 1
