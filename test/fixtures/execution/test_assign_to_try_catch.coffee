result: try
  nonexistent * missing
catch error
  true
  
result2: try nonexistent * missing catch error then true
  
print(result is true and result2 is true)