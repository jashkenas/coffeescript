a: [(x) -> x, (x) -> x * x]

ok a.length is 2


regex: /match/i
words: "I think there is a match in here."

ok !!words.match(regex)


neg: (3 -4)

ok neg is -1


func: ->
  return if true

ok func() is null


str: "\\"
reg: /\\/

ok reg(str) and str is '\\'


i: 10
while i -= 1

ok i is 0


money$: 'dollars'

ok money$ is 'dollars'


ok {a: (num) -> num is 10 }.a 10


bob: {
  name:  'Bob'
  greet: (salutation) ->
    salutation + " " + @name
  hello: ->
    @greet "Hello"
  10: 'number'
}

ok bob.hello() is "Hello Bob"
ok bob[10] is 'number'


obj: {
  'is':  -> yes
  'not': -> no
}

ok obj.is()
ok not obj.not()
