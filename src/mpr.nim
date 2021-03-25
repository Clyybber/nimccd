#[
  libccd
  ---------------------------------
  Copyright (c)2010,2011 Daniel Fiser <danfis@danfis.cz>


   This file is part of libccd.

   Distributed under the OSI-approved BSD License (the "License")
   see accompanying file BDS-LICENSE for details or see
   <http://www.opensource.org/licenses/bsd-license.php>.

   This software is distributed WITHOUT ANY WARRANTY; without even the
   implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
   See the License for more information.
]#

import ccd
from math import sqrt

proc findOrigin[T, R](obj1, obj2: T, ccd: CCDObj[T, R], center: var SupportPoints[R]) {.inline.} =
  ## Finds origin (center) of Minkowski difference (actually it can be any interior point of Minkowski difference)
  ccd.center1(obj1, center.v1)
  ccd.center2(obj2, center.v2)
  center.v = center.v1 - center.v2

type DiscoverPortalResult = enum OriginOutsidePortal, BuiltPortal, OriginOnV1, OriginOnV0V1

proc discoverPortal[T, R](obj1, obj2: T, ccd: CCDObj[T, R], portal: var Simplex[R]): DiscoverPortalResult =
  ## Discovers initial portal - that is tetrahedron that intersects with
  ## origin ray (ray from center of Minkowski diff to (0,0,0).

  ## Returns OriginOutsidePortal if already recognized that origin is outside Minkowski portal.
  ## Returns OriginOnV1 if origin lies on v1 of simplex (only v0 and v1 are present in simplex).
  ## Returns OriginOnV0V1 if origin lies on v0-v1 segment.
  ## Returns BuiltPortal if portal was built.
  # vertex 0 is center of portal
  findOrigin(obj1, obj2, ccd, portal[0])
  portal.size = 1

  if portal[0].v =~ origin(R):
    # Portal's center lies on origin (0,0,0) => we know that objects intersect
    # but we would need to know penetration info. So move center little bit...
    portal[0].v += vec3[R](ccdEps(R) * 10'f64, 0, 0)


  # vertex 1 = supportVec in direction of origin
  var dir = portal[0].v * -1
  normalize(dir)
  computeSupportPoints(obj1, obj2, dir, ccd, portal[1])
  portal.size = 2

  # test if origin isn't outside of v1
  var dot = dot(portal[1].v, dir)
  if isZero(dot) or dot < 0: return OriginOutsidePortal


  # vertex 2
  dir = cross(portal[0].v, portal[1].v)
  if isZero(length2(dir)):
    return if portal[1].v =~ origin(R): OriginOnV1 # origin lies on v1
           else: OriginOnV0V1 # origin lies on v0-v1 segment

  normalize(dir)
  computeSupportPoints(obj1, obj2, dir, ccd, portal[2])
  dot = dot(portal[2].v, dir)
  if isZero(dot) or dot < 0: return OriginOutsidePortal

  portal.size = 3

  # vertex 3 direction
  dir = cross(portal[1].v - portal[0].v, portal[2].v - portal[0].v)
  normalize(dir)

  # it is better to form portal faces to be oriented "outside" origin
  if dot(dir, portal[0].v) > 0:
    let tmp = portal[1]
    portal[1] = portal[2]
    portal[2] = tmp
    dir *= -1

  while portal.size < 4:
    computeSupportPoints(obj1, obj2, dir, ccd, portal[3])
    dot = dot(portal[3].v, dir)
    if isZero(dot) or dot < 0: return OriginOutsidePortal

    var cont = false

    # test if origin is outside (v1, v0, v3) - set v2 as v3 and continue
    dot = dot(cross(portal[1].v, portal[3].v), portal[0].v)
    if dot < 0 and not isZero(dot):
      portal[2] = portal[3]
      cont = true

    if not cont:
      # test if origin is outside (v3, v0, v2) - set v1 as v3 and continue
      dot = dot(cross(portal[3].v, portal[2].v), portal[0].v)
      if dot < 0 and not isZero(dot):
          portal[1] = portal[3]
          cont = true

    if cont:
      dir = cross(portal[1].v - portal[0].v, portal[2].v - portal[0].v)
      normalize(dir)
    else:
      portal.size = 4

  return BuiltPortal

proc expandPortal(portal: var Simplex, v4: SupportPoints) {.inline.} =
  ## Extends portal with new support point. Portal must have face v1-v2-v3 arranged to face outside portal.
  let v4v0 = cross(v4.v, portal[0].v)
  if dot(portal[1].v, v4v0) > 0:
    if dot(portal[2].v, v4v0) > 0:
      portal[1] = v4
    else:
      portal[3] = v4
  else:
    if dot(portal[3].v, v4v0) > 0:
      portal[2] = v4
    else:
      portal[1] = v4

proc portalDir[R](portal: var Simplex[R]): Vec3[R] {.inline.} =
  ## Return dir with direction outside portal. Portal's v1-v2-v3 face must be arranged in correct order!
  result = cross(portal[2].v - portal[1].v, portal[3].v - portal[1].v)
  normalize(result)

proc portalEncapsulesOrigin(portal: var Simplex, dir: Vec3): bool {.inline.} =
  ## Returns true if portal encapsules origin (0,0,0), dir is direction of v1-v2-v3 face.
  let dot = dot(dir, portal[1].v)
  return isZero(dot) or dot > 0

proc portalReachTolerance(portal: var Simplex, v4: SupportPoints, dir: Vec3, ccd: CCDObj): bool {.inline.} =
  ## Returns true if portal with new point v4 would reach specified
  ## tolerance (i.e. returns true if portal can _not_ significantly expand
  ## within Minkowski difference).

  ## v4 is candidate for new point in portal, dir is direction in which v4
  ## was obtained.
  # find the smallest dot product of dir and {v1-v4, v2-v4, v3-v4}

  let dv1 = dot(portal[1].v, dir)
  let dv2 = dot(portal[2].v, dir)
  let dv3 = dot(portal[3].v, dir)
  let dv4 = dot(v4.v, dir)

  var dot1 = dv4 - dv1
  let dot2 = dv4 - dv2
  let dot3 = dv4 - dv3

  dot1 = min(min(dot1, dot2), dot3)

  return dot1 =~ ccd.mpr_tolerance or dot1 < ccd.mpr_tolerance

proc portalCanEncapsuleOrigin(portal: var Simplex, v4: SupportPoints, dir: Vec3): bool {.inline.} =
  ## Returns true if portal expanded by new point v4 could possibly contain origin, dir is direction in which v4 was obtained.
  let dot = dot(v4.v, dir)
  return isZero(dot) or dot > 0

proc refinePortal[T, R](obj1, obj2: T, ccd: CCDObj[T, R], portal: var Simplex[R]): bool =
  ## Expands portal towards origin and determine if objects intersect.
  ## Already established portal must be given as argument.
  ## If intersection is found true is returned, false otherwise
  while true:
    # compute direction outside the portal (from v0 throught v1,v2,v3 face)
    let dir = portalDir(portal)

    # test if origin is inside the portal
    if portalEncapsulesOrigin(portal, dir): return true

    # get next support point
    var v4: SupportPoints[R]
    computeSupportPoints(obj1, obj2, dir, ccd, v4)

    # test if v4 can expand portal to contain origin and if portal
    # expanding doesn't reach given tolerance
    if not portalCanEncapsuleOrigin(portal, v4, dir) or portalReachTolerance(portal, v4, dir, ccd): return false

    # v1-v2-v3 triangle must be rearranged to face outside Minkowski
    # difference (direction from v0).
    expandPortal(portal, v4)

  return false

proc findPos[T, R](obj1, obj2: T, ccd: CCDObj[T, R], portal: var Simplex[R], pos: var Vec3[R]) =
  ## Finds position vector from fully established portal
  let dir = portalDir(portal)

  var b: array[4, R]
  # use barycentric coordinates of tetrahedron to find origin
  b[0] = dot(cross(portal[1].v, portal[2].v), portal[3].v)

  b[1] = dot(cross(portal[3].v, portal[2].v), portal[0].v)

  b[2] = dot(cross(portal[0].v, portal[1].v), portal[3].v)

  b[3] = dot(cross(portal[2].v, portal[1].v), portal[0].v)

  var sum = b[0] + b[1] + b[2] + b[3]

  if isZero(sum) or sum < 0:
    b[0] = 0'f64

    b[1] = dot(cross(portal[2].v, portal[3].v), dir)
    b[2] = dot(cross(portal[3].v, portal[1].v), dir)
    b[3] = dot(cross(portal[1].v, portal[2].v), dir)

    sum = b[1] + b[2] + b[3]

  let inv = 1'f64 / sum

  var p1 = origin(R)
  var p2 = origin(R)
  for i in 0..<4:
    p1 += portal[i].v1 * b[i]
    p2 += portal[i].v2 * b[i]

  p1 *= inv
  p2 *= inv

  pos = (p1 + p2) * 0.5

proc findPenetr[T, R](obj1, obj2: T, ccd: CCDObj[T, R], portal: var Simplex[R], depth: var R, pdir, pos: var Vec3[R]) =
  ## Finds penetration info by expanding provided portal.
  var iterations = 0'u64
  while true:
    # compute portal direction and obtain next support point
    let dir = portalDir(portal)
    var v4: SupportPoints[R]
    computeSupportPoints(obj1, obj2, dir, ccd, v4)

    # reached tolerance []. find penetration info
    if portalReachTolerance(portal, v4, dir, ccd) or iterations > ccd.max_iterations:
      depth = sqrt(vec3PointTriangleDist2(origin(R), portal[1].v, portal[2].v, portal[3].v, addr pdir))
      if isZero(depth):
        # If depth is zero, then we have a touching contact.
        # So following findPenetrTouch(), we assign zero to
        # the direction vector (it can actually be anything
        # according to the decription of penetrationMPR
        # function).
        pdir = origin(R)
      else:
        normalize(pdir)

      # barycentric coordinates:
      findPos(obj1, obj2, ccd, portal, pos)

      return

    expandPortal(portal, v4)

    inc iterations

proc findPenetrTouch[T, R](obj1, obj2: T, ccd: CCDObj[T, R], portal: var Simplex[R], depth: var R, dir, pos: var Vec3[R]) =
  ## Finds penetration info if origin lies on portal's v1
  # Touching contact on portal's v1 - so depth is zero and direction is unimportant and pos can be guessed
  depth = 0
  dir = origin(R)
  pos = (portal[1].v1 + portal[1].v2) * 0.5

proc findPenetrSegment[T, R](obj1, obj2: T, ccd: CCDObj[T, R], portal: var Simplex[R], depth: var R, dir, pos: var Vec3[R]) =
  ## Find penetration info if origin lies on portal's segment v0-v1
  # Origin lies on v0-v1 segment.
  # Depth is distance to v1, direction also and position must be computed

  pos = (portal[1].v1 + portal[1].v2) * 0.5

  #[
  var vec = portal[1].v - portal[0].v
  let k = length(portal[0].v) / length(vec)
  vec *= -k
  pos += vec
  ]#

  dir = portal[1].v
  depth = length(dir)
  normalize(dir)

