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
  expression = expression.body.base.properties[0].value.body.base
  eq expression.type, 'SuperCall'

test "AST as expected for Super node", ->
  expression = getExpression 'class child extends parent then func: -> super.prop'
  expression = expression.body.base.properties[0].value.body.base
  eq expression.type, 'Super'
  eq expression.accessor.type, 'Access'

test "AST as expected for RegexWithInterpolations node", ->
  expression = getExpression '///^#{flavor}script$///'
  eq expression.type, 'RegexWithInterpolations'
  # TODO: Shouldn't there be more info we can check for?

test "AST as expected for TaggedTemplateCall node", ->
  expression = getExpression 'func"tagged"'
  eq expression.type, 'TaggedTemplateCall'
  eq expression.args[0].type, 'StringWithInterpolations'

test "AST as expected for Extends node", ->
  expression = getExpression 'class child extends parent'
  eq expression.type, 'Class'
  eq expression.variable.value, 'child'
  eq expression.parent.value, 'parent'
  # TODO: Is there no Extends node?

test "AST as expected for Access node", ->
  expression = getExpression 'obj.prop'
  eq expression.properties[0].type, 'Access'

  expression = getExpression 'obj?.prop'
  eq expression.properties[0].type, 'Access'
  eq expression.properties[0].soak, yes

test "AST as expected for Index node", ->
  expression = getExpression 'for x, i in iterable then'
  eq expression.type, 'For'
  # TODO: Where's the Index node?

test "AST as expected for Range node", ->
  expression = getExpression '[x..y]'
  eq expression.type, 'Range'
  eq expression.exclusive, no
  eq expression.equals, '='
  eq expression.from.value, 'x'
  eq expression.to.value, 'y'

  expression = getExpression '[4...2]'
  eq expression.type, 'Range'
  eq expression.exclusive, yes
  eq expression.equals, ''
  eq expression.from.value, '4'
  eq expression.to.value, '2'

  expression = {source} = getExpression 'for x in [42...43] then'
  eq expression.range, yes
  eq source.type, 'Range'
  eq source.exclusive, yes
  eq source.equals, ''
  eq source.from.value, '42'
  eq source.to.value, '43'

  expression = {source} = getExpression 'for x in [y..z] then'
  eq expression.range, yes
  eq source.type, 'Range'
  eq source.exclusive, no
  eq source.equals, '='
  eq source.from.value, 'y'
  eq source.to.value, 'z'

  expression = getExpression 'x[..y]'
  [{range}] = expression.properties
  eq range.type, 'Range'
  eq range.exclusive, no
  eq range.equals, '='
  eq range.to.value, 'y'
  eq range.from, undefined

  expression = getExpression 'x[y...]'
  [{range}] = expression.properties
  eq range.type, 'Range'
  eq range.exclusive, yes
  eq range.equals, ''
  eq range.from.value, 'y'
  eq range.to, undefined

  expression = getExpression 'x[...]'
  [{range}] = expression.properties
  eq range.type, 'Range'
  eq range.exclusive, yes
  eq range.equals, ''
  eq range.to, undefined
  eq range.from, undefined

test "AST as expected for Slice node", ->
  expression = getExpression '"abc"[...2]'
  eq expression.properties[0].type, 'Slice'

  expression = getExpression 'x[...][a..][b...][..c][...d]'
  eq expression.properties.length, 5
  for slice in expression.properties
    eq slice.type, 'Slice'
    eq slice.range.type, 'Range'

test "AST as expected for Obj node", ->
  expression = getExpression '{a: a1: x, a2: y; b: b1: z, b2: w}'

  expected =
    type: 'Obj'
    generated: no
    lhs: no
    properties: [
      type: 'Assign'
      variable: value: 'a'
      value:
        type: 'Obj'
        generated: true
        lhs: no
        properties: [
          type: 'Assign'
          context: 'object'
          originalContext: 'object'
          variable: value: 'a1'
          value: value: 'x'
        ,
          type: 'Assign'
          context: 'object'
          originalContext: 'object'
          variable: value: 'a2'
          value: value: 'y'
        ]
    ,
      type: 'Assign'
      variable: value: 'b'
      value:
        type: 'Obj'
        generated: true
        lhs: no
        properties: [
          type: 'Assign'
          context: 'object'
          originalContext: 'object'
          variable: value: 'b1'
          value: value: 'z'
        ,
          type: 'Assign'
          context: 'object'
          originalContext: 'object'
          variable: value: 'b2'
          value: value: 'w'
        ]
    ]

  hasActualAllExpectedPropsAndAreTheyEqual = (actual, expected) ->
    for k , v of expected
      if 'object' is typeof v
        hasActualAllExpectedPropsAndAreTheyEqual actual[k], v
      else
        eq actual[k], v
    return

  hasActualAllExpectedPropsAndAreTheyEqual expression, expected

  # TODO: Test destructuring.

  # console.log JSON.stringify expression, ["type", "generated", "lhs", "value", "properties", "variable"], 2

test "AST as expected for Arr node", ->
  expression = getExpression '[]'
  eq expression.type, 'Arr'
  eq expression.lhs, no
  eq expression.objects.length, 0

  expression = getExpression '[3, "coffee", tables, !1]'
  eq expression.type, 'Arr'
  eq expression.lhs, no
  eq expression.objects.length, 4
  eq expression.objects[0].value, '3'
  eq expression.objects[1].value, '"coffee"'
  eq expression.objects[2].value, 'tables'
  eq expression.objects[3].type, 'Op'

  # TODO: Test destructuring.

test "AST as expected for Class node", ->
  expression = getExpression 'class Klass'
  eq expression.type, 'Class'
  eq expression.variable.value, 'Klass'
  eq expression.body.type, 'Block'
  eq expression.body.expressions.length, 0

  expression = getExpression 'class child extends parent'
  eq expression.type, 'Class'
  eq expression.variable.value, 'child'
  eq expression.parent.value, 'parent'
  eq expression.body.type, 'Block'
  eq expression.body.expressions.length, 0

  expression = getExpression 'class Klass then constructor: ->'
  eq expression.type, 'Class'
  eq expression.variable.value, 'Klass'
  eq expression.body.type, 'Value'
  eq expression.body.properties.length, 0
  eq expression.body.base.type, 'Obj'
  eq expression.body.base.generated, yes
  eq expression.body.base.properties[0].variable.value, 'constructor'
  eq expression.body.base.properties[0].value.type, 'Code'

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
