# Astract Syntax Tree generation
# ------------------------------

# Helpers to get AST nodes for a string of code. The root node is always a
# `Block` node, so for brevity in the tests return its children from
# `expressions`.
getExpressions = (code) ->
  ast = CoffeeScript.compile code, ast: yes
  ast.expressions

getExpression = (code) -> getExpressions(code)[0]

# Recursively compare all values of enumerable properties of `expected` with
# those of `actual`. Use `looseArray` helper function to skip array length
# comparison.
deepStrictEqualExpectedProps = (actual, expected) ->
  eq actual.length, expected.length if expected instanceof Array and not expected.loose
  for k , v of expected
    if 'object' is typeof v
      deepStrictEqualExpectedProps actual[k], v
    else
      eq actual[k], v
  actual

# Flag array for loose copmarision. See above code/comment.
looseArray = (arr) ->
  Object.defineProperty arr, 'loose',
    value: yes
    enumerable: no
  arr

testExpressions = (code, expected) ->
  ast = getExpressions code
  return console.log ast unless expected?
  deepStrictEqualExpectedProps ast, expected

testExpression = (code, expected) ->
  ast = getExpression code
  return console.log ast unless expected?
  deepStrictEqualExpectedProps ast, expected


# Check each node type in the same order as they appear in `nodes.coffee`.
# For nodes that have equivalents in Babel’s AST spec, we’re checking that
# the type and properties match. When relevant, also check that values of
# properties are as expected.

test "AST as expected for Block node", ->
  deepStrictEqualExpectedProps CoffeeScript.compile('return', ast: yes),
    type: 'Block'
    expressions: [
      type: 'Return'
    ]

# Can’t test for `Literal` node, as it’s a base class for the `*Literal`
# classes.

test "AST as expected for NumberLiteral node", ->
  testExpression '42',
    type: 'NumberLiteral'
    value: '42'

test "AST as expected for InfinityLiteral node", ->
  testExpression 'Infinity',
    type: 'InfinityLiteral'
    value: 'Infinity'

test "AST as expected for NaNLiteral node", ->
  testExpression 'NaN',
    type: 'NaNLiteral'
    value: 'NaN'

test "AST as expected for StringLiteral node", ->
  testExpression '"string cheese"',
    type: 'StringLiteral'
    value: '"string cheese"'

test "AST as expected for RegexLiteral node", ->
  testExpression '/^(?!.*(.).*\\1)[gimsuy]*$/',
    type: 'RegexLiteral'
    value: '/^(?!.*(.).*\\1)[gimsuy]*$/'

test "AST as expected for PassthroughLiteral node", ->
  code = 'const CONSTANT = "unreassignable!"'
  testExpression "`#{code}`",
    type: 'PassthroughLiteral'
    value: code
    originalValue: code
    here: false

  code = '\nconst CONSTANT = "unreassignable!"\n'
  testExpression "```#{code}```",
    type: 'PassthroughLiteral'
    value: code
    originalValue: code
    here: yes

test "AST as expected for IdentifierLiteral node", ->
  testExpression 'id = "undercover agent"',
    variable:
      type: 'IdentifierLiteral'
      value: 'id'

test "AST as expected for CSXTag node", ->
  testExpression '<CSXY />',
    variable:
      type: 'CSXTag'
      value: 'CSXY'

test "AST as expected for PropertyName node", ->
  testExpression 'Object.assign',
    properties: [
      name:
        type: 'PropertyName'
        value: 'assign'
    ]

test "AST as expected for ComputedPropertyName node", ->
  testExpression '[fn]: ->',
    type: 'Obj'
    properties: [
      type: 'Assign'
      context: 'object'
      variable: type: 'ComputedPropertyName'
      value: type: 'Code'
    ]
  # TODO: `'fn'` identifier is missing from AST.

test "AST as expected for StatementLiteral node", ->
  testExpression 'break',
    type: 'StatementLiteral'
    value: 'break'

test "AST as expected for ThisLiteral node", ->
  testExpression 'this',
    type: 'ThisLiteral'
    value: 'this'

  testExpression '@',
    type: 'ThisLiteral'
    value: 'this'
    # originalValue: '@'
  # TODO: `@` literal is not yet preserved in ast generation.

test "AST as expected for UndefinedLiteral node", ->
  testExpression 'undefined',
    type: 'UndefinedLiteral'
    value: 'undefined'

test "AST as expected for NullLiteral node", ->
  testExpression 'null',
    type: 'NullLiteral'
    value: 'null'

test "AST as expected for BooleanLiteral node", ->
  testExpression 'true',
    type: 'BooleanLiteral'
    value: 'true'

  testExpression 'off',
    type: 'BooleanLiteral'
    value: 'false'
    originalValue: 'off'

  testExpression 'yes',
    type: 'BooleanLiteral'
    value: 'true'
    originalValue: 'yes'

test "AST as expected for Return node", ->
  testExpression 'return no',
    type: 'Return'
    expression: type: 'BooleanLiteral'

test "AST as expected for YieldReturn node", ->
  testExpression 'yield return ->',
    type: 'YieldReturn'
    expression: type: 'Code'

test "AST as expected for AwaitReturn node", ->
  testExpression 'await return ->',
    type: 'AwaitReturn'
    expression: type: 'Code'

