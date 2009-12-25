Base: => .
Base.prototype.func: string =>
  'zero/' + string.

FirstChild: => .
FirstChild.prototype.__proto__: new Base()
FirstChild.prototype.func: string =>
  super('one/') + string.

SecondChild: => .
SecondChild.prototype.__proto__: new FirstChild()
SecondChild.prototype.func: string =>
  super('two/') + string.

ThirdChild: => .
ThirdChild.prototype.__proto__: new SecondChild()
ThirdChild.prototype.func: string =>
  super('three/') + string.

result: (new ThirdChild()).func('four')

print(result is 'zero/one/two/three/four')

