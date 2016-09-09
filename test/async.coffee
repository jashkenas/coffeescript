
###
For testing purposes pseudo-promises are used. These
execute the then method snchronously when sync promises are used.
All promises used here are sync, as they resolve/reject immediately,
and use no callbacks.
###
class Promise
	constructor: (fn) ->
		@_fulfilled = no
		@_rejected = no
		@_value = null
		@_thens = []

		fn @_win.bind(this), @_fail.bind(this)
 	
	_empty: ->

	_win: (val) ->
		@_fulfilled = true
		@_value = val
		while @_thens.length > 0
			{fulfill, win} = @_thens.shift()
			fulfill win val
		1
		
	

	_fail: (val) ->
		@_rejected = true
		@_value = val
		while @_thens.length > 0
			{fail, reject} = @_thens.shift()
			fail val
			reject val
		0
	

	_iscomplete: ->
		@_fulfilled or @_rejected
	

	then: (win, fail = @_empty) ->
		self = this
		fulfill = null
		reject = null
		promise = new Promise (win, fail) ->
			fulfill = win
			reject = fail

		if @_iscomplete()
			if @_fulfilled
				fulfill win @_value
			else
				fail @_value
				reject @_value
		else
			@_thens.push
				win		: win
				fail	: fail
				fulfill	: fulfill
				reject	: reject
		promise

# always fulfills
winning = (val)->
	new Promise (win, fail) ->
		win(val)
		1

# always is rejected
failing = (val)->
	new Promise (win, fail) ->
		fail(new Error(val))
		0


test "async as argument", ->
	ok ->
		await winning()

test "explicit async", ->
	a = do ->
		await return [1, 2, 3]

	eq a.constructor, Promise

test "implicit async", ->
	a = do ->
		x = await winning(5)
		y = await winning(4)
		z = await winning(3)
		[x, y, z]

	eq a.constructor, Promise

test "async return value (implicit)", ->
	out = null
	a = ->
		x = await winning(5)
		y = await winning(4)
		z = await winning(3)
		[x, y, z]

	do ->
		out = await a()

	arrayEq out, [5, 4, 3]

test "async return value (explicit)", ->
	out = null
	a = ->
		await return [5, 2, 3]

	do ->
		out = await a()

	arrayEq out, [5, 2, 3]


test "async parameters", ->
	[out1, out2] = [null, null]
	a = (a, [b, c])->
		arr = [a]
		arr.push b
		arr.push c
		await return arr

	b = (a, b, c = 5)->
		arr = [a]
		arr.push b
		arr.push c
		await return arr

	do ->
		out1 = await a(5, [4, 3])
		out2 = await b(4, 4)

	arrayEq out1, [5, 4, 3]
	arrayEq out2, [4, 4, 5]

test "async `this` scoping", ->
	bnd = null
	ubnd = null
	nst = null
	obj = 
		bound: ->
			return do =>
				await return this
		unbound: ->
			return do ->
				await return this
		nested: ->
			return do =>
				await do =>
					await do =>
						await return this

	do ->
		bnd = await obj.bound()
		ubnd = await obj.unbound()
		nst = await obj.nested()

	eq bnd, obj
	ok ubnd isnt obj
	eq nst, obj

test "await precedence", ->
	out = null

	fn = (win, fail) ->
		win(3)

	do ->
		# assert precedence between unary (new) and power (**) operators
		out = 1 + await new Promise(fn) ** 2

	eq out, 10

test "`await` inside IIFEs", ->
	[x, y, z] = new Array(3)

	a = do ->
		x = switch (4)	# switch 4
			when 2
				await winning(1)
			when 4
				await winning(5)
			when 7
				await winning(2)

		y = try
			text = "this should be caught"
			throw new Error(text)
			await winning(1)
		catch e
			await winning(4)
		
		z = for i in [0..5]
			a = i * i
			await winning(a)

	eq x, 5
	eq y, 4

	arrayEq z, [0, 1, 4, 9, 16, 25]

test "error if function contains both `await`, and `yield` or `yieldfrom`", ->
	throws -> CoffeeScript.compile '()-> yield 5; await a;'
	throws -> CoffeeScript.compile '()-> yield from a; await b;'

test "error if `await` occurs outside of a function", ->
	throws -> CoffeeScript.compile 'await 1'

test "error throwing", ->
	throws ->
		await failing(2)

test "error handling", ->
	res = null
	val = 0
	a = ->
		try
			await failing("fail")
		catch e
			val = 7	# to assure the catch block runs
			return e


	do ->
		res = await a()

	eq val, 7

	ok res.message?
	eq res.message, "fail"
