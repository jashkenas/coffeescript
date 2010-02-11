#!/usr/bin/env narwhal

//exports.testBNF = require("./bnf");
exports.testBNFParse = require("./bnf_parse");
exports.testConvert = require("./json2jison");
//exports.testLex = require("./lex");
exports.testLexParse = require("./lex_parse");

if (require.main === module)
    require("os").exit(require("test").run(exports)); 
