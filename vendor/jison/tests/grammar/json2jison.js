var assert = require("assert"),
    bnf = require("../../lib/jison/bnf");
    json2jison = require("../../lib/jison/json2jison");

exports["test basic grammar"] = function () {
    var grammar = "%% test: foo bar | baz ; hello: world ;";
    var expected = {bnf: {test: ["foo bar", "baz"], hello: ["world"]}};

    assert.deepEqual(json2jison.convert(bnf.parse(grammar)), json2jison.convert(expected), "grammar should be parsed correctly");
};

exports["test advanced grammar"] = function () {
    var grammar = "%start foo %% test: foo bar | baz ; hello: world %prec UM {action};";
    var expected = {start: "foo", bnf: {test: ["foo bar", "baz"], hello: [[ "world", "action", {prec: "UM"} ]]}};

    assert.deepEqual(json2jison.convert(bnf.parse(grammar)), json2jison.convert(expected), "grammar should be parsed correctly");
};

exports["test actions"] = function () {
    var grammar = "%start foo %% test: foo bar | baz ; hello: world %prec UM {{action{} }} ;";
    var expected = {start: "foo", bnf: {test: ["foo bar", "baz"], hello: [[ "world", "action{}", {prec: "UM"} ]]}};

    assert.deepEqual(json2jison.convert(bnf.parse(grammar)), json2jison.convert(expected), "grammar should be parsed correctly");
};
