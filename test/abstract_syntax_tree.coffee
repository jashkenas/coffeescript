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

testAgainstExpected = (ast, expected) ->
  if expected?
    deepStrictIncludeExpectedProperties ast, expected
  else
    # Convenience for creating new tests; call `testExpression` with no second
    # parameter to see what the current AST generation is for your input code.
    console.log inspect ast

testExpression = (code, expected) ->
  ast = getAstExpression code
  testAgainstExpected ast, expected

testStatement = (code, expected) ->
  ast = getAstStatement code
  testAgainstExpected ast, expected

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

# Shorthand helpers for common AST patterns.

EMPTY_BLOCK =
  type: 'BlockStatement'
  body: []
  directives: []

ID = (name) -> {
  type: 'Identifier'
  name
}

NUMBER = (value) -> {
  type: 'NumericLiteral'
  value
}

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
  testExpression '[fn]: ->',
    type: 'ObjectExpression'
    properties: [
      type: 'ObjectProperty'
      key:
        type: 'Identifier'
        name: 'fn'
      value:
        type: 'FunctionExpression'
      computed: yes
      shorthand: no
      method: no
    ]
    implicit: yes

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
  testStatement 'break',
    type: 'BreakStatement'

  testStatement 'continue',
    type: 'ContinueStatement'

  testStatement 'debugger',
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

test "AST as expected for Return node", ->
  testStatement 'return no',
    type: 'ReturnStatement'
    argument:
      type: 'BooleanLiteral'

  testExpression '''
    (a, b) ->
      return a + b
  ''',
    type: 'FunctionExpression'
    body:
      type: 'BlockStatement'
      body: [
        type: 'ReturnStatement'
        argument:
          type: 'BinaryExpression'
      ]

  testExpression '-> return',
    type: 'FunctionExpression'
    body:
      type: 'BlockStatement'
      body: [
        type: 'ReturnStatement'
        argument: null
      ]

test "AST as expected for YieldReturn node", ->
  testExpression '-> yield return 1',
    type: 'FunctionExpression'
    body:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression:
          type: 'YieldExpression'
          argument:
            type: 'ReturnStatement'
            argument: NUMBER 1
          delegate: no
      ]

test "AST as expected for AwaitReturn node", ->
  testExpression '-> await return 2',
    type: 'FunctionExpression'
    body:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression:
          type: 'AwaitExpression'
          argument:
            type: 'ReturnStatement'
            argument: NUMBER 2
      ]

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
  testStatement 'export {X}',
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

  testStatement 'import X from "."',
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
  testStatement 'import React, {Component} from "react"',
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
  testStatement 'export {}',
    type: 'ExportNamedDeclaration'
    declaration: null
    specifiers: []
    source: null
    exportKind: 'value'

  testStatement 'export fn = ->',
    type: 'ExportNamedDeclaration'
    declaration:
      type: 'AssignmentExpression'
      left:
        type: 'Identifier'
      right:
        type: 'FunctionExpression'
    specifiers: []
    source: null
    exportKind: 'value'

  # testStatement 'export class A',

  testStatement 'export {x as y, z as default}',
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

  testStatement 'export {default, default as b} from "./abc"',
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
  # testStatement 'export default class',
  #   type: 'ExportDefaultDeclaration'
  #   clause:
  #     type: 'Class'

  testStatement 'export default "abc"',
    type: 'ExportDefaultDeclaration'
    declaration:
      type: 'StringLiteral'
      value: 'abc'
      extra:
        raw: '"abc"'

test "AST as expected for ExportAllDeclaration node", ->
  testStatement 'export * from "module-name"',
    type: 'ExportAllDeclaration'
    source:
      type: 'StringLiteral'
      value: 'module-name'
      extra:
        raw: '"module-name"'
    exportKind: 'value'

test "AST as expected for ExportSpecifierList node", ->
  testStatement 'export {a, b, c}',
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
  testStatement 'import React from "react"',
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
  testStatement 'import * as React from "react"',
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

  testStatement 'import React, * as ReactStar from "react"',
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

