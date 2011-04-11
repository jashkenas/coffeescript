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

# Capture a reference to the `document` object in the browser.
document = if typeof @document isnt 'undefined' then document else null

# Creates a new `XMLHttpRequest` object in IE and W3C-compliant browsers.
create = -> throw new Error '`XMLHttpRequest` is not supported.'
if typeof @ActiveXObject isnt 'undefined'
  create = => new @ActiveXObject 'Microsoft.XMLHTTP'
else if typeof @XMLHttpRequest isnt 'undefined'
  create = => new @XMLHttpRequest

# Load a remote script from the current domain via XHR. The optional `callback`
# function accepts two arguments: an error object if the script could not be
# loaded or failed to run, and the result of executing the script using
# `CoffeeScript.run`.
CoffeeScript.load = (url, options, callback) ->
  xhr = create()
  xhr.open 'GET', url, yes
  xhr.overrideMimeType 'text/plain' if 'overrideMimeType' of xhr
  xhr.onreadystatechange = ->
    if xhr.readyState is 4
      error = result = null
      if xhr.status is 200
        try result = CoffeeScript.run xhr.responseText catch error then error = exception
      else
        error = new Error "An error occurred while loading the script `#{url}`."
      callback? error, result
  xhr.send null

# In the browser, the CoffeeScript compiler will asynchronously load, compile,
# and evaluate all `script` elements with a content type of 
# `text/coffeescript`. The scripts are loaded and executed in order on page
# load.
runScripts = ->
  scripts = document.getElementsByTagName 'script'
  index = 0
  length = scripts.length
  (execute = (error) ->
    throw error if error
    script = scripts[index++]
    if script.type is 'text/coffeescript' and script.src
      CoffeeScript.load script.src, null, execute
    else
      CoffeeScript.run script.innerHTML
      execute()
  )()
  null

# Execute scripts on page load in W3C-compliant browsers and IE.
if typeof @addEventListener isnt 'undefined'
  @addEventListener 'DOMContentLoaded', runScripts, no
else if typeof @attachEvent isnt 'undefined'
  @attachEvent 'onload', runScripts
