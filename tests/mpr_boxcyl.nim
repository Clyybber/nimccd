import ../src/[ccd, mpr]
import common, support


template TOSVT(): untyped =
    svtObjPen(addr box, addr cyl, "Pen 1", depth, dir, pos)
    dir *= depth
    cyl.pos += dir
    svtObjPen(addr box, addr cyl, "Pen 1", depth, dir, pos)

block mprBoxcylIntersect:
    var ccd = initCCD[ptr CollisionObj[real], real]()
    var box = initBox[real]()
    var cyl = initCyl[real]()
    var res: bool
    var axis: Vec3[real]

    box.x = 0.5
    box.y = 1
    box.z = 1.5
    cyl.radius = 0.4
    cyl.height = 0.7

    ccd.support1 = supportVec
    ccd.support2 = supportVec
    ccd.center1  = objCenter
    ccd.center2  = objCenter

    cyl.pos = vec3[real](0.1, 0, 0)
    res = intersectMPR(addr box, addr cyl, ccd)
    assert res

    cyl.pos = vec3[real](0.6, 0, 0)
    res = intersectMPR(addr box, addr cyl, ccd)
    assert res

    cyl.pos = vec3[real](0.6, 0.6, 0)
    res = intersectMPR(addr box, addr cyl, ccd)
    assert res

    cyl.pos = vec3[real](0.6, 0.6, 0.5)
    res = intersectMPR(addr box, addr cyl, ccd)
    assert res

    axis = vec3[real](0, 1, 0)
    setAngleAxis(cyl.quat, PI / 3, axis)
    cyl.pos = vec3[real](0.6, 0.6, 0.5)
    res = intersectMPR(addr box, addr cyl, ccd)
    assert res

    axis = vec3[real](0.67, 1.1, 0.12)
    setAngleAxis(cyl.quat, PI / 4, axis)
    cyl.pos = vec3[real](0.6, 0, 0.5)
    res = intersectMPR(addr box, addr cyl, ccd)
    assert res

    axis = vec3[real](-0.1, 2.2, -1)
    setAngleAxis(cyl.quat, PI / 5, axis)
    cyl.pos = vec3[real](0.6, 0, 0.5)
    axis = vec3[real](1, 1, 0)
    setAngleAxis(box.quat, -PI / 4, axis)
    box.pos = vec3[real](0.6, 0, 0.5)
    res = intersectMPR(addr box, addr cyl, ccd)
    assert res

    axis = vec3[real](-0.1, 2.2, -1)
    setAngleAxis(cyl.quat, PI / 5, axis)
    cyl.pos = vec3[real](0.6, 0, 0.5)
    axis = vec3[real](1, 1, 0)
    setAngleAxis(box.quat, -PI / 4, axis)
    box.pos = vec3[real](0.9, 0.8, 0.5)
    res = intersectMPR(addr box, addr cyl, ccd)
    assert res

block mprBoxcylPen:
    var ccd = initCCD[ptr CollisionObj[real], real]()
    var box = initBox[real]()
    var cyl = initCyl[real]()
    var res: bool
    var axis: Vec3[real]
    var depth: real
    var dir, pos: Vec3[real]

    box.x = 0.5
    box.y = 1
    box.z = 1.5
    cyl.radius = 0.4
    cyl.height = 0.7

    ccd.support1 = supportVec
    ccd.support2 = supportVec
    ccd.center1  = objCenter
    ccd.center2  = objCenter

    cyl.pos = vec3[real](0.1, 0, 0)
    res = penetrationMPR(addr box, addr cyl, ccd, depth, dir, pos)
    assert res
    recPen(depth, dir, pos, "Pen 1")
    #TOSVT()

    cyl.pos = vec3[real](0.6, 0, 0)
    res = penetrationMPR(addr box, addr cyl, ccd, depth, dir, pos)
    assert res
    recPen(depth, dir, pos, "Pen 2")
    #TOSVT()

    cyl.pos = vec3[real](0.6, 0.6, 0)
    res = penetrationMPR(addr box, addr cyl, ccd, depth, dir, pos)
    assert res
    recPen(depth, dir, pos, "Pen 3")
    #TOSVT()

    cyl.pos = vec3[real](0.6, 0.6, 0.5)
    res = penetrationMPR(addr box, addr cyl, ccd, depth, dir, pos)
    assert res
    recPen(depth, dir, pos, "Pen 4")
    #TOSVT()

    axis = vec3[real](0, 1, 0)
    setAngleAxis(cyl.quat, PI / 3, axis)
    cyl.pos = vec3[real](0.6, 0.6, 0.5)
    res = penetrationMPR(addr box, addr cyl, ccd, depth, dir, pos)
    assert res
    recPen(depth, dir, pos, "Pen 5")
    #TOSVT()

    axis = vec3[real](0.67, 1.1, 0.12)
    setAngleAxis(cyl.quat, PI / 4, axis)
    cyl.pos = vec3[real](0.6, 0, 0.5)
    res = penetrationMPR(addr box, addr cyl, ccd, depth, dir, pos)
    assert res
    recPen(depth, dir, pos, "Pen 6")
    #TOSVT()

    axis = vec3[real](-0.1, 2.2, -1)
    setAngleAxis(cyl.quat, PI / 5, axis)
    cyl.pos = vec3[real](0.6, 0, 0.5)
    axis = vec3[real](1, 1, 0)
    setAngleAxis(box.quat, -PI / 4, axis)
    box.pos = vec3[real](0.6, 0, 0.5)
    res = penetrationMPR(addr box, addr cyl, ccd, depth, dir, pos)
    assert res
    recPen(depth, dir, pos, "Pen 7")
    #TOSVT()

    axis = vec3[real](-0.1, 2.2, -1)
    setAngleAxis(cyl.quat, PI / 5, axis)
    cyl.pos = vec3[real](0.6, 0, 0.5)
    axis = vec3[real](1, 1, 0)
    setAngleAxis(box.quat, -PI / 4, axis)
    box.pos = vec3[real](0.9, 0.8, 0.5)
    res = penetrationMPR(addr box, addr cyl, ccd, depth, dir, pos)
    assert res
    recPen(depth, dir, pos, "Pen 8")
    #TOSVT()

