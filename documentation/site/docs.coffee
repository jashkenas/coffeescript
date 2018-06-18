unless window.location.origin # Polyfill `location.origin` for IE < 11
  window.location.origin = "#{window.location.protocol}//#{window.location.hostname}"


# Initialize Google Analytics
window.GA_TRACKING_ID = 'UA-106156830-1'
window.dataLayer ?= []
window.gtag = ->
  window.dataLayer.push arguments
  return
window.gtag 'js', new Date()
window.gtag 'config', window.GA_TRACKING_ID


# Initialize the CoffeeScript docs interactions
$(document).ready ->
  # Format dates for the user’s locale, e.g. 'December 24, 2009' or '24 décembre 2009'
  $('time').each (index, el) ->
    date = el.dateTime or $(el).text()
    formattedDate = new Date(date).toLocaleDateString undefined, # undefined to use browser locale
      year: 'numeric'
      month: 'long'
      day: 'numeric'
    $(el).text formattedDate.toString()


  # Mobile navigation
  toggleSidebar = ->
    $('.navbar-toggler, .sidebar').toggleClass 'show'

  $('[data-toggle="offcanvas"]').click toggleSidebar

  $('[data-action="sidebar-nav"]').click (event) ->
    if $('.navbar-toggler').is(':visible')
      event.preventDefault()
      toggleSidebar()
      setTimeout ->
        window.location = event.target.href
      , 260 # Wait for the sidebar to slide away before navigating
    gtag 'event', 'sidebar_navigate',
      event_category: 'navigation'
      event_label: event.target.href.replace window.location.origin, ''

  # Initialize Scrollspy for sidebar navigation; https://getbootstrap.com/docs/4.0/components/scrollspy/
  # See also http://www.codingeverything.com/2014/02/BootstrapDocsSideBar.html and http://jsfiddle.net/KyleMit/v6zhz/
  $('.main').scrollspy
    target: '#contents'
    offset: Math.round $('main').css('padding-top').replace('px', '')

  initializeScrollspyFromHash = (hash) ->
    $("#contents a.active[href!='#{hash}']").removeClass 'show'

  $('.main').on 'activate.bs.scrollspy', (event, target) ->
    # We only want one active link in the nav
    $("#contents a.active[href!='#{target.relatedTarget}']").removeClass 'show'
    $target = $("#contents a[href='#{target.relatedTarget}']")
    return if $target.prop('href') is "#{window.location.origin}/#try"
    # Update the browser address bar on scroll, without adding to the history; clicking the sidebar links will automatically add to the history
    replaceState $target.prop('href')
    # Track this as a new pageview; we only want '/#hash', not 'https://coffeescript.org/#hash'
    gtag 'config', GA_TRACKING_ID,
      page_path: $target.prop('href').replace window.location.origin, ''


  # Initialize CodeMirror for code examples; https://codemirror.net/doc/manual.html
  # Defer this until a code example is clicked or focused, to avoid unnecessary computation/slowness
  textareas = []
  editors = []
  lastCompilationElapsedTime = 200
  $('textarea').each (index) ->
    textareas[index] = @
    $(@).data 'index', index

  initializeEditor = ($textarea) ->
    index = $textarea.data 'index'
    mode = if $textarea.hasClass('javascript-output') then 'javascript' else 'coffeescript'
    editors[index] = editor = CodeMirror.fromTextArea $textarea[0],
      mode: mode
      theme: 'twilight'
      indentUnit: 2
      tabSize: 2
      lineWrapping: on
      lineNumbers: off
      inputStyle: 'contenteditable'
      readOnly: mode isnt 'coffeescript' # Can’t use 'nocursor' if we want the JavaScript to be copyable
      viewportMargin: Infinity

    # Whenever the user edits the CoffeeScript side of a code example, update the JavaScript output
    # If the editor is Try CoffeeScript, also update the hash and save this code in localStorage
    if mode is 'coffeescript'
      pending = null
      editor.on 'change', (instance, change) ->
        clearTimeout pending
        pending = setTimeout ->
          lastCompilationStartTime = Date.now()
          try
            coffee = editor.getValue()
            if index is 0 and $('#try').hasClass('show') # If this is the editor in Try CoffeeScript and it’s still visible
              if $('#try').hasClass('show')
                # Update the hash with the current code
                link = "try:#{encodeURIComponent coffee}"
                replaceState "#{window.location.href.split('#')[0]}##{link}"
              # Save this to the user’s localStorage
              try
                if window.localStorage?
                  window.localStorage.setItem 'tryCoffeeScriptCode', coffee
              catch exception
            output = CoffeeScript.compile coffee, bare: yes
            lastCompilationElapsedTime = Math.max(200, Date.now() - lastCompilationStartTime)
          catch exception
            output = "#{exception}"
          editors[index + 1].setValue output
          gtag 'event', 'edit_code',
            event_category: 'engagement'
            event_label: $textarea.closest('[data-example]').data('example')
        , lastCompilationElapsedTime

      # Fix the code editors’ handling of tab-indented code
      editor.addKeyMap
        'Tab': (cm) ->
          if cm.somethingSelected()
            cm.indentSelection 'add'
          else if /^\t/m.test cm.getValue()
            # If any lines start with a tab, treat this as tab-indented code
            cm.execCommand 'insertTab'
          else
            cm.execCommand 'insertSoftTab'
        'Shift-Tab': (cm) ->
          cm.indentSelection 'subtract'
        'Enter': (cm) ->
          cm.options.indentWithTabs = /^\t/m.test cm.getValue()
          cm.execCommand 'newlineAndIndent'

  $('.placeholder-code').one 'mouseover', (event) ->
    $textarea = $(@).prev 'textarea'
    $(@).remove()
    initializeEditor $textarea
    # Initialize the sibling column too
    $siblingColumn = $ $textarea.parent().siblings()[0]
    $siblingColumn.children('.placeholder-code').remove()
    initializeEditor $ $siblingColumn.children('textarea')[0]

  initializeTryEditors = ->
    initializeEditor $ '#try-coffeescript-coffee'
    initializeEditor $ '#try-coffeescript-js'

  # Handle the code example buttons
  $('[data-action="run-code-example"]').click ->
    run = $(@).data 'run'
    index = $("##{$(@).data('example')}-js").data 'index'
    js = if editors[index]?
      editors[index].getValue()
    else
      $(textareas[index]).val()
    js = "#{js}\nalert(#{unescape run});" unless run is yes
    window.eval js
    gtag 'event', 'run_code',
      event_category: 'engagement'
      event_label: $(@).closest('[data-example]').data('example')

  # Try CoffeeScript
  previousHash = null
  toggleTry = (checkLocalStorage) ->
    $('#try, #try-link').toggleClass 'show'
    if $('#try').hasClass('show')
      previousHash = window.location.hash if window.location.hash
      initializeTryEditors() if $('#try .CodeMirror').length is 0
      if checkLocalStorage and window.localStorage?
        try
          coffee = window.localStorage.getItem 'tryCoffeeScriptCode'
          if coffee?
            editors[0].setValue coffee
          else
            replaceState '#try'
        catch exception
          replaceState '#try'
      else
        replaceState '#try'
    else
      if previousHash then replaceState(previousHash) else clearHash()
  closeTry = ->
    $('#try, #try-link').removeClass 'show'
    if previousHash then replaceState(previousHash) else clearHash()

  $('[data-toggle="try"]').click (event) ->
    event.preventDefault()
    toggleTry yes
  $('[data-close="try"]').click closeTry

  $('[data-action="scroll-to-top"]').click (event) ->
    return if $('#try').hasClass('show')
    $('.main')[0].scrollTop = 0
    setTimeout clearHash, 10

  clearHash = ->
    window.history.replaceState {}, document.title, window.location.pathname

  replaceState = (newURL) ->
    newURL = "#{window.location.pathname}#{newURL}" if newURL?.indexOf('#') is 0
    window.history.replaceState {}, document.title, (newURL or '')

  $(window).on 'hashchange', ->
    # Get rid of dangling # in the address bar
    clearHash() if window.location.hash is ''

  # Configure the initial state
  if window.location.hash?
    if window.location.hash is '#try'
      toggleTry yes
    else if window.location.hash.indexOf('#try') is 0
      initializeTryEditors() if $('#try .CodeMirror').length is 0
      editors[0].setValue decodeURIComponent window.location.hash[5..]
      toggleTry no
    else if window.location.hash is ''
      clearHash()
    else
      initializeScrollspyFromHash window.location.hash
      if window.location.hash.length > 1
        # Initializing the code editors might’ve thrown off our vertical scroll position
        document.getElementById(window.location.hash.slice(1).replace(/try:.*/, '')).scrollIntoView()
