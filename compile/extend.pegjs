{
		@fs =  require('fs')
		@_ = require('lodash')
		@peg = require 'pegjs'
		(require 'pegjs-coffee-plugin').addTo @peg

		@extendParser = (dir,oldN,newN,exs)->
			insertNode = "statement = "
			addNode = exs[0].node

			if oldN == "default.pegjs"
				oldN = "c0.pegjs"

			oldCompiler = @fs.readFileSync(dir+oldN).toString()
			newCompiler = @fs.openSync (dir+newN),"w"
			oldCompiler = oldCompiler.replace insertNode,insertNode + addNode+ " / "
			@fs.writeSync newCompiler,oldCompiler,null,"utf8"
			@fs.writeSync newCompiler,"\n\n//--- extend ---\n",null,"utf8"

			ex = "\n"+exs.map((x)-> x.node + x.extend).join("\n")
			@fs.writeSync newCompiler,ex,null,"utf8"
			@fs.closeSync newCompiler


		@TextendParser = (dir,oldN,newN,exs,addNode,addTo,addPoint)->
			insertNode = addTo+" ="

			#if oldN == "default.pegjs"
			#	oldN = "c0.pegjs"

			oldCompiler = @fs.readFileSync(dir+oldN).toString()
			newCompiler = @fs.openSync (dir+newN),"w"
			#oldCompiler = oldCompiler.replace insertNode,insertNode +" "+ addNode+ " / "
			test = @_.filter oldCompiler.split("\n"),(x)-> return x.indexOf("/") != -1
			#console.log test
			@fs.writeSync newCompiler,oldCompiler,null,"utf8"
			@fs.writeSync newCompiler,"\n\n//--- extend ---\n",null,"utf8"

			ex = "\n"+exs.map((x)-> x.node + x.extend).join("\n")
			@fs.writeSync newCompiler,ex,null,"utf8"
			@fs.closeSync newCompiler


		@parserLog = (dir,oldN,newN)->
			logName = "compile.csv"
			compilerLog = @fs.readFileSync(dir+logName).toString()
			set = compilerLog.split("\n").map((x)-> x.split(","))
			if !(@_.find set,(x)-> x[1] == newN)
				compilerLog += oldN+","+newN+"\n"
				@fs.writeFileSync dir+logName,oldN+","+newN+"\n","utf8"

		@compile = (source,compiler)->
			dir = "./compile/"
			newP = @peg.buildParser (@fs.readFileSync(dir+compiler).toString())
			newsource = newP.parse source
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


extends = EXTEND __ oldC:string _ "," _ newC:string _ "," _ addTo:string _ "," _ n:num TERMINDENT extensions:extend+ DEDENT TERM
{
	dir = "./compile/"
	oldName = oldC+".pegjs"
	newName = newC+".pegjs"

	@TextendParser dir,oldName,newName,extensions,extensions[0].node,addTo,n

	return ""
}
/ EXTEND __ oldC:string _ "," _ newC:string TERMINDENT extensions:extend+ DEDENT TERM
{
	dir = "./compile/"
	oldName = oldC+".pegjs"
	newName = newC+".pegjs"

	@extendParser dir,oldName,newName,extensions

	@parserLog dir,oldName,newName

	return ""
}
extend = node:string _ "=" _ syntax:ExcludeIndentDedent semantics:semantics? TERMINATOR? _ s:( _ "/" _ syn:ExcludeIndentDedent semantics:semantics? )*
{
	extend = " = " + syntax
	if semantics
		extend += "\n{\n\t" + semantics + "\n}\n"

	extend = @_.foldl s,
		((result,x)->
			result += x[1]+x[3]
			if x[4]
				return result+"\n{\n\t"+x[4]+"\n}\n"
			else
				return result),extend

	return {node:node,extend:extend}
}
semantics = TERMINDENT _ s:(ExcludeIndentDedent TERMINATOR? _)+ DEDENT TERMINATOR
{
	return s.map((x)->x[0]).join("\n\t")
}


use = USE __ C:string TERMINATOR t:(text TERMINATOR)+
{
	tex = t.map((x)->x.join("")).join("")
	compiledTex = @compile tex,C+".pegjs"
	return compiledTex
}


text = !reserved i:(charactar / whiteSpace / symbol / INDENT /  "\uEFFE")+ { return i.join("") }
ExcludeIndentDedent = !reserved i:(charactar / whiteSpace / symbol)+ { return i.join("") }
string = !reserved i:(charactar)+ { return i.join("")}
num = "0" {return "0"}
  / head:[1-9] i:(decimalDigit)* {return parseInt(head + i.join(""),10)}

charactar = UniLetter / decimalDigit

EXTEND = a:"extend" !string {return a}
USE = a:"use" !string {return a}

whiteSpace = " " / "\r"
_  = __?
__ = ws:whiteSpace+ {return ws.join("");}

INDENT = "\uEFEF"
DEDENT = ws:(TERMINATOR? _) "\uEFFE" { return ws.join(""); }
TERM = "\n" / "\uEFFF"
TERMINATOR = t:(_ a:TERM{return a})+ {return t.join("");}
TERMINDENT = t:(TERMINATOR INDENT) {return t.join("");}

Keywords
  = ("extend" / "use" / "c0") !string

reserved = Keywords

UniLetter = [A-Za-z]
decimalDigit = [0-9]
symbol = [!-.] / "\\/" {return "/"} / [:-@] /  [\[-`] / [\{-~]