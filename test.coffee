peg = require 'pegjs'
(require 'pegjs-coffee-plugin').addTo peg
fs = require 'fs'
TR = require './trace.coffee'
ecg = require 'escodegen'


input = fs.readFileSync "examples/let.coffee" , "utf8"
# input = fs.readFileSync "examples/input.coffee" , "utf8"
console.log "input : \n" +input + "\n"

preprocessor = peg.buildParser fs.readFileSync('preprocessor.pegjs').toString()

extendParser = peg.buildParser fs.readFileSync('c1.pegjs').toString()
# extendParser = peg.buildParser fs.readFileSync('extend.pegjs').toString()

parser = peg.buildParser fs.readFileSync('easy.pegjs').toString()

#ast = parser.parse input
pre = preprocessor.parse input
# console.log "preprocessor : \n"+pre+"\n"
# console.dir pre

extended = extendParser.parse pre
console.log "extend : \n" +extended+"\n"

ast = parser.parse extended
# console.log "ast : ",ast#.body[0].block[0].block

trAst = TR.trace ast
# console.log "trAst : ",trAst


esc = trAst.toESC()#ast.toESC()
# console.log esc

code = ecg.generate esc
console.log "code : " +code
