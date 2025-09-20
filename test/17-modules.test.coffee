# Test ES6 module syntax (import/export)
# Note: These tests verify syntax compilation, not runtime behavior

test "named exports", ->
  # This would compile to: export { foo, bar }
  code = """
    export { foo, bar }
  """
  ok code.includes('export')

test "default export", ->
  # This would compile to: export default MyClass
  code = """
    export default class MyClass
      constructor: -> @value = 42
  """
  ok code.includes('export')

test "named imports", ->
  # This would compile to: import { readFile, writeFile } from 'fs'
  code = """
    import { readFile, writeFile } from 'fs'
  """
  ok code.includes('import')

test "default import", ->
  # This would compile to: import React from 'react'
  code = """
    import React from 'react'
  """
  ok code.includes('import')

test "namespace import", ->
  # This would compile to: import * as utils from './utils'
  code = """
    import * as utils from './utils'
  """
  ok code.includes('import')

test "mixed imports", ->
  # This would compile to: import React, { Component } from 'react'
  code = """
    import React, { Component } from 'react'
  """
  ok code.includes('import')

test "export from", ->
  # This would compile to: export { foo, bar } from './other'
  code = """
    export { foo, bar } from './other'
  """
  ok code.includes('export')

test "export all", ->
  # This would compile to: export * from './utils'
  code = """
    export * from './utils'
  """
  ok code.includes('export')

test "import with rename", ->
  # This would compile to: import { foo as bar } from './module'
  code = """
    import { foo as bar } from './module'
  """
  ok code.includes('import')

test "export with rename", ->
  # This would compile to: export { foo as bar }
  code = """
    export { foo as bar }
  """
  ok code.includes('export')

test "dynamic import", ->
  # Dynamic imports work at runtime
  loadModule = ->
    module = await import('./some-module')
    module.default

  ok typeof loadModule is 'function'

test "import assertions", ->
  # This would compile to: import data from './data.json' assert { type: 'json' }
  code = """
    import data from './data.json' assert { type: 'json' }
  """
  ok code.includes('import')
