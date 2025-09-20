#!/usr/bin/env coffee

###
CS3/ES5 Test Runner
===================
Uses the actual CS3 parser (parser-cs3.js) with ES5 backend
###

fs = require 'fs'
path = require 'path'
CoffeeScript = require '../lib/coffeescript'
{Lexer} = require '../lib/coffeescript/lexer'

# Load CS3 parser and ES5 backend
try
  parserCS3 = require '../lib/coffeescript/parser-cs3'
catch err
  console.error "CS3 parser not available: #{err.message}"
  process.exit 1

try
  ES5Backend = require '../lib/coffeescript/es6'
catch err
  console.error "ES5 backend not available: #{err.message}"
  process.exit 1

# ANSI colors
green = '\x1B[0;32m'
red = '\x1B[0;31m'
yellow = '\x1B[0;33m'
bold = '\x1B[0;1m'
reset = '\x1B[0m'

# Test tracking
passed = 0
failed = 0
errors = []

# Simple test function
global.test = (name, fn) ->
  try
    fn()
    passed++
    console.log "#{green}✓#{reset} #{name}"
  catch e
    failed++
    errors.push {name, error: e.message}
    console.log "#{red}✗#{reset} #{name}: #{e.message}"

# Test helpers
global.eq = (actual, expected) ->
  if actual isnt expected
    throw new Error "Expected #{expected}, got #{actual}"

global.ok = (value) ->
  throw new Error "Expected truthy value" unless value

global.throws = (fn, message) ->
  try
    fn()
    throw new Error "Expected error: #{message}"
  catch e
    throw e if e.message is "Expected error: #{message}"

global.arrayEq = (actual, expected) ->
  throw new Error "Arrays have different lengths" unless actual.length is expected.length
  for val, i in expected
    throw new Error "Arrays differ at index #{i}" unless actual[i] is val

global.deepEqual = (actual, expected) ->
  JSON.stringify(actual) is JSON.stringify(expected)

# ACTUAL CS3 compilation using parser-cs3 and ES5 backend
compileCS3Real = (code, options = {}) ->
  # Add ES6 flag from command line arguments if present
  options.es6 = true if '--es6' in process.argv

  # Tokenize using CS3 lexer
  lexer = new Lexer()
  tokens = lexer.tokenize code, options

  # Create lexer interface for Solar parser
  i = 0
  lexIface =
    lex: ->
      return 1 if i >= tokens.length
      t = tokens[i++]
      @yytext = t[1]
      @yylloc = t[2]
      @yylineno = if t[2] then t[2].first_line else 0
      @yyleng = String(@yytext).length
      parserCS3.parser.symbolIds[t[0]] or parserCS3.parser.symbolIds[t[1]]
    setInput: -> i = 0
    upcomingInput: -> ''

  # Set up parser with ES5 backend
  backend = new ES5Backend(options)
  parserCS3.parser.lexer = lexIface
  parserCS3.parser.yy = { backend }

  # Parse with CS3 parser
  ast = parserCS3.parse()

  # Generate JavaScript from AST
  result = if ast?.compile
    ast.compile(backend.compileOptions)
  else if backend?.generate
    backend.generate ast
  else
    ''

  result or ''

# Run a test file
runTestFile = (filepath) ->
  console.log "\n#{bold}Testing: #{path.basename(filepath)}#{reset}"
  code = fs.readFileSync(filepath, 'utf8')

  try
    # Compile with REAL CS3 parser
    js = compileCS3Real(code, bare: true, filename: filepath)

    # Run the compiled code
    eval(js)
  catch e
    failed++
    errors.push {name: filepath, error: e.message}
    console.log "#{red}Compilation/Runtime Error: #{e.message}#{reset}"

# Main
console.log "#{bold}CS3 Test Suite - Running with CS3 Parser#{reset}\n"

# Find all test files
testDir = __dirname
testFiles = fs.readdirSync(testDir)
  .filter (f) -> f.endsWith('.test.coffee')
  .sort()
  .map (f) -> path.join(testDir, f)

# Run each test file
for file in testFiles
  runTestFile(file)

# Errors
if failed > 0
  console.log "\n#{bold}Errors:#{reset}"
  for {name, error} in errors
    console.log "  #{red}#{name}:#{reset} #{error}"

# Summary
console.log "\n#{bold}Results:#{reset}"
console.log "#{green}Passed: #{passed}#{reset}"
if failed > 0
  console.log "#{red}Failed: #{failed}#{reset}"
else
  console.log "#{green}All tests passed!#{reset}"

# Parser info
successRate = if passed + failed > 0
  (passed / (passed + failed) * 100).toFixed(1)
else
  "0.0"

console.log "\n#{bold}========================================#{reset}"
console.log "#{bold}CS3 Parser Summary:#{reset}"
console.log "#{bold}========================================#{reset}\n"
console.log "Parser:       CS3 (syntax.coffee -> parser-cs3.js) [Solar parser]"
console.log "Backend:      ES6 (AST data nodes)"
console.log "Pass Rate:    #{successRate}%"

process.exit(if failed > 0 then 1 else 0)
