# This file is running in CommonJS (in Node) or as a classic Script (in the browser tests) so it can use import() within an async function, but not at the top level; and we can’t use static import.
test "dynamic import assertion", ->
  try
    { default: secret } = await import('data:application/json,{"ofLife":42}', { assert: { type: 'json' } })
    eq secret.ofLife, 42
  catch exception
    # This parses on Node 16.14.x but throws an error because JSON modules aren’t unflagged there yet; remove this try/catch once the unflagging of `--experimental-json-modules` is backported (see https://github.com/nodejs/node/pull/41736#issuecomment-1086738670)
    unless exception.message is 'Invalid module "data:application/json,{"ofLife":42}" has an unsupported MIME type "application/json"'
      throw exception

test "assert keyword", ->
  assert = 1

  try
    { default: assert } = await import('data:application/json,{"thatIAm":42}', { assert: { type: 'json' } })
    eq assert.thatIAm, 42
  catch exception
    # This parses on Node 16.14.x but throws an error because JSON modules aren’t unflagged there yet; remove this try/catch once the unflagging of `--experimental-json-modules` is backported (see https://github.com/nodejs/node/pull/41736#issuecomment-1086738670)
    unless exception.message is 'Invalid module "data:application/json,{"thatIAm":42}" has an unsupported MIME type "application/json"'
      throw exception

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
