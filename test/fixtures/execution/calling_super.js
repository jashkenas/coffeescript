(function(){
  var Base = function() {
  };
  Base.prototype.func = function(string) {
    return 'zero/' + string;
  };
  var FirstChild = function() {
  };
  FirstChild.prototype.__proto__ = new Base();
  FirstChild.prototype.func = function(string) {
    return FirstChild.prototype.__proto__.func.call(this, 'one/') + string;
  };
  var SecondChild = function() {
  };
  SecondChild.prototype.__proto__ = new FirstChild();
  SecondChild.prototype.func = function(string) {
    return SecondChild.prototype.__proto__.func.call(this, 'two/') + string;
  };
  var ThirdChild = function() {
  };
  ThirdChild.prototype.__proto__ = new SecondChild();
  ThirdChild.prototype.func = function(string) {
    return ThirdChild.prototype.__proto__.func.call(this, 'three/') + string;
  };
  var result = (new ThirdChild()).func('four');
  print(result === 'zero/one/two/three/four');
})();