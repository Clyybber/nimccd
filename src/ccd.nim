#[
  libccd
  ---------------------------------
  Copyright (c)2012 Daniel Fiser <danfis@danfis.cz>


   This file is part of libccd.

   Distributed under the OSI-approved BSD License (the "License")
   see accompanying file BDS-LICENSE for details or see
   <http://www.opensource.org/licenses/bsd-license.php>.

   This software is distributed WITHOUT ANY WARRANTY; without even the
   implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
   See the License for more information.
]#

from system/ansi_c import c_free, c_malloc
from math import sqrt
from fenv import epsilon

template ccdEps*(n): untyped =
  epsilon(n) # XXX: C version had 1E-6 for float32; and 1E-10 for float64

import glm except vec3, normalize, sign
export glm except vec3, normalize, sign

func isZero*[R](val: R): bool {.inline.} =
  ## Returns true if val is zero.
  abs(val) < ccdEps(R)

func sign*[R](val: R): int {.inline.} =
  ## Returns sign of value.
  if isZero(val): 0
  elif val < 0: -1
  else: 1

func `=~`*[R](a, b: R): bool {.inline.} =
  ## Returns true if a and b equal.
  let ab = abs(a - b)
  if ab < ccdEps(R): return true
  let a = abs(a)
  let b = abs(b)
  return if b > a: ab < ccdEps(R) * b
         else: ab < ccdEps(R) * a

func `=~`*(a, b: Vec3): bool {.inline.} =
  ## Returns true if a and b equal.
  a.x =~ b.x and a.y =~ b.y and a.z =~ b.z

func dist2[R](a, b: Vec3[R]): R {.inline.} =
  ## Returns distance squared between a and b.
  length2(a - b)

func vec3*[R](x, y, z: R): Vec3[R] {.inline.} = glm.vec3(x, y, z)
func normalize*(d: var Vec3) {.inline.} = d *= 1 / length(d)

func origin*[R](_: type[R]): Vec3[R] {.inline.} =
  ## Holds origin (0,0,0)
  vec3[R](0, 0, 0)

template points_on_sphere*(R): untyped =
  ## Array of points uniformly distributed on unit sphere
  [ vec3[R]( 0.000000, -0.000000, -1.000000),
    vec3[R]( 0.723608, -0.525725, -0.447219),
    vec3[R](-0.276388, -0.850649, -0.447219),
    vec3[R](-0.894426, -0.000000, -0.447216),
    vec3[R](-0.276388,  0.850649, -0.447220),
    vec3[R]( 0.723608,  0.525725, -0.447219),
    vec3[R]( 0.276388, -0.850649,  0.447220),
    vec3[R](-0.723608, -0.525725,  0.447219),
    vec3[R](-0.723608,  0.525725,  0.447219),
    vec3[R]( 0.276388,  0.850649,  0.447219),
    vec3[R]( 0.894426,  0.000000,  0.447216),
    vec3[R](-0.000000,  0.000000,  1.000000),
    vec3[R]( 0.425323, -0.309011, -0.850654),
    vec3[R](-0.162456, -0.499995, -0.850654),
    vec3[R]( 0.262869, -0.809012, -0.525738),
    vec3[R]( 0.425323,  0.309011, -0.850654),
    vec3[R]( 0.850648, -0.000000, -0.525736),
    vec3[R](-0.525730, -0.000000, -0.850652),
    vec3[R](-0.688190, -0.499997, -0.525736),
    vec3[R](-0.162456,  0.499995, -0.850654),
    vec3[R](-0.688190,  0.499997, -0.525736),
    vec3[R]( 0.262869,  0.809012, -0.525738),
    vec3[R]( 0.951058,  0.309013,  0.000000),
    vec3[R]( 0.951058, -0.309013,  0.000000),
    vec3[R]( 0.587786, -0.809017,  0.000000),
    vec3[R]( 0.000000, -1.000000,  0.000000),
    vec3[R](-0.587786, -0.809017,  0.000000),
    vec3[R](-0.951058, -0.309013, -0.000000),
    vec3[R](-0.951058,  0.309013, -0.000000),
    vec3[R](-0.587786,  0.809017, -0.000000),
    vec3[R](-0.000000,  1.000000, -0.000000),
    vec3[R]( 0.587786,  0.809017, -0.000000),
    vec3[R]( 0.688190, -0.499997,  0.525736),
    vec3[R](-0.262869, -0.809012,  0.525738),
    vec3[R](-0.850648,  0.000000,  0.525736),
    vec3[R](-0.262869,  0.809012,  0.525738),
    vec3[R]( 0.688190,  0.499997,  0.525736),
    vec3[R]( 0.525730,  0.000000,  0.850652),
    vec3[R]( 0.162456, -0.499995,  0.850654),
    vec3[R](-0.425323, -0.309011,  0.850654),
    vec3[R](-0.425323,  0.309011,  0.850654),
    vec3[R]( 0.162456,  0.499995,  0.850654) ]

