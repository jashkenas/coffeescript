Base: => .
Base.prototype.func: string =>
  'zero/' + string.

FirstChild: => .
FirstChild extends new Base()
FirstChild.prototype.func: string =>
  super('one/') + string.

SecondChild: => .
SecondChild extends new FirstChild()
SecondChild.prototype.func: string =>
  super('two/') + string.

ThirdChild: => .
ThirdChild extends new SecondChild()
ThirdChild.prototype.func: string =>
  super('three/') + string.

result: (new ThirdChild()).func('four')

print(result is 'zero/one/two/three/four')