test "AST as expected for Value node", ->
  testExpression 'for i in [] then i',
    body:
      type: 'Value'
      base: value: 'i'
      properties: []

# Comments aren’t nodes, so they shouldn’t appear in the AST.

test "AST as expected for Call node", ->
  testExpression 'fn()',
    type: 'Call'
    variable: value: 'fn'

  testExpression 'new Date()',
    type: 'Call'
    variable: value: 'Date'
    isNew: yes

  testExpression 'maybe?()',
    type: 'Call'
    soak: yes

  testExpression 'goDo this, that',
    type: 'Call'
    args: [
      {value: 'this'}
      {value: 'that'}
    ]

  testExpression 'do ->',
    type: 'Call'
    do: yes
    variable: type: 'Code'

  testExpression 'do fn',
    type: 'Call'
    do: yes
    variable:
      type: 'IdentifierLiteral'
      value: 'fn'

test "AST as expected for SuperCall node", ->
  testExpression 'class child extends parent then constructor: -> super()',
    body: base: properties: [
      value: body: base:
        type: 'SuperCall'
    ]

test "AST as expected for Super node", ->
  testExpression 'class child extends parent then func: -> super.prop',
    body: base: properties: [
      value: body: base:
        type: 'Super'
        accessor: type: 'Access'
    ]

test "AST as expected for RegexWithInterpolations node", ->
  testExpression '///^#{flavor}script$///',
    type: 'RegexWithInterpolations'

  # TODO: Shouldn't there be more info we can check for?

test "AST as expected for TaggedTemplateCall node", ->
  testExpression 'func"tagged"',
    type: 'TaggedTemplateCall'
    args: [
      type: 'StringWithInterpolations'
    ]

test "AST as expected for Extends node", ->
  testExpression 'class child extends parent',
    type: 'Class'
    variable: value: 'child'
    parent: value: 'parent'
  # TODO: Is there no Extends node?

test "AST as expected for Access node", ->
  testExpression 'obj.prop',
    base: value: 'obj'
    properties: [
      type: 'Access'
      soak: no
      name:
        type: 'PropertyName'
        value: 'prop'
    ]

  testExpression 'obj?.prop',
    base: value: 'obj'
    properties: [
      type: 'Access'
      soak: yes
      name:
        type: 'PropertyName'
        value: 'prop'
    ]

test "AST as expected for Index node", ->
  testExpression 'for x, i in iterable then',
    type: 'For'
  # TODO: Where's the Index node?

test "AST as expected for Range node", ->
  testExpression '[x..y]',
    type: 'Range'
    exclusive: no
    equals: '='
    from: value: 'x'
    to: value: 'y'

  testExpression '[4...2]',
    type: 'Range'
    exclusive: yes
    equals: ''
    from: value: '4'
    to: value: '2'

  testExpression 'for x in [42...43] then',
    range: yes
    source:
      type: 'Range'
      exclusive: yes
      equals: ''
      from: value: '42'
      to: value: '43'

  testExpression 'for x in [y..z] then',
    range: yes
    source:
      type: 'Range'
      exclusive: no
      equals: '='
      from: value: 'y'
      to: value: 'z'

  testExpression 'x[..y]',
    properties: [
      range:
        type: 'Range'
        exclusive: no
        equals: '='
        from: undefined
        to: value: 'y'
    ]

  testExpression 'x[y...]',
    properties: [
      range:
        type: 'Range'
        exclusive: yes
        equals: ''
        from: value: 'y'
        to: undefined
    ]

  testExpression 'x[...]',
    properties: [
      range:
        type: 'Range'
        exclusive: yes
        equals: ''
        from: undefined
        to: undefined
    ]

test "AST as expected for Slice node", ->
  testExpression '"abc"[...2]',
    properties: [
      type: 'Slice'
    ]

  expression = getExpression 'x[...][a..][b...][..c][...d]'
  eq expression.properties.length, 5
  for slice in expression.properties
    eq slice.type, 'Slice'
    eq slice.range.type, 'Range'

test "AST as expected for Obj node", ->
  testExpression '{a: a1: x, a2: y; b: b1: z, b2: w}',
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

  # TODO: Test destructuring.

  # console.log JSON.stringify expression, ["type", "generated", "lhs", "value", "properties", "variable"], 2

test "AST as expected for Arr node", ->
  testExpression '[]',
    type: 'Arr'
    lhs: no
    objects: []

  testExpression '[3, "coffee", tables, !1]',
    type: 'Arr'
    lhs: no
    objects: [
      {value: '3'}
      {value: '"coffee"'}
      {value: 'tables'}     # TODO: File issue for `, value: whatever` syntax not splitting objects properly.
      {type: 'Op'}
    ]

  # TODO: Test destructuring.

test "AST as expected for Class node", ->
  testExpression 'class Klass',
    type: 'Class'
    variable: value: 'Klass'
    body:
      type: 'Block'
      expressions: []

  testExpression 'class child extends parent',
    type: 'Class'
    variable: value: 'child'
    parent: value: 'parent'
    body:
      type: 'Block'
      expressions: []

  testExpression 'class Klass then constructor: ->',
    type: 'Class'
    variable: value: 'Klass'
    parent: undefined
    body:
      type: 'Value'
      properties: []
      base:
        type: 'Obj'
        generated: yes
        properties: [
          variable: value: 'constructor'
          value: type: 'Code'
        ]

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
