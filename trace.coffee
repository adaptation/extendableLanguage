_ = require 'lodash'
node = require './treeNode.coffee'

exports.trace = (Node,env=null)->
  switch Node.type
    when "Program"
      exports.trace Node.body[0],env
      Node
    when "ExpressionStatement"
      exports.trace Node.expr,env
    when "FunctionExpression"
      if Node.body
        exports.trace Node.body,env
        if Node.body.env?
          args = _.map Node.args,(x)-> (x.toString())
          Node.body.env.variable = _.reject(Node.body.env.variable,(x)->(_.contains(args,x)))
      env
    when 'BinaryExpression'
      env
    when 'IfStatement'
      exports.trace Node.body,env
      exports.trace Node.cond,env
      if Node.else
        exports.trace Node.else,env
    when "Literal","Operator", "Identifier","Return","BinaryOperation","Call"
      env
    when "BlockStatement"
      if env is null
        newEnv = {variable:[],parent:null,extend:false}
      else
        newEnv = {variable:[],parent:env}
      Node.env = traceBlock Node.block,newEnv
      env
    when "AssignmentExpression"
      left = Node.left
      if left.type is "Member"
        if left.prop.length is 0 and left.obj.type is "Identifier"
          addVariable(left.obj.toString() ,env)
      exports.trace Node.right,env
      env
    else
      console.log "Trace error"
      console.log Node.type
      env

traceBlock = (block,env)->
  for elem in block
    exports.trace elem,env
  env

addVariable = (v,env)->
  if !(_.find env.variable,(x)-> x is v)
    env.variable.push v

getTopEnv = (env)->
  if env.parent is null
    env
  else
    getTopEnv env.parent