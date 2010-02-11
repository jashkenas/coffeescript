var assert = require("assert"),
    lex = require("../../lib/jison/jisonlex");

exports["test lex grammar with macros"] = function () {
    var lexgrammar = 'D [0-9]\nID [a-zA-Z][a-zA-Z0-9]+\n%%\n\n{D}"ohhai" {print(9);}\n"{" {return \'{\';}';
    var expected = {
        macros: [["D", "[0-9]"], ["ID", "[a-zA-Z][a-zA-Z0-9]+"]],
        rules: [
            ["{D}ohhai\\b", "print(9);"],
            ["\\{", "return '{';"]
        ]
    };

    assert.deepEqual(lex.parse(lexgrammar), expected, "grammar should be parsed correctly");
};

exports["test excaped chars"] = function () {
    var lexgrammar = '%%\n"\\n"+ {return \'NL\';}\n\\n+ {return \'NL2\';}\n\\s+ {/* skip */}';
    var expected = {
        rules: [
            ["\\\\n+", "return 'NL';"],
            ["\\n+", "return 'NL2';"],
            ["\\s+", "/* skip */"]
        ]
    };

    assert.deepEqual(lex.parse(lexgrammar), expected, "grammar should be parsed correctly");
};

exports["test advanced"] = function () {
    var lexgrammar = '%%\n$ {return \'EOF\';}\n. {/* skip */}\n"stuff"*/("{"|";") {/* ok */}\n(.+)[a-z]{1,2}"hi"*? {/* skip */}\n';
    var expected = {
        rules: [
            ["$", "return 'EOF';"],
            [".", "/* skip */"],
            ["stuff*(?=(\\{|;))", "/* ok */"],
            ["(.+)[a-z]{1,2}hi*?", "/* skip */"]
        ]
    };

    assert.deepEqual(lex.parse(lexgrammar), expected, "grammar should be parsed correctly");
};

exports["test [^\]]"] = function () {
    var lexgrammar = '%%\n"["[^\\]]"]" {return true;}\n\'f"oo\\\'bar\'  {return \'baz2\';}\n"fo\\"obar"  {return \'baz\';}\n';
    var expected = {
        rules: [
            ["\\[[^\\]]\\]", "return true;"],
            ["f\"oo'bar\\b", "return 'baz2';"],
            ['fo"obar\\b', "return 'baz';"]
        ]
    };

    assert.deepEqual(lex.parse(lexgrammar), expected, "grammar should be parsed correctly");
};

exports["test multiline action"] = function () {
    var lexgrammar = '%%\n"["[^\\]]"]" %{\nreturn true;\n%}\n';
    var expected = {
        rules: [
            ["\\[[^\\]]\\]", "\nreturn true;\n"]
        ]
    };

    assert.deepEqual(lex.parse(lexgrammar), expected, "grammar should be parsed correctly");
};

exports["test include"] = function () {
    var lexgrammar = '\nRULE [0-9]\n\n%{\n hi <stuff> \n%}\n%%\n"["[^\\]]"]" %{\nreturn true;\n%}\n';
    var expected = {
        macros: [["RULE", "[0-9]"]],
        actionInclude: "\n hi <stuff> \n",
        rules: [
            ["\\[[^\\]]\\]", "\nreturn true;\n"]
        ]
    };

    assert.deepEqual(lex.parse(lexgrammar), expected, "grammar should be parsed correctly");
};

exports["test bnf lex grammar"] = function () {
    var fs = require("file");

    var lexgrammar = lex.parse(fs.path(fs.dirname(module.id))
            .join('lex', 'bnf.jisonlex')
            .read({charset: "utf-8"}));

    var expected = JSON.parse(fs.path(fs.dirname(module.id))
            .join('lex', 'bnf.lex.json')
            .read({charset: "utf-8"}));

    assert.deepEqual(lexgrammar, expected, "grammar should be parsed correctly");
};

exports["test lex grammar bootstrap"] = function () {
    var fs = require("file");

    var lexgrammar = lex.parse(fs.path(fs.dirname(module.id))
            .join('lex', 'lex_grammar.jisonlex')
            .read({charset: "utf-8"}));

    var expected = JSON.parse(fs.path(fs.dirname(module.id))
            .join('lex', 'lex_grammar.lex.json')
            .read({charset: "utf-8"}));

    assert.deepEqual(lexgrammar, expected, "grammar should be parsed correctly");
};

exports["test ANSI C lexical grammar"] = function () {
    var fs = require("file");

    var lexgrammar = lex.parse(fs.path(fs.dirname(module.id))
            .join('lex', 'ansic.jisonlex')
            .read({charset: "utf-8"}));

    assert.ok(lexgrammar, "grammar should be parsed correctly");
};
