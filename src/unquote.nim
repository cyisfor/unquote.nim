# like quote, but it extracts accessors to an AST
# since `[]` doesn't return var NimNode, we're forced to use sequences of indexes rather than
# real references.

from macros import NimNodeKind,
                   kind,
                   `[]`,
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

proc accessors(exp: NimNode,
               op: string = "*",
               kind: NimNodeKind = nnkPrefix,
               parent: Accessor = @[]): seq[Derp] =
  debugEcho("kind ",exp.kind, " ", exp.repr)
  if exp.kind == kind and $exp[0] == op:
    let ident = exp[1]
    debugEcho("yay ",ident)
    result.add(($ident, parent))
    return
  for index in 0..<exp.len:
    var childacc = parent
    childacc.add(index)
    debugEcho("childacc",childacc)
    result.add(accessors(exp[index], op, kind, childacc))

type Opts = tuple
  op: string
  kind: NimNodeKind

proc opts(op: string = "*", kind: NimNodeKind = nnkPrefix): Opts {.compileTime.} =
  return (op: op, kind: kind)
  
macro unquote(opts: static[Opts], exp: untyped): untyped =
  result = newNimNode(nnkStmtList)
  debugEcho("wuh")
  for thing in accessors(exp, opts.op, opts.kind):
    let name = newIdentNode(thing[0])
    let accessor = thing[1]
    debugEcho("boing", name, accessor)
    let expr = quote:
      let `name`: Accessor = @`accessor`
    debugEcho(expr.repr)
    result.add(expr)

unquote(opts()):
  iz
  a
  *test
  offf [*something]
  unquoting
