
#764: Boolean should be indexable
eq Boolean::toString, true['toString']
eq Boolean::toString, false['toString']
eq Boolean::toString, yes['toString']
eq Boolean::toString, no['toString']
eq Boolean::toString, on['toString']
eq Boolean::toString, off['toString']

eq Boolean::toString, true.toString
eq Boolean::toString, false.toString
eq Boolean::toString, yes.toString
eq Boolean::toString, no.toString
eq Boolean::toString, on.toString
eq Boolean::toString, off.toString
