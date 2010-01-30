puts(if my_special_variable? then false else true)

my_special_variable: false

puts(if my_special_variable? then true else false)


# Existential assignment.

a: 5
a: null
a ?= 10
b ?= 10

puts a is 10 and b is 10


# The existential operator.

z: null
x: z ? "EX"

puts z is null and x is "EX"


# Only evaluate once.

counter: 0
get_next_node: ->
  throw "up" if counter
  counter++

puts(if get_next_node()? then true else false)


# Existence chains, soaking up undefined properties:

obj: {
  prop: "hello"
}

puts obj?.prop is "hello"

puts obj?.prop?.non?.existent?.property is undefined


# Soaks and caches method calls as well.

arr: ["--", "----"]

puts arr.pop()?.length is 4
puts arr.pop()?.length is 2
puts arr.pop()?.length is undefined
puts arr[0]?.length is undefined
puts arr.pop()?.length?.non?.existent()?.property is undefined
