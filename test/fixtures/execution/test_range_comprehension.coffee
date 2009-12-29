nums: i * 3 for i in [1..3].

negs: x for x in [-20..-10].
negs: negs[0..2]

result: nums.concat(negs).join(', ')

print(result is '3, 6, 9, -20, -19, -18')