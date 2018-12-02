# Astract Syntax Tree generation
# ------------------------------

# Recursively compare all values of enumerable properties of `expected` with
# those of `actual`. Use `looseArray` helper function to skip array length
# comparison.
deepStrictIncludeExpectedProperties = (actual, expected) ->
  eq actual.length, expected.length if expected instanceof Array and not expected.loose
  for key, val of expected
    if val? and typeof val is 'object'
      fail "Property #{reset}#{key}#{red} expected, but was missing" unless actual[key]
      deepStrictIncludeExpectedProperties actual[key], val
    else
      eq actual[key], val, """
        Property #{reset}#{key}#{red}: expected #{reset}#{actual[key]}#{red} to equal #{reset}#{val}#{red}
          Expected AST output to include:
          #{reset}#{inspect expected}#{red}
          but instead it was:
          #{reset}#{inspect actual}#{red}
      """
  actual

# Flag array for loose comparison. See reference to `.loose` in
# `deepStrictIncludeExpectedProperties` above.
looseArray = (arr) ->
  Object.defineProperty arr, 'loose',
    value: yes
    enumerable: no
  arr

testExpression = (code, expected) ->
  ast = getAstExpression code
  if expected?
    deepStrictIncludeExpectedProperties ast, expected
  else
    # Convenience for creating new tests; call `testExpression` with no second
    # parameter to see what the current AST generation is for your input code.
    console.log inspect ast


test 'Confirm functionality of `deepStrictIncludeExpectedProperties`', ->
  actual =
    name: 'Name'
    a:
      b: 1
      c: 2
    x: [1, 2, 3]

  check = (message, test, expected) ->
    test (-> deepStrictIncludeExpectedProperties actual, expected), message

  check 'Expected property does not match', throws,
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
  deepStrictIncludeExpectedProperties CoffeeScript.compile('a', ast: yes),
    type: 'File'
    program:
      type: 'Program'
      # sourceType: 'module'
      body: [
        type: 'ExpressionStatement'
        expression:
          type: 'Identifier'
      ]
      directives: []
    comments: []

test "AST as expected for NumberLiteral node", ->
  testExpression '42',
    type: 'NumericLiteral'
    value: 42
    extra:
      rawValue: 42
      raw: '42'

  testExpression '0xE1',
    type: 'NumericLiteral'
    value: 225
    extra:
      rawValue: 225
      raw: '0xE1'

test "AST as expected for InfinityLiteral node", ->
  testExpression 'Infinity',
    type: 'Identifier'
    name: 'Infinity'

test "AST as expected for NaNLiteral node", ->
  testExpression 'NaN',
    type: 'Identifier'
    name: 'NaN'

# test "AST as expected for StringLiteral node", ->
#   testExpression '"string cheese"',
#     type: 'StringLiteral'
#     value: '"string cheese"'
#     quote: '"'

#   testExpression "'cheese string'",
#     type: 'StringLiteral'
#     value: "'cheese string'"
#     quote: "'"

# test "AST as expected for RegexLiteral node", ->
#   testExpression '/^(?!.*(.).*\\1)[gimsuy]*$/',
#     type: 'RegexLiteral'
#     value: '/^(?!.*(.).*\\1)[gimsuy]*$/'

# test "AST as expected for PassthroughLiteral node", ->
#   code = 'const CONSTANT = "unreassignable!"'
#   testExpression "`#{code}`",
#     type: 'PassthroughLiteral'
#     value: code
#     originalValue: code
#     here: no

#   code = '\nconst CONSTANT = "unreassignable!"\n'
#   testExpression "```#{code}```",
#     type: 'PassthroughLiteral'
#     value: code
#     originalValue: code
#     here: yes

test "AST as expected for IdentifierLiteral node", ->
  testExpression 'id',
    type: 'Identifier'
    name: 'id'

