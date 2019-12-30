# Astract Syntax Tree location data
# ---------------------------------

testAstLocationData = (code, expected) ->
  testAstNodeLocationData getAstExpressionOrStatement(code), expected

testAstRootLocationData = (code, expected) ->
  testAstNodeLocationData getAstRoot(code), expected

testAstNodeLocationData = (node, expected, path = '') ->
  extendPath = (additionalPath) ->
    return additionalPath unless path
    "#{path}.#{additionalPath}"
  ok node?, "Missing expected node at '#{path}'"
  testSingleNodeLocationData node, expected, path if expected.range?
  for own key, expectedChild of expected when key not in ['start', 'end', 'range', 'loc']
    if Array.isArray expectedChild
      ok Array.isArray(node[key]), "Missing expected array at '#{extendPath key}'"
      for expectedItem, index in expectedChild when expectedItem?
        testAstNodeLocationData node[key][index], expectedItem, extendPath "#{key}[#{index}]"
    else if typeof expectedChild is 'object'
      testAstNodeLocationData node[key], expectedChild, extendPath(key)

testSingleNodeLocationData = (node, expected, path = '') ->
  # Even though it’s not part of the location data, check the type to ensure
  # that we’re testing the node we think we are.
  if expected.type?
    eq node.type, expected.type, \
      "Expected AST node type #{reset}#{node.type}#{red} to equal #{reset}#{expected.type}#{red}"

  eq node.start, expected.start, \
    "Expected #{path}.start: #{reset}#{node.start}#{red} to equal #{reset}#{expected.start}#{red}"
  eq node.end, expected.end, \
    "Expected #{path}.end: #{reset}#{node.end}#{red} to equal #{reset}#{expected.end}#{red}"
  arrayEq node.range, expected.range, \
    "Expected #{path}.range: #{reset}#{JSON.stringify node.range}#{red} to equal #{reset}#{JSON.stringify expected.range}#{red}"
  eq node.loc.start.line, expected.loc.start.line, \
    "Expected #{path}.loc.start.line: #{reset}#{node.loc.start.line}#{red} to equal #{reset}#{expected.loc.start.line}#{red}"
  eq node.loc.start.column, expected.loc.start.column, \
    "Expected #{path}.loc.start.column: #{reset}#{node.loc.start.column}#{red} to equal #{reset}#{expected.loc.start.column}#{red}"
  eq node.loc.end.line, expected.loc.end.line, \
    "Expected #{path}.loc.end.line: #{reset}#{node.loc.end.line}#{red} to equal #{reset}#{expected.loc.end.line}#{red}"
  eq node.loc.end.column, expected.loc.end.column, \
    "Expected #{path}.loc.end.column: #{reset}#{node.loc.end.column}#{red} to equal #{reset}#{expected.loc.end.column}#{red}"

testAstCommentsLocationData = (code, expected) ->
  testAstNodeLocationData getAstRoot(code).comments, expected

if require?
  {mergeAstLocationData, mergeLocationData} = require './../lib/coffeescript/nodes'

  test "the `mergeAstLocationData` helper accepts `justLeading` and `justEnding` options", ->
    first =
      range: [4, 5]
      start: 4
      end: 5
      loc:
        start:
          line: 1
          column: 4
        end:
          line: 1
          column: 5
    second =
      range: [1, 10]
      start: 1
      end: 10
      loc:
        start:
          line: 1
          column: 1
        end:
          line: 2
          column: 2
    testSingleNodeLocationData mergeAstLocationData(first, second), second
    testSingleNodeLocationData mergeAstLocationData(first, second, justLeading: yes),
      range: [1, 5]
      start: 1
      end: 5
      loc:
        start:
          line: 1
          column: 1
        end:
          line: 1
          column: 5
    testSingleNodeLocationData mergeAstLocationData(first, second, justEnding: yes),
      range: [4, 10]
      start: 4
      end: 10
      loc:
        start:
          line: 1
          column: 4
        end:
          line: 2
          column: 2

  test "the `mergeLocationData` helper accepts `justLeading` and `justEnding` options", ->
    testLocationData = (node, expected) ->
      arrayEq node.range, expected.range
      for field in ['first_line', 'first_column', 'last_line', 'last_column']
        eq node[field], expected[field]

    first =
      range: [4, 5]
      first_line: 0
      first_column: 4
      last_line: 0
      last_column: 4
    second =
      range: [1, 10]
      first_line: 0
      first_column: 1
      last_line: 1
      last_column: 2

    testLocationData mergeLocationData(first, second), second
    testLocationData mergeLocationData(first, second, justLeading: yes),
      range: [1, 5]
      first_line: 0
      first_column: 1
      last_line: 0
      last_column: 4
    testLocationData mergeLocationData(first, second, justEnding: yes),
      range: [4, 10]
      first_line: 0
      first_column: 4
      last_line: 1
      last_column: 2

test "AST location data as expected for NumberLiteral node", ->
  testAstLocationData '42',
    type: 'NumericLiteral'
    start: 0
    end: 2
    range: [0, 2]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 2

test "AST location data as expected for InfinityLiteral node", ->
  testAstLocationData 'Infinity',
    type: 'Identifier'
    start: 0
    end: 8
    range: [0, 8]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 8

  testAstLocationData '2e308',
    type: 'NumericLiteral'
    start: 0
    end: 5
    range: [0, 5]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 5

test "AST location data as expected for NaNLiteral node", ->
  testAstLocationData 'NaN',
    type: 'Identifier'
    start: 0
    end: 3
    range: [0, 3]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 3

test "AST location data as expected for IdentifierLiteral node", ->
  testAstLocationData 'id',
    type: 'Identifier'
    start: 0
    end: 2
    range: [0, 2]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 2

test "AST location data as expected for StatementLiteral node", ->
  testAstLocationData 'break',
    type: 'BreakStatement'
    start: 0
    end: 5
    range: [0, 5]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 5

  testAstLocationData 'continue',
    type: 'ContinueStatement'
    start: 0
    end: 8
    range: [0, 8]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 8

  testAstLocationData 'debugger',
    type: 'DebuggerStatement'
    start: 0
    end: 8
    range: [0, 8]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 8

test "AST location data as expected for ThisLiteral node", ->
  testAstLocationData 'this',
    type: 'ThisExpression'
    start: 0
    end: 4
    range: [0, 4]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 4

test "AST location data as expected for UndefinedLiteral node", ->
  testAstLocationData 'undefined',
    type: 'Identifier'
    start: 0
    end: 9
    range: [0, 9]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 9

test "AST location data as expected for NullLiteral node", ->
  testAstLocationData 'null',
    type: 'NullLiteral'
    start: 0
    end: 4
    range: [0, 4]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 4

test "AST location data as expected for BooleanLiteral node", ->
  testAstLocationData 'true',
    type: 'BooleanLiteral'
    start: 0
    end: 4
    range: [0, 4]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 4

test "AST location data as expected for Access node", ->
  testAstLocationData 'obj.prop',
    type: 'MemberExpression'
    object:
      start: 0
      end: 3
      range: [0, 3]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 3
    property:
      start: 4
      end: 8
      range: [4, 8]
      loc:
        start:
          line: 1
          column: 4
        end:
          line: 1
          column: 8
    start: 0
    end: 8
    range: [0, 8]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 8

  testAstLocationData 'a::b',
    type: 'MemberExpression'
    object:
      object:
        start: 0
        end: 1
        range: [0, 1]
        loc:
          start:
            line: 1
            column: 0
          end:
            line: 1
            column: 1
      property:
        start: 1
        end: 3
        range: [1, 3]
        loc:
          start:
            line: 1
            column: 1
          end:
            line: 1
            column: 3
    property:
      start: 3
      end: 4
      range: [3, 4]
      loc:
        start:
          line: 1
          column: 3
        end:
          line: 1
          column: 4
    start: 0
    end: 4
    range: [0, 4]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 4

  testAstLocationData '''
    (
      obj
    ).prop
  ''',
    type: 'MemberExpression'
    object:
      start: 4
      end: 7
      range: [4, 7]
      loc:
        start:
          line: 2
          column: 2
        end:
          line: 2
          column: 5
    property:
      start: 10
      end: 14
      range: [10, 14]
      loc:
        start:
          line: 3
          column: 2
        end:
          line: 3
          column: 6
    start: 0
    end: 14
    range: [0, 14]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 3
        column: 6

test "AST location data as expected for Index node", ->
  testAstLocationData 'a[b]',
    type: 'MemberExpression'
    object:
      start: 0
      end: 1
      range: [0, 1]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 1
    property:
      start: 2
      end: 3
      range: [2, 3]
      loc:
        start:
          line: 1
          column: 2
        end:
          line: 1
          column: 3
    start: 0
    end: 4
    range: [0, 4]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 4

  testAstLocationData 'a?[b][3]',
    type: 'OptionalMemberExpression'
    object:
      object:
        start: 0
        end: 1
        range: [0, 1]
        loc:
          start:
            line: 1
            column: 0
          end:
            line: 1
            column: 1
      property:
        start: 3
        end: 4
        range: [3, 4]
        loc:
          start:
            line: 1
            column: 3
          end:
            line: 1
            column: 4
      start: 0
      end: 5
      range: [0, 5]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 5
    property:
      start: 6
      end: 7
      range: [6, 7]
      loc:
        start:
          line: 1
          column: 6
        end:
          line: 1
          column: 7
    start: 0
    end: 8
    range: [0, 8]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 8

test "AST location data as expected for Parens node", ->
  testAstLocationData '(hmmmmm)',
    type: 'Identifier'
    start: 1
    end: 7
    range: [1, 7]
    loc:
      start:
        line: 1
        column: 1
      end:
        line: 1
        column: 7

  testAstLocationData '(((1)))',
    type: 'NumericLiteral'
    start: 3
    end: 4
    range: [3, 4]
    loc:
      start:
        line: 1
        column: 3
      end:
        line: 1
        column: 4

test "AST location data as expected for Op node", ->
  testAstLocationData '1 <= 2',
    type: 'BinaryExpression'
    left:
      start: 0
      end: 1
      range: [0, 1]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 1
    right:
      start: 5
      end: 6
      range: [5, 6]
      loc:
        start:
          line: 1
          column: 5
        end:
          line: 1
          column: 6
    start: 0
    end: 6
    range: [0, 6]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 6

  testAstLocationData '!x',
    type: 'UnaryExpression'
    argument:
      start: 1
      end: 2
      range: [1, 2]
      loc:
        start:
          line: 1
          column: 1
        end:
          line: 1
          column: 2
    start: 0
    end: 2
    range: [0, 2]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 2

  testAstLocationData 'not x',
    type: 'UnaryExpression'
    argument:
      start: 4
      end: 5
      range: [4, 5]
      loc:
        start:
          line: 1
          column: 4
        end:
          line: 1
          column: 5
    start: 0
    end: 5
    range: [0, 5]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 5

  testAstLocationData 'x++',
    type: 'UpdateExpression'
    argument:
      start: 0
      end: 1
      range: [0, 1]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 1
    start: 0
    end: 3
    range: [0, 3]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 3

  testAstLocationData '(x + y) * z',
    type: 'BinaryExpression'
    left:
      left:
        start: 1
        end: 2
        range: [1, 2]
        loc:
          start:
            line: 1
            column: 1
          end:
            line: 1
            column: 2
      right:
        start: 5
        end: 6
        range: [5, 6]
        loc:
          start:
            line: 1
            column: 5
          end:
            line: 1
            column: 6
      start: 1
      end: 6
      range: [1, 6]
      loc:
        start:
          line: 1
          column: 1
        end:
          line: 1
          column: 6
    right:
      start: 10
      end: 11
      range: [10, 11]
      loc:
        start:
          line: 1
          column: 10
        end:
          line: 1
          column: 11
    start: 0
    end: 11
    range: [0, 11]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 11

test "AST location data as expected for Call node", ->
  testAstLocationData 'fn()',
    type: 'CallExpression'
    start: 0
    end: 4
    range: [0, 4]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 4
    callee:
      start: 0
      end: 2
      range: [0, 2]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 2

  testAstLocationData 'new Date()',
    type: 'NewExpression'
    start: 0
    end: 10
    range: [0, 10]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 10
    callee:
      start: 4
      end: 8
      range: [4, 8]
      loc:
        start:
          line: 1
          column: 4
        end:
          line: 1
          column: 8

  testAstLocationData '''
    new Old(
      1
    )
  ''',
    start: 0
    end: 14
    range: [0, 14]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 3
        column: 1
    type: 'NewExpression'
    arguments: [
      start: 11
      end: 12
      range: [11, 12]
      loc:
        start:
          line: 2
          column: 2
        end:
          line: 2
          column: 3
    ]

  testAstLocationData 'maybe? 1 + 1',
    type: 'OptionalCallExpression'
    start: 0
    end: 12
    range: [0, 12]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 12
    arguments: [
      start: 7
      end: 12
      range: [7, 12]
      loc:
        start:
          line: 1
          column: 7
        end:
          line: 1
          column: 12
    ]

  testAstLocationData '''
    goDo(this,
      that)
  ''',
    type: 'CallExpression'
    start: 0
    end: 18
    range: [0, 18]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 2
        column: 7
    arguments: [
      start: 5
      end: 9
      range: [5, 9]
      loc:
        start:
          line: 1
          column: 5
        end:
          line: 1
          column: 9
    ,
      start: 13
      end: 17
      range: [13, 17]
      loc:
        start:
          line: 2
          column: 2
        end:
          line: 2
          column: 6
    ]

  testAstLocationData 'new Old',
    type: 'NewExpression'
    callee:
      start: 4
      end: 7
      range: [4, 7]
      loc:
        start:
          line: 1
          column: 4
        end:
          line: 1
          column: 7
    start: 0
    end: 7
    range: [0, 7]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 7

test "AST location data as expected for SuperCall node", ->
  testAstLocationData 'class child extends parent then constructor: -> super()',
    type: 'ClassDeclaration'
    body:
      body: [
        body:
          body: [
            expression:
              callee:
                start: 48
                end: 53
                range: [48, 53]
                loc:
                  start:
                    line: 1
                    column: 48
                  end:
                    line: 1
                    column: 53
              start: 48
              end: 55
              range: [48, 55]
              loc:
                start:
                  line: 1
                  column: 48
                end:
                  line: 1
                  column: 55
          ]
      ]
    start: 0
    end: 55
    range: [0, 55]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 55

test "AST location data as expected for Super node", ->
  testAstLocationData '''
    class child extends parent
      func: ->
        super[prop]()
  ''',
    type: 'ClassDeclaration'
    body:
      body: [
        body:
          body: [
            expression:
              callee:
                object:
                  start: 42
                  end: 47
                  range: [42, 47]
                  loc:
                    start:
                      line: 3
                      column: 4
                    end:
                      line: 3
                      column: 9
                property:
                  start: 48
                  end: 52
                  range: [48, 52]
                  loc:
                    start:
                      line: 3
                      column: 10
                    end:
                      line: 3
                      column: 14
                start: 42
                end: 53
                range: [42, 53]
                loc:
                  start:
                    line: 3
                    column: 4
                  end:
                    line: 3
                    column: 15
              start: 42
              end: 55
              range: [42, 55]
              loc:
                start:
                  line: 3
                  column: 4
                end:
                  line: 3
                  column: 17
          ]
      ]
    start: 0
    end: 55
    range: [0, 55]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 3
        column: 17

