generator = ->
  yield 'hello'
  next = yield 'to'
  yield next
  return "All done";

g = generator()
console.log(g.next()) # prints { value: 'hello', done: false }
console.log(g.next()) # print { value: 'to', done: false }
console.log(g.send("you")) # prints { value: 'you', done: false }
console.log(g.next()) # prints { value: undefined, done: true }

range = (start, stop) ->
  yield i for i in [start...stop]

ten = range(0, 10)
while true
  {done,value} = ten.next()
  console.log(value)
  break if done
