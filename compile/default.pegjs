{
node= require('../../../treeNode.coffee')
us = require('lodash')

precedence =
  [ ['||'],
  ['&&'],
  ['===','!=='],
  ['<=','>=','<','>'],
  ['+','-'],
  ['*','/','%']
  ]

precedenceTable = (()->
  table = {}
  level = 0
  for ops in precedence
    ops = precedence[level]
    for op in ops
      table[op] = level;
    ++level
  return table;
)();


foldBinaryOp = (parts)->
  if parts.length < 3
    return parts[0];
  else if parts.length is 3
    return makeTerm(parts[0], parts[1], parts[2]);
  else
    precedence = precedenceTable;
    left = parts.shift()
    op = parts.shift()
    right = parts.shift()
    nextOp = parts.shift()
    if precedence[op] <= precedence[nextOp]
      return makeTerm(left, op, makeTerm(right, nextOp, foldBinaryOp(parts)));
    else
      return makeTerm(makeTerm(left, op, right), nextOp, foldBinaryOp(parts));


makeTerm = (l, op, r)->
  return new node.BinaryOperation(l,op,r);

createMemberCall = (head,access)->
  if !access?
    return head
  switch access.acc
    when "call"
      return new node.Call(head,access.as)
    else
      return head
}

start = program

program = TERMINATOR? _ b:block
{  return new node.Program([b]) }

block = s:statement ss:(_ TERMINATOR _ statement)* TERMINATOR?
{new node.Block([s].concat(ss.map((s)->s[3])))}

statement = ex:expressionworthy {return new node.Expr(ex);} / conditional / return / INDENT b:block DEDENT TERM{return b }

expressionworthy = ABExpr / call / func
ABExpr = assignExpr / binaryExpr

func = params:("(" _ args? _ ")" _ )? "->" _ body:funcBody?
{new node.Function(params[2],body || null) }
args = a:identifier as:(_ "," _ identifier )* {return [a].concat(as.map((x)->x[3]));}
//preprocessor DEDENT -> DEDENT TERM
funcBody = TERMINDENT b:block DEDENT TERM{return b }
    / s:statement {return new node.Block([s]); }

assignExpr = left:left _ "=" !"=" _ right:expressionworthy
{ return new node.Assign(left,right) }


call = fn:callee _ accesses:callAccesses
{
  c = fn
  if accesses
    c = us.foldl(accesses,createMemberCall,c)
  return c
}
callAccesses
  = al:argumentList
  {
    return [{acc:"call",as:al}];
   }
callee = left
argumentList = "(" _ a:argumentListContents? _ ")"{return a || []}
argumentListContents = e:argument es:(_ "," _ argument)*
 {return [e].concat(es.map((e)->e[3]));}
argument = binaryExpr / call

conditional = IF __ cond:ABExpr _ body:conditionalBody _ e:elseClause?
{ return new node.Conditional(cond, body.block, e);}
conditionalBody = b:funcBody{ return {block: b}; }
elseClause = TERMINATOR? _ ELSE b:elseBody { return b; }
elseBody = funcBody

leftExpr = call / primary

return = RETURN __ e:expressionworthy? {return new node.Return(e || null);}

binaryExpr = l:leftExpr r:( _ o:binaryOperator _ e:(expressionworthy / primary){return [o,e]})* {
  return foldBinaryOp([l].concat(us.flatten(r)));
}
binaryOperator = a:CompoundAssignmentOperators !"=" {return a;} / "<=" / ">=" / "<" / ">" / "==" {return "===";} / "!=" {return "!==";}
CompoundAssignmentOperators = a:("&&" / "||" / [*/%] / e:"+" !"+" {return e;} / e:"-" !"-" {return e;}){
  return a;
}

primary = literal / left
literal = Number / bool
left = identifier

bool = TRUE {return new node.Bool(true)} / FALSE {return new node.Bool(false)}

Number = integer

integer "integer"
  = "0" {return new node.Int(0)}
  / head:[1-9] digits:decimalDigit* {return new node.Int(parseInt(head + digits.join(""), 10)); }

decimalDigit = [0-9]

identifier = !reserved i:identifierName { return i; }
identifierName = head:identifierStart tail:identifierPart* {
  tail.unshift(head);
  return new node.Identifier(tail.join(""));
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