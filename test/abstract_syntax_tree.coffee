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

testComments = (code, expected) ->
  ast = getAstRoot code
  testAgainstExpected ast.comments, expected

test 'Confirm functionality of `deepStrictIncludeExpectedProperties`', ->
  actual =
    name: 'Name'
    a:
      b: 1
      c: 2
    x: [1, 2, 3]

  check = (message, test, expected) ->
    test (-> deepStrictIncludeExpectedProperties actual, expected), null, message

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

ID = (name, additionalProperties = {}) ->
  Object.assign({
    type: 'Identifier'
    name
  }, additionalProperties)

NUMBER = (value) -> {
  type: 'NumericLiteral'
  value
}

STRING = (value) -> {
  type: 'StringLiteral'
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

  deepStrictIncludeExpectedProperties CoffeeScript.compile('# comment', ast: yes),
    type: 'File'
    program:
      type: 'Program'
      body: []
      directives: []
    comments: [
      type: 'CommentLine'
      value: ' comment'
    ]

  deepStrictIncludeExpectedProperties CoffeeScript.compile('', ast: yes),
    type: 'File'
    program:
      type: 'Program'
      body: []
      directives: []

  deepStrictIncludeExpectedProperties CoffeeScript.compile(' ', ast: yes),
    type: 'File'
    program:
      type: 'Program'
      body: []
      directives: []

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

  testExpression '10_000',
    type: 'NumericLiteral'
    value: 10000
    extra:
      rawValue: 10000
      raw: '10_000'

  testExpression '1_2.34_5e6_7',
    type: 'NumericLiteral'
    value: 12.345e67
    extra:
      rawValue: 12.345e67
      raw: '1_2.34_5e6_7'

  testExpression '0o7_7_7',
    type: 'NumericLiteral'
    value: 0o777
    extra:
      rawValue: 0o777
      raw: '0o7_7_7'

  testExpression '42n',
    type: 'BigIntLiteral'
    value: '42'
    extra:
      rawValue: '42'
      raw: '42n'

  testExpression '2e3_08',
    type: 'NumericLiteral'
    value: Infinity
    extra:
      rawValue: Infinity
      raw: '2e3_08'

test "AST as expected for InfinityLiteral node", ->
  testExpression 'Infinity',
    type: 'Identifier'
    name: 'Infinity'

  testExpression '2e308',
    type: 'NumericLiteral'
    value: Infinity
    extra:
      raw: '2e308'
      rawValue: Infinity

test "AST as expected for NaNLiteral node", ->
  testExpression 'NaN',
    type: 'Identifier'
    name: 'NaN'

test "AST as expected for StringLiteral node", ->
  # Just a standalone string literal would be treated as a directive,
  # so embed the string literal in an enclosing expression (e.g. a call).
  testExpression 'a "string cheese"',
    type: 'CallExpression'
    arguments: [
      type: 'StringLiteral'
      value: 'string cheese'
      extra:
        raw: '"string cheese"'
    ]

  testExpression "b 'cheese string'",
    type: 'CallExpression'
    arguments: [
      type: 'StringLiteral'
      value: 'cheese string'
      extra:
        raw: "'cheese string'"
    ]

  testExpression "'''heredoc'''",
    type: 'TemplateLiteral'
    expressions: []
    quasis: [
      type: 'TemplateElement'
      value:
        raw: 'heredoc'
      tail: yes
    ]
    quote: "'''"

test "AST as expected for PassthroughLiteral node", ->
  code = 'const CONSTANT = "unreassignable!"'
  testExpression "`#{code}`",
    type: 'PassthroughLiteral'
    value: code
    here: no

  code = '\nconst CONSTANT = "unreassignable!"\n'
  testExpression "```#{code}```",
    type: 'PassthroughLiteral'
    value: code
    here: yes

  testExpression "``",
    type: 'PassthroughLiteral'
    value: ''
    here: no

  # escaped backticks
  testExpression "`\\`abc\\``",
    type: 'PassthroughLiteral'
    value: '\\`abc\\`'
    here: no

test "AST as expected for IdentifierLiteral node", ->
  testExpression 'id',
    type: 'Identifier'
    name: 'id'

test "AST as expected for JSXTag node", ->
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

  testExpression '<div>abc</div>',
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
    children: [
      type: 'JSXText'
      extra:
        raw: 'abc'
      value: 'abc'
    ]

  testExpression '''
    <a>
      {b}
      <c />
    </a>
  ''',
    type: 'JSXElement'
    openingElement:
      type: 'JSXOpeningElement'
      name:
        type: 'JSXIdentifier'
        name: 'a'
      attributes: []
      selfClosing: no
    closingElement:
      type: 'JSXClosingElement'
      name:
        type: 'JSXIdentifier'
        name: 'a'
    children: [
      type: 'JSXText'
      extra:
        raw: '\n  '
      value: '\n  '
    ,
      type: 'JSXExpressionContainer'
      expression: ID 'b'
    ,
      type: 'JSXText'
      extra:
        raw: '\n  '
      value: '\n  '
    ,
      type: 'JSXElement'
      openingElement:
        type: 'JSXOpeningElement'
        name:
          type: 'JSXIdentifier'
          name: 'c'
        selfClosing: true
      closingElement: null
      children: []
    ,
      type: 'JSXText'
      extra:
        raw: '\n'
      value: '\n'
    ]

  testExpression '<>abc{}</>',
    type: 'JSXFragment'
    openingFragment:
      type: 'JSXOpeningFragment'
    closingFragment:
      type: 'JSXClosingFragment'
    children: [
      type: 'JSXText'
      extra:
        raw: 'abc'
      value: 'abc'
    ,
      type: 'JSXExpressionContainer'
      expression:
        type: 'JSXEmptyExpression'
    ]

  testExpression '''
    <a>{<b />}</a>
  ''',
    type: 'JSXElement'
    openingElement:
      type: 'JSXOpeningElement'
      name:
        type: 'JSXIdentifier'
        name: 'a'
      attributes: []
      selfClosing: no
    closingElement:
      type: 'JSXClosingElement'
      name:
        type: 'JSXIdentifier'
        name: 'a'
    children: [
      type: 'JSXExpressionContainer'
      expression:
        type: 'JSXElement'
        openingElement:
          type: 'JSXOpeningElement'
          name:
            type: 'JSXIdentifier'
            name: 'b'
          selfClosing: true
        closingElement: null
        children: []
    ]

  testExpression '''
    <div>{
      # comment
    }</div>
  ''',
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
    children: [
      type: 'JSXExpressionContainer'
      expression:
        type: 'JSXEmptyExpression'
    ]

  testExpression '''
    <div>{### here ###}</div>
  ''',
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
    children: [
      type: 'JSXExpressionContainer'
      expression:
        type: 'JSXEmptyExpression'
    ]

  testExpression '<div:a b:c />',
    type: 'JSXElement'
    openingElement:
      type: 'JSXOpeningElement'
      name:
        type: 'JSXNamespacedName'
        namespace:
          type: 'JSXIdentifier'
          name: 'div'
        name:
          type: 'JSXIdentifier'
          name: 'a'
      attributes: [
        type: 'JSXAttribute'
        name:
          type: 'JSXNamespacedName'
          namespace:
            type: 'JSXIdentifier'
            name: 'b'
          name:
            type: 'JSXIdentifier'
            name: 'c'
      ]
      selfClosing: yes

  testExpression '''
    <div:a>
      {b}
    </div:a>
  ''',
    type: 'JSXElement'
    openingElement:
      type: 'JSXOpeningElement'
      name:
        type: 'JSXNamespacedName'
        namespace:
          type: 'JSXIdentifier'
          name: 'div'
        name:
          type: 'JSXIdentifier'
          name: 'a'
    closingElement:
      type: 'JSXClosingElement'
      name:
        type: 'JSXNamespacedName'
        namespace:
          type: 'JSXIdentifier'
          name: 'div'
        name:
          type: 'JSXIdentifier'
          name: 'a'

  testExpression '''
    <div b={
      c
      d
    } />
  ''',
    type: 'JSXElement'
    openingElement:
      attributes: [
        value:
          type: 'JSXExpressionContainer'
          expression:
            type: 'BlockStatement'
            body: [
              type: 'ExpressionStatement'
            ,
              type: 'ExpressionStatement'
              expression:
                returns: yes
            ]
      ]

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

  testExpression '@b',
    type: 'MemberExpression'
    object:
      type: 'ThisExpression'
      shorthand: yes
    property: ID 'b'

  testExpression 'this.b',
    type: 'MemberExpression'
    object:
      type: 'ThisExpression'
      shorthand: no
    property: ID 'b'

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

test "AST as expected for Call node", ->
  testExpression 'fn()',
    type: 'CallExpression'
    callee:
      type: 'Identifier'
      name: 'fn'
    arguments: []
    optional: no
    implicit: no
    returns: undefined

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
    type: 'OptionalCallExpression'
    optional: yes
    implicit: no

  testExpression 'maybe?(1 + 1)',
    type: 'OptionalCallExpression'
    arguments: [
      type: 'BinaryExpression'
    ]
    optional: yes
    implicit: no

  testExpression 'maybe? 1 + 1',
    type: 'OptionalCallExpression'
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

  testExpression 'a?().b',
    type: 'OptionalMemberExpression'
    object:
      type: 'OptionalCallExpression'
      optional: yes
    optional: no

  testExpression 'a?.b.c()',
    type: 'OptionalCallExpression'
    callee:
      type: 'OptionalMemberExpression'
      object:
        type: 'OptionalMemberExpression'
        optional: yes
      optional: no
    optional: no

  testExpression 'a?.b?()',
    type: 'OptionalCallExpression'
    callee:
      type: 'OptionalMemberExpression'
      optional: yes
    optional: yes

  testExpression 'a?().b?()',
    type: 'OptionalCallExpression'
    callee:
      type: 'OptionalMemberExpression'
      optional: no
      object:
        type: 'OptionalCallExpression'
        optional: yes
    optional: yes

  testExpression 'a().b?()',
    type: 'OptionalCallExpression'
    callee:
      type: 'MemberExpression'
      optional: no
      object:
        type: 'CallExpression'
        optional: no
    optional: yes

  testExpression 'a?().b()',
    type: 'OptionalCallExpression'
    callee:
      type: 'OptionalMemberExpression'
      optional: no
      object:
        type: 'OptionalCallExpression'
        optional: yes
    optional: no

test "AST as expected for SuperCall node", ->
  testStatement 'class child extends parent then constructor: -> super()',
    type: 'ClassDeclaration'
    body:
      type: 'ClassBody'
      body: [
        body:
          type: 'BlockStatement'
          body: [
            type: 'ExpressionStatement'
            expression:
              type: 'CallExpression'
              callee:
                type: 'Super'
          ]
      ]

test "AST as expected for Super node", ->
  testStatement 'class child extends parent then func: -> super.prop',
    type: 'ClassDeclaration'
    body:
      type: 'ClassBody'
      body: [
        body:
          type: 'BlockStatement'
          body: [
            type: 'ExpressionStatement'
            expression:
              type: 'MemberExpression'
              object:
                type: 'Super'
              property: ID 'prop'
              computed: no
          ]
      ]

  testStatement '''
    class child extends parent
      func: ->
        super[prop]()
  ''',
    type: 'ClassDeclaration'
    body:
      type: 'ClassBody'
      body: [
        body:
          type: 'BlockStatement'
          body: [
            type: 'ExpressionStatement'
            expression:
              type: 'CallExpression'
              callee:
                type: 'MemberExpression'
                object:
                  type: 'Super'
                property: ID 'prop'
                computed: yes
          ]
      ]

test "AST as expected for RegexWithInterpolations node", ->
  testExpression '///^#{flavor}script$///',
    type: 'InterpolatedRegExpLiteral'
    interpolatedPattern:
      type: 'TemplateLiteral'
      expressions: [
        ID 'flavor'
      ]
      quasis: [
        type: 'TemplateElement'
        value:
          raw: '^'
        tail: no
      ,
        type: 'TemplateElement'
        value:
          raw: 'script$'
        tail: yes
      ]
      quote: '///'
    flags: ''

  testExpression '''
    ///
      a
      #{b}///ig
  ''',
    type: 'InterpolatedRegExpLiteral'
    interpolatedPattern:
      type: 'TemplateLiteral'
      expressions: [
        ID 'b'
      ]
      quasis: [
        type: 'TemplateElement'
        value:
          raw: '\n  a\n  '
        tail: no
      ,
        type: 'TemplateElement'
        value:
          raw: ''
        tail: yes
      ]
      quote: '///'
    flags: 'ig'

  testExpression '''
    ///
      a # first
      #{b} ### second ###
    ///ig
  ''',
    type: 'InterpolatedRegExpLiteral'
    interpolatedPattern:
      type: 'TemplateLiteral'
      expressions: [
        ID 'b'
      ]
      quasis: [
        type: 'TemplateElement'
        value:
          raw: '\n  a # first\n  '
        tail: no
      ,
        type: 'TemplateElement'
        value:
          raw: ' ### second ###\n'
        tail: yes
      ]
      quote: '///'
    flags: 'ig'
    comments: [
      type: 'CommentLine'
      value: ' first'
    ,
      type: 'CommentBlock'
      value: ' second '
    ]

test "AST as expected for TaggedTemplateCall node", ->
  testExpression 'func"tagged"',
    type: 'TaggedTemplateExpression'
    tag: ID 'func'
    quasi:
      type: 'TemplateLiteral'
      expressions: []
      quasis: [
        type: 'TemplateElement'
        value:
          raw: 'tagged'
        tail: yes
      ]

  testExpression 'a"b#{c}"',
    type: 'TaggedTemplateExpression'
    tag: ID 'a'
    quasi:
      type: 'TemplateLiteral'
      expressions: [
        ID 'c'
      ]
      quasis: [
        type: 'TemplateElement'
        value:
          raw: 'b'
        tail: no
      ,
        type: 'TemplateElement'
        value:
          raw: ''
        tail: yes
      ]

  testExpression '''
    a"""
      b#{c}
    """
  ''',
    type: 'TaggedTemplateExpression'
    tag: ID 'a'
    quasi:
      type: 'TemplateLiteral'
      expressions: [
        ID 'c'
      ]
      quasis: [
        type: 'TemplateElement'
        value:
          raw: '\n  b'
        tail: no
      ,
        type: 'TemplateElement'
        value:
          raw: '\n'
        tail: yes
      ]

  testExpression """
    a'''
      b
    '''
  """,
    type: 'TaggedTemplateExpression'
    tag: ID 'a'
    quasi:
      type: 'TemplateLiteral'
      expressions: []
      quasis: [
        type: 'TemplateElement'
        value:
          raw: '\n  b\n'
        tail: yes
      ]

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
    type: 'OptionalMemberExpression'
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
    type: 'OptionalMemberExpression'
    object:
      type: 'OptionalMemberExpression'
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
    type: 'OptionalMemberExpression'
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

  testExpression 'a[if b then c]',
    type: 'MemberExpression'
    object: ID 'a'
    property:
      type: 'ConditionalExpression'
      test: ID 'b'
      consequent: ID 'c'
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

  testExpression '"abc"[...2]',
    type: 'MemberExpression'
    property:
      type: 'Range'
      from: null
      to:
        type: 'NumericLiteral'
        value: 2
      exclusive: yes
    computed: yes
    optional: no
    shorthand: no

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

  testExpression '''
    a:
      if b then c
  ''',
    type: 'ObjectExpression'
    properties: [
      type: 'ObjectProperty'
      key: ID 'a'
      value:
        type: 'ConditionalExpression'
        test: ID 'b'
        consequent: ID 'c'
    ]
    implicit: yes

  testExpression '''
    a:
      c if b
  ''',
    type: 'ObjectExpression'
    properties: [
      type: 'ObjectProperty'
      key: ID 'a'
      value:
        type: 'ConditionalExpression'
        test: ID 'b'
        consequent: ID 'c'
    ]
    implicit: yes

  testExpression '"#{a}": 1',
    type: 'ObjectExpression'
    properties: [
      type: 'ObjectProperty'
      key:
        type: 'TemplateLiteral'
        expressions: [
          ID 'a'
        ]
      value:
        type: 'NumericLiteral'
        value: 1
      shorthand: no
      computed: yes
    ]
    implicit: yes

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

test "AST as expected for Class node", ->
  testStatement 'class Klass',
    type: 'ClassDeclaration'
    id: ID 'Klass', declaration: yes
    superClass: null
    body:
      type: 'ClassBody'
      body: []

  testStatement 'class child extends parent',
    type: 'ClassDeclaration'
    id: ID 'child', declaration: yes
    superClass: ID 'parent', declaration: no
    body:
      type: 'ClassBody'
      body: []

  testStatement 'class Klass then constructor: -> @a = 1',
    type: 'ClassDeclaration'
    id: ID 'Klass', declaration: yes
    superClass: null
    body:
      type: 'ClassBody'
      body: [
        type: 'ClassMethod'
        static: no
        key: ID 'constructor', declaration: no
        computed: no
        kind: 'constructor'
        id: null
        generator: no
        async: no
        params: []
        body:
          type: 'BlockStatement'
          body: [
            type: 'ExpressionStatement'
            expression:
              type: 'AssignmentExpression'
              returns: undefined
          ]
        bound: no
      ]

  testExpression '''
    a = class A
      b: ->
        c
      d: =>
        e
  ''',
    type: 'AssignmentExpression'
    right:
      type: 'ClassExpression'
      id: ID 'A', declaration: yes
      superClass: null
      body:
        type: 'ClassBody'
        body: [
          type: 'ClassMethod'
          static: no
          key: ID 'b'
          computed: no
          kind: 'method'
          id: null
          generator: no
          async: no
          params: []
          body:
            type: 'BlockStatement'
            body: [
              type: 'ExpressionStatement'
              expression: ID 'c', returns: yes
            ]
          operator: ':'
          bound: no
        ,
          type: 'ClassMethod'
          static: no
          key: ID 'd'
          computed: no
          kind: 'method'
          id: null
          generator: no
          async: no
          params: []
          body:
            type: 'BlockStatement'
            body: [
              type: 'ExpressionStatement'
              expression: ID 'e'
            ]
          operator: ':'
          bound: yes
        ]

  testStatement '''
    class A
      @b: ->
      @c = =>
      @d: 1
      @e = 2
      j = 5
      A.f = 3
      A.g = ->
      this.h = ->
      this.i = 4
  ''',
    type: 'ClassDeclaration'
    id: ID 'A', declaration: yes
    superClass: null
    body:
      type: 'ClassBody'
      body: [
        type: 'ClassMethod'
        static: yes
        key: ID 'b'
        computed: no
        kind: 'method'
        id: null
        generator: no
        async: no
        params: []
        body: EMPTY_BLOCK
        operator: ':'
        staticClassName:
          type: 'ThisExpression'
          shorthand: yes
        bound: no
      ,
        type: 'ClassMethod'
        static: yes
        key: ID 'c'
        computed: no
        kind: 'method'
        id: null
        generator: no
        async: no
        params: []
        body: EMPTY_BLOCK
        operator: '='
        staticClassName:
          type: 'ThisExpression'
          shorthand: yes
        bound: yes
      ,
        type: 'ClassProperty'
        static: yes
        key: ID 'd'
        computed: no
        value: NUMBER 1
        operator: ':'
        staticClassName:
          type: 'ThisExpression'
          shorthand: yes
      ,
        type: 'ClassProperty'
        static: yes
        key: ID 'e'
        computed: no
        value: NUMBER 2
        operator: '='
        staticClassName:
          type: 'ThisExpression'
          shorthand: yes
      ,
        type: 'ExpressionStatement'
        expression:
          type: 'AssignmentExpression'
          left: ID 'j', declaration: yes
          right: NUMBER 5
      ,
        type: 'ClassProperty'
        static: yes
        key: ID 'f'
        computed: no
        value: NUMBER 3
        operator: '='
        staticClassName: ID 'A'
      ,
        type: 'ClassMethod'
        static: yes
        key: ID 'g'
        computed: no
        kind: 'method'
        id: null
        generator: no
        async: no
        params: []
        body: EMPTY_BLOCK
        operator: '='
        staticClassName: ID 'A'
        bound: no
      ,
        type: 'ClassMethod'
        static: yes
        key: ID 'h'
        computed: no
        kind: 'method'
        id: null
        generator: no
        async: no
        params: []
        body: EMPTY_BLOCK
        operator: '='
        staticClassName:
          type: 'ThisExpression'
          shorthand: no
        bound: no
      ,
        type: 'ClassProperty'
        static: yes
        key: ID 'i'
        computed: no
        value: NUMBER 4
        operator: '='
        staticClassName:
          type: 'ThisExpression'
          shorthand: no
      ]

  testStatement '''
    class A
      b: 1
      [c]: 2
      [d]: ->
      @[e]: ->
      @[f]: 3
  ''',
    type: 'ClassDeclaration'
    id: ID 'A', declaration: yes
    superClass: null
    body:
      type: 'ClassBody'
      body: [
        type: 'ClassPrototypeProperty'
        key: ID 'b', declaration: no
        value: NUMBER 1
        computed: no
      ,
        type: 'ClassPrototypeProperty'
        key: ID 'c'
        value: NUMBER 2
        computed: yes
      ,
        type: 'ClassMethod'
        static: no
        key: ID 'd'
        computed: yes
        kind: 'method'
        id: null
        generator: no
        async: no
        params: []
        body: EMPTY_BLOCK
        operator: ':'
        bound: no
      ,
        type: 'ClassMethod'
        static: yes
        key: ID 'e'
        computed: yes
        kind: 'method'
        id: null
        generator: no
        async: no
        params: []
        body: EMPTY_BLOCK
        operator: ':'
        bound: no
        staticClassName:
          type: 'ThisExpression'
          shorthand: yes
      ,
        type: 'ClassProperty'
        static: yes
        key: ID 'f'
        computed: yes
        value: NUMBER 3
        operator: ':'
        staticClassName:
          type: 'ThisExpression'
          shorthand: yes
      ]

  testStatement '''
    class A
      @[b] = ->
      "#{c}": ->
      @[d] = 1
      [e]: 2
      "#{f}": 3
      @[g]: 4
  ''',
    type: 'ClassDeclaration'
    body:
      body: [
        type: 'ClassMethod'
        computed: yes
      ,
        type: 'ClassMethod'
        computed: yes
      ,
        type: 'ClassProperty'
        computed: yes
      ,
        type: 'ClassPrototypeProperty'
        computed: yes
      ,
        type: 'ClassPrototypeProperty'
        computed: yes
      ,
        type: 'ClassProperty'
        computed: yes
      ]

  testStatement '''
    class A.b
  ''',
    type: 'ClassDeclaration'
    id:
      type: 'MemberExpression'
      object: ID 'A', declaration: no
      property: ID 'b', declaration: no

  testStatement '''
    class A
      'constructor': ->
  ''',
    type: 'ClassDeclaration'
    body:
      type: 'ClassBody'
      body: [
        type: 'ClassMethod'
        static: no
        key:
          type: 'StringLiteral'
        computed: no
        kind: 'constructor'
        id: null
        generator: no
        async: no
        params: []
        body: EMPTY_BLOCK
        bound: no
      ]


test "AST as expected for ModuleDeclaration node", ->
  testStatement 'export {X}',
    type: 'ExportNamedDeclaration'
    declaration: null
    specifiers: [
      type: 'ExportSpecifier'
      local:
        type: 'Identifier'
        name: 'X'
        declaration: no
      exported:
        type: 'Identifier'
        name: 'X'
        declaration: no
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
        declaration: no
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
        declaration: no
    ,
      type: 'ImportSpecifier'
      imported:
        type: 'Identifier'
        name: 'Component'
        declaration: no
      importKind: null
      local:
        type: 'Identifier'
        name: 'Component'
        declaration: no
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
        declaration: yes
      right:
        type: 'FunctionExpression'
    specifiers: []
    source: null
    exportKind: 'value'

  testStatement 'export class A',
    type: 'ExportNamedDeclaration'
    declaration:
      type: 'ClassDeclaration'
      id: ID 'A', declaration: yes
      superClass: null
      body:
        type: 'ClassBody'
        body: []
    specifiers: []
    source: null
    exportKind: 'value'

  testStatement 'export {x as y, z as default}',
    type: 'ExportNamedDeclaration'
    declaration: null
    specifiers: [
      type: 'ExportSpecifier'
      local:
        type: 'Identifier'
        name: 'x'
        declaration: no
      exported:
        type: 'Identifier'
        name: 'y'
        declaration: no
    ,
      type: 'ExportSpecifier'
      local:
        type: 'Identifier'
        name: 'z'
        declaration: no
      exported:
        type: 'Identifier'
        name: 'default'
        declaration: no
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
        declaration: no
      exported:
        type: 'Identifier'
        name: 'default'
        declaration: no
    ,
      type: 'ExportSpecifier'
      local:
        type: 'Identifier'
        name: 'default'
        declaration: no
      exported:
        type: 'Identifier'
        name: 'b'
        declaration: no
    ]
    source:
      type: 'StringLiteral'
      value: './abc'
      extra:
        raw: '"./abc"'
    exportKind: 'value'

test "AST as expected for ExportDefaultDeclaration node", ->
  testStatement 'export default class',
    type: 'ExportDefaultDeclaration'
    declaration:
      type: 'ClassDeclaration'

  testStatement 'export default "abc"',
    type: 'ExportDefaultDeclaration'
    declaration:
      type: 'StringLiteral'
      value: 'abc'
      extra:
        raw: '"abc"'

  testStatement 'export default a = b',
    type: 'ExportDefaultDeclaration'
    declaration:
      type: 'AssignmentExpression'
      left: ID 'a', declaration: yes
      right: ID 'b', declaration: no

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
        declaration: no
      exported:
        type: 'Identifier'
        name: 'a'
        declaration: no
    ,
      type: 'ExportSpecifier'
      local:
        type: 'Identifier'
        name: 'b'
        declaration: no
      exported:
        type: 'Identifier'
        name: 'b'
        declaration: no
    ,
      type: 'ExportSpecifier'
      local:
        type: 'Identifier'
        name: 'c'
        declaration: no
      exported:
        type: 'Identifier'
        name: 'c'
        declaration: no
    ]

test "AST as expected for ImportDefaultSpecifier node", ->
  testStatement 'import React from "react"',
    type: 'ImportDeclaration'
    specifiers: [
      type: 'ImportDefaultSpecifier'
      local:
        type: 'Identifier'
        name: 'React'
        declaration: no
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
        declaration: no
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
        declaration: no
    ,
      type: 'ImportNamespaceSpecifier'
      local:
        type: 'Identifier'
        name: 'ReactStar'
        declaration: no
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
      declaration: yes
    right:
      type: 'Identifier'
      name: 'b'
      declaration: no
    operator: '='

  testExpression 'a += b',
    type: 'AssignmentExpression'
    left:
      type: 'Identifier'
      name: 'a'
      declaration: no
    right:
      type: 'Identifier'
      name: 'b'
      declaration: no
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
            declaration: no
        right:
          type: 'NumericLiteral'
      ,
        type: 'ObjectPattern'
        properties: [
          type: 'ObjectProperty'
          key:
            name: 'b'
            declaration: no
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
                    declaration: yes
                  right:
                    value: 3
                shorthand: yes
              ]
            right:
              type: 'ObjectExpression'
              properties: []
        ,
          type: 'RestElement'
          argument:
            name: 'd'
            declaration: yes
          postfix: yes
        ]
      ,
        type: 'RestElement'
        argument:
          name: 'e'
          declaration: yes
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
          declaration: no
        value:
          type: 'ArrayPattern'
          elements: [
            type: 'RestElement'
            argument:
              name: 'b'
              declaration: yes
          ]
      ]
    right:
      name: 'c'
      declaration: no

  testExpression '(a = 1; a ?= b)',
    type: 'SequenceExpression'
    expressions: [
      type: 'AssignmentExpression'
    ,
      type: 'AssignmentExpression'
      left:
        type: 'Identifier'
        name: 'a'
        declaration: no
      right:
        type: 'Identifier'
        name: 'b'
        declaration: no
      operator: '?='
    ]

  testExpression '[a..., b] = c',
    type: 'AssignmentExpression'
    left:
      type: 'ArrayPattern'
      elements: [
        type: 'RestElement'
        argument: ID 'a', declaration: yes
        postfix: yes
      ,
        ID 'b'
      ]
    right:
      ID 'c'

  testExpression '[] = c',
    type: 'AssignmentExpression'
    left:
      type: 'ArrayPattern'
      elements: []
    right:
      ID 'c'

  testExpression '{{a...}...} = b',
    type: 'AssignmentExpression'
    left:
      type: 'ObjectPattern'
      properties: [
        type: 'RestElement'
        argument:
          type: 'ObjectPattern'
          properties: [
            type: 'RestElement'
            argument: ID 'a'
          ]
        postfix: yes
      ]
    right: ID 'b'

  testExpression '{a..., b} = c',
    type: 'AssignmentExpression'
    left:
      type: 'ObjectPattern'
      properties: [
        type: 'RestElement'
        argument: ID 'a'
        postfix: yes
      ,
        type: 'ObjectProperty'
      ]
    right: ID 'c'

  testExpression '{a.b...} = c',
    type: 'AssignmentExpression'
    left:
      type: 'ObjectPattern'
      properties: [
        type: 'RestElement'
        argument:
          type: 'MemberExpression'
        postfix: yes
      ]
    right: ID 'c'

  testExpression '{{a}...} = b',
    type: 'AssignmentExpression'
    left:
      type: 'ObjectPattern'
      properties: [
        type: 'RestElement'
        argument:
          type: 'ObjectPattern'
          properties: [
            type: 'ObjectProperty'
            shorthand: yes
          ]
        postfix: yes
      ]
    right: ID 'b'

  testExpression '[u, [v, ...w, x], ...{...y}, z] = a',
    left:
      type: 'ArrayPattern'

  testExpression '{...{a: [...b, c]}} = d',
    left:
      type: 'ObjectPattern'

  testExpression '{"#{a}": b} = c',
    left:
      type: 'ObjectPattern'
      properties: [
        type: 'ObjectProperty'
        key:
          type: 'TemplateLiteral'
          expressions: [
            ID 'a'
          ]
        computed: yes
      ]

