{exec} = require 'child_process'

files='test.coffee'

exec "coffee #{files}",(err,stdout,stderr)->
		throw err if err
		console.log stdout+stderr