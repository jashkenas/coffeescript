(function(){
  if (day === "Mon") {
    goToWork();
  } else if (day === "Tue") {
    goToThePark();
  } else if (day === "Thu") {
    goIceFishing();
  } else if (day === "Fri" || day === "Sat") {
    if (day === bingoDay) {
      goToBingo();
      goDancing();
    }
  } else if (day === "Sun") {
    goToChurch();
  } else {
    goToWork();
  }
})();
