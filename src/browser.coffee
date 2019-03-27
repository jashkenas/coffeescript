# This **Browser** compatibility layer extends core CoffeeScript functions
# to make things work smoothly when compiling code directly in the browser.
# We add support for loading remote Coffee scripts via **XHR**, and
# `text/coffeescript` script tags, source maps via data-URLs, and so on.

CoffeeScript = require './coffeescript'
{ compile } = CoffeeScript

# Use `window.eval` to evaluate code, rather than just `eval`, to run the
# script in a clean global scope rather than inheriting the scope of the
# CoffeeScript compiler. (So that `cake test:browser` also works in Node,
# use either `window.eval` or `global.eval` as appropriate).
CoffeeScript.eval = (code, options = {}) ->
  options.bare ?= on
  globalRoot = if window? then window else global
  globalRoot['eval'] compile code, options

# Running code does not provide access to this scope.
CoffeeScript.run = (code, options = {}) ->
  options.bare      = on
  options.shiftLine = on
  Function(compile code, options)()

# Export this more limited `CoffeeScript` than what is exported by
# `index.coffee`, which is intended for a Node environment.
module.exports = CoffeeScript

# If we’re not in a browser environment, we’re finished with the public API.
return unless window?

# Include source maps where possible. If we’ve got a base64 encoder, a
# JSON serializer, and tools for escaping unicode characters, we’re good to go.
# Ported from https://developer.mozilla.org/en-US/docs/DOM/window.btoa
if btoa? and JSON?
  compile = (code, options = {}) ->
    options.inlineMap = true
    CoffeeScript.compile code, options

# Load a remote script from the current domain via XHR.
CoffeeScript.load = (url, callback, options = {}, hold = false) ->
  options.sourceFiles = [url]
  xhr = if window.ActiveXObject
    new window.ActiveXObject('Microsoft.XMLHTTP')
  else
    new window.XMLHttpRequest()
  xhr.open 'GET', url, true
  xhr.overrideMimeType 'text/plain' if 'overrideMimeType' of xhr
  xhr.onreadystatechange = ->
    if xhr.readyState is 4
      if xhr.status in [0, 200]
        param = [xhr.responseText, options]
        CoffeeScript.run param... unless hold
      else
        throw new Error "Could not load #{url}"
      callback param if callback
  xhr.send null

# Activate CoffeeScript in the browser by having it compile and evaluate
# all script tags with a content-type of `text/coffeescript`.
# This happens on page load.
CoffeeScript.runScripts = ->
  scripts = window.document.getElementsByTagName 'script'
  coffeetypes = ['text/coffeescript', 'text/literate-coffeescript']
  coffees = (s for s in scripts when s.type in coffeetypes)
  index = 0

  execute = ->
    param = coffees[index]
    if param instanceof Array
      CoffeeScript.run param...
      index++
      execute()

  for script, i in coffees
    do (script, i) ->
      options = literate: script.type is coffeetypes[1]
      source = script.src or script.getAttribute('data-src')
      if source
        options.filename = source
        CoffeeScript.load source,
          (param) ->
            coffees[i] = param
            execute()
          options
          true
      else
        # `options.filename` defines the filename the source map appears as
        # in Developer Tools. If a script tag has an `id`, use that as the
        # filename; otherwise use `coffeescript`, or `coffeescript1` etc.,
        # leaving the first one unnumbered for the common case that there’s
        # only one CoffeeScript script block to parse.
        options.filename = if script.id and script.id isnt '' then script.id else "coffeescript#{if i isnt 0 then i else ''}"
        options.sourceFiles = ['embedded']
        coffees[i] = [script.innerHTML, options]

  execute()

# Listen for window load, both in decent browsers and in IE.
# Only attach this event handler on startup for the
# non-ES module version of the browser compiler, to preserve
# backward compatibility while letting the ES module version
# be importable without side effects.
if this is window
  if window.addEventListener
    window.addEventListener 'DOMContentLoaded', CoffeeScript.runScripts, no
  else
    window.attachEvent 'onload', CoffeeScript.runScripts
