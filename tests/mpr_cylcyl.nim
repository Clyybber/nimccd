import ../src/[ccd, mpr]
import support, common


block mprCylcylAlignedX:
    var ccd = initCCD[ptr CollisionObj[real], real]()
    var c1 = initCyl[real]()
    var c2 = initCyl[real]()
    var res: bool

    ccd.support1 = supportVec
    ccd.support2 = supportVec
    ccd.center1  = objCenter
    ccd.center2  = objCenter

    c1.radius = 0.35
    c1.height = 0.5
    c2.radius = 0.5
    c2.height = 1

    c1.pos = vec3[real](-5, 0, 0)
    for i in 0..<100:
        res = intersectMPR(addr c1, addr c2, ccd)

        if i < 42 or i > 58:
            assert not res
        else:
            assert res

        c1.pos.x += 0.1

block mprCylcylAlignedY:
    var ccd = initCCD[ptr CollisionObj[real], real]()
    var c1 = initCyl[real]()
    var c2 = initCyl[real]()
    var res: bool

    ccd.support1 = supportVec
    ccd.support2 = supportVec
    ccd.center1  = objCenter
    ccd.center2  = objCenter

    c1.radius = 0.35
    c1.height = 0.5
    c2.radius = 0.5
    c2.height = 1

    c1.pos = vec3[real](0, -5, 0)
    for i in 0..<100:
        res = intersectMPR(addr c1, addr c2, ccd)

        if i < 42 or i > 58:
            assert not res
        else:
            assert res

        c1.pos.y += 0.1

block mprCylcylAlignedZ:
    var ccd = initCCD[ptr CollisionObj[real], real]()
    var c1 = initCyl[real]()
    var c2 = initCyl[real]()
    var res: bool

    ccd.support1 = supportVec
    ccd.support2 = supportVec
    ccd.center1  = objCenter
    ccd.center2  = objCenter

    c1.radius = 0.35
    c1.height = 0.5
    c2.radius = 0.5
    c2.height = 1

    c1.pos = vec3[real](0, 0, -5)
    for i in 0..<100:
        res = intersectMPR(addr c1, addr c2, ccd)

        if i < 43 or i > 57:
            assert not res
        else:
            assert res

        c1.pos.z += 0.1

template TOSVT(): untyped =
    svtObjPen(addr cyl1, addr cyl2, "Pen 1", depth, addr dir, addr pos)
    dir *= depth
    cyl2.pos += dir
    svtObjPen(addr cyl1, addr cyl2, "Pen 1", depth, addr dir, addr pos)

block mprCylcylPenetration:
    var ccd = initCCD[ptr CollisionObj[real], real]()
    var cyl1 = initCyl[real]()
    var cyl2 = initCyl[real]()
    var res: bool
    var axis: Vec3[real]
    var depth: real
    var dir, pos: Vec3[real]

    c_printf("\n\n\n---- mprCylcylPenetration ----\n\n\n")

    cyl1.radius = 0.35
    cyl1.height = 0.5
    cyl2.radius = 0.5
    cyl2.height = 1

    ccd.support1 = supportVec
    ccd.support2 = supportVec
    ccd.center1  = objCenter
    ccd.center2  = objCenter

    cyl2.pos = vec3[real](0, 0, 0.3)
    res = penetrationMPR(addr cyl1, addr cyl2, ccd, depth, dir, pos)
    assert res
    recPen(depth, dir, pos, "Pen 1")
    #TOSVT()

    cyl1.pos = vec3[real](0.3, 0.1, 0.1)
    res = penetrationMPR(addr cyl1, addr cyl2, ccd, depth, dir, pos)
    assert res
    recPen(depth, dir, pos, "Pen 2")
    #TOSVT()

    axis = vec3[real](0, 1, 1)
    setAngleAxis(cyl2.quat, PI / 4, axis)
    cyl2.pos = vec3[real](0, 0, 0)
    res = penetrationMPR(addr cyl1, addr cyl2, ccd, depth, dir, pos)
    assert res
    recPen(depth, dir, pos, "Pen 3")
    #TOSVT()

    axis = vec3[real](0, 1, 1)
    setAngleAxis(cyl2.quat, PI / 4, axis)
    cyl2.pos = vec3[real](-0.2, 0.7, 0.2)
    res = penetrationMPR(addr cyl1, addr cyl2, ccd, depth, dir, pos)
    assert res
    recPen(depth, dir, pos, "Pen 4")
    #TOSVT()

    axis = vec3[real](0.567, 1.2, 1)
    setAngleAxis(cyl2.quat, PI / 4, axis)
    cyl2.pos = vec3[real](0.6, -0.7, 0.2)
    res = penetrationMPR(addr cyl1, addr cyl2, ccd, depth, dir, pos)
    assert res
    recPen(depth, dir, pos, "Pen 5")
    #TOSVT()

    axis = vec3[real](-4.567, 1.2, 0)
    setAngleAxis(cyl2.quat, PI / 3, axis)
    cyl2.pos = vec3[real](0.6, -0.7, 0.2)
    res = penetrationMPR(addr cyl1, addr cyl2, ccd, depth, dir, pos)
    assert res
    recPen(depth, dir, pos, "Pen 6")
    #TOSVT()