test "AST as expected for CSXTag node", ->
  testExpression '<CSXY />',
    type: 'JSXElement'
    openingElement:
      type: 'JSXOpeningElement'
      name:
        type: 'JSXIdentifier'
        name: 'CSXY'
      attributes: []
      selfClosing: yes
    closingElement: null
    children: []

  testExpression '<div></div>',
    type: 'JSXElement'
    openingElement:
      type: 'JSXOpeningElement'
      name:
        type: 'JSXIdentifier'
        name: 'div'
      attributes: []
      selfClosing: no
    closingElement:
      type: 'JSXClosingElement'
      name:
        type: 'JSXIdentifier'
        name: 'div'
    children: []

  testExpression '<A.B />',
    type: 'JSXElement'
    openingElement:
      type: 'JSXOpeningElement'
      name:
        type: 'JSXMemberExpression'
        object:
          type: 'JSXIdentifier'
          name: 'A'
        property:
          type: 'JSXIdentifier'
          name: 'B'
      attributes: []
      selfClosing: yes
    closingElement: null
    children: []

  testExpression '<Tag.Name.Here></Tag.Name.Here>',
    type: 'JSXElement'
    openingElement:
      type: 'JSXOpeningElement'
      name:
        type: 'JSXMemberExpression'
        object:
          type: 'JSXMemberExpression'
          object:
            type: 'JSXIdentifier'
            name: 'Tag'
          property:
            type: 'JSXIdentifier'
            name: 'Name'
        property:
          type: 'JSXIdentifier'
          name: 'Here'
      attributes: []
      selfClosing: no
    closingElement:
      type: 'JSXClosingElement'
      name:
        type: 'JSXMemberExpression'
        object:
          type: 'JSXMemberExpression'
          object:
            type: 'JSXIdentifier'
            name: 'Tag'
          property:
            type: 'JSXIdentifier'
            name: 'Name'
        property:
          type: 'JSXIdentifier'
          name: 'Here'
    children: []

  testExpression '<></>',
    type: 'JSXFragment'
    openingFragment:
      type: 'JSXOpeningFragment'
    closingFragment:
      type: 'JSXClosingFragment'
    children: []

  testExpression '<div a b="c" d={e} {...f} />',
    type: 'JSXElement'
    openingElement:
      type: 'JSXOpeningElement'
      name:
        type: 'JSXIdentifier'
        name: 'div'
      attributes: [
        type: 'JSXAttribute'
        name:
          type: 'JSXIdentifier'
          name: 'a'
      ,
        type: 'JSXAttribute'
        name:
          type: 'JSXIdentifier'
          name: 'b'
        value:
          type: 'StringLiteral'
          value: 'c'
      ,
        type: 'JSXAttribute'
        name:
          type: 'JSXIdentifier'
          name: 'd'
        value:
          type: 'JSXExpressionContainer'
          expression:
            type: 'Identifier'
            name: 'e'
      ,
        type: 'JSXSpreadAttribute'
        argument:
          type: 'Identifier'
          name: 'f'
        postfix: no
      ]
      selfClosing: yes
    closingElement: null
    children: []

  testExpression '<div {f...} />',
    type: 'JSXElement'
    openingElement:
      type: 'JSXOpeningElement'
      attributes: [
        type: 'JSXSpreadAttribute'
        argument:
          type: 'Identifier'
          name: 'f'
        postfix: yes
      ]

# test "AST as expected for PropertyName node", ->
#   testExpression 'Object.assign',
#     properties: [
#       name:
#         type: 'PropertyName'
#         value: 'assign'
#     ]

test "AST as expected for ComputedPropertyName node", ->
  # testExpression '[fn]: ->',
  #   type: 'Obj'
  #   properties: [
  #     type: 'Assign'
  #     context: 'object'
  #     variable:
  #       type: 'ComputedPropertyName'
  #     value:
  #       type: 'Code'
  #   ]

  testExpression '[a]: b',
    type: 'ObjectExpression'
    properties: [
      type: 'ObjectProperty'
      key:
        type: 'Identifier'
        name: 'a'
      value:
        type: 'Identifier'
        name: 'b'
      computed: yes
      shorthand: no
      method: no
    ]
    implicit: yes

test "AST as expected for StatementLiteral node", ->
  testExpression 'break',
    type: 'BreakStatement'

  testExpression 'continue',
    type: 'ContinueStatement'

  testExpression 'debugger',
    type: 'DebuggerStatement'

test "AST as expected for ThisLiteral node", ->
  testExpression 'this',
    type: 'ThisExpression'
    shorthand: no

  testExpression '@',
    type: 'ThisExpression'
    shorthand: yes
  # TODO: `@prop` property access isn't covered yet in these tests.

test "AST as expected for UndefinedLiteral node", ->
  testExpression 'undefined',
    type: 'Identifier'
    name: 'undefined'

test "AST as expected for NullLiteral node", ->
  testExpression 'null',
    type: 'NullLiteral'

test "AST as expected for BooleanLiteral node", ->
  testExpression 'true',
    type: 'BooleanLiteral'
    value: true
    name: 'true'

  testExpression 'off',
    type: 'BooleanLiteral'
    value: false
    name: 'off'

  testExpression 'yes',
    type: 'BooleanLiteral'
    value: true
    name: 'yes'

# test "AST as expected for Return node", ->
#   testExpression 'return no',
#     type: 'Return'
#     expression:
#       type: 'BooleanLiteral'

# test "AST as expected for YieldReturn node", ->
#   testExpression 'yield return ->',
#     type: 'YieldReturn'
#     expression:
#       type: 'Code'

# test "AST as expected for AwaitReturn node", ->
#   testExpression 'await return ->',
#     type: 'AwaitReturn'
#     expression:
#       type: 'Code'

# test "AST as expected for Value node", ->
#   testExpression 'for i in [] then i',
#     body:
#       type: 'Value'
#       isDefaultValue: no
#       base:
#         value: 'i'
#       properties: []

#   testExpression 'if 1 then 1 else 2',
#     body:
#       type: 'Value'
#       isDefaultValue: no
#     elseBody:
#       type: 'Value'
#       isDefaultValue: no

#   # TODO: Figgure out the purpose of `isDefaultValue`. It's not set in `Switch` either.

# # Comments aren’t nodes, so they shouldn’t appear in the AST.

