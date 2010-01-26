$('table.list').each (table) ->
  $('tr.account', table).each (row) ->
    row.show()
    row.highlight()
