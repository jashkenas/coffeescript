# A bubble sort implementation, sorting the given array in-place.
bubble_sort = (list) ->
  for i in [0...list.length]
    for j in [0...list.length - i] when list[j] > list[j + 1]
      [list[j], list[j+1]] = [list[j + 1], list[j]]
  list


# Test the function.
console.log bubble_sort([3, 2, 1]).join(' ') is '1 2 3'
console.log bubble_sort([9, 2, 7, 0, 1]).join(' ') is '0 1 2 7 9'