
tameRequire(skip)
tame = require('../lib/coffee-script/coffee-script').tame;

atest "rendezvous & windowing example", (cb) ->

  slots = []
  call = (i, cb) ->
    slots[i] = 1
    await setTimeout(defer(), 10*Math.random())
    slots[i] |= 2
    cb()

  window = (n, window, cb) ->
    rv = new tame.Rendezvous
    nsent = 0
    nrecv = 0
    while nrecv < n
      if nsent - nrecv < window && nsent < n
        call nsent, rv.id(nsent).defer()
        nsent++
      else
        await rv.wait defer(res)
        slots[res] |= 4
        nrecv++
    cb()

  await window 10, 3, defer()
  res = true
  for s in slots
    res = false unless s == 7
  cb(res, {})
