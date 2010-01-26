grade: (student) ->
  if student.excellent_work
    "A+"
  else if student.okay_stuff
    if student.tried_hard then "B" else "B-"
  else
    "C"

eldest: if 24 > 21 then "Liz" else "Ike"