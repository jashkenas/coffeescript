### Literate CoffeeScript parsing

CoffeeScript 2’s parsing of Literate CoffeeScript has been refactored to now be more careful about not treating indented lists as code blocks; but this means that all code blocks (unless they are to be interpreted as comments) must be separated by at least one blank line from lists.

Code blocks should also now maintain a consistent indentation level—so an indentation of one tab (or whatever you consider to be a tab stop, like 2 spaces or 4 spaces) should be treated as your code’s “left margin,” with all code in the file relative to that column.

Code blocks that you want to be part of the commentary, and not executed, must have at least one line (ideally the first line of the block) completely unindented.
