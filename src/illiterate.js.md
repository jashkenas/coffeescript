# Illiterate

Extract code block from markdown à la coffeescript - but for **any** language.

## Usage

> illiterate file.js.md > file.js

After being processed by `illiterate`, this readme file contains only the indented javascript code blocks. The output can be seen in [bin/illiterate.js](./bin/illiterate.js).

## Build

In order to build, you must have `illiterate` installed, and then do...

> npm run build

> ./bin/illiterate readme.md > temp && rm bin/illiterate.js && mv temp bin/illiterate.js

(temp file is used to prevent issues with overwriting currently executing file)

## Source

This file is the documentation, and also is itself the source for a binary which is capable of compiling itself. Anything in this file which is indented is interpreted by markdown as code, and ends up in the compiled output.

### Initialize environment

Create self executing enclosure - convert function into expression by prefixing `!` which prevents accidental invokation of code concatenated beforehand. Might not pass JSLint with default options, but if it is good enough for twitter, it is good enough for me :)

	!function(){

		var illiterate = {};

		if (typeof exports !== 'undefined') {
			if (typeof module !== 'undefined' && module.exports) {
				exports = module.exports = illiterate;
			}
		}

Load dependencies.

		var _ = require('lodash'),
			marked = require('marked');

		illiterate.parse = function(file_contents){

Create a variable to store output as it is built up from input files

			var out = [];

### Main loop


Read each file, and loop through each line

			out.push( _.reduce(marked.lexer(file_contents, {}), function(memo, item){
				if(item.type === 'code'){
					memo.push(item.text);
				}
				return memo;
			}, [] ).join('\n'));

### Output

Finally, output all lines

			return out.join('\n');

		};


### Fin

		if (typeof define === 'function' && define.amd) {
			define('illiterate', [], function() {
				return illiterate;
			});
		}

		return illiterate;

And finally what has been opened, must be closed, and executed...

	}.call(this);