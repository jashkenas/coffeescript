## String Interpolation, Block Strings, and Block Comments

Ruby-style string interpolation is included in CoffeeScript. Double-quoted strings allow for interpolated values, using `#{ … }`, and single-quoted strings are literal. You may even use interpolation in object keys.

```
codeFor('interpolation', 'sentence')
```

Multiline strings are allowed in CoffeeScript. Lines are joined by a single space unless they end with a backslash. Indentation is ignored.

```
codeFor('strings', 'mobyDick')
```

Block strings can be used to hold formatted or indentation-sensitive text (or, if you just don’t feel like escaping quotes and apostrophes). The indentation level that begins the block is maintained throughout, so you can keep it all aligned with the body of your code.

```
codeFor('heredocs', 'html')
```

Double-quoted block strings, like other double-quoted strings, allow interpolation.

Sometimes you’d like to pass a block comment through to the generated JavaScript. For example, when you need to embed a licensing header at the top of a file. Block comments, which mirror the syntax for block strings, are preserved in the generated code.

```
codeFor('block_comment')
```
