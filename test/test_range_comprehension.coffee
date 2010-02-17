nums: i * 3 for i in [1..3]

negs: x for x in [-20..-5*2]
negs: negs[0..2]

result: nums.concat(negs).join(', ')

puts result is '3, 6, 9, -20, -19, -18'

# Ensure that ranges are safe. This used to infinite loop:
j = 5
result: for j in [j..(j+3)]
  j

puts result.join(' ') is '5 6 7 8'

# With range comprehensions, you can loop in steps.
results: x for x in [0..25] by 5

puts results.join(' ') is '0 5 10 15 20 25'