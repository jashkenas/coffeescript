# Issue #380: problem with @ and instanceof
class ClassName
  am_i: ->
    @ instanceof ClassName

obj: new ClassName()
ok obj.am_i()


# Issue #383: Numbers that start with . not recognized
value: .25 + .75
ok value is 1
value: 0.0 + -.25 - -.75 + 0.0
ok value is 0.5

deepEqual [0..10],  [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
deepEqual [0...10], [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
