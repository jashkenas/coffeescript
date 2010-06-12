switch day
  when "Mon" then goToWork()
  when "Tue" then goToThePark()
  when "Thu" then goIceFishing()
  when "Fri", "Sat"
    if day is bingoDay
      goToBingo()
      goDancing()
  when "Sun" then goToChurch()
  else goToWork()