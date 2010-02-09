Base: ->
Base::func: (string) ->
  'zero/' + string

FirstChild: ->
FirstChild extends Base
FirstChild::func: (string) ->
  super('one/') + string

SecondChild: ->
SecondChild extends FirstChild
SecondChild::func: (string) ->
  super('two/') + string

ThirdChild: ->
  @array: [1, 2, 3]
  this
ThirdChild extends SecondChild
ThirdChild::func: (string) ->
  super('three/') + string

result: (new ThirdChild()).func 'four'

puts result is 'zero/one/two/three/four'


TopClass: (arg) ->
  @prop: 'top-' + arg
  this

SuperClass: (arg) ->
  super 'super-' + arg
  this

SubClass: ->
  super 'sub'
  this

SuperClass extends TopClass
SubClass extends SuperClass

puts((new SubClass()).prop is 'top-super-sub')