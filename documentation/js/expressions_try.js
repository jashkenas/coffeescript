
alert((function() {
  try {
    return nonexistent / void 0;
  } catch (error) {
    return "And the error is ... " + error;
  }
})());
