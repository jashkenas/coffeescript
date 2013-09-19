# Macros
# ------

fs = require 'fs'
{throwSyntaxError} = require './helpers'
nodeTypes = require './nodes'

# Compatibility method (IE < 10)
createObject = Object.create
if typeof createObject != 'function'
  createObject = (proto) ->
    f = ->
    f.prototype = proto
    f


# Deep copy a (part of the) AST. Actually, this is just a pretty generic
# ECMAScript 3 expression cloner. (Browser special cases are not supported.)
cloneNode = (src) ->
  return src if typeof src != 'object' || src==null
  return (cloneNode(x) for x in src) if src instanceof Array

  # It's an object, find the prototype and construct an object with it.
  ret = createObject (Object.getPrototypeOf?(src) || src.__proto__  || src.constructor.prototype)
  # And finish by deep copying all own properties.
  ret[key] = cloneNode(val) for own key,val of src
  ret


# Calling `eval` using an alias, causes the code to run outside the callers lexical scope.
evalAlias = eval
getFunc = (func) -> evalAlias "("+func.compile(indent:"")+")"
callFunc = (func, node, utils, args=[]) ->
  try
    return func.apply utils, args
  catch e
    throwSyntaxError "exception in macro: #{e.stack||e}\n\n#{func}\n", node.locationData


# The main work horse.
# `ast` is the node tree for which macro expansion is to be done (the original
# structure will be modified and returned). 
# `csToNodes` is the exports.nodes function of `coffee-script.coffee`. It
# needs to be passed in order to prevent circular requires.
# `options` is a compile options object. The optional `filename` property
# is copied onto each of the nodes, for proper filenames in error reporting.
exports.expand = (ast, csToNodes, options) ->
  # Recursively calls `visit` for every child of `node`. When `visit` returns 
  # `false`, the node is removed from the tree (or replaced by `undefined` if
  # that is not possible). When a node is returned, it is used to replace the
  # original node, and `visit` is called again for the replacing node.
  walkNodes = (node, visit) ->
    return unless node.children
    for name in node.children
      continue unless child = node[name]
      if child instanceof Array
        i = 0
        while item = child[i++]
          res = visit item
          if res # replace (and walk it again)
            child[--i] = res
          else if res==false # delete
            child.splice --i, 1
          else # keep
            walkNodes item, visit
      else
        while (res = visit child) # replace (and walk it again)
          child = node[name] = res
        if res==false # delete (but some node is required)
          node[name] = new nodeTypes.Undefined()
        else # keep
          walkNodes child, visit
    node

  # Define some helper functions, that can be used by the macros. They will
  # get the object as `this`.
  utils =
    # allow access to modules and the environment
    require: require
    # get compiled javascript:
    nodeToJs: (node) -> node.compile(indent:'') if node
    # try to compile and evaluate the node (at compile time) and get the value:
    nodeToVal: (node) -> evalAlias '('+@nodeToJs(node)+')'
    # if the node is a plain identifier, return it as a string:
    nodeToId: (node) -> node.base.value if node.base instanceof nodeTypes.Literal and node.isAssignable() and !node.properties?.length
    # parse `code` as coffeescript (`filename` is for error reporting):
    csToNode: (code,filename) -> csToNodes code, {filename}
    # create a node that includes `code` as a javascript literal (`substitute` will not work on this):
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
    # Walk the node tree, replacing all identifiers that are a key in the `replacements` object, with the value (a node).
    # This is probably still a bit fragile...
    substitute: (node,replacements) -> walkNodes cloneNode(node), (n) ->
      for i,type in ['index','name','source']
        n[type].value = ss if (i or n.source?) and (ss=n[type]?.value) and (ss=replacements[ss])
      ss if (ss=(n.variable?.base?.value || n.base?.value)) and (ss=replacements[ss])?
  # Copy all node classes, so macros can do things like `new @Literal(2)`.
  utils[k] = v for k,v of nodeTypes

  # And now we'll start the actual work.
  macros = {}
  walkNodes ast, (n) ->
    # If we got a filename in our options, attach it to all nodes.
    if options.filename and typeof n.locationData=='object' and !n.locationData.file
      n.locationData.file = options.filename

    name = n.variable?.base?.value
    if name == 'macro' and n.args?.length==1
      if (m = n.args[0]).body
        # execute now: `macro -> console.log 'compiling...'`
        res = callFunc getFunc(m), m, utils
        return (if res instanceof nodeTypes.Base then res else false) # delete if not a node

      if (name = m.variable?.base?.value) and m.args?.length==1 and (funcNode = m.args[0]).body
        # define a macro: `macro someName (a+b) -> a+b`
        macros[name] = getFunc(funcNode)
        return false # delete the node

    if (func = macros[name]) and n.args?.length?
      # execute a macro function.
      res = callFunc func, n, utils, (cloneNode arg for arg in n.args)
      return (if res instanceof nodeTypes.Base then res else false) # delete if not a node

