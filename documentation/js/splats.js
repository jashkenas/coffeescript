(function(){
  var contenders, gold, medalists, silver, the_field;
  gold = silver = the_field = "unknown";
  medalists = function medalists(first, second) {
    var rest;
    rest = Array.prototype.slice.call(arguments, 2);
    gold = first;
    silver = second;
    return the_field = rest;
  };
  contenders = ["Michael Phelps", "Liu Xiang", "Yao Ming", "Allyson Felix", "Shawn Johnson", "Roman Sebrle", "Guo Jingjing", "Tyson Gay", "Asafa Powell", "Usain Bolt"];
  medalists.apply(this, contenders);
  alert("Gold: " + gold);
  alert("Silver: " + silver);
  alert("The Field: " + the_field);
})();