peg = require 'pegjs'
(require 'pegjs-coffee-plugin').addTo peg
fs = require 'fs'
TR = require './trace.coffee'
ecg = require 'escodegen'
_ = require 'lodash'
nodeInfo = require './nodeInfo.coffee'


# input = fs.readFileSync "examples/let.coffee" , "utf8"
input = fs.readFileSync "examples/input3.coffee" , "utf8"
# input = fs.readFileSync "examples/input.coffee" , "utf8"
# console.log "input : \n" +input + "\n"

preprocessor = peg.buildParser fs.readFileSync('preprocessor.pegjs').toString()

makeGrammer = peg.buildParser fs.readFileSync('./compile/getGrammer.pegjs').toString()

extendParser = peg.buildParser fs.readFileSync('./compile/extend.pegjs').toString()

parser = peg.buildParser fs.readFileSync('./compile/default.pegjs').toString()

extendedInput = extendParser.parse input
# console.log "extendedInput : \n" +extendedInput+"\n"

#ast = parser.parse input
pre = preprocessor.parse extendedInput
# pre = preprocessor.parse input
# console.log "preprocessor : \n"+pre+"\n"
# console.dir pre

# readPEG = fs.readFileSync('./compile/c0.pegjs').toString()
# g = makeGrammer.parse readPEG
# console.log g
# fs.writeFileSync "./test.txt",g

# n = nodeInfo.parseNodeInfo './compile/c0.pegjs'
# console.log (n.info "statement")
# console.dir (n.slice(0,5))
# nodeInfo.nodeInfoToFile('./compile/c.pegjs')

# extendedInput = extendParser.parse pre
# console.log "extendedInput : \n" +extendedInput+"\n"

# ast = parser.parse extendedInput
ast = parser.parse pre
# console.log "ast : ",ast#.body[0].block[0].block

trAst = TR.trace ast
# console.log "trAst : ",trAst+"\n"

esc = trAst.toESC()#ast.toESC()
# console.log "esc : \n" esc+"\n"

code = ecg.generate esc
# console.log "code :\n"
console.log code+"\n"
