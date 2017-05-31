## Comments

In CoffeeScript, comments are denoted by the `#` character. Everything from a `#` to the end of the line is ignored by the compiler, and will be excluded from the JavaScript output.

```
codeFor('comment')
```

Sometimes you’d like to pass a block comment through to the generated JavaScript. For example, when you need to embed a licensing header at the top of a file. Block comments, which mirror the syntax for block strings, are preserved in the generated output.

```
codeFor('block_comment')
```
