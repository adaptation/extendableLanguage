{
		@fs =  require('fs')
		@_ = require('lodash')
		@peg = require 'pegjs'
		(require 'pegjs-coffee-plugin').addTo @peg
		@nodeInfo = require('../../../nodeInfo.coffee')

		@TextendParser = (dir,oldN,newN,exs,addTo,addNode,addPoint)->
			insertNode = addTo+" ="
			if oldN == "default.pegjs"
				oldN = "c0.pegjs"

			n = (@nodeInfo.parseNodeInfo (dir+oldN)).map((x)->
					if x.name == addTo
						head = x.leaves.slice(0,addPoint-1)
						rest = x.leaves.slice(addPoint-1)
						head.push addNode
						x.leaves = head.concat rest
						x.num += 1
					return x
				)
			old = n.map((x)->
				if x.name
					#console.log x.leaves
					return x.name+" = "+x.leaves.join(" / ")
				else
					return x
			).join("")

			newCompiler = @fs.openSync (dir+newN),"w"
			@fs.writeSync newCompiler,old,null,"utf8"
			@fs.writeSync newCompiler,"\n\n//--- extend ---\n",null,"utf8"

			ex = "\n"+exs.map((x)-> x.node + x.extend).join("\n")
			@fs.writeSync newCompiler,ex,null,"utf8"
			@fs.closeSync newCompiler

		@extendParser = (dir,oldN,newN,exs)->
			addNode = exs[0].node
			@TextendParser dir,oldN,newN,exs,"statement",addNode,1

		@parserLog = (dir,oldN,newN)->
			logName = "compile.csv"
			compilerLog = @fs.readFileSync(dir+logName).toString()
			set = compilerLog.split("\n").map((x)-> x.split(","))
			if !(@_.find set,(x)-> x[1] == newN)
				newlog = oldN+","+newN+"\n"
				file = @fs.openSync dir+logName,"a"
				@fs.writeSync file,newlog,null,"utf8"
				@fs.closeSync file

		@compile = (source,compiler)->
			dir = "./compile/"
			pre = @peg.buildParser (@fs.readFileSync("preprocessor.pegjs").toString())
			preprocessed = pre.parse source
			newP = @peg.buildParser (@fs.readFileSync(dir+compiler).toString())
			newsource = newP.parse preprocessed
			return newsource
}

start = program

program = TERMINATOR? _ b:block
{ return b}

statement = extends / use / text

block = s:(statement TERMINATOR?)+
{
	return s.map((x)->x.join("")).join("")
}

extends = EXTEND __ oldC:identifier _ "," _ newC:identifier _ ","
 _ addTo:identifier _ "," _ addNode:identifier "," _ n:num
 TERMINATOR? "{" TERMINATOR? extensions:(a:extend TERM{return a})+ TERMINATOR? "}"
{
	dir = "./compile/"
	oldName = oldC+".pegjs"
	newName = newC+".pegjs"

	@TextendParser dir,oldName,newName,extensions,addTo,addNode,n
	@parserLog dir,oldName,newName

	return ""
}
/ EXTEND __ oldC:identifier _ "," _ newC:identifier TERMINATOR? "{" TERMINATOR? extensions:(a:extend TERM{return a})+ TERMINATOR? "}"
{
	dir = "./compile/"
	oldName = oldC+".pegjs"
	newName = newC+".pegjs"

	@extendParser dir,oldName,newName,extensions

	@parserLog dir,oldName,newName

	return ""
}

extend =  node:identifier _ "=" _ semantics:pegTerm
{
	#console.log node,semantics
	extend = " = "+semantics
	return {node:node,extend:extend}
}

pegTerm = a:pegExpr _ b:( TERMINATOR? _ "/" _ c:pegExpr _ {return c})*
{
	return if (b.length > 0) then (([a].concat b).join(" / ")) else a
}

