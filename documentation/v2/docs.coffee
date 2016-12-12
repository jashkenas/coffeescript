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