test "AST location data as expected for Range node", ->
  testAstLocationData '[x..y]',
    type: 'Range'
    from:
      start: 1
      end: 2
      range: [1, 2]
      loc:
        start:
          line: 1
          column: 1
        end:
          line: 1
          column: 2
    to:
      start: 4
      end: 5
      range: [4, 5]
      loc:
        start:
          line: 1
          column: 4
        end:
          line: 1
          column: 5
    start: 0
    end: 6
    range: [0, 6]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 6

  testAstLocationData '[4...2]',
    type: 'Range'
    from:
      start: 1
      end: 2
      range: [1, 2]
      loc:
        start:
          line: 1
          column: 1
        end:
          line: 1
          column: 2
    to:
      start: 5
      end: 6
      range: [5, 6]
      loc:
        start:
          line: 1
          column: 5
        end:
          line: 1
          column: 6
    start: 0
    end: 7
    range: [0, 7]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 7

test "AST location data as expected for Slice node", ->
  testAstLocationData 'x[..y]',
    property:
      to:
        start: 4
        end: 5
        range: [4, 5]
        loc:
          start:
            line: 1
            column: 4
          end:
            line: 1
            column: 5
      start: 2
      end: 5
      range: [2, 5]
      loc:
        start:
          line: 1
          column: 2
        end:
          line: 1
          column: 5
    start: 0
    end: 6
    range: [0, 6]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 6

  testAstLocationData 'x[y...z]',
    property:
      start: 2
      end: 7
      range: [2, 7]
      loc:
        start:
          line: 1
          column: 2
        end:
          line: 1
          column: 7
    start: 0
    end: 8
    range: [0, 8]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 8

  testAstLocationData 'x[...]',
    property:
      start: 2
      end: 5
      range: [2, 5]
      loc:
        start:
          line: 1
          column: 2
        end:
          line: 1
          column: 5
    start: 0
    end: 6
    range: [0, 6]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 6

test "AST location data as expected for Splat node", ->
  testAstLocationData '[a...]',
    type: 'ArrayExpression'
    elements: [
      argument:
        start: 1
        end: 2
        range: [1, 2]
        loc:
          start:
            line: 1
            column: 1
          end:
            line: 1
            column: 2
      start: 1
      end: 5
      range: [1, 5]
      loc:
        start:
          line: 1
          column: 1
        end:
          line: 1
          column: 5
    ]
    start: 0
    end: 6
    range: [0, 6]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 6

  testAstLocationData '[b, ...c]',
    type: 'ArrayExpression'
    elements: [
      {}
    ,
      argument:
        start: 7
        end: 8
        range: [7, 8]
        loc:
          start:
            line: 1
            column: 7
          end:
            line: 1
            column: 8
      start: 4
      end: 8
      range: [4, 8]
      loc:
        start:
          line: 1
          column: 4
        end:
          line: 1
          column: 8
    ]
    start: 0
    end: 9
    range: [0, 9]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 9

test "AST location data as expected for Elision node", ->
  testAstLocationData '[,,,a,, ,b]',
    type: 'ArrayExpression'
    elements: [
      null,,,
      start: 4
      end: 5
      range: [4, 5]
      loc:
        start:
          line: 1
          column: 4
        end:
          line: 1
          column: 5
    ,,,
      start: 9
      end: 10
      range: [9, 10]
      loc:
        start:
          line: 1
          column: 9
        end:
          line: 1
          column: 10
    ]
    start: 0
    end: 11
    range: [0, 11]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 11

test "AST location data as expected for ModuleDeclaration node", ->
  testAstLocationData 'export {X}',
    type: 'ExportNamedDeclaration'
    specifiers: [
      local:
        start: 8
        end: 9
        range: [8, 9]
        loc:
          start:
            line: 1
            column: 8
          end:
            line: 1
            column: 9
      exported:
        start: 8
        end: 9
        range: [8, 9]
        loc:
          start:
            line: 1
            column: 8
          end:
            line: 1
            column: 9
      start: 8
      end: 9
      range: [8, 9]
      loc:
        start:
          line: 1
          column: 8
        end:
          line: 1
          column: 9
    ]
    start: 0
    end: 10
    range: [0, 10]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 10

  testAstLocationData 'import X from "."',
    type: 'ImportDeclaration'
    specifiers: [
      start: 7
      end: 8
      range: [7, 8]
      loc:
        start:
          line: 1
          column: 7
        end:
          line: 1
          column: 8
    ]
    source:
      start: 14
      end: 17
      range: [14, 17]
      loc:
        start:
          line: 1
          column: 14
        end:
          line: 1
          column: 17
    start: 0
    end: 17
    range: [0, 17]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 17

test "AST location data as expected for ImportDeclaration node", ->
  testAstLocationData '''
    import React, {
      Component
    } from "react"
  ''',
    type: 'ImportDeclaration'
    specifiers: [
      start: 7
      end: 12
      range: [7, 12]
      loc:
        start:
          line: 1
          column: 7
        end:
          line: 1
          column: 12
    ,
      imported:
        start: 18
        end: 27
        range: [18, 27]
        loc:
          start:
            line: 2
            column: 2
          end:
            line: 2
            column: 11
      start: 18
      end: 27
      range: [18, 27]
      loc:
        start:
          line: 2
          column: 2
        end:
          line: 2
          column: 11
    ]
    source:
      start: 35
      end: 42
      range: [35, 42]
      loc:
        start:
          line: 3
          column: 7
        end:
          line: 3
          column: 14
    start: 0
    end: 42
    range: [0, 42]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 3
        column: 14

test "AST location data as expected for ExportNamedDeclaration node", ->
  testAstLocationData 'export {}',
    type: 'ExportNamedDeclaration'
    start: 0
    end: 9
    range: [0, 9]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 9

  testAstLocationData 'export fn = ->',
    type: 'ExportNamedDeclaration'
    declaration:
      left:
        start: 7
        end: 9
        range: [7, 9]
        loc:
          start:
            line: 1
            column: 7
          end:
            line: 1
            column: 9
      right:
        start: 12
        end: 14
        range: [12, 14]
        loc:
          start:
            line: 1
            column: 12
          end:
            line: 1
            column: 14
      start: 7
      end: 14
      range: [7, 14]
      loc:
        start:
          line: 1
          column: 7
        end:
          line: 1
          column: 14
    start: 0
    end: 14
    range: [0, 14]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 14

  testAstLocationData 'export class A',
    type: 'ExportNamedDeclaration'
    declaration:
      id:
        start: 13
        end: 14
        range: [13, 14]
        loc:
          start:
            line: 1
            column: 13
          end:
            line: 1
            column: 14
      start: 7
      end: 14
      range: [7, 14]
      loc:
        start:
          line: 1
          column: 7
        end:
          line: 1
          column: 14
    start: 0
    end: 14
    range: [0, 14]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 14

  testAstLocationData '''
    export {
      x as y
      z as default
      }
  ''',
    type: 'ExportNamedDeclaration'
    specifiers: [
      local:
        start: 11
        end: 12
        range: [11, 12]
        loc:
          start:
            line: 2
            column: 2
          end:
            line: 2
            column: 3
      exported:
        start: 16
        end: 17
        range: [16, 17]
        loc:
          start:
            line: 2
            column: 7
          end:
            line: 2
            column: 8
      start: 11
      end: 17
      range: [11, 17]
      loc:
        start:
          line: 2
          column: 2
        end:
          line: 2
          column: 8
    ,
      local:
        start: 20
        end: 21
        range: [20, 21]
        loc:
          start:
            line: 3
            column: 2
          end:
            line: 3
            column: 3
      exported:
        start: 25
        end: 32
        range: [25, 32]
        loc:
          start:
            line: 3
            column: 7
          end:
            line: 3
            column: 14
      start: 20
      end: 32
      range: [20, 32]
      loc:
        start:
          line: 3
          column: 2
        end:
          line: 3
          column: 14
    ]
    start: 0
    end: 36
    range: [0, 36]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 4
        column: 3

  testAstLocationData 'export {default, default as b} from "./abc"',
    type: 'ExportNamedDeclaration'
    specifiers: [
      local:
        start: 8
        end: 15
        range: [8, 15]
        loc:
          start:
            line: 1
            column: 8
          end:
            line: 1
            column: 15
      start: 8
      end: 15
      range: [8, 15]
      loc:
        start:
          line: 1
          column: 8
        end:
          line: 1
          column: 15
    ,
      local:
        start: 17
        end: 24
        range: [17, 24]
        loc:
          start:
            line: 1
            column: 17
          end:
            line: 1
            column: 24
      exported:
        start: 28
        end: 29
        range: [28, 29]
        loc:
          start:
            line: 1
            column: 28
          end:
            line: 1
            column: 29
      start: 17
      end: 29
      range: [17, 29]
      loc:
        start:
          line: 1
          column: 17
        end:
          line: 1
          column: 29
    ]
    source:
      start: 36
      end: 43
      range: [36, 43]
      loc:
        start:
          line: 1
          column: 36
        end:
          line: 1
          column: 43
    start: 0
    end: 43
    range: [0, 43]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 43

test "AST location data as expected for ExportDefaultDeclaration node", ->
  testAstLocationData 'export default class',
    type: 'ExportDefaultDeclaration'
    declaration:
      start: 15
      end: 20
      range: [15, 20]
      loc:
        start:
          line: 1
          column: 15
        end:
          line: 1
          column: 20
    start: 0
    end: 20
    range: [0, 20]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 20

  testAstLocationData 'export default "abc"',
    type: 'ExportDefaultDeclaration'
    declaration:
      start: 15
      end: 20
      range: [15, 20]
      loc:
        start:
          line: 1
          column: 15
        end:
          line: 1
          column: 20
    start: 0
    end: 20
    range: [0, 20]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 20

test "AST location data as expected for ExportAllDeclaration node", ->
  testAstLocationData 'export * from "module-name"',
    type: 'ExportAllDeclaration'
    source:
      start: 14
      end: 27
      range: [14, 27]
      loc:
        start:
          line: 1
          column: 14
        end:
          line: 1
          column: 27
    start: 0
    end: 27
    range: [0, 27]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 27

test "AST location data as expected for ImportDefaultSpecifier node", ->
  testAstLocationData 'import React from "react"',
    type: 'ImportDeclaration'
    specifiers: [
      start: 7
      end: 12
      range: [7, 12]
      loc:
        start:
          line: 1
          column: 7
        end:
          line: 1
          column: 12
    ]
    source:
      start: 18
      end: 25
      range: [18, 25]
      loc:
        start:
          line: 1
          column: 18
        end:
          line: 1
          column: 25
    start: 0
    end: 25
    range: [0, 25]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 25

test "AST location data as expected for ImportNamespaceSpecifier node", ->
  testAstLocationData 'import * as React from "react"',
    type: 'ImportDeclaration'
    specifiers: [
      start: 7
      end: 17
      range: [7, 17]
      loc:
        start:
          line: 1
          column: 7
        end:
          line: 1
          column: 17
    ]
    source:
      start: 23
      end: 30
      range: [23, 30]
      loc:
        start:
          line: 1
          column: 23
        end:
          line: 1
          column: 30
    start: 0
    end: 30
    range: [0, 30]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 30

  testAstLocationData 'import React, * as ReactStar from "react"',
    type: 'ImportDeclaration'
    specifiers: [
      start: 7
      end: 12
      range: [7, 12]
      loc:
        start:
          line: 1
          column: 7
        end:
          line: 1
          column: 12
    ,
      local:
        start: 19
        end: 28
        range: [19, 28]
        loc:
          start:
            line: 1
            column: 19
          end:
            line: 1
            column: 28
      start: 14
      end: 28
      range: [14, 28]
      loc:
        start:
          line: 1
          column: 14
        end:
          line: 1
          column: 28
    ]
    source:
      start: 34
      end: 41
      range: [34, 41]
      loc:
        start:
          line: 1
          column: 34
        end:
          line: 1
          column: 41
    start: 0
    end: 41
    range: [0, 41]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 41

test "AST location data as expected for Obj node", ->
  testAstLocationData "{a: 1, b, [c], @d, [e()]: f, 'g': 2, ...h, i...}",
    type: 'ObjectExpression'
    properties: [
      key:
        start: 1
        end: 2
        range: [1, 2]
        loc:
          start:
            line: 1
            column: 1
          end:
            line: 1
            column: 2
      value:
        start: 4
        end: 5
        range: [4, 5]
        loc:
          start:
            line: 1
            column: 4
          end:
            line: 1
            column: 5
      start: 1
      end: 5
      range: [1, 5]
      loc:
        start:
          line: 1
          column: 1
        end:
          line: 1
          column: 5
    ,
      key:
        start: 7
        end: 8
        range: [7, 8]
        loc:
          start:
            line: 1
            column: 7
          end:
            line: 1
            column: 8
      value:
        start: 7
        end: 8
        range: [7, 8]
        loc:
          start:
            line: 1
            column: 7
          end:
            line: 1
            column: 8
      start: 7
      end: 8
      range: [7, 8]
      loc:
        start:
          line: 1
          column: 7
        end:
          line: 1
          column: 8
    ,
      key:
        start: 11
        end: 12
        range: [11, 12]
        loc:
          start:
            line: 1
            column: 11
          end:
            line: 1
            column: 12
      value:
        start: 11
        end: 12
        range: [11, 12]
        loc:
          start:
            line: 1
            column: 11
          end:
            line: 1
            column: 12
      start: 10
      end: 13
      range: [10, 13]
      loc:
        start:
          line: 1
          column: 10
        end:
          line: 1
          column: 13
    ,
      key:
        object:
          start: 15
          end: 16
          range: [15, 16]
          loc:
            start:
              line: 1
              column: 15
            end:
              line: 1
              column: 16
        property:
          start: 16
          end: 17
          range: [16, 17]
          loc:
            start:
              line: 1
              column: 16
            end:
              line: 1
              column: 17
        start: 15
        end: 17
        range: [15, 17]
        loc:
          start:
            line: 1
            column: 15
          end:
            line: 1
            column: 17
      value:
        object:
          start: 15
          end: 16
          range: [15, 16]
          loc:
            start:
              line: 1
              column: 15
            end:
              line: 1
              column: 16
        property:
          start: 16
          end: 17
          range: [16, 17]
          loc:
            start:
              line: 1
              column: 16
            end:
              line: 1
              column: 17
        start: 15
        end: 17
        range: [15, 17]
        loc:
          start:
            line: 1
            column: 15
          end:
            line: 1
            column: 17
      start: 15
      end: 17
      range: [15, 17]
      loc:
        start:
          line: 1
          column: 15
        end:
          line: 1
          column: 17
    ,
      key:
        start: 20
        end: 23
        range: [20, 23]
        loc:
          start:
            line: 1
            column: 20
          end:
            line: 1
            column: 23
      value:
        start: 26
        end: 27
        range: [26, 27]
        loc:
          start:
            line: 1
            column: 26
          end:
            line: 1
            column: 27
      start: 19
      end: 27
      range: [19, 27]
      loc:
        start:
          line: 1
          column: 19
        end:
          line: 1
          column: 27
    ,
      key:
        start: 29
        end: 32
        range: [29, 32]
        loc:
          start:
            line: 1
            column: 29
          end:
            line: 1
            column: 32
      value:
        start: 34
        end: 35
        range: [34, 35]
        loc:
          start:
            line: 1
            column: 34
          end:
            line: 1
            column: 35
      start: 29
      end: 35
      range: [29, 35]
      loc:
        start:
          line: 1
          column: 29
        end:
          line: 1
          column: 35
    ,
      argument:
        start: 40
        end: 41
        range: [40, 41]
        loc:
          start:
            line: 1
            column: 40
          end:
            line: 1
            column: 41
      start: 37
      end: 41
      range: [37, 41]
      loc:
        start:
          line: 1
          column: 37
        end:
          line: 1
          column: 41
    ,
      argument:
        start: 43
        end: 44
        range: [43, 44]
        loc:
          start:
            line: 1
            column: 43
          end:
            line: 1
            column: 44
      start: 43
      end: 47
      range: [43, 47]
      loc:
        start:
          line: 1
          column: 43
        end:
          line: 1
          column: 47
    ]
    start: 0
    end: 48
    range: [0, 48]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 48

  testAstLocationData 'a: 1',
    type: 'ObjectExpression'
    properties: [
      key:
        start: 0
        end: 1
        range: [0, 1]
        loc:
          start:
            line: 1
            column: 0
          end:
            line: 1
            column: 1
      value:
        start: 3
        end: 4
        range: [3, 4]
        loc:
          start:
            line: 1
            column: 3
          end:
            line: 1
            column: 4
      start: 0
      end: 4
      range: [0, 4]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 4
    ]
    start: 0
    end: 4
    range: [0, 4]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 4

