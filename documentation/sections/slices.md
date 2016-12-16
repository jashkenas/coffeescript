## Array Slicing and Splicing with Ranges

Ranges can also be used to extract slices of arrays. With two dots (`3..6`), the range is inclusive (`3, 4, 5, 6`); with three dots (`3...6`), the range excludes the end (`3, 4, 5`). Slices indices have useful defaults. An omitted first index defaults to zero and an omitted second index defaults to the size of the array.

```
codeFor('slices', 'middle')
```

The same syntax can be used with assignment to replace a segment of an array with new values, splicing it.

```
codeFor('splices', 'numbers')
```

Note that JavaScript strings are immutable, and can’t be spliced.
