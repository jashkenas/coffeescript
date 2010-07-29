var eldest, grade;
grade = function(student) {
  if (student.excellentWork) {
    return "A+";
  } else if (student.okayStuff) {
    return student.triedHard ? "B" : "B-";
  } else {
    return "C";
  }
};
eldest = 24 > 21 ? "Liz" : "Ike";