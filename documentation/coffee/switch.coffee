switch day
  when "Mon" then go_to_work()
  when "Tue" then go_to_the_park()
  when "Thu" then go_ice_fishing()
  when "Fri", "Sat"
    if day is bingo_day
      go_to_bingo()
      go_dancing()
  when "Sun" then go_to_church()
  else go_to_work()