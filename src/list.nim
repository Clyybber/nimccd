#[
  libccd
  ---------------------------------
  Copyright (c)2010 Daniel Fiser <danfis@danfis.cz>


   This file is part of libccd.

   Distributed under the OSI-approved BSD License (the "License")
   see accompanying file BDS-LICENSE for details or see
   <http://www.opensource.org/licenses/bsd-license.php>.

   This software is distributed WITHOUT ANY WARRANTY; without even the
   implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
   See the License for more information.
]#

# __prefetch(x)  - prefetches the cacheline at "x" for read
# __prefetchw(x) - prefetches the cacheline at "x" for write
template prefetch*(x) = discard # TODO
  #when __GNUC__
  #  define _ccd_prefetch(x) __builtin_prefetch(x)
  #  define _ccd_prefetchw(x) __builtin_prefetch(x,1)
  #else
  #  define _ccd_prefetch(x) ((void)0)
  #  define _ccd_prefetchw(x) ((void)0)

type IntrusiveList* = object
  next*, prev*: ptr IntrusiveList

template entry(
    p,     # the head of the embedded list.
    typ,   # the type of the struct this list is embedded in.
    member # the name of the embedded list within the struct.
  ): untyped =
  ## Get the struct for this entry.
  cast[ptr typ](cast[uint64](p) - cast[uint64](offsetof(typ, member)))

template forEachEntry*(
    head,    # the head of the embedded list.
    pos,     # the location to use as a loop cursor.
    postype, # the type of the structs this list is embedded in.
    member,  # the name of the embedded list within the struct.
    XXX: untyped) =
  ## Iterates over list of given type.
  block:
    var pos = entry(head[].next, postype, member)
    while (prefetch(pos[].member.next); (addr pos[].member) != head):
      XXX
      pos = entry(pos[].member.next, postype, member)

template forEachEntrySafe*(
    head,    # the head of the embedded list.
    pos,     # the location to use as a loop cursor.
    n,       # the location to use as temporary storage.
    postype, # the type of the structs this list is embedded in.
    member,  # the name of the embedded list within the struct.
    XXX: untyped) =
  ## Iterates over list of given type, safe against removal of list entry
  block:
    var pos = entry(head[].next, postype, member);
    var n = entry(pos[].member.next, postype, member);
    while (addr pos[].member) != head:
      XXX
      pos = n; n = entry(n[].member.next, postype, member)

proc initList*(l: ptr IntrusiveList) {.inline.} =
  ## Initialize list.
  l[].next = l
  l[].prev = l

proc isEmpty*(head: ptr IntrusiveList): bool {.inline.} =
  ## Returns true if list is empty.
  head[].next == head

proc append*(l, new: ptr IntrusiveList) {.inline.} =
  ## Appends item to end of the list l.
  new[].prev = l[].prev
  new[].next = l
  l[].prev[].next = new
  l[].prev = new

proc delete*(item: ptr IntrusiveList) {.inline.} =
  ## Removes item from list.
  item[].next[].prev = item[].prev
  item[].prev[].next = item[].next
  item[].next = item
  item[].prev = item

