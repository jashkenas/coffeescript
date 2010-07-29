alert((function() {
  try {
    return nonexistent / undefined;
  } catch (error) {
    return "And the error is ... " + error;
  }
})());