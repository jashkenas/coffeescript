for filename in list
  do (filename) ->
    if filename not in ['.DS_Store', 'Thumbs.db', 'ehthumbs.db']
      fs.readFile filename, (err, contents) ->
        compile filename, contents.toString()
