# This file is running in CommonJS (in Node) or as a classic Script (in the browser tests) so it can use import() within an async function, but not at the top level; and we can’t use static import.
test "dynamic import assertion", ->
  { default: secret } = await import('data:application/json,{"ofLife":42}', { assert: { type: 'json' } })
  eq secret.ofLife, 42

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
