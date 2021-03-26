import ../src/ccd
import support, common


block spheresphereAlignedX:
    var ccd = initCCD[ptr CollisionObj[real], real]()
    var s1 = initSphere[real]()
    var s2 = initSphere[real]()
    var res: bool

    ccd.support1 = supportVec
    ccd.support2 = supportVec

    s1.radius = 0.35
    s2.radius = 0.5

    s1.pos = vec3[real](-5, 0, 0)
    for i in 0..<100:
        res = intersectGJK(addr s1, addr s2, ccd)

        if i < 42 or i > 58:
            assert not res
        else:
            assert res

        s1.pos.x += 0.1

block spheresphereAlignedY:
    var ccd = initCCD[ptr CollisionObj[real], real]()
    var s1 = initSphere[real]()
    var s2 = initSphere[real]()
    var res: bool

    ccd.support1 = supportVec
    ccd.support2 = supportVec

    s1.radius = 0.35
    s2.radius = 0.5

    s1.pos = vec3[real](0, -5, 0)
    for i in 0..<100:
        res = intersectGJK(addr s1, addr s2, ccd)

        if i < 42 or i > 58:
            assert not res
        else:
            assert res

        s1.pos.y += 0.1

block spheresphereAlignedZ:
    var ccd = initCCD[ptr CollisionObj[real], real]()
    var s1 = initSphere[real]()
    var s2 = initSphere[real]()
    var res: bool

    ccd.support1 = supportVec
    ccd.support2 = supportVec

    s1.radius = 0.35
    s2.radius = 0.5

    s1.pos = vec3[real](0, 0, -5)
    for i in 0..<100:
        res = intersectGJK(addr s1, addr s2, ccd)

        if i < 42 or i > 58:
            assert not res
        else:
            assert res

        s1.pos.z += 0.1

