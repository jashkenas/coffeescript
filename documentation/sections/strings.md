## Strings

Like JavaScript and many other languages, CoffeeScript supports strings as delimited by the `"` or `'` characters. CoffeeScript also supports string interpolation within `"`-quoted strings, using `#{ … }`. Single-quoted strings are literal. You may even use interpolation in object keys.

```
codeFor('interpolation', 'sentence')
```

Multiline strings are allowed in CoffeeScript. Lines are joined by a single space unless they end with a backslash. Indentation is ignored.

```
codeFor('strings', 'mobyDick')
```

Block strings, delimited by `"""` or `'''`, can be used to hold formatted or indentation-sensitive text (or, if you just don’t feel like escaping quotes and apostrophes). The indentation level that begins the block is maintained throughout, so you can keep it all aligned with the body of your code.

```
codeFor('heredocs', 'html')
```

Double-quoted block strings, like other double-quoted strings, allow interpolation.
