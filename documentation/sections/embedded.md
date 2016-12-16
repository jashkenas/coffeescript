## Embedded JavaScript

Hopefully, you’ll never need to use it, but if you ever need to intersperse snippets of JavaScript within your CoffeeScript, you can use backticks to pass it straight through.

```
codeFor('embedded', 'hi()')
```

Escape backticks with backslashes: `` \`​`` becomes `` `​``.

Escape backslashes before backticks with more backslashes: `` \\\`​`` becomes `` \`​``.

```
codeFor('embedded_escaped', 'markdown()')
```

You can also embed blocks of JavaScript using triple backticks. That’s easier than escaping backticks, if you need them inside your JavaScript block.

```
codeFor('embedded_block', 'time()')
```