test "AST as expected for Code node", ->
  testExpression '=>',
    type: 'ArrowFunctionExpression'
    params: []
    body: EMPTY_BLOCK
    generator: no
    async: no
    id: null
    hasIndentedBody: no

  testExpression '''
    (a, b = 1) ->
      c
      d()
  ''',
    type: 'FunctionExpression'
    params: [
      type: 'Identifier'
      name: 'a'
      declaration: no
    ,
      type: 'AssignmentPattern'
      left:
        type: 'Identifier'
        name: 'b'
        declaration: no
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
          returns: yes
      ]
      directives: []
    generator: no
    async: no
    id: null
    hasIndentedBody: yes

  testExpression '({a}) ->',
    type: 'FunctionExpression'
    params: [
      type: 'ObjectPattern'
      properties: [
        type: 'ObjectProperty'
        key: ID 'a', declaration: no
        value: ID 'a', declaration: no
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
        ID 'a', declaration: no
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
          key: ID 'a', declaration: no
          value:
            type: 'AssignmentPattern'
            left: ID 'a', declaration: no
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
          left: ID 'a', declaration: no
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
      property: ID 'a', declaration: no
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
        key:   ID 'a', declaration: no
        value: ID 'a', declaration: no
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
      argument: ID 'a', declaration: no
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
        expression: ID 'a', returns: yes
      ]
    generator: no
    async: no
    id: null
    hasIndentedBody: no

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
          returns: yes
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

  testExpression '(a) -> a = 1',
    type: 'FunctionExpression'
    body:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression:
          type: 'AssignmentExpression'
          left:
            ID 'a', declaration: no
      ]

  testExpression '(...a) -> a = 1',
    type: 'FunctionExpression'
    body:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression:
          type: 'AssignmentExpression'
          left:
            ID 'a', declaration: no
      ]

  testExpression '({a}) -> a = 1',
    type: 'FunctionExpression'
    body:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression:
          type: 'AssignmentExpression'
          left:
            ID 'a', declaration: no
      ]

  testExpression '([a]) -> a = 1',
    type: 'FunctionExpression'
    body:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression:
          type: 'AssignmentExpression'
          left:
            ID 'a', declaration: no
      ]

  testExpression '(a = 1) -> a = 1',
    type: 'FunctionExpression'
    body:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression:
          type: 'AssignmentExpression'
          left:
            ID 'a', declaration: no
      ]
    generator: no
    async: no
    id: null

  testExpression '({a} = 1) -> a = 1',
    type: 'FunctionExpression'
    body:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression:
          type: 'AssignmentExpression'
          left:
            ID 'a', declaration: no
      ]
    generator: no
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
        declaration: no
      postfix: yes
    ]

  testExpression '[b, ...c]',
    type: 'ArrayExpression'
    elements: [
      name: 'b'
      declaration: no
    ,
      type: 'SpreadElement'
      argument:
        type: 'Identifier'
        name: 'c'
        declaration: no
      postfix: no
    ]

