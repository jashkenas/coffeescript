# This file is running in CommonJS (in Node) or as a classic Script (in the browser tests) so it can use import() within an async function, but not at the top level; and we can’t use static import.
test "dynamic import assertion", ->
  if typeof process is "undefined" or process.version?.startsWith("v17")
    { default: secret } = await import('data:application/json,{"ofLife":42}', { assert: { type: 'json' } })
    eq secret.ofLife, 42

test "assert keyword", ->
  if typeof process is "undefined" or process.version?.startsWith("v17")
    assert = 1

    { default: assert } = await import('data:application/json,{"thatIAm":42}', { assert: { type: 'json' } })
    eq assert.thatIAm, 42

    eqJS """
      import assert from 'regression-test'
    """, """
      import assert from 'regression-test';
    """

test "static import assertion", ->
  eqJS """
    import 'data:application/json,{"foo":3}' assert { type: 'json' }
  """, """
    import 'data:application/json,{"foo":3}' assert {
      type: 'json'
    };
  """

  eqJS """
    import secret from 'data:application/json,{"ofLife":42}' assert { type: 'json' }
  """, """
    import secret from 'data:application/json,{"ofLife":42}' assert {
      type: 'json'
    };
  """

  eqJS """
    import * as secret from 'data:application/json,{"ofLife":42}' assert { type: 'json' }
  """, """
    import * as secret from 'data:application/json,{"ofLife":42}' assert {
      type: 'json'
    };
  """

  # The only file types for which import assertions are currently supported are JSON (Node and browsers) and CSS (browsers), neither of which support named exports; however there’s nothing in the JavaScript grammar preventing a future supported file type from providing named exports.
  eqJS """
    import { foo } from './file.unknown' assert { type: 'unknown' }
  """, """
    import {
      foo
    } from './file.unknown' assert {
        type: 'unknown'
      };
  """

  eqJS """
    import file, { foo } from './file.unknown' assert { type: 'unknown' }
  """, """
    import file, {
      foo
    } from './file.unknown' assert {
        type: 'unknown'
      };
  """

  eqJS """
    import foo from 'bar' assert {}
  """, """
    import foo from 'bar' assert {};
  """

test "static export with assertion", ->
  eqJS """
    export * from 'data:application/json,{"foo":3}' assert { type: 'json' }
  """, """
    export * from 'data:application/json,{"foo":3}' assert {
      type: 'json'
    };
  """

  eqJS """
    export { profile } from './user.json' assert { type: 'json' }
  """, """
    export {
      profile
    } from './user.json' assert {
        type: 'json'
      };
  """
