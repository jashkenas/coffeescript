(function(){
  var _a, city, forecast, temp, weather_report;
  weather_report = function(location) {
    // Make an Ajax request to fetch the weather...
    return [location, 72, "Mostly Sunny"];
  };
  _a = weather_report("Berkeley, CA");
  city = _a[0];
  temp = _a[1];
  forecast = _a[2];
})();
