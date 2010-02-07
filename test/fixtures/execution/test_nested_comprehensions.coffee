multi_liner:
  for x in [3..5]
    for y in [3..5]
      [x, y]

single_liner:
  [x, y] for y in [3..5] for x in [3..5]

puts multi_liner.length is single_liner.length
puts 5 is multi_liner[2][2][1]
puts 5 is single_liner[2][2][1]