test "AST location data as expected for Assign node", ->
  testAstLocationData 'a = b',
    type: 'AssignmentExpression'
    left:
      start: 0
      end: 1
      range: [0, 1]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 1
    right:
      start: 4
      end: 5
      range: [4, 5]
      loc:
        start:
          line: 1
          column: 4
        end:
          line: 1
          column: 5
    start: 0
    end: 5
    range: [0, 5]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 5

  testAstLocationData 'a += b',
    type: 'AssignmentExpression'
    left:
      start: 0
      end: 1
      range: [0, 1]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 1
    right:
      start: 5
      end: 6
      range: [5, 6]
      loc:
        start:
          line: 1
          column: 5
        end:
          line: 1
          column: 6
    start: 0
    end: 6
    range: [0, 6]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 6

  testAstLocationData '{a: [...b]} = c',
    type: 'AssignmentExpression'
    left:
      properties: [
        type: 'ObjectProperty'
        key:
          start: 1
          end: 2
          range: [1, 2]
          loc:
            start:
              line: 1
              column: 1
            end:
              line: 1
              column: 2
        value:
          elements: [
            start: 5
            end: 9
            range: [5, 9]
            loc:
              start:
                line: 1
                column: 5
              end:
                line: 1
                column: 9
          ]
          start: 4
          end: 10
          range: [4, 10]
          loc:
            start:
              line: 1
              column: 4
            end:
              line: 1
              column: 10
        start: 1
        end: 10
        range: [1, 10]
        loc:
          start:
            line: 1
            column: 1
          end:
            line: 1
            column: 10
      ]
      start: 0
      end: 11
      range: [0, 11]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 11
    right:
      start: 14
      end: 15
      range: [14, 15]
      loc:
        start:
          line: 1
          column: 14
        end:
          line: 1
          column: 15
    start: 0
    end: 15
    range: [0, 15]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 15

test "AST location data as expected for Expansion node", ->
  testAstLocationData '[..., b] = c',
    type: 'AssignmentExpression'
    left:
      elements: [
        start: 1
        end: 4
        range: [1, 4]
        loc:
          start:
            line: 1
            column: 1
          end:
            line: 1
            column: 4
      ]
      start: 0
      end: 8
      range: [0, 8]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 8
    start: 0
    end: 12
    range: [0, 12]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 12

test "AST location data as expected for Throw node", ->
  testAstLocationData 'throw new BallError "catch"',
    type: 'ThrowStatement'
    argument:
      start: 6
      end: 27
      range: [6, 27]
      loc:
        start:
          line: 1
          column: 6
        end:
          line: 1
          column: 27
    start: 0
    end: 27
    range: [0, 27]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 27

test "AST location data as expected for Existence node", ->
  testAstLocationData 'Ghosts?',
    type: 'UnaryExpression'
    argument:
      start: 0
      end: 6
      range: [0, 6]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 6
    start: 0
    end: 7
    range: [0, 7]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 7

test "AST location data as expected for JSXTag node", ->
  testAstLocationData '<CSXY />',
    type: 'JSXElement'
    openingElement:
      name:
        start: 1
        end: 5
        range: [1, 5]
        loc:
          start:
            line: 1
            column: 1
          end:
            line: 1
            column: 5
      start: 0
      end: 8
      range: [0, 8]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 8
    start: 0
    end: 8
    range: [0, 8]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 8

  testAstLocationData '<div></div>',
    type: 'JSXElement'
    openingElement:
      name:
        start: 1
        end: 4
        range: [1, 4]
        loc:
          start:
            line: 1
            column: 1
          end:
            line: 1
            column: 4
      start: 0
      end: 5
      range: [0, 5]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 5
    closingElement:
      name:
        start: 7
        end: 10
        range: [7, 10]
        loc:
          start:
            line: 1
            column: 7
          end:
            line: 1
            column: 10
      start: 5
      end: 11
      range: [5, 11]
      loc:
        start:
          line: 1
          column: 5
        end:
          line: 1
          column: 11
    start: 0
    end: 11
    range: [0, 11]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 11

  testAstLocationData '<A.B />',
    type: 'JSXElement'
    openingElement:
      name:
        object:
          start: 1
          end: 2
          range: [1, 2]
          loc:
            start:
              line: 1
              column: 1
            end:
              line: 1
              column: 2
        property:
          start: 3
          end: 4
          range: [3, 4]
          loc:
            start:
              line: 1
              column: 3
            end:
              line: 1
              column: 4
        start: 1
        end: 4
        range: [1, 4]
        loc:
          start:
            line: 1
            column: 1
          end:
            line: 1
            column: 4
      start: 0
      end: 7
      range: [0, 7]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 7
    start: 0
    end: 7
    range: [0, 7]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 7

  testAstLocationData '<Tag.Name.Here></Tag.Name.Here>',
    type: 'JSXElement'
    openingElement:
      name:
        object:
          object:
            start: 1
            end: 4
            range: [1, 4]
            loc:
              start:
                line: 1
                column: 1
              end:
                line: 1
                column: 4
          property:
            start: 5
            end: 9
            range: [5, 9]
            loc:
              start:
                line: 1
                column: 5
              end:
                line: 1
                column: 9
          start: 1
          end: 9
          range: [1, 9]
          loc:
            start:
              line: 1
              column: 1
            end:
              line: 1
              column: 9
        property:
          start: 10
          end: 14
          range: [10, 14]
          loc:
            start:
              line: 1
              column: 10
            end:
              line: 1
              column: 14
        start: 1
        end: 14
        range: [1, 14]
        loc:
          start:
            line: 1
            column: 1
          end:
            line: 1
            column: 14
      start: 0
      end: 15
      range: [0, 15]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 15
    closingElement:
      name:
        object:
          object:
            start: 17
            end: 20
            range: [17, 20]
            loc:
              start:
                line: 1
                column: 17
              end:
                line: 1
                column: 20
          property:
            start: 21
            end: 25
            range: [21, 25]
            loc:
              start:
                line: 1
                column: 21
              end:
                line: 1
                column: 25
          start: 17
          end: 25
          range: [17, 25]
          loc:
            start:
              line: 1
              column: 17
            end:
              line: 1
              column: 25
        property:
          start: 26
          end: 30
          range: [26, 30]
          loc:
            start:
              line: 1
              column: 26
            end:
              line: 1
              column: 30
        start: 17
        end: 30
        range: [17, 30]
        loc:
          start:
            line: 1
            column: 17
          end:
            line: 1
            column: 30
      start: 15
      end: 31
      range: [15, 31]
      loc:
        start:
          line: 1
          column: 15
        end:
          line: 1
          column: 31
    start: 0
    end: 31
    range: [0, 31]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 31

  testAstLocationData '<></>',
    type: 'JSXFragment'
    openingFragment:
      start: 0
      end: 2
      range: [0, 2]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 2
    closingFragment:
      start: 2
      end: 5
      range: [2, 5]
      loc:
        start:
          line: 1
          column: 2
        end:
          line: 1
          column: 5
    start: 0
    end: 5
    range: [0, 5]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 5

  testAstLocationData '''
    <div
      a
      b="c"
      d={e}
      {...f}
    />
  ''',
    type: 'JSXElement'
    openingElement:
      name:
        start: 1
        end: 4
        range: [1, 4]
        loc:
          start:
            line: 1
            column: 1
          end:
            line: 1
            column: 4
      attributes: [
        name:
          start: 7
          end: 8
          range: [7, 8]
          loc:
            start:
              line: 2
              column: 2
            end:
              line: 2
              column: 3
        start: 7
        end: 8
        range: [7, 8]
        loc:
          start:
            line: 2
            column: 2
          end:
            line: 2
            column: 3
      ,
        name:
          start: 11
          end: 12
          range: [11, 12]
          loc:
            start:
              line: 3
              column: 2
            end:
              line: 3
              column: 3
        value:
          start: 13
          end: 16
          range: [13, 16]
          loc:
            start:
              line: 3
              column: 4
            end:
              line: 3
              column: 7
        start: 11
        end: 16
        range: [11, 16]
        loc:
          start:
            line: 3
            column: 2
          end:
            line: 3
            column: 7
      ,
        name:
          start: 19
          end: 20
          range: [19, 20]
          loc:
            start:
              line: 4
              column: 2
            end:
              line: 4
              column: 3
        value:
          expression:
            start: 22
            end: 23
            range: [22, 23]
            loc:
              start:
                line: 4
                column: 5
              end:
                line: 4
                column: 6
          start: 21
          end: 24
          range: [21, 24]
          loc:
            start:
              line: 4
              column: 4
            end:
              line: 4
              column: 7
        start: 19
        end: 24
        range: [19, 24]
        loc:
          start:
            line: 4
            column: 2
          end:
            line: 4
            column: 7
      ,
        argument:
          start: 31
          end: 32
          range: [31, 32]
          loc:
            start:
              line: 5
              column: 6
            end:
              line: 5
              column: 7
        start: 27
        end: 33
        range: [27, 33]
        loc:
          start:
            line: 5
            column: 2
          end:
            line: 5
            column: 8
      ]
      start: 0
      end: 36
      range: [0, 36]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 6
          column: 2
    start: 0
    end: 36
    range: [0, 36]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 6
        column: 2

  testAstLocationData '<div {f...} />',
    type: 'JSXElement'
    openingElement:
      attributes: [
        argument:
          start: 6
          end: 7
          range: [6, 7]
          loc:
            start:
              line: 1
              column: 6
            end:
              line: 1
              column: 7
        start: 5
        end: 11
        range: [5, 11]
        loc:
          start:
            line: 1
            column: 5
          end:
            line: 1
            column: 11
      ]

  testAstLocationData '<div>abc</div>',
    type: 'JSXElement'
    openingElement:
      name:
        start: 1
        end: 4
        range: [1, 4]
        loc:
          start:
            line: 1
            column: 1
          end:
            line: 1
            column: 4
      start: 0
      end: 5
      range: [0, 5]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 5
    closingElement:
      name:
        start: 10
        end: 13
        range: [10, 13]
        loc:
          start:
            line: 1
            column: 10
          end:
            line: 1
            column: 13
      start: 8
      end: 14
      range: [8, 14]
      loc:
        start:
          line: 1
          column: 8
        end:
          line: 1
          column: 14
    children: [
      start: 5
      end: 8
      range: [5, 8]
      loc:
        start:
          line: 1
          column: 5
        end:
          line: 1
          column: 8
    ]
    start: 0
    end: 14
    range: [0, 14]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 14

  testAstLocationData '''
    <a>
      {b}
      <c />
    </a>
  ''',
    type: 'JSXElement'
    openingElement:
      name:
        start: 1
        end: 2
        range: [1, 2]
        loc:
          start:
            line: 1
            column: 1
          end:
            line: 1
            column: 2
      start: 0
      end: 3
      range: [0, 3]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 3
    closingElement:
      name:
        start: 20
        end: 21
        range: [20, 21]
        loc:
          start:
            line: 4
            column: 2
          end:
            line: 4
            column: 3
      start: 18
      end: 22
      range: [18, 22]
      loc:
        start:
          line: 4
          column: 0
        end:
          line: 4
          column: 4
    children: [
      start: 3
      end: 6
      range: [3, 6]
      loc:
        start:
          line: 1
          column: 3
        end:
          line: 2
          column: 2
    ,
      expression:
        start: 7
        end: 8
        range: [7, 8]
        loc:
          start:
            line: 2
            column: 3
          end:
            line: 2
            column: 4
      start: 6
      end: 9
      range: [6, 9]
      loc:
        start:
          line: 2
          column: 2
        end:
          line: 2
          column: 5
    ,
      start: 9
      end: 12
      range: [9, 12]
      loc:
        start:
          line: 2
          column: 5
        end:
          line: 3
          column: 2
    ,
      start: 12
      end: 17
      range: [12, 17]
      loc:
        start:
          line: 3
          column: 2
        end:
          line: 3
          column: 7
    ,
      start: 17
      end: 18
      range: [17, 18]
      loc:
        start:
          line: 3
          column: 7
        end:
          line: 4
          column: 0
    ]
    start: 0
    end: 22
    range: [0, 22]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 4
        column: 4

  testAstLocationData '<>abc{}</>',
    type: 'JSXFragment'
    openingFragment:
      start: 0
      end: 2
      range: [0, 2]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 2
    closingFragment:
      start: 7
      end: 10
      range: [7, 10]
      loc:
        start:
          line: 1
          column: 7
        end:
          line: 1
          column: 10
    children: [
      start: 2
      end: 5
      range: [2, 5]
      loc:
        start:
          line: 1
          column: 2
        end:
          line: 1
          column: 5
    ,
      expression:
        start: 6
        end: 6
        range: [6, 6]
        loc:
          start:
            line: 1
            column: 6
          end:
            line: 1
            column: 6
      start: 5
      end: 7
      range: [5, 7]
      loc:
        start:
          line: 1
          column: 5
        end:
          line: 1
          column: 7
    ]
    start: 0
    end: 10
    range: [0, 10]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 10

  testAstLocationData '''
    <a>{<b />}</a>
  ''',
    type: 'JSXElement'
    children: [
      expression:
        start: 4
        end: 9
        range: [4, 9]
        loc:
          start:
            line: 1
            column: 4
          end:
            line: 1
            column: 9
      start: 3
      end: 10
      range: [3, 10]
      loc:
        start:
          line: 1
          column: 3
        end:
          line: 1
          column: 10
    ]
    start: 0
    end: 14
    range: [0, 14]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 14

  testAstLocationData '''
    <div>{
      # comment
    }</div>
  ''',
    type: 'JSXElement'
    children: [
      expression:
        start: 6
        end: 19
        range: [6, 19]
        loc:
          start:
            line: 1
            column: 6
          end:
            line: 3
            column: 0
      start: 5
      end: 20
      range: [5, 20]
      loc:
        start:
          line: 1
          column: 5
        end:
          line: 3
          column: 1
    ]
    start: 0
    end: 26
    range: [0, 26]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 3
        column: 7

  testAstLocationData '''
    <div>{### here ###}</div>
  ''',
    type: 'JSXElement'
    children: [
      expression:
        start: 6
        end: 18
        range: [6, 18]
        loc:
          start:
            line: 1
            column: 6
          end:
            line: 1
            column: 18
      start: 5
      end: 19
      range: [5, 19]
      loc:
        start:
          line: 1
          column: 5
        end:
          line: 1
          column: 19
    ]
    start: 0
    end: 25
    range: [0, 25]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 25

  testAstLocationData '<div:a b:c />',
    type: 'JSXElement'
    openingElement:
      name:
        namespace:
          start: 1
          end: 4
          range: [1, 4]
          loc:
            start:
              line: 1
              column: 1
            end:
              line: 1
              column: 4
        name:
          start: 5
          end: 6
          range: [5, 6]
          loc:
            start:
              line: 1
              column: 5
            end:
              line: 1
              column: 6
        start: 1
        end: 6
        range: [1, 6]
        loc:
          start:
            line: 1
            column: 1
          end:
            line: 1
            column: 6
      attributes: [
        name:
          namespace:
            start: 7
            end: 8
            range: [7, 8]
            loc:
              start:
                line: 1
                column: 7
              end:
                line: 1
                column: 8
          name:
            start: 9
            end: 10
            range: [9, 10]
            loc:
              start:
                line: 1
                column: 9
              end:
                line: 1
                column: 10
          start: 7
          end: 10
          range: [7, 10]
          loc:
            start:
              line: 1
              column: 7
            end:
              line: 1
              column: 10
        start: 7
        end: 10
        range: [7, 10]
        loc:
          start:
            line: 1
            column: 7
          end:
            line: 1
            column: 10
      ]
      start: 0
      end: 13
      range: [0, 13]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 13
    start: 0
    end: 13
    range: [0, 13]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 13

  testAstLocationData '''
    <div:a>
      {b}
    </div:a>
  ''',
    type: 'JSXElement'
    openingElement:
      name:
        namespace:
          start: 1
          end: 4
          range: [1, 4]
          loc:
            start:
              line: 1
              column: 1
            end:
              line: 1
              column: 4
        name:
          start: 5
          end: 6
          range: [5, 6]
          loc:
            start:
              line: 1
              column: 5
            end:
              line: 1
              column: 6
        start: 1
        end: 6
        range: [1, 6]
        loc:
          start:
            line: 1
            column: 1
          end:
            line: 1
            column: 6
      start: 0
      end: 7
      range: [0, 7]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 7
    closingElement:
      name:
        namespace:
          start: 16
          end: 19
          range: [16, 19]
          loc:
            start:
              line: 3
              column: 2
            end:
              line: 3
              column: 5
        name:
          start: 20
          end: 21
          range: [20, 21]
          loc:
            start:
              line: 3
              column: 6
            end:
              line: 3
              column: 7
        start: 16
        end: 21
        range: [16, 21]
        loc:
          start:
            line: 3
            column: 2
          end:
            line: 3
            column: 7
      start: 14
      end: 22
      range: [14, 22]
      loc:
        start:
          line: 3
          column: 0
        end:
          line: 3
          column: 8
    start: 0
    end: 22
    range: [0, 22]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 3
        column: 8

  testAstLocationData '''
    <div.a>
      {b}
    </div.a>
  ''',
    type: 'JSXElement'
    openingElement:
      name:
        object:
          start: 1
          end: 4
          range: [1, 4]
          loc:
            start:
              line: 1
              column: 1
            end:
              line: 1
              column: 4
        property:
          start: 5
          end: 6
          range: [5, 6]
          loc:
            start:
              line: 1
              column: 5
            end:
              line: 1
              column: 6
        start: 1
        end: 6
        range: [1, 6]
        loc:
          start:
            line: 1
            column: 1
          end:
            line: 1
            column: 6
      start: 0
      end: 7
      range: [0, 7]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 7
    closingElement:
      name:
        object:
          start: 16
          end: 19
          range: [16, 19]
          loc:
            start:
              line: 3
              column: 2
            end:
              line: 3
              column: 5
        property:
          start: 20
          end: 21
          range: [20, 21]
          loc:
            start:
              line: 3
              column: 6
            end:
              line: 3
              column: 7
        start: 16
        end: 21
        range: [16, 21]
        loc:
          start:
            line: 3
            column: 2
          end:
            line: 3
            column: 7
      start: 14
      end: 22
      range: [14, 22]
      loc:
        start:
          line: 3
          column: 0
        end:
          line: 3
          column: 8
    start: 0
    end: 22
    range: [0, 22]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 3
        column: 8

