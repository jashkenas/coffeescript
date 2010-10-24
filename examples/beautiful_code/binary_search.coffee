# Beautiful Code, Chapter 6.
# The implementation of binary search that is tested.

# Return the index of an element in a sorted list. (or -1, if not present)
index = (list, target) ->
  [low, high] = [0, list.length]
  while low < high
    mid = (low + high) >> 1
    val = list[mid]
    return mid if val is target
    if val < target then low = mid + 1 else high = mid
  return -1

console.log 2 is index [10, 20, 30, 40, 50], 30
console.log 4 is index [-97, 35, 67, 88, 1200], 1200
console.log 0 is index [0, 45, 70], 0