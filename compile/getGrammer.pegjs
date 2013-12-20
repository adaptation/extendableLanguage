start = pegProgram

pegProgram = TERMINATOR? _ b:pegBlock { return b}

pegBlock = s:(pegStatement TERMINATOR?)+
{
	return s.map((x)->x.join("")).join("")
}

pegStatement = pegRule / a:pegAction TERMINATOR? {return a} / text

pegRule = node:identifier _ "=" _ semantics:pegTerm
{
	return node+" = "+semantics
}
pegTerm = a:pegExpr _ b:( TERMINATOR? _ "/" _ c:pegExpr _ {return c})*
{
	if b.length > 0
		b.unshift a
		return b.join(" / ")
	else
		return a
}

pegAction = "{" TERMINATOR? (ExcludeBrace TERMINATOR?)* "}" { return ""}

pegExpr = a:firstPegExpr _ "*" _ b:pegExpr? {return a+"* "+b }
 / a:firstPegExpr _ "+" _ b:pegExpr? {return a+"+ "+b }
 / a:firstPegExpr _ "?" _ b:pegExpr? {return a+"? "+b }
 / a:firstPegExpr __ b:pegExpr
 {
 	return a+" "+b
 }
 / a:firstPegExpr TERMINATOR? _ pegAction { return a}
 / firstPegExpr
firstPegExpr = pegLiteral / pegChar
 / "(" _ a:pegTerm _ ")" {return "("+a+")"}
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