proc vec3PointSegmentDist2*[R](P, x0, b: Vec3[R], witness: ptr Vec3[R]): R {.inline.} =
  ## Returns distance^2 of point P to segment ab.
  ## If witness is non-NULL it is filled with coordinates of point from which
  ## was computed distance to point P.
  # The computation comes from solving equation of segment:
  #      S(t) = x0 + t.d
  #          where - x0 is initial point of segment
  #                - d is direction of segment from x0 (|d| > 0)
  #                - t belongs to <0, 1> interval
  #
  # Than, distance from a segment to some point P can be expressed:
  #      D(t) = |x0 + t.d - P|^2
  #          which is distance from any point on segment. Minimization
  #          of this function brings distance from P to segment.
  # Minimization of D(t) leads to simple quadratic equation that's
  # solving is straightforward.
  #
  # Bonus of this method is witness point for free.

  # direction of segment
  let d = b - x0

  # precompute vector from P to x0
  let a = x0 - P

  let t = -dot(a, d) / length2(d)

  if t < 0 or isZero(t):
    result = dist2(x0, P)
    if witness != nil: witness[] = x0
  elif t > 1 or t =~ 1:
    result = dist2(b, P)
    if witness != nil: witness[] = b
  else:
    if witness != nil:
      witness[] = d * t + x0
      result = dist2(witness[], P)
    else:
      result = length2(d * t + a)

proc vec3PointTriangleDist2*[R](P, x0, B, C: Vec3[R], witness: ptr Vec3[R]): R =
  ## Returns distance^2 of point P from triangle formed by triplet a, b, c.
  ## If witness vector is provided it is filled with coordinates of point
  ## from which was computed distance to point P.
  # Computation comes from analytic expression for triangle (x0, B, C)
  #      T(s, t) = x0 + s.d1 + t.d2, where d1 = B - x0 and d2 = C - x0 and
  # Then equation for distance is:
  #      D(s, t) = | T(s, t) - P |^2
  # This leads to minimization of quadratic function of two variables.
  # The solution from is taken only if s is between 0 and 1, t is
  # between 0 and 1 and t + s < 1, otherwise distance from segment is
  # computed.
  var d1 = B - x0
  var d2 = C - x0
  let a = x0 - P

  let u = dot(a, a)
  let v = dot(d1, d1)
  let w = dot(d2, d2)
  let p = dot(a, d1)
  let q = dot(a, d2)
  let r = dot(d1, d2)

  let d = w * v - r * r

  var s, t: R
  if isZero(d):
    # To avoid division by zero for zero (or near zero) area triangles
    t = -1
    s = -1
  else:
    s = (q * r - w * p) / d
    t = (-s * r - q) / w

  if (isZero(s) or s > 0) and
     (s =~ 1 or s < 1) and
     (isZero(t) or t > 0) and
     (t =~ 1 or t < 1) and
     (t + s =~ 1 or t + s < 1):

    if witness != nil:
      d1 *= s
      d2 *= t
      witness[] = x0 + d1 + d2

      result = dist2(witness[], P)
    else:
      result = s * s * v +
               t * t * w +
               2 * s * t * r +
               2 * s * p +
               2 * t * q +
               u
  else:
    result = vec3PointSegmentDist2(P, x0, B, witness)

    var witness2: Vec3[R]
    if (let dist2 = vec3PointSegmentDist2(P, x0, C, addr witness2); dist2) < result:
      result = dist2
      if witness != nil: witness[] = witness2

    if (let dist2 = vec3PointSegmentDist2(P, B, C, addr witness2); dist2) < result:
      result = dist2
      if witness != nil: witness[] = witness2

type
  SupportFn[T, R] = proc (obj: T, dir: Vec3[R], vec: var Vec3[R])
    ## Type of *support* function that takes pointer to 3D object and direction and
    ## returns (via vec argument) furthest point from object in specified direction.

  FirstDirFn[T, R] = proc (obj1, obj2: T, dir: var Vec3[R])
    ## Returns (via dir argument) first direction vector that will be used in
    ## initialization of algorithm.

  CenterFn[T, R] = proc (obj1: T, center: var Vec3[R])
    ## Returns (via center argument) geometric center (some point near center)
    ## of given object.

  CCDObj*[T, R] = object
    ## Main structure of CCD algorithm.
    first_dir*: FirstDirFn[T, R]
      # Returns initial direction where first support point will be searched
    support1*, support2*: SupportFn[T, R]
      # Functions that returns support point of (first object, second object)
    center1*, center2*: CenterFn[T, R]
      # Functions that returns geometric center of (first object, second object)
    max_iterations*: uint64
      # Maximal number of iterations
    epa_tolerance*, mpr_tolerance*: R
      # Boundary tolerance for (GJK+EPA, MPR) algorithms

  SupportPoints*[R] = object
    v*, v1*, v2*: Vec3[R] ## Support points in (minkowski sum, obj1, obj2)

  Simplex*[R] = object
    ps: array[4, SupportPoints[R]]
    lastIdx: int ## index of last added point

