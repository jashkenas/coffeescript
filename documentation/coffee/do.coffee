for fileName in list
  do (fileName) ->
    fs.readFile fileName, (err, contents) ->
      compile fileName, contents.toString()