test "AST as expected for Call node", ->
  testExpression 'fn()',
    type: 'CallExpression'
    callee:
      type: 'Identifier'
      name: 'fn'
    arguments: []
    optional: no
    implicit: no

  testExpression 'new Date()',
    type: 'NewExpression'
    callee:
      type: 'Identifier'
      name: 'Date'
    arguments: []
    optional: no
    implicit: no

  testExpression 'new Date?()',
    type: 'NewExpression'
    callee:
      type: 'Identifier'
      name: 'Date'
    arguments: []
    optional: yes
    implicit: no

  testExpression 'new Old',
    type: 'NewExpression'
    callee:
      type: 'Identifier'
      name: 'Old'
    arguments: []
    optional: no
    implicit: no

  testExpression 'new Old(1)',
    type: 'NewExpression'
    callee:
      type: 'Identifier'
      name: 'Old'
    arguments: [
      type: 'NumericLiteral'
      value: 1
    ]
    optional: no
    implicit: no

  testExpression 'new Old 1',
    type: 'NewExpression'
    callee:
      type: 'Identifier'
      name: 'Old'
    arguments: [
      type: 'NumericLiteral'
      value: 1
    ]
    optional: no
    implicit: yes

  testExpression 'maybe?()',
    type: 'CallExpression'
    optional: yes
    implicit: no

  testExpression 'maybe?(1 + 1)',
    type: 'CallExpression'
    arguments: [
      type: 'BinaryExpression'
    ]
    optional: yes
    implicit: no

  testExpression 'maybe? 1 + 1',
    type: 'CallExpression'
    arguments: [
      type: 'BinaryExpression'
    ]
    optional: yes
    implicit: yes

  testExpression 'goDo this, that',
    type: 'CallExpression'
    arguments: [
      type: 'ThisExpression'
    ,
      type: 'Identifier'
      name: 'that'
    ]
    implicit: yes
    optional: no

# test "AST as expected for SuperCall node", ->
#   testExpression 'class child extends parent then constructor: -> super()',
#     body:
#       base:
#         properties: [
#           value:
#             body:
#               base:
#                 type: 'SuperCall'
#         ]

# test "AST as expected for Super node", ->
#   testExpression 'class child extends parent then func: -> super.prop',
#     body:
#       base:
#         properties: [
#           value:
#             body:
#               base:
#                 type: 'Super'
#                 accessor:
#                   type: 'Access'
#     ]

# test "AST as expected for RegexWithInterpolations node", ->
#   testExpression '///^#{flavor}script$///',
#     type: 'RegexWithInterpolations'

#   # TODO: Shouldn't there be more info we can check for?

# test "AST as expected for TaggedTemplateCall node", ->
#   testExpression 'func"tagged"',
#     type: 'TaggedTemplateCall'
#     args: [
#       type: 'StringWithInterpolations'
#     ]

# test "AST as expected for Extends node", ->
#   testExpression 'class child extends parent',
#     type: 'Class'
#     variable:
#       value: 'child'
#     parent:
#       value: 'parent'
#   # TODO: Is there no Extends node?

test "AST as expected for Access node", ->
  testExpression 'obj.prop',
    type: 'MemberExpression'
    object:
      type: 'Identifier'
      name: 'obj'
    property:
      type: 'Identifier'
      name: 'prop'
    computed: no
    optional: no
    shorthand: no

  testExpression 'obj?.prop',
    # TODO: support Babel 7-style OptionalMemberExpression type
    # type: 'OptionalMemberExpression'
    type: 'MemberExpression'
    object:
      type: 'Identifier'
      name: 'obj'
    property:
      type: 'Identifier'
      name: 'prop'
    computed: no
    optional: yes
    shorthand: no

  testExpression 'a::b',
    type: 'MemberExpression'
    object:
      type: 'MemberExpression'
      object:
        type: 'Identifier'
        name: 'a'
      property:
        type: 'Identifier'
        name: 'prototype'
      computed: no
      optional: no
      shorthand: yes
    property:
      type: 'Identifier'
      name: 'b'
    computed: no
    optional: no
    shorthand: no

  testExpression 'a.prototype.b',
    type: 'MemberExpression'
    object:
      type: 'MemberExpression'
      object:
        type: 'Identifier'
        name: 'a'
      property:
        type: 'Identifier'
        name: 'prototype'
      computed: no
      optional: no
      shorthand: no
    property:
      type: 'Identifier'
      name: 'b'
    computed: no
    optional: no
    shorthand: no

  testExpression 'a?.b.c',
    type: 'MemberExpression'
    object:
      type: 'MemberExpression'
      object:
        type: 'Identifier'
        name: 'a'
      property:
        type: 'Identifier'
        name: 'b'
      computed: no
      optional: yes
      shorthand: no
    property:
      type: 'Identifier'
      name: 'c'
    computed: no
    optional: no
    shorthand: no

test "AST as expected for Index node", ->
  testExpression 'a[b]',
    type: 'MemberExpression'
    object:
      type: 'Identifier'
      name: 'a'
    property:
      type: 'Identifier'
      name: 'b'
    computed: yes
    optional: no
    shorthand: no

  testExpression 'a?[b]',
    type: 'MemberExpression'
    object:
      type: 'Identifier'
      name: 'a'
    property:
      type: 'Identifier'
      name: 'b'
    computed: yes
    optional: yes
    shorthand: no

  testExpression 'a::[b]',
    type: 'MemberExpression'
    object:
      type: 'MemberExpression'
      object:
        type: 'Identifier'
        name: 'a'
      property:
        type: 'Identifier'
        name: 'prototype'
      computed: no
      optional: no
      shorthand: yes
    property:
      type: 'Identifier'
      name: 'b'
    computed: yes
    optional: no
    shorthand: no

  testExpression 'a[b][3]',
    type: 'MemberExpression'
    object:
      type: 'MemberExpression'
      object:
        type: 'Identifier'
        name: 'a'
      property:
        type: 'Identifier'
        name: 'b'
      computed: yes
      optional: no
      shorthand: no
    property:
      type: 'NumericLiteral'
      value: 3
    computed: yes
    optional: no
    shorthand: no

