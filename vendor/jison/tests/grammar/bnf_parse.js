var assert = require("assert"),
    bnf = require("../../lib/jison/bnf"),
    json2jison = require("../../lib/jison/json2jison");

exports["test basic grammar"] = function () {
    var grammar = "%% test: foo bar | baz ; hello: world ;";
    var expected = {bnf: {test: ["foo bar", "baz"], hello: ["world"]}};

    assert.deepEqual(bnf.parse(grammar), expected, "grammar should be parsed correctly");
};

exports["test classy grammar"] = function () {
    var grammar = "%%\n\npgm \n: cdl MAIN LBRACE vdl el RBRACE ENDOFFILE \n; cdl \n: c cdl \n| \n;";
    var expected = {bnf: {pgm: ["cdl MAIN LBRACE vdl el RBRACE ENDOFFILE"], cdl: ["c cdl", ""]}};

    assert.deepEqual(bnf.parse(grammar), expected, "grammar should be parsed correctly");
};

exports["test advanced grammar"] = function () {
    var grammar = "%% test: foo bar {action} | baz ; hello: world %prec UMINUS ;extra: foo {action} %prec '-' ;";
    var expected = {bnf: {test: [["foo bar", "action" ], "baz"], hello: [[ "world", {prec:"UMINUS"} ]], extra: [[ "foo", "action", {prec: "-"} ]]}};

    assert.deepEqual(bnf.parse(grammar), expected, "grammar should be parsed correctly");
};

exports["test nullable rule"] = function () {
    var grammar = "%% test: foo bar | ; hello: world ;";
    var expected = {bnf: {test: ["foo bar", ""], hello: ["world"]}};

    assert.deepEqual(bnf.parse(grammar), expected, "grammar should be parsed correctly");
};

exports["test nullable rule with action"] = function () {
    var grammar = "%% test: foo bar | {action}; hello: world ;";
    var expected = {bnf: {test: ["foo bar", [ "", "action" ]], hello: ["world"]}};

    assert.deepEqual(bnf.parse(grammar), expected, "grammar should be parsed correctly");
};

exports["test nullable rule with < > delimited action"] = function () {
    var grammar = "%% test: foo bar | <action{}>; hello: world ;";
    var expected = {bnf: {test: ["foo bar", [ "", "action{}" ]], hello: ["world"]}};

    assert.deepEqual(bnf.parse(grammar), expected, "grammar should be parsed correctly");
};

exports["test nullable rule with {{ }} delimited action"] = function () {
    var grammar = "%% test: foo bar | {{action{};}}; hello: world ;";
    var expected = {bnf: {test: ["foo bar", [ "", "action{};" ]], hello: ["world"]}};

    assert.deepEqual(bnf.parse(grammar), expected, "grammar should be parsed correctly");
};

exports["test comment"] = function () {
    var grammar = "/* comment */ %% hello: world ;";
    var expected = {bnf: {hello: ["world"]}};

    assert.deepEqual(bnf.parse(grammar), expected, "grammar should be parsed correctly");
};
exports["test comment with nested *"] = function () {
    var grammar = "/* comment * not done */ %% hello: /* oh hai */ world ;";
    var expected = {bnf: {hello: ["world"]}};

    assert.deepEqual(bnf.parse(grammar), expected, "grammar should be parsed correctly");
};
