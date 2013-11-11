_ = require "lodash"

exports.Program = class Program
  constructor:(@body)->
    @type = "Program"
  toString:()->
    @body.map((x)->x.toString())
  toESC:()->
    return {type:@type, body: @body.map((x)-> return x.toESC())}

exports.Expr = class Expr
  constructor:(@expr)->
    @type = "ExpressionStatement"
  toString:()-> return @expr.toString()
  toESC:()-> return makeExpr @expr.toESC()

makeExpr = (expr)->
  return {
    type:"ExpressionStatement",
    expression:expr
  }

exports.Function = class Function
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

exports.Literal = class Literal
  constructor:(@literal)->
    @type = "Literal"
  toString:()-> return @literal.toString()
  toESC:()-> return {type: @type, value: @literal}

exports.Int = class Int extends Literal

exports.Bool = class Bool extends Literal

@String = class String extends Literal

exports.Identifier = class Identifier
  constructor:(@identifier)->
    @type = "Identifier"
  toString:()->
    return @identifier
  toESC:()->
    return {type: @type,name: @identifier.toString()}

exports.Operator = class Operator
  constructor:(@op)->
    @type = "Operator"
  toString:()->
    return @op
  toESC:()->
    return @op

exports.Block = class Block
  constructor:(@block)->
    @type = "BlockStatement"
  toString:()->
    return "{" + @block.map((x)-> return x.toString()) + "}"
  toESC:()->
    block = @block.map((x)-> return x.toESC())
    dec = (setVar @env).concat(setExtends @env)
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

exports.Assign = class Assign
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

@Class = class Class
  constructor:(@name,@parent,@body)->
    @type = 'Class'
  toString:()->
    if @parent
      p = " extends "+@parent.toString()
    else
      p = ""
    "class "+@name.toString()+p+"\n"+@body.toString()
  toESC:()->
    name = @env.className.toESC()
    args = []
    _super = []
    @const = (_.find @body.block,(st)-> return (st.type is "Constructor") )
    @body.block = _.reject @body.block,(st)-> return (st.type is "Constructor")
    body = @body.toESC()
    if @parent?
      parent = @parent.toESC()
      _super.push (makeId "_super")
      body.body.unshift (makeExpr makeCall( (makeId "__extends"), [ (name) ,(makeId "_super")] ))
      if !@const
        body.body.unshift (makeExpr (makeAssign name,(makeFunc null,[],makeBlock [(makeReturn ( makeCall (makeMember (makeMember (makeMember name,(makeId "__super__"),false),(makeId "constructor"),false),(makeId "apply"),false),[makeThis(),(makeId "arguments")]))],false)))
      else
        body.body.unshift @const.toESC()
      args.push parent
    else
      if !@const
        body.body.unshift (makeExpr (makeAssign name,(makeFunc null,[],(makeBlock []),false)))

    body.body.push (makeReturn name)
    v = makeVarDeclaration ([makeVarDeclarator name.name,null])
    body.body.unshift (v)
    r = makeCall (makeFunc null,_super,body,false), args
    if @name?
      return {
        type:"AssignmentExpression",
        operator:"=",
        left:@name.toESC(),
        right: r
      }
    else
      return r


makeCall = (callee,args)->
  return {
    type: "CallExpression",
    callee:callee,
    arguments:args
  }

@InsAssign = class InsAssign
  constructor:(@left,@right)->
    @type="InsAssign"
  toString:()->
    return @left.toString() + ":" + @right.toString()
  toESC:()->
    return makeAssign makeMember(makeMember(@className.toESC(),makeId("prototype")), @left.toESC(),false), @right.toESC()



makeObj = (properties)->
  return {
    type:"ObjectExpression",
    properties:properties
  }

makeMember = (obj,prop,cmp)->
  return {
    type: "MemberExpression",
    object:obj,
    property:prop,
    computed:cmp
  }

makeReturn = (arg)->
  return {
    type:"ReturnStatement",
    argument: arg
  }

makeForIn = (left,right,body)->
  return {
    type:"ForInStatement",
    left:left,
    right:right,
    body:body,
    each:false
    }

