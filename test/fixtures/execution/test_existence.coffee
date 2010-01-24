print(if my_special_variable? then false else true)

my_special_variable: false

print(if my_special_variable? then true else false)


# Existential assignment.

a: 5
a: null
a ?= 10
b ?= 10

print(a is 10 and b is 10)


# The existential operator.

z: null
x: z ? "EX"

print(z is null and x is "EX")


# Only evaluate once.

counter: 0
get_next_node: =>
  throw "up" if counter
  counter++

print(if get_next_node()? then true else false)


# Existence chains, soaking up undefined properties:

obj: {
  prop: "hello"
}

print(obj?.prop is "hello")

print(obj?.prop?.non?.existent?.property is undefined)


# Soaks and caches method calls as well.

arr: ["--", "----"]

print(arr.pop()?.length is 4)
print(arr.pop()?.length is 2)
print(arr.pop()?.length is undefined)
print(arr.pop()?.length?.non?.existent()?.property is undefined)