proc computeSupportPoints*[T, R](obj1, obj2: T, dir: Vec3[R], ccd: CCDObj[T, R], supp: var SupportPoints[R]) =
  ## Computes support point of obj1 and obj2 in direction dir. Support point is returned via supp.
  ccd.support1(obj1, dir, supp.v1)
  ccd.support2(obj2, -dir, supp.v2)
  supp.v = supp.v1 - supp.v2

proc initSimplex*[R]: Simplex[R] {.inline.} = Simplex[R](lastIdx: -1)

proc size*(s: Simplex): int {.inline.} = s.lastIdx + 1
proc `size=`*(s: var Simplex, size: int) {.inline.} = s.lastIdx = size - 1

proc `[]`*[R](s: var Simplex[R], idx: int): var SupportPoints[R] {.inline.} = s.ps[idx]
proc `[]=`*(s: var Simplex, pos: csize_t, a: SupportPoints) {.inline.} = s.ps[pos] = a

proc last*[R](s: var Simplex[R]): var SupportPoints[R] {.inline.} = s[s.lastIdx]

proc add*(s: var Simplex, v: SupportPoints) {.inline.} = inc s.lastIdx; s.ps[s.lastIdx] = v

import list, polytope

func initCCD*[T, R](): CCDObj[T, R] =
  CCDObj[T, R](first_dir: proc (o1, o2: T, dir: var Vec3[R]) {.nimcall.} = dir = vec3(R(1), 0, 0),
              support1: nil, support2: nil, center1: nil, center2: nil,
              max_iterations: uint64.high,
              epa_tolerance: 0.0001, mpr_tolerance: 0.0001)

proc penEPAPos[R](pt: Polytope[R], nearest: ptr PolytopeElement[R], pos: var Vec3[R]) =
  # compute median
  var len: csize_t = 0
  forEachEntry(unsafeAddr pt.vertices, v, PolytopeVertex[R], list):
    inc len

  template ccdAllocArr(typ, num_elements): untyped = cast[ptr typ](c_malloc(sizeof(typ).csize_t * num_elements))

  let vs = cast[ptr UncheckedArray[ptr PolytopeVertex[R]]](ccdAllocArr(ptr PolytopeVertex[R], len))
  if vs == nil: quit "Memory alloc failure"

  var i: csize_t = 0
  forEachEntry(unsafeAddr pt.vertices, v, PolytopeVertex[R], list):
    vs[i] = v
    inc i

  proc qsort(base: pointer, nitems: csize_t, size: csize_t, compar: proc (a, b: pointer): int {.cdecl.}) {.nodecl, importc: "qsort".}

  proc penEPAPosCmp(a, b: pointer): int {.cdecl.} =
    let v1 = cast[ptr ptr PolytopeVertex[R]](a)[]
    let v2 = cast[ptr ptr PolytopeVertex[R]](b)[]
    if v1[].dist =~ v2[].dist: 0
    elif v1[].dist < v2[].dist: -1
    else: 1

  qsort(vs, len, sizeof(ptr PolytopeVertex).csize_t, penEPAPosCmp)

  pos = vec3[R](0, 0, 0)
  var scale: R = 0
  if len mod 2 == 1: inc len

  for i in 0..<len div 2:
    pos += vs[i][].v.v1
    pos += vs[i][].v.v2
    scale += 2'f64

  pos *= 1 / scale

  c_free(vs)

func tripleCross(a, b, c: Vec3): Vec3 {.inline.} = cross(cross(a, b), c) # a x b x c

type DoSimplexResult = enum Continue, Intersect, NoIntersect

func doSimplex2[R](simplex: var Simplex[R], dir: var Vec3[R]): DoSimplexResult =
  let A = simplex.last # get last added as A
  let B = simplex[0] # get the other point
  let AB = B.v - A.v # compute AB oriented segment
  let AO = -A.v # compute AO vector

  let dot = dot(AB, AO) # dot product AB . AO

  # check if origin doesn't lie on AB segment
  if isZero(length2(cross(AB, AO))) and dot > 0: return Intersect

  if isZero(dot) or dot < 0: # check if origin is in area where AB segment is
    # origin is in outside are of A
    simplex[0] = A
    simplex.size = 1
    dir = AO
  else: # origin is in area where AB segment is

    # keep simplex untouched and set direction to
    # AB x AO x AB
    dir = tripleCross(AB, AO, AB)

  return Continue