test "AST as expected for Code node", ->
  testExpression '=>',
    type: 'ArrowFunctionExpression'
    params: []
    body: EMPTY_BLOCK
    generator: no
    async: no
    id: null

  testExpression '''
    (a, b = 1) ->
      c
      d()
  ''',
    type: 'FunctionExpression'
    params: [
      type: 'Identifier'
      name: 'a'
    ,
      type: 'AssignmentPattern'
      left:
        type: 'Identifier'
        name: 'b'
      right:
        type: 'NumericLiteral'
        value: 1
    ]
    body:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression:
          type: 'Identifier'
          name: 'c'
      ,
        type: 'ExpressionStatement'
        expression:
          type: 'CallExpression'
      ]
      directives: []
    generator: no
    async: no
    id: null

  testExpression '({a}) ->',
    type: 'FunctionExpression'
    params: [
      type: 'ObjectPattern'
      properties: [
        type: 'ObjectProperty'
        key: ID('a')
        value: ID('a')
        shorthand: yes
      ]
    ]
    body: EMPTY_BLOCK
    generator: no
    async: no
    id: null

  testExpression '([a]) ->',
    type: 'FunctionExpression'
    params: [
      type: 'ArrayPattern'
      elements: [
        ID('a')
      ]
    ]
    body: EMPTY_BLOCK
    generator: no
    async: no
    id: null

  testExpression '({a = 1} = {}) ->',
    type: 'FunctionExpression'
    params: [
      type: 'AssignmentPattern'
      left:
        type: 'ObjectPattern'
        properties: [
          type: 'ObjectProperty'
          key: ID('a')
          value:
            type: 'AssignmentPattern'
            left: ID('a')
            right: NUMBER(1)
          shorthand: yes
        ]
      right:
        type: 'ObjectExpression'
        properties: []
    ]
    body: EMPTY_BLOCK
    generator: no
    async: no
    id: null

  testExpression '([a = 1] = []) ->',
    type: 'FunctionExpression'
    params: [
      type: 'AssignmentPattern'
      left:
        type: 'ArrayPattern'
        elements: [
          type: 'AssignmentPattern'
          left: ID('a')
          right: NUMBER(1)
        ]
      right:
        type: 'ArrayExpression'
        elements: []
    ]
    body: EMPTY_BLOCK
    generator: no
    async: no
    id: null

  testExpression '() ->',
    type: 'FunctionExpression'
    params: []
    body: EMPTY_BLOCK
    generator: no
    async: no
    id: null

  testExpression '(@a) ->',
    type: 'FunctionExpression'
    params: [
      type: 'MemberExpression'
      object:
        type: 'ThisExpression'
        shorthand: yes
      property: ID 'a'
    ]
    body: EMPTY_BLOCK
    generator: no
    async: no
    id: null

  testExpression '(@a = 1) ->',
    type: 'FunctionExpression'
    params: [
      type: 'AssignmentPattern'
      left:
        type: 'MemberExpression'
      right: NUMBER 1
    ]
    body: EMPTY_BLOCK
    generator: no
    async: no
    id: null

  testExpression '({@a}) ->',
    type: 'FunctionExpression'
    params: [
      type: 'ObjectPattern'
      properties: [
        type: 'ObjectProperty'
        key:
          type: 'MemberExpression'
        value:
          type: 'MemberExpression'
        shorthand: yes
        computed: no
      ]
    ]
    body: EMPTY_BLOCK
    generator: no
    async: no
    id: null

  testExpression '({[a]}) ->',
    type: 'FunctionExpression'
    params: [
      type: 'ObjectPattern'
      properties: [
        type: 'ObjectProperty'
        key:   ID 'a'
        value: ID 'a'
        shorthand: yes
        computed: yes
      ]
    ]
    body: EMPTY_BLOCK
    generator: no
    async: no
    id: null

  testExpression '(...a) ->',
    type: 'FunctionExpression'
    params: [
      type: 'RestElement'
      argument: ID 'a'
      postfix: no
    ]
    body: EMPTY_BLOCK
    generator: no
    async: no
    id: null

  testExpression '(a...) ->',
    type: 'FunctionExpression'
    params: [
      type: 'RestElement'
      argument: ID 'a'
      postfix: yes
    ]
    body: EMPTY_BLOCK
    generator: no
    async: no
    id: null

  testExpression '(..., a) ->',
    type: 'FunctionExpression'
    params: [
      type: 'RestElement'
      argument: null
    ,
      ID 'a'
    ]
    body: EMPTY_BLOCK
    generator: no
    async: no
    id: null

  testExpression '-> a',
    type: 'FunctionExpression'
    params: []
    body:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression: ID 'a'
      ]
    generator: no
    async: no
    id: null

  testExpression '-> await 3',
    type: 'FunctionExpression'
    params: []
    body:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression:
          type: 'AwaitExpression'
          argument: NUMBER 3
      ]
    generator: no
    async: yes
    id: null

  testExpression '-> yield 4',
    type: 'FunctionExpression'
    params: []
    body:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression:
          type: 'YieldExpression'
          argument: NUMBER 4
          delegate: no
      ]
    generator: yes
    async: no
    id: null

  testExpression '-> yield',
    type: 'FunctionExpression'
    params: []
    body:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression:
          type: 'YieldExpression'
          argument: null
          delegate: no
      ]
    generator: yes
    async: no
    id: null

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

