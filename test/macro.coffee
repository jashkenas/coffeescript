jsonEq = (a,b) -> eq JSON.stringify(a), JSON.stringify(b)

test "macro value conversion", ->
  macro TO_ARRAY (expr) -> @valToNode [@nodeToVal(expr)]
  jsonEq [1], TO_ARRAY 1
  jsonEq [{a:2}], TO_ARRAY {a:2}
  jsonEq [[{c:[3,4]}]], TO_ARRAY [{c:[3,4]}]
  jsonEq [null], TO_ARRAY ->

test "macro toId", ->
  macro STRINGIFY (a) -> @valToNode @nodeToId a
  eq "test", STRINGIFY test
  eq undefined, STRINGIFY test.lala
  eq undefined, STRINGIFY test[123]
  eq undefined, STRINGIFY a3 + 4
  eq undefined, STRINGIFY 123
  eq undefined, STRINGIFY {}
  eq undefined, STRINGIFY ->

test "macro ast construction", ->
  macro -> @i18nDict = waterBottles: "%1 bottle[s] of water"
  injectAndPluralize = (msg,arg) -> msg.replace("%1",arg).replace(/[\[\]]/g,'') # stub

  macro I18N (args...) ->
    text = @nodeToId args[0]
    text = @i18nDict[text] || text
    args[0] = @valToNode text
    new @Call(new @Literal("injectAndPluralize"), args)

  eq "17 bottles of water", I18N(waterBottles, 17)

test "macro cs expansion", ->
  tst = (a,b) -> a*b
  eq 144, macro -> @csToNode "x = (a) -> tst(a,6) * 3\nx(5) + x(3)"
 
test "macro substitute", ->
  macro SWAP (a,b) -> @substitute @csToNode("[x,y] = [y,x]"), {x:a,y:b}
  [c,d] = [1,2]
  SWAP c, d
  jsonEq [2,1], [c,d]
  
  tst = (a,b) -> a*b
  tst2 = -> 4
  macro CALC (c1,c2,c3,c4) -> @substitute @csToNode("x = (a) -> tst(a,c1) * c2\nx(c3) + x(c4)"), {c1,c2,c3,c4}
  eq 144, CALC 6, 3, 5, 3
  eq 144, CALC (macro -> @csToNode "tst2()+2"), 3, 5, 3

if fs = require? 'fs'
  test "macro include", ->
    macro -> @fileToNode 'test/macro2.coffee'
    eq 1, INCLUDED_MACRO()
    eq 2, includedFunc()
    eq 3, includedVal
    eq 4, (macro -> @valToNode @includedMeta)
 
