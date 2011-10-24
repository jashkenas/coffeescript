var course, courses, dish, food, foods, _i, _j, _len, _len2, _len3, _ref;

_ref = ['toast', 'cheese', 'wine'];
for (_i = 0, _len = _ref.length; _i < _len; _i++) {
  food = _ref[_i];
  eat(food);
}

courses = ['salad', 'entree', 'dessert'];

for (course = 0, _len2 = courses.length; course < _len2; course++) {
  dish = courses[course];
  menu(course + 1, dish);
}

foods = ['broccoli', 'spinach', 'chocolate'];

for (_j = 0, _len3 = foods.length; _j < _len3; _j++) {
  food = foods[_j];
  if (food !== 'chocolate') eat(food);
}
