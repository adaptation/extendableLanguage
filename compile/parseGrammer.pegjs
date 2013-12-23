{
		@_ = require('lodash')
}
start = pegProgram

pegProgram = TERMINATOR? _ b:pegBlock { return b}

pegBlock = s:(pegStatement TERMINATOR?)+
{
	#console.dir s.map((x)->x[0]).map((x)->x.leaves)
	return @_.flatten s
}

pegStatement = pegRule / pegAction / text

pegRule = node:identifier _ "=" _ semantics:pegTerm
{
	return {name:node,num:semantics.length,leaves:semantics}
}
pegTerm = a:pegExpr _ b:( TERMINATOR? _ "/" _ c:pegExpr _ {return c})*
{
	return if (b.length > 0) then ([a].concat b) else [a]
}

pegAction = "{" a:TERMINATOR? b:(c:ExcludeBrace d:TERMINATOR? {return c+d})* "}"
{
	return "{"+ a + b.join("") + "}"
}

pegExpr = a:firstPegExpr _ "*" _ b:pegExpr? {return a+"* "+b }
 / a:firstPegExpr _ "+" _ b:pegExpr? {return a+"+ "+b }
 / a:firstPegExpr _ "?" _ b:pegExpr? {return a+"? "+b }
 / a:firstPegExpr __ b:pegExpr
 {
 	return a+" "+b
 }
 / a:(firstPegExpr TERMINATOR? _ pegAction) { return a.join("")}
 / firstPegExpr
firstPegExpr = pegLiteral / pegChar
 / "(" _  a:pegExpr _ b:( TERMINATOR? _ "/" _ c:pegExpr _ {return c})* _ ")"
{ return if (b.length > 0) then "("+([a].concat b).join(" / ")+")" else "("+a+")" }
 / "&" _ a:pegExpr {return "&"+a}
 / "!" _ a:pegExpr {return "!"+a}
 / label:identifier _ ":" _ a:pegExpr {return label+":"+a} / identifier
pegLiteral = "\"" a:ExcludeQuot "\"" {return "\""+a+"\""}
 / "\'" a:ExcludeQuot "\'" {return "\'"+a+"\'"}
pegChar = "[" a:ExcludeBracket "]" {return "["+a+"]"}


text = i:(charactar / whiteSpace / symbol / bracket / brace / diagonal / quot)+
{
	return i.join("")
}

identifier = i:identifierName { return i; }
identifierName = head:identifierStart tail:identifierPart* {
  tail.unshift(head)
  return tail.join("")
}
identifierStart = UniLetter / [$_]
identifierPart = identifierStart / decimalDigit

ExcludeQuot = i:(charactar / whiteSpace / symbol / "\\\"" / "\\\'" / bracket / diagonal)+ { return i.join("") }
ExcludeBracket = i:(charactar / whiteSpace / symbol / "\\[" / "\\]" / brace / diagonal / quot)+ { return i.join("") }
ExcludeBrace = i:(charactar / whiteSpace / symbol / bracket / "\\{" / "\\}" / diagonal / quot)+ { return i.join("") }
string = i:(charactar)+ { return i.join("")}

charactar = UniLetter / decimalDigit
whiteSpace = " " / "\r" / "\t"
_  = __?
__ = ws:whiteSpace+ {return ws.join("");}
TERM = "\n"
TERMINATOR = t:(_ a:TERM{return a})+ {return t.join("");}
UniLetter = [A-Za-z]
decimalDigit = [0-9]
bracket = "[" / "]"
brace = "{" / "}"
diagonal = "/"
quot = "\"" / "\'"
symbol =  "!" / "#" / "$" / "%" / "&" / "(" / ")" / "*" / "+" / "," / "-" / "." / ":" / ";" / "<" / "=" / ">" / "?" / "@" / "\\" / "^" / "_" / "`" / "|" / "~"