func doSimplex3[R](simplex: var Simplex[R], dir: var Vec3[R]): DoSimplexResult =
  # get last added as A
  let A = simplex.last
  # get the other points
  let B = simplex[1]
  let C = simplex[0]

  # check touching contact
  if isZero(vec3PointTriangleDist2(origin(R), A.v, B.v, C.v, nil)): return Intersect

  # check if triangle is really triangle (has area > 0)
  # if not simplex can't be expanded and thus no itersection is found
  if A.v =~ B.v or A.v =~ C.v: return NoIntersect

  # compute AO vector
  let AO = -A.v

  # compute AB and AC segments and ABC vector (perpendircular to triangle)
  let AB = B.v - A.v
  let AC = C.v - A.v
  let ABC = cross(AB, AC)

  var dott = dot(cross(ABC, AC), AO)

  template ccd_do_simplex3_45 =
    dott = dot(AB, AO)
    if isZero(dott) or dott > 0:
      simplex[0] = B
      simplex[1] = A
      simplex.size = 2
      dir = tripleCross(AB, AO, AB)
    else:
      simplex[0] = A
      simplex.size = 1
      dir = AO

  if isZero(dott) or dott > 0:
    dott = dot(AC, AO)
    if isZero(dott) or dott > 0:
      # C is already in place
      simplex[1] = A
      simplex.size = 2
      dir = tripleCross(AC, AO, AC)
    else:
      ccd_do_simplex3_45
  else:
    dott = dot(cross(AB, ABC), AO)
    if isZero(dott) or dott > 0:
      ccd_do_simplex3_45
    else:
      dott = dot(ABC, AO)
      if isZero(dott) or dott > 0:
        dir = ABC
      else:
        simplex[0] = B
        simplex[1] = C

        dir = -ABC

  return Continue

func doSimplex4[R](simplex: var Simplex[R], dir: var Vec3[R]): DoSimplexResult =
  # get last added as A
  let A = simplex.last
  # get the other points
  let B = simplex[2]
  let C = simplex[1]
  let D = simplex[0]

  # check if tetrahedron is really tetrahedron (has volume > 0) if it is
  # not simplex can't be expanded and thus no intersection is found
  if isZero(vec3PointTriangleDist2(A.v, B.v, C.v, D.v, nil)): return NoIntersect

  # check if origin lies on some of tetrahedron's face - if so objects intersect
  if isZero(vec3PointTriangleDist2(origin(R), A.v, B.v, C.v, nil)) or
     isZero(vec3PointTriangleDist2(origin(R), A.v, C.v, D.v, nil)) or
     isZero(vec3PointTriangleDist2(origin(R), A.v, B.v, D.v, nil)) or
     isZero(vec3PointTriangleDist2(origin(R), B.v, C.v, D.v, nil)): return Intersect

  # compute AO, AB, AC, AD segments and ABC, ACD, ADB normal vectors
  let AO = -A.v
  let AB = B.v - A.v
  let AC = C.v - A.v
  let AD = D.v - A.v
  let ABC = cross(AB, AC)
  let ACD = cross(AC, AD)
  let ADB = cross(AD, AB)

  # side (positive or negative) of B, C, D relative to planes ACD, ADB and ABC respectively
  let B_on_ACD = sign(dot(ACD, AB))
  let C_on_ADB = sign(dot(ADB, AC))
  let D_on_ABC = sign(dot(ABC, AD))

  # whether origin is on same side of ACD, ADB, ABC as B, C, D respectively
  let AB_O = sign(dot(ACD, AO)) == B_on_ACD
  let AC_O = sign(dot(ADB, AO)) == C_on_ADB
  let AD_O = sign(dot(ABC, AO)) == D_on_ABC

  if AB_O and AC_O and AD_O:
    # origin is in tetrahedron
    return Intersect
  # rearrange simplex to triangle and call doSimplex3()
  elif not AB_O:
    # B is farthest from the origin among all of the tetrahedron's points,
    # so remove it from the list and go on with the triangle case

    # D and C are in place
    simplex[2] = A
    simplex.size = 3
  elif not AC_O:
    # C is farthest
    simplex[1] = D
    simplex[0] = B
    simplex[2] = A
    simplex.size = 3
  else: # not AD_O
    simplex[0] = C
    simplex[1] = B
    simplex[2] = A
    simplex.size = 3

  return doSimplex3(simplex, dir)

func doSimplex[R](simplex: var Simplex[R], dir: var Vec3[R]): DoSimplexResult =
  ## Returns true if simplex contains origin.
  ## This function also alteres simplex and dir according to further processing of GJK algorithm.
  case simplex.size
  of 2: doSimplex2(simplex, dir) # simplex contains segment only one segment
  of 3: doSimplex3(simplex, dir) # simplex contains triangle
  else: #[4]#
    # tetrahedron - this is the only shape which can encapsule origin so doSimplex4() also contains test on it
    doSimplex4(simplex, dir)

