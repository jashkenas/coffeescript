var eldest, grade;
grade = function(student) {
  return student.excellentWork ? "A+" : (student.okayStuff ? (student.triedHard ? "B" : "B-") : "C");
};
eldest = 24 > 21 ? "Liz" : "Ike";