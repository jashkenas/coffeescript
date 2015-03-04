# Illiterate

Extract code block from markdown à la coffeescript - but for **any** language.

## Usage

> illiterate file.js.md > file.js

After being processed by `illiterate`, this readme file contains only the indented javascript code blocks. The output can be seen in [bin/illiterate.js](./bin/illiterate.js).

## Build

There is no real build process to speak of. I tend to do something like...

> ./bin/illiterate readme.md > temp && rm bin/illiterate.js && mv temp bin/illiterate.js

(temp file is used to prevent issues with overwriting currently executing file)

## Source

This file is the documentation, and also is itself the source for a binary which is capable of compiling itself. Anything in this file which is indented is interpreted by markdown as code, and ends up in the compiled output.

### Initialize environment

Create a variable to store output as it is built up from input files

	var out = [];

### Main loop

Loop through each input file (specified as command line arguments)

	process.argv.slice(2).forEach(function(filename){

Read each file, and loop through each line

		require('fs').readFileSync(filename).toString().split(/\r?\n/).forEach(function(line){

If the line starts with a tab or four spaces, strip it out and include the line in  the output

			['    ', '\t'].forEach(function(delimiter){
				if(line.indexOf(delimiter) === 0){
					out.push(line.substring(delimiter.length));
				}
			});

		});

	});

### Output

Finally, output all lines

	console.log(out.join('\n'));