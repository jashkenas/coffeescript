jsonEq = (a,b) -> eq JSON.stringify(a), JSON.stringify(b)

test "macro value conversion", ->
  macro TO_ARRAY (expr) -> macro.valToNode [macro.nodeToVal(expr)]
  jsonEq [1], TO_ARRAY 1
  jsonEq [{a:2}], TO_ARRAY {a:2}
  jsonEq [[{c:[3,4]}]], TO_ARRAY [{c:[3,4]}]
  jsonEq [null], TO_ARRAY ->

test "macro toId", ->
  macro STRINGIFY (a) -> macro.valToNode macro.nodeToId a
  eq "test", STRINGIFY test
  eq undefined, STRINGIFY test.lala
  eq undefined, STRINGIFY test[123]
  eq undefined, STRINGIFY a3 + 4
  eq undefined, STRINGIFY 123
  eq undefined, STRINGIFY {}
  eq undefined, STRINGIFY ->

test "macro in switch", ->
  jsonEq [1], switch STRINGIFY x
    when "x"
      TO_ARRAY 1
    when STRINGIFY z
      2

test "macro ast construction", ->
  macro -> @i18nDict = waterBottles: "%1 bottle[s] of water"
  injectAndPluralize = (msg,arg) -> msg.replace("%1",arg).replace(/[\[\]]/g,'') # stub

  macro I18N (args...) ->
    text = macro.nodeToId args[0]
    text = @i18nDict[text] || text
    args[0] = macro.valToNode text
    new macro.Call(new macro.Literal("injectAndPluralize"), args)

  eq "17 bottles of water", I18N(waterBottles, 17)

test "macro cs expansion", ->
  tst = (a,b) -> a*b
  eq 144, macro -> macro.codeToNode ->
    x = (a) -> tst(a,6) * 3
    x(5) + x(3)
 
test "macro subst", ->
  macro SWAP (a,b) -> (macro.codeToNode -> [x,y] = [y,x]).subst {x:a,y:b}
  [c,d] = [1,2]
  SWAP c, d
  jsonEq [2,1], [c,d]
  
  tst = (a,b) -> a*b
  tst2 = -> 4
  macro CALC (c1,c2,c3,c4) ->
    func = macro.codeToNode ->
      x = (a) -> tst(a,c1) * c2
      x(c3) + x(c4)
    func.subst {c1,c2,c3,c4}
  eq 144, CALC 6, 3, 5, 3
  eq 96, CALC 6, 2, 5, 3
  eq -70, CALC (macro -> macro.codeToNode -> tst2()+3), -1, 6, 4

  a = "12345"
  macro LEN (x) -> (macro.codeToNode -> x.length).subst {x}
  eq a.length, LEN a
  macro THIRD (x) -> (macro.codeToNode -> x[3]).subst {x}
  eq "4", THIRD a
  macro IDX (x) -> (macro.codeToNode -> {12345:321}[x]).subst {x}
  eq 321, IDX a

test "macro contexts", ->
  macro -> @a = 42
  eq 42, macro -> macro.valToNode @a
  macro INCR (arg) -> macro.valToNode macro.nodeToVal(arg)+1
  eq 43, INCR @a

test "macro call within macro arguments", ->
  macro R1 (arg) -> macro.valToNode(macro.nodeToVal(arg)+10)
  macro R2 (arg) -> macro.valToNode(macro.nodeToVal(arg)+1)
  eq 16, R1 R2 5
 
test "macro macro.codeToNode", ->
  macro toLongBody (a,b) ->
    funcAst = macro.codeToNode ->
      test = a+b
      test = test+test
    funcAst.subst {a,b}
  toLongBody(3+5,4)
  eq test, 24


if fs = require? 'fs'
  test "macro include", ->
    macro -> macro.fileToNode 'test/macro2.coffee'
    eq 1, INCLUDED_MACRO()
    eq 2, includedFunc()
    eq 3, includedVal
    eq 4, (macro -> macro.valToNode @includedMeta)
 
