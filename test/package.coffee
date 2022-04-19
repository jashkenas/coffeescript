return if window? or testingBrowser?

{EventEmitter}  = require 'events'
{join}          = require 'path'
{cwd}           = require 'process'
{pathToFileURL} = require 'url'


packageEntryPath = join cwd(), 'lib/coffeescript/index.js'
packageEntryUrl  = pathToFileURL packageEntryPath


test "the coffeescript package exposes all members as named exports in Node", ->

  requiredPackage = require packageEntryPath
  requiredKeys = Object.keys requiredPackage

  importedPackage = await import(packageEntryUrl)
  importedKeys = new Set Object.keys(importedPackage)

  # In `command.coffee`, CoffeeScript extends a `new EventEmitter`;
  # we want to ignore these additional added keys.
  eventEmitterKeys = new Set Object.getOwnPropertyNames(Object.getPrototypeOf(new EventEmitter))

  for key in requiredKeys when not eventEmitterKeys.has(key)
    # Use `eq` test so that missing keys have their names printed in the error message.
    eq (if importedKeys.has(key) then key else undefined), key
