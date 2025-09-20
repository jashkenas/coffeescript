#!/usr/bin/env coffee

###
Run CS3 Test Suite with CS2 Parser
===================================
This runs our CS3 test files using the CS2 parser/compiler
(CoffeeScript 2.x) instead of the CS3/ES5 pipeline, to verify compatibility.
###

fs = require 'fs'
path = require 'path'
CoffeeScript = require '../lib/coffeescript'

# Test helpers
passedTests = 0
failedTests = 0
errors = []

global.test = (description, fn) ->
  try
    fn()
    passedTests++
    console.log "#{green}✓#{reset} #{description}"
  catch error
    failedTests++
    console.log "#{red}✗#{reset} #{description}: #{error.message}"
    errors.push {description, error: error.message}

global.eq = (actual, expected) ->
  throw new Error("Expected #{expected}, got #{actual}") unless actual == expected

global.ok = (value) ->
  throw new Error("Expected truthy value, got #{value}") unless value

global.throws = (fn, expected) ->
  try
    fn()
    throw new Error("Expected function to throw")
  catch e
    if expected and e.message.indexOf(expected) == -1
      throw new Error("Expected error containing '#{expected}', got '#{e.message}'")

global.arrayEq = (actual, expected) ->
  throw new Error("Arrays have different lengths") unless actual.length == expected.length
  for val, i in expected
    throw new Error("Arrays differ at index #{i}") unless actual[i] == val

global.deepEqual = (actual, expected) ->
  JSON.stringify(actual) == JSON.stringify(expected)

# Color codes
green = '\x1b[0;32m'
red = '\x1b[0;31m'
yellow = '\x1b[0;33m'
bold = '\x1b[0;1m'
reset = '\x1b[0m'

console.log "#{bold}CS3 Test Suite - Running with CS2 Parser#{reset}\n"

# Get all test files
testDir = __dirname
testFiles = fs.readdirSync(testDir).filter (f) -> f.endsWith('.test.coffee')
testFiles.sort()

totalFiles = testFiles.length
compiledFiles = 0
runFiles = 0

# Run each test file
for filename in testFiles
  filepath = path.join(testDir, filename)
  console.log "\n#{bold}Testing: #{filename}#{reset}"

  try
    # Read the test file
    code = fs.readFileSync(filepath, 'utf8')

    # Compile with CS2 parser (cs3: false or undefined)
    compiled = CoffeeScript.compile code,
      filename: filename
      bare: true
      cs3: false  # Explicitly use CS2 parser

    compiledFiles++

    # Run the compiled JavaScript
    try
      eval(compiled)
      runFiles++
    catch runError
      console.log "\n#{red}RUNTIME ERROR: #{runError.message}#{reset}"
      errors.push {description: filename, error: runError.message}

  catch compileError
    console.log "#{red}COMPILATION ERROR: #{compileError.message}#{reset}"
    errors.push {description: filename, error: compileError.message}

if failedTests > 0
  console.log "\n#{bold}Errors:#{reset}"
  for error in errors
    console.log "  #{red}#{error.description}:#{reset} #{error.error}"

# Summary
console.log "\n#{bold}Results:#{reset}"
console.log "#{green}Passed: #{passedTests}#{reset}"

if failedTests > 0
  console.log "#{red}Failed: #{failedTests}#{reset}"
else
  console.log "#{green}All tests passed!#{reset}"

successRate = if passedTests + failedTests > 0
  (passedTests / (passedTests + failedTests) * 100).toFixed(1)
else
  "0.0"

# Parser info
console.log "\n#{bold}========================================#{reset}"
console.log "#{bold}CS2 Parser Summary:#{reset}"
console.log "#{bold}========================================#{reset}\n"
console.log "Parser:       CS2 (grammar.coffee -> parser-cs2.js) [Solar parser]"
console.log "Backend:      ES5 (AST instances)"
console.log "Pass Rate:    #{successRate}%"

# Exit code
process.exit(if failedTests > 0 or errors.length > 0 then 1 else 0)
