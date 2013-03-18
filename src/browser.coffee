# Override exported methods for non-Node.js engines.

CoffeeScript = require './coffee-script'
CoffeeScript.require = require

isModernBrowser = if window? then -> true if btoa? and JSON? else ->

compile = (code, options = {}) ->
  res = undefined
  if isModernBrowser()
    options.sourceMap = true
    options.inline = true
    {js, v3SourceMap} = CoffeeScript.compile code, options
    answer = btoa v3SourceMap
    res = "#{js}\n//@ sourceMappingURL=data:application/json;base64,#{answer}\n//@ sourceURL=coffeescript"
  else
    res = CoffeeScript.compile code, options
  res

# Use standard JavaScript `eval` to eval code.
CoffeeScript.eval = (code, options = {}) ->
  options.bare ?= on
  eval compile code, options

# Running code does not provide access to this scope.
CoffeeScript.run = (code, options = {}) ->
  options.bare = on
  Function(compile code, options)()

# If we're not in a browser environment, we're finished with the public API.
return unless window?

# Load a remote script from the current domain via XHR.
CoffeeScript.load = (url, callback, options = {}) ->
  options.sourceFiles = [url]
  xhr = if window.ActiveXObject
    new window.ActiveXObject('Microsoft.XMLHTTP')
  else
    new XMLHttpRequest()
  xhr.open 'GET', url, true
  xhr.overrideMimeType 'text/plain' if 'overrideMimeType' of xhr
  xhr.onreadystatechange = ->
    if xhr.readyState is 4
      if xhr.status in [0, 200]
        CoffeeScript.run xhr.responseText, options
      else
        throw new Error "Could not load #{url}"
      callback() if callback
  xhr.send null

# Activate CoffeeScript in the browser by having it compile and evaluate
# all script tags with a content-type of `text/coffeescript`.
# This happens on page load.
runScripts = ->
  scripts = document.getElementsByTagName 'script'
  coffeetypes = ['text/coffeescript', 'text/literate-coffeescript']
  coffees = (s for s in scripts when s.type in coffeetypes)
  index = 0
  length = coffees.length
  do execute = ->
    script = coffees[index++]
    mediatype = script?.type
    if mediatype in coffeetypes
      options = {literate: mediatype is 'text/literate-coffeescript'}
      if script.src
        CoffeeScript.load script.src, execute, options
      else
        options.sourceFiles = ['embedded']
        CoffeeScript.run script.innerHTML, options
        execute()
  null

# Listen for window load, both in browsers and in IE.
if window.addEventListener
  addEventListener 'DOMContentLoaded', runScripts, no
else
  attachEvent 'onload', runScripts
