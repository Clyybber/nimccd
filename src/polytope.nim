#[
  libccd
  ---------------------------------
  Copyright (c)2010 Daniel Fiser <danfis@danfis.cz>


   This file is part of libccd.

   Distributed under the OSI-approved BSD License (the "License")
   see accompanying file BDS-LICENSE for details or see
   <http:#www.opensource.org/licenses/bsd-license.php>.

   This software is distributed WITHOUT ANY WARRANTY; without even the
   implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
   See the License for more information.
]#

import ccd, list
from system/ansi_c import c_free, c_malloc

type
  ccd_pt_el_typ* = enum ccd_pt_vertex, ccd_pt_edge, ccd_pt_face
  # XXX: These could be a case object, but that would increase memory consumption
  ccd_pt_el_t*[R] = object
    ## General polytope element. Could be vertex, edge or triangle.
    typ*: ccd_pt_el_typ     ## type of element
    dist*: R                ## distance from origin
    witness*: Vec3[R] ## witness point of projection of origin
    list: ccd_list_t        ## list of elements of same type

  ccd_pt_vertex_t*[R] = object
    ## Polytope's vertex.
    typ*: ccd_pt_el_typ
    dist*: R
    witness: Vec3[R]
    list*: ccd_list_t

    id: int
    v*: SupportPoints[R]
    edges: ccd_list_t # List of edges

  ccd_pt_edge_t*[R] = object
    ## Polytope's edge.
    typ*: ccd_pt_el_typ
    dist: R
    witness: Vec3[R]
    list: ccd_list_t

    vertex: array[2, ptr ccd_pt_vertex_t[R]] # Reference to vertices
    faces: array[2, ptr ccd_pt_face_t[R]] # Reference to faces

    vertex_list: array[2, ccd_list_t] # List items in vertices' lists

  ccd_pt_face_t*[R] = object
    ## Polytope's triangle faces.
    typ*: ccd_pt_el_typ
    dist: R
    witness: Vec3[R]
    list: ccd_list_t

    edge: array[3, ptr ccd_pt_edge_t[R]] # Reference to surrounding edges

  ccd_pt_t*[R] = object
    ## Struct containing polytope.
    vertices*: ccd_list_t ## List of vertices
    edges: ccd_list_t     ## List of edges
    faces: ccd_list_t     ## List of faces

    nearest: ptr ccd_pt_el_t[R]
    nearest_dist: R
    nearest_type: ccd_pt_el_typ

proc deleteVertex(pt: var ccd_pt_t, v: ptr ccd_pt_vertex_t) {.inline.} =
  ## Deletes vertex from polytope. Returns 0 on success, -1 otherwise.
  # test if any edge is connected to this vertex
  if not isEmpty(addr v[].edges): return

  # delete vertex from main list
  delete(addr v[].list)

  if pointer(pt.nearest) == pointer(v): pt.nearest = nil

  c_free(v)

proc deleteEdge*(pt: var ccd_pt_t, e: ptr ccd_pt_edge_t) {.inline.} =
  # text if any face is connected to this edge (faces[] is always aligned to lower indices)
  if e[].faces[0] != nil: return

  # disconnect edge from lists of edges in vertex struct
  delete(addr e[].vertex_list[0])
  delete(addr e[].vertex_list[1])

  # disconnect edge from main list
  delete(addr e[].list)

  if pointer(pt.nearest) == pointer(e): pt.nearest = nil

  c_free(e)

proc deleteFace*(pt: var ccd_pt_t, f: ptr ccd_pt_face_t) {.inline.} =
  # remove face from edges' recerence lists
  for i in 0..<3:
      let e = f[].edge[i]
      if e[].faces[0] == f: e[].faces[0] = e[].faces[1]
      e[].faces[1] = nil

  # remove face from list of all faces
  delete(addr f[].list)

  if pointer(pt.nearest) == pointer(f): pt.nearest = nil

  c_free(f)

proc faceVec3*(face: ptr ccd_pt_face_t, a, b, c: var ptr Vec3) {.inline.} =
  ## Returns vertices surrounding given triangle face.
  a = addr face[].edge[0][].vertex[0][].v.v
  b = addr face[].edge[0][].vertex[1][].v.v
  c = if face[].edge[1][].vertex[0] != face[].edge[0][].vertex[0] and
         face[].edge[1][].vertex[0] != face[].edge[0][].vertex[1]:
          addr face[].edge[1][].vertex[0][].v.v
      else:
          addr face[].edge[1][].vertex[1][].v.v

