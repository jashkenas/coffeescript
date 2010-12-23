var funcs, i, _fn;
funcs = [];
_fn = function(i) {
  funcs.push(function(number) {
    return number + i;
  });
};
for (i = 0; i <= 3; i++) {
  _fn(i);
}