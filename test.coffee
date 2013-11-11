peg = require 'pegjs'
(require 'pegjs-coffee-plugin').addTo peg
fs = require 'fs'
TR = require './trace.coffee'
ecg = require 'escodegen'

input = fs.readFileSync "examples/input.coffee" , "utf8"

preprocessor = peg.buildParser fs.readFileSync('preprocessor.pegjs').toString()

parser = peg.buildParser fs.readFileSync('easy.pegjs').toString()

#ast = parser.parse input
pre = preprocessor.parse input
# console.log pre
# console.dir pre

ast = parser.parse pre
# console.log "ast : ",ast#.body[0].block


trAst = TR.trace ast
# console.log "trAst : ",trAst


esc = trAst.toESC()#ast.toESC()
# console.log esc

code = ecg.generate esc
console.log code
