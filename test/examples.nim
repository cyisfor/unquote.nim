import unittest
import unquote
    
test "inject variable identifiers":
  macro mongle(exp: untyped): untyped =
    result = exp
    let acc = unquote(result)
    debugEcho("accessors: ", acc)
    debugEcho(result.repr)
    debugEcho("===============")
    for (name, accessor) in acc:
      debugEcho("\n*** doing accessor ", name,' ', accessor)
      debugEcho(result.repr)
      debugEcho("===============")    
  #    debugEcho(" boop ", result[accessor].repr)
      result[accessor] = newIdentNode("FOOP" & name)
      debugEcho("---")
      debugEcho(result.repr)
      debugEcho("==++++ ===")
    debugEcho(result.repr)

  mongle:
    let `b` = "42"
    let `a` = `b`

  echo(FOOPa)

test "extend a case statement with generated \"of\" branches ":
  proc ofbranches(ident: var NimNode, exp: NimNode): bool {.compileTime.} =
    if exp.kind == nnkOfBranch:
      ident = exp[0]
      return true
    return false
  macro addbranches(exp: untyped): untyped =
    result = exp
    debugEcho("==== before: ==== ")
    debugEcho(exp.repr)
    debugEcho("==== after: ==== ")
    for (name, acc) in unquote(result, ofbranches):
      debugEcho("ofBranch",name)
      var branches: array[0..3, NimNode]
      for i in 0..<branches.len:
        branches[i] = exp[acc].copy
        branches[i][0] = newIntLitNode(i)
      interpolate(result, acc, branches)
    debugEcho(result.repr)
    
  let thing = 2

  addbranches:
    case thing:
    of 0:
      debugEcho("foo")
    else:
      debugEcho("bar")
  case thing:
  of 0:
    debugEcho("foo")
  else:
    debugEcho("bar")
