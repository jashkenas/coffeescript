# Astract Syntax Tree generation
# ------------------------------

# Helpers to get AST nodes for a string of code. The root node is always a
# `Block` node, so for brevity in the tests return its children from
# `expressions`.
getExpressions = (code) ->
  ast = CoffeeScript.compile code, ast: yes
  ast.expressions

getExpression = (code) -> getExpressions(code)[0]

# Check each node type in the same order as they appear in `nodes.coffee`.
# For nodes that have equivalents in Babel’s AST spec, we’re checking that
# the type and properties match. When relevant, also check that values of
# properties are as expected.

test "AST as expected for Block node", ->
  ast = CoffeeScript.compile 'return', ast: yes
  eq ast.type, 'Block'
  eq ast.expressions[0].type, 'Return'

# Can’t test for `Literal` node, as it’s a base class for the `*Literal`
# classes.

test "AST as expected for NumberLiteral node", ->
  expression = getExpression '42'
  eq expression.type, 'NumberLiteral'
  eq expression.value, '42'

test "AST as expected for InfinityLiteral node", ->
  expression = getExpression 'Infinity'
  eq expression.type, 'InfinityLiteral'
  eq expression.value, 'Infinity'

test "AST as expected for NaNLiteral node", ->
  expression = getExpression 'NaN'
  eq expression.type, 'NaNLiteral'
  eq expression.value, 'NaN'

test "AST as expected for StringLiteral node", ->
  expression = getExpression '"string cheese"'
  eq expression.type, 'StringLiteral'
  eq expression.value, '"string cheese"'

test "AST as expected for RegexLiteral node", ->
  expression = getExpression '/^(?!.*(.).*\\1)[gimsuy]*$/'
  eq expression.type, 'RegexLiteral'
  eq expression.value, '/^(?!.*(.).*\\1)[gimsuy]*$/'

test "AST as expected for PassthroughLiteral node", ->
  expression = getExpression '`const CONSTANT = "unreassignable!"`'
  eq expression.type, 'PassthroughLiteral'
  eq expression.value, 'const CONSTANT = "unreassignable!"'

test "AST as expected for IdentifierLiteral node", ->
  expression = getExpression 'id = "undercover agent"'
  variable = expression.variable
  eq variable.type, 'IdentifierLiteral'
  eq variable.value, 'id'

test "AST as expected for CSXTag node", ->
  expression = getExpression '<CSX />'
  variable = expression.variable
  eq variable.type, 'CSXTag'
  eq variable.value, 'CSX'

test "AST as expected for PropertyName node", ->
  expression = getExpression 'Object.assign'
  name = expression.properties[0].name
  eq name.type, 'PropertyName'
  eq name.value, 'assign'

test "AST as expected for ComputedPropertyName node", ->
  # expression = getExpression 'obj = ["fn"]: ->'
  # variable = expression.value.properties[0].variable
  # eq variable.type, 'ComputedPropertyName'
  # eq variable.value, 'fn'

test "AST as expected for StatementLiteral node", ->
  expression = getExpression 'break'
  eq expression.type, 'StatementLiteral'
  eq expression.value, 'break'

test "AST as expected for ThisLiteral node", ->
  expression = getExpression 'this'
  eq expression.type, 'ThisLiteral'
  eq expression.value, 'this'

  expression = getExpression '@'
  eq expression.type, 'ThisLiteral'
  eq expression.value, 'this'
  # TODO: Check for raw value of '@'.

test "AST as expected for UndefinedLiteral node", ->
  expression = getExpression 'undefined'
  eq expression.type, 'UndefinedLiteral'
  eq expression.value, 'undefined'

test "AST as expected for NullLiteral node", ->
  expression = getExpression 'null'
  eq expression.type, 'NullLiteral'
  eq expression.value, 'null'

test "AST as expected for BooleanLiteral node", ->
  expression = getExpression 'true'
  eq expression.type, 'BooleanLiteral'
  eq expression.value, 'true'

  expression = getExpression 'off'
  eq expression.type, 'BooleanLiteral'
  eq expression.value, 'false'
  # TODO: Check for raw value of 'off'.