proc GJK[T, R](obj1, obj2: T, ccd: CCDObj[T, R], simplex: var Simplex[R]): bool =
  ## Performs GJK algorithm. Returns true if intersection was found and simplex
  ## is filled with resulting polytope.
  # initialize simplex struct
  simplex = initSimplex[R]()

  # get first direction
  var dir: Vec3[R]; # direction vector
  ccd.first_dir(obj1, obj2, dir)
  # get first support point
  var last: SupportPoints[R]; # last support point
  computeSupportPoints(obj1, obj2, dir, ccd, last)
  # and add this point to simplex as last one
  simplex.add last

  # set up direction vector to as (O - last) which is exactly -last
  dir = -last.v

  # start iterations
  for _ in 0..<ccd.max_iterations:
    # obtain support point
    computeSupportPoints(obj1, obj2, dir, ccd, last)

    # check if farthest point in Minkowski difference in direction dir
    # isn't somewhere before origin (the test on negative dot product)
    # - because if it is, objects are not intersecting at all.
    if dot(last.v, dir) < 0: return false # intersection not found

    # add last support vector to simplex
    simplex.add last

    # if doSimplex returns 1 if objects intersect, -1 if objects don't
    # intersect and 0 if algorithm should continue
    let do_simplex_res = doSimplex(simplex, dir)
    if do_simplex_res == Intersect: return true # intersection found
    elif do_simplex_res == NoIntersect: return false # intersection not found

    if isZero(length2(dir)): return false # intersection not found

  return false # intersection wasn't found

proc intersectGJK*[T, R](obj1, obj2: T, ccd: CCDObj[T, R]): bool =
  ## Returns true if two given objects interest.
  GJK(obj1, obj2, ccd, (var simplex: Simplex[R]; simplex)) == true

proc nextSupport[T, R](obj1, obj2: T, ccd: CCDObj[T, R], el: ptr PolytopeElement[R], next: var SupportPoints[R]): bool =
  ## Finds next support point (and stores it in `next`). Returns true on success, false otherwise
  if el[].typ == peVertex: return false

  # touch contact
  if isZero(el[].dist): return false

  computeSupportPoints(obj1, obj2, el[].witness, ccd, next)

  # Compute dist of support point along element witness point direction so we
  # can determine whether we expanded a polytope surrounding the origin a bit.
  var dist = dot(next.v, el[].witness)

  if dist - el[].dist < ccd.epa_tolerance: return false

  var a, b, c: ptr Vec3[R]
  if el[].typ == peEdge:
    # fetch end points of edge
    edgeVec3(cast[ptr PolytopeEdge[R]](el), a, b)

    # get distance from segment
    dist = vec3PointSegmentDist2(next.v, a[], b[], nil)
  else: # el->type == peFace
    # fetch vertices of triangle face
    faceVec3(cast[ptr PolytopeFace[R]](el), a, b, c)

    # check if new point can significantly expand polytope
    dist = vec3PointTriangleDist2(next.v, a[], b[], c[], nil)

  if dist < ccd.epa_tolerance: return false

  return true

proc expandPolytope[R](pt: var Polytope[R], el: ptr PolytopeElement[R], newv: SupportPoints[R]) =
  ## Expands polytope('s tri) by new vertex v. Triangle tri is replaced by three triangles each with one vertex in v.
  var v: array[5, ptr PolytopeVertex[R]]
  var e: array[8, ptr PolytopeEdge[R]]
  var f: array[2, ptr PolytopeFace[R]]

  # element can be either segment or triangle
  if el[].typ == peEdge:
    # In this case, segment should be replaced by new point.
    # Simpliest case is when segment stands alone and in this case
    # this segment is replaced by two other segments both connected to
    # newv.
    # Segment can be also connected to max two faces and in that case
    # each face must be replaced by two other faces. To do this
    # correctly it is necessary to have correctly ordered edges and
    # vertices which is exactly what is done in following code.
    #

    edgeVertices(cast[ptr PolytopeEdge[R]](el), v[0], v[2])

    edgeFaces(cast[ptr PolytopeEdge[R]](el), f[0], f[1])

    if f[0] != nil:
      faceEdges(f[0], e[0], e[1], e[2])
      if e[0] == cast[ptr PolytopeEdge[R]](el):
        e[0] = e[2]
      elif e[1] == cast[ptr PolytopeEdge[R]](el):
        e[1] = e[2]

      edgeVertices(e[0], v[1], v[3])
      if v[1] != v[0] and v[3] != v[0]:
        e[2] = e[0]
        e[0] = e[1]
        e[1] = e[2]
        if v[1] == v[2]:
          v[1] = v[3]
      else:
        if v[1] == v[0]:
          v[1] = v[3]

      if f[1] != nil:
        faceEdges(f[1], e[2], e[3], e[4])
        if e[2] == cast[ptr PolytopeEdge[R]](el):
          e[2] = e[4]
        elif e[3] == cast[ptr PolytopeEdge[R]](el):
          e[3] = e[4]
        edgeVertices(e[2], v[3], v[4])
        if v[3] != v[2] and v[4] != v[2]:
          e[4] = e[2]
          e[2] = e[3]
          e[3] = e[4]
          if v[3] == v[0]:
            v[3] = v[4]
        else:
          if v[3] == v[2]:
            v[3] = v[4]


      v[4] = addVertex(pt, newv)

      deleteFace(pt, f[0])
      if f[1] != nil:
        deleteFace(pt, f[1])
        deleteEdge(pt, cast[ptr PolytopeEdge[R]](el))

      e[4] = addEdge(pt, v[4], v[2])
      e[5] = addEdge(pt, v[4], v[0])
      e[6] = addEdge(pt, v[4], v[1])
      if f[1] != nil:
        e[7] = addEdge(pt, v[4], v[3])


      if addFace(pt, e[1], e[4], e[6]) == nil or addFace(pt, e[0], e[6], e[5]) == nil:
        quit "Memory alloc failure"

      if f[1] != nil:
        if addFace(pt, e[3], e[5], e[7]) == nil or addFace(pt, e[4], e[7], e[2]) == nil:
          quit "Memory alloc failure"
      else:
        if addFace(pt, e[4], e[5], cast[ptr PolytopeEdge[R]](el)) == nil:
          quit "Memory alloc failure"
  else: # el->type == peFace
    # replace triangle by tetrahedron without base (base would be the
    # triangle that will be removed)

    # get triplet of surrounding edges and vertices of triangle face
    faceEdges(cast[ptr PolytopeFace[R]](el), e[0], e[1], e[2])
    edgeVertices(e[0], v[0], v[1])
    edgeVertices(e[1], v[2], v[3])

    # following code sorts edges to have e[0] between vertices 0-1,
    # e[1] between 1-2 and e[2] between 2-0
    if v[2] != v[1] and v[3] != v[1]:
      # swap e[1] and e[2]
      e[3] = e[1]
      e[1] = e[2]
      e[2] = e[3]
    if v[3] != v[0] and v[3] != v[1]:
      v[2] = v[3]

    # remove triangle face
    deleteFace(pt, cast[ptr PolytopeFace[R]](el))

    # expand triangle to tetrahedron
    v[3] = addVertex(pt, newv)
    e[3] = addEdge(pt, v[3], v[0])
    e[4] = addEdge(pt, v[3], v[1])
    e[5] = addEdge(pt, v[3], v[2])

    if addFace(pt, e[3], e[4], e[0]) == nil or
       addFace(pt, e[4], e[5], e[1]) == nil or
       addFace(pt, e[5], e[3], e[2]) == nil:
      quit "Memory alloc failure"

