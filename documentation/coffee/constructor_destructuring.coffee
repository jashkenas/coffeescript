class Person
  constructor: (options) ->
    {@name, @age, @height = 'average'} = options

tim = new Person name: 'Tim', age: 4
