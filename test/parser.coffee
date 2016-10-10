# Parser
# ---------

test "operator precedence for logical operators", ->
  source = '''
    a or b and c
  '''
  block = CoffeeScript.nodes source
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
  block = CoffeeScript.nodes source
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
  block = CoffeeScript.nodes source
  [expression] = block.expressions
  eq expression.first.base.value, 'a'
  eq expression.operator, '?'
  eq expression.second.first.base.value, 'b'
  eq expression.second.operator, '&&'
  eq expression.second.second.base.value, 'c'
