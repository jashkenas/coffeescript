
delay = (cb, i) ->
   i = i || 3
   setTimeout cb, i

atest "basic tame waiting", (cb) ->
   i = 1
   await delay defer()
   i++
   cb(i is 2, {})

foo = (i, cb) ->
  await delay(defer(), i)
  cb(i)

atest "basic tame waiting", (cb) ->
   i = 1
   await delay defer()
   i++
   cb(i is 2, {})

atest "basic tame trigger values", (cb) ->
   i = 10
   await foo(i, defer j)
   cb(i is j, {})

atest "basic tame set structs", (cb) ->
   field = "yo"
   i = 10
   obj = { cat : { dog : 0 } }
   await
     foo(i, defer obj.cat[field])
     field = "bar" # change the field to make sure that we captured "yo"
   cb(obj.cat.yo is i, {})

multi = (cb, arr) ->
  await delay defer()
  cb.apply(null, arr)

atest "defer splats", (cb) ->
  v = [ 1, 2, 3, 4]
  obj = { x : 0 }
  await multi(defer(obj.x, out...), v)
  out.unshift obj.x
  ok = true
  for i in [0..v.length-1]
    ok = false if v[i] != out[i]
  cb(ok, {})

atest "continue / break test" , (cb) ->
  tot = 0
  for i in [0..100]
    await delay defer()
    continue if i is 3
    tot += i
    break if i is 10
  cb(tot is 52, {})

atest "for k,v of obj testing", (cb) ->
  obj = { the : "quick", brown : "fox", jumped : "over" }
  s = ""
  for k,v of obj
    await delay defer()
    s += k + " " + v + " "
  cb( s is "the quick brown fox jumped over ", {} )

atest "for k,v in arr testing", (cb) ->
  obj = [ "the", "quick", "brown" ]
  s = ""
  for v,i in obj
    await delay defer()
    s += v + " " + i + " "
  cb( s is "the 0 quick 1 brown 2 ", {} )

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
    res += 10000 if i is 2
  cb( res is 17321, {} )


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
  cb(v is 14, {})

atest "loop construct", (cb) ->
  i = 0
  loop
    await delay defer()
    i += 1
    await delay defer()
    break if i is 10
    await delay defer()
  cb(i is 10, {})

atest "simple autocb operations", (cb) ->
  b = false
  foo = (autocb) ->
    await delay defer()
    true
  await foo defer b
  cb(b, {})

atest "AT variable works in an await (1)", (cb) ->
  class MyClass
    constructor : ->
      @flag = false
    chill : (autocb) ->
      await delay defer()
    run : (autocb) ->
      await @chill defer()
      @flag = true
    getFlag : -> @flag
  o = new MyClass
  await o.run defer()
  cb(o.getFlag(), {})

atest "more advanced autocb test", (cb) ->
  bar = -> "yoyo"
  foo = (val, autocb) ->
    await delay defer()
    if val is 0 then [1,2,3]
    else if val is 1 then { a : 10 }
    else if val is 2 then bar()
    else 33
  oks = 0
  await foo 0, defer x
  oks++ if x[2] is 3
  await foo 1, defer x
  oks++ if x.a is 10
  await foo 2, defer x
  oks++ if x is "yoyo"
  await foo 100, defer x
  oks++ if x is 33
  cb(oks is 4, {})

atest "test of autocb in a simple function", (cb) ->
  simple = (autocb) ->
    await delay defer()
  ok = false
  await simple defer()
  ok = true
  cb(ok,{})

atest "test nested serial/parallel", (cb) ->
  slots = []
  await
    for i in [0..10]
      ( (j, autocb) ->
        await delay defer(), 5 * Math.random()
        await delay defer(), 4 * Math.random()
        slots[j] = true
      )(i, defer())
  ok = true
  for i in [0..10]
    ok = false unless slots[i]
  cb(ok, {})

atest "loops respect autocbs", (cb) ->
  ok = false
  bar = (autocb) ->
    for i in [0..10]
      await delay defer()
      ok = true
  await bar defer()
  cb(ok, {})

atest "test scoping", (cb) ->
  class MyClass
    constructor : -> @val = 0
    run : (autocb) ->
      @val++
      await delay defer()
      @val++
      await
        class Inner
          chill : (autocb) ->
            await delay defer()
            @val = 0
        i = new Inner
        i.chill defer()
      @val++
      await delay defer()
      @val++
      await
        ( (autocb) ->
          class Inner
            chill : (autocb) ->
              await delay defer()
              @val = 0
          i = new Inner
          await i.chill defer()
        )(defer())
      ++@val
    getVal : -> @val
  o = new MyClass
  await o.run defer(v)
  cb(v is 5, {})

atest "AT variable works in an await (2)", (cb) ->
  class MyClass
    constructor : -> @val = 0
    inc : -> @val++
    chill : (autocb) -> await delay defer()
    run : (autocb) ->
      await @chill defer()
      for i in [0..10]
        await @chill defer()
        @inc()
    getVal : -> @val
  o = new MyClass
  await o.run defer()
  cb(o.getVal() is 10, {})