test "AST as expected for Expansion node", ->
  testExpression '(..., b) ->',
    type: 'FunctionExpression'
    params: [
      type: 'RestElement'
      argument: null
    ,
      ID 'b'
    ]

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
          returns: undefined
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

  testExpression '''
    x = (z() while y)
  ''',
    type: 'AssignmentExpression'
    right:
      type: 'WhileStatement'
      body:
        type: 'BlockStatement'
        body: [
          type: 'ExpressionStatement'
          expression:
            type: 'CallExpression'
            returns: yes
        ]

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
        declaration: yes
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
        properties: [
          type: 'ObjectProperty'
          key: ID 'e', declaration: no
          value: ID 'e', declaration: yes
        ]
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

test "AST as expected for Parens node", ->
  testExpression '(hmmmmm)',
    type: 'Identifier'
    name: 'hmmmmm'

  testExpression '(a + b) / c',
    type: 'BinaryExpression'
    operator: '/'
    left:
      type: 'BinaryExpression'
      operator: '+'
      left: ID 'a'
      right: ID 'b'
    right: ID 'c'

  testExpression '(((1)))',
    type: 'NumericLiteral'
    value: 1

test "AST as expected for StringWithInterpolations node", ->
  testExpression '"a#{b}c"',
    type: 'TemplateLiteral'
    expressions: [
      ID 'b'
    ]
    quasis: [
      type: 'TemplateElement'
      value:
        raw: 'a'
      tail: no
    ,
      type: 'TemplateElement'
      value:
        raw: 'c'
      tail: yes
    ]
    quote: '"'

  testExpression '"""a#{b}c"""',
    type: 'TemplateLiteral'
    expressions: [
      ID 'b'
    ]
    quasis: [
      type: 'TemplateElement'
      value:
        raw: 'a'
      tail: no
    ,
      type: 'TemplateElement'
      value:
        raw: 'c'
      tail: yes
    ]
    quote: '"""'

  testExpression '"#{b}"',
    type: 'TemplateLiteral'
    expressions: [
      ID 'b'
    ]
    quasis: [
      type: 'TemplateElement'
      value:
        raw: ''
      tail: no
    ,
      type: 'TemplateElement'
      value:
        raw: ''
      tail: yes
    ]
    quote: '"'

  testExpression '''
    " a
      #{b}
      c
    "
  ''',
    type: 'TemplateLiteral'
    expressions: [
      ID 'b'
    ]
    quasis: [
      type: 'TemplateElement'
      value:
        raw: ' a\n  '
      tail: no
    ,
      type: 'TemplateElement'
      value:
        raw: '\n  c\n'
      tail: yes
    ]
    quote: '"'

  testExpression '''
    """
      a
        b#{
        c
      }d
    """
  ''',
    type: 'TemplateLiteral'
    expressions: [
      ID 'c'
    ]
    quasis: [
      type: 'TemplateElement'
      value:
        raw: '\n  a\n    b'
      tail: no
    ,
      type: 'TemplateElement'
      value:
        raw: 'd\n'
      tail: yes
    ]
    quote: '"""'

  # empty interpolation
  testExpression '"#{}"',
    type: 'TemplateLiteral'
    expressions: [
      type: 'EmptyInterpolation'
    ]
    quasis: [
      type: 'TemplateElement'
      value:
        raw: ''
      tail: no
    ,
      type: 'TemplateElement'
      value:
        raw: ''
      tail: yes
    ]
    quote: '"'

  testExpression '''
    "#{
      # comment
     }"
    ''',
    type: 'TemplateLiteral'
    expressions: [
      type: 'EmptyInterpolation'
    ]
    quasis: [
      type: 'TemplateElement'
      value:
        raw: ''
      tail: no
    ,
      type: 'TemplateElement'
      value:
        raw: ''
      tail: yes
    ]
    quote: '"'

  testExpression '"#{ ### here ### }"',
    type: 'TemplateLiteral'
    expressions: [
      type: 'EmptyInterpolation'
    ]
    quasis: [
      type: 'TemplateElement'
      value:
        raw: ''
      tail: no
    ,
      type: 'TemplateElement'
      value:
        raw: ''
      tail: yes
    ]
    quote: '"'

  testExpression '''
    a "#{
      b
      c
    }"
  ''',
    type: 'CallExpression'
    arguments: [
      type: 'TemplateLiteral'
      expressions: [
        type: 'BlockStatement'
        body: [
          type: 'ExpressionStatement'
        ,
          type: 'ExpressionStatement'
          expression:
            returns: yes
        ]
      ]
    ]

