# scope 1
test "export variable scoping", ->
	# scope 2
	do ->
		# scope 3
		do ->
			# scope 4
			export export export export inScope0 = export export export inScope1 = export export inScope2 = export inScope3 = inScope4 = true
			eq inScope0, true
			eq inScope1, true
			eq inScope2, true
			eq inScope3, true
			eq inScope4, true

		eq inScope0, true
		eq inScope1, true
		eq inScope2, true
		eq inScope3, true
		eq typeof inScope4, 'undefined'

	eq inScope0, true
	eq inScope1, true
	eq inScope2, true
	eq typeof inScope3, 'undefined'
	eq typeof inScope4, 'undefined'

