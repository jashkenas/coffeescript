a: [((x) -> x), ((x) -> x * x)]

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

trailing_comma: [1, 2, 3,]
ok (trailing_comma[0] is 1) and (trailing_comma[2] is 3) and (trailing_comma.length is 3)

trailing_comma: {k1: "v1", k2: 4, k3: (-> true),}
ok trailing_comma.k3() and (trailing_comma.k2 is 4) and (trailing_comma.k1 is "v1")

money$: 'dollars'

ok money$ is 'dollars'


multiline: "one
            two
            three"

ok multiline is 'one two three'


ok {a: (num) -> num is 10 }.a 10


bob: {
  name:  'Bob'
  greet: (salutation) ->
    salutation + " " + @name
  hello: ->
    @['greet'] "Hello"
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