test "AST as expected for Return node", ->
  expression = getExpression 'return no'
  eq expression.type, 'Return'
  eq expression.expression.type, 'BooleanLiteral'

test "AST as expected for YieldReturn node", ->
  expression = getExpression 'yield return ->'
  eq expression.type, 'YieldReturn'
  eq expression.expression.type, 'Code'

test "AST as expected for AwaitReturn node", ->
  expression = getExpression 'await return ->'
  eq expression.type, 'AwaitReturn'
  eq expression.expression.type, 'Code'

test "AST as expected for Value node", ->
  expression = getExpression 'for i in [] then i'
  value = expression.body
  eq value.type, 'Value'
  # eq value.value, 'i'

# Comments aren’t nodes, so they shouldn’t appear in the AST.

test "AST as expected for Call node", ->
  expression = getExpression 'fn()'
  eq expression.type, 'Call'
  variable = expression.variable
  eq variable.value, 'fn'

  expression = getExpression 'new Date()'
  eq expression.type, 'Call'
  eq expression.isNew, yes

  expression = getExpression 'maybe?()'
  eq expression.type, 'Call'
  eq expression.soak, yes

  expression = getExpression 'goDo this, that'
  eq expression.type, 'Call'
  eq expression.args[0].value, 'this'
  eq expression.args[1].value, 'that'

test "AST as expected for SuperCall node", ->
  expression = getExpression 'class child extends parent then constructor: -> super()'
  # TODO

test "AST as expected for Super node", ->
  # TODO

test "AST as expected for RegexWithInterpolations node", ->
  # TODO

test "AST as expected for TaggedTemplateCall node", ->
  # TODO

test "AST as expected for Extends node", ->
  # TODO

test "AST as expected for Access node", ->
  # TODO

test "AST as expected for Index node", ->
  # TODO

test "AST as expected for Range node", ->
  # TODO

test "AST as expected for Slice node", ->
  # TODO

test "AST as expected for Obj node", ->
  # TODO

test "AST as expected for Arr node", ->
  # TODO

test "AST as expected for Class node", ->
  # TODO

test "AST as expected for ExecutableClassBody node", ->
  # TODO

test "AST as expected for ModuleDeclaration node", ->
  # TODO

test "AST as expected for ImportDeclaration node", ->
  # TODO

test "AST as expected for ImportClause node", ->
  # TODO

test "AST as expected for ExportDeclaration node", ->
  # TODO

test "AST as expected for ExportNamedDeclaration node", ->
  # TODO

test "AST as expected for ExportDefaultDeclaration node", ->
  # TODO

test "AST as expected for ExportAllDeclaration node", ->
  # TODO

test "AST as expected for ModuleSpecifierList node", ->
  # TODO

test "AST as expected for ImportSpecifierList node", ->
  # TODO

test "AST as expected for ExportSpecifierList node", ->
  # TODO

test "AST as expected for ModuleSpecifier node", ->
  # TODO

test "AST as expected for ImportSpecifier node", ->
  # TODO

test "AST as expected for ImportDefaultSpecifier node", ->
  # TODO

test "AST as expected for ImportNamespaceSpecifier node", ->
  # TODO

test "AST as expected for ExportSpecifier node", ->
  # TODO

test "AST as expected for Assign node", ->
  # TODO

test "AST as expected for FuncGlyph node", ->
  # TODO

test "AST as expected for Code node", ->
  # TODO

test "AST as expected for Param node", ->
  # TODO

test "AST as expected for Splat node", ->
  # TODO

test "AST as expected for Expansion node", ->
  # TODO

test "AST as expected for Elision node", ->
  # TODO

test "AST as expected for While node", ->
  # TODO

test "AST as expected for Op node", ->
  # TODO

test "AST as expected for In node", ->
  # TODO

test "AST as expected for Try node", ->
  # TODO

test "AST as expected for Throw node", ->
  # TODO

test "AST as expected for Existence node", ->
  # TODO

test "AST as expected for Parens node", ->
  # TODO

test "AST as expected for StringWithInterpolations node", ->
  # TODO

test "AST as expected for For node", ->
  # TODO

test "AST as expected for Switch node", ->
  # TODO

test "AST as expected for If node", ->
  # TODO
