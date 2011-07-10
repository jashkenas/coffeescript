grade = (student) ->
  if student.excellentWork
    "A+"
  else if student.okayStuff
    if student.triedHard then "B" else "B-"
  else
    "C"

students =
  "salvador":
    okayStuff: true
    triedHard: true

alert grade(students["salvador"])