test "AST as expected for Range node", ->
  testExpression '[x..y]',
    type: 'Range'
    exclusive: no
    from:
      name: 'x'
    to:
      name: 'y'

  testExpression '[4...2]',
    type: 'Range'
    exclusive: yes
    from:
      value: 4
    to:
      value: 2

  # testExpression 'for x in [42...43] then',
  #   range: yes
  #   source:
  #     type: 'Range'
  #     exclusive: yes
  #     equals: ''
  #     from:
  #       value: '42'
  #     to:
  #       value: '43'

  # testExpression 'for x in [y..z] then',
  #   range: yes
  #   source:
  #     type: 'Range'
  #     exclusive: no
  #     equals: '='
  #     from:
  #       value: 'y'
  #     to:
  #       value: 'z'

test "AST as expected for Slice node", ->
  testExpression 'x[..y]',
    property:
      type: 'Range'
      exclusive: no
      from: null
      to:
        name: 'y'

  testExpression 'x[y...]',
    property:
      type: 'Range'
      exclusive: yes
      from:
        name: 'y'
      to: null

  testExpression 'x[...]',
    property:
      type: 'Range'
      exclusive: yes
      from: null
      to: null

  # testExpression '"abc"[...2]',
  #   type: 'MemberExpression'
  #   property:
  #     type: 'Range'
  #     from: null
  #     to:
  #       type: 'NumericLiteral'
  #       value: 2
  #     exclusive: yes
  #   computed: yes
  #   optional: no
  #   shorthand: no

  testExpression 'x[...][a..][b...][..c][...d]',
    type: 'MemberExpression'
    object:
      type: 'MemberExpression'
      object:
        type: 'MemberExpression'
        object:
          type: 'MemberExpression'
          object:
            type: 'MemberExpression'
            property:
              type: 'Range'
              from: null
              to: null
              exclusive: yes
          property:
            type: 'Range'
            from:
              name: 'a'
            to: null
            exclusive: no
        property:
          type: 'Range'
          from:
            name: 'b'
          to: null
          exclusive: yes
      property:
        type: 'Range'
        from: null
        to:
          name: 'c'
        exclusive: no
    property:
      type: 'Range'
      from: null
      to:
        name: 'd'
      exclusive: yes

test "AST as expected for Obj node", ->
  testExpression "{a: 1, b, [c], @d, [e()]: f, 'g': 2, ...h, i...}",
    type: 'ObjectExpression'
    properties: [
      type: 'ObjectProperty'
      key:
        type: 'Identifier'
        name: 'a'
      value:
        type: 'NumericLiteral'
        value: 1
      computed: no
      shorthand: no
    ,
      type: 'ObjectProperty'
      key:
        type: 'Identifier'
        name: 'b'
      value:
        type: 'Identifier'
        name: 'b'
      computed: no
      shorthand: yes
    ,
      type: 'ObjectProperty'
      key:
        type: 'Identifier'
        name: 'c'
      value:
        type: 'Identifier'
        name: 'c'
      computed: yes
      shorthand: yes
    ,
      type: 'ObjectProperty'
      key:
        type: 'MemberExpression'
        object:
          type: 'ThisExpression'
        property:
          type: 'Identifier'
          name: 'd'
      value:
        type: 'MemberExpression'
        object:
          type: 'ThisExpression'
        property:
          type: 'Identifier'
          name: 'd'
      computed: no
      shorthand: yes
    ,
      type: 'ObjectProperty'
      key:
        type: 'CallExpression'
        callee:
          type: 'Identifier'
          name: 'e'
        arguments: []
      value:
        type: 'Identifier'
        name: 'f'
      computed: yes
      shorthand: no
    ,
      type: 'ObjectProperty'
      key:
        type: 'StringLiteral'
        value: 'g'
      value:
        type: 'NumericLiteral'
        value: 2
      computed: no
      shorthand: no
    ,
      type: 'SpreadElement'
      argument:
        type: 'Identifier'
        name: 'h'
      postfix: no
    ,
      type: 'SpreadElement'
      argument:
        type: 'Identifier'
        name: 'i'
      postfix: yes
    ]
    implicit: no

  testExpression 'a: 1',
    type: 'ObjectExpression'
    properties: [
      type: 'ObjectProperty'
      key:
        type: 'Identifier'
        name: 'a'
      value:
        type: 'NumericLiteral'
        value: 1
      shorthand: no
      computed: no
    ]
    implicit: yes

#   # TODO: Test destructuring.

#   # console.log JSON.stringify expression, ["type", "generated", "lhs", "value", "properties", "variable"], 2

test "AST as expected for Arr node", ->
  testExpression '[]',
    type: 'ArrayExpression'
    elements: []

  testExpression '[3, tables, !1]',
    type: 'ArrayExpression'
    elements: [
      {value: 3}
      {name: 'tables'}
      {operator: '!'}
    ]

#   # TODO: Test destructuring.

