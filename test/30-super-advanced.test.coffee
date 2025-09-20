# Test Advanced Super Usage

test "super with splats", ->
  class Parent
    constructor: (a, b, c) ->
      @values = [a, b, c]

    method: (x, y, z) ->
      [x, y, z]

  class Child extends Parent
    constructor: (args...) ->
      super args...

    method: (params...) ->
      result = super params...
      result.push('child')
      result

  child = new Child(1, 2, 3)
  ok child.values[0] is 1
  ok child.values[1] is 2
  ok child.values[2] is 3

  result = child.method('a', 'b', 'c')
  ok result[0] is 'a'
  ok result[3] is 'child'

test "super in static methods", ->
  class Parent
    @staticMethod: -> 'parent static'

  class Child extends Parent
    @staticMethod: ->
      parent = super()
      "#{parent} + child"

  eq Child.staticMethod(), 'parent static + child'

test "super without parentheses", ->
  class Parent
    method: -> 'parent'

  class Child extends Parent
    method: ->
      super()  # Need parentheses for method calls

  child = new Child()
  eq child.method(), 'parent'

test "super with mixed arguments", ->
  class Parent
    method: (a, b, rest...) ->
      sum = a + b
      for val in rest
        sum += val
      sum

  class Child extends Parent
    method: (first, others...) ->
      super first, 10, others...

  child = new Child()
  eq child.method(1, 2, 3, 4), 20  # 1 + 10 + 2 + 3 + 4

test "super in methods with property access", ->
  class Parent
    constructor: -> @_value = 0

    getValue: -> @_value
    setValue: (val) -> @_value = val

  class Child extends Parent
    getValue: ->
      val = super()  # Using super in method
      val * 2

    setValue: (val) ->
      super val / 2  # Using super in setter method

  child = new Child()
  child.setValue 10
  eq child.getValue(), 10  # Set 10, stored as 5, retrieved as 10

test "super in arrow functions", ->
  class Parent
    method: -> 'parent'

  class Child extends Parent
    constructor: ->
      super()
      @arrow = =>
        super.method()  # Super in arrow function

    regular: ->
      @arrow()

  child = new Child()
  eq child.regular(), 'parent'

test "super with method delegation", ->
  class Parent
    dynamicMethod: -> 'parent dynamic'

  class Child extends Parent
    callParentMethod: ->
      super.dynamicMethod()

  child = new Child()
  eq child.callParentMethod(), 'parent dynamic'

test "super in async methods", ->
  class Parent
    asyncMethod: -> Promise.resolve('parent async')

  class Child extends Parent
    asyncMethod: ->
      result = await super()
      "#{result} + child"

  child = new Child()
  result = await child.asyncMethod()
  eq result, 'parent async + child'

test "super with destructuring", ->
  class Parent
    method: ({a, b}) -> a + b

  class Child extends Parent
    method: (obj) ->
      super obj

  child = new Child()
  eq child.method({a: 1, b: 2}), 3

test "super edge case - multiple inheritance levels", ->
  class GrandParent
    method: -> 'grandparent'

  class Parent extends GrandParent
    method: ->
      grand = super()
      "#{grand} -> parent"

  class Child extends Parent
    method: ->
      parent = super()
      "#{parent} -> child"

  child = new Child()
  eq child.method(), 'grandparent -> parent -> child'
