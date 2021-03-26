import ../src/ccd
import support, common
from math import PI
import os, strutils, times

from system/ansi_c import c_printf

var bench_num = 1
var cycles = 10000

proc runBench[T, R](o1, o2: ptr CollisionObj[R], ccd: CCDObj[T, R]) =
    var depth: R
    var dir, pos: Vec3[R]
    var i: csize_t

    let t0 = cpuTime()
    for i in 0..<cycles:
        discard penetrationGJK(o1, o2, ccd, depth, dir, pos)
    let t1 = cpuTime()
    echo benchNum,": ",t1 - t0#," ",(t1 - t0) * 10000000000'f64

    inc bench_num

proc boxbox() =
    c_printf("boxbox:\n");

    var ccd = initCCD[ptr CollisionObj[real], real]()
    var box1 = initBox[real]()
    var box2 = initBox[real]()
    var axis: Vec3[real]
    var rot: Quat[real]

    box1.x = 1
    box1.y = 1
    box1.z = 1
    box2.x = 0.5
    box2.y = 1
    box2.z = 1.5

    bench_num = 1;

    ccd.support1 = supportVec
    ccd.support2 = supportVec

    runBench(addr box1, addr box2, ccd);
    runBench(addr box2, addr box1, ccd);

    box1.pos = vec3[real](-0.3, 0.5, 1)
    runBench(addr box1, addr box2, ccd);
    runBench(addr box2, addr box1, ccd);

    box1.x = 1
    box1.y = 1
    box1.z = 1
    box2.x = 1
    box2.y = 1
    box2.z = 1
    axis = vec3[real](0, 0, 1)
    setAngleAxis(box1.quat, PI / 4, axis);
    box1.pos = vec3[real](0, 0, 0)
    runBench(addr box1, addr box2, ccd);
    runBench(addr box2, addr box1, ccd);

    box1.x = 1
    box1.y = 1
    box1.z = 1
    box2.x = 1
    box2.y = 1
    box2.z = 1
    axis = vec3[real](0, 0, 1)
    setAngleAxis(box1.quat, PI / 4, axis);
    box1.pos = vec3[real](-0.5, 0, 0)
    runBench(addr box1, addr box2, ccd);
    runBench(addr box2, addr box1, ccd);

    box1.x = 1
    box1.y = 1
    box1.z = 1
    box2.x = 1
    box2.y = 1
    box2.z = 1
    axis = vec3[real](0, 0, 1)
    setAngleAxis(box1.quat, PI / 4, axis);
    box1.pos = vec3[real](-0.5, 0.5, 0)
    runBench(addr box1, addr box2, ccd);
    runBench(addr box2, addr box1, ccd);

    box1.x = 1
    box1.y = 1
    box1.z = 1
    axis = vec3[real](0, 1, 1)
    setAngleAxis(box1.quat, PI / 4, axis);
    box1.pos = vec3[real](-0.5, 0.1, 0.4)
    runBench(addr box1, addr box2, ccd);
    runBench(addr box2, addr box1, ccd);

    box1.x = 1
    box1.y = 1
    box1.z = 1
    axis = vec3[real](0, 1, 1)
    setAngleAxis(box1.quat, PI / 4, axis);
    axis = vec3[real](1, 1, 1)
    setAngleAxis(rot, PI / 4, axis);
    box1.quat *= rot;
    box1.pos = vec3[real](-0.5, 0.1, 0.4)
    runBench(addr box1, addr box2, ccd)
    runBench(addr box2, addr box1, ccd)


    box1.x = 1
    box1.y = 1
    box1.z = 1
    box2.x = 0.2; box2.y = 0.5; box2.z = 1;
    box2.x = 1
    box2.y = 1
    box2.z = 1

    axis = vec3[real](0, 0, 1)
    setAngleAxis(box1.quat, PI / 4, axis);
    axis = vec3[real](1, 0, 0)
    setAngleAxis(rot, PI / 4, axis);
    box1.quat *= rot;
    box1.pos = vec3[real](-1.3, 0, 0)

    box2.pos = vec3[real](0, 0, 0)
    runBench(addr box1, addr box2, ccd)
    runBench(addr box2, addr box1, ccd)


    c_printf("\n----\n\n");

