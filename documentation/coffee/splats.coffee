gold: silver: the_field: "unknown"

award_medals: (first, second, rest...) ->
  gold:       first
  silver:     second
  the_field:  rest

contenders: [
  "Michael Phelps"
  "Liu Xiang"
  "Yao Ming"
  "Allyson Felix"
  "Shawn Johnson"
  "Roman Sebrle"
  "Guo Jingjing"
  "Tyson Gay"
  "Asafa Powell"
  "Usain Bolt"
]

award_medals contenders...

alert "Gold: " + gold
alert "Silver: " + silver
alert "The Field: " + the_field