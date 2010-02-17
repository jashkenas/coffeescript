func: (first, second, rest...) ->
  rest.join ' '

result: func 1, 2, 3, 4, 5

puts result is "3 4 5"


gold: silver: bronze: the_field: null

medalists: (first, second, third, rest...) ->
  gold:       first
  silver:     second
  bronze:     third
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

medalists "Mighty Mouse", contenders...

puts gold is "Mighty Mouse"
puts silver is "Michael Phelps"
puts bronze is "Liu Xiang"
puts the_field.length is 8