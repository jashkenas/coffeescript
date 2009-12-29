identity_wrap: x => => x

result: identity_wrap(identity_wrap(true))()()

print(result)