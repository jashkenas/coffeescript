# Beautiful Code, Chapter 3.
# Produces the expected runtime of Quicksort, for every integer from 1 to N.

runtime = (N) ->
  [sum, t] = [0, 0]
  for n in [1..N]
    sum += 2 * t
    t = n - 1 + sum / n
  t

console.log runtime(3) is 2.6666666666666665
console.log runtime(5) is 7.4
console.log runtime(8) is 16.92142857142857
