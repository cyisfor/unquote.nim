# like quote, but it extracts accessors to an AST
# since macros.`[]` doesn't return var NimNode, we're forced to use sequences of indexes
# rather than real references.

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

type Accessor* = seq[int]
type Derp = tuple[name: string, acc: Accessor]

const debugging = false

when debugging:
  debugEcho("OSHTINETSH")

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
  when debugging:
    debugEcho("checking at",parent)
    debugEcho(exp.repr)
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
  when debugging:
    debugEcho(acc)
    debugEcho(result.treeRepr)
  for index in acc:
    result = result[index]
    when debugging:
      debugEcho("III",index)
      debugEcho(result.repr)
      debugEcho("=======")

{.hint[XDeclaredButNotUsed]: off.}    
proc `[]=`(exp: var NimNode, acc: Accessor, value: NimNode) {.compileTime.} =
  if len(acc) == 0:
    exp = value
    return
  if len(acc) == 1:
    exp[acc[0]] = value
    return
  when debugging:
    debugEcho("set ACC ",acc)
    debugEcho(exp.repr)
    debugEcho("..........................")
  var cur = exp
  for index in acc[0..^2]:
    cur = cur[index]
    when debugging: debugEcho("at ", index, ' ', cur.repr)
  when debugging:
    debugEcho("setting at ", acc[acc.len-1], " ", cur[acc[acc.len-1]].repr)
  cur[acc[acc.len-1]] = value
  when debugging:
    debugEcho(exp.repr)
    debugEcho("===================")

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
