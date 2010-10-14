# Override exported methods for non-Node.js engines.

CoffeeScript = require './coffee-script'
CoffeeScript.require = require

# Use standard JavaScript `eval` to eval code.
CoffeeScript.eval = (code, options) ->
  eval CoffeeScript.compile code, options

# Running code does not provide access to this scope.
CoffeeScript.run = (code, options) ->
  options?.bare = on
  Function(CoffeeScript.compile code, options)()

# If we're not in a browser environment, we're finished with the public API.
return unless window?

# Load a remote script from the current domain via XHR.
CoffeeScript.load = (url, options) ->
  xhr = new (window.ActiveXObject or XMLHttpRequest)('Microsoft.XMLHTTP')
  xhr.open 'GET', url, true
  xhr.overrideMimeType 'text/plain' if 'overrideMimeType' of xhr
  xhr.onreadystatechange = ->
    CoffeeScript.run xhr.responseText, options if xhr.readyState is 4
  xhr.send null

# Activate CoffeeScript in the browser by having it compile and evaluate
# all script tags with a content-type of `text/coffeescript`.
# This happens on page load.
runScripts = ->
  for script in document.getElementsByTagName 'script'
    if script.type is 'text/coffeescript'
      if script.src
        CoffeeScript.load script.src
      else
        setTimeout -> CoffeeScript.run script.innerHTML
  null
if window.addEventListener
  addEventListener 'DOMContentLoaded', runScripts, no
else
  attachEvent 'onload', runScripts
