var courses, dish, food, foods, i, _i, _j, _len, _len2, _len3, _ref;

_ref = ['toast', 'cheese', 'wine'];
for (_i = 0, _len = _ref.length; _i < _len; _i++) {
  food = _ref[_i];
  eat(food);
}

courses = ['greens', 'caviar', 'truffles', 'roast', 'cake'];

for (i = 0, _len2 = courses.length; i < _len2; i++) {
  dish = courses[i];
  menu(i + 1, dish);
}

foods = ['broccoli', 'spinach', 'chocolate'];

for (_j = 0, _len3 = foods.length; _j < _len3; _j++) {
  food = foods[_j];
  if (food !== 'chocolate') eat(food);
}
