{repeat} = require './helpers'

# A common error class used throughout the compiler to indicate compilation
# errors at a given location in the source code.
exports.CompilerError = class CompilerError extends Error
  name: 'CompilerError'

  constructor: (@message, @startLine, @startColumn,
                @endLine = @startLine, @endColumn = @startColumn) ->
    # Add a stack trace in V8.
    Error.captureStackTrace? @, CompilerError

  # Creates a CompilerError from a given locationData.
  @fromLocationData = (message, {first_line, first_column, last_line, last_column}) ->
    new CompilerError message, first_line, first_column, last_line, last_column

  # Creates a nice error message like, following the "standard" format
  # <filename>:<line>:<col>: <message> plus the line with the error and a marker
  # showing where the error is.
  prettyMessage: (fileName, code, useColors) ->
    errorLine = code.split('\n')[@startLine]
    start     = @startColumn
    # Show only the first line on multi-line errors.
    end       = if @startLine is @endLine then @endColumn + 1 else errorLine.length
    marker    = repeat(' ', start) + repeat('^', end - start)

    if useColors
      colorize  = (str) -> "\x1B[1;31m#{str}\x1B[0m"
      errorLine = errorLine[...start] + colorize(errorLine[start...end]) + errorLine[end..]
      marker    = colorize marker

    message = """
      #{fileName}:#{@startLine + 1}:#{@startColumn + 1}: error: #{@message}
      #{errorLine}
      #{marker}
    """

    # Uncomment to add stacktrace.
    #message += "\n#{@stack}"

    message
