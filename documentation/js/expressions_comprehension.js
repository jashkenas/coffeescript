var globals, name, _results;
globals = (function() {
  _results = [];
  for (name in window) {
    _results.push(name);
  }
  return _results;
}()).slice(0, 10);