pegAction = "{" TERMINATOR? b:(c:ExcludeBrace TERMINATOR? {return c})* "}"
{
	#console.log b
	return "{\n\t"+ (@_.filter b,(x)->x.length > 0 ).join("\n\t") + "\n}"
}

pegExpr = a:firstPegExpr _ "*" TERMINATOR? _ b:pegAction _ c:pegExpr? {return a+"* "+b+c }
 / a:firstPegExpr _ "+" TERMINATOR? _ b:pegAction _ c:pegExpr? {return a+"+ "+b+c }
 / a:firstPegExpr _ "?" TERMINATOR? _ b:pegAction _ c:pegExpr? {return a+"? "+b+c }
 / a:firstPegExpr __ b:pegExpr
 {
 	return a+" "+b
 }
 / a:firstPegExpr TERMINATOR? _  b:pegAction { return a+b}
 / firstPegExpr
firstPegExpr = pegLiteral / pegChar
 / "(" _  a:pegExpr _ b:( TERMINATOR? _ "/" _ c:pegExpr _ {return c})* _ ")"
{ return "("+a+b.join(" / ")+")"}
 / "&" _ a:pegExpr {return "&"+a}
 / "!" _ a:pegExpr {return "!"+a}
 / label:identifier _ ":" _ a:pegExpr {return label+":"+a} / identifier
pegLiteral = "\"" a:ExcludeQuot "\"" {return "\""+a+"\""}
 / "\'" a:ExcludeQuot "\'" {return "\'"+a+"\'"}
pegChar = "[" a:ExcludeBracket "]" {return "["+a+"]"}

identifier = i:identifierName { return i; }
identifierName = head:identifierStart tail:identifierPart* {
  tail.unshift(head)
  return tail.join("")
}
identifierStart = UniLetter / [$_]
identifierPart = identifierStart / decimalDigit



use = USE __ C:identifier TERMINATOR t:(text TERMINATOR?)+
{
	tex = t.map((x)->x.join("")).join("")
	compiledTex = @compile tex,C+".pegjs"
	return compiledTex
}


text = !reserved i:(charactar / whiteSpace / symbol / bracket / brace / diagonal / quot / INDENT /  "\uEFFE" / "\uEFFF")+ { return i.join("") }
ExcludeQuot = i:(charactar / whiteSpace / symbol / "\\\"" / "\\\'" / bracket / diagonal)+ { return i.join("") }
ExcludeBrace = i:(charactar / whiteSpace / symbol / bracket / "\\{" / "\\}" / diagonal / quot / INDENT {return ""} /  "\uEFFE" {return ""} / "\uEFFF" {return ""})+ { return i.join("") }
ExcludeBracket = i:(charactar / whiteSpace / symbol / "\\[" / "\\]" / brace / diagonal / quot)+ { return i.join("") }
num = "0" {return "0"}
  / head:[1-9] i:(decimalDigit)* {return parseInt(head + i.join(""),10)}

charactar = UniLetter / decimalDigit

EXTEND = a:"extend" !identifier {return a}
USE = a:"use" !identifier {return a}

whiteSpace = " " / "\r" / "\t"
_  = __?
__ = ws:whiteSpace+ {return ws.join("");}

INDENT = "\uEFEF"
DEDENT = ws:(TERMINATOR? _) "\uEFFE" { return ws.join(""); }
TERM = "\n" / "\uEFFF"
TERMINATOR = t:(_ a:TERM{return a})+ {return t.join("");}
TERMINDENT = t:(TERMINATOR INDENT) {return t.join("");}

Keywords
  = ("extend" / "use" / "c0") !identifier
reserved = Keywords

UniLetter = [A-Za-z]
decimalDigit = [0-9]
bracket = "[" / "]"
brace = "{" / "}"
diagonal = "/"
quot = "\"" / "\'"
symbol =  "!" / "#" / "$" / "%" / "&" / "(" / ")" / "*" / "+" / "," / "-" / "." / ":" / ";" / "<" / "=" / ">" / "?" / "@" / "\\" / "^" / "_" / "`" / "|" / "~"