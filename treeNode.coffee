_ = require "lodash"

@Program = class Program
  constructor:(@body)->
    @type = "Program"
  toString:()->
    @body.map((x)->x.toString())
  toESC:()->
    return {type:@type, body: @body.map((x)-> return x.toESC())}

@Expr = class Expr
  constructor:(@expr)->
    @type = "ExpressionStatement"
  toString:()-> return @expr.toString()
  toESC:()-> return makeExpr @expr.toESC()

makeExpr = (expr)->
  return {
    type:"ExpressionStatement",
    expression:expr
  }

@Function = class Function
  constructor:(@args,@body)->
    @type = "FunctionExpression"
  toString:()->
    if @args
      return "("+@args.toString()+")->"+@body.toString()
    else
      return "->"+@body.toString()
  toESC:()->
    if @args
      params = @args.map((x)-> return x.toESC())
    else
      params = []

    if @body?
      @body.block = setReturn(@body.block)
      body = @body.toESC()
    else
      body = makeBlock [makeEmpty]
    return makeFunc null,params,body,false

setReturn = (body)->
  last = body.pop()
  switch last.type
    when 'ExpressionStatement'
      body.push (new Return(last.expr))
    when 'Return'
      body.push last
    when 'IfStatement'
      last.body.block = setReturn last.body.block
      if last.else
        last.else.block = setReturn last.else.block
      body.push last
    else
      body.push(new Return(last))
  return body

makeEmpty = {type:"EmptyStatement"}

makeFunc = (id,params,body,ex)->
  return {
      type: "FunctionExpression",
      id: id,
      params: params,
      defaults: [ ],
      rest: null,
      body: body,
      generator: false,
      expression: ex
    }

@BinaryOperation = class BinaryOperation
  constructor:(@left,@op,@right)->
    @type = "BinaryOperation"
  toString:()->
    return @left.toString() + @op + @right.toString()
  toESC:()->
    if @op is "||" or @op is "&&"
      return makeLogicalOp @left.toESC(),@op,@right.toESC()
    else
      return makeBinaryOp @left.toESC(),@op,@right.toESC()


makeBinaryOp = (left,op,right)->
  return {type: 'BinaryExpression',
  operator: op,
  left:left,
  right:right
  }

makeLogicalOp = (left,op,right)->
  return {type: 'LogicalExpression',
  operator: op,
  left:left,
  right:right
  }

@Literal = class Literal
  constructor:(@literal)->
    @type = "Literal"
  toString:()-> return @literal.toString()
  toESC:()-> return {type: @type, value: @literal}

@Int = class Int extends Literal

@Bool = class Bool extends Literal

@Identifier = class Identifier
  constructor:(@identifier)->
    @type = "Identifier"
  toString:()->
    return @identifier
  toESC:()->
    return {type: @type,name: @identifier.toString()}

@Operator = class Operator
  constructor:(@op)->
    @type = "Operator"
  toString:()->
    return @op
  toESC:()->
    return @op

@Block = class Block
  constructor:(@block)->
    @type = "BlockStatement"
  toString:()->
    return "{" + @block.map((x)-> return x.toString()) + "}"
  toESC:()->
    block = @block.map((x)-> return x.toESC())
    dec = (setVar @env)
    if dec.length > 0
      declarations = makeVarDeclaration (dec)
      block.unshift(declarations)
    return makeBlock block

makeBlock = (body)->
  return {
    type:"BlockStatement",
    body:body
  }

makeId = (id)->
  return {type: "Identifier",name: id.toString()}

makeVarDeclarator = (id,init)->
  {
    type:"VariableDeclarator",
    id: makeId(id) ,
    init:init
  }

makeVarDeclaration = (vars)->
  return {
      type:"VariableDeclaration",
      declarations:vars,
      kind:"var"
    }

setVar = (env)->
  if env.variable.length > 0
    vars = env.variable.map (x)-> return makeVarDeclarator x,null
    return vars
  else
    return []

@Assign = class Assign
  constructor:(@left,@right)->
    @type = "AssignmentExpression"
  toString:()->
    return @left.toString() + "=" + @right.toString()
  toESC:()->
    return makeAssign @left.toESC(), @right.toESC()

makeAssign = (left,right)->
  return {
    type:"AssignmentExpression",
    operator:"=",
    left:left,
    right:right
  }

@Conditional = class Conditional
  constructor:(@cond,@body,@else)->
    @type = "IfStatement"
  toString:()->
    if @else?
      return " if " + @cond.toString() + " \n " + @body.toString() + " \n else " + @else.toString()
    else
      return " if " + @cond.toString() + " \n " + @body.toString() + " \n"
  toESC:()->
    if @else
      alternate = @else.toESC()
    else
      alternate = null
    return makeIf @cond.toESC(), @body.toESC(), alternate

makeIf = (test,consequent,alter)->
  return {
    type:"IfStatement",
    test:test,
    consequent:consequent,
    alternate:alter
  }


makeCall = (callee,args)->
  return {
    type: "CallExpression",
    callee:callee,
    arguments:args
  }

makeReturn = (arg)->
  return {
    type:"ReturnStatement",
    argument: arg
  }

@Return = class Return
  constructor:(@expr)->
    @type = "Return"
  toString:()->
    "return "+expr.toString()
  toESC:()->
    if @expr
      expr = @expr.toESC()
    else
      expr = @expr
    return (makeReturn expr)

@Call = class Call
  constructor:(@callee,@args)->
    @type = "Call"
  toString:()->
    return @callee.toString() + "(" + @args.map((x)->x.toString()) + ")"
  toESC:()->
    return makeCall @callee.toESC(),@args.map((x)->x.toESC())