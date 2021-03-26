import ../src/ccd
import support
from math import PI
from system/ansi_c import c_printf, c_sprintf
export c_printf

when defined(testsHighPrecision):
  type real* = float64
else:
  type real* = float32

proc svtCyl*[R](c: ptr CollisionObj, color, name: cstring) =
  var v: array[32, Vec3]
  var rot: Quat
  var axis, vpos, vpos2: Vec3
  var angle, x, y: R

  axis = vec3(0, 0, 1)
  vpos = vec3(0, c[].radius, 0)
  angle = 0
  for i in 0..<16:
    angle = cast[R](i) * (2f * PI / 16f)

    setAngleAxis(rot, angle, axis)
    vpos2 = vpos
    rotateByQuat(vpos2, rot)
    x = vpos2.x
    y = vpos2.y

    v[i] = vec3(x, y, c[].height / 2f)
    v[i + 16] = vec3(x, y, -c[].height / 2f)

  for i in 0..<32:
    rotateByQuat(v[i], c[].quat)
    v[i] += c[].pos

  c_printf("-----\n")
  if name != nil:
    c_printf("Name: %s\n", name)

  c_printf("Face color: %s\n", color)
  c_printf("Edge color: %s\n", color)
  c_printf("Point color: %s\n", color)
  c_printf("Points:\n")
  for i in 0..<32:
    c_printf("%lf %lf %lf\n", v[i].x, v[i].y, v[i].z)

  c_printf("Edges:\n")
  c_printf("0 16\n")
  c_printf("0 31\n")
  for i in 1..<16:
    c_printf("0 %d\n", i)
    c_printf("16 %d\n", i + 16)
    if i != 0:
      c_printf("%d %d\n", i - 1, i)
      c_printf("%d %d\n", i + 16 - 1, i + 16)

    c_printf("%d %d\n", i, i + 16)
    c_printf("%d %d\n", i, i + 16 - 1)

  c_printf("Faces:\n")
  for i in 2..<16:
    c_printf("0 %d %d\n", i, i - 1)
    c_printf("16 %d %d\n", i + 16, i + 16 - 1)

  c_printf("0 16 31\n")
  c_printf("0 31 15\n")
  for i in 1..<16:
    c_printf("%d %d %d\n", i, i + 16, i + 16 - 1)
    c_printf("%d %d %d\n", i, i + 16 - 1, i - 1)
  c_printf("-----\n")

proc svtBox*(b: ptr CollisionObj, color, name: cstring) =
  var v: array[8, Vec3]

  v[0] = vec3(b[].x * 0.5, b[].y * 0.5, b[].z * 0.5)
  v[1] = vec3(b[].x * 0.5, b[].y * -0.5, b[].z * 0.5)
  v[2] = vec3(b[].x * 0.5, b[].y * 0.5, b[].z * -0.5)
  v[3] = vec3(b[].x * 0.5, b[].y * -0.5, b[].z * -0.5)
  v[4] = vec3(b[].x * -0.5, b[].y * 0.5, b[].z * 0.5)
  v[5] = vec3(b[].x * -0.5, b[].y * -0.5, b[].z * 0.5)
  v[6] = vec3(b[].x * -0.5, b[].y * 0.5, b[].z * -0.5)
  v[7] = vec3(b[].x * -0.5, b[].y * -0.5, b[].z * -0.5)

  for i in 0..<8:
    rotateByQuat(v[i], b[].quat)
    v[i] += b[].pos

  c_printf("-----\n")
  if name != nil:
    c_printf("Name: %s\n", name)
  c_printf("Face color: %s\n", color)
  c_printf("Edge color: %s\n", color)
  c_printf("Point color: %s\n", color)
  c_printf("Points:\n")
  for i in 0..<8:
    c_printf("%lf %lf %lf\n", v[i].x, v[i].y, v[i].z)

  c_printf("Edges:\n")
  c_printf("0 1\n 0 2\n2 3\n3 1\n1 2\n6 2\n1 7\n1 5\n")
  c_printf("5 0\n0 4\n4 2\n6 4\n6 5\n5 7\n6 7\n7 2\n7 3\n4 5\n")

  c_printf("Faces:\n")
  c_printf("0 2 1\n1 2 3\n6 2 4\n4 2 0\n4 0 5\n5 0 1\n")
  c_printf("5 1 7\n7 1 3\n6 4 5\n6 5 7\n2 6 7\n2 7 3\n")
  c_printf("-----\n")

proc svtObj*(o: ptr CollisionObj, color, name: cstring) =
  case o[].typ
  of Cylinder: svtCyl(o, color, name)
  of Box: svtBox(o, color, name)
  else: discard

proc svtObjPen*[R](o1, o2: ptr CollisionObj, name: cstring, depth: R, dir, pos: Vec3[R]) =
  var oname: array[500, char]

  let sep: Vec3 = dir * depth + pos

  c_printf("------\n")
  if name != nil:
    c_printf("Name: %s\n", name)
  c_printf("Point color: 0.1 0.1 0.9\n")
  c_printf("Points:\n%lf %lf %lf\n", pos.x, pos.y, pos.z)
  c_printf("------\n")
  c_printf("Point color: 0.1 0.9 0.9\n")
  c_printf("Edge color: 0.1 0.9 0.9\n")
  c_printf("Points:\n%lf %lf %lf\n", pos.x, pos.y, pos.z)
  c_printf("%lf %lf %lf\n", sep.x, sep.y, sep.z)
  c_printf("Edges: 0 1\n")

  oname[0] = 0x0.char
  if name != nil:
    discard c_sprintf(cast[cstring](addr oname), "%s o1", name)
  svtObj(o1, "0.9 0.1 0.1", cast[cstring](addr oname))

  oname[0] = 0x0.char
  if name != nil:
    discard c_sprintf(cast[cstring](addr oname), "%s o1", name)
  svtObj(o2, "0.1 0.9 0.1", cast[cstring](addr oname))

proc recPen*[R](depth: R, dir, pos: Vec3[R], note: cstring) =
  let note = if note == nil: "".cstring
             else: note

  c_printf("# %s: depth: %lf\n", note, depth)
  c_printf("# %s: dir:   [%lf %lf %lf]\n", note, dir.x, dir.y, dir.z)
  c_printf("# %s: pos:   [%lf %lf %lf]\n", note, pos.x, pos.y, pos.z)
  c_printf("#\n")

