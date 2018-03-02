## Comments

In CoffeeScript, comments are denoted by the `#` character to the end of a line, or from `###` to the next appearance of `###`. Comments are ignored by the compiler, though the compiler makes its best effort at reinserting your comments into the output JavaScript after compilation.

```
codeFor('comment')
```

Inline `###` comments make [type annotations](#type-annotations) possible.