atest "another autocb gotcha", (cb) ->
  bar = (autocb) ->
    await delay defer() if yes
  ok = false
  await bar defer()
  ok = true
  cb(ok, {})

atest "fat arrow versus tame", (cb) ->
  class Foo
    constructor : ->
      @bindings = {}

    addHandler : (key,cb) ->
      @bindings[key] = cb

    useHandler : (key, args...) ->
      @bindings[key](args...)

    delay : (autocb) ->
      await delay defer()

    addHandlers : ->
      @addHandler "sleep1", (cb) =>
        await delay defer()
        await @delay defer()
        cb(true)
      @addHandler "sleep2", (cb) =>
        await @delay defer()
        await delay defer()
        cb(true)

  ok1 = ok2 = false
  f = new Foo()
  f.addHandlers()
  await f.useHandler "sleep1", defer(ok1)
  await f.useHandler "sleep2", defer(ok2)
  cb(ok1 and ok2, {})

 atest "nested loops", (cb) ->
  val = 0
  for i in [0..10]
    await delay(defer(),1)
    for j in [0..10]
      await delay(defer(),1)
      val++
  cb(val is 100, {})

atest "empty autocb", (cb) ->
  bar = (autocb) ->
  await bar defer()
  cb(true, {})

atest "more autocb (false)", (cb) ->
  bar = (autocb) ->
    if false
      console.log "not reached"
  await bar defer()
  cb(true, {})

atest "more autocb (true)", (cb) ->
  bar = (autocb) ->
    if true
      10
  await bar defer()
  cb(true, {})

atest "more autocb (true & false)", (cb) ->
  bar = (autocb) ->
    if false
      10
    else
      if false
        11
  await bar defer()
  cb(true, {})

atest "more autocb (while)", (cb) ->
  bar = (autocb) ->
    while false
      10
  await bar defer()
  cb(true, {})

atest "more autocb (comments)", (cb) ->
  bar = (autocb) ->
    ###
    blah blah blah
    ###
  await bar defer()
  cb(true, {})

atest "until", (cb) ->
  i = 10
  out = 0
  until i is 0
    await delay defer()
    out += i--
  cb(out is 55, {})

atest 'expressions -- simple assignment', (cb) ->
  adder = (x, cb) ->
    await delay defer()
    cb(x+1)
  ret = await adder 5, defer _
  cb(ret == 6, {})

atest 'expressions -- simple, but recursive', (cb) ->
  y = if true
    await delay defer()
    10
  cb(y == 10, {})

atest 'expressions -- simple, but recursive (2)', (cb) ->
  adder = (x, cb) ->
    await delay defer()
    cb(x+1)
  y = if true
    x = await adder 4, defer _
    ++x
  cb(y == 6, {})
  
atest 'expressions -- pass value of tail calls', (cb) ->
  adder = (x, cb) ->
    await delay defer()
    cb(x+1)
  y = if true
    await adder 5, defer _
  cb(y == 6, {})

atest 'expressions -- addition (1)', (cb) ->
  slowAdd = (a, b, autocb) ->
    await delay defer()
    a+b
  y = 30 + (await slowAdd 30, 40, defer _)
  cb(y == 100, {})


atest 'expressions -- addition (2)', (cb) ->
  slowAdd = (a, b, autocb) ->
    await delay defer()
    a+b
  y = (await slowAdd 10, 20, defer _) + (await slowAdd 30, 40, defer _)
  cb(y == 100, {})
  
atest 'expressions - chaining', (cb) ->
  id = "image data"
  class Img
    render : -> id
  loadImage = (n, cb) ->
    await delay defer()
    cb new Img
  x = (await loadImage "test.png", defer _).render()
  cb(x is id, {})
  
atest 'expressions - call args', (cb) ->
  slowAdd = (a,b,autocb) ->
    await delay defer()
    a+b
  x = await slowAdd 3, (await slowAdd 3, 4, defer _), defer _
  cb(x is 10, {})
  
atest 'expressions - call args (2)', (cb) ->
  slowAdd = (a,b,autocb) ->
    await delay defer()
    a+b
  x = await slowAdd (await slowAdd 1, 2, defer _), (await slowAdd 3, 4, defer _), defer _
  cb(x is 10, {})

#atest 'arrays and objects', (cb) ->
#  id = "image data"
#  loadImage = (n, cb) ->
#    await delay defer()
#    cb id
#  arr = [
#    (await loadImage "file.jpg", defer()),
#    "another value" ]
#  obj =
#    i : (await loadImage "file.jpg", defer())
#    v : "another value"
#  cb(arr[0] is id and obj.i is id, {})
#
# 

atest 'nesting', (cb) ->
  id = "image data"
  loadImage = (n, cb) ->
    await delay defer()
    cb id
  render = (x) -> x + x
  y = render(await loadImage "test.png", defer _)
  cb(y is (id + id), {})
