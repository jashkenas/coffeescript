var awardMedals, contenders, gold, rest, silver;
var __slice = Array.prototype.slice;
gold = (silver = (rest = "unknown"));
awardMedals = function(first, second) {
  var others;
  others = __slice.call(arguments, 2);
  gold = first;
  silver = second;
  return (rest = others);
};
contenders = ["Michael Phelps", "Liu Xiang", "Yao Ming", "Allyson Felix", "Shawn Johnson", "Roman Sebrle", "Guo Jingjing", "Tyson Gay", "Asafa Powell", "Usain Bolt"];
awardMedals.apply(awardMedals, contenders);
alert("Gold: " + gold);
alert("Silver: " + silver);
alert("The Field: " + rest);