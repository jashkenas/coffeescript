weather_report: location =>
  # Make an Ajax request to fetch the weather...
  [location, 72, "Mostly Sunny"]

[city, temp, forecast]: weather_report "Berkeley, CA"