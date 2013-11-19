{exec} = require 'child_process'

files='test.coffee'

exec "coffee #{files}",(err,stdout,stderr)->
		if err
			console.log stdout
			throw err
		console.log stdout+stderr