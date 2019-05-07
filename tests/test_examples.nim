import unittest
import unquote

from macros import newIdentNode,
                   `[]`,`[]=`,
                   kind,
                   NimNodeKind,
                   copy,
                   newIntLitNode
    
test "inject variable identifiers":
  macro mongle(exp: untyped): untyped =
    result = exp
    let acc = unquote(result)
    for (name, accessor) in acc:
      result[accessor] = newIdentNode("FOOP" & name)

  mongle:
    let `b` = "42"
    let `a` = `b`
  check declared(FOOPb)
  check FOOPb == "42"
  check FOOPa == "42"
  
test "extend a case statement with generated \"of\" branches":
  proc ofbranches(ident: var NimNode, exp: NimNode): bool {.compileTime.} =
    if exp.kind == nnkOfBranch:
      ident = exp[0]
      return true
    return false
  macro addbranches(exp: untyped): untyped =
    result = exp
    debugEcho("==== before: ==== ")
    debugEcho(exp.repr)
    debugEcho("===============")
    for (name, acc) in unquote(result, ofbranches):
      debugEcho("ofBranch ",name)
      let model = exp[acc]
      var branches: array[0..3, NimNode]
      for i in 0..<branches.len:
        branches[i] = model.copy
        branches[i][0] = newIntLitNode(i)
      interpolate(result, acc, branches)
    debugEcho("==== after: ==== ")
    debugEcho(result.repr)
    debugEcho("===============")
    
  let thing = 2

  addbranches:
    case thing:
    of anything123545:
      check true
    else:
      check false
  case thing:
  of 0:
    check false
  else:
    check true
