### Argument parsing and shebang lines

#### Trailing `--`

Previous versions of CoffeeScript required a `--` after the script to run, but this convention is now deprecated. The new standard is described in the output of `coffee -h`:

``` bash
> coffee -h

Usage: coffee [options] [--] path/to/script.coffee [args]

If called without options, `coffee` will run your script.


```

If the script is run with a `--` after the script, it will show a warning, then run your script.

``` bash
> coffee path/to/script.coffee --
coffee was invoked with '--' as the second positional argument, which is
now deprecated. To pass '--' as an argument to a script to run, put an
additional '--' before the path to your script.

'--' will be removed from the argument list.
The positional arguments were: ["path/to/script.coffee","--"]
...
```

#### Shebang scripts

On non-Windows platforms, a `.coffee` file can be made executable by adding a shebang (`#!`) line at the top of the file and marking the file as executable. For example:

`executable-script.coffee`:
``` coffeescript
#!/usr/bin/env coffee

x = 2 + 2
console.log x
```

``` bash
> chmod +x ./executable-script.coffee
> ./executable-script.coffee
4
```

Due to a bug in the argument parsing of previous CoffeeScript versions, this used to fail when trying to pass arguments to the script. Some users on OSX worked around the problem by using `#!/usr/bin/env coffee --` at the top of the file instead. However, that won't work on Linux, which cannot parse shebang lines with more than a single argument. While these scripts will still run on OSX, CoffeeScript will now display a warning before compiling or evaluating files that begin with a too-long shebang line:

`invalid-executable-script.coffee`:
``` coffeescript
#!/usr/bin/env coffee --

x = 2 + 2
console.log x
```

``` bash
> chmod +x /path/to/invalid-executable-script.coffee
> /path/to/invalid-executable-script.coffee
The script to be run begins with a shebang line with more than one
argument. This script will fail on platforms such as Linux which only
allow a single argument.
The shebang line was: '#!/usr/bin/env coffee --' in file '/path/to/shebang-extra-args.coffee'
The arguments were: ["coffee","--"]
4
```

Note that the script *is* still run, producing the `4` at the bottom.
