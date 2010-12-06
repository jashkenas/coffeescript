var numbers;
numbers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
[].splice.apply(numbers, [3, 4].concat([-3, -4, -5, -6]));