proc simplexToPolytope3[T, R](obj1, obj2: T, ccd: CCDObj[T, R], simplex: var Simplex[R], pt: var Polytope[R], nearest: var ptr PolytopeElement[R]): bool =
  ## Transforms simplex to polytope, three vertices required
  nearest = nil

  let a = simplex[0]
  let b = simplex[1]
  let c = simplex[2]

  # If only one triangle left from previous GJK run origin lies on this
  # triangle. So it is necessary to expand triangle into two
  # tetrahedrons connected with base (which is exactly abc triangle).

  # get next support point in direction of normal of triangle
  var d, d2: SupportPoints[R]
  let ab = b.v - a.v
  let ac = c.v - a.v
  let dir = cross(ab, ac)
  computeSupportPoints(obj1, obj2, dir, ccd, d)
  let dist = vec3PointTriangleDist2(d.v, a.v, b.v, c.v, nil)

  # and second one take in opposite direction
  computeSupportPoints(obj1, obj2, -dir, ccd, d2)
  let dist2 = vec3PointTriangleDist2(d2.v, a.v, b.v, c.v, nil)

  var v: array[5, ptr PolytopeVertex[R]]
  var e: array[9, ptr PolytopeEdge[R]]
  # check if face isn't already on edge of minkowski sum and thus we have touching contact
  if isZero(dist) or isZero(dist2):
    v[0] = addVertex(pt, a)
    v[1] = addVertex(pt, b)
    v[2] = addVertex(pt, c)
    e[0] = addEdge(pt, v[0], v[1])
    e[1] = addEdge(pt, v[1], v[2])
    e[2] = addEdge(pt, v[2], v[0])
    nearest = cast[ptr PolytopeElement[R]](addFace(pt, e[0], e[1], e[2]))
    if nearest == nil: quit "Memory alloc failure"

    return false

  # form polyhedron
  v[0] = addVertex(pt, a)
  v[1] = addVertex(pt, b)
  v[2] = addVertex(pt, c)
  v[3] = addVertex(pt, d)
  v[4] = addVertex(pt, d2)

  e[0] = addEdge(pt, v[0], v[1])
  e[1] = addEdge(pt, v[1], v[2])
  e[2] = addEdge(pt, v[2], v[0])

  e[3] = addEdge(pt, v[3], v[0])
  e[4] = addEdge(pt, v[3], v[1])
  e[5] = addEdge(pt, v[3], v[2])

  e[6] = addEdge(pt, v[4], v[0])
  e[7] = addEdge(pt, v[4], v[1])
  e[8] = addEdge(pt, v[4], v[2])

  if addFace(pt, e[3], e[4], e[0]) == nil or
     addFace(pt, e[4], e[5], e[1]) == nil or
     addFace(pt, e[5], e[3], e[2]) == nil or
     addFace(pt, e[6], e[7], e[0]) == nil or
     addFace(pt, e[7], e[8], e[1]) == nil or
     addFace(pt, e[8], e[6], e[2]) == nil:
    quit "Memory alloc failure"

  return true

