# like quote, but it extracts accessors to an AST
# since `[]` doesn't return var NimNode, we're forced to use sequences of indexes rather than
# real references.

from macros import NimNodeKind,
                   kind,
                   `[]`,`[]=`,
                   `$`,
                   len,
                   newNimNode,
                   newTree,
                   quote,
                   newIdentNode, # quote
                   add,
                   treeRepr

type Accessor = seq[int]
type Derp = tuple[name: string, acc: Accessor]


proc default_checker(ident: var NimNode, exp: NimNode): bool {.compileTime.} =
  if exp.kind != nnkAccQuoted:
    return false;
  if exp[0].kind != nnkIdent:
    return false
  ident = exp[0]
  return true

type Checker = type(default_checker)
  
proc accessors(exp: NimNode,
               check: Checker = default_checker,
               parent: Accessor = @[]): seq[Derp] {.compileTime.} =
  var ident: NimNode
  if check(ident, exp):
    result.add(($ident, parent))
    return
  for index in 0..<exp.len:
    var childacc: Accessor
    if parent.len == 0:
      childacc = @[index]
    else:
      childacc = parent
      childacc.insert(0,index)
    result.add(accessors(exp[index], check, childacc))

proc `[]`(exp: NimNode, acc: Accessor): NimNode {.compileTime.} =
  result = exp
  debugEcho(acc)
  debugEcho(result.treeRepr)
  for index in acc:
    debugEcho("III",index)
    debugEcho(result.treeRepr)
    result = result[index]

proc `[]=`(exp: var NimNode, acc: Accessor, value: NimNode) {.compileTime.} =
  if len(acc) == 0:
    exp = value
    return
  if len(acc) == 1:
    debugEcho("fwee ",acc)
    exp[acc[0]] = value
    return
  for index in acc[0..^1]:
    debugEcho("at ", index, ' ', exp.repr)
    exp = exp[index]
  exp[acc[acc.len-1]] = value
    
  
macro unquote(exp: untyped): untyped =
  result = exp
  let acc = accessors(result)
  debugEcho("boing ", acc)
  debugEcho(result.repr)
  for (name, accessor) in acc:
    debugEcho(" ", result[accessor].repr)
    debugEcho("---")
    result[accessor] = newIdentNode("FOOP")
  debugEcho(result.repr)

unquote:
  let `b` = "42"
  let `a` = `b`
  
