## Type Annotations

Static type checking can be achieved in CoffeeScript by using [Flow](https://flow.org/)’s [Comment Types syntax](https://flow.org/en/docs/types/comments/):

```
codeFor('type_annotations')
```

CoffeeScript does not do any type checking itself; the JavaScript output you see above needs to get passed to Flow for it to validate your code. We expect most people will use a [build tool](#es2015plus-output) for this, but here’s how to do it the simplest way possible using the [CoffeeScript](#cli) and [Flow](https://flow.org/en/docs/usage/) command-line tools, assuming you’ve already [installed Flow](https://flow.org/en/docs/install/) and the [latest CoffeeScript](#installation) in your project folder:

```bash
coffee --bare --no-header --compile app.coffee && npm run flow
```

`--bare` and `--no-header` are important because Flow requires the first line of the file to be the comment `// @flow`. If you configure your build chain to compile CoffeeScript and pass the result to Flow in-memory, you can get better performance than this example; and a proper build tool should be able to watch your CoffeeScript files and recompile and type-check them for you on save.

If you know of another way to achieve static type checking with CoffeeScript, please [create an issue](https://github.com/jashkenas/coffeescript/issues/new) and let us know.