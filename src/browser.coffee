# Override exported methods for non-Node.js engines.

CoffeeScript = require './coffee-script'
CoffeeScript.require = require

# Use standard JavaScript `eval` to eval code.
CoffeeScript.eval = (code, options) ->
  eval CoffeeScript.compile code, options

# Running code does not provide access to this scope.
CoffeeScript.run = (code, options = {}) ->
  options.bare = on
  Function(CoffeeScript.compile code, options)()

# If we're not in a browser environment, we're finished with the public API.
return unless window?

# Load a remote script from the current domain via XHR
# and run it immediately.
CoffeeScript.load = (url, options) ->
  xhrFetchScript url, (xhr) ->
    CoffeeScript.run xhr.responseText, options if xhr.readyState is 4

# Load a remote script via XMLHttpRequest.
xhrFetchScript = (url, callback) ->
  xhr = new (window.ActiveXObject or XMLHttpRequest)('Microsoft.XMLHTTP')
  xhr.open 'GET', url, true
  xhr.overrideMimeType 'text/plain' if 'overrideMimeType' of xhr
  xhr.onreadystatechange = -> callback xhr
  xhr.send null

# Activate CoffeeScript in the browser by having it compile and evaluate
# all script tags with a content-type of `text/coffeescript`.
# This happens on page load.
runScripts = ->
  for script in document.getElementsByTagName 'script'
    scriptQueue.add script if script.type is 'text/coffeescript'
  return

# The queue ensures that CoffeeScripts are run in the order in which
# the script tags occur on the page. Every time a script is loaded,
# all scripts that are not waiting for a prior script to be loaded
# are run.
scriptQueue =
  pending: []
  next: 0
  runReadyScripts: ->
    CoffeeScript.run @pending[@next++] while @pending[@next]?
  add: (script) ->
    if script.src
      index = @pending.push(null) - 1
      xhrFetchScript script.src, (xhr) =>
        if xhr.readyState is 4
          @pending[index] = xhr.responseText
          @runReadyScripts()
    else
      @pending.push script.innerHTML
      @runReadyScripts()

# Listen for window load, both in browsers and in IE.
if window.addEventListener
  addEventListener 'DOMContentLoaded', runScripts, no
else
  attachEvent 'onload', runScripts
