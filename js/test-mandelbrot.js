namespace.lookup('com.pageforest.mandelbrot.test').defineOnce(function (ns) {
    var mandelbrot = namespace.lookup('com.pageforest.mandelbrot');
    var base = namespace.lookup('org.startpad.base');

    function addTests(ts) {

        ts.addTest("Iter Samples", function (ut) {
            var m = new mandelbrot.Mandelbrot();
            var inSet = [[0, 0], [0, 1], [0, -1],
                         [-2, 0]];
            var outSet = [[1, 0], [2, 0], [-2.1, 0],
                          [0, 2], [0, -2], [2, 2]];
            var i;
            var p;

            for (i = 0; i < inSet.length; i++) {
                p = inSet[i];
                ut.assertEq(m.iterations(p[0], p[1]), m.maxIterations,
                            p[0] + ', ' + p[1]);
            }

            for (i = 0; i < outSet.length; i++) {
                p = outSet[i];
                ut.assert(m.iterations(p[0], p[1]) != m.maxIterations);
            }
        });

        ts.addTest("Vertical Symmetry", function (ut) {
            var m = new mandelbrot.Mandelbrot();

            for (var i = 0; i < 100; i++) {
                var x = base.randomInt(100) / 100 - 0.5;
                var y = base.randomInt(100) / 100;

                var iters = m.iterations(x, y);
                ut.assertEq(iters, m.iterations(x, -y));
            }
        });

        ts.addTest("Raw Speed Test", function (ut) {
            var m = new mandelbrot.Mandelbrot();
            var msStart = new Date().getTime();
            var cInSet = 0;
            var data = [];

            m.renderData(data, m.rcTop, 256, 256);

            for (var i = 0; i < data.length; i += 4) {
                if (data[i] + data[i + 1] + data[i + 2] == 0) {
                    cInSet++;
                }
            }

            var msElapsed = new Date().getTime() - msStart;
            var area = cInSet * 16 / 256 / 256;
            console.log("area = " + area + " (" + msElapsed + "ms)");
            ut.assert(msElapsed < 1000, "Too slow: " + msElapsed + "ms");
            var error = Math.abs(1.50659 - area);
            ut.assert(error < 0.2, "Area error: " + error);
        });

        ts.addTest("Color Invertibility", function (ut) {
            var m = new mandelbrot.Mandelbrot();

            // Confirm colors assignment are invertible.
            for (var level = 0; level <= m.maxIterations; level++) {
                ut.assertEq(m.levelFromColor(m.colorFromLevel(level)), level);
            }
        });

        ts.addTest("rgba", function (ut) {
            var m = new mandelbrot.Mandelbrot();
            var regex = /^rgba\((\d+,){3}\d+\)$/;
            for (var level = 0; level <= this.maxIterations; level += 100) {
                var color = m.colorFromLevel(color);
                var rgba = m.rgbaFromColor(color);
                ut.assert(regex.test(rgba), rgba);
            }
        });

    }

    ns.addTests = addTests;
});
