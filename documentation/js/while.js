(function(){
  while (demand > supply) {
    sell();
    restock();
  }
  while (supply > demand) {
    buy();
  }
})();