proc faceVertices(face: ptr ccd_pt_face_t, a, b, c: var ptr ccd_pt_vertex_t) {.inline.} =
  a = face[].edge[0][].vertex[0]
  b = face[].edge[0][].vertex[1]
  c = if face[].edge[1][].vertex[0] != face[].edge[0][].vertex[0] and
         face[].edge[1][].vertex[0] != face[].edge[0][].vertex[1]:
          face[].edge[1][].vertex[0]
      else:
          face[].edge[1][].vertex[1]

proc faceEdges*(f: ptr ccd_pt_face_t, a, b, c: var ptr ccd_pt_edge_t) {.inline.} =
  a = f[].edge[0]
  b = f[].edge[1]
  c = f[].edge[2]

proc edgeVec3*(e: ptr ccd_pt_edge_t, a, b: var ptr Vec3) {.inline.} =
  a = addr e[].vertex[0][].v.v
  b = addr e[].vertex[1][].v.v

proc edgeVertices*(e: ptr ccd_pt_edge_t, a, b: var ptr ccd_pt_vertex_t) {.inline.} =
  a = e[].vertex[0]
  b = e[].vertex[1]

proc edgeFaces*(e: ptr ccd_pt_edge_t, f1, f2: var ptr ccd_pt_face_t) {.inline.} =
  f1 = e[].faces[0]
  f2 = e[].faces[1]

proc updateNearest(pt: var ccd_pt_t, el: ptr ccd_pt_el_t) {.inline.} =
  if pt.nearest_dist =~ el[].dist:
      if el[].typ < pt.nearest_type:
          pt.nearest = el
          pt.nearest_dist = el[].dist
          pt.nearest_type = el[].typ
  elif el[].dist < pt.nearest_dist:
      pt.nearest = el
      pt.nearest_dist = el[].dist
      pt.nearest_type = el[].typ

from fenv import maximumPositiveValue
proc renewNearest[R](pt: var ccd_pt_t[R]) =
  pt.nearest_dist = maximumPositiveValue(R)
  pt.nearest_type = ccd_pt_face
  pt.nearest = nil

  forEachEntry(addr pt.vertices, v, ccd_pt_vertex_t[R], list):
      updateNearest(pt, cast[ptr ccd_pt_el_t[R]](v))

  forEachEntry(addr pt.edges, e, ccd_pt_edge_t[R], list):
      updateNearest(pt, cast[ptr ccd_pt_el_t[R]](e))

  forEachEntry(addr pt.faces, f, ccd_pt_face_t[R], list):
      updateNearest(pt, cast[ptr ccd_pt_el_t[R]](f))

proc initPolytope*[R](pt: var ccd_pt_t[R]) =
  initList(addr pt.vertices)
  initList(addr pt.edges)
  initList(addr pt.faces)

  pt.nearest = nil
  pt.nearest_dist = maximumPositiveValue(R)
  pt.nearest_type = ccd_pt_face

proc destroyPolytope*[R](pt: var ccd_pt_t[R]) =
  # first delete all faces
  forEachEntrySafe(addr pt.faces, f, f2, ccd_pt_face_t[R], list):
      deleteFace(pt, f)

  # delete all edges
  forEachEntrySafe(addr pt.edges, e, e2, ccd_pt_edge_t[R], list):
      deleteEdge(pt, e)

  # delete all vertices
  forEachEntrySafe(addr pt.vertices, v, v2, ccd_pt_vertex_t[R], list):
      deleteVertex(pt, v)

template ccdAlloc(typ): untyped = cast[ptr typ](c_malloc(sizeof(typ).csize_t))

proc addVertex*[R](pt: var ccd_pt_t[R], v: SupportPoints[R]): ptr ccd_pt_vertex_t[R] =
  ## Adds vertex to polytope and returns pointer to newly created vertex.
  result = ccdAlloc(ccd_pt_vertex_t[R])
  if result == nil: return nil

  result[].typ = ccd_pt_vertex
  result[].v = v

  result[].dist = length2(result[].v.v)
  result[].witness = result[].v.v

  initList(addr result[].edges)

  # add vertex to list
  append(addr pt.vertices, addr result[].list)

  # update position in .nearest array
  updateNearest(pt, cast[ptr ccd_pt_el_t[R]](result))

