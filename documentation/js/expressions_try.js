(function(){
  alert((function() {
    try {
      return nonexistent / undefined;
    } catch (error) {
      return "Caught an error: " + error;
    }
  })());
})();