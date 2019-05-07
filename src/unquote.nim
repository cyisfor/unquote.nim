# like quote, but it extracts accessors to an AST
# since `[]` doesn't return var NimNode, we're forced to use sequences of indexes rather than
# real references.

from macros import NimNodeKind, kind, `[]`,`$`,len

type Accessor = seq[int]
type Derp = tuple[name: string, acc: Accessor]

proc accessors(exp: NimNode,
               op: string = "*",
               parent: Accessor = @[]): seq[Derp] =
  debugEcho("kind ",exp.kind, " ", exp.repr)
  if exp.kind == nnkPrefix and $exp[0] == op:
    let ident = exp[1]
    debugEcho("yay ",ident)
    result.add(($ident, parent))
    return
  for index in 0..<exp.len:
    var childacc = parent
    childacc.add(index)
    debugEcho("childacc",childacc)
    for thing in accessors(exp[index], op, parent):
      result.add(thing)

macro unquote(op: static[string] = "*", exp: untyped): untyped =
  debugEcho("wuh")
  for thing in accessors(exp, op):
    let name = thing[0]
    let accessor = thing[1]
    debugEcho("boing", name, accessor)

unquote("*"):
  this
  iz
  a
  *test
  offf
  unquoting
