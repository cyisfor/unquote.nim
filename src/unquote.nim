# like quote, but it extracts accessors to an AST
# since `[]` doesn't return var NimNode, we're forced to use sequences of indexes rather than
# real references.

type Accessor = seq[int]

iterator accessors(exp: NimNode, op = nnkPostfix, parent: Accessor = @[]): seq[tuple[string, Accessor]] =
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
  for index in 0..<parent.len:
    let childacc = parent.copy
    childacc.add(index)
    for thing in accessors(parent[index], op, parent):
      yield thing

macro unquote(exp: untyped, op = nnkPostfix): untyped =
  for (name, accessor) in accessors(exp):
    debugEcho(name, accessor)

unquote:
  this
  is
  a
  test*
  of
    unquoting
