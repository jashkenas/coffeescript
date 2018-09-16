# Astract Syntax Tree location data
# ---------------------------------

testAstLocationData = (code, expected) ->
  ast = CoffeeScript.compile code, ast: yes
  # Pull the node we’re testing out of the root `Block` node’s first child.
  node = ast.expressions[0]

  eq node.start, expected.start, \
    "Expected location start #{reset}#{node.start}#{red} to equal #{reset}#{expected.start}#{red}"
  eq node.end, expected.end, \
    "Expected location end #{reset}#{node.end}#{red} to equal #{reset}#{expected.end}#{red}"
  arrayEq node.range, expected.range, \
    "Expected location range #{reset}#{JSON.stringify node.range}#{red} to equal #{reset}#{JSON.stringify expected.range}#{red}"
  eq node.loc.start.line, expected.loc.start.line, \
    "Expected location start line #{reset}#{node.loc.start.line}#{red} to equal #{reset}#{expected.loc.start.line}#{red}"
  eq node.loc.start.column, expected.loc.start.column, \
    "Expected location start column #{reset}#{node.loc.start.column}#{red} to equal #{reset}#{expected.loc.start.column}#{red}"
  eq node.loc.end.line, expected.loc.end.line, \
    "Expected location end line #{reset}#{node.loc.end.line}#{red} to equal #{reset}#{expected.loc.end.line}#{red}"
  eq node.loc.end.column, expected.loc.end.column, \
    "Expected location end column #{reset}#{node.loc.end.column}#{red} to equal #{reset}#{expected.loc.end.column}#{red}"


test "AST location data as expected for NumberLiteral node", ->
  testAstLocationData '42',
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
