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
  white = (text, values...) -> (text[i] + "#{reset}#{v}#{red}" for v, i in values).join('') + text[i]
  eq actual.length, expected.length if expected instanceof Array and not expected.loose
  for k , v of expected
    if 'object' is typeof v
      fail white"`actual` misses #{k} property." unless k of actual
      deepStrictEqualExpectedProps actual[k], v
    else
      eq actual[k], v, white"Property #{k}: expected #{actual[k]} to equal #{v}"
  actual

# Flag array for loose comparision. See above code/comment.
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


test 'Confirm functionality of `deepStrictEqualExpectedProps`', ->
  actual =
    name: 'Name'
    a:
      b: 1
      c: 2
    x: [1, 2, 3]

  check = (message, test, expected) ->
    test (-> deepStrictEqualExpectedProps actual, expected), message

  check 'Expected prop does not match', throws,
    name: '"Name"'

  check 'Array length mismatch', throws,
    x: [1, 2]

  check 'Skip array length check', doesNotThrow,
    x: looseArray [
      1
      2
    ]

  check 'Array length matches', doesNotThrow,
    x: [1, 2, 3]

  check 'Array prop mismatch', throws,
    x: [3, 2, 1]

  check 'Partial object comparison', doesNotThrow,
    a:
      c: 2
    forbidden: undefined

  check 'Actual has forbidden prop', throws,
    a:
      b: 1
      c: undefined

  check 'Check prop for existence only', doesNotThrow,
    name: {}
    a: {}
    x: {}

  check 'Prop is missing', throws,
    missingProp: {}


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
    quote: '"'

  testExpression "'cheese string'",
    type: 'StringLiteral'
    value: "'cheese string'"
    quote: "'"

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
    here: no

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
      variable:
        type: 'ComputedPropertyName'
      value:
        type: 'Code'
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
  #       `@prop` property access isn't covered yet in these tests.

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
    expression:
      type: 'BooleanLiteral'

test "AST as expected for YieldReturn node", ->
  testExpression 'yield return ->',
    type: 'YieldReturn'
    expression:
      type: 'Code'

test "AST as expected for AwaitReturn node", ->
  testExpression 'await return ->',
    type: 'AwaitReturn'
    expression:
      type: 'Code'

test "AST as expected for Value node", ->
  testExpression 'for i in [] then i',
    body:
      type: 'Value'
      isDefaultValue: no
      base:
        value: 'i'
      properties: []

  testExpression 'if 1 then 1 else 2',
    body:
      type: 'Value'
      isDefaultValue: no
    elseBody:
      type: 'Value'
      isDefaultValue: no

  # TODO: Figgure out the purpose of `isDefaultValue`. It's not set in `Switch` either.

# Comments aren’t nodes, so they shouldn’t appear in the AST.

test "AST as expected for Call node", ->
  testExpression 'fn()',
    type: 'Call'
    variable:
      value: 'fn'

  testExpression 'new Date()',
    type: 'Call'
    variable:
      value: 'Date'
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
    variable:
      type: 'Code'

  testExpression 'do fn',
    type: 'Call'
    do: yes
    variable:
      type: 'IdentifierLiteral'
      value: 'fn'

test "AST as expected for SuperCall node", ->
  testExpression 'class child extends parent then constructor: -> super()',
    body:
      base:
        properties: [
          value:
            body:
              base:
                type: 'SuperCall'
        ]

