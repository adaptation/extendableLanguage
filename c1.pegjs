{
node= require('../../../treeNode.coffee')
us = require('lodash')

makeTerm = (l, op, r)->
  return new node.BinaryOperation(l,op,r);
}
start = program

program = TERMINATOR? _ b:block
{  return b }

block = s:statement ss:(_ TERMINATOR _ statement)* TERMINATOR?
{
  a = ""
  if ss.length > 0
    a += ss.map((x)-> "\n" + x[3]).join("")
  return s + a
}

statement = let / expressionworthy / conditional / return

let = "let" _ "(" _ vars:vars _ ")" _ "in" _ TERMINDENT b:block DEDENT TERM
{
  return "\n\uEFEF"+vars+"\n"+b+"\n\uEFFE\uEFFF\n"
}
vars = a:assignExpr as:(_ "," _ assignExpr )*
{return a + as.map((x)->"\n" + x[3]).join("")}

expressionworthy = ABExpr / call / func
ABExpr = assignExpr / binaryExpr

func = params:("(" _ args? _ ")" _ )? "->" _ body:funcBody?
{
  return "(" + (params[2] || "") + ")->" + (body || "")
}
args = a:identifier as:(_ "," _ identifier )*
{
  return a + as.map((x)->x[1] + x[3]).join("")
}
//preprocessor DEDENT -> DEDENT TERM
funcBody = TERMINDENT b:block DEDENT TERM
{
  return "\n\uEFEF"+b+"\n\uEFFE\uEFFF\n"
 }
    / s:statement {return s }

assignExpr = left:left _ "=" !"=" _ right:expressionworthy
{ return left + "=" + right }


call = fn:callee _ accesses:callAccesses
{
  c = fn
  if accesses
    c += accesses
  return c
}
callAccesses = al:argumentList{return al }
callee = left
argumentList = "(" _ a:argumentListContents? _ ")"
{
  b = "("
  if a
    b += a
  b += ")"
  return b
}
argumentListContents = e:argument es:(_ "," _ argument)*
 {return e + es.map((e)->e[1] + e[3]).join("");}
argument = binaryExpr / call

conditional = IF __ cond:ABExpr _ body:conditionalBody _ e:elseClause?
{ return "if "+cond+body+(e || "")}
conditionalBody = funcBody
elseClause = TERMINATOR? _ ELSE b:elseBody
{ return "else "+b }
elseBody = funcBody

leftExpr = call / primary

return = RETURN __ e:expressionworthy? {return "return "+(e || "")}

binaryExpr = l:leftExpr r:( _ o:binaryOperator _ e:(expressionworthy / primary){return [o,e]})* {
  return l + us.flatten(r).join("")
}
binaryOperator = a:CompoundAssignmentOperators !"=" {return a;} / "<=" / ">=" / "<" / ">" / "==" {return "===";} / "!=" {return "!==";}
CompoundAssignmentOperators = a:("&&" / "||" / [*/%] / e:"+" !"+" {return e;} / e:"-" !"-" {return e;}){
  return a;
}

primary = literal / left
literal = Number / bool
left = identifier

bool = TRUE / FALSE

Number = integer

integer "integer"
  = "0" {return "0"}
  / head:[1-9] digits:decimalDigit* {return head + digits.join("") }

decimalDigit = [0-9]

identifier = !reserved i:identifierName { return i; }
identifierName = head:identifierStart tail:identifierPart* {
  tail.unshift(head);
  return tail.join("")
}
identifierStart
  = UniLetter
  / [$_]
identifierPart
  = identifierStart
  / decimalDigit

//keyword
IF = a:"if" !identifierPart {return a}
ELSE = a:"else" !identifierPart {return a}
RETURN = a:"return" !identifierPart {return a}

TRUE = a:"true" !identifierPart {return a}
FALSE = a:"false" !identifierPart {return a}

whiteSpace = " " / "\r"
_  = __?
__ = ws:whiteSpace+ {return ws.join("");}

INDENT = "\uEFEF"
DEDENT = ws:(TERMINATOR? _) "\uEFFE" { return ws.join(""); }
TERM = n:("\r"? "\n"){return n.join("");} / "\uEFFF" { return ''; }
TERMINATOR = t:(_ TERM)+ {return t.join("");}
TERMINDENT = t:(TERMINATOR INDENT) {return t.join("");}

Keywords
  = ("true" / "false" / "return" / "if" / "else") !identifierPart

reserved = Keywords

UniLetter = [A-Za-z]