# test "AST as expected for Class node", ->
#   testExpression 'class Klass',
#     type: 'Class'
#     variable:
#       value: 'Klass'
#     body:
#       type: 'Block'
#       expressions: []

#   testExpression 'class child extends parent',
#     type: 'Class'
#     variable:
#       value: 'child'
#     parent:
#       value: 'parent'
#     body:
#       type: 'Block'
#       expressions: []

#   testExpression 'class Klass then constructor: ->',
#     type: 'Class'
#     variable:
#       value: 'Klass'
#     parent: undefined
#     body:
#       type: 'Value'
#       properties: []
#       base:
#         type: 'Obj'
#         generated: yes
#         properties: [
#           variable:
#             value: 'constructor'
#           value:
#             type: 'Code'
#         ]

# test "AST as expected for ExecutableClassBody node", ->
#   code = """
#     class Klass
#       privateStatic = if 42 then yes else no
#       getPrivateStatic: -> privateStatic
#     """
#   testExpression code,
#     type: 'Class'
#     variable:
#       value: 'Klass'
#     body:
#       type: 'Block'
#       expressions: [
#         type: 'Assign'
#         variable:
#           value: 'privateStatic'
#         value:
#           type: 'If'
#       ,
#         type: 'Obj'
#         generated: yes
#         properties: [
#           type: 'Assign'
#           variable:
#             value: 'getPrivateStatic'
#           value:
#             type: 'Code'
#             body:
#               type: 'Value'
#               properties: []
#         ]
#       ]

test "AST as expected for ModuleDeclaration node", ->
  testExpression 'export {X}',
    type: 'ExportNamedDeclaration'
    declaration: null
    specifiers: [
      type: 'ExportSpecifier'
      local:
        type: 'Identifier'
        name: 'X'
      exported:
        type: 'Identifier'
        name: 'X'
    ]
    source: null
    exportKind: 'value'

  testExpression 'import X from "."',
    type: 'ImportDeclaration'
    specifiers: [
      type: 'ImportDefaultSpecifier'
      local:
        type: 'Identifier'
        name: 'X'
    ]
    importKind: 'value'
    source:
      type: 'StringLiteral'
      value: '.'

test "AST as expected for ImportDeclaration node", ->
  testExpression 'import React, {Component} from "react"',
    type: 'ImportDeclaration'
    specifiers: [
      type: 'ImportDefaultSpecifier'
      local:
        type: 'Identifier'
        name: 'React'
    ,
      type: 'ImportSpecifier'
      imported:
        type: 'Identifier'
        name: 'Component'
      importKind: null
      local:
        type: 'Identifier'
        name: 'Component'
    ]
    importKind: 'value'
    source:
      type: 'StringLiteral'
      value: 'react'
      extra:
        raw: '"react"'

test "AST as expected for ExportNamedDeclaration node", ->
  testExpression 'export {}',
    type: 'ExportNamedDeclaration'
    declaration: null
    specifiers: []
    source: null
    exportKind: 'value'

  # testExpression 'export fn = ->',
  #   type: 'ExportNamedDeclaration'
  #   clause:
  #     type: 'Assign'
  #     variable:
  #       value: 'fn'
  #     value:
  #       type: 'Code'

  # testExpression 'export class A',

  testExpression 'export {x as y, z as default}',
    type: 'ExportNamedDeclaration'
    declaration: null
    specifiers: [
      type: 'ExportSpecifier'
      local:
        type: 'Identifier'
        name: 'x'
      exported:
        type: 'Identifier'
        name: 'y'
    ,
      type: 'ExportSpecifier'
      local:
        type: 'Identifier'
        name: 'z'
      exported:
        type: 'Identifier'
        name: 'default'
    ]
    source: null
    exportKind: 'value'

  testExpression 'export {default, default as b} from "./abc"',
    type: 'ExportNamedDeclaration'
    declaration: null
    specifiers: [
      type: 'ExportSpecifier'
      local:
        type: 'Identifier'
        name: 'default'
      exported:
        type: 'Identifier'
        name: 'default'
    ,
      type: 'ExportSpecifier'
      local:
        type: 'Identifier'
        name: 'default'
      exported:
        type: 'Identifier'
        name: 'b'
    ]
    source:
      type: 'StringLiteral'
      value: './abc'
      extra:
        raw: '"./abc"'
    exportKind: 'value'

test "AST as expected for ExportDefaultDeclaration node", ->
  # testExpression 'export default class',
  #   type: 'ExportDefaultDeclaration'
  #   clause:
  #     type: 'Class'

  testExpression 'export default "abc"',
    type: 'ExportDefaultDeclaration'
    declaration:
      type: 'StringLiteral'
      value: 'abc'
      extra:
        raw: '"abc"'

test "AST as expected for ExportAllDeclaration node", ->
  testExpression 'export * from "module-name"',
    type: 'ExportAllDeclaration'
    source:
      type: 'StringLiteral'
      value: 'module-name'
      extra:
        raw: '"module-name"'
    exportKind: 'value'

