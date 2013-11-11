{
  @indent = [0]
}

start = stmts:Stmt* {stmts.join('')}

LineTerminator = [\n]
WhiteSpace = [ \t]
_ = WhiteSpace*

ExcludeLineTerminator = !LineTerminator c:. {c}
Stmt = chars:ExcludeLineTerminator+ i:Indent {
  str = chars.join('')
  #console.log "pre stmt ",str,i.str
  indent = i.indent
  line = i.line

  INDENT = '\uEFEF'
  DEDENT = '\uEFFE'
  TERM   = '\uEFFF'

  str = str + (Array(line + 1).join '\n')

  last = @indent[@indent.length - 1]

  if indent > last
    #str = str + i.str + INDENT #" INDENT "
    str = str + INDENT #" INDENT "
    @indent.push(indent)
  else if indent < last
   while indent != @indent[@indent.length - 1]
     str = str + DEDENT + TERM + '\n'#" DEDENT "
     @indent.pop()

  str
}

Indent = l:LineTerminator+ w:_ {{str:(l.join('')+w),line:l.length, indent:w.length}}
/ w:_ {{str:w,line:0, indent:w.length}}
