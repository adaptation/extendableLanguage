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
# console.log "extendedInput : \n" +extendedInput+"\n"


# ast =  parser.parse afterConversion
ast = parser.parse extendedInput
# console.log "ast : ",ast#.body[0].block[0].block

trAst = TR.trace ast
# console.log "trAst : ",trAst+"\n"

esc = trAst.toESC()#ast.toESC()
# console.log "esc : \n" esc+"\n"

code = ecg.generate esc
console.log "code :\n"
console.log code+"\n"
