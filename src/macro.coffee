# Macros
# ------

fs = require 'fs'
{throwSyntaxError,locationDataToString} = require './helpers'
nodeTypes = require './nodes'

# Calling `eval` using an alias, causes the code to run outside the callers lexical scope.
evalAlias = eval
getFunc = (func) -> evalAlias "("+func.compile(indent:"")+")"


# The main work horse.
# `ast` is the node tree for which macro expansion is to be done (the original
# structure will be modified and returned). 
# `csToNodes` is the exports.nodes function of `coffee-script.coffee`. It
# needs to be passed in order to prevent circular requires.
exports.expand = (ast, csToNodes) ->
  # The `context` is the this-object passed to all compile-time executions.
  # It can be used to define compile-time functions or state.
  root.cfg = context = {}
  # Define some helper functions, that can be used by the macros. They will
  # be accessible through `root.macro`.
  root.macro = utils =
    # allow access to modules and the environment
    require: require
    # try to expand macros, compile and evaluate the node (at compile time) and get the value:
    nodeToVal: (node) -> getFunc(new @Code([], new @Block([node]))).call context if node
    # if the node is a plain identifier, return it as a string:
    nodeToId: (node) -> node.base.value if node.base instanceof nodeTypes.Literal and node.isAssignable() and !node.properties?.length
    # parse `code` as coffeescript (`filename` is for error reporting):
    csToNode: (code,filename) -> csToNodes code, {filename}
    # create a node that includes `code` as a javascript literal
    jsToNode: (code) -> new nodeTypes.Literal code || "void 0"
    # convert `expr` to a node (only works for jsonable expressions):
    valToNode: (expr) -> @jsToNode JSON.stringify expr
    # read `filename` and parse it (as a js literal when `lang=='js'` or .js extension):
    fileToNode: (filename, lang) ->
      code = fs.readFileSync filename, 'utf8'
      code = code.substr 1 if code.charCodeAt(0)==0xFEFF
      if lang=='js' or (!lang and filename.match /\.js$/)
        @jsToNode code
      else
        @csToNode code, filename
    _codeNodes: []
  # Copy all node classes, so macros can do things like `new @Literal(2)`.
  utils[k] = v for k,v of nodeTypes

  getCalleeName = (node) ->
    if node instanceof nodeTypes.Call and (name = node.variable?.base?.value)
      name += '.'+prop?.name?.value for prop in node.variable.properties
      name

  # Define our lookup-table of macros. We'll start with just these two.
  utils._macros =

    # The `macro` keyword itself is implemented as a predefined macro.
    macro: (arg) ->
      throw new Error("macro expects 1 argument, got #{arguments.length}") unless arguments.length==1
      if arg instanceof nodeTypes.Code
        # execute now: `macro -> console.log 'compiling...'`
        throw new Error 'macro expects a closure without parameters' if arg.params.length
        return getFunc(arg).call context
      if (name = getCalleeName(arg))
        # define a macro: `macro someName (a,b) -> a+b`
        throw new Error("macro expects a closure after identifier") unless arg.args.length==1 and arg.args[0] instanceof nodeTypes.Code
        utils._macros[name] = getFunc arg.args[0]
        return
      throw new Error("macro expects a closure or identifier")

    # `macro.codeToNode` cannot be implemented like the other compile-time
    # helper methods, because it needs to capture the AST of its argument,
    # instead of the value.
	# Although there is currently nothing to prevent calling this helper
	# from outside a macro definition, doing so makes no sense.
    "macro.codeToNode": (func) ->
      if func not instanceof nodeTypes.Code or func.params.length
        throw new Error 'macro.codeToNode expects a function (without arguments)'
      num = utils._codeNodes.length
      utils._codeNodes.push func.body
      utils.jsToNode "macro._codeNodes[#{num}]"
  
  # And now we'll start the actual work.
  nodeTypes.walk ast, (n) ->
    if (name = getCalleeName(n)) and (func = utils._macros[name])
      # execute a macro function.
      try
        utils.caller = locationDataToString n.locationData
        res = func.apply context, n.args
      catch e
        throwSyntaxError e.message, n.locationData
      return (if res instanceof nodeTypes.Base then res else false) # delete if not a node