makeThis = ()->
  return {
    type:"ThisExpression"
  }

makeNew = (call,args)->
  return {
    type:"NewExpression",
    callee:call,
    arguments:args
  }



setExtends = (env)->
  extend = []
  if env.extend
    extend.push makeVarDeclarator "__hasProp", makeMember(makeObj([]), makeId("hasOwnProperty"),false)
    ex =  makeVarDeclarator "__extends",
      makeFunc(null,[(makeId "child"), (makeId "parent")],
        (makeBlock [
          makeForIn(
            (makeVarDeclaration [ makeVarDeclarator("key",null) ]) ,
            (makeId "parent"),
            (makeIf (makeCall (makeMember (makeId "__hasProp"),(makeId "call" ),false), [(makeId "parent"), (makeId "key")] ),
              makeExpr makeAssign (makeMember (makeId "child"),(makeId "key"),true ),
                (makeMember (makeId "parent"),(makeId "key"),true ) ,
              null)
          ),
          (makeExpr (makeAssign (makeId "ctor"),makeFunc(
            null,[],
            (makeBlock [makeExpr (makeAssign (makeMember makeThis(),(makeId "constructor"),false),(makeId "child"))]),
            false))),
          (makeExpr makeAssign(
            (makeMember (makeId "ctor"),(makeId "prototype")),
            (makeMember (makeId "parent"),(makeId "prototype")))),
          (makeExpr makeAssign(
            (makeMember (makeId "child"),(makeId "prototype")),
            (makeNew (makeId "ctor"),[]))),
          (makeExpr makeAssign(
            (makeMember (makeId "child"),(makeId "__super__")),
            (makeMember (makeId "parent"),(makeId "prototype")))),
          (makeReturn (makeId "child"))
        ]),false)
    extend.push ex
    return extend
  else
    return extend

@Constructor = class Constructor
  constructor:(@body)->
    @type = "Constructor"
  toString:()->
    "constructor:"+@body.toString()
  toESC:()->
    return makeExpr (makeAssign @className.toESC(),@body.toESC())

@Member = class Member
  constructor:(@obj,@prop)->
    @type = "Member"
  toString:()->
    @obj.toString() + "." + @prop.map((x)->x.toString())
  toESC:()->
    if @prop.length isnt 0
      p = @prop.map((x)->x.toESC())
      property = p.pop()
      object = makeMemberObj @obj.toESC(),p
      return (makeMember object, property, false)
    else
      return @obj.toESC()

makeMemberObj = (obj, prop)->
  toObj = (obj,prop)->
    makeMember(obj,prop,false)
  object = _.foldl(prop,toObj,obj)
  return object

@New = class New
  constructor:(@obj,@args)->
    @type = "New"
  toString:->
    "new "+@obj.toString()+"( "+@args.map((x)->x.toString())+" )"
  toESC:->
    if @obj.type is "Identifier"
      return (makeNew @obj.toESC(),@args.map((x)->x.toESC()))
    else
      return (makeNew @obj.obj.toESC(),@args.map((x)->x.toESC()))

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

@This = class This
  constructor:()->
    @type = "This"
  toString:()->
    "this"
  toESC:()->
    return (makeThis() )

@Array = class Array
  constructor:(@members)->
    @type = "Array"
  toString:()->
    return "[" + @members.map((x)->x.toString()) + "]"
  toESC:()->
    return makeArray @members.map((x)->x.toESC())

makeArray = (members)->
  return {
    type:"ArrayExpression",
    elements:members
  }

@Object = class Object
  constructor:(@members)->
    @type = "Object"
  toString:()->
    return "{"+@members.map((x)->x.toString()) + "}"
  toESC:()->
    console.log @members
    return makeObj @members.map((x)->{key:x.key.toESC(),value:x.value.toESC(),kind:"init"})

@Call = class Call
  constructor:(@callee,@args)->
    @type = "Call"
  toString:()->
    return @callee.toString() + "(" + @args.map((x)->x.toString()) + ")"
  toESC:()->
    return makeCall @callee.toESC(),@args.map((x)->x.toESC())