test "AST as expected for For node", ->
  testStatement 'for x, i in arr when x? then return',
    type: 'For'
    name: ID 'x', declaration: yes
    index: ID 'i', declaration: yes
    guard:
      type: 'UnaryExpression'
    source: ID 'arr', declaration: no
    body:
      type: 'BlockStatement'
      body: [
        type: 'ReturnStatement'
      ]
    style: 'in'
    own: no
    postfix: no
    await: no
    step: null

  testStatement 'for k, v of obj then return',
    type: 'For'
    name: ID 'v', declaration: yes
    index: ID 'k', declaration: yes
    guard: null
    source: ID 'obj', declaration: no
    body:
      type: 'BlockStatement'
      body: [
        type: 'ReturnStatement'
      ]
    style: 'of'
    own: no
    postfix: no
    await: no
    step: null

  testStatement 'for x from iterable then',
    type: 'For'
    name: ID 'x', declaration: yes
    index: null
    guard: null
    body: EMPTY_BLOCK
    source: ID 'iterable', declaration: no
    style: 'from'
    own: no
    postfix: no
    await: no
    step: null

  testStatement 'for i in [0...42] by step when not (i % 2) then',
    type: 'For'
    name: ID 'i', declaration: yes
    index: null
    body: EMPTY_BLOCK
    source:
      type: 'Range'
    guard:
      type: 'UnaryExpression'
    step: ID 'step', declaration: no
    style: 'in'
    own: no
    postfix: no
    await: no

  testExpression 'a = (x for x in y)',
    type: 'AssignmentExpression'
    right:
      type: 'For'
      name: ID 'x', declaration: yes
      index: null
      body:
        type: 'BlockStatement'
        body: [
          type: 'ExpressionStatement'
          expression: ID 'x', declaration: no, returns: yes
        ]
      source: ID 'y', declaration: no
      guard: null
      step: null
      style: 'in'
      own: no
      postfix: yes
      await: no

  testStatement 'x for [0...1]',
    type: 'For'
    name: null
    index: null
    body:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression: ID 'x', declaration: no, returns: undefined
      ]
    source:
      type: 'Range'
    guard: null
    step: null
    style: 'range'
    own: no
    postfix: yes
    await: no

  testStatement '''
    for own x, y of z
      c()
      d
  ''',
    type: 'For'
    name: ID 'y', declaration: yes
    index: ID 'x', declaration: yes
    body:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression:
          type: 'CallExpression'
          returns: undefined
      ,
        type: 'ExpressionStatement'
        expression: ID 'd', declaration: no, returns: undefined
      ]
    source: ID 'z', declaration: no
    guard: null
    step: null
    style: 'of'
    own: yes
    postfix: no
    await: no

  testExpression '''
    ->
      for await x from y
        z
  ''',
    type: 'FunctionExpression'
    body:
      type: 'BlockStatement'
      body: [
        type: 'For'
        name: ID 'x', declaration: yes
        index: null
        body:
          type: 'BlockStatement'
          body: [
            type: 'ExpressionStatement'
            expression: ID 'z', declaration: no, returns: yes
          ]
        source: ID 'y', declaration: no
        guard: null
        step: null
        style: 'from'
        own: no
        postfix: no
        await: yes
      ]

  testStatement '''
    for {x} in y
      z
  ''',
    type: 'For'
    name:
      type: 'ObjectPattern'
      properties: [
        type: 'ObjectProperty'
        key: ID 'x', declaration: no
        value: ID 'x', declaration: yes
        shorthand: yes
        computed: no
      ]
    index: null
    body:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression: ID 'z'
      ]
    source: ID 'y'
    guard: null
    step: null
    style: 'in'
    postfix: no
    await: no

  testStatement '''
    for [x] in y
      z
  ''',
    type: 'For'
    name:
      type: 'ArrayPattern'
      elements: [
        ID 'x', declaration: yes
      ]
    index: null
    body:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression: ID 'z'
      ]
    source: ID 'y'
    guard: null
    step: null
    style: 'in'
    postfix: no
    await: no

  testStatement '''
    for [x..., y] in z
      y()
  ''',
    type: 'For'
    name:
      type: 'ArrayPattern'

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
      alternate: null
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

  testExpression '''
    f(
      if b
        c
      else
        d
    )
  ''',
      type: 'CallExpression'
      arguments: [
        type: 'ConditionalExpression'
        test: ID 'b'
        consequent: ID 'c'
        alternate: ID 'd'
        postfix: no
        inverted: no
      ]

