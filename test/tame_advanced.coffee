tameRequire(none)

tame = require('../lib/coffee-script/coffee-script').tame;
tamelib = require('../lib/coffee-script/tamelib')

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
      if nsent - nrecv < window and nsent < n
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


atest "pipeliner example", (cb) ->

  slots = []
  call = (i, cb) ->
    slots[i] = 1
    await setTimeout(defer(), 3*Math.random())
    slots[i] |= 2
    cb(4)

  window = (n, window, cb) ->
    tmp = {}
    p = new tamelib.Pipeliner window, .01
    for i in [0..n]
      await p.waitInQueue defer()
      call i, p.defer tmp[i]
    await p.flush defer()
    for k,v of tmp
      slots[k] |= tmp[k]
    cb()

  await window 100, 10, defer()

  ok = true
  for s in slots
    ok = false unless s == 7
  cb(ok, {})