proc simplexToPolytope4[T, R](obj1, obj2: T, ccd: CCDObj[T, R], simplex: var Simplex[R], pt: var Polytope[R], nearest: var ptr PolytopeElement[R]): bool =
  ## Transforms simplex to polytope. It is assumed that simplex has 4 vertices!
  let a = simplex[0]
  let b = simplex[1]
  let c = simplex[2]
  let d = simplex[3]

  # check if origin lies on some of tetrahedron's face - if so use simplexToPolytope3()
  var use_polytope3 = false
  if isZero(vec3PointTriangleDist2(origin(R), a.v, b.v, c.v, nil)):
    use_polytope3 = true

  if isZero(vec3PointTriangleDist2(origin(R), a.v, c.v, d.v, nil)):
    use_polytope3 = true
    simplex[1] = c
    simplex[2] = d

  if isZero(vec3PointTriangleDist2(origin(R), a.v, b.v, d.v, nil)):
    use_polytope3 = true
    simplex[2] = d

  if isZero(vec3PointTriangleDist2(origin(R), b.v, c.v, d.v, nil)):
    use_polytope3 = true
    simplex[0] = b
    simplex[1] = c
    simplex[2] = d

  if use_polytope3:
    simplex.size = 3
    return simplexToPolytope3(obj1, obj2, ccd, simplex, pt, nearest)

  # no touching contact - simply create tetrahedron
  var v: array[4, ptr PolytopeVertex[R]]
  for i in 0..<4:
    v[i] = addVertex(pt, simplex[i])

  var e: array[6, ptr PolytopeEdge[R]]
  e[0] = addEdge(pt, v[0], v[1])
  e[1] = addEdge(pt, v[1], v[2])
  e[2] = addEdge(pt, v[2], v[0])
  e[3] = addEdge(pt, v[3], v[0])
  e[4] = addEdge(pt, v[3], v[1])
  e[5] = addEdge(pt, v[3], v[2])

  # ccdPtAdd*() functions return nil either if the memory allocation
  # failed of if any of the input pointers are nil, so the bad
  # allocation can be checked by the last calls of addFace()
  # because the rest of the bad allocations eventually "bubble up" here
  if addFace(pt, e[0], e[1], e[2]) == nil or
     addFace(pt, e[3], e[4], e[0]) == nil or
     addFace(pt, e[4], e[5], e[1]) == nil or
     addFace(pt, e[5], e[3], e[2]) == nil:
    quit "Memory alloc failure"

  return true

proc simplexToPolytope2[T, R](obj1, obj2: T, ccd: CCDObj[T, R], simplex: var Simplex[R], pt: var Polytope[R], nearest: var ptr PolytopeElement[R]): bool =
  ## Transforms simplex to polytope, two vertices required
  let a = simplex[0]
  let b = simplex[1]

  # This situation is a bit tricky. If only one segment comes from
  # previous run of GJK - it means that either this segment is on
  # minkowski edge (and thus we have touch contact) or it it isn't and
  # therefore segment is somewhere *inside* minkowski sum and it *must*
  # be possible to fully enclose this segment with polyhedron formed by
  # at least 8 triangle faces.

  # get first support point (any)
  var found = false
  var supp: array[4, SupportPoints[R]]
  for point in points_on_sphere(type(ccd).R):
    computeSupportPoints(obj1, obj2, point, ccd, supp[0])
    if not (a.v =~ supp[0].v) and not (b.v =~ supp[0].v):
      found = true; break

  var v: array[6, ptr PolytopeVertex[R]]
  var e: array[12, ptr PolytopeEdge[R]]
  block simplexToPolytope2_not_touching_contact:
    block simplexToPolytope2_touching_contact:
      if not found: break simplexToPolytope2_touching_contact

      # get second support point in opposite direction than supp[0]
      computeSupportPoints(obj1, obj2, -supp[0].v, ccd, supp[1])
      if a.v =~ supp[1].v or b.v =~ supp[1].v: break simplexToPolytope2_touching_contact

      # next will be in direction of normal of triangle a,supp[0],supp[1]
      let dir = cross(supp[0].v - a.v, supp[1].v - a.v)
      computeSupportPoints(obj1, obj2, dir, ccd, supp[2])
      if a.v =~ supp[2].v or b.v =~ supp[2].v: break simplexToPolytope2_touching_contact

      # and last one will be in opposite direction
      computeSupportPoints(obj1, obj2, -dir, ccd, supp[3])
      if a.v =~ supp[3].v or b.v =~ supp[3].v: break simplexToPolytope2_touching_contact

      break simplexToPolytope2_not_touching_contact
    v[0] = addVertex(pt, a)
    v[1] = addVertex(pt, b)
    nearest = cast[ptr PolytopeElement[R]](addEdge(pt, v[0], v[1]))
    if nearest == nil: quit "Memory alloc failure"

    return false

  # form polyhedron
  v[0] = addVertex(pt, a)
  v[1] = addVertex(pt, supp[0])
  v[2] = addVertex(pt, b)
  v[3] = addVertex(pt, supp[1])
  v[4] = addVertex(pt, supp[2])
  v[5] = addVertex(pt, supp[3])

  e[0] = addEdge(pt, v[0], v[1])
  e[1] = addEdge(pt, v[1], v[2])
  e[2] = addEdge(pt, v[2], v[3])
  e[3] = addEdge(pt, v[3], v[0])

  e[4] = addEdge(pt, v[4], v[0])
  e[5] = addEdge(pt, v[4], v[1])
  e[6] = addEdge(pt, v[4], v[2])
  e[7] = addEdge(pt, v[4], v[3])

  e[8]  = addEdge(pt, v[5], v[0])
  e[9]  = addEdge(pt, v[5], v[1])
  e[10] = addEdge(pt, v[5], v[2])
  e[11] = addEdge(pt, v[5], v[3])

  if addFace(pt, e[4], e[5], e[0]) == nil or
     addFace(pt, e[5], e[6], e[1]) == nil or
     addFace(pt, e[6], e[7], e[2]) == nil or
     addFace(pt, e[7], e[4], e[3]) == nil or
     addFace(pt, e[8], e[9], e[0]) == nil or
     addFace(pt, e[9], e[10],e[1]) == nil or
     addFace(pt, e[10],e[11],e[2]) == nil or
     addFace(pt, e[11],e[8], e[3]) == nil:
    quit "Memory alloc failure"

  return true

