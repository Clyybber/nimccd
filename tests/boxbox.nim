import ../src/ccd
import support, common

block boxboxAlignedX:
    var ccd = initCCD[ptr CollisionObj[real], real]()
    var box1 = initBox[real]()
    var box2 = initBox[real]()
    var res: bool

    ccd.support1 = supportVec
    ccd.support2 = supportVec
    #ccd.max_iterations = 20

    box1.x = 1
    box1.y = 2
    box1.z = 1
    box2.x = 2
    box2.y = 1
    box2.z = 2

    box1.pos = vec3[real](-5, 0, 0)
    box2.pos = vec3[real](0, 0, 0)
    box1.quat = quat[real](0, 0, 0, 1)
    box2.quat = quat[real](0, 0, 0, 1)
    for i in 0..<100:
        res = intersectGJK(addr box1, addr box2, ccd)
        if i < 35 or i > 65:
            assert not res
        elif i != 35 and i != 65:
            assert res

        box1.pos.x += 0.1


    box1.x = 0.1
    box1.y = 0.2
    box1.z = 0.1
    box2.x = 0.2
    box2.y = 0.1
    box2.z = 0.2

    box1.pos = vec3[real](-0.5, 0, 0)
    box2.pos = vec3[real](0, 0, 0)
    box1.quat = quat[real](0, 0, 0, 1)
    box2.quat = quat[real](0, 0, 0, 1)
    for i in 0..<100:
        res = intersectGJK(addr box1, addr box2, ccd)

        if i < 35 or i > 65:
            assert not res
        elif i != 35 and i != 65:
            assert res

        box1.pos.x += 0.01


    box1.x = 1
    box1.y = 2
    box1.z = 1
    box2.x = 2
    box2.y = 1
    box2.z = 2

    box1.pos = vec3[real](-5, -0.1, 0)
    box2.pos = vec3[real](0, 0, 0)
    box1.quat = quat[real](0, 0, 0, 1)
    box2.quat = quat[real](0, 0, 0, 1)
    for i in 0..<100:
        res = intersectGJK(addr box1, addr box2, ccd)

        if i < 35 or i > 65:
            assert not res
        elif i != 35 and i != 65:
            assert res

        box1.pos.x += 0.1

block boxboxAlignedY:
    var ccd = initCCD[ptr CollisionObj[real], real]()
    var box1 = initBox[real]()
    var box2 = initBox[real]()
    var res: bool

    ccd.support1 = supportVec
    ccd.support2 = supportVec

    box1.x = 1
    box1.y = 2
    box1.z = 1
    box2.x = 2
    box2.y = 1
    box2.z = 2

    box1.pos = vec3[real](0, -5, 0)
    box2.pos = vec3[real](0, 0, 0)
    box1.quat = quat[real](0, 0, 0, 1)
    box2.quat = quat[real](0, 0, 0, 1)
    for i in 0..<100:
        res = intersectGJK(addr box1, addr box2, ccd)

        if i < 35 or i > 65:
            assert not res
        elif i != 35 and i != 65:
            assert res

        box1.pos.y += 0.1

block boxboxAlignedZ:
    var ccd = initCCD[ptr CollisionObj[real], real]()
    var box1 = initBox[real]()
    var box2 = initBox[real]()
    var res: bool

    ccd.support1 = supportVec
    ccd.support2 = supportVec

    box1.x = 1
    box1.y = 2
    box1.z = 1
    box2.x = 2
    box2.y = 1
    box2.z = 2

    box1.pos = vec3[real](0, 0, -5)
    box2.pos = vec3[real](0, 0, 0)
    box1.quat = quat[real](0, 0, 0, 1)
    box2.quat = quat[real](0, 0, 0, 1)
    for i in 0..<100:
        res = intersectGJK(addr box1, addr box2, ccd)

        if i < 35 or i > 65:
            assert not res
        elif i != 35 and i != 65:
            assert res

        box1.pos.z += 0.1

