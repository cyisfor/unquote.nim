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
             check: Checker = default_checker): seq[Derp] {.compileTime.} =
  proc recurse(exp: NimNode, parent: Accessor): seq[Derp] =
    var ident: NimNode
    if check(ident, exp):
      result.add((ident.repr, parent))
      return
    for index in 0..<exp.len:
      var childacc: Accessor
      if parent.len == 0:
        childacc = @[index]
      else:
        childacc = parent
        childacc.add(index)
      result.add(recurse(exp[index], childacc))
  return recurse(exp, @[])
  
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
