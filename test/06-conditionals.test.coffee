# Test conditional operations

test "if statement", ->
  result = if true then "yes" else "no"
  eq result, "yes"

test "if-else", ->
  x = 5
  result = if x > 3
    "big"
  else
    "small"
  eq result, "big"

test "unless", ->
  result = "default"
  unless false
    result = "changed"
  eq result, "changed"

test "ternary operator", ->
  x = 10
  result = if x > 5 then "big" else "small"
  eq result, "big"

test "switch statement", ->
  grade = (score) ->
    switch
      when score >= 90 then "A"
      when score >= 80 then "B"
      when score >= 70 then "C"
      else "F"
  
  eq grade(95), "A"
  eq grade(85), "B"
  eq grade(65), "F"

test "switch with value", ->
  dayName = (day) ->
    switch day
      when 1 then "Monday"
      when 2 then "Tuesday"
      when 3 then "Wednesday"
      else "Other"
  
  eq dayName(1), "Monday"
  eq dayName(3), "Wednesday"
  eq dayName(7), "Other"

test "postfix if", ->
  result = null
  result = "yes" if true
  eq result, "yes"

test "postfix unless", ->
  result = "yes"
  result = "no" unless true
  eq result, "yes"

test "chained conditionals", ->
  x = 10
  result = if x < 5
    "small"
  else if x < 15
    "medium"
  else
    "large"
  eq result, "medium"

test "existence operator", ->
  value = null
  result = value ? "default"
  eq result, "default"
  
  value = "exists"
  result = value ? "default"
  eq result, "exists"
