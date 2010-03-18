func: (first, second, rest...) ->
  rest.join ' '

result: func 1, 2, 3, 4, 5

ok result is "3 4 5"


gold: silver: bronze: the_field: last: null

medalists: (first, second, third, rest..., unlucky) ->
  gold:       first
  silver:     second
  bronze:     third
  the_field:  rest.concat([last])
  last:       unlucky

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
ok last is "Usain Bolt"
ok the_field.length is 8

contenders.reverse()
medalists contenders[0...2]..., "Mighty Mouse", contenders[2...contenders.length]...

ok gold is "Usain Bolt"
ok silver is "Asafa Powell"
ok bronze is "Mighty Mouse"
ok last is "Michael Phelps"
ok the_field.length is 8

medalists contenders..., 'Tim', 'Bob', 'Jim'
ok last is 'Jim'


obj: {
  name: 'bob'
  accessor: (args...) ->
    [@name].concat(args).join(' ')
  getNames: ->
    args: ['jane', 'ted']
    @accessor(args...)
}

ok obj.getNames() is 'bob jane ted'