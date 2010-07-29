# Sorts an array in ascending natural order using merge sort.
merge_sort = (list) ->

  return list if list.length is 1

  result  = []
  pivot   = Math.floor list.length / 2
  left    = merge_sort list.slice 0, pivot
  right   = merge_sort list.slice pivot

  while left.length and right.length
    result.push(if left[0] < right[0] then left.shift() else right.shift())

  result.concat(left).concat(right)


# Test the function.
puts merge_sort([3, 2, 1]).join(' ') is '1 2 3'
puts merge_sort([9, 2, 7, 0, 1]).join(' ') is '0 1 2 7 9'