test "AST as expected for Super node", ->
  testExpression 'class child extends parent then func: -> super.prop',
    body:
      base:
        properties: [
          value:
            body:
              base:
                type: 'Super'
                accessor:
                  type: 'Access'
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
    variable:
      value: 'child'
    parent:
      value: 'parent'
  # TODO: Is there no Extends node?

test "AST as expected for Access node", ->
  testExpression 'obj.prop',
    base:
      value: 'obj'
    properties: [
      type: 'Access'
      soak: no
      name:
        type: 'PropertyName'
        value: 'prop'
    ]

  testExpression 'obj?.prop',
    base:
      value: 'obj'
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
    from:
      value: 'x'
    to:
      value: 'y'

  testExpression '[4...2]',
    type: 'Range'
    exclusive: yes
    equals: ''
    from:
      value: '4'
    to:
      value: '2'

  testExpression 'for x in [42...43] then',
    range: yes
    source:
      type: 'Range'
      exclusive: yes
      equals: ''
      from:
        value: '42'
      to:
        value: '43'

  testExpression 'for x in [y..z] then',
    range: yes
    source:
      type: 'Range'
      exclusive: no
      equals: '='
      from:
        value: 'y'
      to:
        value: 'z'

  testExpression 'x[..y]',
    properties: [
      range:
        type: 'Range'
        exclusive: no
        equals: '='
        from: undefined
        to:
          value: 'y'
    ]

  testExpression 'x[y...]',
    properties: [
      range:
        type: 'Range'
        exclusive: yes
        equals: ''
        from:
          value: 'y'
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
      variable:
        value: 'a'
      value:
        type: 'Obj'
        generated: true
        lhs: no
        properties: [
          type: 'Assign'
          context: 'object'
          originalContext: 'object'
          variable:
            value: 'a1'
          value:
            value: 'x'
        ,
          type: 'Assign'
          context: 'object'
          originalContext: 'object'
          variable:
            value: 'a2'
          value:
            value: 'y'
        ]
    ,
      type: 'Assign'
      variable:
        value: 'b'
      value:
        type: 'Obj'
        generated: true
        lhs: no
        properties: [
          type: 'Assign'
          context: 'object'
          originalContext: 'object'
          variable:
            value: 'b1'
          value:
            value: 'z'
        ,
          type: 'Assign'
          context: 'object'
          originalContext: 'object'
          variable:
            value: 'b2'
          value:
            value: 'w'
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
    variable:
      value: 'Klass'
    body:
      type: 'Block'
      expressions: []

  testExpression 'class child extends parent',
    type: 'Class'
    variable:
      value: 'child'
    parent:
      value: 'parent'
    body:
      type: 'Block'
      expressions: []

  testExpression 'class Klass then constructor: ->',
    type: 'Class'
    variable:
      value: 'Klass'
    parent: undefined
    body:
      type: 'Value'
      properties: []
      base:
        type: 'Obj'
        generated: yes
        properties: [
          variable:
            value: 'constructor'
          value:
            type: 'Code'
        ]

test "AST as expected for ExecutableClassBody node", ->
  code = """
    class Klass
      privateStatic = if 42 then yes else no
      getPrivateStatic: -> privateStatic
    """
  testExpression code,
    type: 'Class'
    variable:
      value: 'Klass'
    body:
      type: 'Block'
      expressions: [
        type: 'Assign'
        variable:
          value: 'privateStatic'
        value:
          type: 'If'
      ,
        type: 'Obj'
        generated: true
        properties: [
          type: 'Assign'
          variable:
            value: 'getPrivateStatic'
          value:
            type: 'Code'
            body:
              type: 'Value'
              properties: []
        ]
      ]

test "AST as expected for ModuleDeclaration node", ->
  testExpression 'export {X}',
    clause:
      specifiers: [
        type: 'ExportSpecifier'
        moduleDeclarationType: 'export'
        identifier: 'X'
      ]

  testExpression 'import X from "."',
    clause:
      defaultBinding:
        type: 'ImportDefaultSpecifier'
        moduleDeclarationType: 'import'
        identifier: 'X'

test "AST as expected for ImportDeclaration node", ->
  testExpression 'import React, {Component} from "react"',
    type: 'ImportDeclaration'
    source:
      type: 'StringLiteral'
      value: '"react"'
      originalValue: 'react'

test "AST as expected for ImportClause node", ->
  testExpression 'import React, {Component} from "react"',
    clause:
      type: 'ImportClause'
      defaultBinding:
        type: 'ImportDefaultSpecifier'
      namedImports:
        type: 'ImportSpecifierList'

test "AST as expected for ExportDeclaration node", ->
  testExpression 'export {X}',
    clause:
      specifiers: [
        type: 'ExportSpecifier'
        moduleDeclarationType: 'export'
        identifier: 'X'
      ]

test "AST as expected for ExportNamedDeclaration node", ->
  testExpression 'export fn = ->',
    type: 'ExportNamedDeclaration'
    clause:
      type: 'Assign'
      variable:
        value: 'fn'
      value:
        type: 'Code'

test "AST as expected for ExportDefaultDeclaration node", ->
  testExpression 'export default class',
    type: 'ExportDefaultDeclaration'
    clause:
      type: 'Class'

test "AST as expected for ExportAllDeclaration node", ->
  testExpression 'export * from "module-name"',
    type: 'ExportAllDeclaration'
    clause:
      type: 'Literal'
      value: '*'
    source:
      type: 'StringLiteral'
      value: '"module-name"'
      originalValue: 'module-name'
      quote: '"'
      initialChunk: yes
      finalChunk: yes
      fromSourceString: yes

# `ModuleSpecifierList` never makes it into the AST.

test "AST as expected for ImportSpecifierList node", ->
  testExpression 'import React, {Component} from "react"',
    clause:
      namedImports:
        type: 'ImportSpecifierList'
        specifiers: [
          identifier: 'Component'
        ]

test "AST as expected for ExportSpecifierList node", ->
  testExpression 'export {a, b, c}',
    clause:
      type: 'ExportSpecifierList'
      specifiers: [
        {identifier: 'a'}
        {identifier: 'b'}
        {identifier: 'c'}
      ]

# `ModuleSpecifier` never makes it into the AST.

test "AST as expected for ImportSpecifier node", ->
  testExpression 'import {Component, PureComponent} from "react"',
    clause:
      namedImports:
        specifiers: [
          type: 'ImportSpecifier'
          identifier: 'Component'
          moduleDeclarationType: 'import'
          original:
            type: 'IdentifierLiteral'
            value: 'Component'
        ,
          type: 'ImportSpecifier'
          identifier: 'PureComponent'
        ]

test "AST as expected for ImportDefaultSpecifier node", ->
  testExpression 'import React from "react"',
    clause:
      defaultBinding:
        type: 'ImportDefaultSpecifier'
        moduleDeclarationType: 'import'
        identifier: 'React'
        original:
          type: 'IdentifierLiteral'

test "AST as expected for ImportNamespaceSpecifier node", ->
  # TODO

test "AST as expected for ExportSpecifier node", ->
  testExpression 'export {X}',
    clause:
      specifiers: [
        type: 'ExportSpecifier'
        moduleDeclarationType: 'export'
        identifier: 'X'
        original:
          type: 'IdentifierLiteral'
      ]

test "AST as expected for Assign node", ->
  testExpression 'a = 1',
    type: 'Assign'
    variable:
      value: 'a'
    value:
      value: '1'

  testExpression 'a: 1',
    properties: [
      type: 'Assign'
      context: 'object'
      originalContext: 'object'
      variable:
        value: 'a'
      value:
        value: '1'
    ]

# `FuncGlyph` node isn't exported.

test "AST as expected for Code node", ->
  testExpression '=>',
    type: 'Code'
    bound: yes
    body:
      type: 'Block'

  testExpression '-> await 3',
    type: 'Code'
    bound: no
    isAsync: yes
    isMethod: no      # TODO: What's this flag?
    body:
      type: 'Op'
      operator: 'await'
      first:
        type: 'NumberLiteral'
        value: '3'

  testExpression '-> yield 4',
    type: 'Code'
    isGenerator: yes
    body:
      type: 'Op'
      operator: 'yield'
      first:
        type: 'NumberLiteral'
        value: '4'

test "AST as expected for Param node", ->
  testExpression '(a = 1) ->',
    params: [
      type: 'Param'
      name:
        value: 'a'
      value:
        value: '1'
    ]

test "AST as expected for Splat node", ->
  testExpression '(a...) ->',
    params: [
      type: 'Param'
      splat: yes
      name:
        value: 'a'
    ]

  # TODO: Test object splats.

test "AST as expected for Expansion node", ->
  # TODO: Seems to not be exported, confirm and strip test.

test "AST as expected for Elision node", ->
  testExpression '[,,,a,,,b] = "asdfqwer"',
    type: 'Assign'
    variable:
      type: 'Arr'
      lhs: no
      objects: [
        {type: 'Elision'}
        {type: 'Elision'}
        {type: 'Elision'}
        {
          type: 'IdentifierLiteral'
          value: 'a'
        }
        {type: 'Elision'}
        {type: 'Elision'}
        {
          type: 'IdentifierLiteral'
          value: 'b'
        }
      ]
    value:
      type: 'StringLiteral'
      value: '"asdfqwer"'
      originalValue: 'asdfqwer'
      quote: '"'

test "AST as expected for While node", ->
  testExpression 'loop 1',
    type: 'While'
    condition:
      type: 'BooleanLiteral'
      value: 'true'
      originalValue: 'true'   # TODO: This should probably be changed for Prettier.
    body:
      type: 'Value'

  testExpression 'while 1 < 2 then',
    type: 'While'
    condition:
      type: 'Op'
    body:
      type: 'Block'

test "AST as expected for Op node", ->
  testExpression '1 <= 2',
    type: 'Op'
    operator: '<='
    originalOperator: '<='
    flip: no
    first:
      value: '1'
    second:
      value: '2'

  testExpression '1 is 2',
    type: 'Op'
    operator: '==='
    originalOperator: 'is'
    flip: no

  testExpression '1 // 2',
    type: 'Op'
    operator: '//'
    originalOperator: '//'
    flip: no

  testExpression '1 << 2',
    type: 'Op'
    operator: '<<'
    originalOperator: '<<'
    flip: no

  testExpression 'new Old',   # NOTE: `new` with params is a `Call` node.
    type: 'Op'
    operator: 'new'
    originalOperator: 'new'
    flip: no
    first:
      value: 'Old'

  testExpression '-> await 2',
    type: 'Code'
    isAsync: yes
    body:
      type: 'Op'
      operator: 'await'
      originalOperator: 'await'
      first:
        type: 'NumberLiteral'
        value: '2'

  testExpression '-> yield 2',
    type: 'Code'
    isGenerator: yes
    body:
      type: 'Op'
      operator: 'yield'
      originalOperator: 'yield'
      first:
        type: 'NumberLiteral'
        value: '2'

test "AST as expected for In node", ->
  testExpression '1 in 2',
    type: 'Op'
    operator: 'in'
    originalOperator: 'in'
    flip: no
    first:
      value: '1'
    second:
      value: '2'

  testExpression 'for x in 2 then',
    type: 'For'
    range: no
    pattern: no

test "AST as expected for Try node", ->
  testExpression 'try cappuccino',
    type: 'Try'
    attempt:
      type: 'Value'
    recovery: undefined

  testExpression 'try to catch it then log it',
    type: 'Try'
    attempt:
      type: 'Value'
    recovery:
      type: 'Value'
      base:
        type: 'Call'

test "AST as expected for Throw node", ->
  testExpression 'throw new BallError "catch"',
    type: 'Throw'
    expression:
      type: 'Call'
      isNew: yes

test "AST as expected for Existence node", ->
  testExpression 'Ghosts?',
    type: 'Existence',
    comparisonTarget: 'null'
    expression:
      value: 'Ghosts'

  # NOTE: Soaking is covered in `Call` and `Access` nodes.

test "AST as expected for Parens node", ->
  testExpression '(hmmmmm)',
    type: 'Parens',
    body:
      type: 'Value'

  testExpression '(a + b) / c',
    type: 'Op'
    operator: '/'
    first:
      type: 'Parens'
      body:
        type: 'Op'
        operator: '+'

  testExpression '(((1)))',
    type: 'Parens',
    body:
      type: 'Value'
      base:
        type: 'Block'
        expressions: [
          type: 'Parens',
          body:
            type: 'Value'
            base:
              value: '1'
        ]

test "AST as expected for StringWithInterpolations node", ->
  testExpression '"#{o}/"',
    type: 'StringWithInterpolations'
    quote: '"'
    body:
      type: 'Block'
      expressions: [
        originalValue: ''
      ,
        type: 'Interpolation'
        expression:
          type: 'Value'
          base:
            value: 'o'
      ,
        originalValue: '/'
      ]

test "AST as expected for For node", ->
  testExpression 'for x, i in arr when x? then return',
    type: 'For'
    from: undefined
    object: undefined
    range: no
    pattern: no
    returns: no
    guard:
      type: 'Existence'
    source:
      type: 'IdentifierLiteral'
    body:
      type: 'Return'

  testExpression 'for k, v of obj then return',
    type: 'For'
    from: undefined
    object: yes
    range: no
    pattern: no
    returns: no
    guard: undefined
    source:
      type: 'IdentifierLiteral'

  testExpression 'for x from iterable then',
    type: 'For'
    from: yes
    object: undefined
    body:
      type: 'Block'
    source:
      type: 'IdentifierLiteral'

  testExpression 'for i in [0...42] by step when not i % 2 then',
    type: 'For'
    from: undefined
    object: undefined
    range: yes
    pattern: no
    returns: no
    body:
      type: 'Block'
    source:
      type: 'Range'
    guard:
      type: 'Op'
    step:
      type: 'IdentifierLiteral'

  testExpression 'a = (x for x in y)',
    type: 'Assign'
    value:
      type: 'Parens'
      body:
        type: 'For'
        returns: no
        pattern: no

  # TODO: Figgure out the purpose of `pattern` and `returns`.

test "AST as expected for Switch node", ->
  testExpression 'switch x \n when a then a; when b, c then c else 42',
    type: 'Switch'
    subject:
      type: 'IdentifierLiteral'
      value: 'x'
    cases: [
      {
        type: 'IdentifierLiteral'
        value: 'a'
      }
      {
        type: 'Value'
        base:
          value: 'a'
      }
      {
        type: 'IdentifierLiteral'
        value: 'b'
      }
      {
        type: 'IdentifierLiteral'
        value: 'c'
      }
      {
        type: 'Value'
        base:
          value: 'c'
      }
    ]
    otherwise:
      type: 'Value'
      base:
        value: '42'
      isDefaultValue: no

  # TODO: File issue for compile error when using `then` or `;` where `\n` is rn.

test "AST as expected for If node", ->
  testExpression 'if maybe then yes',
    type: 'If'
    isChain: no
    condition:
      type: 'IdentifierLiteral'
    body:
      type: 'Value'
      base:
        type: 'BooleanLiteral'

  testExpression 'yes if maybe',
    type: 'If'
    isChain: no
    condition:
      type: 'IdentifierLiteral'
    body:
      type: 'Value'
      base:
        type: 'BooleanLiteral'

  # TODO: Where's the post-if flag?

  testExpression 'unless x then x else if y then y else z',
    type: 'If'
    isChain: yes
    condition:
      type: 'Op'
      operator: '!'
      originalOperator: '!'
      flip: no
    body:
      type: 'Value'
    elseBody:
      type: 'If'
      isChain: no
      condition:
        type: 'IdentifierLiteral'
      body:
        type: 'Value'
      elseBody:
        type: 'Value'
        isDefaultValue: no

  # TODO: AST generator should preserve use of `unless`.
