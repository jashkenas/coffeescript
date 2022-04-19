# This file throws an error on line 3. It is used for testing error stack traces with sourcemaps.
module.exports =
  throw new Error 'I am error'
