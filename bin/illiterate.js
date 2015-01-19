var out = [];
process.argv.slice(2).forEach(function(filename){
	require('fs').readFileSync(filename).toString().split(/\r?\n/).forEach(function(line){
		['    ', '\t'].forEach(function(delimiter){
			if(line.indexOf(delimiter) === 0){
				out.push(line.substring(delimiter.length));
			}
		});
	});
});
console.log(out.join('\n'));
