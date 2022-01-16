# This file is running in CommonJS (in Node) or as a classic Script (in the browser tests) so it can use import() within an async function, but not at the top level; and we can’t use static import
test "dynamic import assertion", ->
  { default: secret } = await import('data:application/json,{"ofLife":42}', { assert: { type: 'json' } })
  eq secret.ofLife, 42
