# Override exported methods for non-Node.js engines.

CoffeeScript = require './coffee-script'

CoffeeScript.eval = (code, options) ->
  eval CoffeeScript.compile code, options

unless window?
  CoffeeScript.run = (code, options) ->
    (Function CoffeeScript.compile code, options)()
  return

CoffeeScript.run  = (code, options) ->
  setTimeout CoffeeScript.compile code, options

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
processScripts = ->
  for script in document.getElementsByTagName 'script'
    if script.type is 'text/coffeescript'
      if script.src
        CoffeeScript.load script.src
      else
        CoffeeScript.run script.innerHTML
  null
if window.addEventListener
  addEventListener 'DOMContentLoaded', processScripts, false
else
  attachEvent 'onload', processScripts
