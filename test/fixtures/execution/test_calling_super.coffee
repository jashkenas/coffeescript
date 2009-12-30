Base: =>
Base.prototype.func: string =>
  'zero/' + string

FirstChild: =>
FirstChild extends Base
FirstChild.prototype.func: string =>
  super('one/') + string
     
SecondChild: =>
SecondChild extends FirstChild
SecondChild.prototype.func: string =>
  super('two/') + string
   
ThirdChild: =>
ThirdChild extends SecondChild
ThirdChild.prototype.func: string =>
  super('three/') + string

result: (new ThirdChild()).func('four')

print(result is 'zero/one/two/three/four')