test "AST as expected for ExportSpecifierList node", ->
  testExpression 'export {a, b, c}',
    type: 'ExportNamedDeclaration'
    declaration: null
    specifiers: [
      type: 'ExportSpecifier'
      local:
        type: 'Identifier'
        name: 'a'
      exported:
        type: 'Identifier'
        name: 'a'
    ,
      type: 'ExportSpecifier'
      local:
        type: 'Identifier'
        name: 'b'
      exported:
        type: 'Identifier'
        name: 'b'
    ,
      type: 'ExportSpecifier'
      local:
        type: 'Identifier'
        name: 'c'
      exported:
        type: 'Identifier'
        name: 'c'
    ]

test "AST as expected for ImportDefaultSpecifier node", ->
  testExpression 'import React from "react"',
    type: 'ImportDeclaration'
    specifiers: [
      type: 'ImportDefaultSpecifier'
      local:
        type: 'Identifier'
        name: 'React'
    ]
    importKind: 'value'
    source:
      type: 'StringLiteral'
      value: 'react'

test "AST as expected for ImportNamespaceSpecifier node", ->
  testExpression 'import * as React from "react"',
    type: 'ImportDeclaration'
    specifiers: [
      type: 'ImportNamespaceSpecifier'
      local:
        type: 'Identifier'
        name: 'React'
    ]
    importKind: 'value'
    source:
      type: 'StringLiteral'
      value: 'react'

  testExpression 'import React, * as ReactStar from "react"',
    type: 'ImportDeclaration'
    specifiers: [
      type: 'ImportDefaultSpecifier'
      local:
        type: 'Identifier'
        name: 'React'
    ,
      type: 'ImportNamespaceSpecifier'
      local:
        type: 'Identifier'
        name: 'ReactStar'
    ]
    importKind: 'value'
    source:
      type: 'StringLiteral'
      value: 'react'

test "AST as expected for Assign node", ->
  testExpression 'a = b',
    type: 'AssignmentExpression'
    left:
      type: 'Identifier'
      name: 'a'
    right:
      type: 'Identifier'
      name: 'b'
    operator: '='

  testExpression 'a += b',
    type: 'AssignmentExpression'
    left:
      type: 'Identifier'
      name: 'a'
    right:
      type: 'Identifier'
      name: 'b'
    operator: '+='

  testExpression '[@a = 2, {b: {c = 3} = {}, d...}, ...e] = f',
    type: 'AssignmentExpression'
    left:
      type: 'ArrayPattern'
      elements: [
        type: 'AssignmentPattern'
        left:
          type: 'MemberExpression'
          object:
            type: 'ThisExpression'
          property:
            name: 'a'
        right:
          type: 'NumericLiteral'
      ,
        type: 'ObjectPattern'
        properties: [
          type: 'ObjectProperty'
          key:
            name: 'b'
          value:
            type: 'AssignmentPattern'
            left:
              type: 'ObjectPattern'
              properties: [
                type: 'ObjectProperty'
                key:
                  name: 'c'
                value:
                  type: 'AssignmentPattern'
                  left:
                    name: 'c'
                  right:
                    value: 3
                shorthand: yes
              ]
            right:
              type: 'ObjectExpression'
              properties: []
        ,
          type: 'RestElement'
          postfix: yes
        ]
      ,
        type: 'RestElement'
        postfix: no
      ]
    right:
      name: 'f'

  testExpression '{a: [...b]} = c',
    type: 'AssignmentExpression'
    left:
      type: 'ObjectPattern'
      properties: [
        type: 'ObjectProperty'
        key:
          name: 'a'
        value:
          type: 'ArrayPattern'
          elements: [
            type: 'RestElement'
          ]
      ]
    right:
      name: 'c'

# # `FuncGlyph` node isn't exported.

# test "AST as expected for Code node", ->
#   testExpression '=>',
#     type: 'Code'
#     bound: yes
#     body:
#       type: 'Block'

#   testExpression '-> await 3',
#     type: 'Code'
#     bound: no
#     isAsync: yes
#     isMethod: no      # TODO: What's this flag?
#     body:
#       type: 'Op'
#       operator: 'await'
#       first:
#         type: 'NumberLiteral'
#         value: '3'

#   testExpression '-> yield 4',
#     type: 'Code'
#     isGenerator: yes
#     body:
#       type: 'Op'
#       operator: 'yield'
#       first:
#         type: 'NumberLiteral'
#         value: '4'

# test "AST as expected for Param node", ->
#   testExpression '(a = 1) ->',
#     params: [
#       type: 'Param'
#       name:
#         value: 'a'
#       value:
#         value: '1'
#     ]

test "AST as expected for Splat node", ->
  testExpression '[a...]',
    type: 'ArrayExpression'
    elements: [
      type: 'SpreadElement'
      argument:
        type: 'Identifier'
        name: 'a'
      postfix: yes
    ]

  testExpression '[b, ...c]',
    type: 'ArrayExpression'
    elements: [
      name: 'b'
    ,
      type: 'SpreadElement'
      argument:
        type: 'Identifier'
        name: 'c'
      postfix: no
    ]

  # testExpression '(a...) ->',
  #   params: [
  #     type: 'Param'
  #     splat: yes
  #     name:
  #       value: 'a'
  #   ]

#   # TODO: Test object splats.

test "AST as expected for Expansion node", ->
  # testExpression '(...) ->',
  #   type: 'Code'
  #   params: [
  #     {type: 'Expansion'}
  #   ]

  testExpression '[..., b] = c',
    type: 'AssignmentExpression'
    left:
      type: 'ArrayPattern'
      elements: [
        type: 'RestElement'
        argument: null
      ,
        type: 'Identifier'
      ]