proc intersectMPR*[T, R](obj1, obj2: T, ccd: CCDObj[T, R]): bool =
  ## Returns true if two given objects intersect - MPR algorithm is used.
  # Phase 1: Portal discovery - find portal that intersects with origin
  # ray (ray from center of Minkowski diff to origin of coordinates)
  case discoverPortal(obj1, obj2, ccd, (var portal: Simplex[R]; portal))
  of OriginOutsidePortal: false
  of OriginOnV1, OriginOnV0V1: true
  else: refinePortal(obj1, obj2, ccd, portal) # Phase 2

proc penetrationMPR*[T, R](obj1, obj2: T, ccd: CCDObj[T, R], depth: var R, dir, pos: var Vec3[R]): bool =
  ## Computes penetration of obj2 into obj1.
  ## Depth of penetration, direction and position is returned, i.e. if obj2
  ## is translated by computed depth in resulting direction obj1 and obj2
  ## would have touching contact. Position is point in global coordinates
  ## where force should take a place.

  ## Minkowski Portal Refinement algorithm is used (MPR, a.k.a. XenoCollide,
  ## see Game Programming Gem 7).

  ## Returns true if obj1 and obj2 intersect, otherwise false is returned.
  # Phase 1: Portal discovery
  case discoverPortal(obj1, obj2, ccd, (var portal: Simplex[R]; portal))
  of OriginOutsidePortal: return false
  of OriginOnV1: findPenetrTouch(obj1, obj2, ccd, portal, depth, dir, pos)
  of OriginOnV0V1: findPenetrSegment(obj1, obj2, ccd, portal, depth, dir, pos)
  of BuiltPortal:
    # Phase 2: Portal refinement
    if not refinePortal(obj1, obj2, ccd, portal): return false

    # Phase 3. Penetration info
    findPenetr(obj1, obj2, ccd, portal, depth, dir, pos)

  return true