test "AST as expected for Try node", ->
  testAstLocationData 'try cappuccino',
    type: 'TryStatement'
    block:
      type: 'BlockStatement'
      body: [
        expression:
          start: 4
          end: 14
          range: [4, 14]
          loc:
            start:
              line: 1
              column: 4
            end:
              line: 1
              column: 14
        start: 4
        end: 14
        range: [4, 14]
        loc:
          start:
            line: 1
            column: 4
          end:
            line: 1
            column: 14
      ]
      start: 3
      end: 14
      range: [3, 14]
      loc:
        start:
          line: 1
          column: 3
        end:
          line: 1
          column: 14
    start: 0
    end: 14
    range: [0, 14]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 14

  testAstLocationData '''
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
        expression:
          start: 6
          end: 11
          range: [6, 11]
          loc:
            start:
              line: 2
              column: 2
            end:
              line: 2
              column: 7
        start: 6
        end: 11
        range: [6, 11]
        loc:
          start:
            line: 2
            column: 2
          end:
            line: 2
            column: 7
      ,
        expression:
          start: 14
          end: 17
          range: [14, 17]
          loc:
            start:
              line: 3
              column: 2
            end:
              line: 3
              column: 5
        start: 14
        end: 17
        range: [14, 17]
        loc:
          start:
            line: 3
            column: 2
          end:
            line: 3
            column: 5
      ]
      start: 4
      end: 17
      range: [4, 17]
      loc:
        start:
          line: 2
          column: 0
        end:
          line: 3
          column: 5
    handler:
      param:
        start: 24
        end: 25
        range: [24, 25]
        loc:
          start:
            line: 4
            column: 6
          end:
            line: 4
            column: 7
      body:
        body: [
          start: 28
          end: 31
          range: [28, 31]
          loc:
            start:
              line: 5
              column: 2
            end:
              line: 5
              column: 5
        ]
        start: 26
        end: 31
        range: [26, 31]
        loc:
          start:
            line: 5
            column: 0
          end:
            line: 5
            column: 5
      start: 18
      end: 31
      range: [18, 31]
      loc:
        start:
          line: 4
          column: 0
        end:
          line: 5
          column: 5
    finalizer:
      body: [
        expression:
          start: 42
          end: 47
          range: [42, 47]
          loc:
            start:
              line: 7
              column: 2
            end:
              line: 7
              column: 7
        start: 42
        end: 47
        range: [42, 47]
        loc:
          start:
            line: 7
            column: 2
          end:
            line: 7
            column: 7
      ]
      start: 32
      end: 47
      range: [32, 47]
      loc:
        start:
          line: 6
          column: 0
        end:
          line: 7
          column: 7
    start: 0
    end: 47
    range: [0, 47]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 7
        column: 7

  testAstLocationData '''
    try
    catch {e}
      f
  ''',
    type: 'TryStatement'
    handler:
      param:
        start: 10
        end: 13
        range: [10, 13]
        loc:
          start:
            line: 2
            column: 6
          end:
            line: 2
            column: 9
      body:
        start: 14
        end: 17
        range: [14, 17]
        loc:
          start:
            line: 3
            column: 0
          end:
            line: 3
            column: 3
      start: 4
      end: 17
      range: [4, 17]
      loc:
        start:
          line: 2
          column: 0
        end:
          line: 3
          column: 3

test "AST location data as expected for Root node", ->
  testAstRootLocationData '1\n2',
    type: 'File'
    program:
      start: 0
      end: 3
      range: [0, 3]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 2
          column: 1
    start: 0
    end: 3
    range: [0, 3]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 2
        column: 1

  testAstRootLocationData 'a = 1\nb',
    type: 'File'
    program:
      start: 0
      end: 7
      range: [0, 7]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 2
          column: 1
    start: 0
    end: 7
    range: [0, 7]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 2
        column: 1

  testAstRootLocationData 'a = 1\nb\n\n',
    type: 'File'
    program:
      start: 0
      end: 9
      range: [0, 9]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 4
          column: 0
    start: 0
    end: 9
    range: [0, 9]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 4
        column: 0

  testAstRootLocationData 'a = 1\n\n# Comment',
    type: 'File'
    program:
      start: 0
      end: 16
      range: [0, 16]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 3
          column: 9
    start: 0
    end: 16
    range: [0, 16]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 3
        column: 9

  testAstRootLocationData 'a = 1\n\n# Comment\n',
    type: 'File'
    program:
      start: 0
      end: 17
      range: [0, 17]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 4
          column: 0
    start: 0
    end: 17
    range: [0, 17]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 4
        column: 0

  testAstRootLocationData '''
    # comment
    "use strict"
  ''',
    type: 'File'
    program:
      start: 0
      end: 22
      range: [0, 22]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 2
          column: 12
    start: 0
    end: 22
    range: [0, 22]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 2
        column: 12

  testAstRootLocationData ' \n',
    type: 'File'
    program:
      start: 0
      end: 2
      range: [0, 2]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 2
          column: 0
    start: 0
    end: 2
    range: [0, 2]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 2
        column: 0

  testAstRootLocationData '\n',
    type: 'File'
    program:
      start: 0
      end: 1
      range: [0, 1]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 2
          column: 0
    start: 0
    end: 1
    range: [0, 1]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 2
        column: 0

  testAstRootLocationData '',
    type: 'File'
    program:
      start: 0
      end: 0
      range: [0, 0]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 0
    start: 0
    end: 0
    range: [0, 0]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 0

  testAstRootLocationData ' ',
    type: 'File'
    program:
      start: 0
      end: 1
      range: [0, 1]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 1
    start: 0
    end: 1
    range: [0, 1]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 1

test "AST location data as expected for Switch node", ->
  testAstLocationData '''
    switch x
      when a then a
      when b, c then c
      else 42
  ''',
    type: 'SwitchStatement'
    discriminant:
      start: 7
      end: 8
      range: [7, 8]
      loc:
        start:
          line: 1
          column: 7
        end:
          line: 1
          column: 8
    cases: [
      test:
        start: 16
        end: 17
        range: [16, 17]
        loc:
          start:
            line: 2
            column: 7
          end:
            line: 2
            column: 8
      consequent: [
        expression:
          start: 23
          end: 24
          range: [23, 24]
          loc:
            start:
              line: 2
              column: 14
            end:
              line: 2
              column: 15
        start: 23
        end: 24
        range: [23, 24]
        loc:
          start:
            line: 2
            column: 14
          end:
            line: 2
            column: 15
      ]
      start: 11
      end: 24
      range: [11, 24]
      loc:
        start:
          line: 2
          column: 2
        end:
          line: 2
          column: 15
    ,
      test:
        start: 32
        end: 33
        range: [32, 33]
        loc:
          start:
            line: 3
            column: 7
          end:
            line: 3
            column: 8
      start: 27
      end: 33
      range: [27, 33]
      loc:
        start:
          line: 3
          column: 2
        end:
          line: 3
          column: 8
    ,
      test:
        start: 35
        end: 36
        range: [35, 36]
        loc:
          start:
            line: 3
            column: 10
          end:
            line: 3
            column: 11
      consequent: [
        expression:
          start: 42
          end: 43
          range: [42, 43]
          loc:
            start:
              line: 3
              column: 17
            end:
              line: 3
              column: 18
        start: 42
        end: 43
        range: [42, 43]
        loc:
          start:
            line: 3
            column: 17
          end:
            line: 3
            column: 18
      ]
      start: 35
      end: 43
      range: [35, 43]
      loc:
        start:
          line: 3
          column: 10
        end:
          line: 3
          column: 18
    ,
      consequent: [
        expression:
          start: 51
          end: 53
          range: [51, 53]
          loc:
            start:
              line: 4
              column: 7
            end:
              line: 4
              column: 9
        start: 51
        end: 53
        range: [51, 53]
        loc:
          start:
            line: 4
            column: 7
          end:
            line: 4
            column: 9
      ]
      start: 46
      end: 53
      range: [46, 53]
      loc:
        start:
          line: 4
          column: 2
        end:
          line: 4
          column: 9
    ,
    ]
    start: 0
    end: 53
    range: [0, 53]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 4
        column: 9

  testAstLocationData '''
    switch
      when some(condition)
        doSomething()
        andThenSomethingElse
  ''',
    type: 'SwitchStatement'
    cases: [
      test:
        start: 14
        end: 29
        range: [14, 29]
        loc:
          start:
            line: 2
            column: 7
          end:
            line: 2
            column: 22
      consequent: [
        expression:
          start: 34
          end: 47
          range: [34, 47]
          loc:
            start:
              line: 3
              column: 4
            end:
              line: 3
              column: 17
        start: 34
        end: 47
        range: [34, 47]
        loc:
          start:
            line: 3
            column: 4
          end:
            line: 3
            column: 17
      ,
        expression:
          start: 52
          end: 72
          range: [52, 72]
          loc:
            start:
              line: 4
              column: 4
            end:
              line: 4
              column: 24
      ]
    ]
test "AST location data as expected for Code node", ->
  testAstLocationData '''
    (a) ->
      b
      c()
  ''',
    type: 'FunctionExpression'
    params: [
      start: 1
      end: 2
      range: [1, 2]
      loc:
        start:
          line: 1
          column: 1
        end:
          line: 1
          column: 2
    ]
    body:
      body: [
        start: 9
        end: 10
        range: [9, 10]
        loc:
          start:
            line: 2
            column: 2
          end:
            line: 2
            column: 3
      ,
        start: 13
        end: 16
        range: [13, 16]
        loc:
          start:
            line: 3
            column: 2
          end:
            line: 3
            column: 5
      ]
      start: 7
      end: 16
      range: [7, 16]
      loc:
        start:
          line: 2
          column: 0
        end:
          line: 3
          column: 5

  testAstLocationData '''
    -> a
  ''',
    type: 'FunctionExpression'
    body:
      start: 2
      end: 4
      range: [2, 4]
      loc:
        start:
          line: 1
          column: 2
        end:
          line: 1
          column: 4
    start: 0
    end: 4
    range: [0, 4]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 4

  testAstLocationData '''
    (
      a,
      [
        b
        c
      ]
    ) ->
      d
  ''',
    type: 'FunctionExpression'
    params: [
      start: 4
      end: 5
      range: [4, 5]
      loc:
        start:
          line: 2
          column: 2
        end:
          line: 2
          column: 3
    ,
      elements: [
        start: 15
        end: 16
        range: [15, 16]
        loc:
          start:
            line: 4
            column: 4
          end:
            line: 4
            column: 5
      ,
        start: 21
        end: 22
        range: [21, 22]
        loc:
          start:
            line: 5
            column: 4
          end:
            line: 5
            column: 5
      ]
      start: 9
      end: 26
      range: [9, 26]
      loc:
        start:
          line: 3
          column: 2
        end:
          line: 6
          column: 3
    ]
    start: 0
    end: 35
    range: [0, 35]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 8
        column: 3

  testAstLocationData '''
    ->
  ''',
    type: 'FunctionExpression'
    body:
      start: 2
      end: 2
      range: [2, 2]
      loc:
        start:
          line: 1
          column: 2
        end:
          line: 1
          column: 2
    start: 0
    end: 2
    range: [0, 2]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 2

  testAstLocationData '''
    (a...) ->
  ''',
    type: 'FunctionExpression'
    params: [
      argument:
        start: 1
        end: 2
        range: [1, 2]
        loc:
          start:
            line: 1
            column: 1
          end:
            line: 1
            column: 2
      start: 1
      end: 5
      range: [1, 5]
      loc:
        start:
          line: 1
          column: 1
        end:
          line: 1
          column: 5
    ]
    start: 0
    end: 9
    range: [0, 9]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 9

  testAstLocationData '''
    (...a) ->
  ''',
    type: 'FunctionExpression'
    params: [
      argument:
        start: 4
        end: 5
        range: [4, 5]
        loc:
          start:
            line: 1
            column: 4
          end:
            line: 1
            column: 5
      start: 1
      end: 5
      range: [1, 5]
      loc:
        start:
          line: 1
          column: 1
        end:
          line: 1
          column: 5
    ]
    start: 0
    end: 9
    range: [0, 9]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 9

test "AST location data as expected for Return node", ->
  testAstLocationData 'return no',
    type: 'ReturnStatement'
    argument:
      start: 7
      end: 9
      range: [7, 9]
      loc:
        start:
          line: 1
          column: 7
        end:
          line: 1
          column: 9
    start: 0
    end: 9
    range: [0, 9]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 9

  testAstLocationData '''
    (a, b) ->
      return a + b
  ''',
    type: 'FunctionExpression'
    body:
      body: [
        argument:
          start: 19
          end: 24
          range: [19, 24]
          loc:
            start:
              line: 2
              column: 9
            end:
              line: 2
              column: 14
        start: 12
        end: 24
        range: [12, 24]
        loc:
          start:
            line: 2
            column: 2
          end:
            line: 2
            column: 14
      ]
      start: 10
      end: 24
      range: [10, 24]
      loc:
        start:
          line: 2
          column: 0
        end:
          line: 2
          column: 14
    start: 0
    end: 24
    range: [0, 24]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 2
        column: 14

  testAstLocationData '-> return',
    type: 'FunctionExpression'
    body:
      body: [
        start: 3
        end: 9
        range: [3, 9]
        loc:
          start:
            line: 1
            column: 3
          end:
            line: 1
            column: 9
      ]
      start: 2
      end: 9
      range: [2, 9]
      loc:
        start:
          line: 1
          column: 2
        end:
          line: 1
          column: 9
    start: 0
    end: 9
    range: [0, 9]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 9

test "AST as expected for YieldReturn node", ->
  testAstLocationData '-> yield return 1',
    type: 'FunctionExpression'
    body:
      body: [
        expression:
          argument:
            argument:
              start: 16
              end: 17
              range: [16, 17]
              loc:
                start:
                  line: 1
                  column: 16
                end:
                  line: 1
                  column: 17
            start: 9
            end: 17
            range: [9, 17]
            loc:
              start:
                line: 1
                column: 9
              end:
                line: 1
                column: 17
          start: 3
          end: 17
          range: [3, 17]
          loc:
            start:
              line: 1
              column: 3
            end:
              line: 1
              column: 17
        start: 3
        end: 17
        range: [3, 17]
        loc:
          start:
            line: 1
            column: 3
          end:
            line: 1
            column: 17
      ]
      start: 2
      end: 17
      range: [2, 17]
      loc:
        start:
          line: 1
          column: 2
        end:
          line: 1
          column: 17
    start: 0
    end: 17
    range: [0, 17]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 17

  testAstLocationData '-> yield return',
    type: 'FunctionExpression'
    body:
      body: [
        expression:
          argument:
            start: 9
            end: 15
            range: [9, 15]
            loc:
              start:
                line: 1
                column: 9
              end:
                line: 1
                column: 15
          start: 3
          end: 15
          range: [3, 15]
          loc:
            start:
              line: 1
              column: 3
            end:
              line: 1
              column: 15
        start: 3
        end: 15
        range: [3, 15]
        loc:
          start:
            line: 1
            column: 3
          end:
            line: 1
            column: 15
      ]
      start: 2
      end: 15
      range: [2, 15]
      loc:
        start:
          line: 1
          column: 2
        end:
          line: 1
          column: 15
    start: 0
    end: 15
    range: [0, 15]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 15

test "AST as expected for AwaitReturn node", ->
  testAstLocationData '-> await return 1',
    type: 'FunctionExpression'
    body:
      body: [
        expression:
          argument:
            argument:
              start: 16
              end: 17
              range: [16, 17]
              loc:
                start:
                  line: 1
                  column: 16
                end:
                  line: 1
                  column: 17
            start: 9
            end: 17
            range: [9, 17]
            loc:
              start:
                line: 1
                column: 9
              end:
                line: 1
                column: 17
          start: 3
          end: 17
          range: [3, 17]
          loc:
            start:
              line: 1
              column: 3
            end:
              line: 1
              column: 17
        start: 3
        end: 17
        range: [3, 17]
        loc:
          start:
            line: 1
            column: 3
          end:
            line: 1
            column: 17
      ]
      start: 2
      end: 17
      range: [2, 17]
      loc:
        start:
          line: 1
          column: 2
        end:
          line: 1
          column: 17
    start: 0
    end: 17
    range: [0, 17]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 17

  testAstLocationData '-> await return',
    type: 'FunctionExpression'
    body:
      body: [
        expression:
          argument:
            start: 9
            end: 15
            range: [9, 15]
            loc:
              start:
                line: 1
                column: 9
              end:
                line: 1
                column: 15
          start: 3
          end: 15
          range: [3, 15]
          loc:
            start:
              line: 1
              column: 3
            end:
              line: 1
              column: 15
        start: 3
        end: 15
        range: [3, 15]
        loc:
          start:
            line: 1
            column: 3
          end:
            line: 1
            column: 15
      ]
      start: 2
      end: 15
      range: [2, 15]
      loc:
        start:
          line: 1
          column: 2
        end:
          line: 1
          column: 15
    start: 0
    end: 15
    range: [0, 15]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 15

test "AST as expected for If node", ->
  testAstLocationData 'if maybe then yes',
    type: 'IfStatement'
    test:
      start: 3
      end: 8
      range: [3, 8]
      loc:
        start:
          line: 1
          column: 3
        end:
          line: 1
          column: 8
    consequent:
      body: [
        expression:
          start: 14
          end: 17
          range: [14, 17]
          loc:
            start:
              line: 1
              column: 14
            end:
              line: 1
              column: 17
        start: 14
        end: 17
        range: [14, 17]
        loc:
          start:
            line: 1
            column: 14
          end:
            line: 1
            column: 17
      ]
      start: 9
      end: 17
      range: [9, 17]
      loc:
        start:
          line: 1
          column: 9
        end:
          line: 1
          column: 17
    start: 0
    end: 17
    range: [0, 17]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 17

  testAstLocationData 'yes if maybe',
    type: 'IfStatement'
    test:
      start: 7
      end: 12
      range: [7, 12]
      loc:
        start:
          line: 1
          column: 7
        end:
          line: 1
          column: 12
    consequent:
      body: [
        expression:
          start: 0
          end: 3
          range: [0, 3]
          loc:
            start:
              line: 1
              column: 0
            end:
              line: 1
              column: 3
        start: 0
        end: 3
        range: [0, 3]
        loc:
          start:
            line: 1
            column: 0
          end:
            line: 1
            column: 3
      ]
      start: 0
      end: 3
      range: [0, 3]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 3
    start: 0
    end: 12
    range: [0, 12]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 12

  testAstLocationData 'unless x then x else if y then y else z',
    type: 'IfStatement'
    test:
      start: 7
      end: 8
      range: [7, 8]
      loc:
        start:
          line: 1
          column: 7
        end:
          line: 1
          column: 8
    consequent:
      body: [
        expression:
          start: 14
          end: 15
          range: [14, 15]
          loc:
            start:
              line: 1
              column: 14
            end:
              line: 1
              column: 15
        start: 14
        end: 15
        range: [14, 15]
        loc:
          start:
            line: 1
            column: 14
          end:
            line: 1
            column: 15
      ]
      start: 9
      end: 15
      range: [9, 15]
      loc:
        start:
          line: 1
          column: 9
        end:
          line: 1
          column: 15
    alternate:
      test:
        start: 24
        end: 25
        range: [24, 25]
        loc:
          start:
            line: 1
            column: 24
          end:
            line: 1
            column: 25
      consequent:
        body: [
          expression:
            start: 31
            end: 32
            range: [31, 32]
            loc:
              start:
                line: 1
                column: 31
              end:
                line: 1
                column: 32
          start: 31
          end: 32
          range: [31, 32]
          loc:
            start:
              line: 1
              column: 31
            end:
              line: 1
              column: 32
        ]
        start: 26
        end: 32
        range: [26, 32]
        loc:
          start:
            line: 1
            column: 26
          end:
            line: 1
            column: 32
      alternate:
        body: [
          expression:
            start: 38
            end: 39
            range: [38, 39]
            loc:
              start:
                line: 1
                column: 38
              end:
                line: 1
                column: 39
          start: 38
          end: 39
          range: [38, 39]
          loc:
            start:
              line: 1
              column: 38
            end:
              line: 1
              column: 39
        ]
        start: 37
        end: 39
        range: [37, 39]
        loc:
          start:
            line: 1
            column: 37
          end:
            line: 1
            column: 39
      start: 21
      end: 39
      range: [21, 39]
      loc:
        start:
          line: 1
          column: 21
        end:
          line: 1
          column: 39
    start: 0
    end: 39
    range: [0, 39]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 39

  testAstLocationData '''
    if a
      b
    else
      if c
        d
  ''',
    type: 'IfStatement'
    test:
      start: 3
      end: 4
      range: [3, 4]
      loc:
        start:
          line: 1
          column: 3
        end:
          line: 1
          column: 4
    consequent:
      body: [
        expression:
          start: 7
          end: 8
          range: [7, 8]
          loc:
            start:
              line: 2
              column: 2
            end:
              line: 2
              column: 3
        start: 7
        end: 8
        range: [7, 8]
        loc:
          start:
            line: 2
            column: 2
          end:
            line: 2
            column: 3
      ]
      start: 5
      end: 8
      range: [5, 8]
      loc:
        start:
          line: 2
          column: 0
        end:
          line: 2
          column: 3
    alternate:
      body: [
        test:
          start: 19
          end: 20
          range: [19, 20]
          loc:
            start:
              line: 4
              column: 5
            end:
              line: 4
              column: 6
        consequent:
          body: [
            expression:
              start: 25
              end: 26
              range: [25, 26]
              loc:
                start:
                  line: 5
                  column: 4
                end:
                  line: 5
                  column: 5
            start: 25
            end: 26
            range: [25, 26]
            loc:
              start:
                line: 5
                column: 4
              end:
                line: 5
                column: 5
          ]
          start: 21
          end: 26
          range: [21, 26]
          loc:
            start:
              line: 5
              column: 0
            end:
              line: 5
              column: 5
        start: 16
        end: 26
        range: [16, 26]
        loc:
          start:
            line: 4
            column: 2
          end:
            line: 5
            column: 5
      ]
      start: 14
      end: 26
      range: [14, 26]
      loc:
        start:
          line: 4
          column: 0
        end:
          line: 5
          column: 5
    start: 0
    end: 26
    range: [0, 26]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 5
        column: 5

  testAstLocationData '''
    a =
      if b then c else if d then e
  ''',
    type: 'AssignmentExpression'
    right:
      test:
        start: 9
        end: 10
        range: [9, 10]
        loc:
          start:
            line: 2
            column: 5
          end:
            line: 2
            column: 6
      consequent:
        start: 16
        end: 17
        range: [16, 17]
        loc:
          start:
            line: 2
            column: 12
          end:
            line: 2
            column: 13
      alternate:
        test:
          start: 26
          end: 27
          range: [26, 27]
          loc:
            start:
              line: 2
              column: 22
            end:
              line: 2
              column: 23
        consequent:
          start: 33
          end: 34
          range: [33, 34]
          loc:
            start:
              line: 2
              column: 29
            end:
              line: 2
              column: 30
        start: 23
        end: 34
        range: [23, 34]
        loc:
          start:
            line: 2
            column: 19
          end:
            line: 2
            column: 30
      start: 6
      end: 34
      range: [6, 34]
      loc:
        start:
          line: 2
          column: 2
        end:
          line: 2
          column: 30
    start: 0
    end: 34
    range: [0, 34]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 2
        column: 30

  testAstLocationData '''
    f(
      if b
        c
        d
    )
  ''',
    type: 'CallExpression'
    arguments: [
      test:
        start: 8
        end: 9
        range: [8, 9]
        loc:
          start:
            line: 2
            column: 5
          end:
            line: 2
            column: 6
      consequent:
        body: [
          expression:
            start: 14
            end: 15
            range: [14, 15]
            loc:
              start:
                line: 3
                column: 4
              end:
                line: 3
                column: 5
          start: 14
          end: 15
          range: [14, 15]
          loc:
            start:
              line: 3
              column: 4
            end:
              line: 3
              column: 5
        ,
          expression:
            start: 20
            end: 21
            range: [20, 21]
            loc:
              start:
                line: 4
                column: 4
              end:
                line: 4
                column: 5
          start: 20
          end: 21
          range: [20, 21]
          loc:
            start:
              line: 4
              column: 4
            end:
              line: 4
              column: 5
        ]
        start: 10
        end: 21
        range: [10, 21]
        loc:
          start:
            line: 3
            column: 0
          end:
            line: 4
            column: 5
    ]
    start: 0
    end: 23
    range: [0, 23]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 5
        column: 1

test "AST as expected for While node", ->
  testAstLocationData 'loop 1',
    type: 'WhileStatement'
    test:
      start: 0
      end: 4
      range: [0, 4]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 4
    body:
      body: [
        expression:
          start: 5
          end: 6
          range: [5, 6]
          loc:
            start:
              line: 1
              column: 5
            end:
              line: 1
              column: 6
        start: 5
        end: 6
        range: [5, 6]
        loc:
          start:
            line: 1
            column: 5
          end:
            line: 1
            column: 6
      ]
      start: 5
      end: 6
      range: [5, 6]
      loc:
        start:
          line: 1
          column: 5
        end:
          line: 1
          column: 6
    start: 0
    end: 6
    range: [0, 6]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 6

  testAstLocationData 'while 1 < 2 then',
    type: 'WhileStatement'
    test:
      start: 6
      end: 11
      range: [6, 11]
      loc:
        start:
          line: 1
          column: 6
        end:
          line: 1
          column: 11
    body:
      start: 12
      end: 16
      range: [12, 16]
      loc:
        start:
          line: 1
          column: 12
        end:
          line: 1
          column: 16
    start: 0
    end: 16
    range: [0, 16]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 16

  testAstLocationData 'while 1 < 2 then fn()',
    type: 'WhileStatement'
    test:
      start: 6
      end: 11
      range: [6, 11]
      loc:
        start:
          line: 1
          column: 6
        end:
          line: 1
          column: 11
    body:
      body: [
        expression:
          start: 17
          end: 21
          range: [17, 21]
          loc:
            start:
              line: 1
              column: 17
            end:
              line: 1
              column: 21
        start: 17
        end: 21
        range: [17, 21]
        loc:
          start:
            line: 1
            column: 17
          end:
            line: 1
            column: 21
      ]
      start: 12
      end: 21
      range: [12, 21]
      loc:
        start:
          line: 1
          column: 12
        end:
          line: 1
          column: 21
    start: 0
    end: 21
    range: [0, 21]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 21


  testAstLocationData '''
    x() until y
  ''',
    type: 'WhileStatement'
    test:
      start: 10
      end: 11
      range: [10, 11]
      loc:
        start:
          line: 1
          column: 10
        end:
          line: 1
          column: 11
    body:
      body: [
        expression:
          start: 0
          end: 3
          range: [0, 3]
          loc:
            start:
              line: 1
              column: 0
            end:
              line: 1
              column: 3
        start: 0
        end: 3
        range: [0, 3]
        loc:
          start:
            line: 1
            column: 0
          end:
            line: 1
            column: 3
      ]
      start: 0
      end: 3
      range: [0, 3]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 3
    start: 0
    end: 11
    range: [0, 11]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 11

  testAstLocationData '''
    until x when y
      z++
  ''',
    type: 'WhileStatement'
    test:
      start: 6
      end: 7
      range: [6, 7]
      loc:
        start:
          line: 1
          column: 6
        end:
          line: 1
          column: 7
    body:
      body: [
        expression:
          start: 17
          end: 20
          range: [17, 20]
          loc:
            start:
              line: 2
              column: 2
            end:
              line: 2
              column: 5
        start: 17
        end: 20
        range: [17, 20]
        loc:
          start:
            line: 2
            column: 2
          end:
            line: 2
            column: 5
      ]
      start: 15
      end: 20
      range: [15, 20]
      loc:
        start:
          line: 2
          column: 0
        end:
          line: 2
          column: 5
    guard:
      start: 13
      end: 14
      range: [13, 14]
      loc:
        start:
          line: 1
          column: 13
        end:
          line: 1
          column: 14
    start: 0
    end: 20
    range: [0, 20]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 2
        column: 5

  testAstLocationData '''
    x while y when z
  ''',
    type: 'WhileStatement'
    test:
      start: 8
      end: 9
      range: [8, 9]
      loc:
        start:
          line: 1
          column: 8
        end:
          line: 1
          column: 9
    body:
      body: [
        expression:
          start: 0
          end: 1
          range: [0, 1]
          loc:
            start:
              line: 1
              column: 0
            end:
              line: 1
              column: 1
        start: 0
        end: 1
        range: [0, 1]
        loc:
          start:
            line: 1
            column: 0
          end:
            line: 1
            column: 1
      ]
      start: 0
      end: 1
      range: [0, 1]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 1
    guard:
      start: 15
      end: 16
      range: [15, 16]
      loc:
        start:
          line: 1
          column: 15
        end:
          line: 1
          column: 16
    start: 0
    end: 16
    range: [0, 16]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 16

  testAstLocationData '''
    loop
      a()
      b++
  ''',
    type: 'WhileStatement'
    test:
      start: 0
      end: 4
      range: [0, 4]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 4
    body:
      body: [
        expression:
          start: 7
          end: 10
          range: [7, 10]
          loc:
            start:
              line: 2
              column: 2
            end:
              line: 2
              column: 5
        start: 7
        end: 10
        range: [7, 10]
        loc:
          start:
            line: 2
            column: 2
          end:
            line: 2
            column: 5
      ,
        expression:
          start: 13
          end: 16
          range: [13, 16]
          loc:
            start:
              line: 3
              column: 2
            end:
              line: 3
              column: 5
        start: 13
        end: 16
        range: [13, 16]
        loc:
          start:
            line: 3
            column: 2
          end:
            line: 3
            column: 5
      ]
      start: 5
      end: 16
      range: [5, 16]
      loc:
        start:
          line: 2
          column: 0
        end:
          line: 3
          column: 5
    start: 0
    end: 16
    range: [0, 16]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 3
        column: 5

test "AST location data as expected for MetaProperty node", ->
  testAstLocationData '''
    -> new.target
  ''',
    type: 'FunctionExpression'
    body:
      body: [
        expression:
          meta:
            start: 3
            end: 6
            range: [3, 6]
            loc:
              start:
                line: 1
                column: 3
              end:
                line: 1
                column: 6
          property:
            start: 7
            end: 13
            range: [7, 13]
            loc:
              start:
                line: 1
                column: 7
              end:
                line: 1
                column: 13
          start: 3
          end: 13
          range: [3, 13]
          loc:
            start:
              line: 1
              column: 3
            end:
              line: 1
              column: 13
      ]
    start: 0
    end: 13
    range: [0, 13]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 13

test "AST location data as expected for For node", ->
  testAstLocationData 'for x, i in arr when x? then return',
    type: 'For'
    name:
      start: 4
      end: 5
      range: [4, 5]
      loc:
        start:
          line: 1
          column: 4
        end:
          line: 1
          column: 5
    index:
      start: 7
      end: 8
      range: [7, 8]
      loc:
        start:
          line: 1
          column: 7
        end:
          line: 1
          column: 8
    guard:
      start: 21
      end: 23
      range: [21, 23]
      loc:
        start:
          line: 1
          column: 21
        end:
          line: 1
          column: 23
    source:
      start: 12
      end: 15
      range: [12, 15]
      loc:
        start:
          line: 1
          column: 12
        end:
          line: 1
          column: 15
    body:
      body: [
        start: 29
        end: 35
        range: [29, 35]
        loc:
          start:
            line: 1
            column: 29
          end:
            line: 1
            column: 35
      ]
      start: 24
      end: 35
      range: [24, 35]
      loc:
        start:
          line: 1
          column: 24
        end:
          line: 1
          column: 35
    start: 0
    end: 35
    range: [0, 35]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 35

  testAstLocationData 'a = (x for x in y)',
    type: 'AssignmentExpression'
    right:
      name:
        start: 11
        end: 12
        range: [11, 12]
        loc:
          start:
            line: 1
            column: 11
          end:
            line: 1
            column: 12
      body:
        start: 5
        end: 6
        range: [5, 6]
        loc:
          start:
            line: 1
            column: 5
          end:
            line: 1
            column: 6
      source:
        start: 16
        end: 17
        range: [16, 17]
        loc:
          start:
            line: 1
            column: 16
          end:
            line: 1
            column: 17
      start: 5
      end: 17
      range: [5, 17]
      loc:
        start:
          line: 1
          column: 5
        end:
          line: 1
          column: 17
    start: 0
    end: 18
    range: [0, 18]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 18

  testAstLocationData 'x for [0...1]',
    type: 'For'
    body:
      start: 0
      end: 1
      range: [0, 1]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 1
    source:
      start: 6
      end: 13
      range: [6, 13]
      loc:
        start:
          line: 1
          column: 6
        end:
          line: 1
          column: 13
    start: 0
    end: 13
    range: [0, 13]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 13

  testAstLocationData '''
    for own x, y of z
      c()
      d
  ''',
    type: 'For'
    name:
      start: 11
      end: 12
      range: [11, 12]
      loc:
        start:
          line: 1
          column: 11
        end:
          line: 1
          column: 12
    index:
      start: 8
      end: 9
      range: [8, 9]
      loc:
        start:
          line: 1
          column: 8
        end:
          line: 1
          column: 9
    body:
      body: [
        start: 20
        end: 23
        range: [20, 23]
        loc:
          start:
            line: 2
            column: 2
          end:
            line: 2
            column: 5
      ,
        start: 26
        end: 27
        range: [26, 27]
        loc:
          start:
            line: 3
            column: 2
          end:
            line: 3
            column: 3
      ]
      start: 18
      end: 27
      range: [18, 27]
      loc:
        start:
          line: 2
          column: 0
        end:
          line: 3
          column: 3
    source:
      start: 16
      end: 17
      range: [16, 17]
      loc:
        start:
          line: 1
          column: 16
        end:
          line: 1
          column: 17
    start: 0
    end: 27
    range: [0, 27]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 3
        column: 3

  testAstLocationData '''
    ->
      for await x from y
        z
  ''',
    type: 'FunctionExpression'
    body:
      body: [
        name:
          start: 15
          end: 16
          range: [15, 16]
          loc:
            start:
              line: 2
              column: 12
            end:
              line: 2
              column: 13
        body:
          body: [
            start: 28
            end: 29
            range: [28, 29]
            loc:
              start:
                line: 3
                column: 4
              end:
                line: 3
                column: 5
          ]
          start: 24
          end: 29
          range: [24, 29]
          loc:
            start:
              line: 3
              column: 0
            end:
              line: 3
              column: 5
        source:
          start: 22
          end: 23
          range: [22, 23]
          loc:
            start:
              line: 2
              column: 19
            end:
              line: 2
              column: 20
        start: 5
        end: 29
        range: [5, 29]
        loc:
          start:
            line: 2
            column: 2
          end:
            line: 3
            column: 5
      ]
      start: 3
      end: 29
      range: [3, 29]
      loc:
        start:
          line: 2
          column: 0
        end:
          line: 3
          column: 5
    start: 0
    end: 29
    range: [0, 29]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 3
        column: 5

  testAstLocationData '''
    for {x} in y
      z
  ''',
    type: 'For'
    name:
      properties: [
        start: 5
        end: 6
        range: [5, 6]
        loc:
          start:
            line: 1
            column: 5
          end:
            line: 1
            column: 6
      ]
      start: 4
      end: 7
      range: [4, 7]
      loc:
        start:
          line: 1
          column: 4
        end:
          line: 1
          column: 7
    body:
      body: [
        start: 15
        end: 16
        range: [15, 16]
        loc:
          start:
            line: 2
            column: 2
          end:
            line: 2
            column: 3
      ]
      start: 13
      end: 16
      range: [13, 16]
      loc:
        start:
          line: 2
          column: 0
        end:
          line: 2
          column: 3
    source:
      start: 11
      end: 12
      range: [11, 12]
      loc:
        start:
          line: 1
          column: 11
        end:
          line: 1
          column: 12
    start: 0
    end: 16
    range: [0, 16]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 2
        column: 3

test "AST location data as expected for StringWithInterpolations node", ->
  testAstLocationData '"a#{b}c"',
    type: 'TemplateLiteral'
    expressions: [
      start: 4
      end: 5
      range: [4, 5]
      loc:
        start:
          line: 1
          column: 4
        end:
          line: 1
          column: 5
    ]
    quasis: [
      start: 1
      end: 2
      range: [1, 2]
      loc:
        start:
          line: 1
          column: 1
        end:
          line: 1
          column: 2
    ,
      start: 6
      end: 7
      range: [6, 7]
      loc:
        start:
          line: 1
          column: 6
        end:
          line: 1
          column: 7
    ]
    start: 0
    end: 8
    range: [0, 8]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 8

  testAstLocationData '"""a#{b}c"""',
    type: 'TemplateLiteral'
    expressions: [
      start: 6
      end: 7
      range: [6, 7]
      loc:
        start:
          line: 1
          column: 6
        end:
          line: 1
          column: 7
    ]
    quasis: [
      start: 3
      end: 4
      range: [3, 4]
      loc:
        start:
          line: 1
          column: 3
        end:
          line: 1
          column: 4
    ,
      start: 8
      end: 9
      range: [8, 9]
      loc:
        start:
          line: 1
          column: 8
        end:
          line: 1
          column: 9
    ]
    start: 0
    end: 12
    range: [0, 12]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 12

  testAstLocationData '"#{b}"',
    type: 'TemplateLiteral'
    expressions: [
      start: 3
      end: 4
      range: [3, 4]
      loc:
        start:
          line: 1
          column: 3
        end:
          line: 1
          column: 4
    ]
    quasis: [
      start: 1
      end: 1
      range: [1, 1]
      loc:
        start:
          line: 1
          column: 1
        end:
          line: 1
          column: 1
    ,
      start: 5
      end: 5
      range: [5, 5]
      loc:
        start:
          line: 1
          column: 5
        end:
          line: 1
          column: 5
    ]
    start: 0
    end: 6
    range: [0, 6]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 6

  testAstLocationData '''
    " a
      #{b}
      c
    "
  ''',
    type: 'TemplateLiteral'
    expressions: [
      start: 8
      end: 9
      range: [8, 9]
      loc:
        start:
          line: 2
          column: 4
        end:
          line: 2
          column: 5
    ]
    quasis: [
      start: 1
      end: 6
      range: [1, 6]
      loc:
        start:
          line: 1
          column: 1
        end:
          line: 2
          column: 2
    ,
      start: 10
      end: 15
      range: [10, 15]
      loc:
        start:
          line: 2
          column: 6
        end:
          line: 4
          column: 0
    ]
    start: 0
    end: 16
    range: [0, 16]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 4
        column: 1

  testAstLocationData '''
    """
      a
        b#{
        c
      }d
    """
  ''',
    type: 'TemplateLiteral'
    expressions: [
      start: 20
      end: 21
      range: [20, 21]
      loc:
        start:
          line: 4
          column: 4
        end:
          line: 4
          column: 5
    ]
    quasis: [
      start: 3
      end: 13
      range: [3, 13]
      loc:
        start:
          line: 1
          column: 3
        end:
          line: 3
          column: 5
    ,
      start: 25
      end: 27
      range: [25, 27]
      loc:
        start:
          line: 5
          column: 3
        end:
          line: 6
          column: 0
    ]
    start: 0
    end: 30
    range: [0, 30]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 6
        column: 3

  # empty interpolation
  testAstLocationData '"#{}"',
    type: 'TemplateLiteral'
    expressions: [
      start: 3
      end: 3
      range: [3, 3]
      loc:
        start:
          line: 1
          column: 3
        end:
          line: 1
          column: 3
    ]
    quasis: [
      start: 1
      end: 1
      range: [1, 1]
      loc:
        start:
          line: 1
          column: 1
        end:
          line: 1
          column: 1
    ,
      start: 4
      end: 4
      range: [4, 4]
      loc:
        start:
          line: 1
          column: 4
        end:
          line: 1
          column: 4
    ]
    start: 0
    end: 5
    range: [0, 5]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 5

  testAstLocationData '''
    "#{
      # comment
     }"
    ''',
    type: 'TemplateLiteral'
    expressions: [
      start: 3
      end: 17
      range: [3, 17]
      loc:
        start:
          line: 1
          column: 3
        end:
          line: 3
          column: 1
    ]
    quasis: [
      start: 1
      end: 1
      range: [1, 1]
      loc:
        start:
          line: 1
          column: 1
        end:
          line: 1
          column: 1
    ,
      start: 18
      end: 18
      range: [18, 18]
      loc:
        start:
          line: 3
          column: 2
        end:
          line: 3
          column: 2
    ]
    start: 0
    end: 19
    range: [0, 19]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 3
        column: 3

  testAstLocationData '"#{ ### here ### }"',
    type: 'TemplateLiteral'
    expressions: [
      start: 3
      end: 17
      range: [3, 17]
      loc:
        start:
          line: 1
          column: 3
        end:
          line: 1
          column: 17
    ]
    quasis: [
      start: 1
      end: 1
      range: [1, 1]
      loc:
        start:
          line: 1
          column: 1
        end:
          line: 1
          column: 1
    ,
      start: 18
      end: 18
      range: [18, 18]
      loc:
        start:
          line: 1
          column: 18
        end:
          line: 1
          column: 18
    ]
    start: 0
    end: 19
    range: [0, 19]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 19

test "AST location data as expected for dynamic import", ->
  testAstLocationData '''
    import('a')
  ''',
    type: 'CallExpression'
    callee:
      start: 0
      end: 6
      range: [0, 6]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 6
    arguments: [
      start: 7
      end: 10
      range: [7, 10]
      loc:
        start:
          line: 1
          column: 7
        end:
          line: 1
          column: 10
    ]
    start: 0
    end: 11
    range: [0, 11]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 11

test "AST location data as expected for RegexWithInterpolations node", ->
  testAstLocationData '///^#{flavor}script$///',
    type: 'InterpolatedRegExpLiteral'
    interpolatedPattern:
      expressions: [
        start: 6
        end: 12
        range: [6, 12]
        loc:
          start:
            line: 1
            column: 6
          end:
            line: 1
            column: 12
      ]
      quasis: [
        start: 3
        end: 4
        range: [3, 4]
        loc:
          start:
            line: 1
            column: 3
          end:
            line: 1
            column: 4
      ,
        start: 13
        end: 20
        range: [13, 20]
        loc:
          start:
            line: 1
            column: 13
          end:
            line: 1
            column: 20
      ]
      start: 0
      end: 23
      range: [0, 23]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 23
    start: 0
    end: 23
    range: [0, 23]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 23

  testAstLocationData '''
    ///
      a
      #{b}///ig
  ''',
    type: 'InterpolatedRegExpLiteral'
    interpolatedPattern:
      expressions: [
        start: 12
        end: 13
        range: [12, 13]
        loc:
          start:
            line: 3
            column: 4
          end:
            line: 3
            column: 5
      ]
      quasis: [
        start: 3
        end: 10
        range: [3, 10]
        loc:
          start:
            line: 1
            column: 3
          end:
            line: 3
            column: 2
      ,
        start: 14
        end: 14
        range: [14, 14]
        loc:
          start:
            line: 3
            column: 6
          end:
            line: 3
            column: 6
      ]
      start: 0
      end: 17
      range: [0, 17]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 3
          column: 9
    start: 0
    end: 19
    range: [0, 19]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 3
        column: 11

  testAstLocationData '''
    ///
      a # first
      #{b} ### second ###
    ///ig
  ''',
    type: 'InterpolatedRegExpLiteral'
    comments: [
      start: 8
      end: 15
      range: [8, 15]
      loc:
        start:
          line: 2
          column: 4
        end:
          line: 2
          column: 11
    ,
      start: 23
      end: 37
      range: [23, 37]
      loc:
        start:
          line: 3
          column: 7
        end:
          line: 3
          column: 21
    ]

test "AST location data as expected for RegexLiteral node", ->
  testAstLocationData '/a/ig',
    type: 'RegExpLiteral'
    start: 0
    end: 5
    range: [0, 5]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 5

  testAstLocationData '''
    ///
      a
    ///i
  ''',
    type: 'RegExpLiteral'
    start: 0
    end: 12
    range: [0, 12]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 3
        column: 4

  testAstLocationData '/a\\w\\u1111\\u{11111}/',
    type: 'RegExpLiteral'
    start: 0
    end: 20
    range: [0, 20]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 20

  testAstLocationData '''
    ///
      a
      \\w\\u1111\\u{11111}
    ///
  ''',
    type: 'RegExpLiteral'
    start: 0
    end: 31
    range: [0, 31]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 4
        column: 3

  testAstLocationData '''
    ///
      /
      (.+)
      /
    ///
  ''',
    type: 'RegExpLiteral'
    start: 0
    end: 22
    range: [0, 22]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 5
        column: 3

  testAstLocationData '''
    ///
      a # first
      b ### second ###
    ///
  ''',
    type: 'RegExpLiteral'
    comments: [
      start: 8
      end: 15
      range: [8, 15]
      loc:
        start:
          line: 2
          column: 4
        end:
          line: 2
          column: 11
    ,
      start: 20
      end: 34
      range: [20, 34]
      loc:
        start:
          line: 3
          column: 4
        end:
          line: 3
          column: 18
    ]
    start: 0
    end: 38
    range: [0, 38]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 4
        column: 3

test "AST location data as expected for TaggedTemplateCall node", ->
  testAstLocationData 'func"tagged"',
    type: 'TaggedTemplateExpression'
    tag:
      start: 0
      end: 4
      range: [0, 4]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 4
    quasi:
      quasis: [
        start: 5
        end: 11
        range: [5, 11]
        loc:
          start:
            line: 1
            column: 5
          end:
            line: 1
            column: 11
      ]
      start: 4
      end: 12
      range: [4, 12]
      loc:
        start:
          line: 1
          column: 4
        end:
          line: 1
          column: 12
    start: 0
    end: 12
    range: [0, 12]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 12

  testAstLocationData 'a"b#{c}"',
    type: 'TaggedTemplateExpression'
    tag:
      start: 0
      end: 1
      range: [0, 1]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 1
    quasi:
      expressions: [
        start: 5
        end: 6
        range: [5, 6]
        loc:
          start:
            line: 1
            column: 5
          end:
            line: 1
            column: 6
      ]
      quasis: [
        start: 2
        end: 3
        range: [2, 3]
        loc:
          start:
            line: 1
            column: 2
          end:
            line: 1
            column: 3
      ,
        start: 7
        end: 7
        range: [7, 7]
        loc:
          start:
            line: 1
            column: 7
          end:
            line: 1
            column: 7
      ]
      start: 1
      end: 8
      range: [1, 8]
      loc:
        start:
          line: 1
          column: 1
        end:
          line: 1
          column: 8
    start: 0
    end: 8
    range: [0, 8]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 8

  testAstLocationData '''
    a"""
      b#{c}
    """
  ''',
    type: 'TaggedTemplateExpression'
    tag:
      start: 0
      end: 1
      range: [0, 1]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 1
    quasi:
      expressions: [
        start: 10
        end: 11
        range: [10, 11]
        loc:
          start:
            line: 2
            column: 5
          end:
            line: 2
            column: 6
      ]
      quasis: [
        start: 4
        end: 8
        range: [4, 8]
        loc:
          start:
            line: 1
            column: 4
          end:
            line: 2
            column: 3
      ,
        start: 12
        end: 13
        range: [12, 13]
        loc:
          start:
            line: 2
            column: 7
          end:
            line: 3
            column: 0
      ]
      start: 1
      end: 16
      range: [1, 16]
      loc:
        start:
          line: 1
          column: 1
        end:
          line: 3
          column: 3
    start: 0
    end: 16
    range: [0, 16]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 3
        column: 3

  testAstLocationData """
    a'''
      b
    '''
  """,
    type: 'TaggedTemplateExpression'
    tag:
      start: 0
      end: 1
      range: [0, 1]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 1
    quasi:
      quasis: [
        start: 4
        end: 9
        range: [4, 9]
        loc:
          start:
            line: 1
            column: 4
          end:
            line: 3
            column: 0
      ]
      start: 1
      end: 12
      range: [1, 12]
      loc:
        start:
          line: 1
          column: 1
        end:
          line: 3
          column: 3
    start: 0
    end: 12
    range: [0, 12]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 3
        column: 3

test "AST location data as expected for Class node", ->
  testAstLocationData 'class Klass',
    type: 'ClassDeclaration'
    id:
      start: 6
      end: 11
      range: [6, 11]
      loc:
        start:
          line: 1
          column: 6
        end:
          line: 1
          column: 11
    body:
      start: 11
      end: 11
      range: [11, 11]
      loc:
        start:
          line: 1
          column: 11
        end:
          line: 1
          column: 11
    start: 0
    end: 11
    range: [0, 11]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 11

  testAstLocationData 'class child extends parent',
    type: 'ClassDeclaration'
    id:
      start: 6
      end: 11
      range: [6, 11]
      loc:
        start:
          line: 1
          column: 6
        end:
          line: 1
          column: 11
    superClass:
      start: 20
      end: 26
      range: [20, 26]
      loc:
        start:
          line: 1
          column: 20
        end:
          line: 1
          column: 26
    body:
      start: 26
      end: 26
      range: [26, 26]
      loc:
        start:
          line: 1
          column: 26
        end:
          line: 1
          column: 26
    start: 0
    end: 26
    range: [0, 26]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 26

  testAstLocationData 'class Klass then constructor: ->',
    type: 'ClassDeclaration'
    id:
      start: 6
      end: 11
      range: [6, 11]
      loc:
        start:
          line: 1
          column: 6
        end:
          line: 1
          column: 11
    body:
      body: [
        key:
          start: 17
          end: 28
          range: [17, 28]
          loc:
            start:
              line: 1
              column: 17
            end:
              line: 1
              column: 28
        start: 17
        end: 32
        range: [17, 32]
        loc:
          start:
            line: 1
            column: 17
          end:
            line: 1
            column: 32
      ]
      start: 12
      end: 32
      range: [12, 32]
      loc:
        start:
          line: 1
          column: 12
        end:
          line: 1
          column: 32
    start: 0
    end: 32
    range: [0, 32]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 32

  testAstLocationData '''
    a = class A
      b: ->
        c
  ''',
    type: 'AssignmentExpression'
    right:
      id:
        start: 10
        end: 11
        range: [10, 11]
        loc:
          start:
            line: 1
            column: 10
          end:
            line: 1
            column: 11
      body:
        body: [
          key:
            start: 14
            end: 15
            range: [14, 15]
            loc:
              start:
                line: 2
                column: 2
              end:
                line: 2
                column: 3
          body:
            body: [
              start: 24
              end: 25
              range: [24, 25]
              loc:
                start:
                  line: 3
                  column: 4
                end:
                  line: 3
                  column: 5
            ]
            start: 20
            end: 25
            range: [20, 25]
            loc:
              start:
                line: 3
                column: 0
              end:
                line: 3
                column: 5
          start: 14
          end: 25
          range: [14, 25]
          loc:
            start:
              line: 2
              column: 2
            end:
              line: 3
              column: 5
        ]
        start: 12
        end: 25
        range: [12, 25]
        loc:
          start:
            line: 2
            column: 0
          end:
            line: 3
            column: 5
      start: 4
      end: 25
      range: [4, 25]
      loc:
        start:
          line: 1
          column: 4
        end:
          line: 3
          column: 5
    start: 0
    end: 25
    range: [0, 25]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 3
        column: 5

  testAstLocationData '''
    class A
      @b: ->
      @c = ->
      @d: 1
      @e = 2
      A.f = 3
      A.g = ->
      this.h = ->
      this.i = 4
  ''',
    type: 'ClassDeclaration'
    id:
      start: 6
      end: 7
      range: [6, 7]
      loc:
        start:
          line: 1
          column: 6
        end:
          line: 1
          column: 7
    body:
      body: [
        key:
          start: 11
          end: 12
          range: [11, 12]
          loc:
            start:
              line: 2
              column: 3
            end:
              line: 2
              column: 4
        staticClassName:
          start: 10
          end: 11
          range: [10, 11]
          loc:
            start:
              line: 2
              column: 2
            end:
              line: 2
              column: 3
        start: 10
        end: 16
        range: [10, 16]
        loc:
          start:
            line: 2
            column: 2
          end:
            line: 2
            column: 8
      ,
        key:
          start: 20
          end: 21
          range: [20, 21]
          loc:
            start:
              line: 3
              column: 3
            end:
              line: 3
              column: 4
        staticClassName:
          start: 19
          end: 20
          range: [19, 20]
          loc:
            start:
              line: 3
              column: 2
            end:
              line: 3
              column: 3
        start: 19
        end: 26
        range: [19, 26]
        loc:
          start:
            line: 3
            column: 2
          end:
            line: 3
            column: 9
      ,
        key:
          start: 30
          end: 31
          range: [30, 31]
          loc:
            start:
              line: 4
              column: 3
            end:
              line: 4
              column: 4
        staticClassName:
          start: 29
          end: 30
          range: [29, 30]
          loc:
            start:
              line: 4
              column: 2
            end:
              line: 4
              column: 3
        value:
          start: 33
          end: 34
          range: [33, 34]
          loc:
            start:
              line: 4
              column: 6
            end:
              line: 4
              column: 7
        start: 29
        end: 34
        range: [29, 34]
        loc:
          start:
            line: 4
            column: 2
          end:
            line: 4
            column: 7
      ,
        key:
          start: 38
          end: 39
          range: [38, 39]
          loc:
            start:
              line: 5
              column: 3
            end:
              line: 5
              column: 4
        staticClassName:
          start: 37
          end: 38
          range: [37, 38]
          loc:
            start:
              line: 5
              column: 2
            end:
              line: 5
              column: 3
        value:
          start: 42
          end: 43
          range: [42, 43]
          loc:
            start:
              line: 5
              column: 7
            end:
              line: 5
              column: 8
        start: 37
        end: 43
        range: [37, 43]
        loc:
          start:
            line: 5
            column: 2
          end:
            line: 5
            column: 8
      ,
        key:
          start: 48
          end: 49
          range: [48, 49]
          loc:
            start:
              line: 6
              column: 4
            end:
              line: 6
              column: 5
        staticClassName:
          start: 46
          end: 47
          range: [46, 47]
          loc:
            start:
              line: 6
              column: 2
            end:
              line: 6
              column: 3
        value:
          start: 52
          end: 53
          range: [52, 53]
          loc:
            start:
              line: 6
              column: 8
            end:
              line: 6
              column: 9
        start: 46
        end: 53
        range: [46, 53]
        loc:
          start:
            line: 6
            column: 2
          end:
            line: 6
            column: 9
      ,
        key:
          start: 58
          end: 59
          range: [58, 59]
          loc:
            start:
              line: 7
              column: 4
            end:
              line: 7
              column: 5
        staticClassName:
          start: 56
          end: 57
          range: [56, 57]
          loc:
            start:
              line: 7
              column: 2
            end:
              line: 7
              column: 3
        start: 56
        end: 64
        range: [56, 64]
        loc:
          start:
            line: 7
            column: 2
          end:
            line: 7
            column: 10
      ,
        key:
          start: 72
          end: 73
          range: [72, 73]
          loc:
            start:
              line: 8
              column: 7
            end:
              line: 8
              column: 8
        staticClassName:
          start: 67
          end: 71
          range: [67, 71]
          loc:
            start:
              line: 8
              column: 2
            end:
              line: 8
              column: 6
        start: 67
        end: 78
        range: [67, 78]
        loc:
          start:
            line: 8
            column: 2
          end:
            line: 8
            column: 13
      ,
        key:
          start: 86
          end: 87
          range: [86, 87]
          loc:
            start:
              line: 9
              column: 7
            end:
              line: 9
              column: 8
        staticClassName:
          start: 81
          end: 85
          range: [81, 85]
          loc:
            start:
              line: 9
              column: 2
            end:
              line: 9
              column: 6
        value:
          start: 90
          end: 91
          range: [90, 91]
          loc:
            start:
              line: 9
              column: 11
            end:
              line: 9
              column: 12
        start: 81
        end: 91
        range: [81, 91]
        loc:
          start:
            line: 9
            column: 2
          end:
            line: 9
            column: 12
      ]
      start: 8
      end: 91
      range: [8, 91]
      loc:
        start:
          line: 2
          column: 0
        end:
          line: 9
          column: 12
    start: 0
    end: 91
    range: [0, 91]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 9
        column: 12

  testAstLocationData '''
    class A
      b: 1
      [c]: 2
  ''',
    type: 'ClassDeclaration'
    body:
      body: [
        key:
          start: 10
          end: 11
          range: [10, 11]
          loc:
            start:
              line: 2
              column: 2
            end:
              line: 2
              column: 3
        value:
          start: 13
          end: 14
          range: [13, 14]
          loc:
            start:
              line: 2
              column: 5
            end:
              line: 2
              column: 6
        start: 10
        end: 14
        range: [10, 14]
        loc:
          start:
            line: 2
            column: 2
          end:
            line: 2
            column: 6
      ,
        key:
          start: 18
          end: 19
          range: [18, 19]
          loc:
            start:
              line: 3
              column: 3
            end:
              line: 3
              column: 4
        value:
          start: 22
          end: 23
          range: [22, 23]
          loc:
            start:
              line: 3
              column: 7
            end:
              line: 3
              column: 8
        start: 17
        end: 23
        range: [17, 23]
        loc:
          start:
            line: 3
            column: 2
          end:
            line: 3
            column: 8
      ]
      start: 8
      end: 23
      range: [8, 23]
      loc:
        start:
          line: 2
          column: 0
        end:
          line: 3
          column: 8
    start: 0
    end: 23
    range: [0, 23]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 3
        column: 8

  testAstLocationData '''
    class A
      @[b]: 1
      @[c]: ->
  ''',
    type: 'ClassDeclaration'
    body:
      body: [
        key:
          start: 12
          end: 13
          range: [12, 13]
          loc:
            start:
              line: 2
              column: 4
            end:
              line: 2
              column: 5
        staticClassName:
          start: 10
          end: 11
          range: [10, 11]
          loc:
            start:
              line: 2
              column: 2
            end:
              line: 2
              column: 3
        value:
          start: 16
          end: 17
          range: [16, 17]
          loc:
            start:
              line: 2
              column: 8
            end:
              line: 2
              column: 9
        start: 10
        end: 17
        range: [10, 17]
        loc:
          start:
            line: 2
            column: 2
          end:
            line: 2
            column: 9
      ,
        key:
          start: 22
          end: 23
          range: [22, 23]
          loc:
            start:
              line: 3
              column: 4
            end:
              line: 3
              column: 5
        staticClassName:
          start: 20
          end: 21
          range: [20, 21]
          loc:
            start:
              line: 3
              column: 2
            end:
              line: 3
              column: 3
        start: 20
        end: 28
        range: [20, 28]
        loc:
          start:
            line: 3
            column: 2
          end:
            line: 3
            column: 10
      ]
      start: 8
      end: 28
      range: [8, 28]
      loc:
        start:
          line: 2
          column: 0
        end:
          line: 3
          column: 10
    start: 0
    end: 28
    range: [0, 28]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 3
        column: 10

  testAstLocationData '''
    class A
      b = 1
  ''',
    type: 'ClassDeclaration'
    body:
      body: [
        expression:
          left:
            start: 10
            end: 11
            range: [10, 11]
            loc:
              start:
                line: 2
                column: 2
              end:
                line: 2
                column: 3
          right:
            start: 14
            end: 15
            range: [14, 15]
            loc:
              start:
                line: 2
                column: 6
              end:
                line: 2
                column: 7
          start: 10
          end: 15
          range: [10, 15]
          loc:
            start:
              line: 2
              column: 2
            end:
              line: 2
              column: 7
        start: 10
        end: 15
        range: [10, 15]
        loc:
          start:
            line: 2
            column: 2
          end:
            line: 2
            column: 7
      ]
      start: 8
      end: 15
      range: [8, 15]
      loc:
        start:
          line: 2
          column: 0
        end:
          line: 2
          column: 7
    start: 0
    end: 15
    range: [0, 15]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 2
        column: 7

test "AST location data as expected for directives", ->
  testAstRootLocationData '''
    'directive 1'
    'use strict'
    f()
  ''',
    type: 'File'
    program:
      body: [
        start: 27
        end: 30
        range: [27, 30]
        loc:
          start:
            line: 3
            column: 0
          end:
            line: 3
            column: 3
      ]
      directives: [
        start: 0
        end: 13
        range: [0, 13]
        loc:
          start:
            line: 1
            column: 0
          end:
            line: 1
            column: 13
      ,
        start: 14
        end: 26
        range: [14, 26]
        loc:
          start:
            line: 2
            column: 0
          end:
            line: 2
            column: 12
      ]
      start: 0
      end: 30
      range: [0, 30]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 3
          column: 3
    start: 0
    end: 30
    range: [0, 30]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 3
        column: 3

  testAstRootLocationData '''
    'use strict'
  ''',
    type: 'File'
    program:
      directives: [
        start: 0
        end: 12
        range: [0, 12]
        loc:
          start:
            line: 1
            column: 0
          end:
            line: 1
            column: 12
      ]
      start: 0
      end: 12
      range: [0, 12]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 12
    start: 0
    end: 12
    range: [0, 12]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 12

  testAstLocationData '''
    ->
      'use strict'
      f()
      'not a directive'
      g
  ''',
    type: 'FunctionExpression'
    body:
      directives: [
        value:
          start: 5
          end: 17
          range: [5, 17]
          loc:
            start:
              line: 2
              column: 2
            end:
              line: 2
              column: 14
        start: 5
        end: 17
        range: [5, 17]
        loc:
          start:
            line: 2
            column: 2
          end:
            line: 2
            column: 14
      ]
      start: 3
      end: 47
      range: [3, 47]
      loc:
        start:
          line: 2
          column: 0
        end:
          line: 5
          column: 3
    start: 0
    end: 47
    range: [0, 47]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 5
        column: 3

  testAstLocationData '''
    class A
      'classes can have directives too'
      a: ->
  ''',
    type: 'ClassDeclaration'
    body:
      directives: [
        start: 10
        end: 43
        range: [10, 43]
        loc:
          start:
            line: 2
            column: 2
          end:
            line: 2
            column: 35
      ]
      start: 8
      end: 51
      range: [8, 51]
      loc:
        start:
          line: 2
          column: 0
        end:
          line: 3
          column: 7
    start: 0
    end: 51
    range: [0, 51]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 3
        column: 7

test "AST location data as expected for PassthroughLiteral node", ->
  testAstLocationData "`abc`",
    type: 'PassthroughLiteral'
    start: 0
    end: 5
    range: [0, 5]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 5

  code = '\nconst CONSTANT = "unreassignable!"\n'
  testAstLocationData """
    ```
      abc
    ```
  """,
    type: 'PassthroughLiteral'
    start: 0
    end: 13
    range: [0, 13]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 3
        column: 3

  testAstLocationData "``",
    type: 'PassthroughLiteral'
    start: 0
    end: 2
    range: [0, 2]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 2

test "AST location data as expected for comments", ->
  testAstCommentsLocationData '''
    a # simple line comment
  ''', [
    start: 2
    end: 23
    range: [2, 23]
    loc:
      start:
        line: 1
        column: 2
      end:
        line: 1
        column: 23
  ]

  testAstCommentsLocationData '''
    a ### simple here comment ###
  ''', [
    start: 2
    end: 29
    range: [2, 29]
    loc:
      start:
        line: 1
        column: 2
      end:
        line: 1
        column: 29
  ]

  testAstCommentsLocationData '''
    # just a line comment
  ''', [
    start: 0
    end: 21
    range: [0, 21]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 21
  ]

  testAstCommentsLocationData '''
    ### just a here comment ###
  ''', [
    start: 0
    end: 27
    range: [0, 27]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 27
  ]

  testAstCommentsLocationData '''
    "#{
      # empty interpolation line comment
     }"
  ''', [
    start: 6
    end: 40
    range: [6, 40]
    loc:
      start:
        line: 2
        column: 2
      end:
        line: 2
        column: 36
  ]

  testAstCommentsLocationData '''
    "#{
      ### empty interpolation block comment ###
     }"
  ''', [
    start: 6
    end: 47
    range: [6, 47]
    loc:
      start:
        line: 2
        column: 2
      end:
        line: 2
        column: 43
  ]

  testAstCommentsLocationData '''
    # multiple line comments
    # on consecutive lines
  ''', [
    start: 0
    end: 24
    range: [0, 24]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 24
  ,
    start: 25
    end: 47
    range: [25, 47]
    loc:
      start:
        line: 2
        column: 0
      end:
        line: 2
        column: 22
  ]

  testAstCommentsLocationData '''
    # multiple line comments

    # with blank line
  ''', [
    start: 0
    end: 24
    range: [0, 24]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 24
  ,
    start: 26
    end: 43
    range: [26, 43]
    loc:
      start:
        line: 3
        column: 0
      end:
        line: 3
        column: 17
  ]

  testAstCommentsLocationData '''
    #no whitespace line comment
  ''', [
    start: 0
    end: 27
    range: [0, 27]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 27
  ]

  testAstCommentsLocationData '''
    ###no whitespace here comment###
  ''', [
    start: 0
    end: 32
    range: [0, 32]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 32
  ]

  testAstCommentsLocationData '''
    ###
    # multiline
    # here comment
    ###
  ''', [
    start: 0
    end: 34
    range: [0, 34]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 4
        column: 3
  ]

  testAstCommentsLocationData '''
    if b
      ###
      # multiline
      # indented here comment
      ###
      c
  ''', [
    start: 7
    end: 56
    range: [7, 56]
    loc:
      start:
        line: 2
        column: 2
      end:
        line: 5
        column: 5
  ]

test "AST location data as expected for chained comparisons", ->
  testAstLocationData '''
    a >= b < c
  ''',
    type: 'ChainedComparison'
    operands: [
      start: 0
      end: 1
      range: [0, 1]
      loc:
        start:
          line: 1
          column: 0
        end:
          line: 1
          column: 1
    ,
      start: 5
      end: 6
      range: [5, 6]
      loc:
        start:
          line: 1
          column: 5
        end:
          line: 1
          column: 6
    ,
      start: 9
      end: 10
      range: [9, 10]
      loc:
        start:
          line: 1
          column: 9
        end:
          line: 1
          column: 10
    ]
    start: 0
    end: 10
    range: [0, 10]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 10

test "AST location data as expected for Sequence", ->
  testAstLocationData '''
    (a; b)
  ''',
    type: 'SequenceExpression'
    expressions: [
      start: 1
      end: 2
      range: [1, 2]
      loc:
        start:
          line: 1
          column: 1
        end:
          line: 1
          column: 2
    ,
      start: 4
      end: 5
      range: [4, 5]
      loc:
        start:
          line: 1
          column: 4
        end:
          line: 1
          column: 5
    ]
    start: 1
    end: 5
    range: [1, 5]
    loc:
      start:
        line: 1
        column: 1
      end:
        line: 1
        column: 5

  testAstLocationData '''
    (a; b)""
  ''',
    type: 'TaggedTemplateExpression'
    tag:
      expressions: [
        start: 1
        end: 2
        range: [1, 2]
        loc:
          start:
            line: 1
            column: 1
          end:
            line: 1
            column: 2
      ,
        start: 4
        end: 5
        range: [4, 5]
        loc:
          start:
            line: 1
            column: 4
          end:
            line: 1
            column: 5
      ]
      start: 1
      end: 5
      range: [1, 5]
      loc:
        start:
          line: 1
          column: 1
        end:
          line: 1
          column: 5
    start: 0
    end: 8
    range: [0, 8]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 8

test "AST location data as expected for blocks with comments", ->
  # trailing indented comment
  testAstLocationData '''
    ->
      a
      # b
  ''',
    type: 'FunctionExpression'
    body:
      start: 3
      end: 12
      range: [3, 12]
      loc:
        start:
          line: 2
          column: 0
        end:
          line: 3
          column: 5
    start: 0
    end: 12
    range: [0, 12]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 3
        column: 5

  testAstLocationData '''
    if a
      b
      ### c ###
  ''',
    type: 'IfStatement'
    consequent:
      start: 5
      end: 20
      range: [5, 20]
      loc:
        start:
          line: 2
          column: 0
        end:
          line: 3
          column: 11
    start: 0
    end: 20
    range: [0, 20]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 3
        column: 11

  # trailing non-indented comment
  testAstLocationData '''
    ->
      a
    # b
  ''',
    type: 'FunctionExpression'
    body:
      start: 3
      end: 6
      range: [3, 6]
      loc:
        start:
          line: 2
          column: 0
        end:
          line: 2
          column: 3
    start: 0
    end: 6
    range: [0, 6]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 2
        column: 3

  testAstLocationData '''
    if a
      b
    ### c ###
  ''',
    type: 'IfStatement'
    consequent:
      start: 5
      end: 8
      range: [5, 8]
      loc:
        start:
          line: 2
          column: 0
        end:
          line: 2
          column: 3
    start: 0
    end: 8
    range: [0, 8]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 2
        column: 3

  # multiple trailing indented comments
  testAstLocationData '''
    class A
      a: ->
      # b
      #comment
  ''',
    type: 'ClassDeclaration'
    body:
      start: 8
      end: 32
      range: [8, 32]
      loc:
        start:
          line: 2
          column: 0
        end:
          line: 4
          column: 10
    start: 0
    end: 32
    range: [0, 32]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 4
        column: 10

  testAstLocationData '''
    a = ->
      c
      # b
      ### comment ###
  ''',
    type: 'AssignmentExpression'
    right:
      start: 4
      end: 34
      range: [4, 34]
      loc:
        start:
          line: 1
          column: 4
        end:
          line: 4
          column: 17
    start: 0
    end: 34
    range: [0, 34]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 4
        column: 17

  # multiple trailing comments, some indented
  testAstLocationData '''
    class A
      a: ->
      # b
    #comment
  ''',
    type: 'ClassDeclaration'
    body:
      start: 8
      end: 21
      range: [8, 21]
      loc:
        start:
          line: 2
          column: 0
        end:
          line: 3
          column: 5
    start: 0
    end: 21
    range: [0, 21]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 3
        column: 5

  # leading indented comment
  testAstLocationData '''
    ->
      # a
      b
  ''',
    type: 'FunctionExpression'
    body:
      start: 3
      end: 12
      range: [3, 12]
      loc:
        start:
          line: 2
          column: 0
        end:
          line: 3
          column: 3
    start: 0
    end: 12
    range: [0, 12]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 3
        column: 3

  testAstLocationData '''
    if a
      ### b ###
      c
  ''',
    type: 'IfStatement'
    consequent:
      start: 5
      end: 20
      range: [5, 20]
      loc:
        start:
          line: 2
          column: 0
        end:
          line: 3
          column: 3
    start: 0
    end: 20
    range: [0, 20]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 3
        column: 3

  # multiple leading indented comments
  testAstLocationData '''
    ->
      # a
      # b
      c
  ''',
    type: 'FunctionExpression'
    body:
      start: 3
      end: 18
      range: [3, 18]
      loc:
        start:
          line: 2
          column: 0
        end:
          line: 4
          column: 3
    start: 0
    end: 18
    range: [0, 18]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 4
        column: 3

  testAstLocationData '''
    if a
      ### b ###
      # c
      d
  ''',
    type: 'IfStatement'
    consequent:
      start: 5
      end: 26
      range: [5, 26]
      loc:
        start:
          line: 2
          column: 0
        end:
          line: 4
          column: 3
    start: 0
    end: 26
    range: [0, 26]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 4
        column: 3

  # just a comment
  testAstLocationData '''
    ->
      # a
  ''',
    type: 'FunctionExpression'
    body:
      start: 3
      end: 8
      range: [3, 8]
      loc:
        start:
          line: 2
          column: 0
        end:
          line: 2
          column: 5
    start: 0
    end: 8
    range: [0, 8]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 2
        column: 5

  testAstLocationData '''
    if a
      ### b ###
    else
      c
  ''',
    type: 'IfStatement'
    consequent:
      start: 5
      end: 16
      range: [5, 16]
      loc:
        start:
          line: 2
          column: 0
        end:
          line: 2
          column: 11
    start: 0
    end: 25
    range: [0, 25]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 4
        column: 3

  # just a non-indented comment
  testAstLocationData '''
    ->
    # a
  ''',
    type: 'FunctionExpression'
    body:
      start: 2
      end: 2
      range: [2, 2]
      loc:
        start:
          line: 1
          column: 2
        end:
          line: 1
          column: 2
    start: 0
    end: 2
    range: [0, 2]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 1
        column: 2

  # nested dedented comment
  testAstLocationData '''
    switch a
      when b
        c
      # d
  ''',
    type: 'SwitchStatement'
    cases: [
      start: 11
      end: 23
      range: [11, 23]
      loc:
        start:
          line: 2
          column: 2
        end:
          line: 3
          column: 5
    ]
    start: 0
    end: 29
    range: [0, 29]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 4
        column: 5

  # trailing implicit call in condition followed by indented comment
  testAstLocationData '''
    if a b
      # c
      d
  ''',
    type: 'IfStatement'
    test:
      start: 3
      end: 6
      range: [3, 6]
      loc:
        start:
          line: 1
          column: 3
        end:
          line: 1
          column: 6
    consequent:
      start: 7
      end: 16
      range: [7, 16]
      loc:
        start:
          line: 2
          column: 0
        end:
          line: 3
          column: 3
    start: 0
    end: 16
    range: [0, 16]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 3
        column: 3

test "AST location data as expected for heregex comments", ->
  code = '''
    ///
      a # b
    ///
  '''

  testAstLocationData code,
    type: 'RegExpLiteral'
    start: 0
    end: 15
    range: [0, 15]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 3
        column: 3

  eq getAstRoot(code).comments.length, 0

test "AST location data as expected with carriage returns", ->
  code = '''
    a =\r
    "#{\r
      b\r
    }"
  '''

  testAstLocationData code,
    type: 'AssignmentExpression'
    right:
      expressions: [
        start: 12
        end: 13
        range: [12, 13]
        loc:
          start:
            line: 3
            column: 2
          end:
            line: 3
            column: 3
      ]
      quasis: [
        start: 6
        end: 6
        range: [6, 6]
        loc:
          start:
            line: 2
            column: 1
          end:
            line: 2
            column: 1
      ,
        start: 16
        end: 16
        range: [16, 16]
        loc:
          start:
            line: 4
            column: 1
          end:
            line: 4
            column: 1
      ]
      start: 5
      end: 17
      range: [5, 17]
      loc:
        start:
          line: 2
          column: 0
        end:
          line: 4
          column: 2
    start: 0
    end: 17
    range: [0, 17]
    loc:
      start:
        line: 1
        column: 0
      end:
        line: 4
        column: 2
