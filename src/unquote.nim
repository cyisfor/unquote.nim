# like quote, but it extracts accessors to an AST
# since `[]` doesn't return var NimNode, we're forced to use sequences of indexes rather than
# real references.

from macros import NimNodeKind, kind, `[]`,`$`,len

type Accessor = seq[int]
type Derp = tuple[name: string, acc: Accessor]

proc accessors(exp: NimNode,
               op: NimNodeKind = nnkPostfix,
               parent: Accessor = @[]): iterator(): Derp =
  iterator it(): Derp {.closure.} =
    var ident: NimNode
    if exp.kind == op:
      case op:
      of nnkAccQuoted:
        ident = exp[0]
        # other special cases here
        # the typical thing is to have nnkSomething(uselessqualifier, ident) for any prefix ops
        # and [x] is nnkBracketExpr(nothing, x) so 1 is the usual index of the ident
      else:
        ident = exp[1]
      if ident.kind == nnkIdent:
        yield ($ident, parent)
    for index in 0..<exp.len:
      var childacc = parent
      childacc.add(index)
      for thing in accessors(exp[index], op, parent)():
        yield thing
  return it

macro unquote(op: static[NimNodeKind] = nnkPostfix, exp: untyped): untyped =
  debugEcho("wuh")
  for thing in accessors(exp, op)():
    let name = thing[0]
    let accessor = thing[1]
    debugEcho(name, accessor)

unquote(nnkPostFix):
  this
  iz
  a
  test*
  offf
  unquoting
