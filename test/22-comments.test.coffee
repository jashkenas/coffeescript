# Test Comments

test "single line comments", ->
  # This is a comment
  x = 42 # inline comment
  eq x, 42

test "block comments", ->
  ###
  This is a block comment
  spanning multiple lines
  ###
  x = 42
  eq x, 42

test "inline block comments", ->
  x = ### comment ### 42
  eq x, 42

test "comments in objects", ->
  obj =
    # comment before property
    a: 1
    b: 2 # inline comment
    # comment between properties
    c: 3
  eq obj.a, 1
  eq obj.c, 3

test "comments in arrays", ->
  arr = [
    1 # first
    # between elements
    2
    3 # last
  ]
  eq arr[1], 2

test "comments in functions", ->
  fn = ->
    # comment in function
    x = 1
    ### block comment ###
    x + 1
  eq fn(), 2

test "comments in conditionals", ->
  x = if true # condition comment
    # then branch
    42
  else
    # else branch
    0
  eq x, 42

test "comments in loops", ->
  sum = 0
  for i in [1, 2, 3] # loop comment
    # inside loop
    sum += i
  eq sum, 6

test "comments in switch statements", ->
  x = 1
  result = switch x
    # comment before case
    when 1 # case comment
      # case body
      'one'
    # between cases
    when 2
      'two'
  eq result, 'one'

test "comments in class definitions", ->
  class Test
    # comment in class
    constructor: ->
      # constructor comment
      @value = 42

    ### block comment in class ###
    method: ->
      # method comment
      @value

  t = new Test()
  eq t.method(), 42

test "herecomments", ->
  ###
  This is a herecomment
  It can span multiple lines
  And contain "quotes" and 'apostrophes'
  ###
  ok true

test "comments after operators", ->
  x = 1 + # plus
      2 * # times
      3
  eq x, 7

test "comments with YAML-style objects", ->
  obj =
    # comment
    key1: 'value1'
    key2:
      # nested comment
      nested: 'value2'
  eq obj.key2.nested, 'value2'

test "comments don't break indentation", ->
  if true
    # This comment shouldn't break the block
    x = 1
    # Another comment
    y = 2
  eq x, 1
  eq y, 2
