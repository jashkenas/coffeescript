(function(){
  var grade = function(student) {
    if (student.excellent_work) {
      return "A+";
    } else if (student.okay_stuff) {
      return if (student.tried_hard) {
        return "B";
      } else {
        return "B-";
      };
    } else {
      return "C";
    }
  };
  var eldest = 24 > 21 ? "Liz" : "Ike";
})();