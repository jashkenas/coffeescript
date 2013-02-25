{repeat} = require './helpers'

# A common error class used throughout the compiler to indicate compilation
# errors at a given location in the source code.
exports.CompilerError = class CompilerError extends Error
  name: 'CompilerError'

  constructor: (@message, @startLine, @startColumn,
                @endLine = @startLine, @endColumn = @startColumn) ->
    # Add a stack trace in V8.
    Error.captureStackTrace? @, CompilerError

  # Creates a nice error message like, following the "standard" format
  # <filename>:<line>:<col>: <message> plus the line with the error and a marker
  # showing where the error is.
  # TODO: tests
  prettyMessage: (fileName, code) ->
    message = "#{fileName}:#{@startLine}:#{@startColumn}: error: #{@message}"
    if @startLine is @endLine
      errorLine = code.split('\n')[@startLine - 1]
      errorLength = @endColumn - @startColumn + 1
      marker = (repeat ' ', @startColumn - 1) + (repeat '^', errorLength)
      message += "\n#{errorLine}\n#{marker}"
    else
      # TODO: How do we show multi-line errors?
      undefined
    message