block boxboxRot:
    var ccd = initCCD[ptr CollisionObj[real], real]()
    var box1 = initBox[real]()
    var box2 = initBox[real]()
    var res: bool
    var axis: Vec3[real]
    var angle: real

    ccd.support1 = supportVec
    ccd.support2 = supportVec

    box1.x = 1
    box1.y = 2
    box1.z = 1
    box2.x = 2
    box2.y = 1
    box2.z = 2

    box1.pos = vec3[real](-5, 0.5, 0)
    box2.pos = vec3[real](0, 0, 0)
    box2.quat = quat[real](0, 0, 0, 1)
    axis = vec3[real](0, 1, 0)
    setAngleAxis(box1.quat, PI / 4, axis)

    for i in 0..<100:
        res = intersectGJK(addr box1, addr box2, ccd)

        if i < 33 or i > 67:
            assert not res
        elif i != 33 and i != 67:
            assert res

        box1.pos.x += 0.1

    box1.x = 1
    box1.y = 1
    box1.z = 1
    box2.x = 1
    box2.y = 1
    box2.z = 1

    box1.pos = vec3[real](-1.01, 0, 0)
    box2.pos = vec3[real](0, 0, 0)
    box1.quat = quat[real](0, 0, 0, 1)
    box2.quat = quat[real](0, 0, 0, 1)

    axis = vec3[real](0, 1, 0)
    angle = 0
    for i in 0..<30:
        res = intersectGJK(addr box1, addr box2, ccd)

        if i != 0 and i != 10 and i != 20:
            assert res
        else:
            assert not res

        angle += PI / 20
        setAngleAxis(box1.quat, angle, axis)


proc pConf(box1, box2: ptr CollisionObj, v: Vec3) =
    c_printf("# box1.pos: [%lf %lf %lf]\n",
            box1[].pos.x, box1[].pos.y, box1[].pos.z)
    c_printf("# box1->quat: [%lf %lf %lf %lf]\n",
            box1[].quat.arr[0], box1[].quat.arr[1], box1[].quat.arr[2], box1[].quat.arr[3])
    c_printf("# box2->pos: [%lf %lf %lf]\n",
            box2[].pos.x, box2[].pos.y, box2[].pos.z)
    c_printf("# box2->quat: [%lf %lf %lf %lf]\n",
            box2[].quat.arr[0], box2[].quat.arr[1], box2[].quat.arr[2], box2[].quat.arr[3])
    c_printf("# sep: [%lf %lf %lf]\n",
            v.x, v.y, v.z)
    c_printf("#\n")

block boxboxSeparate:
    var ccd = initCCD[ptr CollisionObj[real], real]()
    var box1 = initBox[real]()
    var box2 = initBox[real]()
    var res: bool
    var sep, expsep, expsep2, axis: Vec3[real]

    c_printf("\n\n\n---- boxboxSeparate ----\n\n\n")

    box1.z = 1
    box1.y = 1
    box1.x = 1
    box2.x = 0.5
    box2.y = 1
    box2.z = 1.5


    ccd.support1 = supportVec
    ccd.support2 = supportVec

    box1.pos = vec3[real](-0.5, 0.5, 0.2)
    res = intersectGJK(addr box1, addr box2, ccd)
    assert res

    res = separateGJK(addr box1, addr box2, ccd, sep)
    assert res
    expsep = vec3[real](0.25, 0, 0)
    assert sep =~ expsep

    sep *= -1
    box1.pos += sep
    res = separateGJK(addr box1, addr box2, ccd, sep)
    assert res
    expsep = vec3[real](0, 0, 0)
    assert sep =~ expsep


    box1.pos = vec3[real](-0.3, 0.5, 1)
    res = separateGJK(addr box1, addr box2, ccd, sep)
    assert res
    expsep = vec3[real](0, 0, -0.25)
    assert sep =~ expsep



    box1.z = 1
    box1.y = 1
    box1.x = 1
    box2.z = 1
    box2.y = 1
    box2.x = 1
    axis = vec3[real](0, 0, 1)
    setAngleAxis(box1.quat, PI / 4, axis)
    box1.pos = vec3[real](0, 0, 0)

    res = separateGJK(addr box1, addr box2, ccd, sep)
    assert res
    expsep = vec3[real](0, 0, 1)
    expsep2 = vec3[real](0, 0, -1)
    assert sep =~ expsep or sep =~ expsep2



    box1.z = 1
    box1.y = 1
    box1.x = 1
    axis = vec3[real](0, 0, 1)
    setAngleAxis(box1.quat, PI / 4, axis)
    box1.pos = vec3[real](-0.5, 0, 0)

    res = separateGJK(addr box1, addr box2, ccd, sep)
    assert res
    pConf(addr box1, addr box2, sep)



    box1.z = 1
    box1.y = 1
    box1.x = 1
    axis = vec3[real](0, 1, 1)
    setAngleAxis(box1.quat, PI / 4, axis)
    box1.pos = vec3[real](-0.5, 0.1, 0.4)

    res = separateGJK(addr box1, addr box2, ccd, sep)
    assert res
    pConf(addr box1, addr box2, sep)


template TOSVT(): untyped =
    svtObjPen(addr box1, addr box2, "Pen 1", depth, dir, pos)
    dir *= depth
    box2.pos += dir
    svtObjPen(addr box1, addr box2, "Pen 1", depth, dir, pos)

