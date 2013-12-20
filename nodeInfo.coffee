peg = require 'pegjs'
(require 'pegjs-coffee-plugin').addTo peg
fs = require 'fs'
_ = require 'lodash'

getNames = (x)->
	x.map((y)->y.name)

getLeavesNum = (x)->
	x.map((y)->
		h = {}
		h[y.name] = y.num
		return h )

getLeaves = (x)->
	x.map((y)->
		h = {}
		h[y.name] = y.leaves
		return h )

getInfo = (x,name)->
	# console.dir x
	return ( _.find x,((y)-> return y.name == name) )

@parseNodeInfo = (read)->
	readPEG = fs.readFileSync(read).toString()
	parseNode = peg.buildParser fs.readFileSync('./compile/parseGrammer.pegjs').toString()
	return (parseNode.parse readPEG)

@getNodesInfo = (read)->
	nodeInfo = _.filter (@parseNodeInfo read),(x)-> return x.name?
	nodeInfo.names = getNames nodeInfo
	nodeInfo.leavesNum = getLeavesNum nodeInfo
	nodeInfo.leaves = getLeaves nodeInfo
	nodeInfo.info = (name)-> return (getInfo nodeInfo,name)
	return nodeInfo

@nodeInfoToFile = (read)->
	obj = (x)->
		return "{ "+(_.map(x,(value,key)->
			if key == "leaves"
				v = _.flatten(value.map((y)-> _.reject y,((z)-> return z == "\n") ))
				# console.log v.join("")
				key+": [ "+v.join("")+" ]"
			else
				key+": "+value.toString())
		.join(", "))+" }"
	str = (@getNodesInfo read).map(obj).join(",\n")
	fs.writeFileSync "./nodeInfo.txt",str