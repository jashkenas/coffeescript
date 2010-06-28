(function(){
  var awardMedals, contenders, gold, rest, silver;
  var __slice = Array.prototype.slice;
  gold = (silver = (rest = "unknown"));
  awardMedals = function(first, second) {
    var _a = arguments.length, _b = _a >= 3;
    rest = __slice.call(arguments, 2, _a - 0);
    gold = first;
    silver = second;
    rest = rest;
    return rest;
  };
  contenders = ["Michael Phelps", "Liu Xiang", "Yao Ming", "Allyson Felix", "Shawn Johnson", "Roman Sebrle", "Guo Jingjing", "Tyson Gay", "Asafa Powell", "Usain Bolt"];
  awardMedals.apply(this, contenders);
  alert("Gold: " + gold);
  alert("Silver: " + silver);
  alert("The Field: " + rest);
})();
