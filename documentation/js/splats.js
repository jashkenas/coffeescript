(function(){
  var award_medals, contenders, gold, silver, the_field;
  var __slice = Array.prototype.slice;
  gold = (silver = (the_field = "unknown"));
  award_medals = function(first, second) {
    var rest;
    var _a = arguments.length, _b = _a >= 3;
    rest = __slice.call(arguments, 2, _a - 0);
    gold = first;
    silver = second;
    the_field = rest;
    return the_field;
  };
  contenders = ["Michael Phelps", "Liu Xiang", "Yao Ming", "Allyson Felix", "Shawn Johnson", "Roman Sebrle", "Guo Jingjing", "Tyson Gay", "Asafa Powell", "Usain Bolt"];
  award_medals.apply(this, contenders);
  alert("Gold: " + gold);
  alert("Silver: " + silver);
  alert("The Field: " + the_field);
})();
