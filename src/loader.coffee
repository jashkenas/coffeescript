#!/usr/bin/env coffee

import { readFile } from "fs/promises"
import { readFileSync } from "fs"
import { createRequire } from "module"
import { dirname, extname, resolve as resolvePath } from "path"
import { cwd } from "process"
import { fileURLToPath, pathToFileURL } from "url"
import CoffeeScript from "./index.cjs"

baseURL = pathToFileURL("#{cwd}/").href

is_coffee = (specifier)=>
  specifier.slice(specifier.lastIndexOf(".") + 1) == 'coffee'

export resolve = (specifier, context, defaultResolve) =>
  { parentURL = baseURL } = context

  if is_coffee(specifier)
    return {
      shortCircuit: true,
      url: new URL(specifier, parentURL).href
    }

  defaultResolve(specifier, context, defaultResolve)

export load = (url, context, defaultLoad)=>
  if is_coffee(url)
    format = await getPackageType(url)
    if format == "commonjs"
      return { format }

    { source: rawSource } = await defaultLoad(url, { format })
    transformedSource = CoffeeScript.compile(rawSource.toString(), {
      bare: true,
      filename: url,
      inlineMap: true,
    })

    return {
      format
      source: transformedSource,
    }

  return defaultLoad(url, context, defaultLoad)

getPackageType = (url) =>
  isFilePath = !!extname(url)
  dir = if isFilePath then dirname(fileURLToPath(url)) else url
  packagePath = resolvePath(dir, "package.json")
  type = await readFile(packagePath, { encoding: "utf8" })
    .then((filestring) => JSON.parse(filestring).type)
    .catch (err) =>
      if err?.code != "ENOENT"
        console.error(err)
  if type
    return type
  return dir.length > 1 and getPackageType(resolvePath(dir, ".."))
