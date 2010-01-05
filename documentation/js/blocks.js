(function(){
  $('table.list').each(function(table) {
    return $('tr.account', table).each(function(row) {
      row.show();
      return row.highlight();
    });
  });
})();