proc GJKEPA[T, R](obj1, obj2: T, ccd: CCDObj[T, R], polytope: var Polytope[R], nearest: var ptr PolytopeElement[R]): bool =
  ## Performs GJK+EPA algorithm. Returns 0 if intersection was found and
  ## pt is filled with resulting polytope and nearest with pointer to
  ## nearest element (vertex, edge, face) of polytope to origin.
  nearest = nil

  # run GJK and obtain terminal simplex
  var simplex: Simplex[R]
  if not GJK(obj1, obj2, ccd, simplex): return false

  # transform simplex to polytope - simplex won't be used anymore
  let ret = case simplex.size
            of 4: simplexToPolytope4(obj1, obj2, ccd, simplex, polytope, nearest)
            of 3: simplexToPolytope3(obj1, obj2, ccd, simplex, polytope, nearest)
            else: #[2]# simplexToPolytope2(obj1, obj2, ccd, simplex, polytope, nearest)

  if ret == false: return true # touching contact

  while true:
    # get triangle nearest to origin
    nearest = nearestToOrigin(polytope)

    # get next support point
    var supp: SupportPoints[R]; # support point
    if not nextSupport(obj1, obj2, ccd, nearest, supp): break

    # expand nearest triangle using new point - supp
    expandPolytope(polytope, nearest, supp)

  return true

proc penetrationGJK*[T, R](obj1, obj2: T, ccd: CCDObj[T, R], depth: var R, dir, pos: var Vec3[R]): bool =
  ## Computes penetration of obj2 into obj1.
  ## Depth of penetration, direction and position is returned. It means that
  ## if obj2 is translated by distance depth in direction dir objects will
  ## have touching contact, pos should be position in global coordinates
  ## where force should take a place.

  ## CCD+EPA algorithm is used.

  ## Returns true if obj1 and obj2 intersect and depth, dir and pos are filled
  ## if given non-NULL pointers.
  ## If obj1 and obj2 don't intersect false is returned.
  var polytope: Polytope[R]
  initPolytope(polytope)

  var nearest: ptr PolytopeElement[R]
  result = GJKEPA(obj1, obj2, ccd, polytope, nearest)

  # set separation vector
  if result and nearest != nil:
    # compute depth of penetration
    depth = sqrt(nearest[].dist)

    # store normalized direction vector
    dir = nearest[].witness
    normalize(dir)

    # compute position
    penEPAPos(polytope, nearest, pos)

  destroyPolytope(polytope)

proc separateGJK*[T, R](obj1, obj2: T, ccd: CCDObj[T, R], sep: var Vec3[R]): bool =
  ## This function computes separation vector of two objects. Separation
  ## vector is minimal translation of obj2 to get obj1 and obj2 speparated
  ## (without intersection).
  ## Returns true if obj1 and obj2 intersect and sep is filled with translation
  ## vector. If obj1 and obj2 don't intersect false is returned.
  var polytope: Polytope[R]
  initPolytope(polytope)

  var nearest: ptr PolytopeElement[R]
  result = GJKEPA(obj1, obj2, ccd, polytope, nearest)

  # set separation vector
  if nearest != nil: sep = nearest[].witness

  destroyPolytope(polytope)

