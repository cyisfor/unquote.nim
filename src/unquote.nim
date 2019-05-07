# like quote, but it extracts accessors to an AST
# since `[]` doesn't return var NimNode, we're forced to use sequences of indexes rather than
# real references.

from macros import NimNodeKind, kind, `[]`,`$`,len

type Accessor = seq[int]
type Derp = tuple[name: string, acc: Accessor]

proc accessors(exp: NimNode,
               op = nnkPostfix,
               parent: Accessor): iterator(): Derp =
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
      for thing in accessors(exp[index], op, parent):
        yield thing

macro unquote(exp: untyped, op = nnkPostfix): untyped =
  for (name, accessor) in accessors(exp, op, @[]):
    debugEcho(name, accessor)

unquote:
  this
  is
  a
  test*
  of
    unquoting
