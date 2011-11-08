# An in-place selection sort.
selection_sort = (list) ->
  len = list.length

  # For each item in the list.
  for i in [0...len]

    # Set the minimum to this position.
    min = i

    # Check the rest of the array to see if anything is smaller.
    min = k for v, k in list[i+1...] when v < list[min]

    # Swap if a smaller item has been found.
    [list[i], list[min]] = [list[min], list[i]] if i isnt min

  # The list is now sorted.
  list


# Test the function.
console.log selection_sort([3, 2, 1]).join(' ') is '1 2 3'
console.log selection_sort([9, 2, 7, 0, 1]).join(' ') is '0 1 2 7 9'