test "AST as expected for Elision node", ->
  testExpression '[,,,a,,,b]',
    type: 'ArrayExpression'
    elements: [
      null, null, null
      name: 'a'
      null, null
      name: 'b'
    ]

  testExpression '[,,,a,,,b] = "asdfqwer"',
    type: 'AssignmentExpression'
    left:
      type: 'ArrayPattern'
      elements: [
        null, null, null
      ,
        type: 'Identifier'
        name: 'a'
      ,
        null, null
      ,
        type: 'Identifier'
        name: 'b'
      ]
    right:
      type: 'StringLiteral'
      value: 'asdfqwer'

# test "AST as expected for While node", ->
#   testExpression 'loop 1',
#     type: 'While'
#     condition:
#       type: 'BooleanLiteral'
#       value: 'true'
#       originalValue: 'true'   # TODO: This should probably be changed for Prettier.
#     body:
#       type: 'Value'

#   testExpression 'while 1 < 2 then',
#     type: 'While'
#     condition:
#       type: 'Op'
#     body:
#       type: 'Block'

test "AST as expected for Op node", ->
  testExpression 'a <= 2',
    type: 'BinaryExpression'
    operator: '<='
    left:
      type: 'Identifier'
      name: 'a'
    right:
      type: 'NumericLiteral'
      value: 2

  testExpression 'a is 2',
    type: 'BinaryExpression'
    operator: 'is'
    left:
      type: 'Identifier'
      name: 'a'
    right:
      type: 'NumericLiteral'
      value: 2

  testExpression 'a // 2',
    type: 'BinaryExpression'
    operator: '//'
    left:
      type: 'Identifier'
      name: 'a'
    right:
      type: 'NumericLiteral'
      value: 2

  testExpression 'a << 2',
    type: 'BinaryExpression'
    operator: '<<'
    left:
      type: 'Identifier'
      name: 'a'
    right:
      type: 'NumericLiteral'
      value: 2

  testExpression 'typeof x',
    type: 'UnaryExpression'
    operator: 'typeof'
    prefix: yes
    argument:
      type: 'Identifier'
      name: 'x'

  testExpression 'delete x.y',
    type: 'UnaryExpression'
    operator: 'delete'
    prefix: yes
    argument:
      type: 'MemberExpression'

  testExpression 'do x',
    type: 'UnaryExpression'
    operator: 'do'
    prefix: yes
    argument:
      type: 'Identifier'
      name: 'x'

  # testExpression 'do ->',
  #   type: 'UnaryExpression'
  #   operator: 'do'
  #   prefix: yes
  #   argument:
  #     type: 'FunctionExpression'

  testExpression '!x',
    type: 'UnaryExpression'
    operator: '!'
    prefix: yes
    argument:
      type: 'Identifier'
      name: 'x'

  testExpression 'not x',
    type: 'UnaryExpression'
    operator: 'not'
    prefix: yes
    argument:
      type: 'Identifier'
      name: 'x'

  testExpression '--x',
    type: 'UpdateExpression'
    operator: '--'
    prefix: yes
    argument:
      type: 'Identifier'
      name: 'x'

  testExpression 'x++',
    type: 'UpdateExpression'
    operator: '++'
    prefix: no
    argument:
      type: 'Identifier'
      name: 'x'

  testExpression 'x && y',
    type: 'LogicalExpression'
    operator: '&&'
    left:
      type: 'Identifier'
      name: 'x'
    right:
      type: 'Identifier'
      name: 'y'

  testExpression 'x or y',
    type: 'LogicalExpression'
    operator: 'or'
    left:
      type: 'Identifier'
      name: 'x'
    right:
      type: 'Identifier'
      name: 'y'

  testExpression 'x ? y',
    type: 'LogicalExpression'
    operator: '?'
    left:
      type: 'Identifier'
      name: 'x'
    right:
      type: 'Identifier'
      name: 'y'

  testExpression 'x in y',
    type: 'BinaryExpression'
    operator: 'in'
    left:
      type: 'Identifier'
      name: 'x'
    right:
      type: 'Identifier'
      name: 'y'

  testExpression 'x not in y',
    type: 'BinaryExpression'
    operator: 'not in'
    left:
      type: 'Identifier'
      name: 'x'
    right:
      type: 'Identifier'
      name: 'y'

  testExpression 'x + y * z',
    type: 'BinaryExpression'
    operator: '+'
    left:
      type: 'Identifier'
      name: 'x'
    right:
      type: 'BinaryExpression'
      operator: '*'
      left:
        type: 'Identifier'
        name: 'y'
      right:
        type: 'Identifier'
        name: 'z'

  testExpression '(x + y) * z',
    type: 'BinaryExpression'
    operator: '*'
    left:
      type: 'BinaryExpression'
      operator: '+'
      left:
        type: 'Identifier'
        name: 'x'
      right:
        type: 'Identifier'
        name: 'y'
    right:
      type: 'Identifier'
      name: 'z'

  # testExpression '-> await 2',
  #   type: 'Code'
  #   isAsync: yes
  #   body:
  #     type: 'Op'
  #     operator: 'await'
  #     originalOperator: 'await'
  #     first:
  #       type: 'NumberLiteral'
  #       value: '2'

  # testExpression '-> yield 2',
  #   type: 'Code'
  #   isGenerator: yes
  #   body:
  #     type: 'Op'
  #     operator: 'yield'
  #     originalOperator: 'yield'
  #     first:
  #       type: 'NumberLiteral'
  #       value: '2'

