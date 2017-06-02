sourceFragment = "try:"

# Set up the compilation function, to run when you stop typing.
compileSource = ->
  source = $('#repl_source').val()
  results = $('#repl_results')
  window.compiledJS = ''
  try
    window.compiledJS = CoffeeScript.compile source, bare: on
    el = results[0]
    if el.innerText
      el.innerText = window.compiledJS
    else
      results.text(window.compiledJS)
    results.removeClass 'error'
    $('.minibutton.run').removeClass 'error'
  catch {location, message}
    if location?
      message = "Error on line #{location.first_line + 1}: #{message}"
    results.text(message).addClass 'error'
    $('.minibutton.run').addClass 'error'

  # Update permalink
  $('#repl_permalink').attr 'href', "##{sourceFragment}#{encodeURIComponent source}"

# Listen for keypresses and recompile.
$('#repl_source').keyup -> compileSource()

# Use tab key to insert tabs
$('#repl_source').keydown (e) ->
  if e.keyCode is 9
    e.preventDefault()
    textbox = e.target
    # Insert tab character at caret or in selection
    textbox.value = textbox.value[0...textbox.selectionStart] + "\t" + textbox.value[textbox.selectionEnd...]
    # Put caret in correct position
    textbox.selectionEnd = ++textbox.selectionStart

# Eval the compiled js.
evalJS = ->
  try
    eval window.compiledJS
  catch error then alert error

# Load the console with a string of CoffeeScript.
window.loadConsole = (coffee) ->
  $('#repl_source').val coffee
  compileSource()
  $('.navigation.try').addClass('active')
  false

# Helper to hide the menus.
closeMenus = ->
  $('.navigation.active').removeClass 'active'

$('.minibutton.run').click -> evalJS()

# Bind navigation buttons to open the menus.
$('.navigation').click (e) ->
  return if e.target.tagName.toLowerCase() is 'a'
  return false if $(e.target).closest('.repl_wrapper').length
  if $(this).hasClass('active')
    closeMenus()
  else
    closeMenus()
    $(this).addClass 'active'
  false

$(document).on 'click', '[href="#try"]', (e) ->
  $('.navigation.try').addClass 'active'

# Dismiss console if Escape pressed or click falls outside console
# Trigger Run button on Ctrl-Enter
$(document.body)
  .keydown (e) ->
    closeMenus() if e.which == 27
    evalJS() if e.which == 13 and (e.metaKey or e.ctrlKey) and $('.minibutton.run:visible').length
  .click (e) ->
    return false if $(e.target).hasClass('minibutton')
    closeMenus()

$('#open_webchat').click ->
  $(this).replaceWith $('<iframe src="http://webchat.freenode.net/?channels=coffeescript" width="625" height="400"></iframe>')

$("#repl_permalink").click (e) ->
    window.location = $(this).attr("href")
    false

# If source code is included in location.hash, display it.
hash = decodeURIComponent location.hash.replace(/^#/, '')
if hash.indexOf(sourceFragment) == 0
    src = hash.substr sourceFragment.length
    loadConsole src

compileSource()
