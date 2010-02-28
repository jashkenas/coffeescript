class Base
  func: (string) ->
    'zero/' + string

class FirstChild extends Base
  func: (string) ->
    super('one/') + string

class SecondChild extends FirstChild
  func: (string) ->
    super('two/') + string

class ThirdChild extends SecondChild
  constructor: ->
    @array: [1, 2, 3]

  # Gratuitous comment for testing.
  func: (string) ->
    super('three/') + string

result: (new ThirdChild()).func 'four'

ok result is 'zero/one/two/three/four'


class TopClass
  constructor: (arg) ->
    @prop: 'top-' + arg

class SuperClass extends TopClass
  constructor: (arg) ->
    super 'super-' + arg

class SubClass extends SuperClass
  constructor: ->
    super 'sub'

ok (new SubClass()).prop is 'top-super-sub'