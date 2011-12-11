
delay = (cb, i) ->
   i = i || 10
   setTimeout cb, i

atest "basic tame waiting", (cb) ->
   i = 1
   await delay defer()
   i++
   cb(i == 2, {})

foo = (i, cb) ->
  await delay(defer(), i)
  cb(i)

atest "basic tame waiting", (cb) ->
   i = 1
   await delay defer()
   i++
   cb(i == 2, {})

atest "basic tame trigger values", (cb) ->
   i = 10
   await foo(i, defer (j))
   cb(i == j, {})

atest "basic tame set structs", (cb) ->
   field = "yo"
   i = 10
   obj = { cat : { dog : 0 } }
   await
     foo(i, defer(obj.cat[field]))
     field = "bar" # change the field to make sure that we captured "yo"
   cb(obj.cat.yo == i, {})

atest "continue / brek test" , (cb) ->
  tot = 0
  for i in [0..100]
    await delay defer()
    continue if i == 3
    tot += i
    break if i == 10
  cb(tot == 52, {})

atest "for k,v of obj testing", (cb) ->
  obj = { the : "quick", brown : "fox", jumped : "over" }
  s = ""
  for k,v of obj
    await delay defer()
    s += k + " " + v + " "
  cb( s == "the quick brown fox jumped over ", {} )

atest "for k,v in arr testing", (cb) ->
  obj = [ "the", "quick", "brown" ]
  s = ""
  for v,i in obj
    await delay defer()
    s += v + " " + i + " "
  cb( s == "the 0 quick 1 brown 2 ", {} )

atest "switch-a-roos", (cb) ->
  res = 0
  for i in [0..5]
    await delay defer()
    switch i
      when 0 then res += 1
      when 1
        await delay defer()
        res += 20
      when 2
        await delay defer()
        if false
          res += 100000
        else
          await delay defer()
          res += 300
      else
        res += i*1000
    res += 10000 if i == 2
  cb( res == 17321, {} )


atest "parallel awaits with classes", (cb) ->
  class MyClass
    constructor: ->
      @val = 0
    increment: (wait, i, cb) ->
      await setTimeout(defer(),wait)
      @val += i
      await setTimeout(defer(),wait)
      @val += i
      cb()
    getVal: -> @val

  obj = new MyClass()
  await
    obj.increment 10, 1, defer()
    obj.increment 20, 2, defer()
    obj.increment 30, 4, defer()
  v = obj.getVal()
  cb(v == 14, {})

atest "loop construct", (cb) ->
  i = 0
  loop
    await delay defer()
    i += 1
    await delay defer()
    break if i == 10
    await delay defer()
  cb(i == 10, {})

atest "simple autocb operations", (cb) ->
  b = false
  foo = (autocb) ->
    await delay defer()
    true
  await foo defer b
  cb(b, {})
    
atest "test nested serial/parallel", (cb) ->
  slots = []
  await
    for i in [0..10]
      ( (autocb) ->
        await delay defer(), 5*Math.random()
        await delay defer(), 4*Math.random()
        slots[i] = true
      )(defer())
  ok = true
  for slot in slots
    ok = false unless slot
  cb(ok, {})

atest "more advanced autocb test", (cb) ->
  bar = -> "yoyo"
  foo = (val, autocb) ->
    await delay defer()
    if val == 0 then [1,2,3]
    else if val == 1 then { a : 10 }
    else if val == 2 then bar()
    else 33
  oks = 0
  await foo 0, defer x
  oks++ if x[2] == 3
  await foo 1, defer x
  oks++ if x.a == 10
  await foo 2, defer x
  oks++ if x == "yoyo"
  await foo 100, defer x
  oks++ if x == 33
  cb(oks == 4, {})
