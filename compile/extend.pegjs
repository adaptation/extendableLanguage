{
		@fs =  require('fs')
		@_ = require('lodash')

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

		@parserLog = (dir,oldN,newN)->
			logName = "compile.csv"
			compilerLog = @fs.readFileSync(dir+logName).toString()
			set = compilerLog.split("\n").map((x)-> x.split(","))
			if !(@_.find set,(x)-> x[1] == newN)
				compilerLog += oldN+","+newN+"\n"
				@fs.writeFileSync dir+logName,oldN+","+newN+"\n","utf8"
}

start = program

program = TERMINATOR? _ b:block
{ return b}

statement = extends / text

block = s:(statement TERMINATOR?)+
{
	return s.map((x)->x.join("")).join("")
}



extends = EXTEND __ oldC:string _ "," _ newC:string TERMINDENT extensions:extend+ DEDENT TERM
{
	dir = "./compile/"
	oldName = oldC+".pegjs"
	newName = newC+".pegjs"

	@extendParser dir,oldName,newName,extensions

	@parserLog dir,oldName,newName

	return ""
}
semantics = s:(ExcludeIndentDedent TERMINATOR?)+
{
	return s.map((x)->x[0]).join("\n\t")
}
extend = node:string _ "=" _ syntax:ExcludeIndentDedent TERMINDENT b:semantics DEDENT TERM "\n"
{
	return {node:node,extend:" = " + syntax + "{\n\t" + b + "\n}\n"}
}

text = !reserved i:(charactar / whiteSpace / symbol / INDENT /  "\uEFFE")+ { return i.join("") }
ExcludeIndentDedent = !reserved i:(charactar / whiteSpace / symbol)+ { return i.join("") }
string = !reserved i:(charactar)+ { return i.join("")}

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