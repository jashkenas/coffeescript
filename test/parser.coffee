# Parser
# ---------

test "operator precedence for logical operators", ->
  source = '''
    a or b and c
  '''
  {body: block} = CoffeeScript.nodes source
  [expression] = block.expressions
  eq expression.first.base.value, 'a'
  eq expression.operator, '||'
  eq expression.second.first.base.value, 'b'
  eq expression.second.operator, '&&'
  eq expression.second.second.base.value, 'c'

test "operator precedence for bitwise operators", ->
  source = '''
    a | b ^ c & d
  '''
  {body: block} = CoffeeScript.nodes source
  [expression] = block.expressions
  eq expression.first.base.value, 'a'
  eq expression.operator, '|'
  eq expression.second.first.base.value, 'b'
  eq expression.second.operator, '^'
  eq expression.second.second.first.base.value, 'c'
  eq expression.second.second.operator, '&'
  eq expression.second.second.second.base.value, 'd'

test "operator precedence for binary ? operator", ->
  source = '''
     a ? b and c
  '''
  {body: block} = CoffeeScript.nodes source
  [expression] = block.expressions
  eq expression.first.base.value, 'a'
  eq expression.operator, '?'
  eq expression.second.first.base.value, 'b'
  eq expression.second.operator, '&&'
  eq expression.second.second.base.value, 'c'

test "new calls have a range including the new", ->
  source = '''
    a = new B().c(d)
  '''
  {body: block} = CoffeeScript.nodes source

  assertColumnRange = (node, firstColumn, lastColumn) ->
    eq node.locationData.first_line, 0
    eq node.locationData.first_column, firstColumn
    eq node.locationData.last_line, 0
    eq node.locationData.last_column, lastColumn

  [assign] = block.expressions
  outerCall = assign.value.base
  innerValue = outerCall.variable
  innerCall = innerValue.base

  assertColumnRange assign, 0, 15
  assertColumnRange outerCall, 4, 15
  assertColumnRange innerValue, 4, 12
  assertColumnRange innerCall, 4, 10

test "location data is properly set for nested `new`", ->
  source = '''
    new new A()()
  '''
  {body: block} = CoffeeScript.nodes source

  assertColumnRange = (node, firstColumn, lastColumn) ->
    eq node.locationData.first_line, 0
    eq node.locationData.first_column, firstColumn
    eq node.locationData.last_line, 0
    eq node.locationData.last_column, lastColumn

  [{base: outerCall}] = block.expressions
  innerCall = outerCall.variable

  assertColumnRange outerCall, 0, 12
  assertColumnRange innerCall, 4, 10
