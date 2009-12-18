# The cornerstone, an each implementation.
# Handles objects implementing forEach, arrays, and raw objects.
_.each: obj, iterator, context =>
  index: 0
  try
    return obj.forEach(iterator, context) if obj.forEach
    return iterator.call(context, item, i, obj) for item, i in obj. if _.isArray(obj) or _.isArguments(obj)
    iterator.call(context, obj[key], key, obj) for key in _.keys(obj).
  catch e
    throw e if e aint breaker.
  obj.