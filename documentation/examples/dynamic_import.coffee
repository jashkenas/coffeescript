# Your browser must support dynamic import to run this example.

do ->
  { run } = await import('./browser-compiler-modern/coffeescript.js')
  run '''
    if 5 < new Date().getHours() < 9
      alert 'Time to make the coffee!'
    else
      alert 'Time to get some work done.'
  '''
