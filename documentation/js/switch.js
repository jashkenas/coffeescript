(function(){
  if (day === "Mon") {
    go_to_work();
  } else if (day === "Tue") {
    go_to_the_park();
  } else if (day === "Thu") {
    go_ice_fishing();
  } else if (day === "Fri" || day === "Sat") {
    if (day === bingo_day) {
      go_to_bingo();
      go_dancing();
    }
  } else if (day === "Sun") {
    go_to_church();
  } else {
    go_to_work();
  }
})();
