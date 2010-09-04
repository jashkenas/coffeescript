# Activate CoffeeScript in the browser by having it compile and evaluate
# all script tags with a content-type of `text/coffeescript`.
# This happens on page load.
if document?.getElementsByTagName
  grind = (coffee) ->
    setTimeout exports.compile coffee
  grindRemote = (url) ->
    xhr = new (window.ActiveXObject or XMLHttpRequest)('Microsoft.XMLHTTP')
    xhr.open 'GET', url, true
    xhr.overrideMimeType 'text/plain' if 'overrideMimeType' of xhr
    xhr.onreadystatechange = ->
      grind xhr.responseText if xhr.readyState is 4
    xhr.send null
  processScripts = ->
    for script in document.getElementsByTagName 'script'
      if script.type is 'text/coffeescript'
        if script.src
          grindRemote script.src
        else
          grind script.innerHTML
    null
  if window.addEventListener
    addEventListener 'DOMContentLoaded', processScripts, false
  else
    attachEvent 'onload', processScripts