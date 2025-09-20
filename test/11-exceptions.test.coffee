# Test exception handling

test "try-catch", ->
  result = null
  try
    result = "success"
  catch e
    result = "error"
  eq result, "success"

test "throw and catch", ->
  result = null
  try
    throw new Error("test error")
  catch e
    result = e.message
  eq result, "test error"

test "finally block", ->
  executed = false
  try
    # do nothing
  finally
    executed = true
  ok executed

test "try-catch-finally", ->
  steps = []
  try
    steps.push "try"
    throw new Error("test")
  catch e
    steps.push "catch"
  finally
    steps.push "finally"

  eq steps[0], "try"
  eq steps[1], "catch"
  eq steps[2], "finally"

test "nested try-catch", ->
  outer = null
  inner = null

  try
    try
      throw new Error("inner error")
    catch e
      inner = e.message
      throw new Error("outer error")
  catch e
    outer = e.message

  eq inner, "inner error"
  eq outer, "outer error"

test "catch with specific error", ->
  CustomError = class extends Error

  result = null
  try
    throw new CustomError("custom")
  catch e
    if e instanceof CustomError
      result = "custom caught"
    else
      throw e

  eq result, "custom caught"

test "rethrow", ->
  errorCaught = false
  try
    try
      throw new Error("test")
    catch e
      throw e
  catch e
    errorCaught = true

  ok errorCaught

test "return in finally", ->
  getValue = ->
    try
      return "try"
    finally
      # finally executes but doesn't override return
      "finally"

  eq getValue(), "try"
