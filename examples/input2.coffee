1
a = (b,c)->
	if b < 3
		b+c
	else
		return b - c

extend default,b
	let = "let" _ "(" _ vars:vars _ ")" _ "in" _ TERMINDENT b:block DEDENT TERM
		return "\n\uEFEF"+vars+"\n"+b+"\n\uEFFE\uEFFF\n"
	vars = a:assignExpr as:(_ "," _ assignExpr )*
		return a + as.map((x)->"\n" + x[3]).join("")

use b

let (a = 1,b=2) in
	a + b
()->
	d = 1
	e = 3
	d + e


b = 2
a(b,4)
use c1

let ( a = 3 , b = 4 ) in
	a + b