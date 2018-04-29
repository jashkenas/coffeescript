## Modules

ES2015 modules are supported in CoffeeScript, with very similar `import` and `export` syntax:

```
codeFor('modules')
```

<div id="modules-note" class="bookmark"></div>

Note that the CoffeeScript compiler **does not resolve modules**; writing an `import` or `export` statement in CoffeeScript will produce an `import` or `export` statement in the resulting output. It is your responsibility to [transpile](#transpilation) this ES2015 syntax into code that will work in your target runtimes.

Also note that any file with an `import` or `export` statement will be output without a [top-level function safety wrapper](#lexical-scope); in other words, importing or exporting modules will automatically trigger [bare](#usage) mode for that file. This is because per the ES2015 spec, `import` or `export` statements must occur at the topmost scope.
