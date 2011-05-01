# Override exported methods for non-Node.js engines.
CoffeeScript = require './coffee-script'
CoffeeScript.require = require

# Capture the global object in browsers and CommonJS environments.
global = do -> @

# Use standard JavaScript `eval` to eval code.
CoffeeScript.eval = (code, options = {}) ->
  eval CoffeeScript.compile code, options

# Running code does not provide access to this scope.
CoffeeScript.run = (code, options = {}, callback) ->
  options.bare = on if not ('bare' of options)
  error = null
  try Function(CoffeeScript.compile code, options)() catch exception then error = exception
  callback? error

# Capture a reference to the `document` object in the browser.
document = if 'document' of global then global.document else null

# Load a remote script from the current domain via XHR. The optional `callback`
# function accepts two arguments: an error object if the script could not be
# loaded or failed to run, and the source of the remote script.
CoffeeScript.load = (url, options = {}, callback) ->
  # Creates a new `XMLHttpRequest` object in IE and W3C-compliant browsers.
  xhr = if 'ActiveXObject' of global
    new global.ActiveXObject 'Microsoft.XMLHTTP'
  else if 'XMLHttpRequest' of global
    new global.XMLHttpRequest
  # Unsupported environment; exit early.
  throw new Error '`XMLHttpRequest` is not supported.' if not xhr
  xhr.open 'GET', url, yes
  xhr.overrideMimeType 'text/plain' if 'overrideMimeType' of xhr
  xhr.onreadystatechange = ->
    if xhr.readyState is 4
      error = code = null
      if 200 <= xhr.status < 300 or xhr.status is 304
        try code = CoffeeScript.compile xhr.responseText, options catch exception then error = exception
      else
        error = new Error "An error occurred while loading the script `#{url}`."
      callback? error, code
  xhr.send null

# In the browser, the CoffeeScript compiler will asynchronously load, compile,
# and evaluate all `script` elements with a content type of 
# `text/coffeescript`. The scripts are loaded and executed in order on page
# load.
runScripts = ->
  scripts = document.getElementsByTagName 'script'
  index = -1
  length = scripts.length
  do execute = (error) ->
    throw error if error
    index++
    return if index is length
    script = scripts[index]
    if script.type is 'text/coffeescript'
      if script.src
        CoffeeScript.load script.src, null, (exception, code) ->
          Function(code)() if code
          execute exception
      else
        CoffeeScript.run script.innerHTML, null, execute
    else
      execute()
  null

# Execute scripts on page load in W3C-compliant browsers and IE.
if 'addEventListener' of global
  global.addEventListener 'DOMContentLoaded', runScripts, no
else if 'attachEvent' of global
  global.attachEvent 'onload', runScripts