test "AST as expected for While node", ->
  testStatement 'loop 1',
    type: 'WhileStatement'
    test:
      type: 'BooleanLiteral'
      value: true
    body:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression: NUMBER 1
      ]
    guard: null
    inverted: no
    postfix: no
    loop: yes

  testStatement 'while 1 < 2 then',
    type: 'WhileStatement'
    test:
      type: 'BinaryExpression'
    body:
      type: 'BlockStatement'
      body: []
    guard: null
    inverted: no
    postfix: no
    loop: no

  testStatement 'while 1 < 2 then fn()',
    type: 'WhileStatement'
    test:
      type: 'BinaryExpression'
    body:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression:
          type: 'CallExpression'
      ]
    guard: null
    inverted: no
    postfix: no
    loop: no

  testStatement '''
    x() until y
  ''',
    type: 'WhileStatement'
    test: ID 'y'
    body:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression:
          type: 'CallExpression'
      ]
    guard: null
    inverted: yes
    postfix: yes
    loop: no

  testStatement '''
    until x when y
      z++
  ''',
    type: 'WhileStatement'
    test: ID 'x'
    body:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression:
          type: 'UpdateExpression'
      ]
    guard: ID 'y'
    inverted: yes
    postfix: no
    loop: no

  testStatement '''
    x while y when z
  ''',
    type: 'WhileStatement'
    test: ID 'y'
    body:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression: ID 'x'
      ]
    guard: ID 'z'
    inverted: no
    postfix: yes
    loop: no

  testStatement '''
    loop
      a()
      b++
  ''',
    type: 'WhileStatement'
    test:
      type: 'BooleanLiteral'
    body:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression:
          type: 'CallExpression'
      ,
        type: 'ExpressionStatement'
        expression:
          type: 'UpdateExpression'
      ]
    guard: null
    inverted: no
    postfix: no
    loop: yes

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

  testExpression 'do ->',
    type: 'UnaryExpression'
    operator: 'do'
    prefix: yes
    argument:
      type: 'FunctionExpression'

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

test "AST as expected for Try node", ->
  testStatement 'try cappuccino',
    type: 'TryStatement'
    block:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression:
          type: 'Identifier'
          name: 'cappuccino'
      ]
    handler: null
    finalizer: null

  testStatement '''
    try
      x = 1
      y()
    catch e
      d()
    finally
      f + g
  ''',
    type: 'TryStatement'
    block:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression:
          type: 'AssignmentExpression'
      ,
        type: 'ExpressionStatement'
        expression:
          type: 'CallExpression'
      ]
    handler:
      type: 'CatchClause'
      param:
        type: 'Identifier'
        name: 'e'
      body:
        type: 'BlockStatement'
        body: [
          type: 'ExpressionStatement'
          expression:
            type: 'CallExpression'
        ]
    finalizer:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression:
          type: 'BinaryExpression'
      ]

  testStatement '''
    try
    catch
    finally
  ''',
    type: 'TryStatement'
    block:
      type: 'BlockStatement'
      body: []
    handler:
      type: 'CatchClause'
      param: null
      body:
        type: 'BlockStatement'
        body: []
    finalizer:
      type: 'BlockStatement'
      body: []

  testStatement '''
    try
    catch {e}
      f
  ''',
    type: 'TryStatement'
    block:
      type: 'BlockStatement'
      body: []
    handler:
      type: 'CatchClause'
      param:
        type: 'ObjectPattern'
      body:
        type: 'BlockStatement'
        body: [
          type: 'ExpressionStatement'
        ]
    finalizer: null

test "AST as expected for Throw node", ->
  testStatement 'throw new BallError "catch"',
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

