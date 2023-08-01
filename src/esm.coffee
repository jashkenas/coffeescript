# CoffeeScript ESM loader
#
# Usage: node --loader coffeescript/esm source.coffee
#
# Based on https://nodejs.org/api/esm.html#esm_transpiler_loader and
# https://github.com/DanielXMoore/Civet/blob/main/source/esm.civet

CoffeeScript = require './'
fs           = require 'fs'
module       = require 'module'
{extname}    = require 'path'
{fileURLToPath, pathToFileURL} = require 'url'

CoffeeScript.patchStackTrace()

baseURL = pathToFileURL(process.cwd() + '/').href

exports.resolve = (specifier, context, next) ->
  if CoffeeScript.FILE_EXTENSIONS.includes extname specifier
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

  options = module.options or
            CoffeeScript.helpers.getRootModule(module).options or {}

  # Currently `CoffeeScript.compile` caches all source maps if present. They
  # are available in `getSourceMap` retrieved by `filename`.
  options = {...options, inlineMap: true}

  path = fileURLToPath url
  js = CoffeeScript._compileFile path, options

  # Add .js extension to enable other JavaScript ESM loaders (e.g. Babel)
  result = await next url + '.js',
    # Currently assume that, if you're using the loader, you want ESM format.
    format: "module"
    source: js

  # Remove .js extension from final URL
  result.responseURL = (result.responseURL ? transpiledUrl)
  .replace /\.js$/, ''

  result
