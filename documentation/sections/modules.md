## Modules

[ES2015 modules](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules) are supported in CoffeeScript, with very similar `import` and `export` syntax:

```
codeFor('modules')
```

<div id="dynamic-import" class="bookmark"></div>

[Dynamic import](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/import#Dynamic_Imports) is also supported, with mandatory parentheses:

```
codeFor('dynamic_import', true)
```

<div id="modules-note" class="bookmark"></div>

Note that the CoffeeScript compiler **does not resolve modules**; writing an `import` or `export` statement in CoffeeScript will produce an `import` or `export` statement in the resulting output. Such statements can be run by all modern browsers (when the script is referenced via `<script type="module">`) and [by Node.js](https://nodejs.org/api/esm.html#esm_enabling) when the output `.js` files are in a folder where the nearest parent `package.json` file contains `"type": "module"`. Because the runtime is evaluating the generated output, the `import` statements must reference the output files; so if `file.coffee` is output as `file.js`, it needs to be referenced as `file.js` in the `import` statement, with the `.js` extension included.

Also, any file with an `import` or `export` statement will be output without a [top-level function safety wrapper](#lexical-scope); in other words, importing or exporting modules will automatically trigger [bare](#usage) mode for that file. This is because per the ES2015 spec, `import` or `export` statements must occur at the topmost scope.