test "AST as expected for MetaProperty node", ->
  testExpression '''
    -> new.target
  ''',
    type: 'FunctionExpression'
    body:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression:
          type: 'MetaProperty'
          meta: ID 'new'
          property: ID 'target'
      ]

  testExpression '''
    -> new.target.name
  ''',
    type: 'FunctionExpression'
    body:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression:
          type: 'MemberExpression'
          object:
            type: 'MetaProperty'
            meta: ID 'new'
            property: ID 'target'
          property: ID 'name'
          computed: no
      ]

test "AST as expected for dynamic import", ->
  testExpression '''
    import('a')
  ''',
    type: 'CallExpression'
    callee:
      type: 'Import'
    arguments: [STRING 'a']

test "AST as expected for RegexLiteral node", ->
  testExpression '/a/ig',
    type: 'RegExpLiteral'
    pattern: 'a'
    originalPattern: 'a'
    flags: 'ig'
    delimiter: '/'
    value: undefined
    extra:
      raw: "/a/ig"
      originalRaw: "/a/ig"
      rawValue: undefined

  testExpression '''
    ///
      a
    ///i
  ''',
    type: 'RegExpLiteral'
    pattern: 'a'
    originalPattern: '\n  a\n'
    flags: 'i'
    delimiter: '///'
    value: undefined
    extra:
      raw: "/a/i"
      originalRaw: "///\n  a\n///i"
      rawValue: undefined

  testExpression '/a\\w\\u1111\\u{11111}/',
    type: 'RegExpLiteral'
    pattern: 'a\\w\\u1111\\ud804\\udd11'
    originalPattern: 'a\\w\\u1111\\u{11111}'
    flags: ''
    delimiter: '/'
    value: undefined
    extra:
      raw: "/a\\w\\u1111\\ud804\\udd11/"
      originalRaw: "/a\\w\\u1111\\u{11111}/"
      rawValue: undefined

  testExpression '''
    ///
      a
      \\w\\u1111\\u{11111}
    ///
  ''',
    type: 'RegExpLiteral'
    pattern: 'a\\w\\u1111\\ud804\\udd11'
    originalPattern: '\n  a\n  \\w\\u1111\\u{11111}\n'
    flags: ''
    delimiter: '///'
    value: undefined
    extra:
      raw: "/a\\w\\u1111\\ud804\\udd11/"
      originalRaw: "///\n  a\n  \\w\\u1111\\u{11111}\n///"
      rawValue: undefined

  testExpression '''
    ///
      /
      (.+)
      /
    ///
  ''',
    type: 'RegExpLiteral'
    pattern: '\\/(.+)\\/'
    originalPattern: '\n  /\n  (.+)\n  /\n'
    flags: ''
    delimiter: '///'
    value: undefined
    extra:
      raw: "/\\/(.+)\\//"
      originalRaw: "///\n  /\n  (.+)\n  /\n///"
      rawValue: undefined

  testExpression '''
    ///
      a # first
      b ### second ###
    ///
  ''',
    type: 'RegExpLiteral'
    pattern: 'ab'
    originalPattern: '\n  a # first\n  b ### second ###\n'
    comments: [
      type: 'CommentLine'
      value: ' first'
    ,
      type: 'CommentBlock'
      value: ' second '
    ]

