(function(){
  alert((function() {
    try {
      return nonexistent / undefined;
    } catch (error) {
      return "The error is: " + error;
    }
  })());
})();