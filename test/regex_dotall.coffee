# Regex “dotall” flag, or `s`, is only supported in Node 9+, so put tests for
# the feature in their own file. The feature detection in `Cakefile` that
# causes this test to load is adapted from
# https://github.com/tc39/proposal-regexp-dotall-flag#proposed-solution.

test "dotall flag", ->
  doesNotThrow -> /a.b/s.test 'a\nb'