test "AST as expected for directives", ->
  deepStrictIncludeExpectedProperties CoffeeScript.compile('''
    'directive 1'
    'use strict'
    f()
  ''', ast: yes),
    type: 'File'
    program:
      type: 'Program'
      body: [
        type: 'ExpressionStatement'
        expression:
          type: 'CallExpression'
      ]
      directives: [
        type: 'Directive'
        value:
          type: 'DirectiveLiteral'
          value: 'directive 1'
          extra:
            raw: "'directive 1'"
      ,
        type: 'Directive'
        value:
          type: 'DirectiveLiteral'
          value: 'use strict'
          extra:
            raw: "'use strict'"
      ]

  testExpression '''
    ->
      'use strict'
      f()
      'not a directive'
      g
  ''',
    type: 'FunctionExpression'
    body:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression:
          type: 'CallExpression'
      ,
        type: 'ExpressionStatement'
        expression: STRING 'not a directive'
      ,
        type: 'ExpressionStatement'
        expression: ID 'g'
      ]
      directives: [
        type: 'Directive'
        value:
          type: 'DirectiveLiteral'
          value: 'use strict'
          extra:
            raw: "'use strict'"
      ]

  testExpression '''
    ->
      "not a directive because it's implicitly returned"
  ''',
    type: 'FunctionExpression'
    body:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression: STRING "not a directive because it's implicitly returned"
      ]
      directives: []

  deepStrictIncludeExpectedProperties CoffeeScript.compile('''
    'use strict'
  ''', ast: yes),
    type: 'File'
    program:
      type: 'Program'
      body: []
      directives: [
        type: 'Directive'
        value:
          type: 'DirectiveLiteral'
          value: 'use strict'
          extra:
            raw: "'use strict'"
      ]

  testStatement '''
    class A
      'classes can have directives too'
      a: ->
  ''',
    type: 'ClassDeclaration'
    body:
      type: 'ClassBody'
      body: [
        type: 'ClassMethod'
      ]
      directives: [
        type: 'Directive'
        value:
          type: 'DirectiveLiteral'
          value: 'classes can have directives too'
      ]

  testStatement '''
    if a
      "but other blocks can't"
      b
  ''',
    type: 'IfStatement'
    consequent:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression: STRING "but other blocks can't"
      ,
        type: 'ExpressionStatement'
        expression: ID 'b'
      ]
      directives: []

  testExpression '''
    ->
      """not a directive"""
      b
  ''',
    type: 'FunctionExpression'
    body:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression:
          type: 'TemplateLiteral'
      ,
        type: 'ExpressionStatement'
        expression: ID 'b'
      ]
      directives: []

  testExpression '''
    ->
      # leading comment
      'use strict'
      b
  ''',
    type: 'FunctionExpression'
    body:
      type: 'BlockStatement'
      body: [
        type: 'ExpressionStatement'
        expression: ID 'b'
      ]
      directives: [
        type: 'Directive'
        value:
          type: 'DirectiveLiteral'
          value: 'use strict'
          extra:
            raw: "'use strict'"
      ]

