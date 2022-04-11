{ getSourceMap } = require "./sourcemap"

attach = (stackRoot) ->
  # Based on http://v8.googlecode.com/svn/branches/bleeding_edge/src/messages.js
  # Modified to handle sourceMap
  formatSourcePosition = (frame, getSourceMapping) ->
    filename = undefined
    fileLocation = ''

    if frame.isNative()
      fileLocation = "native"
    else
      if frame.isEval()
        filename = frame.getScriptNameOrSourceURL()
        fileLocation = "#{frame.getEvalOrigin()}, " unless filename
      else
        filename = frame.getFileName()

      filename or= "<anonymous>"

      line = frame.getLineNumber()
      column = frame.getColumnNumber()

      # Check for a sourceMap position
      source = getSourceMapping filename, line, column
      fileLocation =
        if source
          "#{filename}:#{source[0]}:#{source[1]}"
        else
          "#{filename}:#{line}:#{column}"

    functionName = frame.getFunctionName()
    isConstructor = frame.isConstructor()
    isMethodCall = not (frame.isToplevel() or isConstructor)

    if isMethodCall
      methodName = frame.getMethodName()
      typeName = frame.getTypeName()

      if functionName
        tp = as = ''
        if typeName and functionName.indexOf typeName
          tp = "#{typeName}."
        if methodName and functionName.indexOf(".#{methodName}") isnt functionName.length - methodName.length - 1
          as = " [as #{methodName}]"

        "#{tp}#{functionName}#{as} (#{fileLocation})"
      else
        "#{typeName}.#{methodName or '<anonymous>'} (#{fileLocation})"
    else if isConstructor
      "new #{functionName or '<anonymous>'} (#{fileLocation})"
    else if functionName
      "#{functionName} (#{fileLocation})"
    else
      fileLocation

  getSourceMapping = (filename, line, column) ->
    sourceMap = getSourceMap filename, line, column

    answer = sourceMap.sourceLocation [line - 1, column - 1] if sourceMap?
    if answer? then [answer[0] + 1, answer[1] + 1] else null

  # Based on [michaelficarra/CoffeeScriptRedux](http://goo.gl/ZTx1p)
  # NodeJS / V8 have no support for transforming positions in stack traces using
  # sourceMap, so we must monkey-patch Error to display CoffeeScript source
  # positions.
  Error.prepareStackTrace = (err, stack) ->
    frames = for frame in stack
      # Don't display stack frames deeper than the stack root `CoffeeScript.run`
      # for example.
      break if stackRoot and (frame.getFunction() is stackRoot)
      "    at #{formatSourcePosition frame, getSourceMapping}"

    "#{err.toString()}\n#{frames.join '\n'}\n"

module.exports = {
  attach
}
