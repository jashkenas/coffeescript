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
ThirdChild extends SecondChild
ThirdChild::func: (string) ->
  super('three/') + string

result: (new ThirdChild()).func 'four'

print result is 'zero/one/two/three/four'


TopClass: (arg) ->
  @prop: 'top-' + arg

SuperClass: (arg) ->
  super 'super-' + arg

SubClass: ->
  super 'sub'

SuperClass extends TopClass
SubClass extends SuperClass

print((new SubClass()).prop is 'top-super-sub')