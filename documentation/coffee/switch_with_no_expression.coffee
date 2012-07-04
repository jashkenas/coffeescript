score = 76
grade = switch
  when 90 <= score      then 'A'
  when 80 <= score < 90 then 'B'
  when 70 <= score < 80 then 'C'
  when 60 <= score < 70 then 'D'
  when       score < 60 then 'F'
# grade == 'C'