proc addVertexCoords[R](pt: var ccd_pt_t[R], x, y, z: R): ptr ccd_pt_vertex_t[R] {.inline.} =
  addVertex(pt, SupportPoints(v: vec3(x, y, z)))

proc addEdge*[R](pt: var ccd_pt_t[R], v1, v2: ptr ccd_pt_vertex_t[R]): ptr ccd_pt_edge_t[R] =
  ## Adds edge to polytope.
  if v1 == nil or v2 == nil: return nil

  result = ccdAlloc(ccd_pt_edge_t[R])
  if result == nil: return nil

  result[].typ = ccd_pt_edge
  result[].vertex[0] = v1
  result[].vertex[1] = v2
  result[].faces[1] = nil
  result[].faces[0] = nil

  let a = result[].vertex[0][].v.v
  let b = result[].vertex[1][].v.v
  result[].dist = vec3PointSegmentDist2(origin(R), a, b, addr result[].witness)

  append(addr result[].vertex[0][].edges, addr result[].vertex_list[0])
  append(addr result[].vertex[1][].edges, addr result[].vertex_list[1])

  append(addr pt.edges, addr result[].list)

  # update position in .nearest array
  updateNearest(pt, cast[ptr ccd_pt_el_t[R]](result))

proc addFace*[R](pt: var ccd_pt_t[R], e1, e2, e3: ptr ccd_pt_edge_t[R]): ptr ccd_pt_face_t[R] =
  ## Adds face to polytope.
  if e1 == nil or e2 == nil or e3 == nil: return nil

  result = ccdAlloc(ccd_pt_face_t[R])
  if result == nil: return nil

  result[].typ = ccd_pt_face
  result[].edge[0] = e1
  result[].edge[1] = e2
  result[].edge[2] = e3

  # obtain triplet of vertices
  let a = result[].edge[0][].vertex[0][].v.v
  let b = result[].edge[0][].vertex[1][].v.v
  let e = result[].edge[1]
  let c = if e[].vertex[0] != result[].edge[0][].vertex[0] and
             e[].vertex[0] != result[].edge[0][].vertex[1]:
              e[].vertex[0][].v.v
          else:
              e[].vertex[1][].v.v
  result[].dist = vec3PointTriangleDist2(origin(R), a, b, c, addr result[].witness)

  for i in 0..<3:
      if result[].edge[i][].faces[0] == nil:
          result[].edge[i][].faces[0] = result
      else:
          result[].edge[i][].faces[1] = result

  append(addr pt.faces, addr result[].list)

  # update position in .nearest array
  updateNearest(pt, cast[ptr ccd_pt_el_t[R]](result))

proc recomputeDistances*(pt: var ccd_pt_t) =
  ## Recompute distances from origin for all elements in pt.
  forEachEntry(addr pt.vertices, v, ccd_pt_vertex_t, list):
      v[].dist = length2(v[].v.v)
      v[].witness = v[].v.v

  forEachEntry(addr pt.edges, e, ccd_pt_edge_t, list):
      let a = e[].vertex[0][].v.v
      let b = e[].vertex[1][].v.v
      e[].dist = vec3PointSegmentDist2(origin, a, b, addr e[].witness)

  forEachEntry(addr pt.faces, f, ccd_pt_face_t, list):
      # obtain triplet of vertices
      let a = f[].edge[0][].vertex[0][].v.v
      let b = f[].edge[0][].vertex[1][].v.v
      let e = f[].edge[1]
      let c = if e[].vertex[0] != f[].edge[0][].vertex[0] and
                 e[].vertex[0] != f[].edge[0][].vertex[1]:
                  e[].vertex[0][].v.v
              else:
                  e[].vertex[1][].v.v

      f[].dist = vec3PointTriangleDist2(origin, a, b, c, addr f[].witness)

proc nearestToOrigin*[R](pt: var ccd_pt_t[R]): ptr ccd_pt_el_t[R] =
  ## Returns nearest element to origin.
  if pt.nearest == nil: renewNearest(pt)
  return pt.nearest

