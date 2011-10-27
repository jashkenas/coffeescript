var dept, employee, name, output, salary;

salary = 50;
name = "Joe";
dept = "Accounting";

employee = {
  salary: salary,
  name: name,
  dept: dept
};

output = "" + employee.name + " works in " + employee.dept;
