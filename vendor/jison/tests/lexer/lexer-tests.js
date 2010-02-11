#!/usr/bin/env narwhal

exports.testRegExpLexer = require("./regexplexer");

if (require.main === module)
    require("os").exit(require("test").run(exports)); 
