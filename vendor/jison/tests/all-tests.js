#!/usr/bin/env narwhal

exports.testParser = require("./parser/parser-tests");
exports.testLexer = require("./lexer/lexer-tests");
exports.testGrammar = require("./grammar/grammar-tests");

if (require.main === module)
    require("os").exit(require("test").run(exports)); 
