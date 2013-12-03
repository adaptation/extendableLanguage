peg = require 'pegjs'
(require 'pegjs-coffee-plugin').addTo peg
fs = require 'fs'
TR = require './trace.coffee'
ecg = require 'escodegen'


# input = fs.readFileSync "examples/let.coffee" , "utf8"
input = fs.readFileSync "examples/input2.coffee" , "utf8"
# input = fs.readFileSync "examples/input.coffee" , "utf8"
# console.log "input : \n" +input + "\n"

preprocessor = peg.buildParser fs.readFileSync('preprocessor.pegjs').toString()

extendParser = peg.buildParser fs.readFileSync('./compile/extend.pegjs').toString()

parser = peg.buildParser fs.readFileSync('./compile/default.pegjs').toString()

#ast = parser.parse input
pre = preprocessor.parse input
# console.log "preprocessor : \n"+pre+"\n"
# console.dir pre

extendedInput = extendParser.parse pre
# console.log "extend : \n" +extendedInput+"\n"

compile = (source)->
	dir = "./compile/"
	c = "compile.csv"
	compilers = fs.readFileSync(dir + c).toString().split("\n").map((x)-> x.split(","))
	_compile = (oldC,newC)->
		newP = peg.buildParser fs.readFileSync(dir+newC).toString()
		newsource = newP.parse source
		oldP = peg.buildParser fs.readFileSync(dir+oldC).toString()
		return (oldP.parse newsource)
	_compile compilers[0][0],compilers[0][1]


# console.log (compile extendedInput)
# compile extendedInput

# extendedParser = peg.buildParser fs.readFileSync('./compile/b.pegjs').toString()
# newInput = extendedParser.parse extendedInput
# console.log "newInput : \n" +newInput+"\n"

ast = compile extendedInput
# ast =  parser.parse newInput
# ast = parser.parse extendedInput
# console.log "ast : ",ast#.body[0].block[0].block

trAst = TR.trace ast
# console.log "trAst : ",trAst+"\n"


esc = trAst.toESC()#ast.toESC()
# console.log "esc : \n" esc+"\n"

code = ecg.generate esc
console.log "code : " +code+"\n"