test "AST as expected for Switch node", ->
  testStatement '''
    switch x
      when a then a
      when b, c then c
      else 42
  ''',
    type: 'SwitchStatement'
    discriminant:
      type: 'Identifier'
      name: 'x'
    cases: [
      type: 'SwitchCase'
      test:
        type: 'Identifier'
        name: 'a'
      consequent: [
        type: 'ExpressionStatement'
        expression:
          type: 'Identifier'
          name: 'a'
      ]
      trailing: yes
    ,
      type: 'SwitchCase'
      test:
        type: 'Identifier'
        name: 'b'
      consequent: []
      trailing: no
    ,
      type: 'SwitchCase'
      test:
        type: 'Identifier'
        name: 'c'
      consequent: [
        type: 'ExpressionStatement'
        expression:
          type: 'Identifier'
          name: 'c'
      ]
      trailing: yes
    ,
      type: 'SwitchCase'
      test: null
      consequent: [
        type: 'ExpressionStatement'
        expression:
          type: 'NumericLiteral'
          value: 42
      ]
    ]

  testStatement '''
    switch
      when some(condition)
        doSomething()
        andThenSomethingElse
  ''',
    type: 'SwitchStatement'
    discriminant: null
    cases: [
      type: 'SwitchCase'
      test:
        type: 'CallExpression'
      consequent: [
        type: 'ExpressionStatement'
        expression:
          type: 'CallExpression'
      ,
        type: 'ExpressionStatement'
        expression:
          type: 'Identifier'
      ]
      trailing: yes
    ]

  testStatement '''
    switch a
      when 1, 2, 3, 4
        b
      else
        c
        d
  ''',
    type: 'SwitchStatement'
    discriminant:
      type: 'Identifier'
    cases: [
      type: 'SwitchCase'
      test:
        type: 'NumericLiteral'
        value: 1
      consequent: []
      trailing: no
    ,
      type: 'SwitchCase'
      test:
        type: 'NumericLiteral'
        value: 2
      consequent: []
      trailing: no
    ,
      type: 'SwitchCase'
      test:
        type: 'NumericLiteral'
        value: 3
      consequent: []
      trailing: no
    ,
      type: 'SwitchCase'
      test:
        type: 'NumericLiteral'
        value: 4
      consequent: [
        type: 'ExpressionStatement'
        expression:
          type: 'Identifier'
      ]
      trailing: yes
    ,
      type: 'SwitchCase'
      test: null
      consequent: [
        type: 'ExpressionStatement'
        expression:
          type: 'Identifier'
      ,
        type: 'ExpressionStatement'
        expression:
          type: 'Identifier'
      ]
    ]

#   # TODO: File issue for compile error when using `then` or `;` where `\n` is rn.

test "AST as expected for If node", ->
  testStatement 'if maybe then yes',
    type: 'IfStatement'
    test: ID 'maybe'
    consequent:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression:
          type: 'BooleanLiteral'
      ]
    alternate: null
    postfix: no
    inverted: no

  testStatement 'yes if maybe',
    type: 'IfStatement'
    test: ID 'maybe'
    consequent:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression:
          type: 'BooleanLiteral'
      ]
    alternate: null
    postfix: yes
    inverted: no

  testStatement 'unless x then x else if y then y else z',
    type: 'IfStatement'
    test: ID 'x'
    consequent:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression: ID 'x'
      ]
    alternate:
      type: 'IfStatement'
      test: ID 'y'
      consequent:
        type: 'BlockStatement'
        body: [
          type: 'ExpressionStatement'
          expression: ID 'y'
        ]
      alternate:
        type: 'BlockStatement'
        body: [
          type: 'ExpressionStatement'
          expression: ID 'z'
        ]
      postfix: no
      inverted: no
    postfix: no
    inverted: yes

  testStatement '''
    if a
      b
    else
      if c
        d
  ''',
    type: 'IfStatement'
    test: ID 'a'
    consequent:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression: ID 'b'
      ]
    alternate:
      type: 'BlockStatement'
      body: [
        type: 'IfStatement'
        test: ID 'c'
        consequent:
          type: 'BlockStatement'
          body: [
            type: 'ExpressionStatement'
            expression: ID 'd'
          ]
        alternate: null
        postfix: no
        inverted: no
      ]
    postfix: no
    inverted: no

  testExpression '''
    a =
      if b then c else if d then e
  ''',
    type: 'AssignmentExpression'
    right:
      type: 'ConditionalExpression'
      test: ID 'b'
      consequent: ID 'c'
      alternate:
        type: 'ConditionalExpression'
        test: ID 'd'
        consequent: ID 'e'
        alternate: null
        postfix: no
        inverted: no
      postfix: no
      inverted: no

    testExpression '''
      f(
        if b
          c
          d
      )
    ''',
      type: 'CallExpression'
      arguments: [
        type: 'ConditionalExpression'
        test: ID 'b'
        consequent:
          type: 'BlockStatement'
          body: [
            type: 'ExpressionStatement'
            expression:
              ID 'c'
          ,
            type: 'ExpressionStatement'
            expression:
              ID 'd'
          ]
        postfix: no
        inverted: no
      ]

  testStatement 'a unless b',
    type: 'IfStatement'
    test: ID 'b'
    consequent:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression: ID 'a'
      ]
    alternate: null
    postfix: yes
    inverted: yes
