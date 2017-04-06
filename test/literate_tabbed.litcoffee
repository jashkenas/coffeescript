# Tabbed Literate CoffeeScript Test

comment comment

	test "basic literate CoffeeScript parsing", ->
		ok yes

now with a...

	test "broken up indentation", ->

... broken up ...

		do ->

... nested block.

			ok yes

Code must be separated from text by a blank line.

	test "code blocks must be preceded by a blank line", ->

The next line is part of the text and will not be executed.
    fail()

		ok yes

Code in `backticks is not parsed` and...

	test "comments in indented blocks work", ->
		do ->
			do ->
				# Regular comment.

				###
					Block comment.
				###

				ok yes

Regular [Markdown](http://example.com/markdown) features, like links
and unordered lists, are fine:

  * I

  * Am

  * A

  * List

Spaces work too:

  test "spaced code", ->
    ok yes

---

	# keep track of whether code blocks are executed or not
	executed = false

<p>

	executed = true # should not execute, this is just HTML para, not code!

</p>

	test "should ignore indented sections inside HTML", ->
		eq executed, false

---

*   A list item with a code block:

		test "basic literate CoffeeScript parsing", ->
			ok yes

---

*   Lorem ipsum dolor sit amet, consectetuer adipiscing elit.
    Aliquam hendrerit mi posuere lectus. Vestibulum enim wisi,
    viverra nec, fringilla in, laoreet vitae, risus.

*   Donec sit amet nisl. Aliquam semper ipsum sit amet velit.
    Suspendisse id sem consectetuer libero luctus adipiscing.

---

1.  This is a list item with two paragraphs. Lorem ipsum dolor
    sit amet, consectetuer adipiscing elit. Aliquam hendrerit
    mi posuere lectus.

    Vestibulum enim wisi, viverra nec, fringilla in, laoreet
    vitae, risus. Donec sit amet nisl. Aliquam semper ipsum
    sit amet velit.

2.  Suspendisse id sem consectetuer libero luctus adipiscing.

---

1.  This is a list item with two paragraphs. Lorem ipsum dolor
    sit amet, consectetuer adipiscing elit. Aliquam hendrerit
    mi posuere lectus.

    Vestibulum enim wisi, viverra nec, fringilla in, laoreet
    vitae, risus. Donec sit amet nisl. Aliquam semper ipsum
    sit amet velit.

2.  Suspendisse id sem consectetuer libero luctus adipiscing.

---

*   A list item with a blockquote:

    > This is a blockquote
    > inside a list item.

---

This next one probably passes because a string is inoffensive in compiled js, also, can't get `marked` to parse it correctly, and not sure if empty line is permitted between title and reference

This is [an example][id] reference-style link.
[id]: http://example.com/

    "Optional Title Here"

---

	executed = no

1986. What a great season.
          executed = yes

and test...

	test "should recognize indented code blocks in lists", ->
		ok executed

---

	executed = no

1986. What a great season.

				executed = yes

and test...

	test "should recognize indented code blocks in lists with empty line as separator", ->
		ok executed

---

	executed = no

1986\. What a great season.
				executed = yes

and test...

	test "should ignore indented code in escaped list like number", ->
		eq executed, no

one last test!

	test "block quotes should render correctly", ->
		quote = '''
			foo
					and bar!
		'''
		eq quote, 'foo\n\t\tand bar!'
