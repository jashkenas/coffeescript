function Promise (fn) {
	this._fulfilled = false;
	this._rejected = false;
	this._value = undefined;
	this._thens = [];

	fn(this._win.bind(this), this._fail.bind(this));
}
 
Promise.prototype = {
	constructor: Promise,
	
	_empty: function(){

	},

	_win: function(val){
		this._fulfilled = true;
		this._value = val;
		while (this._thens.length > 0){
			var rval;
			thenable = this._thens.shift();

			rval = thenable.win(val);
			thenable.fulfill(rval);
		}
	},

	_fail: function(val){
		this._rejected = true;
		this._value = val;
		while (this._thens.length > 0){
			thenable = this._thens.shift();
			thenable.fail(val);
			thenable.reject(val);
		}
	},

	_iscomplete: function(){
		return this._fulfilled || this._rejected;
	},

	then: function(win, fail){
		var self = this, 
			fulfill,
			reject,
			promise = new Promise(function(win, fail){
				fulfill = win;
				reject = fail;
			});

		if (fail === undefined){
			fail = this._empty;
		}

		if (this._iscomplete()){
			if (this._fulfilled){
				var rval;
				rval = win(this._value);
				fulfill(rval);
			} else {
				fail(this._value);
				reject(this._value);
			}
		} else {
			this._thens.push({
				win: win,
				fail: fail,
				fulfill: fulfill,
				reject: reject
			});
		}

		return promise;
	}
};

module.exports = Promise;