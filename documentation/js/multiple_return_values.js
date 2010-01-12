(function(){
  var __a, city, forecast, temp, weather_report;
  weather_report = function weather_report(location) {
    // Make an Ajax request to fetch the weather...
    return [location, 72, "Mostly Sunny"];
  };
  __a = weather_report("Berkeley, CA");
  city = __a[0];
  temp = __a[1];
  forecast = __a[2];
})();