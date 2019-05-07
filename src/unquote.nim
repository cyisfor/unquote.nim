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
  if exp.kind != nnkPrefix:
    return false;
  if $exp[0] != "*":
    return false
  ident = exp[1]
  return true

type Checker = type(default_checker)
  
proc accessors(exp: NimNode,
               check: Checker = default_checker,
               parent: Accessor = @[]): seq[Derp] {.compileTime.} =
  debugEcho("Fug")
  var ident: NimNode
  if check(ident, exp):
    debugEcho("yay ",ident)
    result.add(($ident, parent))
    return
  for index in 0..<exp.len:
    var childacc = parent
    debugEcho("foo", childacc)
    childacc.insert(0,index)
    debugEcho("bar")
    debugEcho("childacc ",index, " ", childacc)
    result.add(accessors(exp[index], check, childacc))

proc `[]`(exp: NimNode, acc: Accessor): NimNode {.compileTime.} =
  if len(acc) == 1:
    return exp[acc[0]]
  return exp[acc[1..^0]]
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
  result = newNimNode(nnkStmtList)
  var derp = exp
  for thing in accessors(derp):
    let name = newIdentNode(thing[0])
    let accessor = thing[1]
    debugEcho("boing", name, accessor, derp[accessor].repr)
    derp[accessor] = newIdentNode("FOOP")
    let expr = quote:
      let `name`: Accessor = @`accessor`
    debugEcho(expr.repr)
    result.add(expr)

unquote:
  iz
  a
  *test
  offf [*something]
  unquoting
