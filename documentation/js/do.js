var fileName, _fn, _i, _len;
_fn = function(fileName) {
  return fs.readFile(fileName, function(err, contents) {
    return compile(fileName, contents.toString());
  });
};
for (_i = 0, _len = list.length; _i < _len; _i++) {
  fileName = list[_i];
  _fn(fileName);
}