block boxboxPenetration:
    var ccd = initCCD[ptr CollisionObj[real], real]()
    var box1 = initBox[real]()
    var box2 = initBox[real]()
    var res: bool
    var axis: Vec3[real]
    var rot: Quat[real]
    var depth: real
    var dir, pos: Vec3[real]

    c_printf("\n\n\n---- boxboxPenetration ----\n\n\n")

    box1.z = 1
    box1.y = 1
    box1.x = 1
    box2.x = 0.5
    box2.y = 1
    box2.z = 1.5


    ccd.support1 = supportVec
    ccd.support2 = supportVec

    box2.pos = vec3[real](0.1, 0, 0)
    res = penetrationGJK(addr box1, addr box2, ccd, depth, dir, pos)
    assert res
    recPen(depth, dir, pos, "Pen 1")
    #TOSVT()


    box1.pos = vec3[real](-0.3, 0.5, 1)
    res = penetrationGJK(addr box1, addr box2, ccd, depth, dir, pos)
    assert res
    recPen(depth, dir, pos, "Pen 2")
    #TOSVT(); <<<


    box1.z = 1
    box1.y = 1
    box1.x = 1
    box2.z = 1
    box2.y = 1
    box2.x = 1
    axis = vec3[real](0, 0, 1)
    setAngleAxis(box1.quat, PI / 4, axis)
    box1.pos = vec3[real](0.1, 0, 0.1)

    res = penetrationGJK(addr box1, addr box2, ccd, depth, dir, pos)
    assert res
    recPen(depth, dir, pos, "Pen 3")
    #TOSVT()


    box1.z = 1
    box1.y = 1
    box1.x = 1
    box2.z = 1
    box2.y = 1
    box2.x = 1
    axis = vec3[real](0, 0, 1)
    setAngleAxis(box1.quat, PI / 4, axis)
    box1.pos = vec3[real](-0.5, 0, 0)

    res = penetrationGJK(addr box1, addr box2, ccd, depth, dir, pos)
    assert res
    recPen(depth, dir, pos, "Pen 4")
    #TOSVT()


    box1.z = 1
    box1.y = 1
    box1.x = 1
    box2.z = 1
    box2.y = 1
    box2.x = 1
    axis = vec3[real](0, 0, 1)
    setAngleAxis(box1.quat, PI / 4, axis)
    box1.pos = vec3[real](-0.5, 0.5, 0)

    res = penetrationGJK(addr box1, addr box2, ccd, depth, dir, pos)
    assert res
    recPen(depth, dir, pos, "Pen 5")
    #TOSVT()


    box1.z = 1
    box1.y = 1
    box1.x = 1
    box2.z = 1
    box2.y = 1
    box2.x = 1
    box2.pos = vec3[real](0.1, 0, 0)

    box1.z = 1
    box1.y = 1
    box1.x = 1
    axis = vec3[real](0, 1, 1)
    setAngleAxis(box1.quat, PI / 4, axis)
    box1.pos = vec3[real](-0.5, 0.1, 0.4)

    res = penetrationGJK(addr box1, addr box2, ccd, depth, dir, pos)
    assert res
    recPen(depth, dir, pos, "Pen 6")
    #TOSVT()


    box1.z = 1
    box1.y = 1
    box1.x = 1
    axis = vec3[real](0, 1, 1)
    setAngleAxis(box1.quat, PI / 4, axis)
    axis = vec3[real](1, 1, 1)
    setAngleAxis(rot, PI / 4, axis)
    box1.quat *= rot
    box1.pos = vec3[real](-0.5, 0.1, 0.4)

    res = penetrationGJK(addr box1, addr box2, ccd, depth, dir, pos)
    assert res
    recPen(depth, dir, pos, "Pen 7")
    #TOSVT(); <<<


    box1.z = 1
    box1.y = 1
    box1.x = 1
    box2.x = 0.2; box2.y = 0.5; box2.z = 1
    box2.z = 1
    box2.y = 1
    box2.x = 1

    axis = vec3[real](0, 0, 1)
    setAngleAxis(box1.quat, PI / 4, axis)
    axis = vec3[real](1, 0, 0)
    setAngleAxis(rot, PI / 4, axis)
    box1.quat *= rot
    box1.pos = vec3[real](-1.3, 0, 0)

    box2.pos = vec3[real](0, 0, 0)

    res = penetrationGJK(addr box1, addr box2, ccd, depth, dir, pos)
    assert res
    recPen(depth, dir, pos, "Pen 8")
    #TOSVT()
