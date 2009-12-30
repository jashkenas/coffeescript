# Eat lunch.
lunch: food.eat() for food in ['toast', 'cheese', 'wine']

# Zebra-stripe a table.
highlight(row) for row, i in table when i % 2 is 0