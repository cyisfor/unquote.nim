# like quote, but it extracts accessors to an AST
# since macros.`[]` doesn't return var NimNode, we're forced to use sequences of indexes
# rather than real references.

from algorithm import reversed

from macros import NimNodeKind,
                   kind,
                   `[]`,`[]=`,
                   `$`,
                   len,
                   newNimNode,
                   newTree,
                   quote,
                   newIdentNode, # quote
                   add,del,insert,copy,
                   treeRepr,
                   newIntLitNode

type Accessor* = seq[int]
type Derp = tuple[name: string, acc: Accessor]

#[
Note: You can write your own checker, which picks out a node type to remove, and replace with
an ident. An "ofBranch" might be one possibility...
]#

proc default_checker*(ident: var NimNode, exp: NimNode): bool {.compileTime.} =
  if exp.kind != nnkAccQuoted:
    return false;
  if exp[0].kind != nnkIdent:
    return false
  ident = exp[0]
  return true

type Checker* = type(default_checker)
  
proc unquote*(exp: NimNode,
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
      childacc.add(index)
    result.add(unquote(exp[index], check, childacc))

{.hint[XDeclaredButNotUsed]: off.}    
proc `[]`(exp: NimNode, acc: Accessor): NimNode {.compileTime.} =
  result = exp
  for index in acc:
    result = result[index]

{.hint[XDeclaredButNotUsed]: off.}    
proc `[]=`(exp: var NimNode, acc: Accessor, value: NimNode) {.compileTime.} =
  if len(acc) == 0:
    exp = value
    return
  if len(acc) == 1:
    exp[acc[0]] = value
    return
  var cur = exp
  for index in acc[0..^2]:
    cur = cur[index]
  cur[acc[acc.len-1]] = value

proc interpolate(exp: var NimNode, acc: Accessor, values: varargs[NimNode]) {.compileTime.} =
  if len(acc) == 0:
    if len(values) == 0:
      exp = values[0]
    else:
      exp = newTree(nnkStmtList, values)
    return
  var cur = exp
  for index in acc[0..^2]:
    cur = exp[index]
  let index = acc[^1]
  cur.del(index)
  for value in reversed(values):
    cur.insert(index, value)
  
when isMainModule:    
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

  proc ofbranches(ident: var NimNode, exp: NimNode): bool {.compileTime.} =
    if exp.kind == nnkOfBranch:
      ident = exp[0]
      return true
    return false
  macro addbranches(exp: untyped): untyped =
    result = exp
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
