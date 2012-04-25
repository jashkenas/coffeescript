# This file is where third-parties should add their modifications to the
# CoffeeScript grammar. Keeping modifications in a separate file makes it easier
# to pull in updates from the "official" version of CoffeeScript without having
# to deal with complex merges.

# Takes a single argument, which is an object with two properties: grammar and
# operators. These are the objects of same name defined in grammar.coffee.
# They can be modified in-memory here before they are used to create the Parser.
exports.modifyGrammar = ->
