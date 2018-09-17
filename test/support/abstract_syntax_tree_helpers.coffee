# Helpers to get AST nodes for a string of code. The root node is always a
# `Block` node, so for brevity in the tests return its children from
# `expressions`.
getAstExpressions = (code) ->
  ast = CoffeeScript.compile code, ast: yes
  ast.expressions

exports.getExpressionAst = (code) -> getAstExpressions(code)[0]
