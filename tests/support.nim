#[
 * libccd
 * ---------------------------------
 * Copyright (c)2010 Daniel Fiser <danfis@danfis.cz>
 *
 *
 *  This file is part of libccd.
 *
 *  Distributed under the OSI-approved BSD License (the "License")
 *  see accompanying file BDS-LICENSE for details or see
 *  <http://www.opensource.org/licenses/bsd-license.php>.
 *
 *  This software is distributed WITHOUT ANY WARRANTY; without even the
 *  implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *  See the License for more information.
]#

import ../src/ccd
from math import sqrt

proc normalize[R](q: var Quat[R]) {.inline.} =
  let len = length(q)
  if len < ccdEps(R): return
  q = q * (1 / len)

proc setAngleAxis*[R](q: var Quat[R], angle: R, axis: Vec3[R]) {.inline.} =
  let a = angle/2
  let x = axis.x
  let y = axis.y
  let z = axis.z
  let n = sqrt(x*x + y*y + z*z)

  # axis==0? (treat this the same as angle==0 with an arbitrary axis)
  if n < ccdEps(R):
    q.z = 0
    q.y = 0
    q.x = 0
    q.w = 1
  else:
    let s = sin(a)/n

    q.w = cos(a)
    q.x = x*s
    q.y = y*s
    q.z = z*s

    normalize(q)

proc `*`(a, b: Quat): Quat {.inline.} =
  result.x = a.w * b.x +
             a.x * b.w +
             a.y * b.z -
             a.z * b.y
  result.y = a.w * b.y +
             a.y * b.w -
             a.x * b.z +
             a.z * b.x
  result.z = a.w * b.z +
             a.z * b.w +
             a.x * b.y -
             a.y * b.x
  result.w = a.w * b.w -
             a.x * b.x -
             a.y * b.y -
             a.z * b.z

proc rotateByQuat*(v: var Vec3, q: Quat) {.inline.} =
  ## Rotate vector v by quaternion q.
  # original version: 31 mul + 21 add
  # optimized version: 18 mul + 12 add
  # formula: v = v + 2 * cross(q.xyz, cross(q.xyz, v) + q.w * v)
  let vx = v.x
  let vy = v.y
  let vz = v.z

  let w = q.w
  let x = q.x
  let y = q.y
  let z = q.z

  let cross1_x = y * vz - z * vy + w * vx
  let cross1_y = z * vx - x * vz + w * vy
  let cross1_z = x * vy - y * vx + w * vz
  let cross2_x = y * cross1_z - z * cross1_y
  let cross2_y = z * cross1_x - x * cross1_z
  let cross2_z = x * cross1_y - y * cross1_x
  v = vec3(vx + 2 * cross2_x, vy + 2 * cross2_y, vz + 2 * cross2_z)

type
  CollisionObjKind* = enum
    Box
    Sphere
    Cylinder

  CollisionObj*[R] = object
    pos*: Vec3[R]
    quat*: Quat[R]
    radius*: R # TODO: Move into sphere, cyl case once shared case fields are possible
    case typ*: CollisionObjKind
    of Box:
      x*, y*, z*: R ## Lengths of box's edges
    of Sphere:
      discard
    of Cylinder:
      height*: R

proc initBox*[R]: auto =
  CollisionObj[R](typ: Box,
               pos: vec3[R](0, 0, 0),
               quat: Quat[R](arr: [ R(0), 0, 0, 1 ]),
               x: 0, y: 0, z: 0 )

proc initSphere*[R]: auto =
  CollisionObj[R](typ: Sphere,
               pos: vec3[R](0, 0, 0),
               quat: Quat[R](arr: [ R(0), 0, 0, 1 ]),
               radius: 0 )

proc initCyl*[R]: auto =
  CollisionObj[R](typ: Cylinder,
               pos: vec3[R](0, 0, 0),
               quat: Quat[R](arr: [ R(0), 0, 0, 1 ]),
               radius: 0, height: 0 )

proc supportVec*[R](obj: ptr CollisionObj[R], dir: Vec3[R], v: var Vec3[R]) =
  ## Returns supporting vertex via v.
  ## Supporting vertex is fathest vertex from object in direction dir.
  # Support function is made according to Gino van den Bergen's paper
  #  A Fast and Robust CCD Implementation for Collision Detection of
  #  Convex Objects

  var dir = dir
  rotateByQuat(dir, inverse(obj[].quat))

  v = case obj[].typ
      of Box:
        vec3[R](R(sign(dir.x)) * R(obj[].x) * 0.5,
                R(sign(dir.y)) * R(obj[].y) * 0.5,
                R(sign(dir.z)) * R(obj[].z) * 0.5)
      of Sphere:
        let len: R = length2(dir)
        if len - ccdEps(R) > 0:
          dir * (obj[].radius / sqrt(len))
        else:
          vec3[R](0, 0, 0)
      of Cylinder:
        let zdist: R = sqrt(dir.x * dir.x + dir.y * dir.y)
        if isZero(zdist):
          vec3[R](0, 0, R(sign(dir.z)) * obj[].height * 0.5)
        else:
          let rad: R = obj[].radius / zdist
          vec3[R](rad * dir.x, rad * dir.y, R(sign(dir.z)) * obj[].height * 0.5)

  # transform support vertex
  rotateByQuat(v, obj[].quat)
  v += obj[].pos

proc objCenter*[R](obj: ptr CollisionObj[R], center: var Vec3[R]) =
  ## Returns center of object.
  center = vec3[R](0, 0, 0)
  # rotation is not needed
  center += obj[].pos