proc cylcyl() =
    c_printf("cylcyl:\n");

    var ccd = initCCD[ptr CollisionObj[real], real]()
    var cyl1 = initCyl[real]()
    var cyl2 = initCyl[real]()
    var axis: Vec3[real]

    cyl1.radius = 0.35;
    cyl1.height = 0.5;
    cyl2.radius = 0.5;
    cyl2.height = 1;

    ccd.support1 = supportVec
    ccd.support2 = supportVec

    runBench(addr cyl1, addr cyl2, ccd)
    runBench(addr cyl2, addr cyl1, ccd)

    cyl1.pos = vec3[real](0.3, 0.1, 0.1)
    runBench(addr cyl1, addr cyl2, ccd)
    runBench(addr cyl2, addr cyl1, ccd)

    axis = vec3[real](0, 1, 1)
    setAngleAxis(cyl2.quat, PI / 4, axis);
    cyl2.pos = vec3[real](0, 0, 0)
    runBench(addr cyl1, addr cyl2, ccd)
    runBench(addr cyl2, addr cyl1, ccd)

    axis = vec3[real](0, 1, 1)
    setAngleAxis(cyl2.quat, PI / 4, axis);
    cyl2.pos = vec3[real](-0.2, 0.7, 0.2)
    runBench(addr cyl1, addr cyl2, ccd)
    runBench(addr cyl2, addr cyl1, ccd)

    axis = vec3[real](0.567, 1.2, 1)
    setAngleAxis(cyl2.quat, PI / 4, axis);
    cyl2.pos = vec3[real](0.6, -0.7, 0.2)
    runBench(addr cyl1, addr cyl2, ccd)
    runBench(addr cyl2, addr cyl1, ccd)

    axis = vec3[real](-4.567, 1.2, 0)
    setAngleAxis(cyl2.quat, PI / 3, axis);
    cyl2.pos = vec3[real](0.6, -0.7, 0.2)
    runBench(addr cyl1, addr cyl2, ccd)
    runBench(addr cyl2, addr cyl1, ccd)

    c_printf("\n----\n\n");

proc boxcyl() =
    c_printf("boxcyl:\n");

    var ccd = initCCD[ptr CollisionObj[real], real]()
    var box = initBox[real]()
    var cyl = initCyl[real]()
    var axis: Vec3[real]

    box.x = 0.5;
    box.y = 1;
    box.z = 1.5;
    cyl.radius = 0.4;
    cyl.height = 0.7;

    ccd.support1 = supportVec
    ccd.support2 = supportVec

    runBench(addr box, addr cyl, ccd)
    runBench(addr cyl, addr box, ccd)

    cyl.pos = vec3[real](0.6, 0, 0)
    runBench(addr box, addr cyl, ccd)
    runBench(addr cyl, addr box, ccd)

    cyl.pos = vec3[real](0.6, 0.6, 0)
    runBench(addr box, addr cyl, ccd)
    runBench(addr cyl, addr box, ccd)

    cyl.pos = vec3[real](0.6, 0.6, 0.5)
    runBench(addr box, addr cyl, ccd)
    runBench(addr cyl, addr box, ccd)

    axis = vec3[real](0, 1, 0)
    setAngleAxis(cyl.quat, PI / 3, axis);
    cyl.pos = vec3[real](0.6, 0.6, 0.5)
    runBench(addr box, addr cyl, ccd)
    runBench(addr cyl, addr box, ccd)

    axis = vec3[real](0.67, 1.1, 0.12)
    setAngleAxis(cyl.quat, PI / 4, axis);
    cyl.pos = vec3[real](0.6, 0, 0.5)
    runBench(addr box, addr cyl, ccd)
    runBench(addr cyl, addr box, ccd)

    axis = vec3[real](-0.1, 2.2, -1)
    setAngleAxis(cyl.quat, PI / 5, axis);
    cyl.pos = vec3[real](0.6, 0, 0.5)
    axis = vec3[real](1, 1, 0)
    setAngleAxis(box.quat, -PI / 4, axis);
    box.pos = vec3[real](0.6, 0, 0.5)
    runBench(addr box, addr cyl, ccd)
    runBench(addr cyl, addr box, ccd)

    axis = vec3[real](-0.1, 2.2, -1)
    setAngleAxis(cyl.quat, PI / 5, axis);
    cyl.pos = vec3[real](0.6, 0, 0.5)
    axis = vec3[real](1, 1, 0)
    setAngleAxis(box.quat, -PI / 4, axis);
    box.pos = vec3[real](0.9, 0.8, 0.5)
    runBench(addr box, addr cyl, ccd)
    runBench(addr cyl, addr box, ccd)

    c_printf("\n----\n\n");

proc main =
    if paramCount() > 0:
      cycles = parseInt(paramStr(1))

    echo "Cycles: ", cycles
    echo()

    boxbox()
    cylcyl()
    boxcyl()

main()