test "AST as expected for comments", ->
  testComments '''
    a # simple line comment
  ''', [
    type: 'CommentLine'
    value: ' simple line comment'
  ]

  testComments '''
    a ### simple here comment ###
  ''', [
    type: 'CommentBlock'
    value: ' simple here comment '
  ]

  testComments '''
    # just a line comment
  ''', [
    type: 'CommentLine'
    value: ' just a line comment'
  ]

  testComments '''
    ### just a here comment ###
  ''', [
    type: 'CommentBlock'
    value: ' just a here comment '
  ]

  testComments '''
    "#{
      # empty interpolation line comment
     }"
  ''', [
    type: 'CommentLine'
    value: ' empty interpolation line comment'
  ]

  testComments '''
    "#{
      ### empty interpolation block comment ###
     }"
  ''', [
    type: 'CommentBlock'
    value: ' empty interpolation block comment '
  ]

  testComments '''
    # multiple line comments
    # on consecutive lines
  ''', [
    type: 'CommentLine'
    value: ' multiple line comments'
  ,
    type: 'CommentLine'
    value: ' on consecutive lines'
  ]

  testComments '''
    # multiple line comments

    # with blank line
  ''', [
    type: 'CommentLine'
    value: ' multiple line comments'
  ,
    type: 'CommentLine'
    value: ' with blank line'
  ]

  testComments '''
    #no whitespace line comment
  ''', [
    type: 'CommentLine'
    value: 'no whitespace line comment'
  ]

  testComments '''
    ###no whitespace here comment###
  ''', [
    type: 'CommentBlock'
    value: 'no whitespace here comment'
  ]

  testComments '''
    ###
    # multiline
    # here comment
    ###
  ''', [
    type: 'CommentBlock'
    value: '\n# multiline\n# here comment\n'
  ]

  testComments '''
    if b
      ###
      # multiline
      # indented here comment
      ###
      c
  ''', [
    type: 'CommentBlock'
    value: '\n  # multiline\n  # indented here comment\n  '
  ]

  testComments '''
    if foo
      ;
      ### empty ###
  ''', [
    type: 'CommentBlock'
    value: ' empty '
  ]

test "AST as expected for chained comparisons", ->
  testExpression '''
    a < b < c
  ''',
    type: 'ChainedComparison'
    operands: [
      ID 'a'
      ID 'b'
      ID 'c'
    ]
    operators: [
      '<'
      '<'
    ]

  testExpression '''
    a isnt b is c isnt d
  ''',
    type: 'ChainedComparison'
    operands: [
      ID 'a'
      ID 'b'
      ID 'c'
      ID 'd'
    ]
    operators: [
      'isnt'
      'is'
      'isnt'
    ]

  testExpression '''
    a >= b < c
  ''',
    type: 'ChainedComparison'
    operands: [
      ID 'a'
      ID 'b'
      ID 'c'
    ]
    operators: [
      '>='
      '<'
    ]

test "AST as expected for Sequence", ->
  testExpression '''
    (a; b)
  ''',
    type: 'SequenceExpression'
    expressions: [
      ID 'a'
      ID 'b'
    ]

  testExpression '''
    (a; b)""
  ''',
    type: 'TaggedTemplateExpression'
    tag:
      type: 'SequenceExpression'
      expressions: [
        ID 'a'
        ID 'b'
      ]
