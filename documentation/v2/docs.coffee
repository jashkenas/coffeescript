# Initialize Scrollspy for sidebar navigation; http://v4-alpha.getbootstrap.com/components/scrollspy/
$('body').scrollspy
  target: '#nav'
  offset: Math.round $('main').css('padding-top').replace('px', '')

if window.location.hash?
  $(".nav-link.active[href!='#{window.location.hash}']").removeClass 'active'

$(window).on 'activate.bs.scrollspy', (event, target) -> # Why `window`? https://github.com/twbs/bootstrap/issues/20086
  # We only want one active link in the nav
  $(".nav-link.active[href!='#{target.relatedTarget}']").removeClass 'active'
  $target = $(".nav-link[href='#{target.relatedTarget}']")
  # Update the browser address bar on scroll or navigation
  window.history.pushState {}, $target.text(), $target.prop('href')


# Initialize CodeMirror for code examples; https://codemirror.net/doc/manual.html
editors = []
lastCompilationElapsedTime = 200
$('textarea').each (index) ->
  mode = if $(@).hasClass('javascript-output') then 'javascript' else 'coffeescript'

  editors[index] = editor = CodeMirror.fromTextArea @,
    mode: mode
    theme: 'default' # TODO: Change
    indentUnit: 2
    tabSize: 2
    lineWrapping: on
    lineNumbers: off
    inputStyle: 'contenteditable'
    # readOnly: (if mode is 'coffeescript' then no else 'nocursor')
    viewportMargin: Infinity

  if mode is 'coffeescript'
    pending = null
    editor.on 'change', (instance, change) ->
      clearTimeout pending
      pending = setTimeout ->
        lastCompilationStartTime = Date.now()
        try
          output = CoffeeScript.compile editor.getValue(), bare: yes
          lastCompilationElapsedTime = Math.max(200, Date.now() - lastCompilationStartTime)
        catch exception
          output = "#{exception}"
        editors[index + 1].setValue output
      , lastCompilationElapsedTime
