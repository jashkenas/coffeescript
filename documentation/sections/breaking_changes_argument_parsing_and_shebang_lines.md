### Argument parsing and shebang (`#!`) lines

In CoffeeScript 1.x, `--` was required after the path and filename of the script to be run, but before any arguments passed to that script. This convention is now deprecated. So instead of:

```bash
coffee [options] path/to/script.coffee -- [args]
```

Now you would just type:

```bash
coffee [options] path/to/script.coffee [args]
```

The deprecated version will still work, but it will print a warning before running the script.

On non-Windows platforms, a `.coffee` file can be made executable by adding a shebang (`#!`) line at the top of the file and marking the file as executable. For example:

```coffee
#!/usr/bin/env coffee

x = 2 + 2
console.log x
```

If this were saved as `executable.coffee`, it could be made executable and run:

```bash
▶ chmod +x ./executable.coffee
▶ ./executable.coffee
4
```

In CoffeeScript 1.x, this used to fail when trying to pass arguments to the script. Some users on OS X worked around the problem by using `#!/usr/bin/env coffee --` as the first line of the file. That didn’t work on Linux, however, which cannot parse shebang lines with more than a single argument. While such scripts will still run on OS X, CoffeeScript will now display a warning before compiling or evaluating files that begin with a too-long shebang line. Now that CoffeeScript 2 supports passing arguments without needing `--`, we recommend simply changing the shebang lines in such scripts to just `#!/usr/bin/env coffee`.