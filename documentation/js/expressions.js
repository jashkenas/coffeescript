(function(){
  var eldest, grade;
  grade = function grade(student) {
    if (student.excellent_work) {
      return "A+";
    } else if (student.okay_stuff) {
      return student.tried_hard ? "B" : "B-";
    } else {
      return "C";
    }
  };
  eldest = 24 > 21 ? "Liz" : "Ike";
})();
