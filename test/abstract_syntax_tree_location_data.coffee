# Astract Syntax Tree location data
# ---------------------------------

testAstLocationData = (code, expected) ->
  testAstNodeLocationData getAstExpression(code), expected

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
    type: 'CallExpression'
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

  # testAstLocationData 'export fn = ->',
  #   type: 'ExportNamedDeclaration'
  #   clause:
  #     type: 'Assign'
  #     variable:
  #       value: 'fn'
  #     value:
  #       type: 'Code'

  # testAstLocationData 'export class A',

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
  # testAstLocationData 'export default class',
  #   type: 'ExportDefaultDeclaration'
  #   clause:
  #     type: 'Class'

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
