# CoffeeScript ESM loader
#
# Usage:
# node --loader coffeescript/esm source.coffee

CoffeeScript = require './'
fs           = require 'fs'
module       = require 'module'
path         = require 'path'
{fileURLToPath, pathToFileURL} = require 'url'

{patchStackTrace} = CoffeeScript

nodeSourceMapsSupportEnabled = process? and (
  process.execArgv.includes('--enable-source-maps') or
  process.env.NODE_OPTIONS?.includes('--enable-source-maps')
)

unless Error.prepareStackTrace or nodeSourceMapsSupportEnabled
  cacheSourceMaps = true
  patchStackTrace()

baseURL = pathToFileURL(process.cwd() + '/').href

exports.resolve = (specifier, context, next) ->
  if CoffeeScript.FILE_EXTENSIONS.includes path.extname specifier
    {parentURL} = context
    parentURL ?= baseURL

    shortCircuit: true
    format: "coffee"
    url: new URL(specifier, parentURL).href
  else
    # Not CoffeeScript; pass on to next resolver
    next specifier, context

exports.load = (url, context, next) ->
  # Support only local .coffee files for now
  unless context.format is "coffee" and url.startsWith 'file:'
    return next url, context

  options = module.options or getRootModule(module).options or {}

  # Currently `CoffeeScript.compile` caches all source maps if present. They
  # are available in `getSourceMap` retrieved by `filename`.
  if cacheSourceMaps or nodeSourceMapsSupportEnabled
    options = {...options, inlineMap: true}

  path = fileURLToPath url
  js = CoffeeScript._compileFile path, options

  # Add .js extension to enable other JavaScript ESM loaders (e.g. Babel)
  result = await next url + '.js',
    format: "module"
    source: js

  # Remove .js extension from final URL
  result.responseURL = (result.responseURL ? transpiledUrl)
  .replace /\.js$/, ''

  result

# Utility function to find the `options` object attached to the topmost module.
getRootModule = (module) ->
  if module.parent then getRootModule module.parent else module
