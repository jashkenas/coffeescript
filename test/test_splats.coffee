func: (first, second, rest...) ->
  rest.join ' '

result: func 1, 2, 3, 4, 5

ok result is "3 4 5"


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

ok gold is "Mighty Mouse"
ok silver is "Michael Phelps"
ok bronze is "Liu Xiang"
ok the_field.length is 8