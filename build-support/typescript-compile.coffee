# This script will compile coffeescript sources, retain the source maps, then use those to map
# errors from the typescript compilation back to the coffeescript source, since tsc does not
# read source maps for js inputs for some incredibly strange reason, as if there are no other
# languages who would compile to js and generate jsdoc. Anyway, I hope we can convince them to add
# support for it, but it seems appropriate to focus on coffeescript itself first.

'''
# e.g. run these shell commands from the repo root (you'll need to have npm installed typescript):
; cat > test-map.coffee <<EOF
y = 3

###* @type {string} ###
x @= 3
EOF
; coffee build-support/typescript-compile.coffee test-map.coffee
test-map.coffee:4:1 - error TS2322: Type 'number' is not assignable to type 'string'.

4 x @= 3
  ~
# it also generates adjacent .js and .js.map files:
; cat test-map.js
var y;

y = 3;

/** @type {string} */
var x = 3;

//# sourceMappingURL=test-map.js.map
; cat test-map.js.map
{
  "version": 3,
  "file": "test-map.js",
  "sourceRoot": "/home/cosmicexplorer/tools/coffeescript",
  "sources": [
    "test-map.coffee"
  ],
  "names": [],
  "mappings": "AAAA,IAAA;;AAAA,CAAA,GAAI,EAAJ;;;AAGA,IAAA,CAAA,GAAK",
  "sourcesContent": [
    "y = 3\n\n###* @type {string} ###\nx @= 3\n"
  ]
}
# finally, it also generates a .d.ts type definition file:
; cat test-map.d.ts
declare var y: any;
/** @type {string} */
declare var x: string;
'''

assert       = require 'assert'
fs           = require 'fs'
path         = require 'path'
process      = require 'process'

CoffeeScript = require '../lib/coffeescript/index'
ts           = require 'typescript'

coffeeCompileWithSourceMap = (fileNames) ->
  for f in fileNames
    out = f.replace /\.(lit)?coffee$/, '.js'
    mapOut = "#{out}.map"
    code = fs.readFileSync f, 'utf8'
    {js, v3SourceMap, sourceMap} = CoffeeScript.compile code,
      filename: f
      generatedFile: out
      bare: yes
      literate: f.endsWith '.litcoffee'
      header: no
      sourceMap: yes
      sourceRoot: process.cwd()
    fs.writeFileSync out, "#{js}\n//# sourceMappingURL=#{mapOut}\n"
    fs.writeFileSync mapOut, "#{v3SourceMap}\n"
    {
      original: f
      opath: path.resolve f
      code: code
      codeLines: code.split '\n'
      js: out
      mapFile: mapOut
      map: sourceMap
    }

compiled = coffeeCompileWithSourceMap process.argv[2..]
byJsPath = {}
for {js, original, opath, code, codeLines, map} in compiled
  byJsPath[path.resolve js] = {original, opath, code, codeLines, map}

generateMappedCoffeeSource = (name, filePath, content) ->
  {
    ...(ts.createSourceFile name, content, ts.ScriptTarget.Latest, no, ts.ScriptKind.Unknown),
    statements: [],
    parseDiagnostics: [],
    identifiers: new Map,
    path: filePath,
    resolvedPath: filePath,
    originalFileName: name
  }

locationToOffset = (contentLines, line, column) ->
  offset = 0
  for i in [0...line]
    cur = contentLines[i]
    # NB: add 1 for newline
    offset += cur.length + 1
  offset += column
  offset

mapSpan = (diag, map, contentLines, content) ->
  {line: startLine, character: startCol} = ts.getLineAndCharacterOfPosition diag.file, diag.start
  {line: endLine, character: endCol} = ts.getLineAndCharacterOfPosition diag.file, (diag.start + diag.length)

  [origStartLine, origStartCol] = map.sourceLocation [startLine, startCol]
  [origEndLine, origEndCol] = map.sourceLocation [endLine, endCol]

  # NB: the end column appears to get set to 0 for certain spans, including some (all?) symbols and
  #     literal strings. unclear why this occurs, but we are interpreting it as "same in output"
  lengthInferred = origEndLine == origStartLine and origEndCol == 0

  origStart = locationToOffset contentLines, origStartLine, origStartCol

  origEnd = if lengthInferred then origStart + diag.length
  else locationToOffset contentLines, origEndLine, origEndCol

  {start: origStart, length: origEnd - origStart}

checkMappedJsDoc = (mappedCompiled, options) ->
  fileNames = (k for own k of mappedCompiled)
  for f in fileNames
    assert f.endsWith '.js'
  program = ts.createProgram fileNames, options
  emitResult = program.emit()

  rawDiagnostics = ts.getPreEmitDiagnostics(program).concat(emitResult.diagnostics)

  mappedDiagnostics = for diag in rawDiagnostics
    continue unless diag.file?
    continue unless mappedCompiled[diag.file.resolvedPath]?
    {original, opath, code, codeLines, map} = mappedCompiled[diag.file.resolvedPath]
    realSource = generateMappedCoffeeSource original, opath, code
    {start: realStart, length: realLength} = mapSpan diag, map, codeLines, code
    {
      ...diag,
      file: realSource,
      start: realStart,
      length: realLength,
    }

  console.log ts.formatDiagnosticsWithColorAndContext mappedDiagnostics,
    getCurrentDirectory: -> process.cwd()
    getNewLine: -> '\n'
    getCanonicalFileName: (fileName) -> fileName

  exitCode = if emitResult.emitSkipped then 1 else 0
  process.exit exitCode


checkMappedJsDoc byJsPath,
  allowJs: yes
  checkJs: yes
  declaration: yes
  emitDeclarationOnly: yes