# test "AST as expected for Try node", ->
#   testExpression 'try cappuccino',
#     type: 'Try'
#     attempt:
#       type: 'Value'
#     recovery: undefined

#   testExpression 'try to catch it then log it',
#     type: 'Try'
#     attempt:
#       type: 'Value'
#     recovery:
#       type: 'Value'
#       base:
#         type: 'Call'

test "AST as expected for Throw node", ->
  testExpression 'throw new BallError "catch"',
    type: 'ThrowStatement'
    argument:
      type: 'NewExpression'

test "AST as expected for Existence node", ->
  testExpression 'Ghosts?',
    type: 'UnaryExpression',
    argument:
      name: 'Ghosts'
    operator: '?'
    prefix: no

#   # NOTE: Soaking is covered in `Call` and `Access` nodes.

test "AST as expected for Parens node", ->
  testExpression '(hmmmmm)',
    type: 'Identifier'
    name: 'hmmmmm'

#   testExpression '(a + b) / c',
#     type: 'Op'
#     operator: '/'
#     first:
#       type: 'Parens'
#       body:
#         type: 'Op'
#         operator: '+'

  testExpression '(((1)))',
    type: 'NumericLiteral'
    value: 1

# test "AST as expected for StringWithInterpolations node", ->
#   testExpression '"#{o}/"',
#     type: 'StringWithInterpolations'
#     quote: '"'
#     body:
#       type: 'Block'
#       expressions: [
#         originalValue: ''
#       ,
#         type: 'Interpolation'
#         expression:
#           type: 'Value'
#           base:
#             value: 'o'
#       ,
#         originalValue: '/'
#       ]

# test "AST as expected for For node", ->
#   testExpression 'for x, i in arr when x? then return',
#     type: 'For'
#     from: undefined
#     object: undefined
#     range: no
#     pattern: no
#     returns: no
#     guard:
#       type: 'Existence'
#     source:
#       type: 'IdentifierLiteral'
#     body:
#       type: 'Return'

#   testExpression 'for k, v of obj then return',
#     type: 'For'
#     from: undefined
#     object: yes
#     range: no
#     pattern: no
#     returns: no
#     guard: undefined
#     source:
#       type: 'IdentifierLiteral'

#   testExpression 'for x from iterable then',
#     type: 'For'
#     from: yes
#     object: undefined
#     body:
#       type: 'Block'
#     source:
#       type: 'IdentifierLiteral'

#   testExpression 'for i in [0...42] by step when not i % 2 then',
#     type: 'For'
#     from: undefined
#     object: undefined
#     range: yes
#     pattern: no
#     returns: no
#     body:
#       type: 'Block'
#     source:
#       type: 'Range'
#     guard:
#       type: 'Op'
#     step:
#       type: 'IdentifierLiteral'

#   testExpression 'a = (x for x in y)',
#     type: 'Assign'
#     value:
#       type: 'Parens'
#       body:
#         type: 'For'
#         returns: no
#         pattern: no

#   # TODO: Figure out the purpose of `pattern` and `returns`.

# test "AST as expected for Switch node", ->
#   testExpression 'switch x \n when a then a; when b, c then c else 42',
#     type: 'Switch'
#     subject:
#       type: 'IdentifierLiteral'
#       value: 'x'
#     cases: [
#       {
#         type: 'IdentifierLiteral'
#         value: 'a'
#       }
#       {
#         type: 'Value'
#         base:
#           value: 'a'
#       }
#       {
#         type: 'IdentifierLiteral'
#         value: 'b'
#       }
#       {
#         type: 'IdentifierLiteral'
#         value: 'c'
#       }
#       {
#         type: 'Value'
#         base:
#           value: 'c'
#       }
#     ]
#     otherwise:
#       type: 'Value'
#       base:
#         value: '42'
#       isDefaultValue: no

#   # TODO: File issue for compile error when using `then` or `;` where `\n` is rn.

# test "AST as expected for If node", ->
#   testExpression 'if maybe then yes',
#     type: 'If'
#     isChain: no
#     condition:
#       type: 'IdentifierLiteral'
#     body:
#       type: 'Value'
#       base:
#         type: 'BooleanLiteral'

#   testExpression 'yes if maybe',
#     type: 'If'
#     isChain: no
#     condition:
#       type: 'IdentifierLiteral'
#     body:
#       type: 'Value'
#       base:
#         type: 'BooleanLiteral'

#   # TODO: Where's the post-if flag?

#   testExpression 'unless x then x else if y then y else z',
#     type: 'If'
#     isChain: yes
#     condition:
#       type: 'Op'
#       operator: '!'
#       originalOperator: '!'
#       flip: no
#     body:
#       type: 'Value'
#     elseBody:
#       type: 'If'
#       isChain: no
#       condition:
#         type: 'IdentifierLiteral'
#       body:
#         type: 'Value'
#       elseBody:
#         type: 'Value'
#         isDefaultValue: no

#   # TODO: AST generator should preserve use of `unless`.
